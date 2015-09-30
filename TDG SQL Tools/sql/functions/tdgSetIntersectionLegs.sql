CREATE OR REPLACE FUNCTION tdg.tdgSetIntersectionLegs(
    int_table_ REGCLASS,
    road_table_ REGCLASS,
    int_ids_ INTEGER[] DEFAULT NULL)
RETURNS BOOLEAN AS $func$

DECLARE
    sql TEXT;

BEGIN
    RAISE NOTICE 'Setting intersection legs on %', int_table_;
    sql := '
        UPDATE  '||int_table_||'
        SET     legs = (SELECT  COUNT(roads.road_id)
                        FROM    '||road_table_||' roads
                        WHERE   '||int_table_||'.int_id = roads.intersection_from
                        OR      '||int_table_||'.int_id = roads.intersection_to)';

    IF int_ids_ IS NULL THEN
        EXECUTE sql;
    ELSE
        EXECUTE sql || ' WHERE int_id = ANY($1)'
        USING   int_ids_;
    END IF;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgSetIntersectionLegs(REGCLASS,REGCLASS,INTEGER[]) OWNER TO gis;
