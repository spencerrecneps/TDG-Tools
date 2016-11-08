CREATE OR REPLACE FUNCTION tdg.tdgNetworkCostFromTime(
    road_table_ REGCLASS,
    speed_ FLOAT,
    feet_per_second_ BOOLEAN DEFAULT NULL,
    road_ids_ INTEGER[] DEFAULT NULL)
--populate cross-street data
RETURNS BOOLEAN AS $func$

DECLARE
    vert_table REGCLASS;
    speed_fps FLOAT;

BEGIN
    raise notice 'PROCESSING:';

    IF speed_ = 0 THEN
        RETURN 'f';
    END IF;

    vert_table = road_table_ || '_net_vert';

    -- convert to feet per second if necessary
    IF feet_per_second_ IS NULL THEN
        speed_fps := speed_ * 5280 / 3600;
    ELSE
        speed_fps := speed_;
    END IF;

    IF road_ids_ IS NULL THEN
        EXECUTE '
            UPDATE  '||vert_table||'
            SET     vert_cost = ST_Length(r.geom) / $1
            FROM    '||road_table_||' r
            WHERE   r.road_id = '||vert_table||'.road_id;'
        USING   speed_fps;
    ELSE
        EXECUTE '
            UPDATE  '||vert_table||'
            SET     vert_cost = ST_Length(r.geom) / $1
            FROM    '||road_table_||' r
            WHERE   r.road_id = '||vert_table||'.road_id
            AND     r.road_id = ANY ($1);'
        USING   speed_fps,
                road_ids_;
    END IF;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgNetworkCostFromTime(REGCLASS,FLOAT,BOOLEAN,INTEGER[]) OWNER TO gis;
