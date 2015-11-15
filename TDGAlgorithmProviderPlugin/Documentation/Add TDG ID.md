#Add TDG ID

##Parameters
Name         | Type
-------------|----------
INPUT_LAYER  | Input layer

**INPUT_LAYER** - The layer to add the TDG ID to.

##Description

Adds a column named tdg_id to the input layer and populates with a unique
identifier. The identifier is a set of numbers and letters 36 characters long
that is unique across the entire company.

TDG IDs are important for creating a standardized road network. They are also
helpful in many other contexts. In general, it is recommended to add a TDG ID
to any dataset that we receive from a client, as well as any other dataset
that will be used for future analysis.
