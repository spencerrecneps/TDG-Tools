--check for plpythonu and install if not present already
CREATE OR REPLACE FUNCTION make_plpythonu()
RETURNS VOID
LANGUAGE SQL
AS $$
    CREATE LANGUAGE plpythonu;
$$;
SELECT
    CASE
    WHEN EXISTS(
        SELECT 1
        FROM pg_catalog.pg_language
        WHERE lanname='plpythonu'
    )
    THEN NULL
    ELSE make_plpythonu() END;
DROP FUNCTION make_plpythonu();

--give permission to the tdg schema
GRANT ALL ON SCHEMA tdg TO PUBLIC;

CREATE SCHEMA IF NOT EXISTS generated AUTHORIZATION gis;
CREATE SCHEMA IF NOT EXISTS received AUTHORIZATION gis;
CREATE SCHEMA IF NOT EXISTS scratch AUTHORIZATION gis;
CREATE TYPE tdg.tdgShortestPathType AS (
    path_id INT,
    from_vert INT,
    to_vert INT,
    move_sequence INT,
    link_id INT,
    vert_id INT,
    road_id INT,
    int_id INT,
    move_cost INT,
    cumulative_cost INT
);
CREATE TABLE stress_seg_mixed (
    speed integer,
    adt integer,
    lanes integer,
    stress integer,
    CONSTRAINT stress_seg_mixed_key PRIMARY KEY (speed,adt,lanes,stress)
);

INSERT INTO stress_seg_mixed (speed, adt, lanes, stress)
VALUES  (25,750,0,1),
        (25,2000,0,1),
        (25,3000,0,1),
        (25,999999,0,2),
        (25,750,1,1),
        (25,2000,1,1),
        (25,6000,1,2),
        (25,999999,1,3),
        (25,6000,2,3),
        (25,999999,2,3),
        (30,750,0,2),
        (30,2000,0,2),
        (30,3000,0,2),
        (30,999999,0,2),
        (30,750,1,2),
        (30,2000,1,2),
        (30,6000,1,3),
        (30,999999,1,3),
        (30,6000,2,3),
        (30,999999,2,4),
        (35,750,0,2),
        (35,2000,0,3),
        (35,3000,0,3),
        (35,999999,0,3),
        (35,750,1,2),
        (35,2000,1,3),
        (35,6000,1,4),
        (35,999999,1,4),
        (35,6000,2,3),
        (35,999999,2,4),
        (40,750,0,3),
        (40,2000,0,3),
        (40,3000,0,4),
        (40,999999,0,4),
        (40,750,1,3),
        (40,2000,1,3),
        (40,6000,1,4),
        (40,999999,1,4),
        (40,6000,2,4),
        (40,999999,2,4),
        (45,750,0,3),
        (45,2000,0,4),
        (45,3000,0,4),
        (45,999999,0,4),
        (45,750,1,3),
        (45,2000,1,4),
        (45,6000,1,4),
        (45,999999,1,4),
        (45,6000,2,4),
        (45,999999,2,4),
        (99,750,0,4),
        (99,2000,0,4),
        (99,3000,0,4),
        (99,999999,0,4),
        (99,750,1,4),
        (99,2000,1,4),
        (99,6000,1,4),
        (99,999999,1,4),
        (99,6000,2,4),
        (99,999999,2,4),
        (25,999999,99,3),
        (30,999999,99,4),
        (35,999999,99,4),
        (40,999999,99,4),
        (45,999999,99,4),
        (99,999999,99,4);

GRANT ALL ON TABLE tdg.stress_seg_mixed TO public;
ANALYZE tdg.stress_seg_mixed;
CREATE TABLE stress_seg_bike_w_park (
    speed integer,
    bike_park_lane_wd_ft integer,
    lanes integer,
    stress integer,
    CONSTRAINT stress_seg_bike_w_park_key PRIMARY KEY (speed,bike_park_lane_wd_ft,lanes,stress)
);

INSERT INTO stress_seg_bike_w_park (speed, bike_park_lane_wd_ft, lanes, stress)
VALUES  (20,99,1,1),
        (20,14,1,2),
        (20,13,1,2),
        (20,99,99,3),
        (20,14,99,3),
        (25,99,1,1),
        (25,14,1,2),
        (25,13,1,23),
        (25,99,99,3),
        (25,14,99,3),
        (30,99,1,2),
        (30,14,1,2),
        (30,13,1,23),
        (30,99,99,3),
        (30,14,99,3),
        (35,99,1,3),
        (35,14,1,3),
        (35,13,1,3),
        (35,99,99,3),
        (35,14,99,3),
        (99,99,1,3),
        (99,14,1,4),
        (99,13,1,4),
        (99,99,99,3),
        (99,14,99,4);

GRANT ALL ON TABLE tdg.stress_seg_bike_w_park TO public;
ANALYZE tdg.stress_seg_bike_w_park;
CREATE TABLE stress_cross_w_median (
    speed integer,
    lanes integer,
    stress integer,
    CONSTRAINT stress_cross_w_median_pkey PRIMARY KEY (speed,lanes,stress)
);

INSERT INTO stress_cross_w_median (speed, lanes, stress)
VALUES  (25,3,1),
        (25,5,1),
        (25,99,2),
        (30,3,1),
        (30,5,2),
        (30,99,3),
        (35,3,2),
        (35,5,3),
        (35,99,4),
        (99,3,3),
        (99,5,4),
        (99,99,4);

GRANT ALL ON TABLE tdg.stress_cross_w_median TO public;
ANALYZE tdg.stress_cross_w_median;
CREATE TABLE stress_seg_bike_no_park (
    speed integer,
    bike_lane_wd_ft integer,
    lanes integer,
    stress integer,
    CONSTRAINT stress_seg_bike_no_park_key PRIMARY KEY (speed,bike_lane_wd_ft,lanes,stress)
);

INSERT INTO stress_seg_bike_no_park (speed, bike_lane_wd_ft, lanes, stress)
VALUES  (25,99,1,1),
        (25,5,1,2),
        (25,99,2,2),
        (25,5,2,2),
        (25,99,99,3),
        (25,5,99,3),
        (30,99,1,1),
        (30,5,1,2),
        (30,99,2,2),
        (30,5,2,2),
        (30,99,99,3),
        (30,5,99,3),
        (35,99,1,1),
        (35,5,1,2),
        (35,99,2,2),
        (35,5,2,2),
        (35,99,99,3),
        (35,5,99,3),
        (40,99,1,3),
        (40,5,1,3),
        (40,99,2,3),
        (40,5,2,3),
        (40,99,99,4),
        (40,5,99,4),
        (45,99,1,3),
        (45,5,1,3),
        (45,99,2,3),
        (45,5,2,4),
        (45,99,99,4),
        (45,5,99,4),
        (99,99,1,3),
        (99,5,1,4),
        (99,99,2,3),
        (99,5,2,4),
        (99,99,99,4),
        (99,5,99,4);

GRANT ALL ON TABLE tdg.stress_seg_bike_no_park TO public;
ANALYZE tdg.stress_seg_bike_no_park;
CREATE TABLE stress_cross_no_median (
    speed integer,
    lanes integer,
    stress integer,
    CONSTRAINT stress_cross_no_median_pkey PRIMARY KEY (speed,lanes,stress)
);

