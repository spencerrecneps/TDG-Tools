#Meld

##Parameters
**Target layer** - The layer to which information should be joined.

**Field with target IDs** - The field in the target data that uniquely identifies features.

**Source layer** - The layer with information to be joined to the target features.

**Field with source IDs** - The field in the source data that uniquely identifies features.

**Search tolerance** - The search distance for finding matching features. (Given in
units of the coordinate system.)

**Output file** - The location to save the output layer (if blank, saves as a
temporary layer)

**Keep non-matching features** - Whether to keep target features that do not have a match in the
source layer.

##Description
Meld associates information from one set of lines onto a set of
similar, but not exactly overlapping lines.

A match is determined using the following logic. For each target feature, a
search is made for any source features within the tolerance distance. If there
are any matches, they are then searched for their distance from
the start, mid, and end points of each target feature. If a source feature
is within the tolerance distance of all three points, it is considered a match.
A tie is broken by the average distance from all three points.

As an example, imagine you received a layer representing all the bike lanes in
a municipality, but the lines don't line up perfectly with the roads layer
so a spatial join won't work. You can use this tool to assign the bike
lane data to the roads that they overlap with.
