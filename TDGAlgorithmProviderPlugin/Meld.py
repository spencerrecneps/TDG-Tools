# -*- coding: utf-8 -*-

"""
***************************************************************************
    Meld.py
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
__date__ = 'September 2015'
__copyright__ = '(C) 2015, Spencer Gardner'

# This will get replaced with a git SHA1 when you do a git archive

__revision__ = '$Format:%H$'

from PyQt4.QtCore import QSettings
from qgis.core import *

import processing
from processing.core.GeoAlgorithm import GeoAlgorithm
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterTableField
from processing.core.parameters import ParameterBoolean


class Meld(GeoAlgorithm):
    """This algorithm takes an target line dataset and a
    source line dataset. It identifies the most likely candidate
    for a match based on the spatial mismatch between the two at
    various points along the source line.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    TARGET_LAYER = 'TARGET_LAYER'
    TARGET_ID = 'TARGET_ID'
    SOURCE_LAYER = 'SOURCE_LAYER'
    SOURCE_ID = 'SOURCE_ID'
    TOLERANCE = 'TOLERANCE'


    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Meld'

        # The branch of the toolbox under which the algorithm will appear
        #self.group = 'Algorithms for vector layers'
        self.group = 'Data Management'

        # Target layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.TARGET_LAYER,
            self.tr('Target layer'), [ParameterVector.VECTOR_TYPE_LINE], optional=False))

        # Unique identifier for target layer
        # Required
        self.addParameter(ParameterTableField(self.TARGET_ID,
            self.tr('Unique identifier for target layer'),
            parent=self.TARGET_LAYER,
            optional=False))

        # Source layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.SOURCE_LAYER,
            self.tr('Source layer'), [ParameterVector.VECTOR_TYPE_LINE], optional=False))

        # Unique identifier for source layer
        # Required
        self.addParameter(ParameterTableField(self.SOURCE_ID,
            self.tr('Unique identifier for source layer'),
            parent=self.SOURCE_LAYER,
            optional=False))

    def processAlgorithm(self, progress):
        # Retrieve the values of the parameters entered by the user
        targetLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.TARGET_LAYER))
        sourceLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.SOURCE_LAYER))
        targetIdField = self.getParameterValue(self.TARGET_ID)
        sourceIdField = self.getParameterValue(self.SOURCE_ID)

        # loop through target features

            # identify candidate source features (if any)

            # loop through candidate source features

                # generate points along each target feature at intervals

                # loop through points and get distance to source
