CREATE OR REPLACE FUNCTION tdg.tdgRoadGeomChangeTable ()
RETURNS TRIGGER
AS $BODY$

--------------------------------------------------------------------------
-- This function is called automatically anytime a change is made to the
-- geometry or intersection z value of a record in a TDG-standardized
-- road layer. It creates a temporary table to track the rows in the road
-- layer that have changed.
--------------------------------------------------------------------------

BEGIN
    EXECUTE '
        CREATE TEMPORARY TABLE tmp_roadgeomchange (road_id INTEGER)
        ON COMMIT DROP;';

    RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgRoadGeomChangeTable() OWNER TO gis;
