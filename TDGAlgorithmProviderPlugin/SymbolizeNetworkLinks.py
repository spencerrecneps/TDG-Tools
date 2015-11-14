# -*- coding: utf-8 -*-

"""
***************************************************************************
    SymbolizeNetworkLinks.py
    ---------------------
    Date                 : November 2015
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
__date__ = 'November 2015'
__copyright__ = '(C) 2015, Spencer Gardner'

# This will get replaced with a git SHA1 when you do a git archive

__revision__ = '$Format:%H$'

import os
from qgis.core import *

from TDGAlgorithm import TDGAlgorithm
import processing
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.tools import dataobjects


class SymbolizeNetworkLinks(TDGAlgorithm):
    """This algorithm adds a roads layer to the map with the stress level
    symbolized for easy review
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    ROADS_LAYER = 'ROADS_LAYER'

    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Add network links'

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

        # check if this is a roads layer
        self.setLayersFromDb()
        if not self.intsLayer.isValid():
            raise GeoAlgorithmExecutionException('Layer %s is not a valid TDG \
                roads layer' % inLayer.name())

        # check if this has a network links layer
        if not self.linksLayer.isValid():
            raise GeoAlgorithmExecutionException('No network links layer found \
                for %s' % inLayer.name())

        # create the new layer
        self.linksLayer.loadNamedStyle(
            os.path.join(self.stylePath, 'net_link.qml')
        )
        self.addLinksToMap()
