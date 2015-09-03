CREATE OR REPLACE FUNCTION tdgUpdateIntersections ()
RETURNS TRIGGER
AS $BODY$

DECLARE
    inttable TEXT;

BEGIN
    inttable := TG_TABLE_NAME || '_intersections';
    
    IF (TG_OP = 'UPDATE') THEN

    ELSIF (TG_OP = 'DELETE') THEN

    ELSIF (TG_OP = 'INSERT') THEN

    END IF;

    RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdgMakeIntersections(REGCLASS) OWNER TO gis;



-- http://www.postgresql.org/docs/current/static/plpgsql-trigger.html
