#tdgMultiToSingle

##Parameters
Name        | Type
------------|----------
temp_table_ | REGCLASS
new_table_  | TEXT
schema_     | TEXT
srid_       | INTEGER
overwrite_  | BOOLEAN

**temp_table_** - The name of the temporary table to copy data from. This table
will be deleted when the function completes.

**new_table_** - The name of the new table to create.

**schema_** - The schema to create the new table in.

**srid_** - The desired SRID for geometries in the new data. N.B. The spatial unit of the SRID should be US Feet.

**overwrite_** - Whether to overwrite an existing table of the same schema and name.

##Description

When a table is imported from QGIS, the QGIS tool first uses QGIS' own "Import
into PostGIS" tool to upload data into the database. However, the table that is
uploaded is of geometry type MULTILINESTRING and may also not be in the
desired spatial reference system.

To remedy this, the initial import is done to a temporary table. Once the table
is imported, tdgMultiToSingle is called. It breaks any MULTILINESTRING geometries
into regular LINESTRINGs. In these cases, it duplicates the attribute information
for every individual LINESTRING that is produced.

In addition, a new field called 'tdg_id' is added to the table, which contains
a globally unique identifier generated for each feature. This value is
guaranteed to be unique across all data in the company, making it easy to join
derived data back to its original source.
