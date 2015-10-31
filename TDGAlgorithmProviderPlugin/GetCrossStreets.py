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

from TDGAlgorithm import TDGAlgorithm
import processing
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterBoolean
from processing.tools import dataobjects


class GetCrossStreets(TDGAlgorithm):
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
        self.name = 'Set Cross Street Data'

        # The branch of the toolbox under which the algorithm will appear
        #self.group = 'Algorithms for vector layers'
        self.group = 'Data Management'

        # Input roads layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.ROADS_LAYER,
            self.tr('Standardized TDG roads layer'), [ParameterVector.VECTOR_TYPE_LINE], optional=False))


    def processAlgorithm(self, progress):
        # Retrieve the values of the parameters entered by the user
        inLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.ROADS_LAYER))

        # establish db connection
        progress.setInfo('Getting DB connection')
        self.setDbFromRoadsLayer(inLayer)


        # build the base sql statement
        baseSql = u'select tdgGenerateCrossStreetData('
        baseSql = baseSql + "'" + self.schema + "." + self.roadsTable + "',"

        # loop through either selected features (if any) or all features (if
        # no selection) and process the cross streets in chunks of 100
        featureIds = inLayer.selectedFeaturesIds()
        if len(featureIds) == 0:
            featureIds = inLayer.allFeatureIds()
        progress.setInfo('Processing ' + str(len(featureIds)) + ' features')
        chunks = [featureIds[i:i+100] for i in range(0, len(featureIds), 100)]
        count = 100
        for chunk in chunks:
            sql = "'{"
            for featId in chunk:
                sql = sql + str(featId) + ','
            sql = sql[:-1]                  #remove the last comma
            sql = sql + "}'::INTEGER[])"    #finish the call
            try:
                self.db.connector._execute_and_commit(baseSql + sql)
                progress.setPercentage(100*count/len(featureIds))
                sql = "'{"
                count = count + 100
            except:
                raise
