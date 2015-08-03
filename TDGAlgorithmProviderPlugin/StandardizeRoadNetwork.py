# -*- coding: utf-8 -*-

"""
***************************************************************************
    StandardizeRoadNetwork.py
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
from qgis.core import QgsDataSourceURI, QgsVectorLayerImport, QGis, QgsFeature, QgsGeometry

import processing
from processing.core.GeoAlgorithm import GeoAlgorithm
from processing.core.GeoAlgorithmExecutionException import GeoAlgorithmExecutionException
from processing.core.parameters import ParameterVector
from processing.core.parameters import ParameterString
from processing.core.parameters import ParameterTableField
from processing.core.parameters import ParameterBoolean
from processing.core.parameters import ParameterSelection

from processing.tools import dataobjects, vector
from processing.algs.qgis import postgis_utils
from dbutils import LayerDbInfo


class StandardizeRoadNetwork(GeoAlgorithm):
    """This algorithm takes an input road dataset and converts
    it into a standardized format for use in stress analysis
    and other tasks.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    TABLE_NAME = 'TABLE_NAME'
    ROADS_LAYER = 'ROADS_LAYER'
    ID_FIELD = 'ID_FIELD'
    NAME_FIELD = 'NAME_FIELD'
    ADT_FIELD = 'ADT_FIELD'
    SPEED_FIELD = 'SPEED_FIELD'
    OVERWRITE = 'OVERWRITE'
    DELETE_SOURCE = 'DELETE_SOURCE'

    def defineCharacteristics(self):
        """Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # The name that the user will see in the toolbox
        self.name = 'Create standardized TDG road layer'

        # The branch of the toolbox under which the algorithm will appear
        #self.group = 'Algorithms for vector layers'
        self.group = 'Network Analysis'

        # name for new table
        # mandatory
        self.addParameter(ParameterString(self.TABLE_NAME,
            self.tr('Name of table to be created'), optional=False))

        # 1 - Input roads layer. Must be line type
        # It is a mandatory (not optional) one, hence the False argument
        self.addParameter(ParameterVector(self.ROADS_LAYER,
            self.tr('Roads layer'), [ParameterVector.VECTOR_TYPE_LINE], optional=False))

        # 2 - Source ID field in the roads data
        # Optional field
        self.addParameter(ParameterTableField(self.ID_FIELD,
            self.tr('Original ID field of the road layer'), optional=True))

        # 3 - Name field in the roads data
        # Optional field
        self.addParameter(ParameterTableField(self.NAME_FIELD,
            self.tr('Name field of the road layer'), optional=True))

        # 4 - ADT field in the roads data
        # Optional field
        self.addParameter(ParameterTableField(self.ADT_FIELD,
            self.tr('ADT field of the road layer'), optional=True))

        # 5 - Speed limit field in the roads data
        # Optional field
        self.addParameter(ParameterTableField(self.SPEED_FIELD,
            self.tr('Speed limit field of the road layer'), optional=True))

        # 6 - Overwrite existing table?
        self.addParameter(ParameterBoolean(self.OVERWRITE,
            self.tr('Overwrite'), default=True))

        # Delete source table?
        self.addParameter(ParameterBoolean(self.DELETE_SOURCE,
            self.tr('Delete source table'), default=False))

    def processAlgorithm(self, progress):
        # Retrieve the values of the parameters entered by the user
        tableName = self.getParameterValue(self.TABLE_NAME).strip().lower()
        inLayer = dataobjects.getObjectFromUri(self.getParameterValue(self.ROADS_LAYER))
        fieldIdOrig = self.getParameterValue(self.ID_FIELD)
        fieldName = self.getParameterValue(self.NAME_FIELD)
        fieldADT = self.getParameterValue(self.ADT_FIELD)
        fieldSpeed = self.getParameterValue(self.SPEED_FIELD)
        overwrite = self.getParameterValue(self.OVERWRITE)
        delSource = self.getParameterValue(self.DELETE_SOURCE)

        # establish db connection
        roadsDb = LayerDbInfo(inLayer.source())
        dbHost = roadsDb.getHost()
        dbPort = roadsDb.getPort()
        dbName = roadsDb.getDBName()
        dbUser = roadsDb.getUser()
        dbPass = roadsDb.getPassword()
        dbSchema = roadsDb.getSchema()
        dbType = roadsDb.getType()
        dbSRID = roadsDb.getSRID()
        try:
            db = postgis_utils.GeoDB(host=dbHost,
                                     port=dbPort,
                                     dbname=dbName,
                                     user=dbUser,
                                     passwd=dbPass)
        except postgis_utils.DbError, e:
            raise GeoAlgorithmExecutionException(
                self.tr("Couldn't connect to database:\n%s" % e.message))

        # check for existing table, delete or raise error
        tables = db.list_geotables(schema=dbSchema)
        tableNames = [table[0] for table in tables]
        if tableName in tableNames:
            if overwrite:
                db.delete_geometry_table(tableName, schema=dbSchema)
            else:
                raise GeoAlgorithmExecutionException(
                    self.tr('Table %s already exists' % tableName))

        # create new table, starting with new fields
        fieldList = [
            {'name': 'id', 'pgtype': 'serial'},#, 'type': QVariant.Int},
            {'name': 'road_name', 'pgtype': 'text'},#, 'type': QVariant.String},
            {'name': 'source_id', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'functional_class', 'pgtype': 'text'},#, 'type': QVariant.String},
            {'name': 'one_way', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'speed_limit', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'adt', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'ft_seg_lanes_thru', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'ft_seg_lanes_bike_wd_ft', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'ft_seg_lanes_park_wd_ft', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'ft_seg_stress_override', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'ft_seg_stress', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'ft_int_lanes_thru', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'ft_int_lanes_lt', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'ft_int_lanes_rt_len_ft', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'ft_int_lanes_rt_radius_speed_mph', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'ft_int_lanes_bike_wd_ft', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'ft_int_lanes_bike_straight', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'ft_int_stress_override', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'ft_int_stress', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'ft_cross_median_wd_ft', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'ft_cross_signal', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'ft_cross_speed_limit', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'ft_cross_lanes', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'ft_cross_stress_override', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'ft_cross_stress', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'tf_seg_lanes_thru', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'tf_seg_lanes_bike_wd_ft', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'tf_seg_lanes_park_wd_ft', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'tf_seg_stress_override', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'tf_seg_stress', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'tf_int_lanes_thru', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'tf_int_lanes_lt', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'tf_int_lanes_rt_len_ft', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'tf_int_lanes_rt_radius_speed_mph', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'tf_int_lanes_bike_wd_ft', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'tf_int_lanes_bike_straight', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'tf_int_stress_override', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'tf_int_stress', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'tf_cross_median_wd_ft', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'tf_cross_signal', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'tf_cross_speed_limit', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'tf_cross_lanes', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'tf_cross_stress_override', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'tf_cross_stress', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'source', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'target', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'cost', 'pgtype': 'int'},#, 'type': QVariant.Int},
            {'name': 'reverse_cost', 'pgtype': 'int'}#, 'type': QVariant.Int}
        ]

        dbFields = []
        for f in fieldList:
            dbFields.append(postgis_utils.TableField(f['name'],f['pgtype']))
        db.create_table(tableName,
                        dbFields,
                        pkey='id',
                        schema=dbSchema)

        db.add_geometry_column(tableName, dbType, schema=dbSchema,
                               geom_column='geom', srid=dbSRID)

        db.create_spatial_index(tableName, schema=dbSchema, geom_column='geom')

        # set up the new table's uri and get new object
        uri = QgsDataSourceURI()
        uri.setConnection(dbHost, str(dbPort), dbName, dbUser, dbPass)
        uri.setDataSource(dbSchema, tableName, 'geom', 'id')
        outLayer = dataobjects.getObjectFromUri(uri.uri(),forceLoad=True)

        # iterate road features and add to new table
        outFields = outLayer.dataProvider().fields()
        inGeom = QgsGeometry()
        for feature in vector.features(inLayer):
            outFeat = QgsFeature(outFields)
            inGeom = feature.geometry()
            outFeat.setGeometry(inGeom)
            if fieldIdOrig:
                outFeat.setAttribute('id',feature.attribute(fieldIdOrig))
            if fieldName:
                outFeat.setAttribute('road_name',feature.attribute(fieldName))
            if fieldADT:
                outFeat.setAttribute('adt',feature.attribute(fieldADT))
            if fieldSpeed:
                outFeat.setAttribute('speed_limit',feature.attribute(fieldSpeed))
            outLayer.addFeature(outFeat)
            del outFeat
        outLayer.commitChanges()
        #iface.addVectorLayer(uri.uri(),tableName,'postgres')


        # delete source table
        if delSource:
            db.delete_geometry_table(roadsDb.getTable(),schema=roadsDb.getSchema())
