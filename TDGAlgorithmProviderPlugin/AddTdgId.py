# -*- coding: utf-8 -*-

"""
***************************************************************************
    AddTdgId.py
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

from PyQt4.QtCore import QVariant
from qgis.core import *
import uuid

import processing
from processing.core.GeoAlgorithm import GeoAlgorithm
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.tools import dataobjects, vector


class AddTdgId(GeoAlgorithm):
    """This algorithm takes an input dataset and adds a column name
    'tdg_id' with UUID values.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    INPUT_LAYER = 'INPUT_LAYER'

    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Add TDG ID field'

        # The branch of the toolbox under which the algorithm will appear
        #self.group = 'Algorithms for vector layers'
        self.group = 'Data Management'

        # Input roads layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.INPUT_LAYER,
            self.tr('Input layer'), [ParameterVector.VECTOR_TYPE_ANY], optional=False))


    def processAlgorithm(self, progress):
        # Retrieve the values of the parameters entered by the user
        inLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.INPUT_LAYER))
        provider = inLayer.dataProvider()

        # check for existing tdg_id field
        progress.setPercentage(0)
        progress.setInfo('Checking if tdg_id field already exists')
        exists = False
        try:
            vector.resolveFieldIndex(inLayer,'tdg_id')
            exists = True
        except:
            pass

        if exists:
            raise GeoAlgorithmExecutionException('A field named tdg_id already \
                exists')
        progress.setPercentage(10)

        # start editing and add field
        progress.setInfo('Adding tdg_id field')
        field = QgsField('tdg_id', QVariant.String)
        inLayer.startEditing()
        provider.addAttributes([field])
        #inLayer.addAttribute(field)
        inLayer.updateFields()

        # loop through features and add random uuid value
        fieldIndex = vector.resolveFieldIndex(inLayer,'tdg_id')
        progress.setInfo('Setting tdg_id values')
        count = 0
        totalCount = len(vector.features(inLayer))
        for feat in vector.features(inLayer):
            count += 1
            progress.setPercentage(10 + 95*count/totalCount)
            tdgId = str(uuid.uuid4())
            feat.setAttribute(fieldIndex,tdgId)
            inLayer.updateFeature(feat)

        # commit and finish editing
        progress.setInfo('Committing changes')
        success = False
        try:
            success = inLayer.commitChanges()
        except Exception, e:
            inLayer.rollBack()
            raise GeoAlgorithmExecutionException('Error committing changes: %s' % str(e))

        if success:
            inLayer.endEditCommand()
        else:
            inLayer.rollBack()
            raise GeoAlgorithmExecutionException('Error committing changes')
