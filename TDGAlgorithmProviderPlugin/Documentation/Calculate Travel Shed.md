#Calculate Travel Shed

##Parameters
**Roads layer** - The TDG standardized road layer of the network dataset.

**Points layer** - The points from which travel sheds will be calculated.

**Field containing the network vertex IDs** - The field in the points layer
that contains network vertex IDs.

**Maximum travel budget** - How far the travel shed will extend from each point.
Given in terms of the travel cost calculated on the network layer.

**Maimum allowable traffic stress** - The most stressful LTS score to allow
in building the travel shed. Can be left at zero to exclude LTS in the
analysis.

**Polygon output** - Save location for the travel shed polygons.

**Road feature output** - Save location for the travel shed roads.

##Description
Builds a travel shed around each point in an input point layer. If desired,
the travel sheds can exclude road segments above a given traffic stress score.
The travel shed is constrained by a travel budget, which is expressed in terms
of the costs calculated on the road network.

Depending on the analysis, this
could be simply the length of each road segment, or time needed to travel on the
segment (based on an assumed travel speed), or some other measure developed
as part of the analysis.

The tool produces two output layers: travel shed polygons and road features.
The output polygon represents the maximum extent of the travel shed. The
output roads represent all roads within the travel shed.
