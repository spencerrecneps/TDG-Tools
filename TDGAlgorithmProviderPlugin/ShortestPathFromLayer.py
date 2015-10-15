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
from processing.core.GeoAlgorithm import GeoAlgorithm
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterString
from processing.core.parameters import ParameterNumber
from processing.core.parameters import ParameterTableField
from processing.core.parameters import ParameterSelection
from processing.core.outputs import OutputVector

from processing.tools import dataobjects, vector
from processing.algs.qgis import postgis_utils
from dbutils import LayerDbInfo
from nxutils import NXUtils

import networkx as nx

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
    OUT_LAYER = 'OUT_LAYER'


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

        # Output layer
        self.addOutput(OutputVector(self.OUT_LAYER, self.tr('Shortest paths')))


    def processAlgorithm(self, progress):
        progress.setPercentage(0)
        # Retrieve the values of the parameters entered by the user
        roadsLayer = dataobjects.getObjectFromUri(
            self.getParameterValue(self.ROADS_LAYER))
        destsLayer = dataobjects.getObjectFromUri(
            self.getParameterValue(self.DESTINATIONS_LAYER))
        vertIdField = self.getParameterValue(self.VERT_ID_FIELD)
        stress = self.getParameterValue(self.STRESS)

        # build the output layer
        fields = QgsFields()
        fields.append(QgsField('path_id', QVariant.Int))
        fields.append(QgsField('from_vert', QVariant.Int))
        fields.append(QgsField('to_vert', QVariant.Int))
        fields.append(QgsField('sequence', QVariant.Int))
        fields.append(QgsField('int_id', QVariant.Int))
        fields.append(QgsField('int_cost', QVariant.Int))
        fields.append(QgsField('road_id', QVariant.Int))
        fields.append(QgsField('road_cost', QVariant.Int))
        fields.append(QgsField('cmtve_cost', QVariant.Int))
        writer = self.getOutputFromName(self.OUT_LAYER).getVectorWriter(
            fields, QGis.WKBLineString, roadsLayer.crs())
        progress.setPercentage(2)

        # establish db connection
        roadsDb = LayerDbInfo(roadsLayer)
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
        progress.setPercentage(3)

        # get network
        progress.setInfo('Building network')
        nu = NXUtils(roadsLayer)
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
            roads[feat['road_id']] = feat.geometry()

        # loop through each destination and get shortest routes to all others
        count = 0
        for fromVert in vertIds:
            for toVert in vertIds:
                if not fromVert == toVert:
                    count = count + 1
                    if count % 1000 == 0:
                        progress.setInfo('Shortest path for pair %i of %i'
                                % (count, vertPairCount))
                    if nx.has_path(DG,source=fromVert,target=toVert):
                        shortestPath = nx.shortest_path(DG,
                                                        source=fromVert,
                                                        target=toVert,
                                                        weight='weight')
                        seq = 0
                        cost = 0
                        for i, v1 in enumerate(shortestPath):
                            if i == 0:
                                pass  #leave out because this is the start vertex
                            elif i < len(shortestPath) - 1:
                                v2 = shortestPath[i+1]
                                seq += 1
                                cost += DG.edge[v1][v2]['weight']
                                cost += DG.node[v2]['weight']

                                # create the new feature
                                f = QgsFeature(fields)
                                f.setAttribute(0,count) #path_id
                                f.setAttribute(1,fromVert) #from_vert
                                f.setAttribute(2,toVert) #to_vert
                                f.setAttribute(3,seq) #sequence
                                f.setAttribute(4,DG.node[v2]['int_id']) #int_id
                                f.setAttribute(5,DG.node[v2]['weight']) #int_cost
                                f.setAttribute(6,DG.edge[v1][v2]['road_id']) #road_id
                                f.setAttribute(7,DG.edge[v1][v2]['weight']) #road_cost
                                f.setAttribute(8,cost) #cmtve_cost
                                f.setGeometry(roads[DG.edge[v1][v2]['road_id']])

                                # NEED TO ADD ATTRIBUTES TO NEW FEATURE AND THEN
                                writer.addFeature(f)
                            # leave the last item out because it's the end vertex

                    progress.setPercentage(90*count/vertPairCount)
        del writer
