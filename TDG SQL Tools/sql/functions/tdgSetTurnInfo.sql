CREATE OR REPLACE FUNCTION tdg.tdgSetTurnInfo (
    link_table_ REGCLASS,
    int_ids_ INT[] DEFAULT NULL)
RETURNS BOOLEAN AS $func$

DECLARE
    temp_table TEXT;
    link_record RECORD;
    source_vert INT;

BEGIN
    --compile list of int_ids_ if needed
    IF int_ids_ IS NULL THEN
        -- assume crossing is true unless proven otherwise
        EXECUTE 'UPDATE '||link_table_||' SET int_crossing = $1'
        USING   't'::BOOLEAN;

        -- set right turns
        EXECUTE '
            UPDATE  '||link_table_||'
            SET     int_crossing = $1
            WHERE   link_id = (
                        SELECT      r.link_id
                        FROM        '||link_table_||' r
                        WHERE       '||link_table_||'.source_road_id = r.source_road_id
                        AND         '||link_table_||'.int_id = r.int_id
                        ORDER BY    (sin(radians(r.turn_angle))>0)::INT DESC,
                                    CASE    WHEN sin(radians(r.turn_angle))>0
                                            THEN cos(radians(r.turn_angle))
                                            ELSE -cos(radians(r.turn_angle))
                                            END ASC
                        LIMIT       1
            );'
        USING   'f'::BOOLEAN;
    ELSE
        -- assume crossing is true unless proven otherwise
        EXECUTE '
            UPDATE  '||link_table_||'
            SET     int_crossing = $1
            WHERE   int_id = ANY ($1);'
        USING   't'::BOOLEAN;

        -- set right turns
        EXECUTE '
            UPDATE  '||link_table_||'
            SET     int_crossing = $1
            WHERE   link_id = (
                        SELECT      r.link_id
                        FROM        '||link_table_||' r
                        WHERE       '||link_table_||'.source_road_id = r.source_road_id
                        AND         '||link_table_||'.int_id = r.int_id
                        ORDER BY    (sin(radians(r.turn_angle))>0)::INT DESC,
                                    CASE    WHEN sin(radians(r.turn_angle))>0
                                            THEN cos(radians(r.turn_angle))
                                            ELSE -cos(radians(r.turn_angle))
                                            END ASC
                        LIMIT       1
            )
            AND     int_id = ANY ($1);'
        USING   'f'::BOOLEAN;
    END IF;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgSetTurnInfo(REGCLASS,INT[]) OWNER TO gis;
