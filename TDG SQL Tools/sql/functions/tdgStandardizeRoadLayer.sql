CREATE OR REPLACE FUNCTION tdgStandardizeRoadLayer( input_table REGCLASS,
                                                    output_table TEXT,
                                                    id_field TEXT,
                                                    name_field TEXT,
                                                    adt_field TEXT,
                                                    speed_field TEXT,
                                                    func_field TEXT,
                                                    oneway_field TEXT,
                                                    overwrite BOOLEAN,
                                                    delete_source BOOLEAN)
RETURNS BOOLEAN AS $func$

DECLARE
    schemaname TEXT;
    outtabname TEXT;
    query TEXT;
    srid INT;

BEGIN
    raise notice 'PROCESSING:';

    --get schema
    BEGIN
        schemaname = 'tdg';
        outtabname = schemaname||'.'||output_table;
    END;

    --get srid of the geom
    BEGIN
        EXECUTE format('SELECT tdgGetSRID(to_regclass(%L),%s)',input_table,quote_literal('geom')) INTO srid;

        IF srid IS NULL THEN
            RAISE NOTICE 'ERROR: Can not determine the srid of the geometry in table %', t_name;
            RETURN 'f';
        END IF;
        raise DEBUG '  -----> SRID found %',srid;
    END;

    --drop new table if exists
    BEGIN
        IF overwrite THEN
            RAISE NOTICE 'DROPPING TABLE %', output_table;
            EXECUTE format('DROP TABLE IF EXISTS %s',output_table);
        END IF;
    END;

    --create new table
    BEGIN
        EXECUTE format('
            CREATE TABLE %s (   id SERIAL PRIMARY KEY,
                                geom geometry(linestring,%L),
                                road_name TEXT,
                                source_id TEXT,
                                functional_class TEXT,
                                one_way VARCHAR(2),
                                speed_limit INT,
                                adt INT,
                                ft_seg_lanes_thru INT,
                                ft_seg_lanes_bike_wd_ft INT,
                                ft_seg_lanes_park_wd_ft INT,
                                ft_seg_stress_override INT,
                                ft_seg_stress INT,
                                ft_int_lanes_thru INT,
                                ft_int_lanes_lt INT,
                                ft_int_lanes_rt_len_ft INT,
                                ft_int_lanes_rt_radius_speed_mph INT,
                                ft_int_lanes_bike_wd_ft INT,
                                ft_int_lanes_bike_straight INT,
                                ft_int_stress_override INT,
                                ft_int_stress INT,
                                ft_cross_median_wd_ft INT,
                                ft_cross_signal INT,
                                ft_cross_speed_limit INT,
                                ft_cross_lanes INT,
                                ft_cross_stress_override INT,
                                ft_cross_stress INT,
                                tf_seg_lanes_thru INT,
                                tf_seg_lanes_bike_wd_ft INT,
                                tf_seg_lanes_park_wd_ft INT,
                                tf_seg_stress_override INT,
                                tf_seg_stress INT,
                                tf_int_lanes_thru INT,
                                tf_int_lanes_lt INT,
                                tf_int_lanes_rt_len_ft INT,
                                tf_int_lanes_rt_radius_speed_mph INT,
                                tf_int_lanes_bike_wd_ft INT,
                                tf_int_lanes_bike_straight INT,
                                tf_int_stress_override INT,
                                tf_int_stress INT,
                                tf_cross_median_wd_ft INT,
                                tf_cross_signal INT,
                                tf_cross_speed_limit INT,
                                tf_cross_lanes INT,
                                tf_cross_stress_override INT,
                                tf_cross_stress INT,
                                source INT,
                                target INT,
                                cost INT,
                                reverse_cost INT)
            ',  outtabname,
                srid);
    END;

    --copy features over
    BEGIN
        query := '';
        query := '   INSERT INTO ' || outtabname || ' (geom';
        IF name_field IS NOT NULL THEN
            query := query || ',road_name';
            END IF;
        IF id_field IS NOT NULL THEN
            query := query || ',source_id';
            END IF;
        IF func_field IS NOT NULL THEN
            query := query || ',functional_class';
            END IF;
        IF oneway_field IS NOT NULL THEN
            query := query || ',one_way';
            END IF;
        IF speed_field IS NOT NULL THEN
            query := query || ',speed_limit';
            END IF;
        IF adt_field IS NOT NULL THEN
            query := query || ',adt';
            END IF;
        query := query || ') SELECT ST_SnapToGrid(r.geom,2)';
        IF name_field IS NOT NULL THEN
            query := query || ',' || name_field;
            END IF;
        IF id_field IS NOT NULL THEN
            query := query || ',' || id_field;
            END IF;
        IF func_field IS NOT NULL THEN
            query := query || ',' || func_field;
            END IF;
        IF oneway_field IS NOT NULL THEN
            query := query || ',' || oneway_field;
            END IF;
        IF speed_field IS NOT NULL THEN
            query := query || ',' || speed_field;
            END IF;
        IF adt_field IS NOT NULL THEN
            query := query || ',' || adt_field;
            END IF;
        query := query || ' FROM ' ||input_table::TEXT|| ' r';

        EXECUTE query;
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
