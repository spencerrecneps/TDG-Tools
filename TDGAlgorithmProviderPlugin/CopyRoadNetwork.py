# -*- coding: utf-8 -*-

"""
***************************************************************************
    CopyRoadNetwork.py
    ---------------------
    Date                 : November 2015
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
__date__ = 'November 2015'
__copyright__ = '(C) 2015, Spencer Gardner'

# This will get replaced with a git SHA1 when you do a git archive

__revision__ = '$Format:%H$'

from qgis.core import *
from TDGAlgorithm import TDGAlgorithm
import processing
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector, ParameterSelection, ParameterString, ParameterBoolean
from processing.tools import dataobjects


class CopyRoadNetwork(TDGAlgorithm):
    """This algorithm copies an existing road network"""

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    OLD_ROAD_LAYER = 'OLD_ROAD_LAYER'
    SCHEMA_NAME = 'SCHEMA_NAME'
    NEW_ROAD_LAYER = 'NEW_ROAD_LAYER'
    OVERWRITE = 'OVERWRITE'
    ADDTOMAP = 'ADDTOMAP'

    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Copy road dataset'

        # The branch of the toolbox under which the algorithm will appear
        #self.group = 'Algorithms for vector layers'
        self.group = 'Data Management'

        # Input roads layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.OLD_ROAD_LAYER,
            self.tr('Standardized TDG roads layer'), [ParameterVector.VECTOR_TYPE_LINE], optional=False))

        # schema
        self.addParameter(ParameterSelection(self.SCHEMA_NAME,
            self.tr('Schema'), self.SCHEMA_NAMES))

        # New roads table name
        self.addParameter(ParameterString(self.NEW_ROAD_LAYER,
            self.tr('New roads layer name')))

        # Overwrite existing tables?
        self.addParameter(ParameterBoolean(self.OVERWRITE,
            self.tr('Overwrite existing tables (if they exist)'), True))

        # Add new table to map?
        self.addParameter(ParameterBoolean(self.ADDTOMAP,
            self.tr('Add new tables to map'), True))


    def processAlgorithm(self, progress):
        # Retrieve the values of the parameters entered by the user
        inLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.OLD_ROAD_LAYER))
        schema = self.SCHEMA_NAMES[self.getParameterValue(self.SCHEMA_NAME)]
        table = self.getParameterValue(self.NEW_ROAD_LAYER).strip().lower()
        overwrite = self.getParameterValue(self.OVERWRITE)
        addToMap = self.getParameterValue(self.ADDTOMAP)

        # establish db connection
        progress.setInfo('Getting DB connection')
        progress.setPercentage(0)
        self.setDbFromRoadsLayer(inLayer)

        # check if this is a roads layer
        self.setLayersFromDb()
        if not self.intsLayer.isValid():
            raise GeoAlgorithmExecutionException('Layer %s is not a valid TDG \
                roads layer' % inLayer.name())
        progress.setPercentage(5)

        progress.setInfo('Copying roads table')
        try:
            self.db.connector._execute_and_commit(
                "select tdg.tdgCopyTable('%s','%s','%s','%s')" % (self.roadsTable,table,schema,overwrite)
            )
            self.db.connector._execute_and_commit(
                "select tdg.tdgCopyTable('%s','%s','%s','%s')" % (self.intsTable,table + '_intersections',schema,overwrite)
            )
            if self.vertsLayer.isValid():
                self.db.connector._execute_and_commit(
                    "select tdg.tdgCopyTable('%s','%s','%s','%s')" % (self.vertsTable,table + '_net_vert',schema,overwrite)
                )
            if self.linksLayer.isValid():
                self.db.connector._execute_and_commit(
                    "select tdg.tdgCopyTable('%s','%s','%s','%s')" % (self.linksTable,table + '_net_link',schema,overwrite)
                )
        except Exception, e:
            raise GeoAlgorithmExecutionException(e)
        progress.setPercentage(50)

        # set db from new layer
        progress.setInfo('Getting new layers')
        uri = QgsDataSourceURI(self.roadsLayer.source())
        uri.setDataSource(schema, table, 'geom', '', 'road_id')
        dbLayer = QgsVectorLayer(uri.uri(),table,'postgres')
        self.setDbFromRoadsLayer(dbLayer)
        self.setLayersFromDb()
        progress.setPercentage(55)

        progress.setInfo('Setting indexes and triggers')
        try:
            fullRoadsTable = self.schema + '.' + self.roadsTable
            fullIntsTable = self.schema + '.' + self.intsTable
            self.db.connector._execute_and_commit(
                "select tdg.tdgMakeStandardizedRoadIndexes('%s')" % (fullRoadsTable)
            )
            self.db.connector._execute_and_commit(
                "select tdg.tdgMakeIntersectionIndexes('%s')" % (fullIntsTable)
            )
            self.db.connector._execute_and_commit(
                "select tdg.tdgMakeRoadTriggers('%s','%s')" % (fullRoadsTable, self.roadsTable)
            )
            self.db.connector._execute_and_commit(
                "select tdg.tdgMakeIntersectionTriggers('%s','%s')" % (fullIntsTable, self.intsTable)
            )
        except Exception, e:
            raise GeoAlgorithmExecutionException(e)
        progress.setPercentage(90)

        if addToMap:
            progress.setInfo('Adding to map')
            self.addRoadsToMap()
            self.addIntsToMap()
            if self.linksLayer:
                self.addLinksToMap()
            if self.vertsLayer:
                self.addVertsToMap()
        progress.setPercentage(100)
