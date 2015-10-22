# -*- coding: utf-8 -*-

"""
***************************************************************************
    TDGAlgorithm.py
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

from PyQt4.QtCore import QSettings
from qgis.core import *

import processing
from processing.core.GeoAlgorithm import GeoAlgorithm
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException

from processing.tools import dataobjects
from processing.algs.qgis import postgis_utils
from dbutils import LayerDbInfo

from db_manager.db_plugins import createDbPlugin
from db_manager.db_plugins.plugin import DBPlugin, Schema, Table, BaseError


class TDGAlgorithm(GeoAlgorithm):
    """This is an extension of the main processing geoalgorithm with some extra
    goodies thrown in related to TDG tools
    """

    roadsLayer = None
    roadsTable = None
    intsLayer = None
    intsTable = None
    vertsLayer = None
    vertsTable = None
    linksLayer = None
    linksTable = None
    dbConnection = None
    db = None
    schema = None


    # assign layers to the various TDG datasets using the roads layer as input
    def setLayersFromRoadsLayer(self,inRoadsLayer):
        if not self.db:
            GeoAlgorithmExecutionException('Connection to database not set for \
                layer %s' % inRoadsLayer.name())

        self.intsTable = self.roadsTable + '_intersections'
        self.vertsTable = self.roadsTable + '_net_vert'
        self.linksTable = self.roadsTable + '_net_link'

        self.intsLayer = db.toSqlLayer(
            'SELECT * FROM %s.%s' % (self.schema,intsTable),
            'geom',
            'int_id',
            roadsDb.getUniqueLayerName(intsTable),
            QgsMapLayer.VectorLayer,
            False
        )
        if not (self.intsLayer.isValid()):
            self.intsLayer = None

        self.vertsLayer = db.toSqlLayer(
            'SELECT * FROM %s.%s' % (self.schema,vertsTable),
            'geom',
            'vert_id',
            roadsDb.getUniqueLayerName(vertsTable),
            QgsMapLayer.VectorLayer,
            False
        )
        if not (self.vertsLayer.isValid()):
            self.vertsLayer = None

        self.linksLayer = db.toSqlLayer(
            'SELECT * FROM %s.%s' % (self.schema,linksTable),
            'geom',
            'link_id',
            roadsDb.getUniqueLayerName(linksTable),
            QgsMapLayer.VectorLayer,
            False
        )
        if not (self.linksLayer.isValid()):
            self.linksLayer = None


    # set the reference to the database
    def setDbFromRoadsLayer(self,inRoadsLayer):
        # db helpers
        roadsDb = LayerDbInfo(inRoadsLayer)
        dbConnName = roadsDb.getConnName()
        self.roadsTable = roadsDb.getTable()
        self.schema = roadsDb.getSchema()
        dbType = 'postgis'

        # get connection to db
        if dbConnName:
            dbPluginClass = createDbPlugin(dbType,dbConnName)
            if dbPluginClass:
                try:
                    self.dbConnection = dbPluginClass.connect()
                    self.db = dbPluginClass.database()
                except BaseError, e:
                    raise GeoAlgorithmExecutionException('Error connecting to \
                        database %s. Exception: %s' % (dbConnName, str(e)))
            else:
                raise GeoAlgorithmExecutionException('Error connecting to \
                    database %s' % dbConnName)
        else:
            raise GeoAlgorithmExecutionException('Could not identify database \
                from layer %s' % roadsLayer.name())


    def getUniqueLayerName(self,baseName):
        names = []
        for layer in QgsMapLayerRegistry.instance().mapLayers().values():
            names.append( layer.name() )

        newLayerName = str(baseName)
        i = 0
        while newLayerName in names:
            i+=1
            newLayerName = u"%s_%d" % (baseName, i)

        return newLayerName


    # execute a sql query on the database
    def executeSql(self,sql):
        pass


    # add roads layer to map with styling
    def addRoadsToMap(self):
        pass


    # add intersections layer to map with styling
    def addIntsToMap(self):
        pass


    # add vertices layer to map with styling
    def addVertsToMap(self):
        pass


    # add links layer to map with styling
    def addLinksToMap(self):
        pass
