CREATE OR REPLACE FUNCTION tdgUpdateIntersections ()
RETURNS TRIGGER
AS $BODY$

DECLARE
    inttable TEXT;

BEGIN
    inttable := TG_TABLE_NAME || '_intersections';

    IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN

        --create new intersection point at road startpoint (if applicable)
        EXECUTE '   INSERT INTO ' || inttable || '(geom)
                    SELECT  ST_StartPoint($2.geom)
                    WHERE   NOT EXISTS (SELECT  1
                                        FROM    ' || inttable || ' ints
                                        WHERE   ints.geom = ST_StartPoint($2.geom));'
        USING   NEW,
                NEW;

        --update road with new intersection point
        EXECUTE '
            SELECT  id
            FROM '  || inttable || ' ints
            WHERE   ints.geom = ST_StartPoint($1.geom);
            '
        INTO NEW.intersection_from
        USING NEW;


        --create new intersection point at road endpoint (if applicable)
        EXECUTE '   INSERT INTO ' || inttable || '(geom)
                    SELECT  ST_EndPoint($2.geom)
                    WHERE   NOT EXISTS (SELECT  1
                                        FROM    ' || inttable || ' ints
                                        WHERE   ints.geom = ST_EndPoint($2.geom));'
        USING   NEW,
                NEW;

        --update road with new intersection point
        EXECUTE '
            SELECT  id
            FROM '  || inttable || ' ints
            WHERE   ints.geom = ST_EndPoint($1.geom);
            '
        INTO NEW.intersection_to
        USING NEW;

    ELSIF TG_OP = 'DELETE' THEN

    END IF;

    RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdgUpdateIntersections() OWNER TO gis;



-- http://www.postgresql.org/docs/current/static/plpgsql-trigger.html
