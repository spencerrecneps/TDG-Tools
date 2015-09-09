CREATE OR REPLACE FUNCTION tdgUpdateIntersections ()
RETURNS TRIGGER
AS $BODY$

DECLARE
    inttable TEXT;
    legs INT;
    startintersection RECORD;
    endintersection RECORD;

BEGIN
    inttable := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME || '_intersections';

    IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
        --snap new geom
        NEW.geom := ST_SnapToGrid(NEW.geom,2);

        -------------------
        --  START POINT  --
        -------------------
        -- get start intersection data if it already exists
        EXECUTE '
            SELECT  id, geom, legs
            FROM ' || inttable || '
            WHERE   geom = ST_StartPoint($1.geom);'
        INTO    startintersection
        USING   NEW;


        -- need to add some logic in here to not create a new intersection
        -- when the update simply moves an existing endpoint with legs = 1
        -- perhaps treat as entirely different IF clause at beginning?


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


        -------------------
        --   END POINT   --
        -------------------
        -- get end intersection data if it already exists
        EXECUTE '
            SELECT  id, geom, legs
            FROM ' || inttable || '
            WHERE   geom = ST_EndPoint($1.geom);'
        INTO    endintersection
        USING   NEW;

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

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdgUpdateIntersections() OWNER TO gis;



-- http://www.postgresql.org/docs/current/static/plpgsql-trigger.html
