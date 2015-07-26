# -*- coding: utf-8 -*-

"""
***************************************************************************
    __init__.py
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

from PyQt4.QtCore import QSettings

from processing.core.GeoAlgorithm import GeoAlgorithm
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterString
from processing.core.parameters import ParameterTableField
from processing.core.parameters import ParameterBoolean
from processing.core.parameters import ParameterSelection

from processing.tools import dataobjects
from processing.algs.qgis import postgis_utils


class CreateRoadNetwork(GeoAlgorithm):
    """This algorithm takes an input road dataset and converts
    it into a standardized format for use in stress analysis
    and other tasks.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    ROADS_LAYER = 'ROADS_LAYER'
    DATABASE = 'DATABASE'
    TABLENAME = 'TABLENAME'
    OVERWRITE = 'OVERWRITE'

    def dbConnectionNames(self):
        settings = QSettings()
        settings.beginGroup('/PostgreSQL/connections/')
        return settings.childGroups()

    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Import new TDG road layer'

        # The branch of the toolbox under which the algorithm will appear
        #self.group = 'Algorithms for vector layers'
        self.group = 'TDG Tools'

        # 1 - Input roads layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.ROADS_LAYER,
            self.tr('Roads layer'), [ParameterVector.VECTOR_TYPE_LINE], False))

        # 2 - DB connection
        self.DB_CONNECTIONS = self.dbConnectionNames()
        self.addParameter(ParameterSelection(self.DATABASE,
            self.tr('Database (connection name)'), self.DB_CONNECTIONS))

        # 3 - Table name
        self.addParameter(ParameterString(self.TABLENAME,
            self.tr('Table name to import to (leave blank to use layer name)')))

        # 4 - Overwrite existing table?
        self.addParameter(ParameterBoolean(self.OVERWRITE,
            self.tr('Overwrite'), True))

    def processAlgorithm(self, progress):
        # Retrieve the values of the parameters entered by the user
        # 1 - roads layer
        roadsLayer = dataobjects.getObjectFromUri(self.ROADS_LAYER)

        # 2 - db connection
        connection = self.DB_CONNECTIONS[self.getParameterValue(self.DATABASE)]
        settings = QSettings()
        mySettings = '/PostgreSQL/connections/' + connection
        try:
            database = settings.value(mySettings + '/database')
            username = settings.value(mySettings + '/username')
            host = settings.value(mySettings + '/host')
            port = settings.value(mySettings + '/port', type=int)
            password = settings.value(mySettings + '/password')
        except Exception, e:
            raise GeoAlgorithmExecutionException(
                self.tr('Bad database connection name: %s' % connection))

        # 3 - table name
        table = self.getParameterValue(self.TABLENAME).strip().lower()
        if table == '':
            table = roadsLayer.name().lower()
        table.replace(' ', '')

        # test connection
        providerName = 'postgres'
        try:
            db = postgis_utils.GeoDB(host=host, port=port, dbname=database,
                                     user=username, passwd=password)
        except postgis_utils.DbError, e:
            raise GeoAlgorithmExecutionException(
                self.tr("Couldn't connect to database:\n%s" % e.message))

        # And now we can process

        # Now we take the features from input layer and add them to the
        # output. Method features() returns an iterator, considering the
        # selection that might exist in layer and the configuration that
        # indicates should algorithm use only selected features or all
        # of them
        features = vector.features(roadsLayer)
        for f in features:
            pass

        # There is nothing more to do here. We do not have to open the
        # layer that we have created. The framework will take care of
        # that, or will handle it if this algorithm is executed within
        # a complex model
