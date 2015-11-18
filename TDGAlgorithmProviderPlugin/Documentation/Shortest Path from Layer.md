#Shortest Path from Layer

##Parameters
**Input road layer** - The TDG standardized road layer. (Must have network built)

**Destinations layer** - A layer with points representing destinations on the road
network. The data must include a field that identifies the network vertex ID.

**Field with vertex ID** - The field in the destinations layer with vertex IDs.

**Maximum allowable traffic stress** - The greatest stress to be allowed on the route.
Can be left at 0 to ignore stress.

**Keep raw path layer** - Whether to output the raw shortest path data, which
includes every road segment of every shortest path.

**Raw path output location** - Location to save raw path data shapefile to.
(creates a temporary layer if left blank)

**Keep routes layer** - Whether to output the routes data, which includes
a single record for every shortest path.

**Routes output location** - Location to save routes data shapefile to.
(creates a temporary layer if left blank)

**Keep summary layer** - Whether to output the summary data, which summarizes
the number of shortest routes that use a given segment of roadway.

**Summary location** - Location to save summary data shapefile to.
(creates a temporary layer if left blank)

##Description

Calculates a shortest path from each point in the destinations layer to every
other point in the layer. If a stress level is given the tool ignores road
segments that exceed the given stress.

There are three datasets that this analysis produces:

1. _Raw paths_ - The raw shortest path data. This is a record of every road
segment that is used on a shortest path for every shortest path in the analysis.
Each record includes the linework of the underlying road segment.

2. _Routes_ - The routes of every shortest path. This is a single record for
the shortest path from each destination to every other destination. Each record
includes the linework of the entire route followed by a shortest path.

3. _Summary_ - Summary data for each road segment. Every road segment that is
part of a shortest path is represented, including a count of the number of
shortest paths that use that road segment. Each record includes the linework
of the underlying road segment.