INSERT INTO stress_cross_no_median (speed, lanes, stress)
VALUES  (25,3,1),
        (25,5,2),
        (25,99,4),
        (30,3,1),
        (30,5,2),
        (30,99,4),
        (35,3,2),
        (35,5,3),
        (35,99,4),
        (99,3,3),
        (99,5,4),
        (99,99,4);

GRANT ALL ON TABLE tdg.stress_cross_no_median TO public;
ANALYZE tdg.stress_cross_no_median;
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
    EXECUTE '
        UPDATE  '||link_table_||'
        SET     movement = NULL
        FROM    '||int_table_||' ints
        WHERE   ints.int_id = '||link_table_||'.int_id
        AND     ints.int_id = ANY ($1);'
    USING   int_ids_;

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
CREATE OR REPLACE FUNCTION tdg.tdgGenerateCrossStreetData(
    road_table_ REGCLASS,
    road_ids_ INTEGER[] DEFAULT NULL)
--populate cross-street data
RETURNS BOOLEAN AS $func$

DECLARE
    int_table REGCLASS;

BEGIN
    raise notice 'PROCESSING:';

    --compile list of int_ids_ if needed
    IF road_ids_ IS NULL THEN
        EXECUTE 'SELECT array_agg(road_id) FROM '||road_table_||';' INTO road_ids_;
    END IF;

    int_table = road_table_ || '_intersections';

    RAISE NOTICE 'Clearing old values';
    EXECUTE '
        UPDATE  ' || road_table_ || '
        SET     road_from = NULL,
                road_to = NULL
        WHERE   road_id = ANY ($1);'
    USING   road_ids_;

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
        AND     '||road_table_||'.road_id != r.road_id
        AND     '||road_table_||'.road_id = ANY ($1);'
    USING   road_ids_;
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
        AND     '||road_table_||'.road_id != r.road_id
        AND     '||road_table_||'.road_id = ANY ($1);'
    USING   road_ids_;

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
            WHERE   a.road_id = ANY ($1)
        )
        UPDATE  '||road_table_||'
        SET     road_from = (   SELECT      x.road_name
                                FROM        x
                                WHERE       '||road_table_||'.road_id = x.this_id
                                ORDER BY    ABS(SIN(RADIANS(MOD(360 + x.xing_azi - x.this_azi,360)))) DESC
                                LIMIT       1)
        WHERE   road_id = ANY ($1)'
    USING   road_ids_;
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
            WHERE   a.road_id = ANY ($1)
        )
        UPDATE  '||road_table_||'
        SET     road_to = (     SELECT      x.road_name
                                FROM        x
                                WHERE       '||road_table_||'.road_id = x.this_id
                                ORDER BY    ABS(SIN(RADIANS(MOD(360 + x.xing_azi - x.this_azi,360)))) DESC
                                LIMIT       1)
        WHERE   road_id = ANY ($1)'
    USING   road_ids_;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgGenerateCrossStreetData(REGCLASS,INTEGER[]) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgInsertIntersections(
    int_table_ REGCLASS,
    road_table_ REGCLASS)
RETURNS BOOLEAN AS $func$

DECLARE
    rowcount INT;

BEGIN
    RAISE NOTICE 'Checking for existing intersections in %', int_table_;
    EXECUTE 'SELECT 1 FROM '||int_table_||' WHERE int_id IS NOT NULL;';
    GET DIAGNOSTICS rowcount = ROW_COUNT;

    IF rowcount > 0 THEN
        RAISE EXCEPTION 'Records already exist in %', int_table_
        USING HINT = 'Drop all existing records or use road_ids as an input.';
    END IF;

    RAISE NOTICE 'Inserting intersections into %', int_table_;
    EXECUTE '
        INSERT INTO '||int_table_||' (geom, z_elev)
        SELECT  ST_StartPoint(road_f.geom), road_f.z_from
        FROM    '||road_table_||' road_f
        UNION
        SELECT  ST_EndPoint(road_t.geom), road_t.z_to
        FROM    '||road_table_||' road_t';

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgInsertIntersections(REGCLASS,REGCLASS) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdgTableCheck (input_table REGCLASS)
RETURNS BOOLEAN AS $func$

DECLARE
    namecheck RECORD;

