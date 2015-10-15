# -*- coding: utf-8 -*-

"""
***************************************************************************
    ShortestPathIntersections.py
    ---------------------
    Date                 : October 2015
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
__date__ = 'October 2015'
__copyright__ = '(C) 2015, Spencer Gardner'

# This will get replaced with a git SHA1 when you do a git archive

__revision__ = '$Format:%H$'

from PyQt4.QtCore import QSettings
from qgis.core import *

import processing
from processing.core.GeoAlgorithm import GeoAlgorithm
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterString
from processing.core.parameters import ParameterNumber
from processing.core.parameters import ParameterTableField
from processing.core.parameters import ParameterSelection

from processing.tools import dataobjects, vector
from processing.algs.qgis import postgis_utils
from dbutils import LayerDbInfo


class ShortestPathFromLayer(GeoAlgorithm):
    """This algorithm takes an input road network and
    an origin-destination intersection pair and finds
    the shortest path between the two.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    ROADS_LAYER = 'ROADS_LAYER'
    DESTINATIONS_LAYER = 'DESTINATIONS_LAYER'
    VERT_ID_FIELD = 'VERT_ID_FIELD'
    STRESS = 'STRESS'
    SCHEMA_NAME = 'SCHEMA_NAME'
    TABLE_NAME = 'TABLE_NAME'


    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Shortest paths - layer'

        # The branch of the toolbox under which the algorithm will appear
        #self.group = 'Algorithms for vector layers'
        self.group = 'Network Analysis'

        # Input roads layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.ROADS_LAYER,
            self.tr('Roads layer (must have a network built)'),
            [ParameterVector.VECTOR_TYPE_LINE], optional=False))

        # Input roads layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.DESTINATIONS_LAYER,
            self.tr('Destinations layer (must have vertex IDs)'),
            [ParameterVector.VECTOR_TYPE_POINT], optional=False))

        # Field with vertex IDs
        # Required
        self.addParameter(ParameterTableField(self.VERT_ID_FIELD,
            self.tr('Field containing the network vertex IDs'),
            parent=self.DESTINATIONS_LAYER,
            datatype = ParameterTableField.DATA_TYPE_NUMBER,
            optional=False))

        # Max stress
        self.addParameter(ParameterNumber(self.STRESS,
            self.tr('Maximum allowable traffic stress (leave at 0 to ignore)'),
            minValue=0,maxValue=4))

        # Schema name
        self.SCHEMA_NAMES = ['generated','received','scratch']
        self.addParameter(ParameterSelection(self.SCHEMA_NAME,
            self.tr('Output schema'), self.SCHEMA_NAMES))

        # Table name
        self.addParameter(ParameterString(self.TABLE_NAME,
            self.tr('Output table name')))


    def processAlgorithm(self, progress):
        # Retrieve the values of the parameters entered by the user
        roadsLayer = dataobjects.getObjectFromUri(
            self.getParameterValue(self.ROADS_LAYER))
        destsLayer = dataobjects.getObjectFromUri(
            self.getParameterValue(self.DESTINATIONS_LAYER))
        vertIdField = self.getParameterValue(self.VERT_ID_FIELD)
        stress = self.getParameterValue(self.STRESS)
        schemaName = self.SCHEMA_NAMES[self.getParameterValue(self.SCHEMA_NAME)]
        tableName = self.getParameterValue(self.TABLE_NAME)

        # establish db connection
        roadsDb = LayerDbInfo(roadsLayer.source())
        dbHost = roadsDb.getHost()
        dbPort = roadsDb.getPort()
        dbName = roadsDb.getDBName()
        dbUser = roadsDb.getUser()
        dbPass = roadsDb.getPassword()
        dbSchema = roadsDb.getSchema()
        dbTable = roadsDb.getTable()
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

        # connection = None
        # if connectionName:
        #     dbpluginclass = createDbPlugin( 0, connectionName ) # connection type 0 = postgis
        #     if dbpluginclass:
        #         try:
        #             connection = dbpluginclass.connect()
        #         except BaseError as e:
        #             progress.setText(e.msg)
        # else:
        #     progress.setText("<b>## Couldn't connect to database</b>")

        # get vertex ids
        progress.setInfo('Getting vertex IDs')
        vertIds = []
        for val in vector.values(destsLayer,vertIdField)[vertIdField]:
            if val.is_integer():
                vertIds.append(int(val))
            else:
                raise GeoAlgorithmExecutionException(
                    self.tr('Bad vert_id values. Input field was %s. Check that \
                        these are integer values.' % vertIdField))

        vertPairCount = len(vertIds) ** 2
        progress.setInfo('%i total destination pairs identified' % vertPairCount)

        # first construct the base sql call
        baseSql = 'select tdg.tdgShortestPathMatrix('
        baseSql = baseSql + "'" + dbTable + "',"

        count = 0
        sql = "'{"
        for fromVertId in vertIds:
            for toVertId in vertIds:
                count = count + 1
                sql = sql + str(fromVertId) + ',' + str(toVertId) + ','
                if count % 1000 == 0 or count == vertPairCount:
                    progress.setInfo('Processing pair %i of %i'
                        % (count, vertPairCount))
                    sql = sql[:-1]                  #remove the last comma
                    sql = sql + "}'::INTEGER[]"    #finish the call
                    sql = baseSql + sql
                    sql = sql + ",'" + schemaName + "',"
                    sql = sql + "'" + tableName + "',"
                    if count == 1000 or (count < 1000 and count == vertPairCount):
                        sql = sql + "'t',"  #overwrite
                        sql = sql + "'f',"  #append
                    else:
                        sql = sql + "'f',"  #overwrite
                        sql = sql + "'t',"  #append
                    sql = sql + "'t',"  #map
                    sql = sql + "NULL)"  #stress
                    try:
                        db._exec_sql_and_commit(sql)
                        progress.setPercentage(100*count/vertPairCount)
                        sql = "'{"
                    except:
                        raise
