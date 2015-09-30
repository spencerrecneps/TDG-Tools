CREATE OR REPLACE FUNCTION tdg.tdgSetRoadIntersections(
    int_table_ REGCLASS,
    road_table_ REGCLASS,
    road_ids_ INTEGER[] DEFAULT NULL)
RETURNS BOOLEAN AS $func$

BEGIN
    --compile list of int_ids_ if needed
    IF road_ids_ IS NULL THEN
        EXECUTE '
            UPDATE  '||road_table_||'
            SET     intersection_from = ints.int_id
            FROM    '||int_table_||' ints
            WHERE   ints.geom = ST_StartPoint('||road_table_||'.geom)
            AND     ints.z_elev = '||road_table_||'.z_from;
            UPDATE  '||road_table_||'
            SET     intersection_to = ints.int_id
            FROM    '||int_table_||' ints
            WHERE   ints.geom = ST_EndPoint('||road_table_||'.geom)
            AND     ints.z_elev = '||road_table_||'.z_to;';
    ELSE
        EXECUTE '
            UPDATE  '||road_table_||'
            SET     intersection_from = ints.int_id
            FROM    '||int_table_||' ints
            WHERE   ints.geom = ST_StartPoint('||road_table_||'.geom)
            AND     ints.z_elev = '||road_table_||'.z_from
            AND     road_id = ANY ($1);
            UPDATE  '||road_table_||'
            SET     intersection_to = ints.int_id
            FROM    '||int_table_||' ints
            WHERE   ints.geom = ST_EndPoint('||road_table_||'.geom)
            AND     ints.z_elev = '||road_table_||'.z_to
            AND     road_id = ANY ($1);'
        USING   road_ids_;
    END IF;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgSetRoadIntersections(REGCLASS,REGCLASS,INTEGER[]) OWNER TO gis;
