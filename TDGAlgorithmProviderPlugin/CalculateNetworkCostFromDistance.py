# -*- coding: utf-8 -*-

"""
***************************************************************************
    CalculateNetworkCostFromDistance.py
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

import os
import markdown2
from qgis.core import *

import processing
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.tools import dataobjects
from TDGAlgorithm import TDGAlgorithm


class CalculateNetworkCostFromDistance(TDGAlgorithm):
    """This algorithm takes an input road dataset and converts
    it into a standardized format for use in stress analysis
    and other tasks.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    ROADS_LAYER = 'ROADS_LAYER'

    def help(self):
        html = markdown2.markdown_path(os.path.join(self.helpPath,'Calculate Network Cost From Distance.md'))
        return True, html

    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Network cost from distance'

        # The branch of the toolbox under which the algorithm will appear
        #self.group = 'Algorithms for vector layers'
        self.group = 'Network Analysis'

        # Input roads layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.ROADS_LAYER,
            self.tr('Roads layer'), [ParameterVector.VECTOR_TYPE_LINE], optional=False))


    def processAlgorithm(self, progress):
        # Retrieve the values of the parameters entered by the user
        inLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.ROADS_LAYER))

        # establish db connection
        progress.setInfo('Getting DB connection')
        self.setDbFromRoadsLayer(inLayer)

        # set up the sql call and run
        progress.setInfo('Calculating network costs')
        sql = 'select tdg.tdgNetworkCostFromDistance(' + " \
                '" + self.schema + '.' + self.roadsTable + "')"
        progress.setInfo('Database call was: ')
        progress.setInfo(sql)
        try:
            self.db.connector._execute_and_commit(sql)
        except:
            raise GeoAlgorithmExecutionException('Error communicating with \
                database')
