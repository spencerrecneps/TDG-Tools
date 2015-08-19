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
CREATE OR REPLACE FUNCTION tdgMakeRouter (input_table REGCLASS)
RETURNS BOOLEAN AS $func$

DECLARE
    namecheck RECORD;
    schema_name TEXT;
    table_name TEXT;
    routetable TEXT;
    linktable TEXT;
    verttable TEXT;

BEGIN
    BEGIN
        --make sure the input table exists and get infos
        RAISE NOTICE 'Checking % exists',input_table;
        EXECUTE '   SELECT  schema_name,
                            table_name
                    FROM    tdgTableDetails('||quote_literal(input_table)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
        schema_name=namecheck.schema_name;
        table_name=namecheck.table_name;
        IF schema_name IS NULL OR table_name IS NULL THEN
            RAISE NOTICE '-------> % not found',input_table;
            RETURN 'f';
        END IF;

        --set table names
        routetable = schema_name || '.' || table_name || '_net_router';
        linktable = schema_name || '.' || table_name || '_net_link';
        verttable = schema_name || '.' || table_name || '_net_vert';

        --check whether link and vert tables exist
        IF tdgTableCheck(linktable) = 'f' THEN
            RAISE NOTICE '--------> % not found',linktable;
            RETURN 'f';
        END IF;
        IF tdgTableCheck(verttable) = 'f' THEN
            RAISE NOTICE '--------> % not found',verttable;
            RETURN 'f';
        END IF;

        --create new routing table
        RAISE NOTICE 'Creating routing table %',routetable;
        EXECUTE format('DROP TABLE IF EXISTS %s;',routetable);
        EXECUTE format('
            CREATE TABLE %s (
                id SERIAL PRIMARY KEY,
                net_id TEXT,
                net_cost INT,
                net_stress INT
            )
            ',  routetable);
        EXECUTE format('
            CREATE INDEX %s ON %s (net_id);'
            ,  'idx_'||table_name||'_router_netid',
                routetable);
    END;

    BEGIN
        RAISE NOTICE 'Inserting data';
        EXECUTE format('
            INSERT INTO %s (net_id,net_cost,net_stress)
            SELECT  l.source_node::TEXT || %L || l.target_node::TEXT,
                    COALESCE(link_cost,0),
                    COALESCE(link_stress,1)
            FROM    %s l
            ',  routetable,
                '-',
                linktable);
    END;

RETURN 't';
END $func$ LANGUAGE plpgsql;
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
    inttable text;
    srid int;
    indexcheck TEXT;

BEGIN
    RAISE NOTICE 'PROCESSING:';

    --check table and schema
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
        inttable = schema_name || '.' || table_name || '_intersections';
    END;

    --check for from/to/cost columns
    BEGIN
        RAISE NOTICE 'checking for source/target columns';
        IF tdgColumnCheck(table_name,'source') = 't' THEN
            EXECUTE format('
                UPDATE %s SET source=NULL;
                ',  sourcetable);
        ELSE
            EXECUTE format('
                ALTER TABLE %s ADD COLUMN source INT;
                ',  sourcetable);
        END IF;
        IF tdgColumnCheck(table_name,'target') = 't' THEN
            EXECUTE format('
                UPDATE %s SET target=NULL;
                ',  sourcetable);
        ELSE
            EXECUTE format('
                ALTER TABLE %s ADD COLUMN target INT;
                ',  sourcetable);
        END IF;
        IF tdgColumnCheck(table_name,'ft_cost') = 't' THEN
            EXECUTE format('
                UPDATE %s SET ft_cost=NULL;
                ',  sourcetable);
        ELSE
            EXECUTE format('
                ALTER TABLE %s ADD COLUMN ft_cost INT;
                ',  sourcetable);
        END IF;
        IF tdgColumnCheck(table_name,'tf_cost') = 't' THEN
            EXECUTE format('
                UPDATE %s SET tf_cost=NULL;
                ',  sourcetable);
        ELSE
            EXECUTE format('
                ALTER TABLE %s ADD COLUMN tf_cost INT;
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
            CREATE TABLE %s (   node_id serial PRIMARY KEY,
                                intersection_id INT,
                                node_cost INT,
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
                                source_node INT,
                                target_node INT,
                                direction VARCHAR(2),
                                link_cost INT,
                                link_stress INT,
                                geom geometry(linestring,%L));
            ',  linktable,
                srid);
    END;

    --indexes
    BEGIN
        RAISE NOTICE 'creating indexes';
        EXECUTE format('
            CREATE INDEX %s ON %s USING gist (geom);
            CREATE INDEX %s ON %s (intersection_id);
            CREATE INDEX %s ON %s (road_id);
            CREATE INDEX %s ON %s (direction);
            CREATE INDEX %s ON %s (source_node,target_node);
            ',  'sidx_' || table_name || 'vert_geom',
                verttable,
                'idx_' || table_name || 'vert_intid',
                verttable,
                'idx_' || table_name || '_link_road_id',
                linktable,
                'idx_' || table_name || '_link_direction',
                linktable,
                'idx_' || table_name || '_link_src_trgt',
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
            INSERT INTO %s (node_order, geom)
            SELECT      COUNT(i),
                        geom
            FROM        v
            GROUP BY    geom;
            ',  srid,
                sourcetable,
                sourcetable,
                verttable);
    END;

    --get source/target info
    BEGIN
        RAISE NOTICE 'getting source/target info';
        EXECUTE format('
            UPDATE  %s
            SET     source = vf.node_id,
                    target = vt.node_id
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
            WHERE   s.source = vf.node_id
            AND     s.target = vt.node_id;
            ',  sourcetable,
                verttable,
                verttable);

        --self segment ft
        EXECUTE format('
            INSERT INTO %s (geom,
                            direction,
                            road_id,
                            source_node,
                            target_node,
                            link_cost,
                            link_stress)
            SELECT  ST_Makeline(l.f_point,l.t_point),
                    %L,
                    r.id,
                    r.source,
                    r.target,
                    r.ft_cost,
                    GREATEST(r.ft_seg_stress,r.ft_int_stress)
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
                            source_node,
                            target_node,
                            link_cost,
                            link_stress)
            SELECT  ST_Makeline(l.t_point,l.f_point),
                    %L,
                    r.id,
                    r.target,
                    r.source,
                    r.tf_cost,
                    GREATEST(r.tf_seg_stress,r.tf_int_stress)
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
            INSERT INTO %s (geom,
                            direction,
                            road_id,
                            source_node,
                            target_node,
                            link_cost,
                            link_stress)
            SELECT  ST_Makeline(fl.t_point,tl.f_point),
                    %L,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL
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
                'ft',
                sourcetable,
                sourcetable,
                'ft',
                'ft');

        --from end to end
        EXECUTE format('
            INSERT INTO %s (geom,
                            direction,
                            road_id,
                            source_node,
                            target_node,
                            link_cost,
                            link_stress)
            SELECT  ST_Makeline(fl.t_point,tl.t_point),
                    %L,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL
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
                'ft',
                sourcetable,
                sourcetable,
                'ft',
                'tf');

        --from start to end
        EXECUTE format('
            INSERT INTO %s (geom,
                            direction,
                            road_id,
                            source_node,
                            target_node,
                            link_cost,
                            link_stress)
            SELECT  ST_Makeline(fl.f_point,tl.t_point),
                    %L,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL
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
                'ft',
                sourcetable,
                sourcetable,
                'tf',
                'tf');

        --from start to start
        EXECUTE format('
            INSERT INTO %s (geom,
                            direction,
                            road_id,
                            source_node,
                            target_node,
                            link_cost,
                            link_stress)
            SELECT  ST_Makeline(fl.f_point,tl.f_point),
                    %L,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL
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
                'ft',
                sourcetable,
                sourcetable,
                'tf',
                'ft');
    END;

    BEGIN
        EXECUTE format('ANALYZE %s;', verttable);
        EXECUTE format('ANALYZE %s;', linktable);
        EXECUTE format('ANALYZE %s;', turnrestricttable);
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
                                ft_cost INT,
                                tf_cost INT)
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

    --snap geom to grid to nearest 2 ft
    BEGIN
        RAISE NOTICE 'snapping road geometries';
        EXECUTE format('
            UPDATE  %s
            SET     geom = ST_SnapToGrid(geom,2);
            ',  outtabname);
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

    BEGIN
        EXECUTE format('ANALYZE %s;', output_table);
    END;

    BEGIN
        PERFORM tdgMakeIntersections(outtabname::REGCLASS);
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION tdgMakeIntersections (input_table REGCLASS)
RETURNS BOOLEAN AS $func$

DECLARE
    namecheck RECORD;
    schema_name TEXT;
    table_name TEXT;
    inttable text;
    sridinfo record;
    srid int;

BEGIN
    RAISE NOTICE 'PROCESSING:';

    --check table and schema
    BEGIN
        RAISE NOTICE 'Checking % exists',input_table;
        EXECUTE '   SELECT  schema_name,
                            table_name
                    FROM    tdgTableDetails('||quote_literal(input_table)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
        schema_name:=namecheck.schema_name;
        table_name:=namecheck.table_name;
        IF schema_name IS NULL OR table_name IS NULL THEN
            RAISE NOTICE '-------> % not found',input_table;
            RETURN 'f';
        ELSE
            RAISE NOTICE '  -----> OK';
        END IF;

        inttable = schema_name || '.' || table_name || '_intersections';
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

    BEGIN
        RAISE NOTICE 'creating intersection table';
        EXECUTE format('
            CREATE TABLE %s (   id serial PRIMARY KEY,
                                geom geometry(point,%L),
                                legs INT,
                                signalized BOOLEAN);
            ',  inttable,
                srid);
    END;

    BEGIN
        RAISE NOTICE 'adding intersections';
        EXECUTE format('
            CREATE TEMP TABLE v (i INT, geom geometry(point,%L)) ON COMMIT DROP;
            INSERT INTO v (i, geom) SELECT id, ST_StartPoint(geom) FROM %s ORDER BY id ASC;
            INSERT INTO v (i, geom) SELECT id, ST_EndPoint(geom) FROM %s ORDER BY id ASC;
            INSERT INTO %s (legs, geom)
            SELECT      COUNT(i),
                        geom
            FROM        v
            GROUP BY    geom;
            ',  srid,
                input_table,
                input_table,
                inttable);
    END;

EXECUTE format('ANALYZE %s;', inttable);

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
