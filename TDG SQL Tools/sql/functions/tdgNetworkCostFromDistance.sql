CREATE OR REPLACE FUNCTION tdg.tdgNetworkCostFromDistance(
    road_table_ REGCLASS,
    road_ids_ INTEGER[] DEFAULT NULL)
--populate cross-street data
RETURNS BOOLEAN AS $func$

DECLARE
    link_table REGCLASS;

BEGIN
    raise notice 'PROCESSING:';

    link_table = road_table_ || '_net_link';

    IF road_ids_ IS NULL THEN
        EXECUTE '
            UPDATE  '||link_table||'
            SET     link_cost = ROUND((ST_Length(source_road.geom) + ST_Length(target_road.geom))/2)
            FROM    '||road_table_||' source_road,
                    '||road_table_||' target_road
            WHERE   source_road.road_id = '||link_table||'.source_road_id
            AND     target_road.road_id = '||link_table||'.target_road_id;';
    ELSE
        EXECUTE '
            UPDATE  '||link_table||'
            SET     link_cost = ST_Length(r.geom)
            FROM    '||road_table_||' source_road,
                    '||road_table_||' target_road
            WHERE   source_road.road_id = '||link_table||'.source_road_id
            AND     target_road.road_id = '||link_table||'.target_road_id
            AND     (target_road_id = ANY ($1) OR source_road_id = ANY ($1));'
        USING   road_ids_;
    END IF;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgNetworkCostFromDistance(REGCLASS,INTEGER[]) OWNER TO gis;
