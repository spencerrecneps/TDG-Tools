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

import os
import markdown2
from PyQt4.QtCore import QVariant
from qgis.core import *
from math import sqrt

from TDGAlgorithm import TDGAlgorithm
import processing
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterBoolean
from processing.core.parameters import ParameterNumber
from processing.core.parameters import ParameterTableField
from processing.core.parameters import ParameterSelection
from processing.core.outputs import OutputVector
from processing.tools import dataobjects, vector

class Meld(TDGAlgorithm):
    """This algorithm takes a target line dataset and a
    source line dataset. It identifies the most likely candidate
    for a match based on the spatial mismatch between the two at
    various points along the source line.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    TARGET_LAYER = 'TARGET_LAYER'
    TARGET_IDS = 'TARGET_IDS'
    SOURCE_LAYER = 'SOURCE_LAYER'
    SOURCE_IDS = 'SOURCE_IDS'
    TOLERANCE = 'TOLERANCE'
    MAX_SKEW = 'MAX_SKEW'
    METHOD = 'METHOD'
    OUT_LAYER = 'OUT_LAYER'
    KEEP_NULLS = 'KEEP_NULLS'


    def help(self):
        html = markdown2.markdown_path(os.path.join(self.helpPath,'Meld.md'))
        return True, html


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

        # Field with target ids
        self.addParameter(ParameterTableField(self.TARGET_IDS,
            self.tr('Field with target IDs'),
            parent=self.TARGET_LAYER,
            optional=False))

        # Source layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.SOURCE_LAYER,
            self.tr('Source layer'), [ParameterVector.VECTOR_TYPE_LINE], optional=False))

        # Field with source ids
        self.addParameter(ParameterTableField(self.SOURCE_IDS,
            self.tr('Field with source IDs'),
            parent=self.SOURCE_LAYER,
            optional=False))

        # Tolerance
        self.addParameter(
            ParameterNumber(
                self.TOLERANCE,
                self.tr('Search tolerance'),
                minValue=0
            )
        )

        # Max skew
        self.addParameter(
            ParameterNumber(
                self.MAX_SKEW,
                self.tr('Maximum skew (degrees, not used for midpoint method)'),
                minValue=0,
                default=30
            )
        )

        # Method
        self.METHODS = ['Endpoints','Midpoint']#,'Thirds']
        self.addParameter(ParameterSelection(self.METHOD,
            self.tr('Search method'), self.METHODS))

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
        targetFieldName = self.getParameterValue(self.TARGET_IDS)
        sourceLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.SOURCE_LAYER))
        sourceFieldName = self.getParameterValue(self.SOURCE_IDS)
        tolerance = self.getParameterValue(self.TOLERANCE)
        maxSkew = self.getParameterValue(self.MAX_SKEW)
        method = self.METHODS[self.getParameterValue(self.METHOD)]
        keepNulls = self.getParameterValue(self.KEEP_NULLS)

        # get input field types and set output fields
        targetField = targetLayer.dataProvider().fields().at(vector.resolveFieldIndex(targetLayer,targetFieldName))
        sourceField = sourceLayer.dataProvider().fields().at(vector.resolveFieldIndex(sourceLayer,sourceFieldName))
        fields = QgsFields()
        fields.append(QgsField('target_id', targetField.type()))
        fields.append(QgsField('source_id', sourceField.type()))

        # set up output writer
        writer = self.getOutputFromName(self.OUT_LAYER).getVectorWriter(
            fields, QGis.WKBLineString, targetLayer.crs())

        # create spatial index for source features
        progress.setInfo('Indexing source features')
        index = vector.spatialindex(sourceLayer)

        # build dictionary of source features
        sourceFeatures = {}
        for sourceFeat in vector.features(sourceLayer):
            sourceFeatures[sourceFeat.id()] = sourceFeat

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
            targetId = targetFeat[targetFieldName]
            if targetId is None:
                raise GeoAlgorithmExecutionException('Target ID value cannot be empty')
            matchId = None
            outFeat.setAttribute(0,targetId)

            targetGeom = QgsGeometry(targetFeat.geometry())
            if targetGeom is None:
                continue

            # get first, last, and mid points of target feature
            targetLength = targetGeom.length()
            firstPoint = targetGeom.interpolate(0)
            midPoint = targetGeom.interpolate(targetLength*0.5)
            lastPoint = targetGeom.interpolate(targetLength)

            # get source features within the tolerance
            targetBox = targetGeom.buffer(tolerance,5).boundingBox()
            sourceIds = index.intersects(targetBox)

            # test for nearness
            if method == 'Midpoint':
                # get the 5 nearest neighbors
                midSourceIds = index.nearestNeighbor(midPoint.asPoint(),5)

                # loop through the nearest features and identify the closest match
                minDist = -1
                for sourceId in midSourceIds:
                    if not sourceId in sourceIds:
                        continue
                    sourceGeom = QgsGeometry(sourceFeatures.get(sourceId).geometry())

                    if midPoint.distance(sourceGeom) > tolerance:
                        continue

                    # get distances
                    firstDist = firstPoint.distance(sourceGeom)
                    lastDist = lastPoint.distance(sourceGeom)

                    if minDist < 0:
                        minDist = firstDist + lastDist
                        matchId = sourceFeatures[sourceId][sourceFieldName]
                    elif minDist > firstDist + lastDist:
                        minDist = firstDist + lastDist
                        matchId = sourceFeatures[sourceId][sourceFieldName]
            elif method == 'Thirds':
                thirdPoint = targetGeom.interpolate(targetLength*0.33)
                twoThirdsPoint = targetGeom.interpolate(targetLength*0.67)

                # get the 5 nearest neighbors
                thirdSourceIds = index.nearestNeighbor(thirdPoint.asPoint(),5)
                twoThirdsSourceIds = index.nearestNeighbor(twoThirdsPoint.asPoint(),5)

                # find common ids

                # loop through the nearest features and identify the closest match
                minDist = -1
                for sourceId in midSourceIds:
                    if not sourceId in sourceIds:
                        continue
                    sourceGeom = QgsGeometry(sourceFeatures.get(sourceId).geometry())

                    if midPoint.distance(sourceGeom) > tolerance:
                        continue

                    # get distances
                    firstDist = firstPoint.distance(sourceGeom)
                    lastDist = lastPoint.distance(sourceGeom)

                    if minDist < 0:
                        minDist = firstDist + lastDist
                        matchId = sourceFeatures[sourceId][sourceFieldName]
                    elif minDist > firstDist + lastDist:
                        minDist = firstDist + lastDist
                        matchId = sourceFeatures[sourceId][sourceFieldName]
            elif method == 'Endpoints':
                avgDist = None

                thisAngle = radians(firstPoint().asPoint().azimuth(lastPoint().asPoint()))

                for sourceId in sourceIds:
                    sourceGeom = QgsGeometry(sourceFeatures.get(sourceId).geometry())

                    # skip a feature if it's not at least 1/2 as long as target
                    if sourceGeom.length() < (targetGeom.length()*0.5):
                        continue

                    # skip a feature if the difference in angles is too large
                    fp = sourceGeom.interpolate(0).asPoint()
                    lp = sourceGeom.interpolate(1).asPoint()
                    sourceAngle = radians(fp.azimuth(lp))
                    '''Compare angles'''

                    # get distances
                    firstDist = firstPoint.distance(sourceGeom)
                    midDist = midPoint.distance(sourceGeom)
                    lastDist = lastPoint.distance(sourceGeom)

                    # skip a feature if it's beyond the tolerance at any point on the target
                    if (firstDist > tolerance or
                            midDist > tolerance or
                            lastDist > tolerance):
                        continue

                    # check deviation
                    dev = sqrt((midDist - firstDist)**2 + (midDist - lastDist)**2)
                    if dev > (targetLength/2):
                        continue

                    # get the closest match
                    checkDist = sum([firstDist,midDist,lastDist])/3

                    if avgDist is None:
                        avgDist = checkDist
                        matchId = sourceFeatures[sourceId][sourceFieldName]
                    elif checkDist < avgDist:
                        avgDist = checkDist
                        matchId = sourceFeatures[sourceId][sourceFieldName]

            outFeat.setAttribute(1,matchId)
            outFeat.setGeometry(targetGeom)
            if keepNulls:
                writer.addFeature(outFeat)
            elif not matchId is None:
                writer.addFeature(outFeat)

        del writer
