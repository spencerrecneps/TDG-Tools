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

def isDbTable(tableName):
    pass

class LayerDbInfo:
    def __init__(self, layerInfo):
        if layerInfo[:6] == 'dbname':
            layerInfo = layerInfo.replace('\'','"')
            vals = dict(re.findall('(\S+)="?(.*?)"? ',layerInfo))
            self.dbName = str(vals['dbname'])
            self.key = str(vals['key'])
            self.user = str(vals['user'])
            self.password = str(vals['password'])
            self.srid = int(vals['srid'])
            self.type = str(vals['type'])
            self.host = str(vals['host'])
            self.port = int(vals['port'])

            # need some extra processing to get table name and schema
            table = vals['table'].split('.')
            self.schemaName = table[0].strip('"')
            self.tableName = table[1].strip('"')
        else:
            raise

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
