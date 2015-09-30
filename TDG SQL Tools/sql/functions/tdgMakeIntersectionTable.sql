CREATE OR REPLACE FUNCTION tdg.tdgMakeIntersectionTable (road_table_ REGCLASS)
RETURNS BOOLEAN AS $func$

DECLARE
    schema_name TEXT;
    table_name TEXT;
    int_table TEXT;
    srid INT;

BEGIN
    -- set table name and schema
    RAISE NOTICE 'Getting table details for %',road_table_;
    EXECUTE '   SELECT  schema_name, table_name
                FROM    tdgTableDetails($1::TEXT)'
    USING   road_table_
    INTO    schema_name, table_name;

    int_table = schema_name || '.' || table_name || '_intersections';

    -- get srid of the geom
    RAISE NOTICE 'Getting SRID of geometry';
    EXECUTE 'SELECT tdgGetSRID($1,$2);'
    USING   road_table_,
            'geom'
    INTO    srid;

    IF srid IS NULL THEN
        RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', table_name;
    END IF;
    raise NOTICE '  -----> SRID found %',srid;

    -- create the intersection table
    BEGIN
        RAISE NOTICE 'Creating table %', int_table;
        EXECUTE format('
            CREATE TABLE %s (   int_id serial PRIMARY KEY,
                                geom geometry(point,%L),
                                z_elev INT NOT NULL DEFAULT 0,
                                legs INT,
                                signalized BOOLEAN);
            ',  int_table,
                srid);
    END;

    RETURN 't';

END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeIntersectionTable(REGCLASS) OWNER TO gis;
