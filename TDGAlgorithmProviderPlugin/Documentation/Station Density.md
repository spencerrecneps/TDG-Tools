#Station Density

##Parameters
**Station layer** - The station layer.

**Cluster tolerance** - The cluster tolerance to use in the calculation.

##Description
Calculates the density of a bike share network using the given cluster tolerance.
The measure expresses how far a typical station in the system is from
nearby stations.

In technical terms, the measure finds the nearest X stations (X being the
cluster tolerance) and then sums the distance from the station to each of
these nearest stations. The output is the average of this measure for all
stations in the system.
