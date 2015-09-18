CREATE OR REPLACE FUNCTION tdg.tdgMakeIntersections (input_table REGCLASS)
RETURNS BOOLEAN AS $func$

DECLARE
    namecheck RECORD;
    schema_name TEXT;
    table_name TEXT;
    inttable text;
    sridinfo record;
    srid int;

BEGIN
    RAISE NOTICE 'PROCESSING:';

    --check table and schema
    BEGIN
        RAISE NOTICE 'Getting table details for %',input_table;
        EXECUTE '   SELECT  schema_name, table_name
                    FROM    tdgTableDetails($1::TEXT)'
        USING   input_table
        INTO    schema_name, table_name;

        inttable = schema_name || '.' || table_name || '_intersections';
    END;

    --get srid of the geom
    BEGIN
        EXECUTE 'SELECT tdgGetSRID($1,$2);'
        USING   input_table,
                'geom'
        INTO    srid;

        IF srid IS NULL THEN
            RAISE EXCEPTION 'Could not determine SRID of ', input_table;
        END IF;
        RAISE NOTICE '  -----> SRID found %',srid;
    END;

    BEGIN
        RAISE NOTICE 'creating intersection table';
        EXECUTE format('
            CREATE TABLE %s (   id serial PRIMARY KEY,
                                geom geometry(point,%L),
                                legs INT,
                                signalized BOOLEAN);
            ',  inttable,
                srid);
    END;

    BEGIN
        RAISE NOTICE 'adding intersections';
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
    END;

    EXECUTE format('ANALYZE %s;', inttable);

    -- add intersection data to roads
    BEGIN
        RAISE NOTICE 'populating intersection data in roads table';
        EXECUTE format('
            UPDATE  %s
            SET     intersection_from = if.id,
                    intersection_to = it.id
            FROM    %s if,
                    %s it
            WHERE   ST_StartPoint(%s.geom) = if.geom
            and     ST_EndPoint(%s.geom) = it.geom;
            ',  input_table,
                inttable,
                inttable,
                input_table,
                input_table);
    END;

    --triggers
    BEGIN
        EXECUTE format('
            CREATE TRIGGER tdg%sGeomPreventUpdate
                BEFORE UPDATE OF geom ON %s
                FOR EACH ROW
                EXECUTE PROCEDURE tdgTriggerDoNothing();
            ',  table_name || '_ints',
                inttable);
        EXECUTE format('
            CREATE TRIGGER tdg%sPreventInsDel
                BEFORE INSERT OR DELETE ON %s
                FOR EACH ROW
                EXECUTE PROCEDURE tdgTriggerDoNothing();
            ',  table_name || '_ints',
                inttable);
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeIntersections(REGCLASS) OWNER TO gis;