BEGIN
    RAISE NOTICE 'Checking % exists',input_table;
    EXECUTE '   SELECT  schema_name,
                        table_name
                FROM    tdgTableDetails('||quote_literal(input_table)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
    IF namecheck.schema_name IS NULL OR namecheck.table_name IS NULL THEN
        RETURN 'f';
    END IF;

RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgTableCheck(REGCLASS) OWNER TO gis;
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
CREATE OR REPLACE FUNCTION tdg.tdgMultiToSingle (
    temp_table_ REGCLASS,
    new_table_ TEXT,
    schema_ TEXT,
    srid_ INTEGER,
    overwrite_ BOOLEAN)
RETURNS BOOLEAN AS $func$

DECLARE
    namecheck TEXT;
    primarykeycolumn TEXT;
    columndetails RECORD;
    newcolumnname TEXT;
    columncount INT;
    addstatement TEXT;
    copystatement TEXT;

BEGIN
    --create schema if needed
    EXECUTE 'CREATE SCHEMA IF NOT EXISTS ' || schema_ || ';';

    --drop table if overwrite
    IF overwrite_ THEN
        EXECUTE 'DROP TABLE IF EXISTS ' || schema_ || '.' || new_table_ || ';';
    ELSE
        RAISE NOTICE 'Checking whether table % exists',new_table_;
        EXECUTE '   SELECT  table_name
                    FROM    tdgTableDetails($1)'
        USING   schema_ || '.' || new_table_
        INTO    namecheck;

        IF NOT namecheck IS NULL THEN
            RAISE EXCEPTION 'Table % already exists', new_table_;
        END IF;
    END IF;

    --get temp table primary key column name
    RAISE NOTICE 'Getting primary key from %', temp_table_;
    EXECUTE '
        SELECT a.attname
        FROM   pg_index i
        JOIN   pg_attribute a
                    ON a.attrelid = i.indrelid
                    AND a.attnum = ANY(i.indkey)
        WHERE  i.indrelid = $1::regclass
        AND    i.indisprimary;'
    USING   schema_ || '.' || temp_table_
    INTO    primarykeycolumn;

    --create new table
    RAISE NOTICE 'Creating table %',new_table_;
    EXECUTE '   CREATE TABLE ' || schema_ || '.' || new_table_ || '
                    ( ' || primarykeycolumn || ' SERIAL PRIMARY KEY,
                        temp_id INTEGER,
                        tdg_id TEXT NOT NULL DEFAULT uuid_generate_v4()::TEXT,
                        geom geometry(LINESTRING,' || srid_::TEXT || '));';

    --insert info from temporary table
    EXECUTE '   INSERT INTO ' || schema_ || '.' || new_table_ || ' (temp_id,geom)
                SELECT ' || primarykeycolumn || ',ST_Transform((ST_Dump(geom)).geom,$1)
                FROM ' || temp_table_ || ';'
    USING   srid_;


    --copy table structure from temporary table
    RAISE NOTICE 'Copying table structure from %', temp_table_;

    --loop through temp table columns and build statements to copy data
    columncount := 0;
    addstatement := 'ALTER TABLE ' || schema_ || '.' || new_table_ || ' ';
    copystatement := 'UPDATE ' || schema_ || '.' || new_table_ || ' SET ';
    FOR columndetails IN
    EXECUTE '
        SELECT  a.attname AS col,
                pg_catalog.format_type(a.atttypid, a.atttypmod) AS datatype
        FROM    pg_catalog.pg_attribute a
        WHERE   a.attnum > 0
        AND     NOT a.attisdropped
        AND     a.attrelid = ' || quote_literal(temp_table_) || '::REGCLASS;'
    LOOP
        IF columndetails.col NOT IN (primarykeycolumn,'geom','tdg_id') THEN
            RAISE NOTICE 'Found column %', columndetails.col;
            --advance count
            columncount := columncount + 1;

            --sanitize column name
            newcolumnname := regexp_replace(LOWER(columndetails.col), '[^a-zA-Z0-9_]', '', 'g');
            IF columncount = 1 THEN
                addstatement := addstatement || ' ADD COLUMN '
                                || newcolumnname || ' '
                                || columndetails.datatype;
            ELSE
                addstatement := addstatement || ', ADD COLUMN '
                                || newcolumnname || ' '
                                || columndetails.datatype;
            END IF;

            --copy data over
            IF columncount = 1 THEN
                copystatement := copystatement || newcolumnname || '=t.'
                                || quote_ident(columndetails.col);
            ELSE
                copystatement := copystatement || ',' || newcolumnname || '=t.'
                                || quote_ident(columndetails.col);
            END IF;
        END IF;
    END LOOP;

    copystatement := copystatement || ' FROM ' || temp_table_ || ' t WHERE t.'
        || primarykeycolumn || ' = ' || schema_ || '.' || new_table_ || '.temp_id;';

    RAISE NOTICE 'Adding columns';
    EXECUTE addstatement;
    RAISE NOTICE 'Copying data';
    EXECUTE copystatement;

    --drop the temp_id column
    RAISE NOTICE 'Dropping temoporary ID column';
    EXECUTE 'ALTER TABLE ' || schema_ || '.' || new_table_ || ' DROP COLUMN temp_id;';

    --drop the temporary table
    RAISE NOTICE 'Dropping temoporary table';
    EXECUTE 'DROP TABLE ' || temp_table_ || ';';

    RETURN 't';

END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMultiToSingle(REGCLASS,TEXT,TEXT,INTEGER,BOOLEAN) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgShortestPathVerts (
    link_table_ REGCLASS,
    vert_table_ REGCLASS,
    from_to_pairs_ INTEGER[],
    stress_ INTEGER DEFAULT NULL)
RETURNS SETOF tdg.tdgShortestPathType AS $$

import networkx as nx

# switch to pythonic variable names
linkTable = link_table_
vertTable = vert_table_
fromToPairs = from_to_pairs_

# check the fromToPairs input to make sure there isn't an unpaired number
if not len(fromToPairs)%2 == 0:
    plpy.error('Unpaired vertex given')

# split fromToPairs into pairs
vertPairs = zip(fromToPairs[::2], fromToPairs[1::2])

# check vert existence
for pair in vertPairs:
    for v in pair:
        qc = plpy.execute('SELECT EXISTS (SELECT 1 FROM %s WHERE vert_id = %s)' % (vertTable,v))
        if not qc[0]['exists']:
            plpy.error('Vertex' + str(v) + ' does not exist.')

# set up function to return edges
def getNextNode(nodes,node):
    pos = nodes.index(node)
    try:
        return nodes[pos+1]
    except:
        return None

# create the graph
DG=nx.DiGraph()

# read input stress
stress = 99
if not stress_ is None:
    stress = stress_

# edges first
edges = plpy.execute('SELECT * FROM %s;' % linkTable)
for e in edges:
    DG.add_edge(e['source_vert'],
                e['target_vert'],
                weight=max(e['link_cost'],0),
                link_id=e['link_id'],
                stress=min(e['link_stress'],99),
                road_id=e['road_id'])

# then vertices
verts = plpy.execute('SELECT * FROM %s;' % vertTable)
for v in verts:
    vid = v['vert_id']
    DG.node[vid]['weight'] = max(v['vert_cost'],0)
    DG.node[vid]['int_id'] = v['int_id']


# get the shortest path
ret = []
pairId = 0
for fromVert, toVert in vertPairs:
    pairId = pairId + 1
    if fromVert == toVert:  # handle case where same from/to vert is given
        ret.append((pairId,
                    fromVert,
                    toVert,
                    1,
                    None,
                    None,
                    None,
                    None,
                    0,
                    0))
    else:
        plpy.info('Checking for path existence from: ' + str(fromVert) + \
            ' to: ' + str(toVert))
        if nx.has_path(DG,source=fromVert,target=toVert):
            plpy.info('Path found')
            shortestPath = nx.shortest_path(DG,source=fromVert,target=toVert,weight='weight')
            seq = 0
            cost = 0
            for v1 in shortestPath:
                v2 = getNextNode(shortestPath,v1)
                seq = seq + 1
                if v2:
                    if seq == 1:
                        ret.append((pairId,
                                    fromVert,
                                    toVert,
                                    seq,
                                    None,
                                    v1,
                                    None,
                                    DG.node[v1]['int_id'],
                                    0,
                                    0))
                        seq = seq + 1
                    else:
                        cost = cost + DG.node[v1]['weight']
                        ret.append((pairId,
                                    fromVert,
                                    toVert,
                                    seq,
                                    None,
                                    v1,
                                    None,
                                    DG.node[v1]['int_id'],
                                    DG.node[v1]['weight'],
                                    cost))
                        seq = seq + 1
                    cost = cost + DG.edge[v1][v2]['weight']
                    ret.append((pairId,
                                fromVert,
                                toVert,
                                seq,
                                DG.edge[v1][v2]['link_id'],
                                None,
                                DG.edge[v1][v2]['road_id'],
                                None,
                                DG.edge[v1][v2]['weight'],
                                cost))
                else:
                    ret.append((pairId,
                                fromVert,
                                toVert,
                                seq,
                                None,
                                v1,
                                None,
                                DG.node[v1]['int_id'],
                                0,
                                cost))
        else:
            ret.append((pairId,
                        fromVert,
                        toVert,
                        None,
                        None,
                        None,
                        None,
                        None,
                        None,
                        None))

return ret

$$ LANGUAGE plpythonu;
ALTER FUNCTION tdg.tdgShortestPathVerts(REGCLASS,REGCLASS,INTEGER[],INTEGER) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgInsertIntersections(
    int_table_ REGCLASS,
    road_table_ REGCLASS,
    road_ids INTEGER[])
RETURNS BOOLEAN AS $func$

BEGIN
    RAISE NOTICE 'Inserting intersections into %', int_table_;

    -- create staging table
    DROP TABLE IF EXISTS tmp_ints;
    EXECUTE '
        CREATE TEMPORARY TABLE tmp_ints (
            geom geometry(point),
            z_elev INTEGER)
        ON COMMIT DROP;';

    -- add candidate points
    EXECUTE '
        INSERT INTO tmp_ints (geom, z_elev)
        SELECT  ST_StartPoint(road_f.geom), road_f.z_from
        FROM    '||road_table_||' road_f
        WHERE   road_f.road_id = ANY ($1);
        INSERT INTO tmp_ints (geom, z_elev)
        SELECT  ST_EndPoint(road_t.geom), road_t.z_to
        FROM    '||road_table_||' road_t
        WHERE   road_t.road_id = ANY ($1);'
    USING   road_ids;

    -- indexes
    EXECUTE '
        CREATE INDEX sidx_tmp_ints_geom ON tmp_ints USING GIST (geom);
        CREATE INDEX idx_tmp_ints_z_elev ON tmp_ints (z_elev);
        ANALYZE tmp_ints;';

    -- move to intersection table
    EXECUTE '
        INSERT INTO '||int_table_||' (geom, z_elev)
        SELECT DISTINCT geom, z_elev
        FROM tmp_ints
        WHERE NOT EXISTS (  SELECT  1
                            FROM    '||int_table_||' i
                            WHERE   tmp_ints.geom = i.geom
                            AND     tmp_ints.z_elev = i.z_elev)';

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgInsertIntersections(REGCLASS,REGCLASS,INTEGER[]) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgSetIntersectionLegs(
    int_table_ REGCLASS,
    road_table_ REGCLASS,
    int_ids_ INTEGER[] DEFAULT NULL)
RETURNS BOOLEAN AS $func$

DECLARE
    sql TEXT;

BEGIN
    RAISE NOTICE 'Setting intersection legs on %', int_table_;
    sql := '
        UPDATE  '||int_table_||'
        SET     legs = (SELECT  COUNT(roads.road_id)
                        FROM    '||road_table_||' roads
                        WHERE   '||int_table_||'.int_id = roads.intersection_from
                        OR      '||int_table_||'.int_id = roads.intersection_to)';

    IF int_ids_ IS NULL THEN
        EXECUTE sql;
    ELSE
        EXECUTE sql || ' WHERE int_id = ANY($1)'
        USING   int_ids_;
    END IF;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgSetIntersectionLegs(REGCLASS,REGCLASS,INTEGER[]) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdgUpdateNetwork (input_table REGCLASS, rowids INT[])
RETURNS BOOLEAN AS $func$

DECLARE

BEGIN

RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgUpdateNetwork(REGCLASS,INT[]) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgSetRoadIntersections(
    int_table_ REGCLASS,
    road_table_ REGCLASS,
    road_ids_ INTEGER[] DEFAULT NULL)
RETURNS BOOLEAN AS $func$

BEGIN
    --compile list of int_ids_ if needed
    IF road_ids_ IS NULL THEN
        EXECUTE '
            UPDATE  '||road_table_||'
            SET     intersection_from = ints.int_id
            FROM    '||int_table_||' ints
            WHERE   ints.geom = ST_StartPoint('||road_table_||'.geom)
            AND     ints.z_elev = '||road_table_||'.z_from;
            UPDATE  '||road_table_||'
            SET     intersection_to = ints.int_id
            FROM    '||int_table_||' ints
            WHERE   ints.geom = ST_EndPoint('||road_table_||'.geom)
            AND     ints.z_elev = '||road_table_||'.z_to;';
    ELSE
        EXECUTE '
            UPDATE  '||road_table_||'
            SET     intersection_from = ints.int_id
            FROM    '||int_table_||' ints
            WHERE   ints.geom = ST_StartPoint('||road_table_||'.geom)
            AND     ints.z_elev = '||road_table_||'.z_from
            AND     road_id = ANY ($1);
            UPDATE  '||road_table_||'
            SET     intersection_to = ints.int_id
            FROM    '||int_table_||' ints
            WHERE   ints.geom = ST_EndPoint('||road_table_||'.geom)
            AND     ints.z_elev = '||road_table_||'.z_to
            AND     road_id = ANY ($1);'
        USING   road_ids_;
    END IF;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgSetRoadIntersections(REGCLASS,REGCLASS,INTEGER[]) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdgColumnCheck (input_table REGCLASS, column_name TEXT)
RETURNS BOOLEAN AS $func$

BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_attribute
        WHERE  attrelid = input_table
        AND    attname = column_name
        AND    NOT attisdropped)
    THEN
        RETURN 't';
    END IF;
