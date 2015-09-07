CREATE OR REPLACE FUNCTION tdgAddIntersections ()
RETURNS TRIGGER
AS $BODY$

DECLARE
    inttable TEXT;

BEGIN
    inttable := TG_TABLE_NAME || '_intersections';

    IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
        --create new intersection point at road startpoint (if applicable)
        EXECUTE format('
            INSERT INTO %s (geom)
            SELECT  ST_StartPoint(newrow.geom)
            FROM (SELECT NEW.*) AS newrow
            WHERE   NOT EXISTS (SELECT  1
                                FROM    %s ints
                                WHERE   ints.geom = ST_StartPoint(newrow.geom));
            ',  inttable,
                inttable);

        --update road with new intersection point
        EXECUTE format('
            SELECT  id
            FROM    %s
            WHERE   %s.geom = ST_StartPoint(NEW.geom);
            ') INTO NEW.intersection_from;


        --create new intersection point at road endpoint (if applicable)
        EXECUTE format('
            INSERT INTO %s (geom)
            SELECT  ST_StartPoint(NEW.geom)
            WHERE   NOT EXISTS (SELECT  1
                                FROM    %s ints
                                WHERE   ints.geom = ST_EndPoint(NEW.geom));
            ',  inttable,
                inttable);

        --update road with new intersection point
        EXECUTE format('
            SELECT  id
            FROM    %s
            WHERE   %s.geom = ST_EndPoint(NEW.geom);
            ') INTO NEW.intersection_to;

    ELSIF TG_OP = 'DELETE' THEN

    END IF;

    RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdgAddIntersections() OWNER TO gis;



-- http://www.postgresql.org/docs/current/static/plpgsql-trigger.html
