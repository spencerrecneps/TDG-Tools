CREATE OR REPLACE FUNCTION tdgCalculateStress(  _input_table REGCLASS,
                                                _seg BOOLEAN,
                                                _approach BOOLEAN,
                                                _cross BOOLEAN,
                                                _ids INT[] DEFAULT NULL)
--calculate stress score
RETURNS BOOLEAN AS $func$

DECLARE
    tablecheck TEXT;
    namecheck record;

BEGIN
    raise notice 'PROCESSING:';

    --get schema
    BEGIN
        IF _cross THEN
            --stress_cross_w_median
            tablecheck := 'stress_cross_w_median';
            RAISE NOTICE 'Checking % has stress tables',_input_table;
            RAISE NOTICE 'Checking for %', tablecheck;
            EXECUTE '   SELECT  schema_name,
                                table_name
                        FROM    tdgTableDetails('||quote_literal(tablecheck)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
            IF namecheck.schema_name IS NULL OR namecheck.table_name IS NULL THEN
                RAISE NOTICE '-------> % not found',tablecheck;
                RETURN 'f';
            ELSE
                RAISE NOTICE '  -----> OK';
            END IF;


            --stress_cross_no_median
            tablecheck := 'stress_cross_no_median';
            RAISE NOTICE 'Checking for %', tablecheck;
            EXECUTE '   SELECT  schema_name,
                                table_name
                        FROM    tdgTableDetails('||quote_literal(tablecheck)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
            IF namecheck.schema_name IS NULL OR namecheck.table_name IS NULL THEN
                RAISE NOTICE '-------> % not found',tablecheck;
                RETURN 'f';
            ELSE
                RAISE NOTICE '  -----> OK';
            END IF;
        END IF;

        IF _seg THEN
            --stress_seg_bike_w_park
            tablecheck := 'stress_seg_bike_w_park';
            RAISE NOTICE 'Checking for %', tablecheck;
            EXECUTE '   SELECT  schema_name,
                                table_name
                        FROM    tdgTableDetails('||quote_literal(tablecheck)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
            IF namecheck.schema_name IS NULL OR namecheck.table_name IS NULL THEN
                RAISE NOTICE '-------> % not found',tablecheck;
                RETURN 'f';
            ELSE
                RAISE NOTICE '  -----> OK';
            END IF;

            --stress_seg_bike_no_park
            tablecheck := 'stress_seg_bike_no_park';
            RAISE NOTICE 'Checking for %', tablecheck;
            EXECUTE '   SELECT  schema_name,
                                table_name
                        FROM    tdgTableDetails('||quote_literal(tablecheck)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
            IF namecheck.schema_name IS NULL OR namecheck.table_name IS NULL THEN
                RAISE NOTICE '-------> % not found',tablecheck;
                RETURN 'f';
            ELSE
                RAISE NOTICE '  -----> OK';
            END IF;

            --stress_seg_bike_w_park
            tablecheck := 'stress_seg_bike_w_park';
            RAISE NOTICE 'Checking for %', tablecheck;
            EXECUTE '   SELECT  schema_name,
                                table_name
                        FROM    tdgTableDetails('||quote_literal(tablecheck)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
            IF namecheck.schema_name IS NULL OR namecheck.table_name IS NULL THEN
                RAISE NOTICE '-------> % not found',tablecheck;
                RETURN 'f';
            ELSE
                RAISE NOTICE '  -----> OK';
            END IF;

            --stress_seg_mixed
            tablecheck := 'stress_seg_mixed';
            RAISE NOTICE 'Checking for %', tablecheck;
            EXECUTE '   SELECT  schema_name,
                                table_name
                        FROM    tdgTableDetails('||quote_literal(tablecheck)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
            IF namecheck.schema_name IS NULL OR namecheck.table_name IS NULL THEN
                RAISE NOTICE '-------> % not found',tablecheck;
                RETURN 'f';
            ELSE
                RAISE NOTICE '  -----> OK';
            END IF;
        END IF;
    END;

    --clear old values
    BEGIN
        RAISE NOTICE 'Clearing old values';
        IF _seg THEN
            EXECUTE format('
                UPDATE  %s
                SET     ft_seg_stress = NULL,
                        tf_seg_stress = NULL;
                ',  _input_table);
        END IF;
        IF _approach THEN
            EXECUTE format('
                UPDATE  %s
                SET     ft_int_stress = NULL,
                        tf_int_stress = NULL;
                ',  _input_table);
        END IF;
        IF _cross THEN
            EXECUTE format('
                UPDATE  %s
                SET     ft_cross_stress = NULL,
                        tf_cross_stress = NULL;
                ',  _input_table);
        END IF;
    END;

    --do calcs
    BEGIN
        ------------------------------------------------------
        --apply segment stress using tables
        ------------------------------------------------------
        IF _seg THEN
            RAISE NOTICE 'Calculating segment stress';

            -- mixed ft direction
            EXECUTE format('
                UPDATE  %s
                SET     ft_seg_stress=( SELECT      stress
                                        FROM        %s s
                                        WHERE       %s.speed_limit <= s.speed
                                        AND         %s.adt <= s.adt
                                        AND         COALESCE(%s.ft_seg_lanes_thru,1) <= s.lanes
                                        ORDER BY    s.stress ASC
                                        LIMIT       1)
                WHERE   (COALESCE(ft_seg_lanes_bike_wd_ft,0) < 4 AND COALESCE(ft_seg_lanes_park_wd_ft,0) = 0)
                OR      COALESCE(ft_seg_lanes_bike_wd_ft,0) + COALESCE(ft_seg_lanes_park_wd_ft,0) < 12;
                ',  _input_table,
                    'tdg.stress_seg_mixed',
                    _input_table,
                    _input_table,
                    _input_table);

            -- mixed tf direction
            EXECUTE format('
                UPDATE  %s
                SET     tf_seg_stress=( SELECT      stress
                                        FROM        %s s
                                        WHERE       %s.speed_limit <= s.speed
                                        AND         %s.adt <= s.adt
                                        AND         COALESCE(%s.tf_seg_lanes_thru,1) <= s.lanes
                                        ORDER BY    s.stress ASC
                                        LIMIT       1)
                WHERE   (COALESCE(tf_seg_lanes_bike_wd_ft,0) < 4 AND COALESCE(tf_seg_lanes_park_wd_ft,0) = 0)
                OR      COALESCE(tf_seg_lanes_bike_wd_ft,0) + COALESCE(tf_seg_lanes_park_wd_ft,0) < 12;
                ',  _input_table,
                    'tdg.stress_seg_mixed',
                    _input_table,
                    _input_table,
                    _input_table);

            -- bike lane no parking ft direction
            EXECUTE format('
                UPDATE  %s
                SET     ft_seg_stress=( SELECT      stress
                                        FROM        %s s
                                        WHERE       %s.speed_limit <= s.speed
                                        AND         %s.ft_seg_lanes_bike_wd_ft <= s.bike_lane_wd_ft
                                        AND         %s.ft_seg_lanes_thru <= s.lanes
                                        ORDER BY    s.stress ASC
                                        LIMIT       1)
                WHERE   ft_seg_lanes_bike_wd_ft >= 4
                AND     COALESCE(ft_seg_lanes_park_wd_ft,0) = 0;
                ',  _input_table,
                    'stress_seg_bike_no_park',
                    _input_table,
                    _input_table,
                    _input_table);

            -- bike lane no parking tf direction
            EXECUTE format('
                UPDATE  %s
                SET     tf_seg_stress=( SELECT      stress
                                        FROM        %s s
                                        WHERE       %s.speed_limit <= s.speed
                                        AND         %s.tf_seg_lanes_bike_wd_ft <= s.bike_lane_wd_ft
                                        AND         %s.tf_seg_lanes_thru <= s.lanes
                                        ORDER BY    s.stress ASC
                                        LIMIT       1)
                WHERE   tf_seg_lanes_bike_wd_ft >= 4
                AND     COALESCE(tf_seg_lanes_park_wd_ft,0) = 0;
                ',  _input_table,
                    'stress_seg_bike_no_park',
                    _input_table,
                    _input_table,
                    _input_table);

            -- parking with or without bike lanes ft direction
            EXECUTE format('
                UPDATE  %s
                SET     ft_seg_stress=( SELECT      stress
                                        FROM        %s s
                                        WHERE       %s.speed_limit <= s.speed
                                        AND         COALESCE(%s.ft_seg_lanes_bike_wd_ft,0) + %s.ft_seg_lanes_park_wd_ft <= s.bike_park_lane_wd_ft
                                        AND         %s.ft_seg_lanes_thru <= s.lanes
                                        ORDER BY    s.stress ASC
                                        LIMIT       1)
                WHERE   COALESCE(ft_seg_lanes_park_wd_ft,0) > 0
                AND     ft_seg_lanes_park_wd_ft + COALESCE(ft_seg_lanes_bike_wd_ft,0) >= 12;
                ',  _input_table,
                    'stress_seg_bike_w_park',
                    _input_table,
                    _input_table,
                    _input_table,
                    _input_table);

            -- parking with or without bike lanes tf direction
            EXECUTE format('
                UPDATE  %s
                SET     tf_seg_stress=( SELECT      stress
                                        FROM        %s s
                                        WHERE       %s.speed_limit <= s.speed
                                        AND         COALESCE(%s.tf_seg_lanes_bike_wd_ft,0) + %s.tf_seg_lanes_park_wd_ft <= s.bike_park_lane_wd_ft
                                        AND         %s.tf_seg_lanes_thru <= s.lanes
                                        ORDER BY    s.stress ASC
                                        LIMIT       1)
                WHERE   COALESCE(tf_seg_lanes_park_wd_ft,0) > 0
                AND     tf_seg_lanes_park_wd_ft + COALESCE(tf_seg_lanes_bike_wd_ft,0) >= 12;
                ',  _input_table,
                    'stress_seg_bike_w_park',
                    _input_table,
                    _input_table,
                    _input_table,
                    _input_table);

            --trails
            EXECUTE format('
                UPDATE  %s
                SET     ft_seg_stress = 1,
                        tf_seg_stress = 1
                WHERE   functional_class = %L;
                ',  _input_table,
                    'Trail');

            --overrides
            EXECUTE format('
                UPDATE  %s
                SET     ft_seg_stress = ft_seg_stress_override
                WHERE   ft_seg_stress_override IS NOT NULL;
                UPDATE  %s
                SET     tf_seg_stress = tf_seg_stress_override
                WHERE   tf_seg_stress_override IS NOT NULL;
                ',  _input_table,
                    _input_table);
        END IF;

        ------------------------------------------------------
        --apply intersection stress
        ------------------------------------------------------
        IF _approach THEN
            -- shared right turn lanes ft direction
            EXECUTE format('
                UPDATE  %s
                SET     ft_int_stress = 3
                WHERE   COALESCE(ft_int_lanes_bike_wd_ft,0) < 4
                AND     ft_int_lanes_rt_len_ft >= 75
                AND     ft_int_lanes_rt_len_ft < 150;
                UPDATE  %s
                SET     ft_int_stress = 4
                WHERE   COALESCE(ft_int_lanes_bike_wd_ft,0) < 4
                AND     ft_int_lanes_rt_len_ft >= 150;
                ',  _input_table,
                    _input_table);

            -- shared right turn lanes tf direction
            EXECUTE format('
                UPDATE  %s
                SET     tf_int_stress = 3
                WHERE   COALESCE(tf_int_lanes_bike_wd_ft,0) < 4
                AND     tf_int_lanes_rt_len_ft >= 75
                AND     tf_int_lanes_rt_len_ft < 150;
                UPDATE  %s
                SET     tf_int_stress = 4
                WHERE   COALESCE(tf_int_lanes_bike_wd_ft,0) < 4
                AND     tf_int_lanes_rt_len_ft >= 150;
                ',  _input_table,
                    _input_table);

            -- pocket bike lane w/right turn lanes ft direction
            EXECUTE format('
                UPDATE  %s
                SET     ft_int_stress = 2
                WHERE   COALESCE(ft_int_lanes_bike_wd_ft,0) >= 4
                AND     ft_int_lanes_rt_len_ft <= 150
                AND     ft_int_lanes_rt_radius_speed_mph <= 15
                AND     ft_int_lanes_bike_straight = 1;
                UPDATE  %s
                SET     ft_int_stress = 3
                WHERE   COALESCE(ft_int_lanes_bike_wd_ft,0) >= 4
                AND     COALESCE(ft_int_lanes_rt_len_ft,0) > 0
                AND     ft_int_lanes_rt_radius_speed_mph <= 20
                AND     ft_int_lanes_bike_straight = 1
                AND     ft_int_stress IS NOT NULL;
                UPDATE  %s
                SET     ft_int_stress = 3
                WHERE   COALESCE(ft_int_lanes_bike_wd_ft,0) >= 4
                AND     ft_int_lanes_rt_radius_speed_mph <= 15
                AND     COALESCE(ft_int_lanes_bike_straight,0) = 0;
                UPDATE  %s
                SET     ft_int_stress = 4
                WHERE   COALESCE(ft_int_lanes_bike_wd_ft,0) >= 4
                AND     ft_int_stress IS NULL;
                ',  _input_table,
                    _input_table,
                    _input_table,
                    _input_table);

            -- pocket bike lane w/right turn lanes tf direction
            EXECUTE format('
                UPDATE  %s
                SET     tf_int_stress = 2
                WHERE   COALESCE(tf_int_lanes_bike_wd_ft,0) >= 4
                AND     tf_int_lanes_rt_len_ft <= 150
                AND     tf_int_lanes_rt_radius_speed_mph <= 15
                AND     tf_int_lanes_bike_straight = 1;
                UPDATE  %s
                SET     tf_int_stress = 3
                WHERE   COALESCE(tf_int_lanes_bike_wd_ft,0) >= 4
                AND     COALESCE(tf_int_lanes_rt_len_ft,0) > 0
                AND     tf_int_lanes_rt_radius_speed_mph <= 20
                AND     tf_int_lanes_bike_straight = 1
                AND     tf_int_stress IS NOT NULL;
                UPDATE  %s
                SET     tf_int_stress = 3
                WHERE   COALESCE(tf_int_lanes_bike_wd_ft,0) >= 4
                AND     tf_int_lanes_rt_radius_speed_mph <= 15
                AND     COALESCE(tf_int_lanes_bike_straight,0) = 0;
                UPDATE  %s
                SET     tf_int_stress = 4
                WHERE   COALESCE(tf_int_lanes_bike_wd_ft,0) >= 4
                AND     tf_int_stress IS NULL;
                ',  _input_table,
                    _input_table,
                    _input_table,
                    _input_table);

            --trails
            EXECUTE format('
                UPDATE  %s
                SET     ft_int_stress = 1,
                        tf_int_stress = 1
                WHERE   functional_class = %L;
                ',  _input_table,
                    'Trail');

            --overrides
            EXECUTE format('
                UPDATE  %s
                SET     ft_int_stress = ft_int_stress_override
                WHERE   ft_int_stress_override IS NOT NULL;
                UPDATE  %s
                SET     tf_int_stress = tf_int_stress_override
                WHERE   tf_int_stress_override IS NOT NULL;
                ',  _input_table,
                    _input_table);
        END IF;

        ------------------------------------------------------
        --apply crossing stress
        ------------------------------------------------------
        IF _cross THEN
            --no median (or less than 6 ft), ft
            EXECUTE format('
                UPDATE  %s
                SET     ft_cross_stress = ( SELECT      s.stress
                                            FROM        %s s
                                            WHERE       %s.ft_cross_speed_limit <= s.speed
                                            AND         %s.ft_cross_lanes <= s.lanes
                                            ORDER BY    s.stress ASC
                                            LIMIT       1)
                WHERE   COALESCE(ft_cross_median_wd_ft,0) < 6;
                ',  _input_table,
                    'stress_cross_no_median',
                    _input_table,
                    _input_table);

            --no median (or less than 6 ft), tf
            EXECUTE format('
                UPDATE  %s
                SET     tf_cross_stress = ( SELECT      s.stress
                                            FROM        %s s
                                            WHERE       %s.tf_cross_speed_limit <= s.speed
                                            AND         %s.tf_cross_lanes <= s.lanes
                                            ORDER BY    s.stress ASC
                                            LIMIT       1)
                WHERE   COALESCE(tf_cross_median_wd_ft,0) < 6;
                ',  _input_table,
                    'stress_cross_no_median',
                    _input_table,
                    _input_table);

            --with median at least 6 ft, ft
            EXECUTE format('
                UPDATE  %s
                SET     ft_cross_stress = ( SELECT      s.stress
                                            FROM        %s s
                                            WHERE       %s.ft_cross_speed_limit <= s.speed
                                            AND         %s.ft_cross_lanes <= s.lanes
                                            ORDER BY    s.stress ASC
                                            LIMIT       1)
                WHERE   COALESCE(ft_cross_median_wd_ft,0) >= 6;
                ',  _input_table,
                    'stress_cross_w_median',
                    _input_table,
                    _input_table);

            --with median at least 6 ft, tf
            EXECUTE format('
                UPDATE  %s
                SET     tf_cross_stress = ( SELECT      s.stress
                                            FROM        %s s
                                            WHERE       %s.tf_cross_speed_limit <= s.speed
                                            AND         %s.tf_cross_lanes <= s.lanes
                                            ORDER BY    s.stress ASC
                                            LIMIT       1)
                WHERE   COALESCE(tf_cross_median_wd_ft,0) >= 6;
                ',  _input_table,
                    'stress_cross_w_median',
                    _input_table,
                    _input_table);

            --traffic signals ft
            EXECUTE format('
                UPDATE  %s
                SET     ft_cross_stress = 1
                WHERE   ft_cross_signal = 1;
                ',  _input_table);

            --traffic signals tf
            EXECUTE format('
                UPDATE  %s
                SET     tf_cross_stress = 1
                WHERE   tf_cross_signal = 1;
                ',  _input_table);

            --overrides
            EXECUTE format('
                UPDATE  %s
                SET     tf_cross_stress = tf_cross_stress_override
                WHERE   tf_cross_stress_override IS NOT NULL;
                UPDATE  %s
                SET     ft_cross_stress = ft_cross_stress_override
                WHERE   ft_cross_stress_override IS NOT NULL;
                ',  _input_table,
                    _input_table);
        END IF;

        ------------------------------------------------------
        --nullify stress on contraflow one-way segments
        ------------------------------------------------------
        EXECUTE format('
            UPDATE  %s
            SET     ft_seg_stress = NULL,
                    ft_int_stress = NULL,
                    ft_cross_stress = NULL
            WHERE   one_way = %L;
            UPDATE  %s
            SET     tf_seg_stress = NULL,
                    tf_int_stress = NULL,
                    tf_cross_stress = NULL
            WHERE   one_way = %L;
            ',  _input_table,
                'tf',
                _input_table,
                'ft');
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
