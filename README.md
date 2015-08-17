#TDG Tools
=========================

This is a suite of tools that integrate QGIS functionality and the power of PostGIS to perform operations standard to TDG's analytical processes.

The tools are divided into two major types: QGIS tools, and PostGIS functions. In most cases, a QGIS tool is simply a wrapper to an underlying PostGIS function (or functions). In other words, it would be possible to accomplish most of the same operations available through the QGIS interface within the confines of the PostGIS database. For those of you brave souls who prefer text over a GUI, this is good news.

##QGIS Tools
-------------------------
The QGIS tools are divided into categories based on logical groupings of the types of operations that TDG analysts do on a regular basis.

###Network Analysis
* [Import Road Layer](https://github.com/spencerrecneps/TDG-Tools/blob/master/Documentation/Import Road Layer.md)
* Standardize Road Layer
* Make Road Network
* Calculate Road Slope
* Shortest Path Route
###Traffic Stress
* Calculate Traffic Stress
###Demand Analysis
* Create Demand Grid
* Generate Demand Points
* Add Demand Points
* Calculate Demand
