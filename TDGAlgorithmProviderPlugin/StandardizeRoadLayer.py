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
__date__ = 'July 2015'
__copyright__ = '(C) 2015, Spencer Gardner'

# This will get replaced with a git SHA1 when you do a git archive

__revision__ = '$Format:%H$'

from PyQt4.QtCore import QSettings
from qgis.core import *

from TDGAlgorithm import TDGAlgorithm
import processing
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterString
from processing.core.parameters import ParameterTableField
from processing.core.parameters import ParameterBoolean
from processing.core.parameters import ParameterSelection
from processing.tools import dataobjects, vector


class StandardizeRoadLayer(TDGAlgorithm):
    """This algorithm takes an input road dataset and converts
    it into a standardized format for use in stress analysis
    and other tasks.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    SCHEMA_NAME = 'SCHEMA_NAME'
    TABLE_NAME = 'TABLE_NAME'
    ROADS_LAYER = 'ROADS_LAYER'
    Z_FROM_FIELD = 'Z_FROM_FIELD'
    Z_TO_FIELD = 'Z_TO_FIELD'
    NAME_FIELD = 'NAME_FIELD'
    ADT_FIELD = 'ADT_FIELD'
    SPEED_FIELD = 'SPEED_FIELD'
    FUNC_FIELD = 'FUNC_FIELD'
    ONEWAY_FIELD = 'ONEWAY_FIELD'
    ADDTOMAP = 'ADDTOMAP'
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
        self.group = 'Data Management'

        # schema for new table
        self.SCHEMA_NAMES = ['generated','received','scratch']
        self.addParameter(ParameterSelection(self.SCHEMA_NAME,
            self.tr('Schema'), self.SCHEMA_NAMES))

        # name for new table
        # mandatory
        self.addParameter(ParameterString(self.TABLE_NAME,
            self.tr('Name of table to be created'), optional=False))

        # Input roads layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.ROADS_LAYER,
            self.tr('Roads layer'), [ParameterVector.VECTOR_TYPE_LINE], optional=False))

        # Field with z elev values
        # Optional field
        self.addParameter(ParameterTableField(self.Z_FROM_FIELD,
            self.tr('Intersection Z (elevation) value at segment starting point'),
            parent=self.ROADS_LAYER,
            optional=True))

        # Field with z elev values
        # Optional field
        self.addParameter(ParameterTableField(self.Z_TO_FIELD,
            self.tr('Intersection Z (elevation) value at segment ending point'),
            parent=self.ROADS_LAYER,
            optional=True))

        # Name field in the roads data
        # Optional field
        self.addParameter(ParameterTableField(self.NAME_FIELD,
            self.tr('Name field of the road layer'),
            parent=self.ROADS_LAYER,
            optional=True))

        # ADT field in the roads data
        # Optional field
        self.addParameter(ParameterTableField(self.ADT_FIELD,
            self.tr('ADT field of the road layer'),
            parent=self.ROADS_LAYER,
            optional=True))

        # Speed limit field in the roads data
        # Optional field
        self.addParameter(ParameterTableField(self.SPEED_FIELD,
            self.tr('Speed limit field of the road layer'),
            parent=self.ROADS_LAYER,
            optional=True))

        # Function class field in the roads data
        # Optional field
        self.addParameter(ParameterTableField(self.FUNC_FIELD,
            self.tr('Functional class field of the road layer'),
            parent=self.ROADS_LAYER,
            optional=True))

        # One way field in the roads data
        # Optional field
        self.addParameter(ParameterTableField(self.ONEWAY_FIELD,
            self.tr('One way field of the road layer'),
            parent=self.ROADS_LAYER,
            optional=True))

        # Add new table to map?
        self.addParameter(ParameterBoolean(self.ADDTOMAP,
            self.tr('Add new table to map'), True))

        # Overwrite existing table?
        self.addParameter(ParameterBoolean(self.OVERWRITE,
            self.tr('Overwrite'), default=True))

        # Delete source table?
        self.addParameter(ParameterBoolean(self.DELETE_SOURCE,
            self.tr('Delete source table'), default=False))

    def processAlgorithm(self, progress):
        # Retrieve the values of the parameters entered by the user
        schema = self.SCHEMA_NAMES[self.getParameterValue(self.SCHEMA_NAME)]
        tableName = self.getParameterValue(self.TABLE_NAME).strip().lower()
        inLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.ROADS_LAYER))
        fieldZFrom = self.getParameterValue(self.Z_FROM_FIELD)
        fieldZTo = self.getParameterValue(self.Z_TO_FIELD)
        fieldName = self.getParameterValue(self.NAME_FIELD)
        fieldADT = self.getParameterValue(self.ADT_FIELD)
        fieldSpeed = self.getParameterValue(self.SPEED_FIELD)
        fieldFunc = self.getParameterValue(self.FUNC_FIELD)
        fieldOneway = self.getParameterValue(self.ONEWAY_FIELD)
        addToMap = self.getParameterValue(self.ADDTOMAP)
        overwrite = self.getParameterValue(self.OVERWRITE)
        delSource = self.getParameterValue(self.DELETE_SOURCE)

        # establish db connection
        progress.setInfo('Getting DB connection')
        self.setDbFromLayer(inLayer)
        uri = QgsDataSourceURI(inLayer.source())
        inTable = uri.schema() + "." + uri.table()

        # check the crs on the road layer
        crs = self.getValidCrs(inLayer.crs().toWkt())

        # first create the new road table
        progress.setInfo('Creating standardized road layer')
        sql = u'select tdg.tdgMakeStandardizedRoadLayer('
        sql = sql + "'" + inTable + "',"
        sql = sql + "'" + schema + "',"
        sql = sql + "'" + tableName + "',"
        if overwrite:
            sql = sql + "'t')"
        else:
            sql = sql + "'f')"
        try:
            self.db.connector._execute_and_commit(sql)
        except Exception, e:
            raise GeoAlgorithmExecutionException(str(e))
        progress.setPercentage(3)


        # next copy data into the new road table
        progress.setInfo('Copying features')

        # first construct the base sql call
        baseSql = u'select tdg.tdgInsertStandardizedRoad('
        baseSql = baseSql + "'" + inTable + "',"
        baseSql = baseSql + "'" + schema + '.' + tableName + "',"
        if fieldName is None:
            baseSql = baseSql + 'NULL,'
        else:
            baseSql = baseSql + "'" + fieldName + "',"
        if fieldZFrom is None:
            baseSql = baseSql + 'NULL,'
        else:
            baseSql = baseSql + "'" + fieldZFrom + "',"
        if fieldZTo is None:
            baseSql = baseSql + 'NULL,'
        else:
            baseSql = baseSql + "'" + fieldZTo + "',"
        if fieldADT is None:
            baseSql = baseSql + 'NULL,'
        else:
            baseSql = baseSql + "'" + fieldADT + "',"
        if fieldSpeed is None:
            baseSql = baseSql + 'NULL,'
        else:
            baseSql = baseSql + "'" + fieldSpeed + "',"
        if fieldFunc is None:
            baseSql = baseSql + 'NULL,'
        else:
            baseSql = baseSql + "'" + fieldFunc + "',"
        if fieldOneway is None:
            baseSql = baseSql + 'NULL,'
        else:
            baseSql = baseSql + "'" + fieldOneway + "',"

        featureIds = inLayer.selectedFeaturesIds()
        if len(featureIds) == 0:
            featureIds = inLayer.allFeatureIds()
        progress.setInfo('Processing ' + str(len(featureIds)) + ' features')
        chunks = [featureIds[i:i+1000] for i in range(0, len(featureIds), 1000)]
        count = 1000
        for chunk in chunks:
            sql = "'{"
            for featId in chunk:
                sql = sql + str(featId) + ','
            sql = sql[:-1]                  #remove the last comma
            sql = sql + "}'::INTEGER[])"    #finish the call
            try:
                self.db.connector._execute_and_commit(baseSql + sql)
                progress.setPercentage(3+20*count/len(featureIds))
                sql = "'{"
                count = count + 1000
            except Exception, e:
                raise GeoAlgorithmExecutionException(str(e))

        # create the indexes
        sql = u'select tdgMakeStandardizedRoadIndexes('
        sql = sql + "'" + schema + '.' + tableName + "')"
        try:
            self.db.connector._execute_and_commit(sql)
        except Exception, e:
            raise GeoAlgorithmExecutionException(str(e))
        progress.setPercentage(26)

        # create the roads layer
        progress.setInfo('Creating road layer')
        self.roadsTable = tableName
        self.schema = schema
        self.srid = str(crs.postgisSrid())
        self.roadsLayer = self.setLayer(tableName,'road_id',QGis.WKBLineString)
        if self.roadsLayer is None:
            raise GeoAlgorithmExecutionException('Could not identify new road layer in database')

        # create the intersection table
        progress.setInfo('Creating intersection table')
        sql = u'select tdg.tdgMakeIntersectionTable('
        sql = sql + "'" + schema + '.' + self.roadsTable + "')"
        try:
            self.db.connector._execute_and_commit(sql)
        except Exception, e:
            raise GeoAlgorithmExecutionException(str(e))
        progress.setPercentage(28)
        self.setLayersFromDb()
        if self.intsLayer is None:
            raise GeoAlgorithmExecutionException('Could not identify new intersections layer in database')

        # add intersections to the intersection table
        progress.setInfo('Adding intersections')
        sql = u'select tdg.tdgInsertIntersections('
        sql = sql + "'" + self.intsTable + "',"
        sql = sql + "'" + self.roadsTable + "')"
        try:
            self.db.connector._execute_and_commit(sql)
        except Exception, e:
            raise GeoAlgorithmExecutionException(str(e))
        progress.setPercentage(40)

        # create indexes on intersections table
        progress.setInfo('Adding indexes')
        sql = u'select tdg.tdgMakeIntersectionIndexes('
        sql = sql + "'" + self.intsTable + "')"
        try:
            self.db.connector._execute_and_commit(sql)
        except Exception, e:
            raise GeoAlgorithmExecutionException(str(e))
        progress.setPercentage(43)

        # loop through road features and process their intersection info
        # in chunks of 1000
        progress.setInfo('Adding intersection data to roads')
        featureIds = self.roadsLayer.allFeatureIds()
        progress.setInfo('  Processing ' + str(len(featureIds)) + ' road features')
        baseSql = u'select tdg.tdgSetRoadIntersections('
        baseSql = baseSql + "'" + self.intsTable + "',"
        baseSql = baseSql + "'" + self.roadsTable + "',"
        chunks = [featureIds[i:i+1000] for i in range(0, len(featureIds), 1000)]
        count = 1000
        for chunk in chunks:
            sql = "'{"
            for featId in chunk:
                sql = sql + str(featId) + ','
            sql = sql[:-1]                  #remove the last comma
            sql = sql + "}'::INTEGER[])"    #finish the call
            try:
                self.db.connector._execute_and_commit(baseSql + sql)
                progress.setPercentage(43+48*count/len(featureIds))
                sql = "'{"
                count = count + 1000
            except Exception, e:
                raise GeoAlgorithmExecutionException(str(e))

        # loop through intersection features and set the count of legs
        progress.setInfo('Calculating intersection legs')
        featureIds = self.intsLayer.allFeatureIds()
        progress.setInfo('  Processing ' + str(len(featureIds)) + ' intersection features')
        baseSql = u'select tdg.tdgSetIntersectionLegs('
        baseSql = baseSql + "'" + self.intsTable + "',"
        baseSql = baseSql + "'" + self.roadsTable + "',"
        chunks = [featureIds[i:i+1000] for i in range(0, len(featureIds), 1000)]
        count = 1000
        for chunk in chunks:
            sql = "'{"
            for featId in chunk:
                sql = sql + str(featId) + ','
            sql = sql[:-1]                  #remove the last comma
            sql = sql + "}'::INTEGER[])"    #finish the call
            try:
                self.db.connector._execute_and_commit(baseSql + sql)
                progress.setPercentage(91+7*count/len(featureIds))
                sql = "'{"
                count = count + 1000
            except Exception, e:
                raise GeoAlgorithmExecutionException(str(e))

        # set intersection triggers
        progress.setInfo('Adding intersection triggers')
        sql = u'select tdg.tdgMakeIntersectionTriggers('
        sql = sql + "'" + self.intsTable + "',"
        sql = sql + "'" + self.roadsTable + "')"
        try:
            self.db.connector._execute_and_commit(sql)
        except Exception, e:
            raise GeoAlgorithmExecutionException(str(e))
        progress.setPercentage(99)

        # set road triggers
        progress.setInfo('Adding road triggers')
        sql = u'select tdg.tdgMakeRoadTriggers('
        sql = sql + "'" + schema + '.' + self.roadsTable + "',"
        sql = sql + "'" + self.roadsTable + "')"
        try:
            self.db.connector._execute_and_commit(sql)
        except Exception, e:
            raise GeoAlgorithmExecutionException(str(e))
        progress.setPercentage(100)

        # add layers to map
        mapReg = QgsMapLayerRegistry.instance()
        if addToMap:
            self.addRoadsToMap()
            self.addIntsToMap()
