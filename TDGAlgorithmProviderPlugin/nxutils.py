# -*- coding: utf-8 -*-

"""
***************************************************************************
    dbutils.py
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

import networkx as nx
import re
from qgis.core import *
from dbutils import LayerDbInfo, isDbTable
from processing.tools import vector
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException

class NXUtils:
    def __init__(self, roadsLayer):
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

        if self.isNetwork():  # need to test for existence of network layers
            pass
        else:
            raise GeoAlgorithmExecutionException('No network layer found for \
                    table %s' % dbTable)

        # create verts layer
        uri = QgsDataSourceURI()
        self.vertTable = dbTable + '_net_vert'
        uri.setConnection(dbHost,str(dbPort),dbName,dbUser,dbPass)
        uri.setDataSource(dbSchema,self.vertTable,'geom','','vert_id')
        uri.setWkbType(QGis.WKBPoint)
        self.vertLayer = QgsVectorLayer(uri.uri(),self.vertTable,'postgres')

        # create links layer
        self.linkTable = dbTable + '_net_link'
        uri.setConnection(dbHost,str(dbPort),dbName,dbUser,dbPass)
        uri.setDataSource(dbSchema,self.linkTable,'geom','','link_id')
        uri.setWkbType(QGis.WKBLineString)
        self.linkLayer = QgsVectorLayer(uri.uri(),self.linkTable,'postgres')

        # other vars
        self.DG = nx.DiGraph()


    def isNetwork(self):
        return True

    def buildNetwork(self):
        # edges
        edges = vector.values(self.linkLayer,
                                'source_vert',
                                'target_vert',
                                'link_cost',
                                'link_id',
                                'link_stress',
                                'road_id')
        edgeCount = len(edges['link_id'])
        for i in range(edgeCount):
            self.DG.add_edge(int(edges['source_vert'][i]),
                        int(edges['target_vert'][i]),
                        weight=max(edges['link_cost'][i],0),
                        link_id=edges['link_id'][i],
                        stress=min(edges['link_stress'][i],99),
                        road_id=edges['road_id'][i])

        # vertices
        verts = vector.values(self.vertLayer,
                                'vert_id',
                                'vert_cost',
                                'int_id')
        vertCount = len(verts['vert_id'])
        for i in range(vertCount):
            vid = verts['vert_id'][i]
            self.DG.node[vid]['weight'] = max(verts['vert_cost'][i],0)
            self.DG.node[vid]['int_id'] = verts['int_id'][i]

    def getNetwork(self):
        return self.DG

    def getVertLayer(self):
        return self.vertLayer

    def getLinkLayer(self):
        return self.linkLayer
