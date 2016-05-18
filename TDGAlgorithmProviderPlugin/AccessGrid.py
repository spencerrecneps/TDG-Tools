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
    GRID_LAYER = 'GRID_LAYER'
    VERT_ID_FIELD = 'VERT_ID_FIELD'
    BUDGET = 'BUDGET'
    STRESS = 'STRESS'
    OUT_LAYER = 'OUT_LAYER'


    def help(self):
        html = markdown2.markdown_path(os.path.join(self.helpPath,'Calculate Travel Shed.md'))
        return True, html


    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Travel sheds'

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
                [ParameterVector.VECTOR_TYPE_POLYGON],
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

        # Max travel budget
        self.addParameter(
            ParameterNumber(
                self.BUDGET,
                self.tr('Maximum travel budget (in cost units)'),
                minValue=0
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


        # Output raw layer
        self.addOutput(
            OutputVector(self.OUT_LAYER, self.tr('Output'))
        )


    def processAlgorithm(self, progress):
        progress.setPercentage(0)
        # Retrieve the values of the parameters entered by the user
        inLayer = dataobjects.getObjectFromUri(
            self.getParameterValue(self.ROADS_LAYER))
        gridLayer = dataobjects.getObjectFromUri(
            self.getParameterValue(self.GRID_LAYER))
        vertIdField = self.getParameterValue(self.VERT_ID_FIELD)
        stress = self.getParameterValue(self.STRESS)
        budget = self.getParameterValue(self.BUDGET)

        # build the output layer
        gridFields = QgsFields(gridLayer.fields())
        gridFields.append(QgsField('count', QVariant.Int))
        polyWriter = self.getOutputFromName(self.OUT_LAYER).getVectorWriter(
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
        progress.setPercentage(10)

        # read input stress
        if not stress:
            stress = 99

        # Get vertex IDs from input layer
        progress.setInfo('Getting input vertex IDs')
        vertIds = []
        for val in vector.values(gridLayer,vertIdField)[vertIdField]:
            if val.is_integer():
                vertIds.append(int(val))
            else:
                raise GeoAlgorithmExecutionException(
                    self.tr('Bad vert_id values. Input field was %s. Check that \
                        these are integer values.' % vertIdField))

        # loop through the point features and generate travel sheds for each
        count = 0
        totalCount = len(vertIds)
        for feat in vector.features(gridLayer):
            outFeat = QgsFeature()


        for vertId in vertIds:
            outPolyFeat = QgsFeature(gridFields)
            outPolyFeat.setAttribute(0,vertId)
            outPolyGeom = QgsGeometry()
            count += 1
            progress.setPercentage(10+int(90*count/totalCount))
            hull = []

            paths = nx.single_source_dijkstra(
                DG,
                vertId,
                cutoff=budget,
                weight='weight'
            )

            # build the convex hull around the travel shed
            vertFeats = vector.features(self.vertsLayer)
            for f in vertFeats:
                if f['vert_id'] in paths[0].keys():
                    inGeom = QgsGeometry(f.geometry())
                    hull.extend(vector.extractPoints(inGeom))

            if len(hull) >= 3:
                try:
                    tmpGeom = QgsGeometry(outPolyGeom.fromMultiPoint(hull))
                    outPolyGeom = tmpGeom.convexHull()
                    outPolyFeat.setGeometry(outPolyGeom)
                    polyWriter.addFeature(outPolyFeat)
                except Exception, e:
                    raise GeoAlgorithmExecutionException(
                        'Exception while processing geometries: ' + str(e))

            # build the road path around each travel shed
            roadIds = set()
            for v, path in paths[1].iteritems():
                for i, v1 in enumerate(path):
                    if i == 0:
                        pass
                    elif i == len(path) - 1:
                        pass
                    else:
                        v2 = path[i+1]
                        roadId = DG.edge[v1][v2]['road_id']
                        if roadId:
                            roadIds.add(roadId)

            for f in vector.features(self.roadsLayer):
                roadId = f['road_id']
                if roadId in roadIds:
                    try:
                        routeFeat = QgsFeature(routeFields)
                        routeFeat.setAttribute(0,vertId)
                        routeFeat.setAttribute(1,roadId)
                        routeFeat.setGeometry(QgsGeometry(f.geometry()))
                        routeWriter.addFeature(routeFeat)
                    except Exception, e:
                        raise GeoAlgorithmExecutionException(
                            'Exception while processing geometries: ' + str(e))

        del polyWriter
        del routeWriter
