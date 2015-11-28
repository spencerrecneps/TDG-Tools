#Copy Road Dataset

##Parameters
**Input road layer** - The TDG standardized road layer to copy.

**Output database schema** - The schema to save the new layer to in the database.

**New road layer** - The name of the new road layer to create.

**Overwrite** - Whether to overwrite an existing table (if applicable.)

**Add to map** - Whether to add the new road layers to the map.

##Description
Copies an existing TDG road network. This can be useful for evaluating
alternatives, where a base dataset represents existing conditions and
alternatives represent minor changes from the base condition.

Road layers can only be copied within the same PostGIS database.
