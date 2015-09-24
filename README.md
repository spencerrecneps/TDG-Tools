#TDG Tools

This is a suite of tools that integrate QGIS functionality and the power of PostGIS to perform operations standard to TDG's analytical processes.

The tools are divided into two major types: QGIS tools, and PostGIS functions. In most cases, a QGIS tool is simply a wrapper to an underlying PostGIS function (or functions). In other words, it would be possible to accomplish most of the same operations available through the QGIS interface within the confines of the PostGIS database. For those of you brave souls who prefer text over a GUI, this is good news.

##QGIS Tools

The QGIS tools are divided into categories based on logical groupings of the types of operations that TDG analysts do on a regular basis.

###Network Analysis
* [Import Road Layer](https://github.com/spencerrecneps/TDG-Tools/blob/master/Documentation/qgis/Import Road Layer.md)
* [Standardize Road Layer](https://github.com/spencerrecneps/TDG-Tools/blob/master/Documentation/qgis/Standardize Road Layer.md)
* [Make Road Network](https://github.com/spencerrecneps/TDG-Tools/blob/master/Documentation/qgis/Make Road Network.md)
* Calculate Road Slope
* Shortest Path Route

###Traffic Stress
* [Calculate Traffic Stress](https://github.com/spencerrecneps/TDG-Tools/blob/master/Documentation/qgis/Calculate Traffic Stress.md)

###Demand Analysis
* Create Demand Grid
* Generate Demand Points
* Add Demand Points
* Calculate Demand

##PostGIS Tools

The PostGIS tools do the heavy lifting. In order to enable a PostGIS database to run the TDG tools, the following extensions must be installed:
* PostGIS (enables spatial operations)
* UUID-OSSP (library for generating unique identifiers)
* plpythonu (Python API for database functions)

These can be installed along with the TDG extension in one fell swoop with the following query (this must be run as a database administrator - typically the postgres account)
```
CREATE EXTENSION postgis;
CREATE EXTENSION "uuid-ossp";
CREATE LANGUAGE plpythonu;
CREATE EXTENSION tdg;
```

The TDG tools will create a new schema in the database named "tdg". This is where the functions created by the TDG extension live. It is not advisable to save datasets in the tdg schema.

The following functions are created for use with the extension:
* tdgCalculateStress
* tdgColumnCheck
* tdgGenerateCrossStreetData
* tdgGenerateIntersectionStreets
* tdgGetSRID
* tdgMakeIntersections
* tdgMakeNetwork
* [tdgMultiToSingle](https://github.com/spencerrecneps/TDG-Tools/blob/master/Documentation/postgis/tdgMultiToSingle.md)
* tdgSetTurnInfo
* tdgShortestPathIntersections
* tdgShortestPathVerts
* tdgStandardizeRoadLayer
* tdgTableCheck
* tdgTableDetails
* tdgUpdateIntersections
* tdgUpdateNetwork