RETURN 'f';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgColumnCheck(REGCLASS, TEXT) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgMakeNetwork(road_table_ REGCLASS)
--need triggers to automatically update vertices and links
RETURNS BOOLEAN AS $func$

DECLARE
    schema_name TEXT;
    table_name TEXT;
    query TEXT;
    vert_table TEXT;
    link_table TEXT;
    turnrestrict_table TEXT;
    int_table REGCLASS;
    srid INT;

BEGIN
    RAISE NOTICE 'PROCESSING:';


    --check table and schema
    BEGIN
        RAISE NOTICE 'Getting table details for %',road_table_;
        EXECUTE '   SELECT  schema_name, table_name
                    FROM    tdgTableDetails($1::TEXT)'
        USING   road_table_
        INTO    schema_name, table_name;

        vert_table = schema_name || '.' || table_name || '_net_vert';
        link_table = schema_name || '.' || table_name || '_net_link';
        turnrestrict_table = schema_name || '.' || table_name || '_turn_restriction';
        int_table = schema_name || '.' || table_name || '_intersections';
    END;


    --get srid of the geom
    BEGIN
        RAISE NOTICE 'Getting SRID of geometry';
        EXECUTE 'SELECT tdgGetSRID($1,$2);'
        USING   road_table_,
                'geom'
        INTO    srid;

        IF srid IS NULL THEN
            RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', road_table_;
        END IF;
        raise NOTICE '  -----> SRID found %',srid;
    END;


    --drop old tables
    BEGIN
        RAISE NOTICE 'dropping any preexisting tables';
        EXECUTE '
            DROP TABLE IF EXISTS '||turnrestrict_table||';
            DROP TABLE IF EXISTS '||vert_table||';
            DROP TABLE IF EXISTS '||link_table||';';
    END;


    --create new tables
    BEGIN
        RAISE NOTICE 'creating vertices table';
        EXECUTE '
            CREATE TABLE '||vert_table||' (
                vert_id serial PRIMARY KEY,
                int_id INT,
                road_id INT,
                vert_cost INT,
                geom geometry(point,'||srid::TEXT||'));';

        RAISE NOTICE 'creating turn restrictions table';
        EXECUTE '
            CREATE TABLE '||turnrestrict_table||' (
                from_id integer NOT NULL,
                to_id integer NOT NULL,
                CONSTRAINT '||table_name||'_trn_rstrctn_check CHECK (from_id <> to_id));';

        RAISE NOTICE 'creating link table';
        EXECUTE '
            CREATE TABLE '||link_table||' (
                link_id SERIAL PRIMARY KEY,
                road_id INT,
                source_vert INT,
                target_vert INT,
                int_id INT,
                direction VARCHAR(2),
                movement TEXT,
                link_cost INT,
                link_stress INT,
                geom geometry(linestring,'||srid::TEXT||'));';
    END;


    -- create vertices
    EXECUTE '
        INSERT INTO '||vert_table||' (int_id,road_id,geom)
        SELECT  ints.int_id,
                road.road_id,
                (ST_Dump(ST_Intersection(ST_ExteriorRing(ST_Buffer(ints.geom,2)),road.geom))).geom
        FROM    '||int_table||' ints
        JOIN    '||road_table_||' road
                ON ints.int_id IN (road.intersection_from,road.intersection_to)
        WHERE   ints.legs > 2;';
    EXECUTE '
        INSERT INTO '||vert_table||' (int_id,geom)
        SELECT DISTINCT
            ints.int_id,
            ints.geom
        FROM    '||int_table||' ints
        JOIN    '||road_table_||' road
                ON ints.int_id IN (road.intersection_from,road.intersection_to)
        WHERE   ints.legs <= 2;';

    --vertex indices
    RAISE NOTICE 'Creating vertex indices';
    EXECUTE '
        CREATE INDEX sidx_'||table_name||'_vert_geom ON '||vert_table||'
            USING gist (geom);
        CREATE INDEX idx_'||table_name||'_vert_intid ON '||vert_table||'(int_id);
        CREATE INDEX idx_'||table_name||'_vert_roadid ON '||vert_table||'(road_id);';


    EXECUTE 'ANALYZE '||vert_table||';';

    ---------------
    -- add links --
    ---------------
    --ft self link
    EXECUTE '
        INSERT INTO '||link_table||' (
            road_id,
            direction,
            source_vert,
            target_vert,
            geom)
        SELECT  road.road_id,
                $1,
                vertsf.vert_id,
                vertst.vert_id,
                ST_Makeline(vertsf.geom,vertst.geom)
        FROM    '||road_table_||' road,
                '||vert_table||' vertsf,
                '||vert_table||' vertst
        WHERE   COALESCE(road.one_way,$1) = $1
        AND     COALESCE(vertsf.road_id,road.road_id) = road.road_id
        AND     vertsf.int_id = road.intersection_from
        AND     COALESCE(vertst.road_id,road.road_id) = road.road_id
        AND     vertst.int_id = road.intersection_to;'
    USING   'ft';

    --tf self link
    EXECUTE '
        INSERT INTO '||link_table||' (
            road_id,
            direction,
            source_vert,
            target_vert,
            geom)
        SELECT  road.road_id,
                $1,
                vertst.vert_id,
                vertsf.vert_id,
                ST_Makeline(vertst.geom,vertsf.geom)
        FROM    '||road_table_||' road,
                '||vert_table||' vertsf,
                '||vert_table||' vertst
        WHERE   COALESCE(road.one_way,$1) = $1
        AND     COALESCE(vertsf.road_id,road.road_id) = road.road_id
        AND     vertsf.int_id = road.intersection_from
        AND     COALESCE(vertst.road_id,road.road_id) = road.road_id
        AND     vertst.int_id = road.intersection_to;'
    USING   'tf';

    -- connector links
    EXECUTE '
        INSERT INTO '||link_table||' (
            geom,
            direction,
            int_id,
            source_vert,
            target_vert)
        SELECT  ST_Makeline(vert1.geom,vert2.geom),
                NULL,
                vert1.int_id,
                vert1.vert_id,
                vert2.vert_id
        FROM    '||vert_table||' vert1
        JOIN    '||vert_table||' vert2
                ON  vert1.vert_id != vert2.vert_id
                AND vert1.road_id != vert2.road_id
                AND vert1.int_id = vert2.int_id
        WHERE   vert1.road_id IS NOT NULL
        AND     vert2.road_id IS NOT NULL;';


    --set turn information intersection by intersections
    -- BEGIN
    --     EXECUTE format('
    --         SELECT tdgSetTurnInfo(%L,%L,%L,%L);
    --         ',  link_table,
    --             int_table,
    --             vert_table);
    -- END;


    --link indexes
    BEGIN
        RAISE NOTICE 'creating link indexes';
        EXECUTE '
            CREATE INDEX idx_'||table_name||'_link_road_id ON '||link_table||' (road_id);
            CREATE INDEX idx_'||table_name||'_link_direction ON '||link_table||' (direction);
            CREATE INDEX idx_'||table_name||'_link_src_trgt ON '||link_table||' (source_vert,target_vert);';
    END;

    BEGIN
        EXECUTE 'ANALYZE '||link_table||';';
        EXECUTE 'ANALYZE '||turnrestrict_table||';';
    END;
RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeNetwork(REGCLASS) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgMakeIntersectionTable (road_table_ REGCLASS)
RETURNS BOOLEAN AS $func$

DECLARE
    schema_name TEXT;
    table_name TEXT;
    int_table TEXT;
    srid INT;

BEGIN
    -- set table name and schema
    RAISE NOTICE 'Getting table details for %',road_table_;
    EXECUTE '   SELECT  schema_name, table_name
                FROM    tdgTableDetails($1::TEXT)'
    USING   road_table_
    INTO    schema_name, table_name;

    int_table = schema_name || '.' || table_name || '_intersections';

    -- get srid of the geom
    RAISE NOTICE 'Getting SRID of geometry';
    EXECUTE 'SELECT tdgGetSRID($1,$2);'
    USING   road_table_,
            'geom'
    INTO    srid;

    IF srid IS NULL THEN
        RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', table_name;
    END IF;
    raise NOTICE '  -----> SRID found %',srid;

    -- create the intersection table
    BEGIN
        RAISE NOTICE 'Creating table %', int_table;
        EXECUTE format('
            CREATE TABLE %s (   int_id serial PRIMARY KEY,
                                geom geometry(point,%L),
                                z_elev INT NOT NULL DEFAULT 0,
                                legs INT,
                                signalized BOOLEAN);
            ',  int_table,
                srid);
    END;

    RETURN 't';

END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeIntersectionTable(REGCLASS) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgMakeIntersectionIndexes (int_table_ REGCLASS)
RETURNS BOOLEAN AS $func$

DECLARE
    table_name TEXT;

BEGIN
    --get base table name
    EXECUTE 'SELECT table_name FROM tdgTableDetails($1);'
    USING   int_table_::TEXT
    INTO    table_name;

    --intersection indices
    RAISE NOTICE 'Creating indexes on %', int_table_;

    EXECUTE '
        CREATE INDEX sidx_'||table_name||'_geom
            ON '||int_table_||' USING gist(geom);';
    EXECUTE '
        CREATE INDEX idx_'||table_name||'_z_elev
            ON '||int_table_||' (z_elev);';

    EXECUTE 'ANALYZE '||int_table_;

    RETURN 't';

END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeIntersectionIndexes(REGCLASS) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgMakeIntersections (
    road_table_ REGCLASS,
    z_vals_ BOOLEAN DEFAULT 'f')
RETURNS BOOLEAN AS $func$

DECLARE
    namecheck RECORD;
    schema_name TEXT;
    table_name TEXT;
    int_table TEXT;
    srid INT;

