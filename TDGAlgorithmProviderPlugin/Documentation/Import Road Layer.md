#Import Road Layer

##Parameters
**Input dataset** - The road dataset to import into the PostGIS database.

**Database** - The database to import to.

**Schema** - The database schema to import to.

**Table name** - The name of the table to create.

**Add to map** - Add the imported dataset to the map.

**Overwrite** - Whether to overwrite an existing table (if applicable.)

**Target CRS** - The projection to save the data to.

##Description
Imports a road dataset into a PostGIS database. The tool makes a couple of
key changes as it imports:

1. Adds a TDG ID column to the table if one doesn't already exist.
2. Converts the line geometries to LINESTRING type, as opposed to
MULTILINESTRING. This is necessary for many of the operations that other tools
perform.
3. Reprojects to the specified target projection. The projection must be
measured in feet and also must have a standardized EPSG* code.

\* Most common projections have an EPSG code. Codes can be found using
http://epsg.io/. In addition, an EPSG code can often be found in ArcMap
by opening the data frame properties and reviewing the map projection.
EPSG codes are also often indicated in the ArcMap layer properties dialog.
