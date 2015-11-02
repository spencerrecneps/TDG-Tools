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

class ShortestPathFromLayer(TDGAlgorithm):
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
    KEEP_RAW = 'KEEP_RAW'
    RAW_LAYER = 'RAW_LAYER'
    KEEP_ROUTES = 'KEEP_ROUTES'
    ROUTES_LAYER = 'ROUTES_LAYER'
    KEEP_SUMS = 'KEEP_SUMS'
    SUMS_LAYER = 'SUMS_LAYER'


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
                self.DESTINATIONS_LAYER,
                self.tr('Destinations layer (must have vertex IDs)'),
                [ParameterVector.VECTOR_TYPE_POINT],
                optional=False
            )
        )

        # Field with vertex IDs
        # Required
        self.addParameter(
            ParameterTableField(
                self.VERT_ID_FIELD,
                self.tr('Field containing the network vertex IDs'),
                parent=self.DESTINATIONS_LAYER,
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

        # Keep raw layer?
        self.addParameter(
            ParameterBoolean(
                self.KEEP_RAW,
                self.tr('Keep raw shortest path layer?'), default=True
            )
        )

        # Output raw layer
        self.addOutput(
            OutputVector(self.RAW_LAYER, self.tr('Raw shortest path layer'))
        )

        # Keep routes layer?
        self.addParameter(
            ParameterBoolean(
                self.KEEP_ROUTES,
                self.tr('Keep shortest path routes layer?'), default=True
            )
        )

        # Output routes layer
        self.addOutput(
            OutputVector(self.ROUTES_LAYER, self.tr('Shortest path routes layer'))
        )

        # Keep sum layer?
        self.addParameter(
            ParameterBoolean(
                self.KEEP_SUMS,
                self.tr('Keep path summary layer?'), default=True
            )
        )

        # Output sum layer
        self.addOutput(
            OutputVector(self.SUMS_LAYER, self.tr('Shortest path summary layer'))
        )


    def processAlgorithm(self, progress):
        progress.setPercentage(0)
        # Retrieve the values of the parameters entered by the user
        roadsLayer = dataobjects.getObjectFromUri(
            self.getParameterValue(self.ROADS_LAYER))
        destsLayer = dataobjects.getObjectFromUri(
            self.getParameterValue(self.DESTINATIONS_LAYER))
        vertIdField = self.getParameterValue(self.VERT_ID_FIELD)
        stress = self.getParameterValue(self.STRESS)
        keepRaw = self.getParameterValue(self.KEEP_RAW)
        keepRoutes = self.getParameterValue(self.KEEP_ROUTES)
        keepSums = self.getParameterValue(self.KEEP_SUMS)

        # build the raw output layer
        if keepRaw:
            rawFields = QgsFields()
            rawFields.append(QgsField('path_id', QVariant.Int))
            rawFields.append(QgsField('sequence', QVariant.Int))
            rawFields.append(QgsField('from_vert', QVariant.Int))
            rawFields.append(QgsField('to_vert', QVariant.Int))
            rawFields.append(QgsField('int_id', QVariant.Int))
            rawFields.append(QgsField('int_cost', QVariant.Int))
            rawFields.append(QgsField('road_id', QVariant.Int))
            rawFields.append(QgsField('road_cost', QVariant.Int))
            rawFields.append(QgsField('cmtve_cost', QVariant.Int))
            rawWriter = self.getOutputFromName(self.RAW_LAYER).getVectorWriter(
                rawFields, QGis.WKBLineString, roadsLayer.crs())
        if keepRoutes:
            routeFields = QgsFields()
            routeFields.append(QgsField('path_id', QVariant.Int))
            routeFields.append(QgsField('from_vert', QVariant.Int))
            routeFields.append(QgsField('to_vert', QVariant.Int))
            routeFields.append(QgsField('cmtve_cost', QVariant.Int))
            routeWriter = self.getOutputFromName(self.ROUTES_LAYER).getVectorWriter(
                routeFields, QGis.WKBLineString, roadsLayer.crs())
        if keepSums:
            sumFields = QgsFields()
            sumFields.append(QgsField('road_id', QVariant.Int))
            sumFields.append(QgsField('use_count', QVariant.Int))
            sumWriter = self.getOutputFromName(self.SUMS_LAYER).getVectorWriter(
                sumFields, QGis.WKBLineString, roadsLayer.crs())
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
        progress.setPercentage(10)

        # read input stress
        if not stress:
            stress = 99

        # Get vertex IDs from input layer
        progress.setInfo('Getting vertex IDs')
        vertIds = []
        for val in vector.values(destsLayer,vertIdField)[vertIdField]:
            if val.is_integer():
                vertIds.append(int(val))
            else:
                raise GeoAlgorithmExecutionException(
                    self.tr('Bad vert_id values. Input field was %s. Check that \
                        these are integer values.' % vertIdField))

        # count pairs
        vertPairCount = len(vertIds) ** 2 - len(vertIds)
        progress.setInfo('%i total destination pairs identified' % vertPairCount)

        # set up dictionary of road_ids with their geoms
        roads = dict()
        for feat in vector.features(roadsLayer):
            g = QgsGeometry(feat.geometry())
            f = QgsFeature(sumFields)
            f.setGeometry(g)
            f.setAttribute(0,feat['road_id'])
            roads[feat['road_id']] = {'geom': g, 'count': 0, 'feat': f}

        # loop through each destination and get shortest routes to all others
        try:
            rowCount = 0
            pairCount = 0
            for fromVert in vertIds:
                for toVert in vertIds:
                    if not fromVert == toVert:
                        # set counts
                        pairCount += 1
                        seq = 0
                        cost = 0
                        if pairCount % 1000 == 0:
                            progress.setInfo('Shortest path for pair %i of %i'
                                    % (pairCount, vertPairCount))

                        # set feature for route output
                        routeFeat = None
                        if keepRoutes:
                            routeFeat = QgsFeature(routeFields)
                            routeFeat.setAttribute(0,pairCount) #path_id
                            routeFeat.setAttribute(1,fromVert) #from_vert
                            routeFeat.setAttribute(2,toVert) #to_vert

                        # check the path and iterate through it
                        if nx.has_path(DG,source=fromVert,target=toVert):
                            shortestPath = nx.shortest_path(DG,
                                                            source=fromVert,
                                                            target=toVert,
                                                            weight='weight')
                            for i, v1 in enumerate(shortestPath):
                                if i == 0:
                                    pass  #leave out because this is the start vertex
                                elif i == len(shortestPath) - 1:
                                    pass  #Leave out because this is the last vertex
                                else:
                                    rowCount += 1
                                    v2 = shortestPath[i+1]
                                    roadId = DG.edge[v1][v2]['road_id']
                                    if not roadId:
                                        continue       #skip if this isn't a road link
                                    seq += 1
                                    roads[roadId]['count'] += 1
                                    v3 = None
                                    if i < len(shortestPath) - 2:
                                        v3 = shortestPath[i+2]

                                    # set costs
                                    linkCost = DG.edge[v1][v2]['weight']
                                    intCost = 0
                                    if v3 and not DG.edge[v2][v3]['road_id']:
                                        intCost = DG.edge[v2][v3]['weight']
                                    cost += linkCost
                                    cost += intCost

                                    # create the new features
                                    if roadId in roads and roads.get(roadId).get('geom'):
                                        geom = roads.get(roadId).get('geom')
                                        if keepRaw:
                                            rawFeat = QgsFeature(rawFields)
                                            rawFeat.setAttribute(0,pairCount) #path_id
                                            rawFeat.setAttribute(1,seq) #sequence
                                            rawFeat.setAttribute(2,fromVert) #from_vert
                                            rawFeat.setAttribute(3,toVert) #to_vert
                                            rawFeat.setAttribute(4,DG.node[v2]['int_id']) #int_id
                                            rawFeat.setAttribute(5,intCost) #int_cost
                                            rawFeat.setAttribute(6,roadId) #road_id
                                            rawFeat.setAttribute(7,linkCost) #road_cost
                                            rawFeat.setAttribute(8,cost) #cmtve_cost
                                            rawFeat.setGeometry(geom)
                                            rawWriter.addFeature(rawFeat)
                                            del rawFeat
                                        if keepRoutes:
                                            routeFeat.setAttribute(3,cost) #cmtve_cost
                                            if not routeFeat.constGeometry():
                                                routeFeat.setGeometry(geom)
                                            else:
                                                routeFeat.setGeometry(
                                                    geom.combine(routeFeat.constGeometry())
                                                )
                                            routeWriter.addFeature(routeFeat)
                                        if keepSums:
                                            sumFeat = roads.get(roadId).get('feat')
                                            useCount = roads.get(roadId).get('count')
                                            sumFeat.setAttribute(1,useCount) #use_count

                        del routeFeat
                        progress.setPercentage(10 + 90*pairCount/vertPairCount)

            for roadId, r in roads.iteritems():
                if r.get('count') > 0:
                    sumWriter.addFeature(r.get('feat'))

        except Exception, e:
            raise GeoAlgorithmExecutionException('Uncaught error: %s' % e)

        del rawWriter
        del routeWriter
        del sumWriter
