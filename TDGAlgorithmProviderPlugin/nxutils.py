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
from db_manager.db_plugins import createDbPlugin
from db_manager.db_plugins.plugin import DBPlugin, Schema, Table, BaseError

class NXUtils:
    def __init__(self, roadsLayer):
        # layers
        self.vertLayer = None
        self.linkLayer = None

        # db helpers
        roadsDb = LayerDbInfo(roadsLayer)
        dbConnName = roadsDb.getConnName()
        dbTable = roadsDb.getTable()
        dbSchema = roadsDb.getSchema()
        dbType = 'postgis'
        connection = None

        # get connection to db
        if dbConnName:
            dbPluginClass = createDbPlugin(dbType,dbConnName)
            if dbPluginClass:
                try:
                    connection = dbPluginClass.connect()
                except BaseError, e:
                    raise GeoAlgorithmExecutionException('Error connecting to \
                        database %s. Exception: %s' % (dbConnNamem, e))
            else:
                raise GeoAlgorithmExecutionException('Error connecting to \
                    database %s' % dbConnName)
        else:
            raise GeoAlgorithmExecutionException('Could not identify database \
                from layer %s' % roadsLayer.name())

        # get network layers
        if connection:
            db = dbPluginClass.database()
            if db:
                vertTable = dbTable + '_net_vert'
                linkTable = dbTable + '_net_link'

                self.vertLayer = db.toSqlLayer(
                    'SELECT * FROM %s.%s' % (dbSchema,vertTable),
                    'geom',
                    'vert_id',
                    roadsDb.getUniqueLayerName(vertTable),
                    QgsMapLayer.VectorLayer,
                    False
                )

                self.linkLayer = db.toSqlLayer(
                    'SELECT * FROM %s.%s' % (dbSchema,linkTable),
                    'geom',
                    'link_id',
                    roadsDb.getUniqueLayerName(linkTable),
                    QgsMapLayer.VectorLayer,
                    False
                )

                # raise error if couldn't load network tables
                if not (self.vertLayer.isValid() and self.linkLayer.isValid()):
                    raise GeoAlgorithmExecutionException('Could not load \
                        tables %s and %s. Check to make sure %s has a \
                        network built.' % (vertTable,linkTable,roadsLayer.name()))
            else:
                raise GeoAlgorithmExecutionException('Database not found \
                    for layer %s' % roadsLayer.name())
        else:
            raise GeoAlgorithmExecutionException('Error connecting to \
                database %s' % dbConnName)

        # other vars
        self.DG = nx.DiGraph()

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
            self.DG.add_edge(edges['source_vert'][i],
                        edges['target_vert'][i],
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