BEGIN
    RAISE NOTICE 'PROCESSING:';

    --check table and schema
    BEGIN
        RAISE NOTICE 'Getting table details for %',road_table_;
        EXECUTE '   SELECT  schema_name, table_name
                    FROM    tdgTableDetails($1::TEXT)'
        USING   road_table_
        INTO    schema_name, table_name;

        int_table = schema_name || '.' || table_name || '_intersections';
    END;

    --get srid of the geom
    BEGIN
        RAISE NOTICE 'Getting SRID of geometry';
        EXECUTE 'SELECT tdgGetSRID($1,$2);'
        USING   road_table_,
                'geom'
        INTO    srid;

        IF srid IS NULL THEN
            RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', table_name;
        END IF;
        raise NOTICE '  -----> SRID found %',srid;
    END;

    BEGIN
        RAISE NOTICE 'Creating table %', int_table;
        EXECUTE format('
            CREATE TABLE %s (   int_id serial PRIMARY KEY,
                                geom geometry(point,%L),
                                z_elev INT NOT NULL DEFAULT 0,
                                legs INT,
                                signalized BOOLEAN);
            ',  int_table,
                srid);
    END;

    --add intersections to table
    BEGIN
        RAISE NOTICE 'Adding intersections';

        EXECUTE '
            CREATE TEMP TABLE tmp_v (i INT, z INT, geom geometry(POINT,'||srid::TEXT||'))
            ON COMMIT DROP;
            INSERT INTO tmp_v (i, z, geom)
                SELECT      road_id, z_from, ST_StartPoint(geom)
                FROM        ' || road_table_ || '
                ORDER BY    road_id ASC;
            INSERT INTO tmp_v (i, z, geom)
                SELECT      road_id, z_to, ST_EndPoint(geom)
                FROM        ' || road_table_ || '
                ORDER BY    road_id ASC;
            INSERT INTO ' || int_table || ' (legs, z_elev, geom)
                SELECT      COUNT(i), COALESCE(z,0), geom
                FROM        tmp_v
                GROUP BY    COALESCE(z,0), geom;';
    END;

    --intersection indices
    BEGIN
        EXECUTE '
            CREATE INDEX sidx_'||table_name||'_ints_geom
                ON '||int_table||' USING gist(geom);';
        EXECUTE '
            CREATE INDEX idx_'||table_name||'_ints_z_elev
                ON '||int_table||' (z_elev);';
    END;
    EXECUTE format('ANALYZE %s;', int_table);

    -- add intersection data to roads
    BEGIN
        RAISE NOTICE 'Populating intersection data in %', road_table_;
        EXECUTE '
            UPDATE  '||road_table_||'
            SET     intersection_from = if.int_id,
                    intersection_to = it.int_id
            FROM    '||int_table||' if,
                    '||int_table||' it
            WHERE   '||road_table_||'.geom <#> if.geom < 5
            AND     ST_StartPoint('||road_table_||'.geom) = if.geom
            AND     '||road_table_||'.z_from = if.z_elev
            AND     '||road_table_||'.geom <#> it.geom < 5
            AND     ST_EndPoint('||road_table_||'.geom) = it.geom
            AND     '||road_table_||'.z_to = it.z_elev;';
    END;

    --triggers to prevent changes
    EXECUTE 'SELECT tdgMakeIntersectionTriggers($1,$2);'
    USING   int_table,
            table_name;

    --triggers to update intersections when changes are made to roads
    EXECUTE 'SELECT tdgMakeRoadTriggers($1,$2);'
    USING   road_table_,
            table_name;

    --road intersection indexes
    BEGIN
        RAISE NOTICE 'Adding indices to %', road_table_;
        EXECUTE '
            CREATE INDEX idx_'||table_name||'_intfrom ON '||road_table_||' (intersection_from);
            CREATE INDEX idx_'||table_name||'_intto ON '||road_table_||' (intersection_to);';
    END;

    --not null on road intersections
    BEGIN
        RAISE NOTICE 'Setting column constraints on %', road_table_;
        EXECUTE '
            ALTER TABLE '||table_name||' ALTER COLUMN intersection_from SET NOT NULL;
            ALTER TABLE '||table_name||' ALTER COLUMN intersection_to SET NOT NULL;';
    END;

    RAISE NOTICE 'Analyzing';
    EXECUTE 'ANALYZE '||road_table_||';';
    EXECUTE 'ANALYZE '||int_table||';';

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeIntersections(REGCLASS,BOOLEAN) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdgGenerateIntersectionStreets (input_table REGCLASS, intids INT[])
RETURNS BOOLEAN AS $func$

DECLARE

BEGIN

RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgGenerateIntersectionStreets(REGCLASS, INT[]) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgMakeStandardizedRoadIndexes(road_table_ REGCLASS)
RETURNS BOOLEAN AS $func$

DECLARE
    table_name TEXT;

BEGIN
    EXECUTE 'SELECT table_name FROM tdgTableDetails($1);'
    USING   road_table_::TEXT
    INTO    table_name;

    raise notice 'Creating indices on: %', road_table_;

    EXECUTE format('
        CREATE INDEX sidx_%s_geom ON %s USING GIST(geom);
        CREATE INDEX idx_%s_oneway ON %s (one_way);
        CREATE INDEX idx_%s_sourceid ON %s (source_id);
        CREATE INDEX idx_%s_funcclass ON %s (functional_class);
        CREATE INDEX idx_%s_zf ON %s (z_from);
        CREATE INDEX idx_%s_zt ON %s (z_to);
        ',  table_name,
            road_table_,
            table_name,
            road_table_,
            table_name,
            road_table_,
            table_name,
            road_table_,
            table_name,
            road_table_,
            table_name,
            road_table_);

    EXECUTE '
        CREATE INDEX idx_'||table_name||'_intfrom ON '||road_table_||' (intersection_from);
        CREATE INDEX idx_'||table_name||'_intto ON '||road_table_||' (intersection_to);';

    EXECUTE format('ANALYZE %s;',road_table_);

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeStandardizedRoadIndexes(REGCLASS) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgInsertStandardizedRoad(
    input_table_ REGCLASS,
    road_table_ REGCLASS,
    id_field_ TEXT,
    name_field_ TEXT,
    z_from_field_ TEXT,
    z_to_field_ TEXT,
    adt_field_ TEXT,
    speed_field_ TEXT,
    func_field_ TEXT,
    oneway_field_ TEXT,
    input_ids_ INTEGER[] DEFAULT NULL)
RETURNS BOOLEAN AS $func$

DECLARE
    id_column TEXT;
    table_name TEXT;
    road_table TEXT;
    querytext TEXT;
    bad_one_way_id INT;
BEGIN
    -- get column name of primary key
    EXECUTE '
        SELECT a.attname
        FROM   pg_index i
        JOIN   pg_attribute a ON a.attrelid = i.indrelid
                             AND a.attnum = ANY(i.indkey)
        WHERE  i.indrelid = $1
        AND    i.indisprimary;'
    USING   input_table_
    INTO    id_column;

    --copy features over
    BEGIN
        RAISE NOTICE 'Copying features to %', road_table_;
        --querytext := '';
        querytext := '   INSERT INTO ' || road_table_ || ' (geom';
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
        querytext := querytext || ' FROM ' ||input_table_|| ' r ';

        IF input_ids_ IS NULL THEN
            EXECUTE querytext;
        ELSE
            EXECUTE querytext || '
                WHERE r.'||id_column||' = ANY ('||quote_literal(input_ids_::TEXT)||')';
        END IF;

    EXCEPTION
        WHEN check_violation THEN
            EXECUTE '
                SELECT  '||id_column||'
                FROM    '||input_table_||'
                WHERE   '||quote_ident(oneway_field_)||' IS NOT NULL
                AND     '||quote_ident(oneway_field_)||' NOT IN ($1,$2)
                LIMIT   1'
            INTO    bad_one_way_id
            USING   'ft',
                    'tf';
            RAISE EXCEPTION 'Bad one_way value on feature id %', bad_one_way_id
            USING HINT = 'Value must be "ft" or "tf"';
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgInsertStandardizedRoad(
    REGCLASS,REGCLASS,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,
    TEXT,TEXT,INTEGER[]) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgGetSRID(input_table REGCLASS,geom_name TEXT)
RETURNS INT AS $func$

DECLARE
    geomdetails RECORD;

