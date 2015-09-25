CREATE OR REPLACE FUNCTION tdg.tdgSetTurnInfo (
    link_table_ REGCLASS,
    int_table_ REGCLASS,
    vert_table_ REGCLASS,
    int_ids_ INT[] DEFAULT NULL)
RETURNS BOOLEAN AS $func$

DECLARE
    temp_table TEXT;
    link_record RECORD;

BEGIN
    --compile list of int_ids_ if needed
    IF int_ids_ IS NULL THEN
        EXECUTE 'SELECT array_agg(int_id) FROM '||int_table||';' INTO int_ids_;
    END IF;

    FOR link_record IN
    EXECUTE 'SELECT link_id, ST_Azimuth(geom) AS azi'
    LOOP
    --loop through links with int legs > 3. find r/l turns using sin/cos



    RAISE NOTICE 'Creating temporary movement data table';
    temp_table := 'tmp_tdggtitemptbl';
    EXECUTE '
        CREATE TEMP TABLE '||temp_table||' (
            int_id INT,
            ref_link_id INT,
            match_link_id INT,
            ref_azimuth INT,
            match_azimuth INT,
            movement TEXT)
        ON COMMIT DROP;';

    EXECUTE '
        INSERT INTO '||temp_table||' (
            int_id,
            ref_link_id,
            match_link_id,
            ref_azimuth,
            match_azimuth)
        SELECT  ints.int_id,
                l1.link_id,
                l2.link_id,
                ST_Azimuth(ST_StartPoint(l1.geom),ST_EndPoint(l1.geom)),
                ST_Azimuth(ST_StartPoint(l2.geom),ST_EndPoint(l2.geom))
        FROM    '||int_table_||' ints
        JOIN    '||vert_table_||' v1
                ON  ints.int_id = v1.int_id
        JOIN    '||vert_table_||' v2
                ON  ints.int_id = v2.int_id
        JOIN    '||link_table_||' l1
                ON  l1.target_vert = v1.vert_id
                AND l1.road_id IS NOT NULL
        JOIN    '||link_table_||' l2
                ON  l2.source_vert = v2.vert_id
                AND l2.road_id IS NOT NULL
                AND l1.road_id != l2.road_id
        WHERE   ints.int_id = ANY ($1);'
    USING   int_ids_;

    --reposition the azimuths so that the reference azimuth is at 0
    RAISE NOTICE 'Repositioning azimuths';

    EXECUTE format('
        UPDATE  '||temp_table||'
        SET     match_azimuth = match_azimuth - ref_azimuth,
                ref_azimuth = 0;';

    --calculate turn info
    --right turns



    RAISE NOTICE 'calculating turns';
    EXECUTE '
        UPDATE  '||temp_table||'
        SET     movement = $1
        FROM    (   SELECT DISTINCT ON (t.ref_link_id)
                        t.ref_link_id,
                        t.match_link_id
                    FROM '||temp_table||' t
                    ORDER BY t.ref_link_id, t.match_azimuth DESC) x
        WHERE   '||temp_table||'.ref_link_id = x.ref_link_id
        AND     '||temp_table||'.match_link_id = x.match_link_id;'
    USING   'right';

    --left turns
    EXECUTE format('
        UPDATE  %s
        SET     movement = %L
        FROM    (   SELECT DISTINCT ON (t.ref_link_id)
                        t.ref_link_id,
                        t.match_link_id
                    FROM %s t
                    ORDER BY t.ref_link_id, t.match_azimuth ASC) x
        WHERE   %s.ref_link_id = x.ref_link_id
        AND     %s.match_link_id = x.match_link_id;
        ',  temp_table,
            'left',
            temp_table,
            temp_table,
            temp_table);

    --straights
    EXECUTE format('
        UPDATE  %s
        SET     movement = %L
        WHERE   movement IS NULL;
        ',  temp_table,
            'straight');

    --find intersections where left or right may have been assigned
    --but it's actually straight (i.e.T intersections or other odd situations)
    EXECUTE format('
        UPDATE  %s
        SET     movement = %L
        FROM    %s ints
        WHERE   %s.int_id = ints.int_id
        AND     (   SELECT  COUNT(t.int_id)
                    FROM    %s t
                    WHERE   t.int_id = %s.int_id
                    AND     t.ref_link_id = %s.ref_link_id) < 3
        AND     match_azimuth >= 150
        AND     match_azimuth <= 210
        AND     movement != %L;
        ',  temp_table,
            'straight',
            int_table_,
            temp_table,
            temp_table,
            temp_table,
            temp_table,
            'straight');

    --set turn info in links table
    RAISE NOTICE 'setting turns in %', link_table_;
    EXECUTE format('
        UPDATE  %s
        SET     movement = t.movement
        FROM    %s t,
                %s lf,
                %s lt
        WHERE   t.ref_link_id = lf.link_id
        AND     t.match_link_id = lt.link_id
        AND     %s.source_vert = lf.target_vert
        AND     %s.target_vert = lt.source_vert;
        ',  link_table_,
            temp_table,
            link_table_,
            link_table_,
            link_table_,
            link_table_);

    --clean up temp table
    EXECUTE format('DROP TABLE %s', temp_table);

RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgSetTurnInfo(REGCLASS,REGCLASS,REGCLASS,INT[]) OWNER TO gis;
