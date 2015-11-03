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
#from processing.algs.qgis import postgis_utils

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
    dbConnName = None
    dbPluginClass = None
    dbConnection = None
    db = None
    schema = None
#db.connector.connection.notices

    # set the reference to the database
    def setDbFromLayer(self,inLayer):
        # db helpers
        self.setDbConnName(inLayer)
        dbType = 'postgis'

        # get connection to db
        if self.dbConnName:
            self.dbPluginClass = createDbPlugin(dbType,self.dbConnName)
            if self.dbPluginClass:
                try:
                    self.dbConnection = self.dbPluginClass.connect()
                    self.db = self.dbPluginClass.database()
                except BaseError, e:
                    raise GeoAlgorithmExecutionException('Error connecting to \
                        database %s. Exception: %s' % (self.dbConnName, str(e)))
            else:
                raise GeoAlgorithmExecutionException('Error connecting to \
                    database %s' % self.dbConnName)
        else:
            raise GeoAlgorithmExecutionException('Could not identify database \
                from layer %s' % inLayer.name())


    # set the reference to the database
    def setDbFromRoadsLayer(self,inRoadsLayer):
        # db helpers
        uri = QgsDataSourceURI(inRoadsLayer.source())
        self.roadsTable = uri.table()
        self.schema = uri.schema()
        self.roadsLayer = inRoadsLayer
        self.setDbFromLayer(inRoadsLayer)


    # assign layers to the various TDG datasets using the roads layer as input
    def setLayersFromDb(self):
        if not self.db:
            GeoAlgorithmExecutionException('Connection to database not set')

        self.intsTable = self.roadsTable + '_intersections'
        self.vertsTable = self.roadsTable + '_net_vert'
        self.linksTable = self.roadsTable + '_net_link'

        self.intsLayer = self.db.toSqlLayer(
            'SELECT * FROM %s.%s' % (self.schema,self.intsTable),
            'geom',
            'int_id',
            self.getUniqueLayerName(self.intsTable),
            QgsMapLayer.VectorLayer,
            False
        )
        if not (self.intsLayer.isValid()):
            self.intsLayer = None

        self.vertsLayer = self.db.toSqlLayer(
            'SELECT * FROM %s.%s' % (self.schema,self.vertsTable),
            'geom',
            'vert_id',
            self.getUniqueLayerName(self.vertsTable),
            QgsMapLayer.VectorLayer,
            False
        )
        if not (self.vertsLayer.isValid()):
            self.vertsLayer = None

        self.linksLayer = self.db.toSqlLayer(
            'SELECT * FROM %s.%s' % (self.schema,self.linksTable),
            'geom',
            'link_id',
            self.getUniqueLayerName(self.linksTable),
            QgsMapLayer.VectorLayer,
            False
        )
        if not (self.linksLayer.isValid()):
            self.linksLayer = None


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


    def setDbConnName(self,inLayer):
        # get db details by
        # searching qgis db connections for a match to the layer
        if not inLayer.providerType() == u'postgres':
            raise GeoAlgorithmExecutionException('Layer %s is not stored in a PostGIS database' % inLayer.name())

        # get the name of the db from the uri
        uri = QgsDataSourceURI(inLayer.source())
        dbName = uri.database()

        settings = QSettings()
        settings.beginGroup('/PostgreSQL/connections/')
        try:
            for conn in settings.childGroups():
                if settings.value(conn + '/database') == dbName:
                    self.dbConnName = conn
        except Exception, e:
            raise GeoAlgorithmExecutionException('Unspecified error reading \
                    database connections: %s' % e)

        if not self.dbConnName:
            raise GeoAlgorithmExecutionException('No stored database connection \
                    identified for layer %s' % inLayer.name())


    def setRoadsLayer(self,inLayer):
        self.roadsLayer = inLayer

    # add roads layer to map with styling
    def addRoadsToMap(self):
        QgsMapLayerRegistry.instance().addMapLayer(self.roadsLayer)


    # add intersections layer to map with styling
    def addIntsToMap(self):
        QgsMapLayerRegistry.instance().addMapLayer(self.intsLayer)


    # add vertices layer to map with styling
    def addVertsToMap(self):
        QgsMapLayerRegistry.instance().addMapLayer(self.vertsLayer)


    # add links layer to map with styling
    def addLinksToMap(self):
        QgsMapLayerRegistry.instance().addMapLayer(self.linksLayer)
