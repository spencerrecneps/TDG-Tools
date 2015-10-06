CREATE OR REPLACE FUNCTION tdg.tdgInsertIntersections(
    int_table_ REGCLASS,
    road_table_ REGCLASS,
    road_ids INTEGER[])
RETURNS BOOLEAN AS $func$

BEGIN
    RAISE NOTICE 'Inserting intersections into %', int_table_;

    -- create staging table
    DROP TABLE IF EXISTS tmp_ints;
    EXECUTE '
        CREATE TEMPORARY TABLE tmp_ints (
            geom geometry(point),
            z_elev INTEGER)
        ON COMMIT DROP;';

    -- add candidate points
    EXECUTE '
        INSERT INTO tmp_ints (geom, z_elev)
        SELECT  ST_StartPoint(road_f.geom), road_f.z_from
        FROM    '||road_table_||' road_f
        WHERE   road_f.road_id = ANY ($1);
        INSERT INTO tmp_ints (geom, z_elev)
        SELECT  ST_EndPoint(road_t.geom), road_t.z_to
        FROM    '||road_table_||' road_t
        WHERE   road_t.road_id = ANY ($1);'
    USING   road_ids;

    -- indexes
    EXECUTE '
        CREATE INDEX sidx_tmp_ints_geom ON tmp_ints USING GIST (geom);
        CREATE INDEX idx_tmp_ints_z_elev ON tmp_ints (z_elev);
        ANALYZE tmp_ints;';

    -- move to intersection table
    EXECUTE '
        INSERT INTO '||int_table_||' (geom, z_elev)
        SELECT DISTINCT geom, z_elev
        FROM tmp_ints
        WHERE NOT EXISTS (  SELECT  1
                            FROM    '||int_table_||' i
                            WHERE   tmp_ints.geom = i.geom
                            AND     tmp_ints.z_elev = i.z_elev)';

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgInsertIntersections(REGCLASS,REGCLASS,INTEGER[]) OWNER TO gis;
