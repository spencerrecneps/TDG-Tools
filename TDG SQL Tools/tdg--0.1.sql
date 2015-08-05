-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION tdg" to load this file. \quit

CREATE OR REPLACE FUNCTION MakeNetwork(t_name varchar(50))
--sets triggers to automatically update vertices
RETURNS VARCHAR AS $func$

DECLARE
    sname text;
    tname text;
    namecheck record;
    query text;
    sourcetable text;
    verttable text;
    linktable text;
    turnrestricttable text;
    sridinfo record;
    srid int;

BEGIN
    raise notice 'PROCESSING:';

    --check table and schema
    BEGIN
        RAISE DEBUG 'Checking % exists',t_name;
        execute 'select * from pgr_getTableName('||quote_literal(t_name)||')' into namecheck;
        sname=namecheck.sname;
        tname=namecheck.tname;
        IF sname IS NULL OR tname IS NULL THEN
    	RAISE NOTICE '-------> % not found',t_name;
            RETURN 'FAIL';
        ELSE
    	RAISE DEBUG '  -----> OK';
        END IF;

        sourcetable = sname || '.' || tname;
        verttable = sname || '.' || tname || '_net_vert';
        linktable = sname || '.' || tname || '_net_link';
        turnrestricttable = sname || '.' || tname || '_turn_restriction';
    END;

    --snap geom to grid to nearest 2 ft
    BEGIN
        RAISE DEBUG 'snapping road geometries';
        EXECUTE format('
            UPDATE  %s
            SET     geom = ST_SnapToGrid(geom,2);
            ',  sourcetable);
    END;

    --check for from/to columns
    BEGIN
        RAISE DEBUG 'checking for source/target columns';
        IF EXISTS (
            SELECT 1 FROM pg_attribute
            WHERE  attrelid = tname::regclass
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
            WHERE  attrelid = tname::regclass
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
    END;

    --get srid of the geom
    BEGIN
        RAISE DEBUG 'Checking the SRID of the geometry';
        query= '  SELECT ST_SRID(geom) as srid
                FROM ' || pgr_quote_ident(t_name) || '
                WHERE geom IS NOT NULL LIMIT 1';
        EXECUTE QUERY INTO sridinfo;

        IF sridinfo IS NULL OR sridinfo.srid IS NULL THEN
            RAISE NOTICE 'ERROR: Can not determine the srid of the geometry in table %', t_name;
            RETURN 'FAIL';
        END IF;
        srid := sridinfo.srid;
        raise DEBUG '  -----> SRID found %',srid;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'ERROR: Can not determine the srid of the geometry "%" in table %', the_geom,tabname;
            RETURN 'FAIL';
    END;

    --drop old tables
    BEGIN
        RAISE DEBUG 'dropping tables';
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
        raise DEBUG 'creating new tables';
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
        RAISE DEBUG 'creating indexes';
        EXECUTE format('
            CREATE INDEX %s ON %s USING gist (geom);
            CREATE INDEX %s ON %s (road_id);
            CREATE INDEX %s ON %s (direction);
            CREATE INDEX %s ON %s (source,target);
            ',  'sidx_' || tname || 'vert_geom',
                verttable,
                'idx_' || tname || '_link_road_id',
                linktable,
                'idx_' || tname || '_link_direction',
                linktable,
                'idx_' || tname || '_srctrgt',
                sourcetable);
    END;

    --insert points into vertices table
    BEGIN
        RAISE DEBUG 'adding points to vertices table';
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
        RAISE DEBUG 'getting source/target info';
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
                tname,
                tname);
    END;

    --populate links table
    BEGIN
        RAISE DEBUG 'adding links';
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
            SELECT  id,
                    ST_Length(geom) AS len,
                    ST_LineInterpolatePoint(geom,LEAST(0.5*ST_Length(geom)-5,50.0)/ST_Length(geom)) AS f_point,
                    ST_LineInterpolatePoint(geom,GREATEST(0.5*ST_Length(geom)+5,ST_Length(geom)-50)/ST_Length(geom)) AS t_point
            FROM    %s;
            ',  sourcetable);

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
RETURN 'success';
END $func$ LANGUAGE plpgsql;


--trigger needs
--cost update on source roads
--geom update/delete/add on source roads
--add/delete from turn restrictions

CREATE OR REPLACE FUNCTION GenerateCrossStreetData(anyelement)
--populate cross-street data
RETURNS INT
LANGUAGE SQL AS
'SELECT 1';


CREATE OR REPLACE FUNCTION CalculateStress(anyelement)
--calculate stress score
RETURNS INT
LANGUAGE SQL AS
'SELECT 1';


-------------------------------------------
--                                       --
--            STRESS TABLES              --
--                                       --
-------------------------------------------
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
