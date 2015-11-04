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

from PyQt4.QtCore import QVariant
from qgis.core import *
from math import sqrt

import processing
from processing.core.GeoAlgorithm import GeoAlgorithm
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterBoolean
from processing.core.parameters import ParameterNumber
from processing.core.outputs import OutputVector
from processing.tools import dataobjects, vector

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
    SOURCE_LAYER = 'SOURCE_LAYER'
    TOLERANCE = 'TOLERANCE'
    OUT_LAYER = 'OUT_LAYER'
    KEEP_NULLS = 'KEEP_NULLS'



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

        # Source layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.SOURCE_LAYER,
            self.tr('Source layer'), [ParameterVector.VECTOR_TYPE_LINE], optional=False))

        # Tolerance
        self.addParameter(
            ParameterNumber(
                self.TOLERANCE,
                self.tr('Search tolerance'),
                minValue=0
            )
        )

        # Output layer
        self.addOutput(
            OutputVector(self.OUT_LAYER, self.tr('Output layer'))
        )

        # Keep nonmatches?
        self.addParameter(
            ParameterBoolean(
                self.KEEP_NULLS,
                self.tr('Keep non-matching target features?'), default=False
            )
        )


    def processAlgorithm(self, progress):
        # Retrieve the values of the parameters entered by the user
        targetLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.TARGET_LAYER))
        sourceLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.SOURCE_LAYER))
        tolerance = self.getParameterValue(self.TOLERANCE)
        fields = QgsFields()
        fields.append(QgsField('source_id', QVariant.Int))
        fields.append(QgsField('target_id', QVariant.Int))
        writer = self.getOutputFromName(self.OUT_LAYER).getVectorWriter(
            fields, QGis.WKBLineString, targetLayer.crs())
        keepNulls = self.getParameterValue(self.KEEP_NULLS)

        # create spatial index for source features
        index = vector.spatialindex(sourceLayer)

        # loop through target features
        progress.setInfo('Checking target features')
        targetFeats = vector.features(targetLayer)
        count = 0
        totalCount = len(targetFeats)
        progress.setInfo('%i target features identified' % totalCount)
        for targetFeat in targetFeats:
            count += 1
            progress.setPercentage(count/totalCount)
            outFeat = QgsFeature(fields)
            targetId = targetFeat.id()
            matchId = None
            outFeat.setAttribute(0,targetId)

            targetGeom = QgsGeometry(targetFeat.geometry())
            if targetGeom is None:
                continue
            targetBox = targetGeom.buffer(tolerance,5).boundingBox()
            avgDist = None

            # get first, last, and mid points of target feature
            firstPoint = targetGeom.interpolate(0)
            midPoint = targetGeom.interpolate(targetGeom.length()*0.5)
            lastPoint = targetGeom.interpolate(targetGeom.length()*1)

            # get list of source ids from the spatial index
            sourceIds = index.intersects(targetBox)

            # build dictionary of source features
            sourceFeatures = {}
            for sourceFeat in vector.features(sourceLayer):
                sourceFeatures[sourceFeat.id()] = sourceFeat

            for sourceId in sourceIds:
                sourceGeom = QgsGeometry(sourceFeatures.get(sourceId).geometry())

                # skip a feature if it's not at least 1/2 as long as target
                if sourceGeom.length() < (targetGeom.length()*0.5):
                    continue

                # get distances
                firstDist = firstPoint.distance(sourceGeom)
                midDist = midPoint.distance(sourceGeom)
                lastDist = lastPoint.distance(sourceGeom)

                # skip a feature if it's beyond the tolerance at any point on the target
                if (firstDist > tolerance or
                        midDist > tolerance or
                        lastDist > tolerance):
                    continue

                # # check deviation
                # dev = sqrt((midDist - firstDist)**2 + (midDist - lastDist)**2)
                # if dev > tolerance:
                #     continue

                # get the closest match
                checkDist = sum([firstDist,midDist,lastDist])/3

                if avgDist is None:
                    avgDist = checkDist
                    matchId = sourceId
                elif checkDist < avgDist:
                    avgDist = checkDist
                    matchId = sourceId

            outFeat.setAttribute(1,matchId)
            outFeat.setGeometry(targetGeom)
            if keepNulls:
                writer.addFeature(outFeat)
            elif not matchId is None:
                writer.addFeature(outFeat)

        del writer
