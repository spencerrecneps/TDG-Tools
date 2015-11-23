# -*- coding: utf-8 -*-

"""
***************************************************************************
    StationDensity.py
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

import os
import markdown2
from PyQt4.QtCore import QVariant
from qgis.core import *
from math import sqrt

from TDGAlgorithm import TDGAlgorithm
import processing
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterNumber
from processing.tools import dataobjects, vector

class StationDensity(TDGAlgorithm):
    """This algorithm takes an input point dataset representing bike share
    stations and reports a measure of station density by averaging the
    distance to nearby stations. A smaller score is more dense.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    STATION_LAYER = 'STATION_LAYER'
    TOLERANCE = 'TOLERANCE'


    def help(self):
        html = markdown2.markdown_path(os.path.join(self.helpPath,'Station Density.md'))
        return True, html


    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Station Density'

        # The branch of the toolbox under which the algorithm will appear
        #self.group = 'Algorithms for vector layers'
        self.group = 'Bike Share'

        # Station layer. Must be point type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.STATION_LAYER,
            self.tr('Station layer'), [ParameterVector.VECTOR_TYPE_POINT], optional=False))

        # Cluster tolerance (the number of stations to search for in the density
        # calculation)
        self.addParameter(
            ParameterNumber(
                self.TOLERANCE,
                self.tr('Cluster tolerance'),
                minValue=0
            )
        )


    def processAlgorithm(self, progress):
        # Retrieve the values of the parameters entered by the user
        stationLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.STATION_LAYER))
        tolerance = self.getParameterValue(self.TOLERANCE)

        # create spatial index for station features
        progress.setInfo('Indexing station features')
        index = vector.spatialindex(stationLayer)

        # build dictionary of station features
        stationFeats = vector.features(stationLayer)
        stationFeatures = {}
        for stationFeat in stationFeats:
            stationFeatures[stationFeat.id()] = {
                'feature': stationFeat,
                'distances': []
            }

        # loop through station features
        progress.setInfo('Getting station cluster indexes')
        count = 0
        totalCount = len(stationFeats)
        progress.setInfo('%i target features identified' % totalCount)
        totalDistance = 0
        for stationId, station in stationFeatures.iteritems():
            count += 1
            progress.setPercentage(count/totalCount)
            geom = QgsGeometry(station.get('feature').geometry())

            # get nearest neighbors using cluster tolerance and the
            # spatial index (tolerance + 1 because it will also return
            # the feature itself as a match)
            neighbors = index.nearestNeighbor(geom.asPoint(),tolerance + 1)

            # loop through neighbors and add distance to the feature's list
            for neighbor in neighbors:
                neighborFeat = stationFeatures.get(neighbor).get('feature')
                neighborGeom = QgsGeometry(neighborFeat.geometry())
                distance = geom.distance(neighborGeom)

                if distance > 0:    # excludes a self-match
                    station['distances'].append(distance)

            totalDistance += sum(station.get('distances'))

            # need to refine this final measure
        progress.setInfo('Total distance: %d' % (totalDistance))
        progress.setInfo('Total stations: %d' % (totalCount))
        progress.setInfo('Compactness: %d' % (totalDistance/totalCount))
