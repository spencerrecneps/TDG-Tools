# -*- coding: utf-8 -*-

"""
***************************************************************************
    CalculateStress.py
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

from PyQt4.QtCore import QSettings, QVariant
from qgis.core import QgsDataSourceURI, QgsVectorLayerImport, QGis, QgsFeature, QgsGeometry

import processing
from processing.core.GeoAlgorithm import GeoAlgorithm
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterBoolean

from processing.tools import dataobjects
from processing.algs.qgis import postgis_utils
from dbutils import LayerDbInfo


class CalculateStress(GeoAlgorithm):
    """This algorithm takes an input road dataset and calculates
    the traffic stress
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    ROADS_LAYER = 'ROADS_LAYER'
    SEGMENT = 'SEGMENT'
    APPROACH = 'APPROACH'
    CROSS = 'CROSS'

    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Calculate traffic stress'

        # The branch of the toolbox under which the algorithm will appear
        #self.group = 'Algorithms for vector layers'
        self.group = 'Traffic Stress'

        # Input roads layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.ROADS_LAYER,
            self.tr('Standardized TDG roads layer'), [ParameterVector.VECTOR_TYPE_LINE], optional=False))

        # Should stress be calculated for the segment?
        self.addParameter(ParameterBoolean(self.SEGMENT,
            self.tr('Calculate for segments'), default=True))

        # Should stress be calculated for the approaches?
        self.addParameter(ParameterBoolean(self.APPROACH,
            self.tr('Calculate for approaches'), default=True))

        # Should stress be calculated for the segment?
        self.addParameter(ParameterBoolean(self.CROSS,
            self.tr('Calculate for crossings'), default=True))


    def processAlgorithm(self, progress):
        # Retrieve the values of the parameters entered by the user
        inLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.ROADS_LAYER))

        # establish db connection
        roadsDb = LayerDbInfo(inLayer.source())
        dbHost = roadsDb.getHost()
        dbPort = roadsDb.getPort()
        dbName = roadsDb.getDBName()
        dbUser = roadsDb.getUser()
        dbPass = roadsDb.getPassword()
        dbSchema = roadsDb.getSchema()
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

        sql = 'select tdgCalculateStress('
        sql = sql + "'" + roadsDb.getTable() + "'"
        if self.SEGMENT:
            sql = sql + ",'t'"
        else:
            sql = sql + ",'f'"
        if self.APPROACH:
            sql = sql + ",'t'"
        else:
            sql = sql + ",'f'"
        if self.CROSS:
            sql = sql + ",'t'"
        else:
            sql = sql + ",'f'"
        sql = sql + ");"

        #processing.runalg("qgis:postgisexecutesql",dbName,sql)
        progress.setInfo('Calculating stress scores')
        try:
            db._exec_sql_and_commit(sql)
        except:
            raise
