#Meld

##Parameters
Name        | Type
------------|----------
temp_table_ | REGCLASS
new_table_  | TEXT
schema_     | TEXT
srid_       | INTEGER
overwrite_  | BOOLEAN

**TARGET_LAYER** - The layer to which information should be joined.
**SOURCE_LAYER** - The layer with information to be joined to the target features.
**TOLERANCE** - The search distance for finding matching features.
**OUT_LAYER** - The location to save the output layer (if blank, saves as a
temporary layer)
**KEEP_NULLS** - Whether to keep target features that do not have a match in the
source layer.

##Description

Meld is a tool to associate information from one set of lines onto a set of
similar, but not exactly overlapping lines.

A match is determined using the following logic. For each target feature, a
search is made for any source features within the tolerance distance. If there
are any matches, they are then searched for their distance from
the start, mid, and end points of each target feature. If a source feature
is within the tolerance distance of all three points, it is considered a match.
A tie is broken by the average distance from all three points.
