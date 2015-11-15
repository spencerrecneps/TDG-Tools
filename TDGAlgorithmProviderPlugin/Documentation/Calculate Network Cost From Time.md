#Calculate Network Cost from Time

##Parameters
Name         | Type
-------------|----------
ROADS_LAYER  | Roads layer
SPEED | Number
FEET_PER_SECOND | Boolean

**ROADS_LAYER** - The roads layer of the network dataset.

**SPEED** - The assumed speed (defaults to miles per hour.)

**FEET_PER_SECOND** - Indicates whether the speed measure is in feet per second.

##Description

Assigns a cost to each link in the network based on the amount of time it takes
to traverse an associated road segment. Only links that are associated to
road segments are given a cost. (i.e. links that represent movements through
intersections are not included.)

Unless specified, the speed is assumed to be in miles per hour.

For reference, common assumptions for speeds are:
*Average bicyclist - 12 miles per hour
*Average pedestrian - 3.5 miles per hour
