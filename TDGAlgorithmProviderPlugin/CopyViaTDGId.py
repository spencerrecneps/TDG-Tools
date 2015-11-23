# -*- coding: utf-8 -*-

"""
***************************************************************************
    CopyViaTDGId.py
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
import markdown2
from qgis.core import *

from TDGAlgorithm import TDGAlgorithm
import processing
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterTableField
from processing.tools import dataobjects, vector


class CopyViaTDGId(TDGAlgorithm):
    """This algorithm copies values from one dataset to another using features
    that have the same tdg_id values.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    SOURCE_LAYER = 'SOURCE_LAYER'
    SOURCE_FIELD = 'SOURCE_FIELD'
    TARGET_LAYER = 'TARGET_LAYER'
    TARGET_FIELD = 'TARGET_FIELD'

    def help(self):
        html = markdown2.markdown_path(os.path.join(self.helpPath,'Copy Via TDG ID.md'))
        return True, html

    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Copy via TDG ID'

        # The branch of the toolbox under which the algorithm will appear
        #self.group = 'Algorithms for vector layers'
        self.group = 'Data Management'

        # Source layer. Must be vector
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.SOURCE_LAYER,
            self.tr('Source layer'), [ParameterVector.VECTOR_TYPE_ANY], optional=False))

        # Field with source values
        self.addParameter(ParameterTableField(self.SOURCE_FIELD,
            self.tr('Field with source values'),
            parent=self.SOURCE_LAYER,
            optional=False))

        # Target layer. Must be vector
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.TARGET_LAYER,
            self.tr('Target layer'), [ParameterVector.VECTOR_TYPE_ANY], optional=False))

        # Field with target values
        self.addParameter(ParameterTableField(self.TARGET_FIELD,
            self.tr('Field to copy values to'),
            parent=self.TARGET_LAYER,
            optional=False))


    def processAlgorithm(self, progress):
        # Retrieve the values of the parameters entered by the user
        sourceLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.SOURCE_LAYER))
        sourceField = self.getParameterValue(self.SOURCE_FIELD)
        targetLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.TARGET_LAYER))
        targetField = self.getParameterValue(self.TARGET_FIELD)

        # check for tdg_id fields in source and target
        progress.setPercentage(0)
        progress.setInfo('Checking for tdg_id fields')
        exists = False
        try:
            vector.resolveFieldIndex(sourceLayer,'tdg_id')
            exists = True
        except:
            pass

        if not exists:
            raise GeoAlgorithmExecutionException('No tdg_id field was found in \
                layer %s' % sourceLayer.name())

        exists = False
        try:
            vector.resolveFieldIndex(targetLayer,'tdg_id')
            exists = True
        except:
            pass

        if not exists:
            raise GeoAlgorithmExecutionException('No tdg_id field was found in \
                layer %s' % targetLayer.name())
        progress.setPercentage(2)

        # build dict of source data
        progress.setInfo('Reading source values')
        count = 0
        totalCount = len(vector.features(sourceLayer))
        sourceValues = {}
        for feat in vector.features(sourceLayer):
            count += 1
            progress.setPercentage(2 + 28*count/totalCount)
            tdgId = feat['tdg_id']
            copyAttr = feat[sourceField]
            if tdgId is None:
                continue
            sourceValues[tdgId] = copyAttr

        # start editing
        targetLayer.startEditing()

        # iterate target features and assign matching source value
        progress.setInfo('Copying to target features')
        count = 0
        totalCount = len(vector.features(targetLayer))
        for targetFeat in vector.features(targetLayer):
            count += 1
            progress.setPercentage(30 + 68*count/totalCount)
            tdgId = targetFeat['tdg_id']
            if tdgId is None:
                continue
            if tdgId in sourceValues:
                fieldIndex = vector.resolveFieldIndex(targetLayer,targetField)
                sourceVal = sourceValues.get(tdgId)
                targetFeat.setAttribute(fieldIndex,sourceVal)
                targetLayer.updateFeature(targetFeat)

        progress.setInfo('Editing has been left active for layer %s.' % targetLayer.name())
        progress.setInfo('Please finalize this operation by checking values, saving your edits, and closing the edit session.')

        # # commit and finish editing
        # success = False
        # try:
        #     success = targetLayer.commitChanges()
        # except Exception, e:
        #     targetLayer.rollBack()
        #     raise GeoAlgorithmExecutionException('Error committing changes: %s' % str(e))
        #
        # if success:
        #     targetLayer.endEditCommand()
        # else:
        #     targetLayer.rollBack()
        #     raise GeoAlgorithmExecutionException('Error committing changes')
