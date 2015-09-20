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

        INSERT INTO tmp_roadgeomchange (
            road_id,
            old_int_from,
            old_int_to)
        VALUES (
            OLD.road_id,
            OLD.intersection_from,
            OLD.intersection_to);
    ELSEIF TG_OP = 'INSERT' THEN
        NEW.geom := ST_SnapToGrid(NEW.geom,2);

        INSERT INTO tmp_roadgeomchange (road_id)
        VALUES (NEW.road_id);
    ELSEIF TG_OP = 'DELETE' THEN
        INSERT INTO tmp_roadgeomchange (
            road_id,
            old_int_from,
            old_int_to)
        VALUES (
            OLD.road_id,
            OLD.intersection_from,
            OLD.intersection_to);
        RETURN OLD;
    END IF;

    --suspend triggers on the intersections table so that our
    --changes are not ignored.
    EXECUTE 'ALTER TABLE ' || int_table || ' DISABLE TRIGGER ALL;';

    --add new intersections
    IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
        --startpoint
        EXECUTE '
            SELECT  1
            FROM    '||int_table||' i
            WHERE   i.geom = ST_StartPoint($1)
            AND     i.z_elev = $2;'
        USING   NEW.geom,
                NEW.z_from;
        GET DIAGNOSTICS i = ROW_COUNT;
        IF i = 0 THEN
            EXECUTE 'INSERT INTO '||int_table||' (geom) SELECT ST_StartPoint($1);'
            USING   NEW.geom;
        END IF;

        --endpoint
        EXECUTE '
            SELECT  1
            FROM    '||int_table||' i
            WHERE   i.geom = ST_EndPoint($1)
            AND     i.z_elev = $2;'
        USING   NEW.geom,
                NEW.z_to;
        GET DIAGNOSTICS i = ROW_COUNT;
        IF i = 0 THEN
            EXECUTE 'INSERT INTO '||int_table||' (geom) SELECT ST_EndPoint($1);'
            USING   NEW.geom;
        END IF;

        --re-enable triggers on the intersections table
        EXECUTE 'ALTER TABLE ' || int_table || ' ENABLE TRIGGER ALL;';

        --assign intersections to road
        EXECUTE '
            UPDATE  tmp_roadgeomchange
            SET     new_int_from = (SELECT  int_id
                                    FROM    '||int_table||' i
                                    WHERE   ST_StartPoint($1) = i.geom
                                    AND     $2 = i.z_elev),
                    new_int_to = (  SELECT  int_id
                                            FROM    '||int_table||' i
                                            WHERE   ST_EndPoint($1) = i.geom
                                            AND     $3 = i.z_elev)
            WHERE   tmp_roadgeomchange.road_id = $4;'
        USING   NEW.geom,
                NEW.z_from,
                NEW.z_to,
                NEW.road_id;

        --set new from intersection
        EXECUTE 'SELECT new_int_from FROM tmp_roadgeomchange WHERE road_id = $1'
        USING   NEW.road_id
        INTO    NEW.intersection_from;

        --set new to intersection
        EXECUTE 'SELECT new_int_to FROM tmp_roadgeomchange WHERE road_id = $1'
        USING   NEW.road_id
        INTO    NEW.intersection_to;

        RETURN NEW;
    END IF;
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgRoadGeomChangeVals() OWNER TO gis;
