CREATE OR REPLACE FUNCTION tdg.tdgInsertIntersections(
    int_table_ REGCLASS,
    road_table_ REGCLASS)
RETURNS BOOLEAN AS $func$

DECLARE
    rowcount INT;

BEGIN
    RAISE NOTICE 'Checking for existing intersections in %', int_table_;
    EXECUTE 'SELECT 1 FROM '||int_table_||' WHERE int_id IS NOT NULL;';
    GET DIAGNOSTICS rowcount = ROW_COUNT;

    IF rowcount > 0 THEN
        RAISE EXCEPTION 'Records already exist in %', int_table_
        USING HINT = 'Drop all existing records or use road_ids as an input.';
    END IF;

    RAISE NOTICE 'Inserting intersections into %', int_table_;
    EXECUTE '
        INSERT INTO '||int_table_||' (geom, z_elev)
        SELECT  ST_StartPoint(road_f.geom), road_f.z_from
        FROM    '||road_table_||' road_f
        UNION
        SELECT  ST_EndPoint(road_t.geom), road_t.z_to
        FROM    '||road_table_||' road_t';

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgInsertIntersections(REGCLASS,REGCLASS) OWNER TO gis;
