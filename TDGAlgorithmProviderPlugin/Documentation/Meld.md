#Meld

##Parameters
**Target layer** - The layer to which information should be joined.

**Field with target IDs** - The field in the target data that uniquely identifies features.

**Source layer** - The layer with information to be joined to the target features.

**Field with source IDs** - The field in the source data that uniquely identifies features.

**Search tolerance** - The search distance for finding matching features. (Given in
units of the coordinate system.)

**Search method** - The matching method to be used.

**Keep non-matching features** - Whether to keep target features that do not have a match in the
source layer.

**Output layer** - The location to save the output layer (if blank, saves as a
temporary layer)

##Description
Meld associates information from one set of lines onto a set of
similar, but not exactly overlapping lines. This is often called "conflation" in
GIS.

Match logic is defined in the **search method** parameter, which offers the
following options:
- Endpoints
- Midpoints

The _endpoints_ method matches features by comparing the endpoints of the target
layer to the endpoints of the source layer. If both endpoints overlap within
the tolerance distance a match is assumed.

The _midpoints_ method matches features by finding the source features closest to
the target feature within the tolerance. The endpoints of the target are then
compared to each source. The source feature with the lowest cumulative distance
from the target endpoints is assumed to match.

As an example, imagine you received a layer representing all the bike lanes in
a municipality, but the lines don't line up perfectly with the roads layer
so a spatial join won't work. You can use this tool to assign the bike
lane data to the roads that they overlap with.
