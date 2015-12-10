CREATE OR REPLACE FUNCTION tdg.tdgCalculateStress(
    input_table_ REGCLASS,
    seg_ BOOLEAN,
    approach_ BOOLEAN,
    cross_ BOOLEAN,
    ids_ INT[] DEFAULT NULL)
--calculate stress score
RETURNS BOOLEAN AS $func$

DECLARE
    stress_cross_w_median REGCLASS;
    stress_cross_no_median REGCLASS;
    stress_seg_mixed REGCLASS;
    stress_seg_bike_w_park REGCLASS;
    stress_seg_bike_no_park REGCLASS;

BEGIN
    raise notice 'PROCESSING:';

    --test tables
    BEGIN
        IF cross_ THEN
            stress_cross_w_median := 'stress_cross_w_median'::REGCLASS;
            stress_cross_no_median := 'stress_cross_no_median'::REGCLASS;
        END IF;

        IF seg_ THEN
            stress_seg_mixed := 'stress_seg_mixed'::REGCLASS;
            stress_seg_bike_w_park := 'stress_seg_bike_w_park'::REGCLASS;
            stress_seg_bike_no_park := 'stress_seg_bike_no_park'::REGCLASS;
        END IF;
    END;

    --clear old values
    BEGIN
        RAISE NOTICE 'Clearing old values';
        IF seg_ THEN
            EXECUTE format('
                UPDATE  %s
                SET     ft_seg_stress = NULL,
                        tf_seg_stress = NULL;
                ',  input_table_);
        END IF;
        IF approach_ THEN
            EXECUTE format('
                UPDATE  %s
                SET     ft_int_stress = NULL,
                        tf_int_stress = NULL;
                ',  input_table_);
        END IF;
        IF cross_ THEN
            EXECUTE format('
                UPDATE  %s
                SET     ft_cross_stress = NULL,
                        tf_cross_stress = NULL;
                ',  input_table_);
        END IF;
    END;

    --do calcs
    BEGIN
        ------------------------------------------------------
        --apply segment stress using tables
        ------------------------------------------------------
        IF seg_ THEN
            RAISE NOTICE 'Calculating segment stress';

            -- mixed ft direction
            EXECUTE '
                UPDATE ' || input_table_ || '
                SET     ft_seg_stress=( SELECT      stress
                                        FROM        ' || stress_seg_mixed || ' s
                                        WHERE       ' || input_table_ || '.speed_limit <= s.speed
                                        AND         COALESCE(' || input_table_ || '.adt,0) <= s.adt
                                        AND         COALESCE(' || input_table_ || '.ft_seg_lanes_thru,1) <= s.lanes
                                        ORDER BY    s.stress ASC
                                        LIMIT       1)
                WHERE   (COALESCE(ft_seg_lanes_bike_wd_ft,0) < 4 AND COALESCE(ft_seg_lanes_park_wd_ft,0) = 0)
                OR      COALESCE(ft_seg_lanes_bike_wd_ft,0) + COALESCE(ft_seg_lanes_park_wd_ft,0) < 12;';

            -- mixed tf direction
            EXECUTE '
                UPDATE ' || input_table_ || '
                SET     tf_seg_stress=( SELECT      stress
                                        FROM        ' || stress_seg_mixed || ' s
                                        WHERE       ' || input_table_ || '.speed_limit <= s.speed
                                        AND         COALESCE(' || input_table_ || '.adt,0) <= s.adt
                                        AND         COALESCE(' || input_table_ || '.tf_seg_lanes_thru,1) <= s.lanes
                                        ORDER BY    s.stress ASC
                                        LIMIT       1)
                WHERE   (COALESCE(tf_seg_lanes_bike_wd_ft,0) < 4 AND COALESCE(tf_seg_lanes_park_wd_ft,0) = 0)
                OR      COALESCE(tf_seg_lanes_bike_wd_ft,0) + COALESCE(tf_seg_lanes_park_wd_ft,0) < 12;';

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
                ',  input_table_,
                    'stress_seg_bike_no_park',
                    input_table_,
                    input_table_,
                    input_table_);

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
                ',  input_table_,
                    'stress_seg_bike_no_park',
                    input_table_,
                    input_table_,
                    input_table_);

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
                ',  input_table_,
                    'stress_seg_bike_w_park',
                    input_table_,
                    input_table_,
                    input_table_,
                    input_table_);

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
                ',  input_table_,
                    'stress_seg_bike_w_park',
                    input_table_,
                    input_table_,
                    input_table_,
                    input_table_);

            --trails
            EXECUTE format('
                UPDATE  %s
                SET     ft_seg_stress = 1,
                        tf_seg_stress = 1
                WHERE   functional_class = %L;
                ',  input_table_,
                    'Trail');

            --overrides
            EXECUTE format('
                UPDATE  %s
                SET     ft_seg_stress = ft_seg_stress_override
                WHERE   ft_seg_stress_override IS NOT NULL;
                UPDATE  %s
                SET     tf_seg_stress = tf_seg_stress_override
                WHERE   tf_seg_stress_override IS NOT NULL;
                ',  input_table_,
                    input_table_);
        END IF;

        ------------------------------------------------------
        --apply intersection stress
        ------------------------------------------------------
        IF approach_ THEN
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
                ',  input_table_,
                    input_table_);

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
                ',  input_table_,
                    input_table_);

            -- pocket bike lane w/right turn lanes ft direction
            EXECUTE format('
                UPDATE  %s
                SET     ft_int_stress = 2
                WHERE   COALESCE(ft_int_lanes_bike_wd_ft,0) >= 4
                AND     ft_int_lanes_rt_len_ft <= 150
                AND     ft_int_lanes_rt_rad_mph <= 15
                AND     ft_int_lanes_bike_straight = 1;
                UPDATE  %s
                SET     ft_int_stress = 3
                WHERE   COALESCE(ft_int_lanes_bike_wd_ft,0) >= 4
                AND     COALESCE(ft_int_lanes_rt_len_ft,0) > 0
                AND     ft_int_lanes_rt_rad_mph <= 20
                AND     ft_int_lanes_bike_straight = 1
                AND     ft_int_stress IS NOT NULL;
                UPDATE  %s
                SET     ft_int_stress = 3
                WHERE   COALESCE(ft_int_lanes_bike_wd_ft,0) >= 4
                AND     ft_int_lanes_rt_rad_mph <= 15
                AND     COALESCE(ft_int_lanes_bike_straight,0) = 0;
                UPDATE  %s
                SET     ft_int_stress = 4
                WHERE   COALESCE(ft_int_lanes_bike_wd_ft,0) >= 4
                AND     ft_int_stress IS NULL;
                ',  input_table_,
                    input_table_,
                    input_table_,
                    input_table_);

            -- pocket bike lane w/right turn lanes tf direction
            EXECUTE format('
                UPDATE  %s
                SET     tf_int_stress = 2
                WHERE   COALESCE(tf_int_lanes_bike_wd_ft,0) >= 4
                AND     tf_int_lanes_rt_len_ft <= 150
                AND     tf_int_lanes_rt_rad_mph <= 15
                AND     tf_int_lanes_bike_straight = 1;
                UPDATE  %s
                SET     tf_int_stress = 3
                WHERE   COALESCE(tf_int_lanes_bike_wd_ft,0) >= 4
                AND     COALESCE(tf_int_lanes_rt_len_ft,0) > 0
                AND     tf_int_lanes_rt_rad_mph <= 20
                AND     tf_int_lanes_bike_straight = 1
                AND     tf_int_stress IS NOT NULL;
                UPDATE  %s
                SET     tf_int_stress = 3
                WHERE   COALESCE(tf_int_lanes_bike_wd_ft,0) >= 4
                AND     tf_int_lanes_rt_rad_mph <= 15
                AND     COALESCE(tf_int_lanes_bike_straight,0) = 0;
                UPDATE  %s
                SET     tf_int_stress = 4
                WHERE   COALESCE(tf_int_lanes_bike_wd_ft,0) >= 4
                AND     tf_int_stress IS NULL;
                ',  input_table_,
                    input_table_,
                    input_table_,
                    input_table_);

            --trails
            EXECUTE format('
                UPDATE  %s
                SET     ft_int_stress = 1,
                        tf_int_stress = 1
                WHERE   functional_class = %L;
                ',  input_table_,
                    'Trail');

            --overrides
            EXECUTE format('
                UPDATE  %s
                SET     ft_int_stress = ft_int_stress_override
                WHERE   ft_int_stress_override IS NOT NULL;
                UPDATE  %s
                SET     tf_int_stress = tf_int_stress_override
                WHERE   tf_int_stress_override IS NOT NULL;
                ',  input_table_,
                    input_table_);
        END IF;

        ------------------------------------------------------
        --apply crossing stress
        ------------------------------------------------------
        IF cross_ THEN
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
                ',  input_table_,
                    'stress_cross_no_median',
                    input_table_,
                    input_table_);

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
                ',  input_table_,
                    'stress_cross_no_median',
                    input_table_,
                    input_table_);

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
                ',  input_table_,
                    'stress_cross_w_median',
                    input_table_,
                    input_table_);

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
                ',  input_table_,
                    'stress_cross_w_median',
                    input_table_,
                    input_table_);

            --traffic signals ft
            EXECUTE format('
                UPDATE  %s
                SET     ft_cross_stress = 1
                WHERE   ft_cross_signal = 1;
                ',  input_table_);

            --traffic signals tf
            EXECUTE format('
                UPDATE  %s
                SET     tf_cross_stress = 1
                WHERE   tf_cross_signal = 1;
                ',  input_table_);

            --overrides
            EXECUTE format('
                UPDATE  %s
                SET     tf_cross_stress = tf_cross_stress_override
                WHERE   tf_cross_stress_override IS NOT NULL;
                UPDATE  %s
                SET     ft_cross_stress = ft_cross_stress_override
                WHERE   ft_cross_stress_override IS NOT NULL;
                ',  input_table_,
                    input_table_);
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
            ',  input_table_,
                'tf',
                input_table_,
                'ft');
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgCalculateStress(REGCLASS,BOOLEAN,BOOLEAN,BOOLEAN,INT[]) OWNER TO gis;
