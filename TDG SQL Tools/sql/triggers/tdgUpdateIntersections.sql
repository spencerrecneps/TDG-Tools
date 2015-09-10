CREATE OR REPLACE FUNCTION tdgUpdateIntersections ()
RETURNS TRIGGER
AS $BODY$

--------------------------------------------------------------------------
-- This function is called automatically anytime a change is made to the
-- geometry of a record in a TDG-standardized road layer. It snaps
-- the new geometry to a 2-ft grid and then updates the intersection
-- information. The geometry matches an existing intersection if it
-- is within 5 ft of another intersection.
--
-- N.B. If the end of a cul-de-sac is moved, the old intersection point
-- is deleted and a new one is created. This should be an edge case
-- and wouldn't cause any problems anyway. A fix to move the intersection
-- point rather than create a new one would complicate the code and the
-- current behavior isn't really problematic.
--------------------------------------------------------------------------

DECLARE
    inttable TEXT;
    legs INT;
    startintersection RECORD;
    endintersection RECORD;

BEGIN
    --get the intersection table
    inttable := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME || '_intersections';

    --suspend triggers on the intersections table so that our
    --changes are not ignored.
    EXECUTE 'ALTER TABLE ' || inttable || ' DISABLE TRIGGER ALL;';

    --trigger operation
    IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
        --snap new geom
        NEW.geom := ST_SnapToGrid(NEW.geom,2);

        -------------------
        --  START POINT  --
        -------------------
        --do nothing if startpoint didn't change
        IF (TG_OP = 'INSERT' OR NOT (ST_StartPoint(NEW.geom) = ST_StartPoint(OLD.geom))) THEN
            -- get new start intersection data if it already exists
            EXECUTE '
                SELECT  id, geom, legs
                FROM ' || inttable || '
                WHERE       ST_DWithin(geom,ST_StartPoint($1.geom),5)
                AND         geom <#> $1.geom <= 5
                ORDER BY    geom <#> ST_StartPoint($1.geom) ASC
                LIMIT       1;'
            INTO    startintersection
            USING   NEW,
                    NEW,
                    NEW;

            -- insert/update intersections and new record
            IF startintersection.id IS NULL THEN
                EXECUTE '
                    INSERT INTO ' || inttable || ' (geom, legs)
                    SELECT ST_StartPoint($1.geom), 1
                    RETURNING id;'
                INTO    NEW.intersection_from
                USING   NEW;
            ELSE
                NEW.intersection_from := startintersection.id;
                EXECUTE '
                    UPDATE ' || inttable || '
                    SET     legs = COALESCE(legs,0) + 1
                    WHERE   id = $1;'
                USING   startintersection.id;
            END IF;
        END IF;


        -------------------
        --   END POINT   --
        -------------------
        --do nothing if startpoint didn't change
        IF (TG_OP = 'INSERT' OR NOT (ST_EndPoint(NEW.geom) = ST_EndPoint(OLD.geom))) THEN
            -- get end intersection data if it already exists
            EXECUTE '
                SELECT  id, geom, legs
                FROM ' || inttable || '
                WHERE       ST_DWithin(geom,ST_EndPoint($1.geom),5)
                AND         geom <#> $1.geom <= 5
                ORDER BY    geom <#> ST_EndPoint($1.geom) ASC
                LIMIT       1;'
            INTO    endintersection
            USING   NEW,
                    NEW,
                    NEW;

            -- insert/update intersections and new record
            IF endintersection.id IS NULL THEN
                EXECUTE '
                    INSERT INTO ' || inttable || ' (geom, legs)
                    SELECT ST_EndPoint($1.geom), 1
                    RETURNING id;'
                INTO    NEW.intersection_to
                USING   NEW;
            ELSE
                NEW.intersection_to := endintersection.id;
                EXECUTE '
                    UPDATE ' || inttable || '
                    SET     legs = COALESCE(legs,0) + 1
                    WHERE   id = $1;'
                USING   endintersection.id;
            END IF;
        END IF;
    END IF;

    IF (TG_OP = 'DELETE' OR TG_OP = 'UPDATE') THEN
        -------------------
        --  START POINT  --
        -------------------
        --do nothing if startpoint didn't change
        IF (TG_OP = 'DELETE' OR NOT (ST_StartPoint(NEW.geom) = ST_StartPoint(OLD.geom))) THEN
            -- get start intersection legs
            EXECUTE '
                SELECT  legs
                FROM ' || inttable || '
                WHERE   id = $1.intersection_from;'
            INTO    legs
            USING   OLD;

            IF legs > 1 THEN
                EXECUTE '
                    UPDATE ' || inttable || '
                    SET     legs = legs - 1
                    WHERE   id = $1.intersection_from;'
                USING   OLD;
            ELSE
                EXECUTE '
                    DELETE FROM ' || inttable || '
                    WHERE   id = $1.intersection_from;'
                USING   OLD;
            END IF;
        END IF;


        -------------------
        --   END POINT   --
        -------------------
        --do nothing if endpoint didn't change
        IF (TG_OP = 'DELETE' OR NOT (ST_EndPoint(NEW.geom) = ST_EndPoint(OLD.geom))) THEN
            -- get end intersection legs
            EXECUTE '
                SELECT  legs
                FROM ' || inttable || '
                WHERE   id = $1.intersection_to;'
            INTO    legs
            USING   OLD;

            IF legs > 1 THEN
                EXECUTE '
                    UPDATE ' || inttable || '
                    SET     legs = legs - 1
                    WHERE   id = $1.intersection_to;'
                USING   OLD;
            ELSE
                EXECUTE '
                    DELETE FROM ' || inttable || '
                    WHERE   id = $1.intersection_to;'
                USING   OLD;
            END IF;
        END IF;
    END IF;

    --re-enable triggers on the intersections table
    EXECUTE 'ALTER TABLE ' || inttable || ' ENABLE TRIGGER ALL;';

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdgUpdateIntersections() OWNER TO gis;
