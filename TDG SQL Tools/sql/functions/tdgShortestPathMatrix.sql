CREATE OR REPLACE FUNCTION tdg.tdgShortestPathMatrix (
    road_table_ REGCLASS,
    from_to_pairs_ INTEGER[],
    schema_name_ TEXT,
    table_name_ TEXT,
    overwrite_ BOOLEAN,
    append_ BOOLEAN,
    map_ BOOLEAN,
    stress_ INTEGER DEFAULT NULL)
RETURNS BOOLEAN AS $func$

DECLARE
    int_table REGCLASS;
    link_table REGCLASS;
    vert_table REGCLASS;
    output_table TEXT;
    namecheck TEXT;
    srid INT;

BEGIN
    -- get network tables
    BEGIN
        int_table := road_table_ || '_intersections';
        link_table := road_table_ || '_net_link';
        vert_table := road_table_ || '_net_vert';
    EXCEPTION
        WHEN undefined_table THEN
        RAISE EXCEPTION 'Table % is not a networked road layer', road_table_
        USING HINT = 'A networked road layer has
            accompanying intersection, link, and vertex tables.';
    END;

    -- combine table and schema
    EXECUTE 'CREATE SCHEMA IF NOT EXISTS '||schema_name_||';';
    output_table := schema_name_ || '.' || table_name_;

    -- delete old table
    IF overwrite_ THEN
        EXECUTE 'DROP TABLE IF EXISTS '||table_name_||';';
    END IF;

    IF append_ THEN
        RAISE NOTICE 'Checking whether table % exists',output_table;
        EXECUTE '   SELECT  output_table
                    FROM    tdgTableDetails($1)'
        USING   output_table
        INTO    namecheck;

        IF namecheck IS NULL THEN
            RAISE EXCEPTION 'Table % does not exist. Cannot append data.', output_table;
        END IF;

        -- drop indexes
        EXECUTE '
            DROP INDEX IF EXISTS sidx_'||table_name_||'_geom;
            DROP INDEX IF EXISTS idx_'||table_name_||'_pathid;
            DROP INDEX IF EXISTS idx_'||table_name_||'_seq;
            DROP INDEX IF EXISTS idx_'||table_name_||'_link;
            DROP INDEX IF EXISTS idx_'||table_name_||'_road;
            DROP INDEX IF EXISTS idx_'||table_name_||'_vert;
            DROP INDEX IF EXISTS idx_'||table_name_||'_int;
        ';
    ELSE        --create table
        EXECUTE 'CREATE TABLE '||output_table||' (
            id SERIAL PRIMARY KEY,
            path_id INT,
            from_vert INT,
            to_vert INT,
            move_sequence INT,
            link_id INT,
            vert_id INT,
            road_id INT,
            int_id INT,
            move_cost INT,
            cumulative_cost INT
        );';
    END IF;

    RAISE NOTICE 'Getting shortest paths';
    EXECUTE '
        INSERT INTO '||output_table||' (
            path_id,
            from_vert,
            to_vert,
            move_sequence,
            link_id,
            vert_id,
            road_id,
            int_id,
            move_cost,
            cumulative_cost
        )
        SELECT * FROM tdg.tdgShortestPathVerts($1,$2,$3,$4);'
    USING   link_table,
            vert_table,
            from_to_pairs_,
            stress_;

    -- get geoms if map_
    IF map_ THEN
        RAISE NOTICE 'Adding geometry data';
        -- get srid
        RAISE NOTICE 'Getting SRID of geometry';
        EXECUTE 'SELECT tdgGetSRID($1,$2);'
        USING   road_table_,
                'geom'
        INTO    srid;

        -- add geom column if not append_
        IF NOT append_ THEN
            EXECUTE '
                ALTER TABLE '||output_table||'
                ADD COLUMN geom geometry(linestring,'||srid::TEXT||');';
        END IF;

        -- update
        EXECUTE '
            UPDATE '||output_table||'
            SET     geom = roads.geom
            FROM    '||road_table_||' roads
            WHERE   roads.road_id = '||output_table||'.road_id;';

        -- spatial index
        EXECUTE '
            CREATE INDEX sidx_'||table_name_||'_geom
            ON '||output_table||' USING GIST (geom);';
    END IF;

    -- other indexes
    RAISE NOTICE 'Creating indexes';
    EXECUTE '
        CREATE INDEX idx_'||table_name_||'_pathid ON '||output_table||' (path_id);
        CREATE INDEX idx_'||table_name_||'_seq ON '||output_table||' (move_sequence);
        CREATE INDEX idx_'||table_name_||'_link ON '||output_table||' (link_id);
        CREATE INDEX idx_'||table_name_||'_road ON '||output_table||' (road_id);
        CREATE INDEX idx_'||table_name_||'_vert ON '||output_table||' (vert_id);
        CREATE INDEX idx_'||table_name_||'_int ON '||output_table||' (int_id);
    ';

    -- analyze
    EXECUTE 'ANALYZE '||output_table||';';

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgShortestPathMatrix(REGCLASS,INTEGER[],TEXT,TEXT,
    BOOLEAN,BOOLEAN,BOOLEAN,INTEGER) OWNER TO gis;
