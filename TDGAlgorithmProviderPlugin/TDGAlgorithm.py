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
    srid = None

    SCHEMA_NAMES = ['generated','received','scratch']

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
        self.srid = str(inRoadsLayer.crs().postgisSrid())
        self.roadsLayer = inRoadsLayer
        self.setDbFromLayer(inRoadsLayer)


    # assign layers to the various TDG datasets using the roads layer as input
    def setLayersFromDb(self):
        if not self.db:
            raise GeoAlgorithmExecutionException('Connection to database not set')

        if self.roadsTable is None:
            raise GeoAlgorithmExecutionException('Roads table not set in database')

        self.intsTable = self.roadsTable + '_intersections'
        self.vertsTable = self.roadsTable + '_net_vert'
        self.linksTable = self.roadsTable + '_net_link'

        self.intsLayer = self.setLayer(self.intsTable,'int_id',QGis.WKBPoint)
        self.vertsLayer = self.setLayer(self.vertsTable,'vert_id',QGis.WKBPoint)
        self.linksLayer = self.setLayer(self.linksTable,'link_id',QGis.WKBLineString)


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

    def setLayer(self,table,keyCol,geomType=None):
        if self.schema is None:
            return
        if self.db is None:
            return
        uri = QgsDataSourceURI(self.db.uri())
        uri.setDataSource(self.schema,table,'geom','',keyCol)
        if geomType:
            uri.setWkbType(geomType)
        uri.setSrid(self.srid)

        layerName = self.getUniqueLayerName(table)
        return QgsVectorLayer(uri.uri(), layerName, 'postgres')

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

    # check that a crs is a standard postgis authid
    def getValidCrs(self,constructor):
        crs = QgsCoordinateReferenceSystem()
        crs.createFromUserInput(constructor)
        pgSrid = crs.postgisSrid()
        if pgSrid == 0:
            raise GeoAlgorithmExecutionException('The selected coordinate system \
                cannot be used in the PostGIS database. Please select a different \
                projection. Hint: any projection with an EPSG code should work.')
        if not crs.mapUnits() == QGis.Feet:
            raise GeoAlgorithmExecutionException('The units of the selected \
                coordinate system are not in feet. TDG Tools requires a feet-based \
                system. Please select a different projection.')
        return crs
