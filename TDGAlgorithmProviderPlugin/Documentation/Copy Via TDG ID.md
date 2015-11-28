#Copy Via TDG ID

##Parameters
**Source layer** - The layer to copy values from.

**Source field** - The field to copy values from.

**Target layer** - The layer to copy values to.

**Target field** - The field to copy values to.

##Description
Copies values from the source layer to the target layer based on shared
TDG IDs in both datasets. Both source and target layers must have a field
named tdg_id that holds TDG IDs. Values are only copied where a match is
found between the source and target layer.

The tool leaves the target layer in an open editing session so that the
changes can be discarded if not satisfactory.
