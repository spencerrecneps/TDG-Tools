# -*- coding: utf-8 -*-

"""
***************************************************************************
    AccessGrid.py
    ---------------------
    Date                 : January 2016
    Copyright            : (C) 2016 by Spencer Gardner
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
__date__ = 'January 2016'
__copyright__ = '(C) 2016, Spencer Gardner'

# This will get replaced with a git SHA1 when you do a git archive

__revision__ = '$Format:%H$'

import os
import markdown2
from PyQt4.QtCore import QVariant
from qgis.core import *

from TDGAlgorithm import TDGAlgorithm
import processing
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterString
from processing.core.parameters import ParameterNumber
from processing.core.parameters import ParameterTableField
from processing.core.parameters import ParameterSelection
from processing.core.outputs import OutputVector

from processing.tools import dataobjects, vector
from nxutils import NXUtils

import networkx as nx

class AccessGrid(TDGAlgorithm):
    """This algorithm takes an input grid with the nearest
    network vertex identified and calculates the travel
    shed for each cell, counting the number of cells
    that are accessible within the shed.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    ROADS_LAYER = 'ROADS_LAYER'
    ORIGINS_LAYER = 'ORIGINS_LAYER'
    ORIGIN_VERT_ID_FIELD = 'ORIGIN_VERT_ID_FIELD'
    GRID_LAYER = 'GRID_LAYER'
    GRID_VERT_ID_FIELD = 'GRID_VERT_ID_FIELD'
    BUDGET = 'BUDGET'
    STRESS = 'STRESS'
    OUT_LAYER = 'OUT_LAYER'


    def help(self):
        html = markdown2.markdown_path(os.path.join(self.helpPath,'Access Grid.md'))
        return True, html


    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Access grid'

        # The branch of the toolbox under which the algorithm will appear
        #self.group = 'Algorithms for vector layers'
        self.group = 'Network Analysis'

        # Input roads layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(
            ParameterVector(
                self.ROADS_LAYER,
                self.tr('Roads layer (must have a network built)'),
                [ParameterVector.VECTOR_TYPE_LINE],
                optional=False
            )
        )

        # Input origins layer. Must be point type
        # Required
        self.addParameter(
            ParameterVector(
                self.ORIGINS_LAYER,
                self.tr('Origins layer (must have network vertex IDs)'),
                [ParameterVector.VECTOR_TYPE_POINT],
                optional=False
            )
        )

        # Origins field with vertex IDs
        # Required
        self.addParameter(
            ParameterTableField(
                self.ORIGIN_VERT_ID_FIELD,
                self.tr('Origin field containing the network vertex IDs'),
                parent=self.ORIGINS_LAYER,
                datatype = ParameterTableField.DATA_TYPE_NUMBER,
                optional=False
            )
        )

        # Input grid layer. Must be polygon type
        # Required
        self.addParameter(
            ParameterVector(
                self.GRID_LAYER,
                self.tr('Grid layer (must have vertex IDs)'),
                [ParameterVector.VECTOR_TYPE_POLYGON],
                optional=False
            )
        )

        # Grid field with vertex IDs
        # Required
        self.addParameter(
            ParameterTableField(
                self.GRID_VERT_ID_FIELD,
                self.tr('Grid field containing the network vertex IDs'),
                parent=self.GRID_LAYER,
                datatype = ParameterTableField.DATA_TYPE_NUMBER,
                optional=False
            )
        )

        # Max travel budget
        # Required
        self.addParameter(
            ParameterNumber(
                self.BUDGET,
                self.tr('Maximum travel budget (in cost units)'),
                minValue=0,
                optional=False
            )
        )

        # Max stress
        # Required
        self.addParameter(
            ParameterNumber(
                self.STRESS,
                self.tr('Maximum allowable traffic stress'),
                minValue=1,maxValue=4,
                optional=False
            )
        )


        # Output raw layer
        self.addOutput(
            OutputVector(self.OUT_LAYER, self.tr('Output'))
        )


    def processAlgorithm(self, progress):
        progress.setPercentage(0)
        # Retrieve the values of the parameters entered by the user
        inLayer = dataobjects.getObjectFromUri(
            self.getParameterValue(self.ROADS_LAYER))
        originsLayer = dataobjects.getObjectFromUri(
            self.getParameterValue(self.ORIGINS_LAYER))
        oVertIdField = self.getParameterValue(self.ORIGIN_VERT_ID_FIELD)
        gridLayer = dataobjects.getObjectFromUri(
            self.getParameterValue(self.GRID_LAYER))
        gVertIdField = self.getParameterValue(self.GRID_VERT_ID_FIELD)
        stress = self.getParameterValue(self.STRESS)
        budget = self.getParameterValue(self.BUDGET)

        # build the output layer
        gridFields = QgsFields()
        gridFields.append(QgsField('id', QVariant.Int))
        gridFields.append(QgsField('origin_id', QVariant.Int))
        gridFields.append(QgsField('grid_id', QVariant.Int))
        gridFields.append(QgsField('car_cost', QVariant.Int))
        gridFields.append(QgsField('bike_cost', QVariant.Int))
        gridFields.append(QgsField('conn_idx', QVariant.Double))
        gridWriter = self.getOutputFromName(self.OUT_LAYER).getVectorWriter(
            gridFields, QGis.WKBPolygon, inLayer.crs())

        progress.setPercentage(2)

        # establish db connection
        progress.setInfo('Getting DB connection')
        self.setDbFromRoadsLayer(inLayer)
        self.setLayersFromDb()
        if self.vertsLayer is None or self.linksLayer is None:
            raise GeoAlgorithmExecutionException('Could not find related \
                network tables. Have you built the network tables on \
                layer %s?' % inLayer.name())
        progress.setPercentage(3)

        # get network
        progress.setInfo('Building network')
        nu = NXUtils(self.vertsLayer,self.linksLayer)
        nu.buildNetwork()
        DG = nu.getNetwork()
        # if not stress:
        #     stress = 99
        SG = nu.getStressNetwork(stress)
        progress.setPercentage(10)

        # loop through the grid features and get distances to origins for each
        count = 0
        totalCount = len(vector.features(originsLayer))
        idStep = 0
        for originFeat in vector.features(originsLayer):
            originVertId = originFeat.attribute(oVertIdField)

            # skip if node is not accessible by low stress
            if not originVertId in SG:
                continue

            # get shortest path
            pathsBase = nx.single_source_dijkstra_path_length(
                DG,
                source=originVertId,
                cutoff=budget,
                weight='weight'
            )

            # get shortest low stress path
            pathsLowStress = nx.single_source_dijkstra_path_length(
                SG,
                source=originVertId,
                cutoff=budget,
                weight='weight'
            )

            # loop through grid and establish features
            for gridFeat in vector.features(gridLayer):
                gridVertId = gridFeat.attribute(gVertIdField)
                if gridVertId in pathsLowStress:
                    if gridVertId in pathsBase:
                        carCost = pathsBase[gridVertId]
                    else:
                        carCost = None
                    bikeCost = pathsLowStress[gridVertId]
                    connIdx = float()
                    if carCost is None:
                        connIdx = 1
                    elif carCost == 0:
                        connIdx = 1
                    else:
                        connIdx = float(bikeCost)/float(carCost)
                    outFeat = QgsFeature(gridFields)
                    outFeat.setAttribute(0,idStep) #feature id
                    outFeat.setAttribute(1,originFeat.id()) #origin_id
                    outFeat.setAttribute(2,gridFeat.id()) #grid_id
                    outFeat.setAttribute(3,carCost) #car_cost
                    outFeat.setAttribute(4,bikeCost) #bike_cost
                    outFeat.setAttribute(5,connIdx) #conn_idx
                    outGeom = QgsGeometry(gridFeat.geometry())
                    outFeat.setGeometry(outGeom)
                    idStep += 1
                    gridWriter.addFeature(outFeat)

            count += 1
            progress.setPercentage(10+int(90*float(count)/totalCount))

        del gridWriter
