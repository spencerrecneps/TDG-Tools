# -*- coding: utf-8 -*-

"""
***************************************************************************
    RoadSlope.py
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
__date__ = 'August 2015'
__copyright__ = '(C) 2015, Spencer Gardner'

# This will get replaced with a git SHA1 when you do a git archive

__revision__ = '$Format:%H$'

import os
import markdown2
from PyQt4.QtCore import QSettings
from qgis.core import QgsFeature

from TDGAlgorithm import TDGAlgorithm
import processing
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterRaster

from processing.tools import vector


class RoadSlope(TDGAlgorithm):
    """This algorithm takes an input road dataset and
    overlays it with an elevation raster, getting an elevation
    profile for each segment.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    ROADS_LAYER = 'ROADS_LAYER'
    ELEV_LAYER = 'ELEV_LAYER'


    def help(self):
        html = markdown2.markdown_path(os.path.join(self.helpPath,'Road Slope.md'))
        return True, html


    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Elevation climb'

        # The branch of the toolbox under which the algorithm will appear
        self.group = 'Data Management'

        # Input roads layer. Must be line type
        self.addParameter(ParameterVector(self.ROADS_LAYER,
            self.tr('Roads layer'),
            [ParameterVector.VECTOR_TYPE_LINE],
            optional=False))

        # Input elevation layer
        self.addParameter(ParameterRaster(self.ELEV_LAYER,
            self.tr('Elevation layer'),
            optional=False))


    def processAlgorithm(self, progress):
        # Retrieve the values of the parameters entered by the user
        roadsLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.ROADS_LAYER))
        elevLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.ELEV_LAYER))

        # ##########################
        # # And now we can process #
        # ##########################
        #
        # #open editing
        # roadsLayer.startEditing()
        #
        # # check for existing field
        # fields = roadsLayer.pendingFields()
        # try:
        #     f = fields.field('ft_climb')
        # except:
        #     bool QgsVectorLayer::addAttribute	(	const QgsField & 	field	)
        #     #or
        #     processing.runalg("qgis:addfieldtoattributetable")
        # try:
        #     f = fields.field('tf_climb')
        # except:
        #     processing.runalg("qgis:addfieldtoattributetable")
        #
        # # iterate features and read elevations
        # for feature in vector.features(roadsLayer):
        #     #select feature?
        #
        #     pts = processing.runalg("grass:v.to.points")
        #     #or maybe
        #     pts = processing.runalg("grass:v.segment")
        #
        #     #get elevation profile
        #     elevs = processing.runalg("grass:r.profile")
        #
        #     #read elevations
        # roadsLayer.commitChanges()
