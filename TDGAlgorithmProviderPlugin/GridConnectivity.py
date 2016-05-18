# -*- coding: utf-8 -*-

"""
***************************************************************************
    GridConnectivity.py
    ---------------------
    Date                 : March 2016
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
__date__ = 'March 2016'
__copyright__ = '(C) 2016, Spencer Gardner'

# This will get replaced with a git SHA1 when you do a git archive

__revision__ = '$Format:%H$'

import os
import markdown2
from PyQt4.QtCore import QSettings, QVariant
from qgis.core import *

import processing
from TDGAlgorithm import TDGAlgorithm
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterString
from processing.core.parameters import ParameterBoolean
from processing.core.parameters import ParameterNumber
from processing.core.parameters import ParameterTableField
from processing.core.parameters import ParameterSelection
from processing.core.outputs import OutputVector

from processing.tools import dataobjects, vector
from processing.algs.qgis import postgis_utils
from nxutils import NXUtils

import networkx as nx

class GridConnectivity(TDGAlgorithm):
    """This algorithm takes an input road network and
    an origin-destination intersection pair and finds
    the shortest path between the two.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    ROADS_LAYER = 'ROADS_LAYER'
    GRID_LAYER = 'GRID_LAYER'
    VERT_ID_FIELD = 'VERT_ID_FIELD'
    STRESS = 'STRESS'
    OUTPUT_LAYER = 'OUTPUT_LAYER'


    def help(self):
        html = markdown2.markdown_path(os.path.join(self.helpPath,'Shortest Path from Layer.md'))
        return True, html


    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Grid connectivity'

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

        # Input roads layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(
            ParameterVector(
                self.GRID_LAYER,
                self.tr('Grid layer (must have vertex IDs)'),
                [ParameterVector.VECTOR_TYPE_ANY],
                optional=False
            )
        )

        # Field with vertex IDs
        # Required
        self.addParameter(
            ParameterTableField(
                self.VERT_ID_FIELD,
                self.tr('Field containing the network vertex IDs'),
                parent=self.GRID_LAYER,
                datatype = ParameterTableField.DATA_TYPE_NUMBER,
                optional=False
            )
        )

        # Max stress
        self.addParameter(
            ParameterNumber(
                self.STRESS,
                self.tr('Maximum allowable traffic stress (leave at 0 to ignore)'),
                minValue=0,maxValue=4
            )
        )

        # Output layer
        self.addOutput(
            OutputVector(self.OUTPUT_LAYER, self.tr('Output layer'))
        )


    def processAlgorithm(self, progress):
        progress.setPercentage(0)
        # Retrieve the values of the parameters entered by the user
        roadsLayer = dataobjects.getObjectFromUri(
            self.getParameterValue(self.ROADS_LAYER))
        gridLayer = dataobjects.getObjectFromUri(
            self.getParameterValue(self.GRID_LAYER))
        vertIdField = self.getParameterValue(self.VERT_ID_FIELD)
        stress = self.getParameterValue(self.STRESS)

        # build the output layer
        outFields = QgsFields()
        outFields.append(QgsField('grid_id', QVariant.Int))
        outFields.append(QgsField('status',QVariant.String))
        outFields.append(QgsField('free_cost', QVariant.Int))
        outFields.append(QgsField('cnst_cost', QVariant.Int))
        outFields.append(QgsField('cost_ratio', QVariant.Double))
        writer = self.getOutputFromName(self.OUTPUT_LAYER).getVectorWriter(
            outFields, QGis.WKBPolygon, roadsLayer.crs())
        progress.setPercentage(2)

        # establish db connection
        progress.setInfo('Getting DB connection')
        self.setDbFromRoadsLayer(roadsLayer)
        self.setLayersFromDb()

        # get network
        progress.setInfo('Building network')
        nu = NXUtils(self.vertsLayer,self.linksLayer)
        nu.buildNetwork()
        DG = nu.getNetwork()
        SG = nu.getStressNetwork(stress)
        progress.setPercentage(10)
        graphCosts = nx.get_edge_attributes(DG,'weight')

        #get grid feature and vert id
        progress.setText('Reading selected feature(s)')
        selectedGridFeatures = processing.features(gridLayer)
        if not len(selectedGridFeatures) == 1:
            raise GeoAlgorithmExecutionException('You must select one and only one feature in the grid layer')
        gridFeature = QgsFeature()
        for i, f in enumerate(selectedGridFeatures):
            gridFeature = f
        sourceVertId = gridFeature.attribute(vertIdField)

        #test for source feature not having any low stress connections
        if not SG.has_node(sourceVertId):
            raise GeoAlgorithmExecutionException('The selected grid cell has no low stress connections')

        #iterate grid features and compile scores
        progress.setText('Generating grid scores')
        #helper function to sum costs from graph
        def sumCosts(nodes,graphWeights):
            cost = 0
            del nodes[1]    #remove the source and target nodes from consideration
            del nodes[-1]
            for j, node in enumerate(nodes):
                    try:
                        cost = cost + graphCosts[(node,nodes[j+1])]
                    except:
                        pass
            return cost
        #gridProvider = grid.dataProvider()
        gridFeatures = gridLayer.getFeatures()
        for i, gf in enumerate(gridFeatures):
            targetVertId = gf.attribute(vertIdField)
            progress.setInfo('from: ' + str(sourceVertId) + ' to: ' + str(targetVertId))

            #write new feature
            progress.setText('Writing grid feature')
            newFeat = QgsFeature()
            newGeom = QgsGeometry(gf.geometry())
            newFeat.setGeometry(newGeom)
            newFeat.initAttributes(5)
            newFeat.setAttribute(0,gf.attribute(vertIdField))
            if targetVertId == sourceVertId:
                newFeat.setAttribute(1,'Source cell')
            elif not SG.has_node(targetVertId):
                newFeat.setAttribute(1,'Unreachable')
            elif not nx.has_path(SG,source=sourceVertId,target=targetVertId):
                newFeat.setAttribute(1,'Unreachable')
            else:
                #get shortest path without stress
                pathNoStress = nx.shortest_path(DG,source=sourceVertId,target=targetVertId,weight='weight')
                #get shortest path with stress
                pathStress = nx.shortest_path(SG,source=sourceVertId,target=targetVertId,weight='weight')
                #get cost values
                costNoStress = sumCosts(pathNoStress,graphCosts)
                costStress = sumCosts(pathStress,graphCosts)

                #add attributes
                newFeat.setAttribute(1,'Target cell')
                newFeat.setAttribute(2,costNoStress)
                newFeat.setAttribute(3,costStress)
                if costNoStress == 0:
                    pass
                else:
                    newFeat.setAttribute(4,float(costStress)/float(costNoStress))

            writer.addFeature(newFeat)

        del writer
