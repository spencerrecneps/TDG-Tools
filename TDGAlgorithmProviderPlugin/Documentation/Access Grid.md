#Access Grid

##Parameters
**Roads layer** - The TDG standardized road layer of the network dataset.

**Grid layer** - The grid layer for which access will be calculated.

**Field containing the network vertex IDs** - The field in the grid layer
that contains network vertex IDs.

**Maximum travel budget** - How far the travel shed will extend from each point.
Given in terms of the travel cost calculated on the network layer.

**Maimum allowable traffic stress** - The most stressful LTS score to allow
in building the travel shed. Can be left at zero to exclude LTS in the
analysis.

**Output** - Save location for the access grid calculations.

##Description
Builds a travel shed around each cell in a grid and calculates the number of
other grid cells that are accessible within the allowable travel budget,
expressed in terms of the cost given in the road network. If desired,
the travel sheds can exclude road segments above a given traffic stress score.
