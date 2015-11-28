#Calculate Network Cost from Distance

##Parameters
**Roads layer** - The roads layer of the network dataset.

##Description
Assigns a cost to each link in the network based on the distance of the
associated road segment. Only links that are associated to road segments
are given a cost. (i.e. links that represent movements through intersections
are not included.)

By design, road networks must use a projection measured in feet, so the
cost is calculated in feet.
