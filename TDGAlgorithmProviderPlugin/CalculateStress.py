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
__date__ = 'July 2015'
__copyright__ = '(C) 2015, Spencer Gardner'

# This will get replaced with a git SHA1 when you do a git archive

__revision__ = '$Format:%H$'

import os
import markdown2

from TDGAlgorithm import TDGAlgorithm
import processing
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterBoolean
from processing.tools import dataobjects


class CalculateStress(TDGAlgorithm):
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

    def help(self):
        html = markdown2.markdown_path(os.path.join(self.helpPath,'Calculate Traffic Stress.md'))
        return True, html

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
        calcSegment = self.getParameterValue(self.SEGMENT)
        calcApproach = self.getParameterValue(self.APPROACH)
        calcCross = self.getParameterValue(self.CROSS)

        # establish db connection
        progress.setInfo('Getting DB connection')
        self.setDbFromRoadsLayer(inLayer)

        # check if this is a roads layer
        self.setLayersFromDb()
        if not self.intsLayer.isValid():
            raise GeoAlgorithmExecutionException('Layer %s is not a valid TDG \
                roads layer' % inLayer.name())

        sql = u'select tdgCalculateStress('
        sql = sql + "'" + self.roadsTable + "'"
        if calcSegment:
            sql = sql + ",'t'"
        else:
            sql = sql + ",'f'"
        if calcApproach:
            sql = sql + ",'t'"
        else:
            sql = sql + ",'f'"
        if calcCross:
            sql = sql + ",'t'"
        else:
            sql = sql + ",'f'"
        sql = sql + ");"

        #processing.runalg("qgis:postgisexecutesql",dbName,sql)
        progress.setInfo('Calculating stress scores')
        progress.setInfo('Database call was: ')
        progress.setInfo(sql)
        try:
            self.db.connector._execute_and_commit(sql)
        except:
            raise
