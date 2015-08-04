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
    linkverttable text;
    turnrestricttable text;
    sridinfo record;
    srid int;

BEGIN
    raise notice 'PROCESSING:';

    --check table and schema
    BEGIN
        RAISE DEBUG 'Cheking % exists',t_name;
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
        linkverttable = sname || '.' || tname || '_net_link_node';
        turnrestricttable = sname || '.' || tname || '_turn_restriction';
    END;


    --get srid of the geom
    BEGIN
        raise DEBUG 'Checking the SRID of the geometry';
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

    BEGIN
        --drop old tables
        raise DEBUG 'dropping tables';
        EXECUTE format('
            DROP TABLE IF EXISTS %s;
            DROP TABLE IF EXISTS %s;
            DROP TABLE IF EXISTS %s;
            ',  turnrestricttable,
                verttable,
                linkverttable);
    END;

    BEGIN
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
                                node_id INT);
            ',  linkverttable);
    END;

    BEGIN
        --indexes
        EXECUTE format('
            CREATE INDEX %s ON %s USING gist (geom);
            CREATE INDEX %s ON %s (road_id, node_id);
            ',  'sidx_' || tname || 'vert_geom',
                verttable,
                'idx_' || tname || '_rdnd',
                linkverttable);
    END;

    BEGIN
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
            INSERT INTO %s (road_id, node_id)
            SELECT  v.i,
                    n.id
            FROM    v,
                    %s n
            WHERE   v.geom = n.geom
            ',  srid,
                sourcetable,
                sourcetable,
                verttable,
                ' | ',
                linkverttable,
                verttable);
    END;
RETURN 'success';
END $func$ LANGUAGE plpgsql;


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