BEGIN
    EXECUTE '
        SELECT  ST_SRID('|| geom_name || ') AS srid
        FROM    ' || input_table || '
        WHERE   $1 IS NOT NULL LIMIT 1'
    USING   --geom_name,
            --input_table,
            geom_name
    INTO    geomdetails;

    RETURN geomdetails.srid;
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgGetSRID(REGCLASS,TEXT) OWNER TO gis;
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
CREATE OR REPLACE FUNCTION tdg.tdgShortestPathMatrix (
    road_table_ REGCLASS,
    from_to_pairs_ INTEGER[],
    schema_name_ TEXT,
    table_name_ TEXT,
    overwrite_ BOOLEAN,
    append_ BOOLEAN,
    map_ BOOLEAN,
    stress_ INTEGER DEFAULT NULL)
RETURNS BOOLEAN AS $func$

DECLARE
    int_table REGCLASS;
    link_table REGCLASS;
    vert_table REGCLASS;
    output_table TEXT;
    namecheck TEXT;
    srid INT;

BEGIN
    -- get network tables
    BEGIN
        int_table := road_table_ || '_intersections';
        link_table := road_table_ || '_net_link';
        vert_table := road_table_ || '_net_vert';
    EXCEPTION
        WHEN undefined_table THEN
        RAISE EXCEPTION 'Table % is not a networked road layer', road_table_
        USING HINT = 'A networked road layer has
            accompanying intersection, link, and vertex tables.';
    END;

    -- combine table and schema
    EXECUTE 'CREATE SCHEMA IF NOT EXISTS '||schema_name_||';';
    output_table := schema_name_ || '.' || table_name_;

    -- delete old table
    IF overwrite_ THEN
        EXECUTE 'DROP TABLE IF EXISTS '||table_name_||';';
    END IF;

    IF append_ THEN
        RAISE NOTICE 'Checking whether table % exists',output_table;
        EXECUTE '   SELECT  table_name
                    FROM    tdgTableDetails($1)'
        USING   output_table
        INTO    namecheck;

        IF namecheck IS NULL THEN
            RAISE EXCEPTION 'Table % does not exist. Cannot append data.', output_table;
        END IF;

        -- drop indexes
        EXECUTE '
            DROP INDEX IF EXISTS sidx_'||table_name_||'_geom;
            DROP INDEX IF EXISTS idx_'||table_name_||'_pathid;
            DROP INDEX IF EXISTS idx_'||table_name_||'_seq;
            DROP INDEX IF EXISTS idx_'||table_name_||'_link;
            DROP INDEX IF EXISTS idx_'||table_name_||'_road;
            DROP INDEX IF EXISTS idx_'||table_name_||'_vert;
            DROP INDEX IF EXISTS idx_'||table_name_||'_int;
        ';
    ELSE        --create table
        EXECUTE 'CREATE TABLE '||output_table||' (
            id SERIAL PRIMARY KEY,
            path_id INT,
            from_vert INT,
            to_vert INT,
            move_sequence INT,
            link_id INT,
            vert_id INT,
            road_id INT,
            int_id INT,
            move_cost INT,
            cumulative_cost INT
        );';
    END IF;

    RAISE NOTICE 'Getting shortest paths';
    EXECUTE '
        INSERT INTO '||output_table||' (
            path_id,
            from_vert,
            to_vert,
            move_sequence,
            link_id,
            vert_id,
            road_id,
            int_id,
            move_cost,
            cumulative_cost
        )
        SELECT * FROM tdg.tdgShortestPathVerts($1,$2,$3,$4);'
    USING   link_table,
            vert_table,
            from_to_pairs_,
            stress_;

    -- get geoms if map_
    IF map_ THEN
        RAISE NOTICE 'Adding geometry data';
        -- get srid
        RAISE NOTICE 'Getting SRID of geometry';
        EXECUTE 'SELECT tdgGetSRID($1,$2);'
        USING   road_table_,
                'geom'
        INTO    srid;

        -- add geom column if not append_
        IF NOT append_ THEN
            EXECUTE '
                ALTER TABLE '||output_table||'
                ADD COLUMN geom geometry(linestring,'||srid::TEXT||');';
        END IF;

        -- update
        EXECUTE '
            UPDATE '||output_table||'
            SET     geom = roads.geom
            FROM    '||road_table_||' roads
            WHERE   roads.road_id = '||output_table||'.road_id;';

        -- spatial index
        EXECUTE '
            CREATE INDEX sidx_'||table_name_||'_geom
            ON '||output_table||' USING GIST (geom);';
    END IF;

    -- other indexes
    RAISE NOTICE 'Creating indexes';
    EXECUTE '
        CREATE INDEX idx_'||table_name_||'_pathid ON '||output_table||' (path_id);
        CREATE INDEX idx_'||table_name_||'_seq ON '||output_table||' (move_sequence);
        CREATE INDEX idx_'||table_name_||'_link ON '||output_table||' (link_id);
        CREATE INDEX idx_'||table_name_||'_road ON '||output_table||' (road_id);
        CREATE INDEX idx_'||table_name_||'_vert ON '||output_table||' (vert_id);
        CREATE INDEX idx_'||table_name_||'_int ON '||output_table||' (int_id);
    ';

    -- analyze
    EXECUTE 'ANALYZE '||output_table||';';

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgShortestPathMatrix(REGCLASS,INTEGER[],TEXT,TEXT,
    BOOLEAN,BOOLEAN,BOOLEAN,INTEGER) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgTableDetails(input_table_ TEXT)
RETURNS TABLE (schema_name TEXT, table_name TEXT) AS $func$

BEGIN
    RETURN QUERY EXECUTE '
        SELECT  nspname::TEXT, relname::TEXT
        FROM    pg_namespace n JOIN pg_class c ON n.oid = c.relnamespace
        WHERE   c.oid = ' || quote_literal(input_table_) || '::REGCLASS';

EXCEPTION
    WHEN undefined_table THEN
        RETURN;
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgTableDetails(TEXT) OWNER TO gis;




-- CREATE OR REPLACE FUNCTION tdgTableDetails(input_table_ TEXT)
-- RETURNS TABLE (schema_name TEXT, table_name TEXT) AS $func$
--
-- BEGIN
--     RETURN QUERY EXECUTE '
--         SELECT  nspname::TEXT, relname::TEXT
--         FROM    pg_namespace n JOIN pg_class c ON n.oid = c.relnamespace
--         WHERE   c.oid = to_regclass(' || quote_literal(input_table_) || ')';
-- END $func$ LANGUAGE plpgsql;
-- ALTER FUNCTION tdgTableDetails(TEXT) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgMakeIntersectionTriggers(
    int_table_ REGCLASS,
    table_name_ TEXT)
RETURNS BOOLEAN AS $func$

BEGIN
    RAISE NOTICE 'Creating triggers on %', int_table_;

    --prevent updates/changes
    EXECUTE format('
        CREATE TRIGGER tdg%sGeomPreventUpdate
            BEFORE UPDATE OF geom ON %s
            FOR EACH ROW
            EXECUTE PROCEDURE tdgTriggerDoNothing();
        ',  table_name_ || '_ints',
            int_table_);
    EXECUTE format('
        CREATE TRIGGER tdg%sPreventInsDel
            BEFORE INSERT OR DELETE ON %s
            FOR EACH ROW
            EXECUTE PROCEDURE tdgTriggerDoNothing();
        ',  table_name_ || '_ints',
            int_table_);

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeIntersectionTriggers(REGCLASS,TEXT) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgRoadGeomChangeVals ()
RETURNS TRIGGER
AS $BODY$

