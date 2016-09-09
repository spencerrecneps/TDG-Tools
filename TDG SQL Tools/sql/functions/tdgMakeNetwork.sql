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
                int_id INT,
                turn_angle INT,
                int_crossing BOOLEAN,
                int_stress INT,
                source_vert INT,
                source_road_id INT,
                source_road_dir VARCHAR(2),
                source_road_azi INT,
                source_stress INT,
                target_vert INT,
                target_road_id INT,
                target_road_dir VARCHAR(2),
                target_road_azi INT,
                target_stress INT,
                link_cost INT,
                link_stress INT,
                geom geometry(linestring,'||srid::TEXT||'));';
    END;


    -- create vertices
    EXECUTE '
        INSERT INTO '||vert_table||' (road_id,geom)
        SELECT  road.road_id,
                ST_LineInterpolatePoint(road.geom,0.5)
        FROM    '||road_table_||' road;';

    --vertex indices
    RAISE NOTICE 'Creating vertex indices';
    EXECUTE '
        CREATE INDEX sidx_'||table_name||'_vert_geom ON '||vert_table||'
            USING gist (geom);
        CREATE INDEX idx_'||table_name||'_vert_roadid ON '||vert_table||'(road_id);';


    EXECUTE 'ANALYZE '||vert_table||';';

    ---------------
    -- add links --
    ---------------
    -- two-way to two-way
    EXECUTE '
        INSERT INTO '||link_table||' (int_id, source_vert, target_vert, geom)
        SELECT  ints.int_id,
                vert1.vert_id,
                vert2.vert_id,
                ST_Makeline(vert1.geom,vert2.geom)
        FROM    '||int_table||' ints,
                '||vert_table||' vert1,
                '||road_table_||' roads1,
                '||vert_table||' vert2,
                '||road_table_||' roads2
        WHERE   vert1.road_id = roads1.road_id
        AND     vert2.road_id = roads2.road_id
        AND     ints.int_id IN (roads1.intersection_from, roads1.intersection_to)
        AND     ints.int_id IN (roads2.intersection_from, roads2.intersection_to)
        AND     roads1.one_way IS NULL
        AND     roads2.one_way IS NULL
        AND     roads1.road_id != roads2.road_id';

    -- two-way to from-to
    EXECUTE '
        INSERT INTO '||link_table||' (int_id, source_vert, target_vert, geom)
        SELECT  ints.int_id,
                vert1.vert_id,
                vert2.vert_id,
                ST_Makeline(vert1.geom,vert2.geom)
        FROM    '||int_table||' ints,
                '||vert_table||' vert1,
                '||road_table_||' roads1,
                '||vert_table||' vert2,
                '||road_table_||' roads2
        WHERE   vert1.road_id = roads1.road_id
        AND     vert2.road_id = roads2.road_id
        AND     ints.int_id IN (roads1.intersection_from, roads1.intersection_to)
        AND     ints.int_id = roads2.intersection_from
        AND     roads1.one_way IS NULL
        AND     roads2.one_way = $1
        AND     roads1.road_id != roads2.road_id'
    USING   'ft';

    -- two-way to to-from
    EXECUTE '
        INSERT INTO '||link_table||' (int_id, source_vert, target_vert, geom)
        SELECT  ints.int_id,
                vert1.vert_id,
                vert2.vert_id,
                ST_Makeline(vert1.geom,vert2.geom)
        FROM    '||int_table||' ints,
                '||vert_table||' vert1,
                '||road_table_||' roads1,
                '||vert_table||' vert2,
                '||road_table_||' roads2
        WHERE   vert1.road_id = roads1.road_id
        AND     vert2.road_id = roads2.road_id
        AND     ints.int_id IN (roads1.intersection_from, roads1.intersection_to)
        AND     ints.int_id = roads2.intersection_to
        AND     roads1.one_way IS NULL
        AND     roads2.one_way = $1
        AND     roads1.road_id != roads2.road_id'
    USING   'tf';

    -- from-to to two-way
    EXECUTE '
        INSERT INTO '||link_table||' (int_id, source_vert, target_vert, geom)
        SELECT  ints.int_id,
                vert1.vert_id,
                vert2.vert_id,
                ST_Makeline(vert1.geom,vert2.geom)
        FROM    '||int_table||' ints,
                '||vert_table||' vert1,
                '||road_table_||' roads1,
                '||vert_table||' vert2,
                '||road_table_||' roads2
        WHERE   vert1.road_id = roads1.road_id
        AND     vert2.road_id = roads2.road_id
        AND     ints.int_id = roads1.intersection_to
        AND     ints.int_id IN (roads2.intersection_from, roads2.intersection_to)
        AND     roads1.one_way = $1
        AND     roads2.one_way IS NULL
        AND     roads1.road_id != roads2.road_id'
    USING   'ft';

    -- from-to to from-to
    EXECUTE '
        INSERT INTO '||link_table||' (int_id, source_vert, target_vert, geom)
        SELECT  ints.int_id,
                vert1.vert_id,
                vert2.vert_id,
                ST_Makeline(vert1.geom,vert2.geom)
        FROM    '||int_table||' ints,
                '||vert_table||' vert1,
                '||road_table_||' roads1,
                '||vert_table||' vert2,
                '||road_table_||' roads2
        WHERE   vert1.road_id = roads1.road_id
        AND     vert2.road_id = roads2.road_id
        AND     ints.int_id = roads1.intersection_to
        AND     ints.int_id = roads2.intersection_from
        AND     roads1.one_way = $1
        AND     roads2.one_way = $1
        AND     roads1.road_id != roads2.road_id'
    USING   'ft';

    -- from-to to to-from
    EXECUTE '
        INSERT INTO '||link_table||' (int_id, source_vert, target_vert, geom)
        SELECT  ints.int_id,
                vert1.vert_id,
                vert2.vert_id,
                ST_Makeline(vert1.geom,vert2.geom)
        FROM    '||int_table||' ints,
                '||vert_table||' vert1,
                '||road_table_||' roads1,
                '||vert_table||' vert2,
                '||road_table_||' roads2
        WHERE   vert1.road_id = roads1.road_id
        AND     vert2.road_id = roads2.road_id
        AND     ints.int_id = roads1.intersection_to
        AND     ints.int_id = roads2.intersection_to
        AND     roads1.one_way = $1
        AND     roads2.one_way = $2
        AND     roads1.road_id != roads2.road_id'
    USING   'ft', 'tf';

    -- to-from to two-way
    EXECUTE '
        INSERT INTO '||link_table||' (int_id, source_vert, target_vert, geom)
        SELECT  ints.int_id,
                vert1.vert_id,
                vert2.vert_id,
                ST_Makeline(vert1.geom,vert2.geom)
        FROM    '||int_table||' ints,
                '||vert_table||' vert1,
                '||road_table_||' roads1,
                '||vert_table||' vert2,
                '||road_table_||' roads2
        WHERE   vert1.road_id = roads1.road_id
        AND     vert2.road_id = roads2.road_id
        AND     ints.int_id = roads1.intersection_from
        AND     ints.int_id IN (roads2.intersection_from, roads2.intersection_to)
        AND     roads1.one_way = $1
        AND     roads2.one_way IS NULL
        AND     roads1.road_id != roads2.road_id'
    USING   'tf';

    -- to-from to to-from
    EXECUTE '
        INSERT INTO '||link_table||' (int_id, source_vert, target_vert, geom)
        SELECT  ints.int_id,
                vert1.vert_id,
                vert2.vert_id,
                ST_Makeline(vert1.geom,vert2.geom)
        FROM    '||int_table||' ints,
                '||vert_table||' vert1,
                '||road_table_||' roads1,
                '||vert_table||' vert2,
                '||road_table_||' roads2
        WHERE   vert1.road_id = roads1.road_id
        AND     vert2.road_id = roads2.road_id
        AND     ints.int_id = roads1.intersection_from
        AND     ints.int_id = roads2.intersection_to
        AND     roads1.one_way = $1
        AND     roads2.one_way = $1
        AND     roads1.road_id != roads2.road_id'
    USING   'tf';

    -- to-from to from-to
    EXECUTE '
        INSERT INTO '||link_table||' (int_id, source_vert, target_vert, geom)
        SELECT  ints.int_id,
                vert1.vert_id,
                vert2.vert_id,
                ST_Makeline(vert1.geom,vert2.geom)
        FROM    '||int_table||' ints,
                '||vert_table||' vert1,
                '||road_table_||' roads1,
                '||vert_table||' vert2,
                '||road_table_||' roads2
        WHERE   vert1.road_id = roads1.road_id
        AND     vert2.road_id = roads2.road_id
        AND     ints.int_id = roads1.intersection_from
        AND     ints.int_id = roads2.intersection_from
        AND     roads1.one_way = $1
        AND     roads2.one_way = $2
        AND     roads1.road_id != roads2.road_id'
    USING   'tf', 'ft';

    --link indexes
    BEGIN
        RAISE NOTICE 'creating link indexes';
        EXECUTE '
            CREATE INDEX idx_'||table_name||'_vert_road_id ON '||vert_table||' (road_id);
            CREATE INDEX idx_'||table_name||'_link_int_id ON '||link_table||' (int_id);
            CREATE INDEX idx_'||table_name||'_link_src_trgt ON '||link_table||' (source_vert,target_vert);
            CREATE INDEX idx_'||table_name||'_link_src_rdid ON '||link_table||' (source_road_id);
            CREATE INDEX idx_'||table_name||'_link_tgt_rdid ON '||link_table||' (target_road_id);';
    END;

    BEGIN
        EXECUTE 'ANALYZE '||link_table||';';
        EXECUTE 'ANALYZE '||turnrestrict_table||';';
    END;

    --get source and target roads
    BEGIN
        RAISE NOTICE 'Setting source and target roads';
        --source road
        EXECUTE '
            UPDATE '||link_table||'
            SET     source_road_id = s_vert.road_id,
                    target_road_id = t_vert.road_id
            FROM    '||vert_table||' s_vert,
                    '||vert_table||' t_vert
            WHERE   '||link_table||'.source_vert = s_vert.vert_id
            AND     '||link_table||'.target_vert = t_vert.vert_id';
    END;

    --get road directions
    BEGIN
        RAISE NOTICE 'Setting road directions';
        --source_road_dir
        EXECUTE '
            UPDATE '||link_table||'
            SET     source_road_dir = CASE WHEN '||link_table||'.int_id = road.intersection_to THEN $1
                                    ELSE $2
                                    END
            FROM    '||road_table_||' road
            WHERE   '||link_table||'.source_road_id = road.road_id'
        USING   'ft', 'tf';
        --target_road_dir
        EXECUTE '
            UPDATE '||link_table||'
            SET     target_road_dir = CASE WHEN '||link_table||'.int_id = road.intersection_to THEN $1
                                    ELSE $2
                                    END
            FROM    '||road_table_||' road
            WHERE   '||link_table||'.target_road_id = road.road_id'
        USING   'ft', 'tf';
    END;

    --set azimuths and turn angles
    BEGIN
        RAISE NOTICE 'Setting azimuths';
        EXECUTE '
            UPDATE '||link_table||'
            SET     source_road_azi = CASE  WHEN source_road_dir = $1
                                            THEN degrees(ST_Azimuth(ST_LineInterpolatePoint(roads1.geom,0.5),ST_StartPoint(roads1.geom)))
                                            ELSE degrees(ST_Azimuth(ST_LineInterpolatePoint(roads1.geom,0.5),ST_EndPoint(roads1.geom)))
                                            END,
                    target_road_azi = CASE  WHEN target_road_dir = $1
                                            THEN degrees(ST_Azimuth(ST_StartPoint(roads2.geom),ST_LineInterpolatePoint(roads2.geom,0.5)))
                                            ELSE degrees(ST_Azimuth(ST_EndPoint(roads2.geom),ST_LineInterpolatePoint(roads2.geom,0.5)))
                                            END
            FROM    '||road_table_||' roads1,
                    '||road_table_||' roads2
            WHERE   source_road_id = roads1.road_id
            AND     target_road_id = roads2.road_id;'
        USING   'tf';
    END;
    BEGIN
        RAISE NOTICE 'Setting turn angles';
        EXECUTE '
            UPDATE '||link_table||'
            SET     turn_angle = (target_road_azi - source_road_azi + 360) % 360;';
    END;

    --set turn info
    BEGIN
        EXECUTE 'SELECT tdg.tdgSetTurnInfo($1)'
        USING   link_table;
    END;

    --add stress to links
    BEGIN
        RAISE NOTICE 'Setting stress on links';
        --source_stress
        EXECUTE '
            UPDATE '||link_table||'
            SET     source_stress = CASE WHEN '||link_table||'.int_id = road.intersection_to THEN road.ft_seg_stress
                                    ELSE road.tf_seg_stress
                                    END
            FROM    '||road_table_||' road
            WHERE   '||link_table||'.source_road_id = road.road_id';

        --int_stress
        EXECUTE '
            UPDATE '||link_table||'
            SET     int_stress = roads.ft_int_stress
            FROM    '||road_table_||' roads
            WHERE   '||link_table||'.source_road_id = roads.road_id
            AND     source_road_dir = $1;'
        USING   'ft';
        EXECUTE '
            UPDATE '||link_table||'
            SET     int_stress = roads.tf_int_stress
            FROM    '||road_table_||' roads
            WHERE   '||link_table||'.source_road_id = roads.road_id
            AND     source_road_dir = $1;'
        USING   'tf';
        EXECUTE '
            UPDATE '||link_table||'
            SET     int_stress = 1
            WHERE   NOT int_crossing;';

        --target_stress
        EXECUTE '
            UPDATE '||link_table||'
            SET     target_stress = CASE WHEN '||link_table||'.int_id = road.intersection_to THEN road.tf_seg_stress
                                    ELSE road.ft_seg_stress
                                    END
            FROM    '||road_table_||' road
            WHERE   '||link_table||'.target_road_id = road.road_id';

        --link_stress
        EXECUTE '
            UPDATE '||link_table||'
            SET     link_stress = GREATEST(source_stress,int_stress,target_stress)';
    END;
RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeNetwork(REGCLASS) OWNER TO gis;
