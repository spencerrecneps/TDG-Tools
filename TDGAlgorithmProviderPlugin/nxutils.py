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
from qgis.core import *
from processing.tools import vector
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException

class NXUtils:
    def __init__(self, vertsLayer, linksLayer):
        # layers
        self.vertsLayer = vertsLayer
        self.linksLayer = linksLayer
        if self.vertsLayer is None or self.linksLayer is None:
            raise GeoAlgorithmExecutionException('Could not identify \
                vertex and link layers. Were network tables created in PostGIS?')

        # other vars
        self.DG = nx.DiGraph()

    def buildNetwork(self):
        # edges
        edges = vector.values(self.linksLayer,
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
        verts = vector.values(self.vertsLayer,
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

    def getStressNetwork(self,stress):
        SG = nx.DiGraph()
        SG = nx.DiGraph( [ (u,v,d) for u,v,d in self.DG.edges(data=True) if d['stress'] <= stress ] )
        for v in SG.nodes():
            SG.node[v]['weight'] = self.DG.node[v].get('weight')
            SG.node[v]['int_id'] = self.DG.node[v].get('int_id')
        return SG
