CREATE OR REPLACE FUNCTION tdgSetTurnInfo ( linktable REGCLASS,
                                            inttable REGCLASS,
                                            verttable REGCLASS,
                                            intersection_ids INT[])
RETURNS BOOLEAN AS $func$

DECLARE
    temptable TEXT;

BEGIN
    RAISE NOTICE 'creating temporary turn data table';
    temptable := 'tdggtitemptbl';
    EXECUTE format('
        CREATE TEMP TABLE %s (
            int_id INT,
            ref_link_id INT,
            match_link_id INT,
            ref_azimuth INT,
            match_azimuth INT,
            movement TEXT)
        ON COMMIT DROP;
    ',  temptable);

    EXECUTE format('
        INSERT INTO %s (int_id,
                        ref_link_id,
                        match_link_id,
                        ref_azimuth,
                        match_azimuth)
        SELECT  int.id,
                l1.id,
                l2.id,
                degrees(ST_Azimuth(ST_StartPoint(l1.geom),ST_EndPoint(l1.geom))),
                degrees(ST_Azimuth(ST_StartPoint(l2.geom),ST_EndPoint(l2.geom)))
        FROM    %s int
        JOIN    %s v1
                ON  int.id = v1.intersection_id
        JOIN    %s v2
                ON  int.id = v2.intersection_id
        JOIN    %s l1
                ON  l1.target_node = v1.node_id
                AND l1.road_id IS NOT NULL
        JOIN    %s l2
                ON  l2.source_node = v2.node_id
                AND l2.road_id IS NOT NULL
                AND l1.road_id != l2.road_id
        WHERE   int.id = ANY (%L);
        ',  temptable,
            inttable,
            verttable,
            verttable,
            linktable,
            linktable,
            intersection_ids);

    --reposition the azimuths so that the reference azimuth is at 0
    RAISE NOTICE 'repositioning azimuths';

    EXECUTE format('
        UPDATE  %s
        SET     match_azimuth = MOD((360 + 180 + match_azimuth - ref_azimuth),360);
        ',  temptable);

    EXECUTE format('
        UPDATE  %s
        SET     ref_azimuth = 0;
        ',  temptable);


    --calculate turn info
    --right turns
    RAISE NOTICE 'calculating turns';
    EXECUTE format('
        UPDATE  %s
        SET     movement = %L
        FROM    (   SELECT DISTINCT ON (t.ref_link_id)
                        t.ref_link_id,
                        t.match_link_id
                    FROM %s t
                    ORDER BY t.ref_link_id, t.match_azimuth DESC) x
        WHERE   %s.ref_link_id = x.ref_link_id
        AND     %s.match_link_id = x.match_link_id;
        ',  temptable,
            'right',
            temptable,
            temptable,
            temptable);

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
        ',  temptable,
            'left',
            temptable,
            temptable,
            temptable);

    --straights
    EXECUTE format('
        UPDATE  %s
        SET     movement = %L
        WHERE   movement IS NULL;
        ',  temptable,
            'straight');

    --find intersections where left or right may have been assigned
    --but it's actually straight (i.e.T intersections or other odd situations)
    EXECUTE format('
        UPDATE  %s
        SET     movement = %L
        FROM    %s ints
        WHERE   %s.int_id = ints.id
        AND     (   SELECT  COUNT(t.int_id)
                    FROM    %s t
                    WHERE   t.int_id = %s.int_id
                    AND     t.ref_link_id = %s.ref_link_id) < 3
        AND     match_azimuth >= 150
        AND     match_azimuth <= 210
        AND     movement != %L;
        ',  temptable,
            'straight',
            inttable,
            temptable,
            temptable,
            temptable,
            temptable,
            'straight');

    --set turn info in links table
    RAISE NOTICE 'setting turns in %', linktable;
    EXECUTE format('
        UPDATE  %s
        SET     movement = t.movement
        FROM    %s t,
                %s lf,
                %s lt
        WHERE   t.ref_link_id = lf.id
        AND     t.match_link_id = lt.id
        AND     %s.source_node = lf.target_node
        AND     %s.target_node = lt.source_node;
        ',  linktable,
            temptable,
            linktable,
            linktable,
            linktable,
            linktable);

    --clean up temp table
    EXECUTE format('DROP TABLE %s', temptable);

RETURN 't';
END $func$ LANGUAGE plpgsql;
