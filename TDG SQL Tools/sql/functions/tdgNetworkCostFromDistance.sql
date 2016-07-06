CREATE OR REPLACE FUNCTION tdg.tdgNetworkCostFromDistance(
    road_table_ REGCLASS,
    road_ids_ INTEGER[] DEFAULT NULL)
--populate cross-street data
RETURNS BOOLEAN AS $func$

DECLARE
    vert_table REGCLASS;

BEGIN
    raise notice 'PROCESSING:';

    vert_table = road_table_ || '_net_vert';

    IF road_ids_ IS NULL THEN
        EXECUTE '
            UPDATE  '||vert_table||'
            SET     vert_cost = ST_Length(r.geom)
            FROM    '||road_table_||' r
            WHERE   r.road_id = '||vert_table||'.road_id;';
    ELSE
        EXECUTE '
            UPDATE  '||vert_table||'
            SET     vert_cost = ST_Length(r.geom)
            FROM    '||road_table_||' r
            WHERE   r.road_id = '||vert_table||'.road_id
            AND     r.road_id = ANY ($1);'
        USING   road_ids_;
    END IF;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgNetworkCostFromDistance(REGCLASS,INTEGER[]) OWNER TO gis;
