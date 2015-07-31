# -*- coding: utf-8 -*-
"""
/***************************************************************************
 TDGAlgorithmProviderPlugin
                                 A QGIS plugin
 Tools for TDG analyses
                             -------------------
        begin                : 2015-07-25
        copyright            : (C) 2015 by Spencer Gardner
        email                : spencergardner@gmail.com
        git sha              : $Format:%H$
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
 This script initializes the plugin, making it known to QGIS.
"""


# noinspection PyPep8Naming
def classFactory(iface):  # pylint: disable=invalid-name
    """Load TDGAlgorithmProviderPlugin class from file TDGAlgorithmProviderPlugin.

    :param iface: A QGIS interface instance.
    :type iface: QgsInterface
    """
    #
    from .TDGAlgorithmProviderPlugin import TDGAlgorithmProviderPlugin
    return TDGAlgorithmProviderPlugin(iface)
