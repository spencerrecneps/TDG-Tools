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

import re
from qgis.core import *
from dbutils import LayerDbInfo, isDbTable
from processing.tools import vector
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException

class NXUtils:
    def __init__(self, roadsLayer):
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

        if isNetwork():  # need to test for existence of network layers
            pass
        else:
            raise GeoAlgorithmExecutionException('No network layer found for \
                    table %s' % dbTable)

        # create verts layer
        uri = QgsDataSourceURI()
        self.vertTable = dbTable + '_net_vert'
        uri.setConnection(dbHost,str(dbPort),dbName,dbUser,dbPass)
        uri.setDataSource(schema,self.vertTable,'geom','','vert_id')
        uri.setWkbType(QGis.WKBPoint)
        self.vertLayer = QgsVectorLayer(uri.uri(),self.vertTable,'postgres')

        # create links layer
        self.linkTable = dbTable + '_net_link'
        uri.setConnection(dbHost,str(dbPort),dbName,dbUser,dbPass)
        uri.setDataSource(schema,self.linkTable,'geom','','link_id')
        uri.setWkbType(QGis.WKBLineString)
        self.linkLayer = QgsVectorLayer(uri.uri(),self.linkTable,'postgres')

        # other vars
        self.DG = nx.DiGraph()


    def isNetwork(self):
        return t

    def buildNetwork(self):
        # edges
        progress.setInfo('Adding edges')
        for edge in vector.values(self.linkLayer,
                                'source_vert',
                                'target_vert',
                                'link_cost',
                                'link_id',
                                'link_stress',
                                'road_id'):
            self.DG.add_edge(edge['source_vert'],
                        edge['target_vert'],
                        weight=max(edge['link_cost'],0),
                        link_id=edge['link_id'],
                        stress=min(edge['link_stress'],99),
                        road_id=edge['road_id'])

        # vertices
        progress.setInfo('Adding vertices')
        for vert in vector.values(self.vertLayer,
                                'vert_id',
                                'vert_cost',
                                'int_id'):
            vid = vert['vert_id']
            self.DG.node[vid]['weight'] = max(vert['vert_cost'],0)
            self.DG.node[vid]['int_id'] = vert['int_id']

    def getNetwork(self):
        return self.DG
