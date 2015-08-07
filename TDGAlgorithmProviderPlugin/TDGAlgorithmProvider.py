# -*- coding: utf-8 -*-

"""
***************************************************************************
    TDGAlgorithmProvider.py
    ---------------------
    Date                 : July 2015
    Copyright            : (C) 2013 by Spencer Gardner
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

from processing.core.AlgorithmProvider import AlgorithmProvider
from processing.core.ProcessingConfig import Setting, ProcessingConfig

from processing.script.ScriptUtils import ScriptUtils

from ImportRoadLayer import ImportRoadLayer
from StandardizeRoadLayer import StandardizeRoadLayer
from MakeRoadNetwork import MakeRoadNetwork


class TDGAlgorithmProvider(AlgorithmProvider):

    def __init__(self):
        AlgorithmProvider.__init__(self)

        # Activate provider by default
        self.activate = True

        # Load algorithms
        self.alglist = [
            ImportRoadLayer(),
            StandardizeRoadLayer(),
            MakeRoadNetwork()]
        for alg in self.alglist:
            alg.provider = self

    def initializeSettings(self):
        AlgorithmProvider.initializeSettings(self)

    def unload(self):
        AlgorithmProvider.unload(self)

    def getName(self):
        return 'tdg'

    def getDescription(self):
        return self.tr('TDG tools')

    def getIcon(self):
        """We return the default icon.
        """
        return AlgorithmProvider.getIcon(self)

    def _loadAlgorithms(self):
        self.algs = self.alglist

    def supportsNonFileBasedOutput(self):
        return True
