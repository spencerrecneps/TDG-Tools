CREATE OR REPLACE FUNCTION tdg.tdgStandardizeRoadLayer(
    input_table_ REGCLASS,
    output_schema_ TEXT,
    output_table_name_ TEXT,
    id_field_ TEXT,
    name_field_ TEXT,
    z_from_field_ TEXT,
    z_to_field_ TEXT,
    adt_field_ TEXT,
    speed_field_ TEXT,
    func_field_ TEXT,
    oneway_field_ TEXT,
    overwrite_ BOOLEAN,
    delete_source_ BOOLEAN)
RETURNS BOOLEAN AS $func$

DECLARE
    namecheck RECORD;
    input_schema TEXT;
    table_name TEXT;
    road_table TEXT;
    intersection_table TEXT;
    querytext TEXT;
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
        EXECUTE format('
            CREATE TABLE %s (   road_id SERIAL PRIMARY KEY,
                                geom geometry(linestring,%L),
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
                                tf_cross_stress INT)
            ',  road_table,
                srid);
    END;

    --copy features over
    BEGIN
        RAISE NOTICE 'Copying features to %', road_table;
        --querytext := '';
        querytext := '   INSERT INTO ' || road_table || ' (geom';
        querytext := querytext || ',source_data';
        IF name_field_ IS NOT NULL THEN
            querytext := querytext || ',road_name';
            END IF;
        IF id_field_ IS NOT NULL THEN
            querytext := querytext || ',source_id';
            END IF;
        IF func_field_ IS NOT NULL THEN
            querytext := querytext || ',functional_class';
            END IF;
        IF oneway_field_ IS NOT NULL THEN
            querytext := querytext || ',one_way';
            END IF;
        IF speed_field_ IS NOT NULL THEN
            querytext := querytext || ',speed_limit';
            END IF;
        IF adt_field_ IS NOT NULL THEN
            querytext := querytext || ',adt';
            END IF;
        IF z_from_field_ IS NOT NULL THEN
            querytext := querytext || ',z_from';
            END IF;
        IF z_to_field_ IS NOT NULL THEN
            querytext := querytext || ',z_to';
            END IF;
        querytext := querytext || ') SELECT ST_SnapToGrid(r.geom,2)';
        querytext := querytext || ',' || quote_literal(input_table_);
        IF name_field_ IS NOT NULL THEN
            querytext := querytext || ',' || quote_ident(name_field_);
            END IF;
        IF id_field_ IS NOT NULL THEN
            querytext := querytext || ',' || quote_ident(id_field_);
            END IF;
        IF func_field_ IS NOT NULL THEN
            querytext := querytext || ',' || quote_ident(func_field_);
            END IF;
        IF oneway_field_ IS NOT NULL THEN
            querytext := querytext || ',' || quote_ident(oneway_field_);
            END IF;
        IF speed_field_ IS NOT NULL THEN
            querytext := querytext || ',' || quote_ident(speed_field_);
            END IF;
        IF adt_field_ IS NOT NULL THEN
            querytext := querytext || ',' || quote_ident(adt_field_);
            END IF;
        IF z_from_field_ IS NOT NULL THEN
            querytext := querytext || ',' || quote_ident(z_from_field_);
            END IF;
        IF z_to_field_ IS NOT NULL THEN
            querytext := querytext || ',' || quote_ident(z_to_field_);
            END IF;
        querytext := querytext || ' FROM ' ||input_table_|| ' r';

        EXECUTE querytext;
    END;

    --indexes
    BEGIN
        EXECUTE format('
            CREATE INDEX sidx_%s_geom ON %s USING GIST(geom);
            CREATE INDEX idx_%s_oneway ON %s (one_way);
            CREATE INDEX idx_%s_sourceid ON %s (source_id);
            CREATE INDEX idx_%s_funcclass ON %s (functional_class);
            CREATE INDEX idx_%s_zf ON %s (z_from);
            CREATE INDEX idx_%s_zt ON %s (z_to);
            ',  output_table_name_,
                road_table,
                output_table_name_,
                road_table,
                output_table_name_,
                road_table,
                output_table_name_,
                road_table,
                output_table_name_,
                road_table,
                output_table_name_,
                road_table);
    END;

    BEGIN
        EXECUTE format('ANALYZE %s;',road_table);
    END;

    -- BEGIN
    --     IF z_from_field_ IS NOT NULL AND z_to_field_ IS NOT NULL THEN
    --         PERFORM tdgMakeIntersections(road_table::REGCLASS,'t'::BOOLEAN);
    --     ELSE
    --         PERFORM tdgMakeIntersections(road_table::REGCLASS,'f'::BOOLEAN);
    --     END IF;
    --
    -- END;

    BEGIN
        EXECUTE format('ANALYZE %s;',road_table);
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgStandardizeRoadLayer(
    REGCLASS,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,
    TEXT,TEXT,TEXT,BOOLEAN,BOOLEAN) OWNER TO gis;
