CREATE TABLE stress_seg_mixed (
    speed integer,
    adt integer,
    lanes integer,
    stress integer
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
CREATE TABLE stress_seg_bike_w_park (
    speed integer,
    bike_park_lane_wd_ft integer,
    lanes integer,
    stress integer
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
CREATE TABLE stress_cross_w_median (
    speed integer,
    lanes integer,
    stress integer
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
CREATE TABLE stress_seg_bike_no_park (
    speed integer,
    bike_lane_wd_ft integer,
    lanes integer,
    stress integer
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
CREATE TABLE stress_cross_no_median (
    speed integer,
    lanes integer,
    stress integer
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
CREATE OR REPLACE FUNCTION tdgGenerateCrossStreetData(input_table REGCLASS)
--populate cross-street data
RETURNS BOOLEAN AS $func$

DECLARE
    tablecheck TEXT;
    namecheck record;
    tablevert TEXT;

BEGIN
    raise notice 'PROCESSING:';

    --get schema
    BEGIN
        --net link
        RAISE NOTICE 'Checking % is network layer',input_table;
        tablecheck := '';
        tablecheck := input_table || '_net_link';
        RAISE NOTICE 'Checking for %',tablecheck;
        EXECUTE '   SELECT  schema_name,
                            table_name
                    FROM    tdgTableDetails('||quote_literal(tablecheck)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
        IF namecheck.schema_name IS NULL OR namecheck.table_name IS NULL THEN
            RAISE NOTICE '-------> % not found',tablecheck;
            RETURN 'f';
        ELSE
            RAISE NOTICE '  -----> OK';
        END IF;

        --net vert
        tablecheck := '';
        namecheck := NULL;
        tablecheck := input_table || '_net_vert';
        RAISE NOTICE 'Checking for %',tablecheck;
        EXECUTE '   SELECT  schema_name,
                            table_name
                    FROM    tdgTableDetails('||quote_literal(tablecheck)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
        IF namecheck.schema_name IS NULL OR namecheck.table_name IS NULL THEN
            RAISE NOTICE '-------> % not found',tablecheck;
            RETURN 'f';
        ELSE
            tablevert := namecheck.schema_name||'.'||namecheck.table_name;
            RAISE NOTICE '  -----> OK';
        END IF;

        --turn restriction
        tablecheck := '';
        namecheck := NULL;
        tablecheck := input_table || '_turn_restriction';
        RAISE NOTICE 'Checking for %',tablecheck;
        EXECUTE '   SELECT  schema_name,
                            table_name
                    FROM    tdgTableDetails('||quote_literal(tablecheck)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
        IF namecheck.schema_name IS NULL OR namecheck.table_name IS NULL THEN
            RAISE NOTICE '-------> % not found',tablecheck;
            RETURN 'f';
        ELSE
            RAISE NOTICE '  -----> OK';
        END IF;


    END;

    BEGIN
        RAISE NOTICE 'Clearing old values';
        EXECUTE format('
            UPDATE  %s
            SET     road_from = NULL,
                    road_to = NULL;
            ',  input_table);
    END;

    BEGIN
        --ignore culs-de-sac (order 1)
        --get road names of no intersection (order 2)
        --from streets
        RAISE NOTICE 'Assigning from streets, node order 2';
        EXECUTE format('
            UPDATE  %s
            SET     road_from = r.road_name
            FROM    %s v,
                    %s r
            WHERE   v.node_order = 2
            AND     %s.source = v.id
            AND     v.id IN (r.source,r.target)
            AND     %s.id != r.id;
            ',  input_table,
                tablevert,
                input_table,
                input_table,
                input_table);
        --to streets
        RAISE NOTICE 'Assigning to streets, node order 2';
        EXECUTE format('
            UPDATE  %s
            SET     road_to = r.road_name
            FROM    %s v,
                    %s r
            WHERE   v.node_order = 2
            AND     %s.target = v.id
            AND     v.id IN (r.source,r.target)
            AND     %s.id != r.id;
            ',  input_table,
                tablevert,
                input_table,
                input_table,
                input_table);

        --get road name of leg nearest to 90 degrees
        --from streets
        RAISE NOTICE 'Assigning from streets, node order >2';
        EXECUTE format('
            WITH    x1 AS ( SELECT  a.id AS this_id,
                                    b.id AS xing_id,
                                    b.road_name AS xing_name,
                                    ST_Intersection(ST_Buffer(v.geom,10),a.geom) AS this_geom,
                                    ST_Intersection(ST_Buffer(v.geom,10),b.geom) AS xing_geom
                            FROM    %s a,
                                    %s v,
                                    %s b
                            WHERE   a.source = v.id
                            AND     v.node_order > 2
                            AND     v.id IN (b.source,b.target)
                            AND     a.id != b.id),
                    x2 AS ( SELECT  this_id,
                                    xing_id,
                                    xing_name,
                                    degrees(ST_Azimuth(ST_StartPoint(this_geom),ST_EndPoint(this_geom)))::numeric AS this_azi,
                                    degrees(ST_Azimuth(ST_StartPoint(xing_geom),ST_EndPoint(xing_geom)))::numeric AS xing_azi
                            FROM    x1)
            UPDATE  %s
            SET     road_from =(SELECT      x2.xing_name
                                FROM        x2
                                WHERE       %s.id = x2.this_id
                                ORDER BY    ABS(90 - (mod(mod(360 + x2.xing_azi - x2.this_azi, 360), 180) )) ASC
                                LIMIT       1)
            FROM    %s v
            WHERE   source = v.id
            AND     v.node_order > 2;
            ',  input_table,
                tablevert,
                input_table,
                input_table,
                input_table,
                tablevert);
        --to streets
        EXECUTE format('
            WITH    x1 AS ( SELECT  a.id AS this_id,
                                    b.id AS xing_id,
                                    b.road_name AS xing_name,
                                    ST_Intersection(ST_Buffer(v.geom,10),a.geom) AS this_geom,
                                    ST_Intersection(ST_Buffer(v.geom,10),b.geom) AS xing_geom
                            FROM    %s a,
                                    %s v,
                                    %s b
                            WHERE   a.target = v.id
                            AND     v.node_order > 2
                            AND     v.id IN (b.source,b.target)
                            AND     a.id != b.id),
                    x2 AS ( SELECT  this_id,
                                    xing_id,
                                    xing_name,
                                    degrees(ST_Azimuth(ST_StartPoint(this_geom),ST_EndPoint(this_geom)))::numeric AS this_azi,
                                    degrees(ST_Azimuth(ST_StartPoint(xing_geom),ST_EndPoint(xing_geom)))::numeric AS xing_azi
                            FROM    x1)
            UPDATE  %s
            SET     road_to =(  SELECT      x2.xing_name
                                FROM        x2
                                WHERE       %s.id = x2.this_id
                                ORDER BY    ABS(90 - (mod(mod(360 + x2.xing_azi - x2.this_azi, 360), 180) )) ASC
                                LIMIT       1)
            FROM    %s v
            WHERE   target = v.id
            AND     v.node_order > 2;
            ',  input_table,
                tablevert,
                input_table,
                input_table,
                input_table,
                tablevert);
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION tdgMakeNetwork(input_table REGCLASS)
--need triggers to automatically update vertices and links
RETURNS BOOLEAN AS $func$

DECLARE
    schema_name text;
    table_name text;
    namecheck record;
    query text;
    sourcetable text;
    verttable text;
    linktable text;
    turnrestricttable text;
    sridinfo record;
    srid int;
    indexcheck TEXT;

BEGIN
    RAISE NOTICE 'PROCESSING:';

    --check table and schema
    --need to redo without reliance on pgrouting
    BEGIN
        RAISE NOTICE 'Checking % exists',input_table;
        EXECUTE '   SELECT  schema_name,
                            table_name
                    FROM    tdgTableDetails('||quote_literal(input_table)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
        schema_name=namecheck.schema_name;
        table_name=namecheck.table_name;
        IF schema_name IS NULL OR table_name IS NULL THEN
    	RAISE NOTICE '-------> % not found',input_table;
            RETURN 'f';
        ELSE
    	RAISE NOTICE '  -----> OK';
        END IF;

        sourcetable = schema_name || '.' || table_name;
        verttable = schema_name || '.' || table_name || '_net_vert';
        linktable = schema_name || '.' || table_name || '_net_link';
        turnrestricttable = schema_name || '.' || table_name || '_turn_restriction';
    END;

    --snap geom to grid to nearest 2 ft
    BEGIN
        RAISE NOTICE 'snapping road geometries';
        EXECUTE format('
            UPDATE  %s
            SET     geom = ST_SnapToGrid(geom,2);
            ',  sourcetable);
    END;

    --check for from/to/cost columns
    BEGIN
        RAISE NOTICE 'checking for source/target columns';
        IF EXISTS (
            SELECT 1 FROM pg_attribute
            WHERE  attrelid = table_name::regclass
            AND    attname = 'source'
            AND    NOT attisdropped)
        THEN
            EXECUTE format('
                UPDATE %s SET source=NULL;
                ',  sourcetable);
        ELSE
            EXECUTE format('
                ALTER TABLE %s ADD COLUMN source INT;
                ',  sourcetable);
        END IF;
        IF EXISTS (
            SELECT 1 FROM pg_attribute
            WHERE  attrelid = table_name::regclass
            AND    attname = 'target'
            AND    NOT attisdropped)
        THEN
            EXECUTE format('
                UPDATE %s SET target=NULL;
                ',  sourcetable);
        ELSE
            EXECUTE format('
                ALTER TABLE %s ADD COLUMN target INT;
                ',  sourcetable);
        END IF;
        IF NOT EXISTS (
            SELECT 1 FROM pg_attribute
            WHERE  attrelid = table_name::regclass
            AND    attname = 'cost'
            AND    NOT attisdropped)
        THEN
            EXECUTE format('
                ALTER TABLE %s ADD COLUMN cost INT;
                ',  sourcetable);
        END IF;
    END;

    --get srid of the geom
    BEGIN
        EXECUTE format('SELECT tdgGetSRID(to_regclass(%L),%s)',input_table,quote_literal('geom')) INTO srid;

        IF srid IS NULL THEN
            RAISE NOTICE 'ERROR: Can not determine the srid of the geometry in table %', t_name;
            RETURN 'f';
        END IF;
        RAISE NOTICE '  -----> SRID found %',srid;
    END;

    --drop old tables
    BEGIN
        RAISE NOTICE 'dropping tables';
        EXECUTE format('
            DROP TABLE IF EXISTS %s;
            DROP TABLE IF EXISTS %s;
            DROP TABLE IF EXISTS %s;
            ',  turnrestricttable,
                verttable,
                linktable);
    END;

    --create new tables
    BEGIN
        RAISE NOTICE 'creating new tables';
        EXECUTE format('
            CREATE TABLE %s (   id serial PRIMARY KEY,
                                node_id TEXT,
                                node_order INT,
                                cost INT,
                                geom geometry(point,%L));
            ',  verttable,
                srid);

        EXECUTE format('
            CREATE TABLE %s (   from_id integer NOT NULL,
                                to_id integer NOT NULL,
                                CONSTRAINT %I CHECK (from_id <> to_id));
            ',  turnrestricttable,
                turnrestricttable || '_trn_rstrctn_check');

        EXECUTE format('
            CREATE TABLE %s (   id serial primary key,
                                road_id INT,
                                direction VARCHAR(2),
                                cost INT,
                                stress INT,
                                geom geometry(linestring,%L));
            ',  linktable,
                srid);
    END;

    --indexes
    BEGIN
        RAISE NOTICE 'creating indexes';
        EXECUTE format('
            CREATE INDEX %s ON %s USING gist (geom);
            CREATE INDEX %s ON %s (road_id);
            CREATE INDEX %s ON %s (direction);
            ',  'sidx_' || table_name || 'vert_geom',
                verttable,
                'idx_' || table_name || '_link_road_id',
                linktable,
                'idx_' || table_name || '_link_direction',
                linktable);
        EXECUTE format('SELECT to_regclass(%L)', quote_literal(schema_name||'.idx_'||table_name||'_srctrgt')) INTO indexcheck;
        IF indexcheck IS NOT NULL THEN
            EXECUTE format('
                CREATE INDEX %s ON %s (source,target);
                ',  'idx_' || table_name || '_srctrgt',
                    sourcetable);
        END IF;
    END;

    --insert points into vertices table
    BEGIN
        RAISE NOTICE 'adding points to vertices table';
        EXECUTE format('
            CREATE TEMP TABLE v (i INT, geom geometry(point,%L)) ON COMMIT DROP;
            INSERT INTO v (i, geom) SELECT id, ST_StartPoint(geom) FROM %s ORDER BY id ASC;
            INSERT INTO v (i, geom) SELECT id, ST_EndPoint(geom) FROM %s ORDER BY id ASC;
            INSERT INTO %s (node_id, node_order, geom)
            SELECT      string_agg(i::TEXT, %L),
                        COUNT(i),
                        geom
            FROM        v
            GROUP BY    geom;
            ',  srid,
                sourcetable,
                sourcetable,
                verttable,
                ' | ');
    END;

    --get source/target info
    BEGIN
        RAISE NOTICE 'getting source/target info';
        EXECUTE format('
            UPDATE  %s
            SET     source = vf.id,
                    target = vt.id
            FROM    %s vf,
                    %s vt
            WHERE   ST_StartPoint(%I.geom) = vf.geom
            AND     ST_EndPoint(%I.geom) = vt.geom
            ',  sourcetable,
                verttable,
                verttable,
                table_name,
                table_name);
    END;

    --populate links table
    BEGIN
        RAISE NOTICE 'adding links';
        EXECUTE format('
            CREATE TEMP TABLE lengths ( id SERIAL PRIMARY KEY,
                                        len FLOAT,
                                        f_point geometry(point, %L),
                                        t_point geometry(point, %L))
            ON COMMIT DROP;
            ',  srid,
                srid);

        EXECUTE format('
            INSERT INTO lengths (id, len, f_point, t_point)
            SELECT  s.id,
                    ST_Length(s.geom) AS len,
                    CASE    WHEN vf.node_order > 2
                            THEN ST_LineInterpolatePoint(s.geom,LEAST(0.5*ST_Length(s.geom)-5,50.0)/ST_Length(s.geom))
                            ELSE ST_StartPoint(s.geom)
                            END AS f_point,
                    CASE    WHEN vt.node_order > 2
                            THEN ST_LineInterpolatePoint(s.geom,GREATEST(0.5*ST_Length(s.geom)+5,ST_Length(s.geom)-50)/ST_Length(s.geom))
                            ELSE ST_EndPoint(s.geom)
                            END AS t_point
            FROM    %s s,
                    %s vf,
                    %s vt
            WHERE   s.source = vf.id
            AND     s.target = vt.id;
            ',  sourcetable,
                verttable,
                verttable);

        --self segment ft
        EXECUTE format('
            INSERT INTO %s (geom,
                            direction,
                            road_id,
                            cost)
            SELECT  ST_Makeline(l.f_point,l.t_point),
                    %L,
                    r.id,
                    r.cost
            FROM    %s r,
                    lengths l
            WHERE   r.id=l.id
            AND     (r.one_way IS NULL OR r.one_way = %L);
            ',  linktable,
                'ft',
                sourcetable,
                'ft');

        --self segment tf
        EXECUTE format('
            INSERT INTO %s (geom,
                            direction,
                            road_id,
                            cost)
            SELECT  ST_Makeline(l.t_point,l.f_point),
                    %L,
                    r.id,
                    r.cost
            FROM    %s r,
                    lengths l
            WHERE   r.id=l.id
            AND     (r.one_way IS NULL OR r.one_way = %L);
            ',  linktable,
                'tf',
                sourcetable,
                'tf');

        --from end to start
        EXECUTE format('
            INSERT INTO %s (geom)
            SELECT  ST_Makeline(fl.t_point,tl.f_point)
            FROM    %s f,
                    %s t,
                    lengths fl,
                    lengths tl
            WHERE   f.id != t.id
            AND     f.target = t.source
            AND     f.id = fl.id
            AND     t.id = tl.id
            AND     (f.one_way IS NULL OR f.one_way = %L)
            AND     (t.one_way IS NULL OR t.one_way = %L);
            ',  linktable,
                sourcetable,
                sourcetable,
                'ft',
                'ft');

        --from end to end
        EXECUTE format('
            INSERT INTO %s (geom)
            SELECT  ST_Makeline(fl.t_point,tl.t_point)
            FROM    %s f,
                    %s t,
                    lengths fl,
                    lengths tl
            WHERE   f.id != t.id
            AND     f.target = t.target
            AND     f.id = fl.id
            AND     t.id = tl.id
            AND     (f.one_way IS NULL OR f.one_way = %L)
            AND     (t.one_way IS NULL OR t.one_way = %L);
            ',  linktable,
                sourcetable,
                sourcetable,
                'ft',
                'tf');

        --from start to end
        EXECUTE format('
            INSERT INTO %s (geom)
            SELECT  ST_Makeline(fl.f_point,tl.t_point)
            FROM    %s f,
                    %s t,
                    lengths fl,
                    lengths tl
            WHERE   f.id != t.id
            AND     f.source = t.target
            AND     f.id = fl.id
            AND     t.id = tl.id
            AND     (f.one_way IS NULL OR f.one_way = %L)
            AND     (t.one_way IS NULL OR t.one_way = %L);
            ',  linktable,
                sourcetable,
                sourcetable,
                'tf',
                'tf');

        --from start to start
        EXECUTE format('
            INSERT INTO %s (geom)
            SELECT  ST_Makeline(fl.f_point,tl.f_point)
            FROM    %s f,
                    %s t,
                    lengths fl,
                    lengths tl
            WHERE   f.id != t.id
            AND     f.source = t.source
            AND     f.id = fl.id
            AND     t.id = tl.id
            AND     (f.one_way IS NULL OR f.one_way = %L)
            AND     (t.one_way IS NULL OR t.one_way = %L);
            ',  linktable,
                sourcetable,
                sourcetable,
                'tf',
                'ft');
    END;
RETURN 't';
END $func$ LANGUAGE plpgsql;
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
    namecheck record;
    schemaname TEXT;
    tabname TEXT;
    outtabname TEXT;
    query TEXT;
    srid INT;

BEGIN
    raise notice 'PROCESSING:';

    --get schema
    BEGIN
        RAISE NOTICE 'Checking % exists',input_table;
        EXECUTE '   SELECT  schema_name,
                            table_name
                    FROM    tdgTableDetails('||quote_literal(input_table)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
        schemaname=namecheck.schema_name;
        tabname=namecheck.table_name;
        IF schemaname IS NULL OR tabname IS NULL THEN
            RAISE NOTICE '-------> % not found',input_table;
            RETURN 'f';
        ELSE
            RAISE NOTICE '  -----> OK';
        END IF;

        outtabname = schemaname||'.'||output_table;
    END;

    --get srid of the geom
    BEGIN
        EXECUTE format('SELECT tdgGetSRID(to_regclass(%L),%s)',tabname,quote_literal('geom')) INTO srid;

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
                                road_from TEXT,
                                road_to TEXT,
                                source_data TEXT,
                                source_id TEXT,
                                functional_class TEXT,
                                one_way VARCHAR(2),
                                speed_limit INT,
                                adt INT,
                                z_value INT,
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
        query := query || ',source_data';
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
        query := query || ',' || quote_literal(tabname);
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
        query := query || ' FROM ' ||tabname|| ' r';

        EXECUTE query;
    END;

    --indexes
    BEGIN
        EXECUTE format('
            CREATE INDEX sidx_%s_geom ON %s USING GIST(geom);
            CREATE INDEX idx_%s_oneway ON %s (one_way);
            CREATE INDEX idx_%s_zval ON %s (z_value);
            CREATE INDEX idx_%s_srctrgt ON %s (source,target);
            ',  output_table,
                outtabname,
                output_table,
                outtabname,
                output_table,
                outtabname,
                output_table,
                outtabname);
    END;

    EXECUTE format('ANALYZE %s;', output_table);
    RETURN 't';
END $func$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION tdgGetSRID(input_table REGCLASS,geom_name TEXT)
RETURNS INT AS $func$

DECLARE
    geomdetails RECORD;

BEGIN
    EXECUTE format ('
        SELECT  ST_SRID(%s) AS srid
        FROM    %s
        WHERE   %s IS NOT NULL LIMIT 1
        ',  geom_name,
            input_table,
            geom_name) INTO geomdetails;

    RETURN geomdetails.srid;
END $func$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION tdgCalculateStress(anyelement)
--calculate stress score
RETURNS INT
LANGUAGE SQL AS
'SELECT 1';
CREATE OR REPLACE FUNCTION tdgTableDetails(input_table REGCLASS)
RETURNS RECORD AS $func$

DECLARE
    tabledetails RECORD;

BEGIN
    EXECUTE format ('
        SELECT  nspname::TEXT AS schema_name,
                relname::TEXT AS table_name
        FROM    pg_namespace n JOIN pg_class c ON n.oid = c.relnamespace
        WHERE   c.oid = %L::regclass
        ',  input_table) INTO tabledetails;

    RETURN tabledetails;
END $func$ LANGUAGE plpgsql;
