CREATE OR REPLACE FUNCTION tdg.tdgMakeNetwork(road_table_ REGCLASS)
--need triggers to automatically update vertices and links
RETURNS BOOLEAN AS $func$

DECLARE
    schema_name TEXT;
    table_name TEXT;
    query TEXT;
    vert_table TEXT;
    link_table TEXT;
    turnrestrict_table TEXT;
    int_table REGCLASS;
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

        vert_table = schema_name || '.' || table_name || '_net_vert';
        link_table = schema_name || '.' || table_name || '_net_link';
        turnrestrict_table = schema_name || '.' || table_name || '_turn_restriction';
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
            RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', road_table_;
        END IF;
        raise NOTICE '  -----> SRID found %',srid;
    END;


    --drop old tables
    BEGIN
        RAISE NOTICE 'dropping any preexisting tables';
        EXECUTE '
            DROP TABLE IF EXISTS '||turnrestrict_table||';
            DROP TABLE IF EXISTS '||vert_table||';
            DROP TABLE IF EXISTS '||link_table||';';
    END;


    --create new tables
    BEGIN
        RAISE NOTICE 'creating vertices table';
        EXECUTE '
            CREATE TABLE '||vert_table||' (
                vert_id serial PRIMARY KEY,
                int_id INT,
                road_id INT,
                vert_cost INT,
                geom geometry(point,'||srid::TEXT||'));';

        RAISE NOTICE 'creating turn restrictions table';
        EXECUTE '
            CREATE TABLE '||turnrestrict_table||' (
                from_id integer NOT NULL,
                to_id integer NOT NULL,
                CONSTRAINT '||table_name||'_trn_rstrctn_check CHECK (from_id <> to_id));';

        RAISE NOTICE 'creating link table';
        EXECUTE '
            CREATE TABLE '||link_table||' (
                link_id SERIAL PRIMARY KEY,
                road_id INT,
                source_vert INT,
                target_vert INT,
                int_id INT,
                direction VARCHAR(2),
                movement TEXT,
                link_cost INT,
                link_stress INT,
                geom geometry(linestring,'||srid::TEXT||'));';
    END;


    -- create vertices
    EXECUTE '
        INSERT INTO '||vert_table||' (int_id,road_id,geom)
        SELECT  ints.int_id,
                road.road_id,
                (ST_Dump(ST_Intersection(ST_ExteriorRing(ST_Buffer(ints.geom,2)),road.geom))).geom
        FROM    '||int_table||' ints
        JOIN    '||road_table_||' road
                ON ints.int_id IN (road.intersection_from,road.intersection_to)
        WHERE   ints.legs > 2;';
    EXECUTE '
        INSERT INTO '||vert_table||' (int_id,geom)
        SELECT DISTINCT
            ints.int_id,
            ints.geom
        FROM    '||int_table||' ints
        JOIN    '||road_table_||' road
                ON ints.int_id IN (road.intersection_from,road.intersection_to)
        WHERE   ints.legs <= 2;';

    --vertex indices
    RAISE NOTICE 'Creating vertex indices';
    EXECUTE '
        CREATE INDEX sidx_'||table_name||'_vert_geom ON '||vert_table||'
            USING gist (geom);
        CREATE INDEX idx_'||table_name||'_vert_intid ON '||vert_table||'(int_id);
        CREATE INDEX idx_'||table_name||'_vert_roadid ON '||vert_table||'(road_id);';


    EXECUTE 'ANALYZE '||vert_table||';';

    ---------------
    -- add links --
    ---------------
    --ft self link
    EXECUTE '
        INSERT INTO '||link_table||' (
            road_id,
            direction,
            source_vert,
            target_vert,
            geom)
        SELECT  road.road_id,
                $1,
                vertsf.vert_id,
                vertst.vert_id,
                ST_Makeline(vertsf.geom,vertst.geom)
        FROM    '||road_table_||' road,
                '||vert_table||' vertsf,
                '||vert_table||' vertst
        WHERE   COALESCE(road.one_way,$1) = $1
        AND     COALESCE(vertsf.road_id,road.road_id) = road.road_id
        AND     vertsf.int_id = road.intersection_from
        AND     COALESCE(vertst.road_id,road.road_id) = road.road_id
        AND     vertst.int_id = road.intersection_to;'
    USING   'ft';

    --tf self link
    EXECUTE '
        INSERT INTO '||link_table||' (
            road_id,
            direction,
            source_vert,
            target_vert,
            geom)
        SELECT  road.road_id,
                $1,
                vertst.vert_id,
                vertsf.vert_id,
                ST_Makeline(vertst.geom,vertsf.geom)
        FROM    '||road_table_||' road,
                '||vert_table||' vertsf,
                '||vert_table||' vertst
        WHERE   COALESCE(road.one_way,$1) = $1
        AND     COALESCE(vertsf.road_id,road.road_id) = road.road_id
        AND     vertsf.int_id = road.intersection_from
        AND     COALESCE(vertst.road_id,road.road_id) = road.road_id
        AND     vertst.int_id = road.intersection_to;'
    USING   'tf';

    -- connector links
    EXECUTE '
        INSERT INTO '||link_table||' (
            geom,
            direction,
            int_id,
            source_vert,
            target_vert)
        SELECT  ST_Makeline(vert1.geom,vert2.geom),
                NULL,
                vert1.int_id,
                vert1.vert_id,
                vert2.vert_id
        FROM    '||vert_table||' vert1
        JOIN    '||vert_table||' vert2
                ON  vert1.vert_id != vert2.vert_id
                AND vert1.road_id != vert2.road_id
                AND vert1.int_id = vert2.int_id
        WHERE   vert1.road_id IS NOT NULL
        AND     vert2.road_id IS NOT NULL;';


    --set turn information intersection by intersections
    -- BEGIN
    --     EXECUTE format('
    --         SELECT tdgSetTurnInfo(%L,%L,%L,%L);
    --         ',  link_table,
    --             int_table,
    --             vert_table);
    -- END;


    --link indexes
    BEGIN
        RAISE NOTICE 'creating link indexes';
        EXECUTE '
            CREATE INDEX idx_'||table_name||'_link_road_id ON '||link_table||' (road_id);
            CREATE INDEX idx_'||table_name||'_link_direction ON '||link_table||' (direction);
            CREATE INDEX idx_'||table_name||'_link_src_trgt ON '||link_table||' (source_vert,target_vert);';
    END;

    BEGIN
        EXECUTE 'ANALYZE '||link_table||';';
        EXECUTE 'ANALYZE '||turnrestrict_table||';';
    END;
RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeNetwork(REGCLASS) OWNER TO gis;
