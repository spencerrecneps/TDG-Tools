# -*- coding: utf-8 -*-

"""
***************************************************************************
    StandardizeRoadNetwork.py
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

from PyQt4.QtCore import QSettings
from qgis.core import QgsDataSourceURI, QgsVectorLayerImport, QGis, QgsFeature, QgsGeometry

import processing
from processing.core.GeoAlgorithm import GeoAlgorithm
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterString
from processing.core.parameters import ParameterTableField
from processing.core.parameters import ParameterBoolean
from processing.core.parameters import ParameterSelection

from processing.tools import dataobjects, vector
from processing.algs.qgis import postgis_utils
from dbutils import LayerDbInfo


class StandardizeRoadNetwork(GeoAlgorithm):
    """This algorithm takes an input road dataset and converts
    it into a standardized format for use in stress analysis
    and other tasks.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    ROADS_LAYER = 'ROADS_LAYER'
    ID_FIELD = 'ID_FIELD'
    NAME_FIELD = 'NAME_FIELD'
    ADT_FIELD = 'ADT_FIELD'
    SPEED_FIELD = 'SPEED_FIELD'
    OVERWRITE = 'OVERWRITE'

    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Create standardized TDG road layer'

        # The branch of the toolbox under which the algorithm will appear
        #self.group = 'Algorithms for vector layers'
        self.group = 'Network Analysis'

        # 1 - Input roads layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.ROADS_LAYER,
            self.tr('Roads layer'), [ParameterVector.VECTOR_TYPE_LINE], optional=False))

        # 2 - Source ID field in the roads data
        # Optional field
        self.addParameter(ParameterTableField(self.ID_FIELD,
            self.tr('Original ID field of the road layer'), optional=True))

        # 3 - Name field in the roads data
        # Optional field
        self.addParameter(ParameterTableField(self.NAME_FIELD,
            self.tr('Name field of the road layer'), optional=True))

        # 4 - ADT field in the roads data
        # Optional field
        self.addParameter(ParameterTableField(self.ADT_FIELD,
            self.tr('ADT field of the road layer'), optional=True))

        # 5 - Speed limit field in the roads data
        # Optional field
        self.addParameter(ParameterTableField(self.SPEED_FIELD,
            self.tr('Speed limit field of the road layer'), optional=True))

        # 6 - Overwrite existing table?
        self.addParameter(ParameterBoolean(self.OVERWRITE,
            self.tr('Overwrite'), default=True))

    def processAlgorithm(self, progress):
        # Retrieve the values of the parameters entered by the user
        # 1 - roads layer
        roadsLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.ROADS_LAYER))

        roadsDb = LayerDbInfo(roadsLayer.source())
