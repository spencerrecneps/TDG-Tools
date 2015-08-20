CREATE OR REPLACE FUNCTION tdgGetTurnInfo ( link_table REGCLASS,
                                            inttable REGCLASS)
RETURNS BOOLEAN AS $func$

BEGIN
    --assign 'straight' to non-intersections
    EXECUTE format('
        UPDATE  %I
        SET     movement = %L
        FROM    %I ints
        WHERE   ints.id = intersection_id
        AND     ints.legs = 2;
        ',  link_table,
            'straight',
            inttable);

    --left turns at 3-legged intersections
    EXECUTE format('
        UPDATE  %I
        SET     movement = %L
        FROM    %I ints
        WHERE   ints.id = intersection_id
        AND     ints.legs = 3;
        ',  link_table,
            'left',
            inttable);
    --need to fix this



    --right turns at 3-legged intersections

    --straight at 3-legged intersections

    --straight at 4-legged intersections

    --left turns at 4-legged intersections

    --right turns at 4-legged intersections

    --straight at >4-legged intersections

    --left turns at >4-legged intersections

    --right turns at >4-legged intersections



RETURN 't';
END $func$ LANGUAGE plpgsql;
