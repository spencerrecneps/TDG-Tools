CREATE OR REPLACE FUNCTION tdgUpdateIntersections ()
RETURNS TRIGGER
AS $BODY$

DECLARE
    inttable TEXT;

BEGIN
    inttable := TG_TABLE_NAME || '_intersections';

    IF (TG_OP = 'UPDATE') THEN
        --update old geoms of affected roads and intersections
        EXECUTE format('
            WITH counts AS (SELECT  ints.id id,
                                    COUNT(roads.id) c
                            FROM    %s ints
                            JOIN    TG_TABLE_NAME roads
                                    ON ints.geom IN (ST_StartPoint(roads.geom), ST_EndPoint(roads.geom))
                            WHERE   ints.id IN (OLD.intersection_from,OLD.intersection_to))
            UPDATE  %s
            SET     legs = counts.c
            FROM    counts
            WHERE   %s.id = counts.id;
            ',  inttable,
                inttable,
                inttable);

        --check for new geoms
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
    ELSIF (TG_OP = 'DELETE') THEN

    ELSIF (TG_OP = 'INSERT') THEN

    END IF;

    RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdgUpdateIntersections() OWNER TO gis;



-- http://www.postgresql.org/docs/current/static/plpgsql-trigger.html
