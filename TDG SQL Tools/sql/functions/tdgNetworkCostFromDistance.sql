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
            UPDATE '||link_table||'
            SET     link_cost = ROUND((source_road_length + target_road_length) / 2);';
    ELSE
        EXECUTE '
            UPDATE '||link_table||'
            SET     link_cost = ROUND((source_road_length + target_road_length) / 2)
            WHERE   (target_road_id = ANY ($1) OR source_road_id = ANY ($1));'
        USING   road_ids_;
    END IF;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgNetworkCostFromDistance(REGCLASS,INTEGER[]) OWNER TO gis;