--------------------------------------------------------------------------
-- This function is called automatically anytime a change is made to the
-- geometry or intersection z value of a record in a TDG-standardized
-- road layer. It snaps the new geometry to a 2-ft grid and then updates
-- the intersection information. The geometry matches an existing
-- intersection if it is within 5 ft of another intersection.
--
-- N.B. If the end of a cul-de-sac is moved, the old intersection point
-- is deleted and a new one is created. This should be an edge case
-- and wouldn't cause any problems anyway. A fix to move the intersection
-- point rather than create a new one would complicate the code and the
-- current behavior isn't really problematic.
--------------------------------------------------------------------------

DECLARE
    road_table REGCLASS;
    int_table REGCLASS;
    i INTEGER;

BEGIN
    --get the intersection and road tables
    road_table := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME;
    int_table := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME || '_intersections';

    --popoulate change tables
    IF TG_OP = 'UPDATE' THEN
        NEW.geom := ST_SnapToGrid(NEW.geom,2);

        INSERT INTO tmp_roadgeomchange (road_id)
        VALUES (OLD.road_id);
    ELSEIF TG_OP = 'INSERT' THEN
        NEW.geom := ST_SnapToGrid(NEW.geom,2);

        INSERT INTO tmp_roadgeomchange (road_id)
        VALUES (NEW.road_id);
    ELSEIF TG_OP = 'DELETE' THEN
        INSERT INTO tmp_roadgeomchange (road_id)
        VALUES (OLD.road_id);
        RETURN OLD;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgRoadGeomChangeVals() OWNER TO gis;
CREATE OR REPLACE FUNCTION tdgTriggerDoNothing ()
RETURNS TRIGGER
AS $BODY$

--------------------------------------------------------------------------
-- This function is prevents a change from being committed.
--------------------------------------------------------------------------

BEGIN
    RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdgTriggerDoNothing() OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgRoadGeomUpdate ()
RETURNS TRIGGER
AS $BODY$

--------------------------------------------------------------------------
-- This function is called automatically anytime a change is made to the
-- geometry or intersection z value of a record in a TDG-standardized
-- road layer. It creates an array of changed road_ids and then calls
-- tdgUpdateIntersections() to make updates.
--------------------------------------------------------------------------

DECLARE
    road_table REGCLASS;
    int_table REGCLASS;
    road_ids INTEGER[];
    int_ids INTEGER[];

BEGIN
    -- get the intersection and road tables
    road_table := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME;
    int_table := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME || '_intersections';

    -- gather affected road_ids into an array
    EXECUTE 'SELECT array_agg(road_id) FROM tmp_roadgeomchange'
    INTO    road_ids;

    --suspend triggers on the intersections table so that our
    --changes are not ignored.
    EXECUTE 'ALTER TABLE ' || int_table || ' DISABLE TRIGGER ALL;';

    -- update intersection and road data on affected road_ids
    PERFORM tdgInsertIntersections(int_table,road_table,road_ids);
    PERFORM tdgSetRoadIntersections(int_table,road_table,road_ids);

    --EXECUTE 'ANALYZE ' || road_table;
    --EXECUTE 'ANALYZE ' || int_table;

    -- gather intersections into an array
    EXECUTE '
        SELECT  array_agg(int_id)
        FROM    '||int_table||'
        WHERE EXISTS (  SELECT  1
                        FROM    '||road_table||' roads
                        WHERE   road_id = ANY ($1)
                        AND     ('||int_table||'.int_id = roads.intersection_from
                                OR '||int_table||'.int_id = roads.intersection_to));'
    USING   road_ids
    INTO    int_ids;

    -- update legs on intersections
    PERFORM tdgSetIntersectionLegs(int_table,road_table,int_ids);

    -- remove obsolete intersections
    EXECUTE '
        DELETE FROM '||int_table||'
        WHERE NOT EXISTS (  SELECT  1
                            FROM    '||road_table||' roads
                            WHERE   '||int_table||'.int_id = roads.intersection_from
                            OR      '||int_table||'.int_id = roads.intersection_to);';

    --re-enable triggers on the intersections table
    EXECUTE 'ALTER TABLE ' || int_table || ' ENABLE TRIGGER ALL;';

    DROP TABLE tmp_roadgeomchange;

    RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgRoadGeomUpdate() OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgMakeRoadTriggers(
    road_table_ REGCLASS,
    table_name_ TEXT)
RETURNS BOOLEAN AS $func$

BEGIN
    RAISE NOTICE 'Creating triggers on %', road_table_;

    --------------------
    --road geom changes
    --------------------
    -- create temp table
    EXECUTE '
        CREATE TRIGGER tr_tdg'||table_name_||'GeomUpdateTable
            BEFORE UPDATE OF geom, z_from, z_to ON '||road_table_||'
            FOR EACH STATEMENT
            EXECUTE PROCEDURE tdgRoadGeomChangeTable();';
    -- populate with vals
    EXECUTE '
        CREATE TRIGGER tr_tdg'||table_name_||'GeomUpdateVals
            BEFORE UPDATE OF geom, z_from, z_to ON '||road_table_||'
            FOR EACH ROW
            EXECUTE PROCEDURE tdgRoadGeomChangeVals();';
    -- update intersections
    EXECUTE '
        CREATE TRIGGER tr_tdg'||table_name_||'GeomUpdateIntersections
            AFTER UPDATE OF geom, z_from, z_to ON '||road_table_||'
            FOR EACH STATEMENT
            EXECUTE PROCEDURE tdgRoadGeomUpdate();';


    --------------------
    --road insert/delete
    --------------------
    -- create temp table
    EXECUTE '
        CREATE TRIGGER tr_tdg'||table_name_||'GeomAddDelTable
            BEFORE INSERT OR DELETE ON '||road_table_||'
            FOR EACH STATEMENT
            EXECUTE PROCEDURE tdgRoadGeomChangeTable();';
    -- populate with vals
    EXECUTE '
        CREATE TRIGGER tr_tdg'||table_name_||'GeomAddDelVals
            BEFORE INSERT OR DELETE ON '||road_table_||'
            FOR EACH ROW
            EXECUTE PROCEDURE tdgRoadGeomChangeVals();';
    -- update intersections
    EXECUTE '
        CREATE TRIGGER tr_tdg'||table_name_||'GeomAddDelIntersections
            AFTER INSERT OR DELETE ON '||road_table_||'
            FOR EACH STATEMENT
            EXECUTE PROCEDURE tdgRoadGeomUpdate();';

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeRoadTriggers(REGCLASS,TEXT) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgRoadGeomChangeTable ()
RETURNS TRIGGER
AS $BODY$

--------------------------------------------------------------------------
-- This function is called automatically anytime a change is made to the
-- geometry or intersection z value of a record in a TDG-standardized
-- road layer. It creates a temporary table to track the rows in the road
-- layer that have changed.
--------------------------------------------------------------------------

BEGIN
    EXECUTE '
        CREATE TEMPORARY TABLE tmp_roadgeomchange (road_id INTEGER)
        ON COMMIT DROP;';

    RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgRoadGeomChangeTable() OWNER TO gis;
