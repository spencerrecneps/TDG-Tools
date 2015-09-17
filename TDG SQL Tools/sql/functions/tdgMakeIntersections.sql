CREATE OR REPLACE FUNCTION tdg.tdgMakeIntersections (
    input_table_ REGCLASS,
    z_vals_ BOOLEAN DEFAULT 'f')
RETURNS BOOLEAN AS $func$

DECLARE
    namecheck RECORD;
    schema_name TEXT;
    table_name TEXT;
    inttable text;
    sridinfo record;
    srid INT;

BEGIN
    RAISE NOTICE 'PROCESSING:';

    --check table and schema
    BEGIN
        RAISE NOTICE 'Getting table details for %',input_table_;
        EXECUTE '   SELECT  schema_name, table_name
                    FROM    tdgTableDetails($1::TEXT)'
        USING   input_table_
        INTO    schema_name, table_name;

        inttable = schema_name || '.' || table_name || '_intersections';
    END;

    --get srid of the geom
    BEGIN
        RAISE NOTICE 'Getting SRID of geometry';
        EXECUTE 'SELECT tdgGetSRID($1,$2);'
        USING   input_table_,
                'geom'
        INTO    srid;

        IF srid IS NULL THEN
            RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', table_name;
        END IF;
        raise NOTICE '  -----> SRID found %',srid;
    END;

    BEGIN
        RAISE NOTICE 'creating intersection table';
        EXECUTE format('
            CREATE TABLE %s (   int_id serial PRIMARY KEY,
                                geom geometry(point,%L),
                                z_elev INT NOT NULL DEFAULT 0,
                                legs INT,
                                signalized BOOLEAN);
            ',  inttable,
                srid);
    END;

    --add intersections to table
    BEGIN
        RAISE NOTICE 'adding intersections';

        EXECUTE '
            CREATE TEMP TABLE v (i INT, z INT, geom geometry(POINT,'||srid::TEXT||'))
            ON COMMIT DROP;
            INSERT INTO v (i, z, geom)
                SELECT      road_id, z_from, ST_StartPoint(geom)
                FROM        ' || input_table_ || '
                ORDER BY    road_id ASC;
            INSERT INTO v (i, z, geom)
                SELECT      road_id, z_to, ST_EndPoint(geom)
                FROM        ' || input_table_ || '
                ORDER BY    road_id ASC;
            INSERT INTO ' || inttable || ' (legs, z_elev, geom)
                SELECT      COUNT(i), COALESCE(z,0), geom
                FROM        v
                GROUP BY    COALESCE(z,0), geom;';
    END;

    EXECUTE format('ANALYZE %s;', inttable);

    -- add intersection data to roads
    BEGIN
        RAISE NOTICE 'populating intersection data in roads table';
        EXECUTE format('
            UPDATE  %s
            SET     intersection_from = if.int_id,
                    intersection_to = it.int_id
            FROM    %s if,
                    %s it
            WHERE   ST_StartPoint(%s.geom) = if.geom
            AND     %s.z_from = if.z_elev
            AND     ST_EndPoint(%s.geom) = it.geom
            AND     %s.z_to = it.z_elev;
            ',  input_table_,
                inttable,
                inttable,
                input_table_,
                input_table_,
                input_table_,
                input_table_);
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
ALTER FUNCTION tdg.tdgMakeIntersections(REGCLASS,BOOLEAN) OWNER TO gis;
