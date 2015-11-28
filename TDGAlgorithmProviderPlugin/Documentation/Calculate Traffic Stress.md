#Calculate Traffic Stress

##Parameters
**Input road layer** - The TDG standardized road layer for calculating stress.

**Calculate for segments** - Whether to calculate stress for road segments.

**Calculate for approaches** - Whether to calculate stress for intersection approaches.

**Calculate for crossings** - Whether to calculate stress for intersection crossings.

##Description
The Level of Traffic Stress (LTS) methodology is one common measure for how
well a roadway accommodates travel by bicycle. Three different elements of the
road network can be assigned scores: the segments, approaches, and crossings.

The TDG standardized road layer has fields that correspond to inputs used
in calculating traffic stress. Therefore, in order for this tool to work,
the appropriate fields in the roads layer need to be populated with input data.

Depending on the project, the LTS methodology may include any combination of the
three elements. Typically, segments are the easiest elements to score because
the rating relies on more commonly-available data.

The full published LTS methodology can be found at: http://transweb.sjsu.edu/project/1005.html

Please note that TDG uses a modified version based on changes suggested by
Peter Furth in an email exchange with TDG staff.

Data needs for each element are as follows:

###Segments###
* Number of travel lanes and/or average daily traffic (ADT)
* Whether parking exists on the segment and how wide the parking lane is (parking
information is only needed if bike lanes are present)
* Whether there are bike lanes and how wide the lanes are
* The speed limit

###Approaches###
* Whether there is a right-turn only lane and how long it is
* The design turn speed of the right turn lane (based on curb radius)
* Behavior of bike lanes at the approach to the intersection (whether the bike
lane drops, shifts laterally, or continues straight)

###Crossings###
* Number of travel lanes and/or ADT on the crossing street
* Speed limit on the crossing street
* Whether there is a median refuge on the crossing street (only matters if the
median is a minimum of six feet wide)
