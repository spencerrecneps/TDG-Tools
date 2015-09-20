CREATE OR REPLACE FUNCTION tdg.tdgGenerateCrossStreetData(road_table_ REGCLASS)
--populate cross-street data
RETURNS BOOLEAN AS $func$

DECLARE
    int_table REGCLASS;

BEGIN
    raise notice 'PROCESSING:';

    int_table = road_table_ || '_intersections';

    RAISE NOTICE 'Clearing old values';
    EXECUTE '
        UPDATE ' || road_table_ || ' SET road_from = NULL, road_to = NULL;';

    --ignore culs-de-sac (legs = 1)

    -- get road names of no intersection (order 2)
    RAISE NOTICE 'Assigning for non-intersections (legs = 2)';
    --from streets
    EXECUTE '
        UPDATE  '||road_table_||'
        SET     road_from = r.road_name
        FROM    '||int_table||' i,
                '||road_table_||' r
        WHERE   i.legs = 2
        AND     '||road_table_||'.intersection_from = i.int_id
        AND     i.int_id IN (r.intersection_from,r.intersection_to)
        AND     '||road_table_||'.z_from = r.z_from
        AND     '||road_table_||'.road_id != r.road_id;';
    --to streets
    EXECUTE '
        UPDATE  '||road_table_||'
        SET     road_from = r.road_name
        FROM    '||int_table||' i,
                '||road_table_||' r
        WHERE   i.legs = 2
        AND     '||road_table_||'.intersection_to = i.int_id
        AND     i.int_id IN (r.intersection_from,r.intersection_to)
        AND     '||road_table_||'.z_to = r.z_to
        AND     '||road_table_||'.road_id != r.road_id;';

    --get road name of leg nearest to 90 degrees
    RAISE NOTICE 'Assigning cross streets for intersections';
    --from streets
    EXECUTE '
        WITH x AS (
            SELECT  a.road_id AS this_id,
                    b.road_id AS xing_id,
                    b.road_name AS road_name,
                    degrees(ST_Azimuth(ST_StartPoint(a.geom),ST_EndPoint(a.geom)))::numeric AS this_azi,
                    degrees(ST_Azimuth(ST_StartPoint(b.geom),ST_EndPoint(b.geom)))::numeric AS xing_azi
            FROM    '||road_table_||' a
            JOIN    '||road_table_||' b
                        ON a.intersection_from IN (b.intersection_from,b.intersection_to)
                        AND a.road_id != b.road_id
        )
        UPDATE  '||road_table_||'
        SET     road_from = (   SELECT      x.road_name
                                FROM        x
                                WHERE       '||road_table_||'.road_id = x.this_id
                                ORDER BY    ABS(SIN(RADIANS(MOD(360 + x.xing_azi - x.this_azi,360)))) DESC
                                LIMIT       1)';
--ORDER BY    ABS(90 - (mod(mod(360 + x.xing_azi - x.this_azi, 360), 180) )) ASC
    --to streets
    EXECUTE '
        WITH x AS (
            SELECT  a.road_id AS this_id,
                    b.road_id AS xing_id,
                    b.road_name AS road_name,
                    degrees(ST_Azimuth(ST_StartPoint(a.geom),ST_EndPoint(a.geom)))::numeric AS this_azi,
                    degrees(ST_Azimuth(ST_StartPoint(b.geom),ST_EndPoint(b.geom)))::numeric AS xing_azi
            FROM    '||road_table_||' a
            JOIN    '||road_table_||' b
                        ON a.intersection_to IN (b.intersection_from,b.intersection_to)
                        AND a.road_id != b.road_id
        )
        UPDATE  '||road_table_||'
        SET     road_to = (     SELECT      x.road_name
                                FROM        x
                                WHERE       '||road_table_||'.road_id = x.this_id
                                ORDER BY    ABS(SIN(RADIANS(MOD(360 + x.xing_azi - x.this_azi,360)))) DESC
                                LIMIT       1)';

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgGenerateCrossStreetData(REGCLASS) OWNER TO gis;
