# -*- coding: utf-8 -*-

"""
***************************************************************************
    MakeRoadNetwork.py
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
from qgis.core import *

from TDGAlgorithm import TDGAlgorithm
import processing
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterBoolean
from processing.tools import dataobjects


class MakeRoadNetwork(TDGAlgorithm):
    """This algorithm takes an input road dataset and adds
    the necessary tables and database triggers to maintain
    a routable network.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    ROADS_LAYER = 'ROADS_LAYER'
    ADDTOMAP = 'ADDTOMAP'


    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Make TDG network layer'

        # The branch of the toolbox under which the algorithm will appear
        #self.group = 'Algorithms for vector layers'
        self.group = 'Network Analysis'

        # Input roads layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.ROADS_LAYER,
            self.tr('Base roads layer'), [ParameterVector.VECTOR_TYPE_LINE], optional=False))

        # Add new tables to map?
        self.addParameter(ParameterBoolean(self.ADDTOMAP,
            self.tr('Add new tables to map'), True))


    def processAlgorithm(self, progress):
        # Retrieve the values of the parameters entered by the user
        inLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.ROADS_LAYER))
        addToMap = self.getParameterValue(self.ADDTOMAP)

        # establish db connection
        progress.setInfo('Getting DB connection')
        self.setDbFromRoadsLayer(inLayer)
        self.setLayersFromDb()

        #sql = 'select tdgMakeNetwork('
        #sql = sql + "'" + roadsDb.getTable() + "');"
        sql = "select tdgMakeNetwork('%s.%s');" % (self.schema, self.roadsTable)
        progress.setInfo('Creating network')
        try:
            self.db.connector._execute_and_commit(sql)
        except:
            raise

        # add layers to map
        if addToMap:
            self.setLayersFromDb()
            self.addLinksToMap()
            self.addVertsToMap()
