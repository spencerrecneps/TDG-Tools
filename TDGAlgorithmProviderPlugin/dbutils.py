# -*- coding: utf-8 -*-

"""
***************************************************************************
    dbutils.py
    ---------------------
    Date                 : July 2015
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
__date__ = 'July 2013'
__copyright__ = '(C) 2015, Spencer Gardner'

# This will get replaced with a git SHA1 when you do a git archive

__revision__ = '$Format:%H$'

import re
from PyQt4.QtCore import QSettings
from qgis.core import *
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException


def isDbTable(tableName):
    pass

class LayerDbInfo:
    def __init__(self, layer):
        self.connName = None
        self.dbName = None
        self.schemaName = None
        self.tableName = None
        self.key = None
        self.user = None
        self.password = None
        self.srid = None
        self.type = None
        self.host = None
        self.port = None

        # test for postgis and get the provider
        if not layer.providerType() == 'postgres':
            raise GeoAlgorithmExecutionException('Layer %s does not \
                    come from a PostGIS table' % layer.name())
        provider = layer.dataProvider()

        # parse the table details
        vals = dict(re.findall('(\S+)="?(.*?)"? ',provider.dataSourceUri()))
        self.dbName = str(vals['dbname']).strip("'")
        self.key = str(vals['key']).strip("'")
        self.srid = int(provider.crs().postgisSrid())
        try:
            self.type = str(vals['type'])
        except:
            pass
        table = vals['table'].split('.')
        self.schemaName = table[0].strip('"')
        self.tableName = table[1].strip('"')

        if not self.dbName:
            raise GeoAlgorithmExecutionException('There was a problem \
                    retrieving database information for layer %s' % l.name())

        # get db details by
        # searching qgis db connections for a match to the layer
        settings = QSettings()
        settings.beginGroup('/PostgreSQL/connections/')
        try:
            for conn in settings.childGroups():
                if settings.value(conn + '/database') == self.dbName:
                    self.connName = conn
                    self.user = settings.value(conn + '/username')
                    self.host = settings.value(conn + '/host')
                    self.password = settings.value(conn + '/password')
                    self.port = int(settings.value(conn + '/port'))
        except Exception, e:
            raise GeoAlgorithmExecutionException('Unspecified error reading \
                    database connections: %s' % e)

        if not self.connName:
            raise GeoAlgorithmExecutionException('No stored database connection \
                    identified for layer %s' % layer.name())

    def getConnName(self):
        return self.connName

    def getDBName(self):
        return self.dbName

    def getHost(self):
        return self.host

    def getPort(self):
        return self.port

    def getKey(self):
        return self.key

    def getUser(self):
        return self.user

    def getPassword(self):
        return self.password

    def getSRID(self):
        return self.srid

    def getType(self):
        return self.type

    def getSchema(self):
        return self.schemaName

    def getTable(self):
        return self.tableName
