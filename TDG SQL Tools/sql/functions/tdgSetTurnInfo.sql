CREATE OR REPLACE FUNCTION tdg.tdgSetTurnInfo (
    link_table_ REGCLASS,
    int_table_ REGCLASS,
    vert_table_ REGCLASS,
    int_ids_ INT[] DEFAULT NULL)
RETURNS BOOLEAN AS $func$

DECLARE
    temp_table TEXT;
    link_record RECORD;
    source_vert INT;

BEGIN
    --compile list of int_ids_ if needed
    IF int_ids_ IS NULL THEN
        EXECUTE 'SELECT array_agg(int_id) FROM '||int_table_||';' INTO int_ids_;
    END IF;

    --set existing movements to null
    EXECUTE 'UPDATE '||link_table_||' SET movement = NULL;';

    --loop through links with int legs > 3. find r/l turns using sin/cos
    FOR link_record IN
    EXECUTE '
        SELECT  links.road_id,
                ST_Azimuth(ST_StartPoint(links.geom),ST_EndPoint(links.geom)) AS azi,
                links.target_vert,
                ints.legs,
                ints.int_id
        FROM    '||link_table_||' links
        JOIN    '||vert_table_||' verts
                ON links.target_vert = verts.vert_id
        JOIN    '||int_table_||' ints
                ON verts.int_id = ints.int_id
                AND ints.legs > 2
        WHERE   links.road_id IS NOT NULL
        AND     ints.int_id = ANY ($1)'
    USING   int_ids_
    LOOP
        --right turn
        EXECUTE '
            SELECT      links.source_vert
            FROM        '||link_table_||' links
            JOIN        '||vert_table_||' verts
                        ON links.source_vert = verts.vert_id
            WHERE       links.road_id IS NOT NULL
            AND         links.road_id != $1
            AND         verts.int_id = $2
            AND         sin(ST_Azimuth(ST_StartPoint(links.geom),ST_EndPoint(links.geom)) - $3) > 0 --must be between 0 and 180 degrees
            AND         cos(ST_Azimuth(ST_StartPoint(links.geom),ST_EndPoint(links.geom)) - $3) < 0.7 --must be greater than 45 degrees
            ORDER BY    cos(ST_Azimuth(ST_StartPoint(links.geom),ST_EndPoint(links.geom)) - $3) ASC --closest to 180 degrees
            LIMIT       1;'
        USING   link_record.road_id,
                link_record.int_id,
                link_record.azi
        INTO    source_vert;

        IF NOT source_vert IS NULL THEN
            EXECUTE '
                UPDATE  '||link_table_||'
                SET     movement = $1
                WHERE   source_vert = $2
                AND     target_vert = $3;'
            USING   'right',
                    link_record.target_vert,
                    source_vert;
        END IF;

        --left turn
        EXECUTE '
            SELECT      links.source_vert
            FROM        '||link_table_||' links
            JOIN        '||vert_table_||' verts
                        ON links.source_vert = verts.vert_id
            WHERE       links.road_id IS NOT NULL
            AND         links.road_id != $1
            AND         verts.int_id = $2
            AND         sin(ST_Azimuth(ST_StartPoint(links.geom),ST_EndPoint(links.geom)) - $3) < 0 --must be between 180 and 360 degrees
            AND         cos(ST_Azimuth(ST_StartPoint(links.geom),ST_EndPoint(links.geom)) - $3) < 0.7 --must be less than 315 degrees
            ORDER BY    cos(ST_Azimuth(ST_StartPoint(links.geom),ST_EndPoint(links.geom)) - $3) ASC --closest to 180 degrees
            LIMIT       1;'
        USING   link_record.road_id,
                link_record.int_id,
                link_record.azi
        INTO    source_vert;

        IF NOT source_vert IS NULL THEN
            EXECUTE '
                UPDATE  '||link_table_||'
                SET     movement = $1
                WHERE   source_vert = $2
                AND     target_vert = $3;'
            USING   'left',
                    link_record.target_vert,
                    source_vert;
        END IF;
    END LOOP;

    EXECUTE 'UPDATE '||link_table_||' SET movement = $1 WHERE movement IS NULL;'
    USING   'straight';

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgSetTurnInfo(REGCLASS,REGCLASS,REGCLASS,INT[]) OWNER TO gis;
