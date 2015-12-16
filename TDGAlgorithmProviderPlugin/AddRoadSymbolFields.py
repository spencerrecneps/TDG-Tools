# -*- coding: utf-8 -*-

"""
***************************************************************************
    AddRoadSymbolFields.py
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
from PyQt4.QtCore import QVariant
from qgis.core import *

from TDGAlgorithm import TDGAlgorithm
import processing
from processing.core.GeoAlgorithm import GeoAlgorithm
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.tools import dataobjects, vector


class AddRoadSymbolFields(TDGAlgorithm):
    """This algorithm takes an input dataset and adds columns for storing
    information related to road symbols that can be used for labeling on the map.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    INPUT_LAYER = 'INPUT_LAYER'

    def help(self):
        html = markdown2.markdown_path(os.path.join(self.helpPath,'Add Road Symbol Fields.md'))
        return True, html

    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Add road symbol fields'

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
        postgres = False
        if inLayer.providerType() == u'postgres':
            postgres = True

        progress.setPercentage(0)
        fields = {
            'carto_symbol_type': False,
            'carto_symbol_text': False,
            'carto_symbol_path': False
        }

        for fieldName, exists in fields.iteritems():
            progress.setInfo('Checking if %s field already exists' % fieldName)
            try:
                vector.resolveFieldIndex(inLayer,fieldName)
                fields[fieldName] = True
            except:
                pass

        for fieldName, exists in fields.iteritems():
            if exists:
                progress.setInfo('Field %s already exists' % fieldName)
            else:
                progress.setInfo('Adding %s field' % fieldName)
                if postgres:
                    pass
                else:
                    field = QgsField(fieldName, QVariant.String)
                    inLayer.startEditing()
                    provider.addAttributes([field])
                    inLayer.updateFields()
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
