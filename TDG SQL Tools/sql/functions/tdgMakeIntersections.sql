CREATE OR REPLACE FUNCTION tdg.tdgMakeIntersections (
    road_table_ REGCLASS,
    z_vals_ BOOLEAN DEFAULT 'f')
RETURNS BOOLEAN AS $func$

DECLARE
    namecheck RECORD;
    schema_name TEXT;
    table_name TEXT;
    int_table TEXT;
    srid INT;

BEGIN
    RAISE NOTICE 'PROCESSING:';

    --check table and schema
    BEGIN
        RAISE NOTICE 'Getting table details for %',road_table_;
        EXECUTE '   SELECT  schema_name, table_name
                    FROM    tdgTableDetails($1::TEXT)'
        USING   road_table_
        INTO    schema_name, table_name;

        int_table = schema_name || '.' || table_name || '_intersections';
    END;

    --get srid of the geom
    BEGIN
        RAISE NOTICE 'Getting SRID of geometry';
        EXECUTE 'SELECT tdgGetSRID($1,$2);'
        USING   road_table_,
                'geom'
        INTO    srid;

        IF srid IS NULL THEN
            RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', table_name;
        END IF;
        raise NOTICE '  -----> SRID found %',srid;
    END;

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

    --add intersections to table
    BEGIN
        RAISE NOTICE 'Adding intersections';

        EXECUTE '
            CREATE TEMP TABLE tmp_v (i INT, z INT, geom geometry(POINT,'||srid::TEXT||'))
            ON COMMIT DROP;
            INSERT INTO tmp_v (i, z, geom)
                SELECT      road_id, z_from, ST_StartPoint(geom)
                FROM        ' || road_table_ || '
                ORDER BY    road_id ASC;
            INSERT INTO tmp_v (i, z, geom)
                SELECT      road_id, z_to, ST_EndPoint(geom)
                FROM        ' || road_table_ || '
                ORDER BY    road_id ASC;
            INSERT INTO ' || int_table || ' (legs, z_elev, geom)
                SELECT      COUNT(i), COALESCE(z,0), geom
                FROM        tmp_v
                GROUP BY    COALESCE(z,0), geom;';
    END;

    --intersection indices
    BEGIN
        EXECUTE '
            CREATE INDEX sidx_'||table_name||'_ints_geom
                ON '||int_table||' USING gist(geom);';
        EXECUTE '
            CREATE INDEX idx_'||table_name||'_ints_z_elev
                ON '||int_table||' (z_elev);';
    END;
    EXECUTE format('ANALYZE %s;', int_table);

    -- add intersection data to roads
    BEGIN
        RAISE NOTICE 'Populating intersection data in %', road_table_;
        EXECUTE '
            UPDATE  '||road_table_||'
            SET     intersection_from = if.int_id,
                    intersection_to = it.int_id
            FROM    '||int_table||' if,
                    '||int_table||' it
            WHERE   '||road_table_||'.geom <#> if.geom < 5
            AND     ST_StartPoint('||road_table_||'.geom) = if.geom
            AND     '||road_table_||'.z_from = if.z_elev
            AND     '||road_table_||'.geom <#> it.geom < 5
            AND     ST_EndPoint('||road_table_||'.geom) = it.geom
            AND     '||road_table_||'.z_to = it.z_elev;';
    END;

    --triggers to prevent changes
    EXECUTE 'SELECT tdgMakeIntersectionTriggers($1,$2);'
    USING   int_table,
            table_name;

    --triggers to update intersections when changes are made to roads
    EXECUTE 'SELECT tdgMakeRoadTriggers($1,$2);'
    USING   road_table_,
            table_name;

    --road intersection indexes
    BEGIN
        RAISE NOTICE 'Adding indices to %', road_table_;
        EXECUTE '
            CREATE INDEX idx_'||table_name||'_intfrom ON '||road_table_||' (intersection_from);
            CREATE INDEX idx_'||table_name||'_intto ON '||road_table_||' (intersection_to);';
    END;

    --not null on road intersections
    BEGIN
        RAISE NOTICE 'Setting column constraints on %', road_table_;
        EXECUTE '
            ALTER TABLE '||table_name||' ALTER COLUMN intersection_from SET NOT NULL;
            ALTER TABLE '||table_name||' ALTER COLUMN intersection_to SET NOT NULL;';
    END;

    RAISE NOTICE 'Analyzing';
    EXECUTE 'ANALYZE '||road_table_||';';
    EXECUTE 'ANALYZE '||int_table||';';

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeIntersections(REGCLASS,BOOLEAN) OWNER TO gis;
