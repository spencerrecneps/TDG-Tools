CREATE OR REPLACE FUNCTION tdgAddIntersections ()
RETURNS TRIGGER
AS $BODY$

DECLARE
    inttable TEXT;

BEGIN
    inttable := TG_TABLE_NAME || '_intersections';

    '---------------------------------------------'
    'CHECK INTO "OLD TABLE" AND "NEW TABLE" CLAUSE'
    '---------------------------------------------'

    IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
        --create new intersection points
        EXECUTE format('
            INSERT INTO %s (geom)
            SELECT  ST_StartPoint(NEW.geom)
            WHERE   NOT EXISTS (SELECT  1
                                FROM    %s ints
                                WHERE   ints.geom = ST_StartPoint(NEW.geom));
            INSERT INTO %s (geom)
            SELECT  ST_EndPoint(NEW.geom)
            WHERE   NOT EXISTS (SELECT  1
                                FROM    %s ints
                                WHERE   ints.geom = ST_EndPoint(NEW.geom));
            ',  inttable,
                inttable,
                inttable,
                inttable);

        --update roads
        EXECUTE format('

            ')


        --delete intersections with 0 legs

        EXECUTE format('
            CREATE TEMP TABLE v (i INT, geom geometry(point,%L)) ON COMMIT DROP;
            INSERT INTO v (i, geom) SELECT id, ST_StartPoint(geom) FROM %s ORDER BY id ASC;
            INSERT INTO v (i, geom) SELECT id, ST_EndPoint(geom) FROM %s ORDER BY id ASC;
            INSERT INTO %s (legs, geom)
            SELECT      COUNT(i),
                        geom
            FROM        v
            GROUP BY    geom;
            ',  srid,
                input_table,
                input_table,
                inttable);

    END IF;

    RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdgAddIntersections() OWNER TO gis;



-- http://www.postgresql.org/docs/current/static/plpgsql-trigger.html
