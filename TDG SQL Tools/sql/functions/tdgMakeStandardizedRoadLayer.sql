CREATE OR REPLACE FUNCTION tdg.tdgMakeStandardizedRoadLayer(
    input_table_ REGCLASS,
    output_schema_ TEXT,
    output_table_name_ TEXT,
    overwrite_ BOOLEAN)
RETURNS BOOLEAN AS $func$

DECLARE
    namecheck RECORD;
    table_name TEXT;
    road_table TEXT;
    intersection_table TEXT;
    srid INT;
BEGIN
    raise notice 'PROCESSING:';

    --create schema if needed
    EXECUTE 'CREATE SCHEMA IF NOT EXISTS ' || output_schema_ || ';';

    --set output tables
    road_table = output_schema_ || '.' || output_table_name_;
    intersection_table = road_table || '_intersections';

    --drop table if overwrite
    IF overwrite_ THEN
        EXECUTE 'DROP TABLE IF EXISTS ' || intersection_table || ';';
        EXECUTE 'DROP TABLE IF EXISTS ' || road_table || ';';
    ELSE
        RAISE NOTICE 'Checking whether table % exists',road_table;
        EXECUTE '   SELECT  table_name
                    FROM    tdgTableDetails($1)'
        USING   road_table
        INTO    namecheck;

        IF NOT namecheck IS NULL THEN
            RAISE EXCEPTION 'Table % already exists', road_table;
        END IF;

        RAISE NOTICE 'Checking whether table % exists',intersection_table;
        EXECUTE '   SELECT  table_name
                    FROM    tdgTableDetails($1)'
        USING   intersection_table
        INTO    namecheck;

        IF NOT namecheck IS NULL THEN
            RAISE EXCEPTION 'Table % already exists', intersection_table;
        END IF;
    END IF;

    --get srid of the geom
    BEGIN
        RAISE NOTICE 'Getting SRID of geometry';
        EXECUTE 'SELECT tdgGetSRID($1,$2);'
        USING   input_table_,
                'geom'
        INTO    srid;

        IF srid IS NULL THEN
            RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', t_name;
        END IF;
        raise NOTICE '  -----> SRID found %',srid;
    END;

    --create new table
    BEGIN
        RAISE NOTICE 'Creating table %', road_table;
        EXECUTE '
            CREATE TABLE '||road_table||' (
                road_id SERIAL PRIMARY KEY,
                geom geometry(linestring,'||srid::TEXT||'),
                road_name TEXT,
                road_from TEXT,
                road_to TEXT,
                z_from INT DEFAULT 0,
                z_to INT DEFAULT 0,
                intersection_from INT,
                intersection_to INT,
                source_data TEXT,
                source_id TEXT,
                functional_class TEXT,
                one_way VARCHAR(2) CHECK (
                    one_way = '||quote_literal('ft')||'
                    OR one_way = '||quote_literal('tf')||'),
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
                tf_cross_stress INT);';
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeStandardizedRoadLayer(
    REGCLASS,TEXT,TEXT,BOOLEAN) OWNER TO gis;
