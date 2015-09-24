# -*- coding: utf-8 -*-

"""
***************************************************************************
    ImportRoadLayer.py
    ---------------------
    Date                 : July 2015
    Copyright            : (C) 2015 by Spencer Gardner
    Email                : spencergardner at gmail dot com
***************************************************************************
*                                                                         *
*   This program is free software; you can redistribute it and/or modify  *
*   it under the terms of the GNU General Public License as published by  *
*   the Free Software Foundation; either version 2 of the License, or     *
*   (at your option) any later version.                                   *
*                                                                         *
***************************************************************************
"""

__author__ = 'Spencer Gardner'
__date__ = 'July 2015'
__copyright__ = '(C) 2015, Spencer Gardner'

# This will get replaced with a git SHA1 when you do a git archive

__revision__ = '$Format:%H$'

import string
import random
from PyQt4.QtCore import QSettings
from qgis.core import *

import processing
from processing.core.GeoAlgorithm import GeoAlgorithm
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterString
from processing.core.parameters import ParameterCrs
from processing.core.parameters import ParameterBoolean
from processing.core.parameters import ParameterSelection

from processing.tools import dataobjects, vector
from processing.algs.qgis import postgis_utils


class ImportRoadLayer(GeoAlgorithm):
    """This algorithm takes an input road dataset and
    uploads it to a PostGIS database for use in stress analysis
    and other tasks.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    ROADS_LAYER = 'ROADS_LAYER'
    DATABASE = 'DATABASE'
    SCHEMANAME = 'SCHEMANAME'
    TABLENAME = 'TABLENAME'
    ADDTOMAP = 'ADDTOMAP'
    OVERWRITE = 'OVERWRITE'
    TARGET_CRS = 'TARGET_CRS'

    def dbConnectionNames(self):
        settings = QSettings()
        settings.beginGroup('/PostgreSQL/connections/')
        return settings.childGroups()

    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Import new TDG road layer'

        # The branch of the toolbox under which the algorithm will appear
        #self.group = 'Algorithms for vector layers'
        self.group = 'Data Management'

        # Input roads layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.ROADS_LAYER,
            self.tr('Roads layer'), [ParameterVector.VECTOR_TYPE_LINE], False))

        # DB connection
        self.DB_CONNECTIONS = self.dbConnectionNames()
        self.addParameter(ParameterSelection(self.DATABASE,
            self.tr('Database (connection name)'), self.DB_CONNECTIONS))

        # Schema name
        self.SCHEMA_NAMES = ['generated','received','scratch']
        self.addParameter(ParameterSelection(self.SCHEMANAME,
            self.tr('Schema'), self.SCHEMA_NAMES))

        # Table name
        self.addParameter(ParameterString(self.TABLENAME,
            self.tr('Table name to import to (leave blank to use layer name)')))

        # Add new table to map?
        self.addParameter(ParameterBoolean(self.ADDTOMAP,
            self.tr('Add new table to map'), True))

        # Overwrite existing table?
        self.addParameter(ParameterBoolean(self.OVERWRITE,
            self.tr('Overwrite'), True))

        # CRS
        self.addParameter(ParameterCrs(self.TARGET_CRS,
            self.tr('Target CRS'), 'EPSG:4326'))

    def processAlgorithm(self, progress):
        # Retrieve the values of the parameters entered by the user
        # roads layer
        roadsLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.ROADS_LAYER))

        # db connection
        connection = self.DB_CONNECTIONS[self.getParameterValue(self.DATABASE)]
        settings = QSettings()
        mySettings = '/PostgreSQL/connections/' + connection
        try:
            database = settings.value(mySettings + '/database')
            username = settings.value(mySettings + '/username')
            host = settings.value(mySettings + '/host')
            port = settings.value(mySettings + '/port', type=int)
            password = settings.value(mySettings + '/password')
        except Exception, e:
            raise GeoAlgorithmExecutionException(
                self.tr('Bad database connection name: %s' % connection))

        # schema name
        schema = self.SCHEMA_NAMES[self.getParameterValue(self.SCHEMANAME)]

        # table name
        table = self.getParameterValue(self.TABLENAME).strip().lower()
        if table is None or len(table) < 1:
            table = roadsLayer.name().lower()
        table.replace(' ', '')

        # test connection
        providerName = 'postgres'
        try:
            db = postgis_utils.GeoDB(host=host, port=port, dbname=database,
                                     user=username, passwd=password)
        except postgis_utils.DbError, e:
            raise GeoAlgorithmExecutionException(
                self.tr("Couldn't connect to database:\n%s" % e.message))

        # Add to map
        addToMap = self.getParameterValue(self.ADDTOMAP)

        # Overwrite
        overwrite = self.getParameterValue(self.OVERWRITE)

        # Target CRS
        crsId = self.getParameterValue(self.TARGET_CRS)
        targetCrs = QgsCoordinateReferenceSystem()
        targetCrs.createFromUserInput(crsId)
        pgSrid = targetCrs.postgisSrid()

        ##########################
        # And now we can process #
        ##########################
        #linestrings = processing.runalg('qgis:multiparttosingleparts')

        # first create the schema if it doesn't exist
        progress.setInfo('Creating schema ' + schema + '(if necessary)')
        processing.runalg("qgis:postgisexecutesql",connection,
            "CREATE SCHEMA IF NOT EXISTS " + schema)
        progress.setPercentage(5)

        # set up the temporary table and import the raw data
        tempTableName = ''.join(random.sample(string.lowercase,10))
        progress.setInfo('Importing to temporary table: ' + tempTableName)
        #processing.runalg("qgis:importintopostgis",database,tempTableName,schema,
        #    roadsLayer,False,True,'geom',True,True,None)
        processing.runalg("qgis:importintopostgis",roadsLayer,
            self.getParameterValue(self.DATABASE),schema,tempTableName,
            None,'geom',False,True,True,True)
        progress.setPercentage(60)

        # move the temp table to its final location
        # need to parse the crsId to get rid of the EPSG: part
        progress.setInfo('Cleaning and finalizing table as: ' + table)
        processing.runalg("qgis:postgisexecutesql",connection,
            "SELECT tdgMultiToSingle(\'" + tempTableName + "\',\
                \'" + table + "\',\
                \'" + schema + "\',\
                " + str(pgSrid) + ",\
                " + str(overwrite) + ")")
        progress.setPercentage(90)

        progress.setInfo('Analyzing table ' + table)
        processing.runalg("qgis:postgisexecutesql",connection,
            "ANALYZE " + schema + "." + table)
        progress.setPercentage(99)

        # set up the new table's uri
        uri = QgsDataSourceURI()
        uri.setConnection(host, str(port), database, username, password)

        uri.setDataSource(schema, table, 'geom', '', 'id')
        uri.setSrid(str(pgSrid))
        uri.setWkbType(QGis.WKBLineString)

        # add new table to map
        if addToMap:
            layer = QgsVectorLayer(uri.uri(),table,'postgres')
            QgsMapLayerRegistry.instance().addMapLayer(layer)
