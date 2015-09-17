CREATE OR REPLACE FUNCTION tdg.tdgUpdateIntersections(
    road_table_ REGCLASS,
    int_table_ REGCLASS,
    road_ids_ INTEGER[]
)
RETURNS TRIGGER
AS $BODY$

--------------------------------------------------------------------------
-- This function update road and intersection information based on
-- a set of road_ids passed in as an array.
--------------------------------------------------------------------------

DECLARE
    int_ids INTEGER[];

BEGIN
    --identify affected intersections


    --update intersection leg count


    --update from/to intersections on roads




END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgUpdateIntersections(REGCLASS,REGCLASS,INTEGER[]) OWNER TO gis;
