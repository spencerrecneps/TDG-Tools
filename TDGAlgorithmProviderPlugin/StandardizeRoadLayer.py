# -*- coding: utf-8 -*-

"""
***************************************************************************
    StandardizeRoadLayer.py
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
__date__ = 'July 2013'
__copyright__ = '(C) 2015, Spencer Gardner'

# This will get replaced with a git SHA1 when you do a git archive

__revision__ = '$Format:%H$'

from PyQt4.QtCore import QSettings, QVariant
from qgis.core import QgsDataSourceURI, QgsVectorLayerImport, QGis, QgsFeature, QgsGeometry

import processing
from processing.core.GeoAlgorithm import GeoAlgorithm
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterString
from processing.core.parameters import ParameterTableField
from processing.core.parameters import ParameterBoolean
from processing.core.parameters import ParameterSelection

from processing.tools import dataobjects, vector
from processing.algs.qgis import postgis_utils
from dbutils import LayerDbInfo


class StandardizeRoadLayer(GeoAlgorithm):
    """This algorithm takes an input road dataset and converts
    it into a standardized format for use in stress analysis
    and other tasks.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    TABLE_NAME = 'TABLE_NAME'
    ROADS_LAYER = 'ROADS_LAYER'
    ID_FIELD = 'ID_FIELD'
    NAME_FIELD = 'NAME_FIELD'
    ADT_FIELD = 'ADT_FIELD'
    SPEED_FIELD = 'SPEED_FIELD'
    FUNC_FIELD = 'FUNC_FIELD'
    ONEWAY_FIELD = 'ONEWAY_FIELD'
    OVERWRITE = 'OVERWRITE'
    DELETE_SOURCE = 'DELETE_SOURCE'

    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Create standardized TDG road layer'

        # The branch of the toolbox under which the algorithm will appear
        #self.group = 'Algorithms for vector layers'
        self.group = 'Network Analysis'

        # name for new table
        # mandatory
        self.addParameter(ParameterString(self.TABLE_NAME,
            self.tr('Name of table to be created'), optional=False))

        # Input roads layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.ROADS_LAYER,
            self.tr('Roads layer'), [ParameterVector.VECTOR_TYPE_LINE], optional=False))

        # Source ID field in the roads data
        # Optional field
        self.addParameter(ParameterTableField(self.ID_FIELD,
            self.tr('Original ID field of the road layer'), optional=True))

        # Name field in the roads data
        # Optional field
        self.addParameter(ParameterTableField(self.NAME_FIELD,
            self.tr('Name field of the road layer'), optional=True))

        # ADT field in the roads data
        # Optional field
        self.addParameter(ParameterTableField(self.ADT_FIELD,
            self.tr('ADT field of the road layer'), optional=True))

        # Speed limit field in the roads data
        # Optional field
        self.addParameter(ParameterTableField(self.SPEED_FIELD,
            self.tr('Speed limit field of the road layer'), optional=True))

        # Function class field in the roads data
        # Optional field
        self.addParameter(ParameterTableField(self.FUNC_FIELD,
            self.tr('Functional class field of the road layer'), optional=True))

        # One way field in the roads data
        # Optional field
        self.addParameter(ParameterTableField(self.ONEWAY_FIELD,
            self.tr('One way field of the road layer'), optional=True))

        # Overwrite existing table?
        self.addParameter(ParameterBoolean(self.OVERWRITE,
            self.tr('Overwrite'), default=True))

        # Delete source table?
        self.addParameter(ParameterBoolean(self.DELETE_SOURCE,
            self.tr('Delete source table'), default=False))

    def processAlgorithm(self, progress):
        # Retrieve the values of the parameters entered by the user
        tableName = self.getParameterValue(self.TABLE_NAME).strip().lower()
        inLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.ROADS_LAYER))
        fieldIdOrig = self.getParameterValue(self.ID_FIELD)
        fieldName = self.getParameterValue(self.NAME_FIELD)
        fieldADT = self.getParameterValue(self.ADT_FIELD)
        fieldSpeed = self.getParameterValue(self.SPEED_FIELD)
        fieldFunc = self.getParameterValue(self.FUNC_FIELD)
        fieldOneway = self.getParameterValue(self.ONEWAY_FIELD)
        overwrite = self.getParameterValue(self.OVERWRITE)
        delSource = self.getParameterValue(self.DELETE_SOURCE)

        # establish db connection
        roadsDb = LayerDbInfo(inLayer.source())
        dbHost = roadsDb.getHost()
        dbPort = roadsDb.getPort()
        dbName = roadsDb.getDBName()
        dbUser = roadsDb.getUser()
        dbPass = roadsDb.getPassword()
        dbSchema = roadsDb.getSchema()
        dbType = roadsDb.getType()
        dbSRID = roadsDb.getSRID()
        try:
            db = postgis_utils.GeoDB(host=dbHost,
                                     port=dbPort,
                                     dbname=dbName,
                                     user=dbUser,
                                     passwd=dbPass)
        except postgis_utils.DbError, e:
            raise GeoAlgorithmExecutionException(
                self.tr("Couldn't connect to database:\n%s" % e.message))


        settings = QSettings()
        mySettings = '/PostgreSQL/connections/' + dbName
        try:
            database = settings.value(mySettings + '/database')
        except Exception, e:
            raise GeoAlgorithmExecutionException(
                self.tr('Wrong database connection name: %s' % connection))

        sql = 'select tdgStandardizeRoadLayer('
        sql = sql + "'" + roadsDb.getTable() + "',"
        sql = sql + "'" + tableName + "',"
        if fieldIdOrig is None:
            sql = sql + 'NULL,'
        else:
            sql = sql + "'" + fieldIdOrig + "',"
        if fieldName is None:
            sql = sql + 'NULL,'
        else:
            sql = sql + "'" + fieldName + "',"
        if fieldADT is None:
            sql = sql + 'NULL,'
        else:
            sql = sql + "'" + fieldADT + "',"
        if fieldSpeed is None:
            sql = sql + 'NULL,'
        else:
            sql = sql + "'" + fieldSpeed + "',"
        if fieldFunc is None:
            sql = sql + 'NULL,'
        else:
            sql = sql + "'" + fieldFunc + "',"
        if fieldOneway is None:
            sql = sql + 'NULL,'
        else:
            sql = sql + "'" + fieldOneway + "',"
        if overwrite:
            sql = sql + "'t',"
        else:
            sql = sql + "'f',"
        if delSource:
            sql = sql + "'t')"
        else:
            sql = sql + "'f')"

        processing.runalg("qgis:postgisexecutesql",database,
            sql)

        if delSource:
            delSql = 'DROP TABLE ' + roadsDb.getTable()
            processing.runalg("qgis:postgisexecutesql",database,
                delSql)
"""
        # set up the new table's uri and get new object
        uri = QgsDataSourceURI()
        uri.setConnection(dbHost, str(dbPort), dbName, dbUser, dbPass)
        uri.setDataSource(dbSchema, tableName, 'geom', 'id')

        #iface.addVectorLayer(uri.uri(),tableName,'postgres')
"""
