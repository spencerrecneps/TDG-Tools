CREATE OR REPLACE FUNCTION tdg.tdgRoadGeomChangeVals ()
RETURNS TRIGGER
AS $BODY$

--------------------------------------------------------------------------
-- This function is called automatically anytime a change is made to the
-- geometry or intersection z value of a record in a TDG-standardized
-- road layer. It snaps the new geometry to a 2-ft grid and then updates
-- the intersection information. The geometry matches an existing
-- intersection if it is within 5 ft of another intersection.
--
-- N.B. If the end of a cul-de-sac is moved, the old intersection point
-- is deleted and a new one is created. This should be an edge case
-- and wouldn't cause any problems anyway. A fix to move the intersection
-- point rather than create a new one would complicate the code and the
-- current behavior isn't really problematic.
--------------------------------------------------------------------------

DECLARE
    road_table REGCLASS;
    int_table REGCLASS;
    i INTEGER;

BEGIN
    --get the intersection and road tables
    road_table := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME;
    int_table := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME || '_intersections';

    --popoulate change tables
    IF TG_OP = 'UPDATE' THEN
        NEW.geom := ST_SnapToGrid(NEW.geom,2);

        INSERT INTO tmp_roadgeomchange (road_id)
        VALUES (OLD.road_id);
    ELSEIF TG_OP = 'INSERT' THEN
        NEW.geom := ST_SnapToGrid(NEW.geom,2);

        INSERT INTO tmp_roadgeomchange (road_id)
        VALUES (NEW.road_id);
    ELSEIF TG_OP = 'DELETE' THEN
        INSERT INTO tmp_roadgeomchange (road_id)
        VALUES (OLD.road_id);
        RETURN OLD;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgRoadGeomChangeVals() OWNER TO gis;
