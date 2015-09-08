CREATE OR REPLACE FUNCTION tdgUpdateIntersections ()
RETURNS TRIGGER
AS $BODY$

DECLARE
    inttable TEXT;
    legs INT;
    newpointexists BOOLEAN;

BEGIN
    inttable := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME || '_intersections';

    IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
        --snap new geom
        NEW.geom := ST_SnapToGrid(NEW.geom,2);

        -------------------
        --  START POINT  --
        -------------------
        --test whether the start point changed
        IF NOT ST_StartPoint(NEW.geom) = ST_StartPoint(OLD.geom) THEN

            --test old start intersection point for number of legs
            EXECUTE 'SELECT legs FROM ' || inttable || ' WHERE id = $1.intersection_from;'
            INTO    legs
            USING   NEW;

            --test new start intersection point to see if it already exists
            EXECUTE '
                SELECT  1
                FROM ' || inttable || '
                WHERE   geom = ST_StartPoint($1.geom)
                AND     NOT id = $1.intersection_from;'
            INTO    newpointexists
            USING   NEW;
            newpointexists := COALESCE(newpointexists,0::BOOLEAN);

            IF legs = 1 THEN
                IF newpointexists THEN
                    --delete old intersection point
                    EXECUTE 'DELETE FROM ' || inttable || ' WHERE id = $1.intersection_from;'
                    USING NEW;
                ELSE --new location doesn't already exist
                    --move intersection point to new road startpoint
                    EXECUTE '
                        UPDATE ' || inttable || '
                        SET     geom = ST_StartPoint($1.geom)
                        WHERE   id = $2.intersection_from;'
                    USING   NEW,
                            NEW;
                END IF;
            ELSE --legs != 1
                IF NOT newpointexists THEN
                    --create new intersection point at road startpoint (if applicable)
                    EXECUTE '   INSERT INTO ' || inttable || '(geom)
                                SELECT  ST_StartPoint($1.geom);'
                    USING   NEW;
                END IF;
            END IF;

            --update road with new intersection point
            EXECUTE '
                SELECT  id
                FROM '  || inttable || ' ints
                WHERE   ints.geom = ST_StartPoint($1.geom);'
            INTO NEW.intersection_from
            USING NEW;

            --update legs on old and new intersections
            IF legs > 1 OR newpointexists THEN
                EXECUTE '
                    UPDATE ' || inttable || '
                    SET     legs = legs - 1
                    WHERE   id = $1.intersection_from;'
                USING OLD;

                EXECUTE '
                    UPDATE ' || inttable || '
                    SET     legs = COALESCE(legs,0) + 1
                    WHERE   id = $1.intersection_from;'
                USING NEW;
            END IF;
        END IF;


        -------------------
        --  END POINT  --
        -------------------
        --test whether the end point changed
        IF NOT ST_EndPoint(NEW.geom) = ST_EndPoint(OLD.geom) THEN

            --test old end intersection point for number of legs
            legs := NULL;
            EXECUTE 'SELECT legs FROM ' || inttable || ' WHERE id = $1.intersection_to;'
            INTO    legs
            USING   NEW;

            --test new end intersection point to see if it already exists
            newpointexists := NULL;
            EXECUTE '
                SELECT  1
                FROM ' || inttable || '
                WHERE   geom = ST_EndPoint($1.geom)
                AND     NOT id = $1.intersection_to;'
            INTO    newpointexists
            USING   NEW;
            newpointexists := COALESCE(newpointexists,0::BOOLEAN);

            IF legs = 1 THEN
                IF newpointexists THEN
                    --delete old intersection point
                    EXECUTE 'DELETE FROM ' || inttable || ' WHERE id = $1.intersection_to;'
                    USING NEW;
                ELSE --new location doesn't already exist
                    --move intersection point to new road endpoint
                    EXECUTE '
                        UPDATE ' || inttable || '
                        SET     geom = ST_EndPoint($1.geom)
                        WHERE   id = $2.intersection_to;'
                    USING   NEW,
                            NEW;
                END IF;
            ELSE --legs != 1
                IF NOT newpointexists THEN
                    --create new intersection point at road endpoint (if applicable)
                    EXECUTE '   INSERT INTO ' || inttable || '(geom)
                                SELECT  ST_EndPoint($1.geom);'
                    USING   NEW;
                END IF;
            END IF;

            --update road with new intersection point
            EXECUTE '
                SELECT  id
                FROM '  || inttable || ' ints
                WHERE   ints.geom = ST_EndPoint($1.geom);'
            INTO NEW.intersection_to
            USING NEW;

            --update legs on old and new intersections
            IF legs > 1 OR newpointexists THEN
                EXECUTE '
                    UPDATE ' || inttable || '
                    SET     legs = legs - 1
                    WHERE   id = $1.intersection_to;'
                USING OLD;

                EXECUTE '
                    UPDATE ' || inttable || '
                    SET     legs = COALESCE(legs,0) + 1
                    WHERE   id = $1.intersection_to;'
                USING NEW;
            END IF;
        END IF;

    ELSIF TG_OP = 'DELETE' THEN

    END IF;

    RETURN NEW;
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdgUpdateIntersections() OWNER TO gis;



-- http://www.postgresql.org/docs/current/static/plpgsql-trigger.html
