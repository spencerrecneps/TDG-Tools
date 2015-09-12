CREATE TYPE tdgShortestPathType AS (
    move_sequence INT,
    link_id INT,
    vert_id INT,
    road_id INT,
    int_id INT,
    move_cost INT
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
CREATE OR REPLACE FUNCTION tdgSetTurnInfo ( linktable REGCLASS,
                                            inttable REGCLASS,
                                            verttable REGCLASS,
                                            intersection_ids INT[])
RETURNS BOOLEAN AS $func$

DECLARE
    temptable TEXT;

BEGIN
    RAISE NOTICE 'creating temporary turn data table';
    temptable := 'tdggtitemptbl';
    EXECUTE format('
        CREATE TEMP TABLE %s (
            int_id INT,
            ref_link_id INT,
            match_link_id INT,
            ref_azimuth INT,
            match_azimuth INT,
            movement TEXT)
        ON COMMIT DROP;
    ',  temptable);

    EXECUTE format('
        INSERT INTO %s (int_id,
                        ref_link_id,
                        match_link_id,
                        ref_azimuth,
                        match_azimuth)
        SELECT  int.id,
                l1.id,
                l2.id,
                degrees(ST_Azimuth(ST_StartPoint(l1.geom),ST_EndPoint(l1.geom))),
                degrees(ST_Azimuth(ST_StartPoint(l2.geom),ST_EndPoint(l2.geom)))
        FROM    %s int
        JOIN    %s v1
                ON  int.id = v1.intersection_id
        JOIN    %s v2
                ON  int.id = v2.intersection_id
        JOIN    %s l1
                ON  l1.target_node = v1.node_id
                AND l1.road_id IS NOT NULL
        JOIN    %s l2
                ON  l2.source_node = v2.node_id
                AND l2.road_id IS NOT NULL
                AND l1.road_id != l2.road_id
        WHERE   int.id = ANY (%L);
        ',  temptable,
            inttable,
            verttable,
            verttable,
            linktable,
            linktable,
            intersection_ids);

    --reposition the azimuths so that the reference azimuth is at 0
    RAISE NOTICE 'repositioning azimuths';

    EXECUTE format('
        UPDATE  %s
        SET     match_azimuth = MOD((360 + 180 + match_azimuth - ref_azimuth),360);
        ',  temptable);

    EXECUTE format('
        UPDATE  %s
        SET     ref_azimuth = 0;
        ',  temptable);


    --calculate turn info
    --right turns
    RAISE NOTICE 'calculating turns';
    EXECUTE format('
        UPDATE  %s
        SET     movement = %L
        FROM    (   SELECT DISTINCT ON (t.ref_link_id)
                        t.ref_link_id,
                        t.match_link_id
                    FROM %s t
                    ORDER BY t.ref_link_id, t.match_azimuth DESC) x
        WHERE   %s.ref_link_id = x.ref_link_id
        AND     %s.match_link_id = x.match_link_id;
        ',  temptable,
            'right',
            temptable,
            temptable,
            temptable);

    --left turns
    EXECUTE format('
        UPDATE  %s
        SET     movement = %L
        FROM    (   SELECT DISTINCT ON (t.ref_link_id)
                        t.ref_link_id,
                        t.match_link_id
                    FROM %s t
                    ORDER BY t.ref_link_id, t.match_azimuth ASC) x
        WHERE   %s.ref_link_id = x.ref_link_id
        AND     %s.match_link_id = x.match_link_id;
        ',  temptable,
            'left',
            temptable,
            temptable,
            temptable);

    --straights
    EXECUTE format('
        UPDATE  %s
        SET     movement = %L
        WHERE   movement IS NULL;
        ',  temptable,
            'straight');

    --find intersections where left or right may have been assigned
    --but it's actually straight (i.e.T intersections or other odd situations)
    EXECUTE format('
        UPDATE  %s
        SET     movement = %L
        FROM    %s ints
        WHERE   %s.int_id = ints.id
        AND     (   SELECT  COUNT(t.int_id)
                    FROM    %s t
                    WHERE   t.int_id = %s.int_id
                    AND     t.ref_link_id = %s.ref_link_id) < 3
        AND     match_azimuth >= 150
        AND     match_azimuth <= 210
        AND     movement != %L;
        ',  temptable,
            'straight',
            inttable,
            temptable,
            temptable,
            temptable,
            temptable,
            'straight');

    --set turn info in links table
    RAISE NOTICE 'setting turns in %', linktable;
    EXECUTE format('
        UPDATE  %s
        SET     movement = t.movement
        FROM    %s t,
                %s lf,
                %s lt
        WHERE   t.ref_link_id = lf.id
        AND     t.match_link_id = lt.id
        AND     %s.source_node = lf.target_node
        AND     %s.target_node = lt.source_node;
        ',  linktable,
            temptable,
            linktable,
            linktable,
            linktable,
            linktable);

    --clean up temp table
    EXECUTE format('DROP TABLE %s', temptable);

RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgSetTurnInfo(REGCLASS,REGCLASS,REGCLASS,INT[]) OWNER TO gis;
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
ALTER FUNCTION tdgGenerateCrossStreetData(REGCLASS) OWNER TO gis;
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
CREATE OR REPLACE FUNCTION tdgMultiToSingle (   temp_table_ REGCLASS,
                                                new_table_ TEXT,
                                                schema_ TEXT,
                                                srid_ INTEGER,
                                                overwrite_ BOOLEAN)
RETURNS BOOLEAN AS $func$

DECLARE
    namecheck TEXT;
    columndetails RECORD;
    newcolumnname TEXT;

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
        USING   new_table_
        INTO    namecheck;

        IF NOT namecheck IS NULL THEN
            RAISE EXCEPTION 'Table % already exists', new_table_;
        END IF;
    END IF;

    --create new table
    EXECUTE '   CREATE TABLE ' || schema_ || '.' || new_table_ || '
                    (   id SERIAL PRIMARY KEY,
                        temp_id INTEGER,
                        tdg_id TEXT NOT NULL DEFAULT uuid_generate_v4()::TEXT,
                        geom geometry(LINESTRING,' || srid_::TEXT || '));';

    --insert info from temporary table
    EXECUTE '   INSERT INTO ' || schema_ || '.' || new_table_ || ' (temp_id,geom)
                SELECT id,ST_Transform((ST_Dump(geom)).geom,$1)
                FROM ' || temp_table_ || ';'
    USING   srid_;

    --copy table structure from temporary table
    RAISE NOTICE 'Copying table structure from %', temp_table_;
    FOR columndetails IN
    EXECUTE '
        SELECT  a.attname AS col,
                pg_catalog.format_type(a.atttypid, a.atttypmod) AS datatype
        FROM    pg_catalog.pg_attribute a
        WHERE   a.attnum > 0
        AND     NOT a.attisdropped
        AND     a.attrelid = ' || quote_literal(temp_table_) || '::REGCLASS;'
    LOOP
        IF columndetails.col NOT IN ('id','geom','tdg_id') THEN
            --sanitize column name
            newcolumnname := regexp_replace(LOWER(columndetails.col), '[^a-zA-Z_]', '', 'g');
            EXECUTE '   ALTER TABLE ' || new_table_ || '
                        ADD COLUMN ' || newcolumnname || ' ' || columndetails.datatype || ';';

            --copy data over
            EXECUTE '   UPDATE ' || new_table_ || '
                        SET ' || newcolumnname || ' = t.' || quote_ident(columndetails.col) || '
                        FROM ' || temp_table_ || ' t
                        WHERE t.id = ' || new_table_ || '.temp_id;';
        END IF;
    END LOOP;

    --drop the temp_id column
    EXECUTE 'ALTER TABLE ' || schema_ || '.' || new_table_ || ' DROP COLUMN temp_id;';

    --drop the temporary table
    EXECUTE 'DROP TABLE ' || temp_table_ || ';';

    RETURN 't';

EXCEPTION
    EXECUTE 'DROP TABLE ' || temp_table_ || ';';
    
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgMultiToSingle(REGCLASS,TEXT,TEXT,INTEGER,BOOLEAN) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdgShortestPathVerts (   linktable_ REGCLASS,
                                                    verttable_ REGCLASS,
                                                    from_ INT,
                                                    to_ INT,
                                                    stress_ INT DEFAULT NULL)
RETURNS SETOF tdgShortestPathType AS $$

import networkx as nx

# check node existence
qc = plpy.execute('SELECT EXISTS (SELECT 1 FROM %s WHERE node_id = %s)' % (verttable_,from_))
if not qc[0]['exists']:
    plpy.error('From vertex does not exist.')
qc = plpy.execute('SELECT EXISTS (SELECT 1 FROM %s WHERE node_id = %s)' % (verttable_,to_))
if not qc[0]['exists']:
    plpy.error('To vertex does not exist.')

# create the graph
DG=nx.DiGraph()

# read input stress
stress = 99
if not stress_ is None:
    stress = stress_

# edges first
edges = plpy.execute('SELECT * FROM %s;' % linktable_)
for e in edges:
    DG.add_edge(e['source_node'],
                e['target_node'],
                weight=max(e['link_cost'],0),
                link_id=e['id'],
                stress=min(e['link_stress'],99),
                road_id=e['road_id'])

# then vertices
verts = plpy.execute('SELECT * FROM %s;' % verttable_)
for v in verts:
    vid = v['node_id']
    DG.node[vid]['weight'] = max(v['node_cost'],0)
    DG.node[vid]['intersection_id'] = v['intersection_id']


# get the shortest path
plpy.info('Checking for path existence')
if nx.has_path(DG,source=from_,target=to_):
    plpy.info('Path found')
    shortestPath = nx.shortest_path(DG,source=from_,target=to_,weight='weight')
else:
    plpy.error('No path between given vertices')


# set up function to return edges
def getNextNode(nodes,node):
    pos = nodes.index(node)
    try:
        return nodes[pos+1]
    except:
        return None


# build the return values
ret = []
seq = 0
for v1 in shortestPath:
    seq = seq + 1
    v2 = getNextNode(shortestPath,v1)
    if v2:
        ret.append((seq,
                    None,
                    v1,
                    None,
                    DG.node[v1]['intersection_id'],
                    DG.node[v1]['weight']))
        seq = seq + 1
        ret.append((seq,
                    DG.edge[v1][v2]['link_id'],
                    None,
                    DG.edge[v1][v2]['road_id'],
                    None,
                    DG.edge[v1][v2]['weight']))
    else:
        ret.append((seq,
                    None,
                    v1,
                    None,
                    DG.node[v1]['intersection_id'],
                    DG.node[v1]['weight']))

return ret

$$ LANGUAGE plpythonu;
ALTER FUNCTION tdgShortestPathVerts(REGCLASS,REGCLASS,INT,INT,INT) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdgUpdateNetwork (input_table REGCLASS, rowids INT[])
RETURNS BOOLEAN AS $func$

DECLARE

BEGIN

RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgUpdateNetwork(REGCLASS,INT[]) OWNER TO gis;
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
    intersection_ids INT[];

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
                                intersection_id INT,
                                direction VARCHAR(2),
                                movement TEXT,
                                link_cost INT,
                                link_stress INT,
                                geom geometry(linestring,%L));
            ',  linktable,
                srid);
    END;


    --create temporary table of all possible vertices
    EXECUTE format('
        CREATE TEMP TABLE v (   id SERIAL PRIMARY KEY,
                                road_id INT,
                                vert_id INT,
                                int_id INT,
                                loc VARCHAR(1),
                                int_geom geometry(point,%L),
                                vert_geom geometry(point,%L))
        ON COMMIT DROP;
        ',  srid,
            srid);


    --insert vertices
    BEGIN
        RAISE NOTICE 'adding points to vertices table';

        EXECUTE format('
            INSERT INTO v (road_id, loc, int_geom, vert_geom)
            SELECT      id,
                        %L,
                        ST_StartPoint(geom),
                        ST_LineInterpolatePoint(s.geom,LEAST(0.5*ST_Length(s.geom)-2,4)/ST_Length(s.geom))
            FROM        %s s
            ORDER BY    id ASC;
            ',  'f',
                sourcetable);

        EXECUTE format('
            INSERT INTO v (road_id, loc, int_geom, vert_geom)
            SELECT      id,
                        %L,
                        ST_EndPoint(geom),
                        ST_LineInterpolatePoint(s.geom,GREATEST(0.5*ST_Length(s.geom)+2,ST_Length(s.geom)-4)/ST_Length(s.geom))
            FROM        %s s
            ORDER BY    id ASC;
            ',  't',
                sourcetable);

        --get intersections for v
        EXECUTE format('
            UPDATE  v
            SET     int_id = intersection.id
            FROM    %s intersection
            WHERE   v.int_geom = intersection.geom;
            ',  inttable);

        --insert points into vertices table
        EXECUTE format('
            INSERT INTO %s (intersection_id, geom)
            SELECT      intersection.id,
                        v.vert_geom
            FROM        v,
                        %s intersection
            WHERE       v.int_id = intersection.id
            AND         intersection.legs > 2
            GROUP BY    intersection.id,
                        v.vert_geom;
            ',  verttable,
                inttable);

        EXECUTE format('
            INSERT INTO %s (intersection_id, geom)
            SELECT      intersection.id,
                        v.int_geom
            FROM        v,
                        %s intersection
            WHERE       v.int_id = intersection.id
            AND         intersection.legs < 3
            GROUP BY    intersection.id,
                        v.int_geom;
            ',  verttable,
                inttable);
    END;

    --vertex indexes
    BEGIN
        RAISE NOTICE 'creating vertex indexes';
        EXECUTE format('
            CREATE INDEX %s ON %s USING gist (geom);
            CREATE INDEX %s ON %s (intersection_id);
            ',  'sidx_' || table_name || 'vert_geom',
                verttable,
                'idx_' || table_name || 'vert_intid',
                verttable);
    END;

    EXECUTE format('ANALYZE %s;', verttable);

    --join back the vertices to v
    BEGIN
        EXECUTE format('
            UPDATE  v
            SET     vert_id = vx.node_id
            FROM    %s vx
            WHERE   v.vert_geom = vx.geom;
            ',  verttable);
        EXECUTE format('
            UPDATE  v
            SET     vert_id = vx.node_id
            FROM    %s vx
            WHERE   v.int_geom = vx.geom;
            ',  verttable);
    END;


    --populate direct links
    BEGIN
        RAISE NOTICE 'adding links';
        EXECUTE format('
            CREATE TEMP TABLE lengths ( id SERIAL PRIMARY KEY,
                                        len FLOAT,
                                        f_point geometry(point, %L),
                                        t_point geometry(point, %L),
                                        f_int_id INT,
                                        t_int_id INT)
            ON COMMIT DROP;
            ',  srid,
                srid);

        EXECUTE format('
            INSERT INTO lengths (id, len, f_point, t_point, f_int_id, t_int_id)
            SELECT  s.id,
                    ST_Length(s.geom) AS len,
                    CASE    WHEN f_int.legs > 2
                            THEN vf.vert_geom
                            ELSE vf.int_geom
                            END AS f_point,
                    CASE    WHEN t_int.legs > 2
                            THEN vt.vert_geom
                            ELSE vt.int_geom
                            END AS t_point,
                    vf.int_id,
                    vt.int_id
            FROM    %s s
            JOIN    v vf
                    ON s.id = vf.road_id AND vf.loc = %L
            JOIN    %s f_int
                    ON vf.int_id = f_int.id
            JOIN    v vt
                    ON s.id = vt.road_id AND vt.loc = %L
            JOIN    %s t_int
                    ON vt.int_id = t_int.id;
            ',  input_table,
                'f',
                inttable,
                't',
                inttable);

        --links - self segment ft
        EXECUTE format('
            INSERT INTO %s (geom,
                            direction,
                            road_id,
                            link_cost,
                            link_stress)
            SELECT  ST_Makeline(l.f_point,l.t_point),
                    %L,
                    r.id,
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

        --links - self segment tf
        EXECUTE format('
            INSERT INTO %s (geom,
                            direction,
                            road_id,
                            link_cost,
                            link_stress)
            SELECT  ST_Makeline(l.t_point,l.f_point),
                    %L,
                    r.id,
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
    END;

    --set source/target info
    BEGIN
        RAISE NOTICE 'setting source/target info';
        EXECUTE format('
            UPDATE  %s
            SET     source_node = vf.vert_id,
                    target_node = vt.vert_id
            FROM    v vf,
                    v vt
            WHERE   %s.direction = %L
            AND     %s.road_id = vf.road_id AND vf.loc = %L
            AND     %s.road_id = vt.road_id AND vt.loc = %L;
            ',  linktable,
                linktable,
                'ft',
                linktable,
                'f',
                linktable,
                't');
        EXECUTE format('
            UPDATE  %s
            SET     source_node = vt.vert_id,
                    target_node = vf.vert_id
            FROM    v vf,
                    v vt
            WHERE   %s.direction = %L
            AND     %s.road_id = vf.road_id AND vf.loc = %L
            AND     %s.road_id = vt.road_id AND vt.loc = %L;
            ',  linktable,
                linktable,
                'tf',
                linktable,
                'f',
                linktable,
                't');
    END;


    --populate connector links
    BEGIN
        EXECUTE format('
            INSERT INTO %s (geom,
                            direction,
                            intersection_id,
                            source_node,
                            target_node,
                            link_cost,
                            link_stress)
            SELECT  ST_Makeline(v1.geom,v2.geom),
                    NULL,
                    v1.intersection_id,
                    v1.node_id,
                    v2.node_id,
                    NULL,
                    NULL
            FROM    %s v1,
                    %s v2,
                    %s s1,
                    %s s2
            WHERE   v1.node_id != v2.node_id
            AND     v1.intersection_id = v2.intersection_id
            AND     s1.target_node = v1.node_id
            AND     s2.source_node = v2.node_id
            AND     NOT s1.road_id = s2.road_id;
            ',  linktable,
                verttable,
                verttable,
                linktable,
                linktable);
    END;


    --set turn information intersection by intersections
    BEGIN
        EXECUTE format('SELECT array_agg(id) from %s',inttable) INTO intersection_ids;
        EXECUTE format('
            SELECT tdgSetTurnInfo(%L,%L,%L,%L);
            ',  linktable,
                inttable,
                verttable,
                intersection_ids);
    END;


    --link indexes
    BEGIN
        RAISE NOTICE 'creating link indexes';
        EXECUTE format('
            CREATE INDEX %s ON %s (road_id);
            CREATE INDEX %s ON %s (direction);
            CREATE INDEX %s ON %s (source_node,target_node);
            ',  'idx_' || table_name || '_link_road_id',
                linktable,
                'idx_' || table_name || '_link_direction',
                linktable,
                'idx_' || table_name || '_link_src_trgt',
                linktable);
    END;

    BEGIN
        EXECUTE format('ANALYZE %s;', linktable);
        EXECUTE format('ANALYZE %s;', turnrestricttable);
    END;
RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgMakeNetwork(REGCLASS) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdgShortestPathIntersections (   inttable_ REGCLASS,
                                                            linktable_ REGCLASS,
                                                            verttable_ REGCLASS,
                                                            from_ INT,
                                                            to_ INT,
                                                            stress_ INT DEFAULT NULL)
RETURNS SETOF tdgShortestPathType AS $func$

DECLARE
    vertcheck BOOLEAN;
    fromtestvert INT;
    totestvert INT;
    minfromvert INT;
    mintovert INT;
    mincost INT;
    comparecost INT;

BEGIN
    --check intersections for existence
    RAISE NOTICE 'Checking intersections';

    EXECUTE 'SELECT EXISTS (SELECT 1 FROM '|| inttable_ || ' WHERE id IN ($1,$2));'
    INTO    vertcheck
    USING   from_,
            to_;

    IF NOT vertcheck THEN
        EXECUTE 'SELECT EXISTS (SELECT 1 FROM '|| inttable_ || ' WHERE id = $1);'
        INTO    vertcheck
        USING   from_;

        IF NOT vertcheck THEN
            RAISE EXCEPTION 'Nonexistent intersection --> %', from_::TEXT
            USING HINT = 'Please check your intersections';
        END IF;

        EXECUTE 'SELECT EXISTS (SELECT 1 FROM '|| inttable_ || ' WHERE id = $1);'
        INTO    vertcheck
        USING   to_;

        IF NOT vertcheck THEN
            RAISE EXCEPTION 'Nonexistent intersection --> %', to_::TEXT
            USING HINT = 'Please check your intersections';
        END IF;
    END IF;

    RAISE NOTICE 'Testing shortest paths';
    --do shortest path starting at first vertex to other vertices
    --then do another and compare SUM(move_cost) to first. Keep lowest.
    FOR fromtestvert IN
    EXECUTE '   SELECT  node_id
                FROM ' || verttable_ || '
                WHERE   intersection_id = $1;'
    USING   from_
    LOOP
        FOR totestvert IN
        EXECUTE '   SELECT  node_id
                    FROM ' || verttable_ || '
                    WHERE   intersection_id = $1;'
        USING   to_
        LOOP
            EXECUTE '   SELECT SUM(move_cost)
                        FROM    tdgShortestPathVerts($1,$2,$3,$4,$5);'
            USING   linktable_,
                    verttable_,
                    fromtestvert,
                    totestvert,
                    stress_
            INTO    comparecost;

            IF mincost IS NULL OR comparecost < mincost THEN
                mincost := comparecost;
                minfromvert := fromtestvert;
                mintovert := totestvert;
            END IF;
        END LOOP;
    END LOOP;

RETURN QUERY
EXECUTE '   SELECT  *
            FROM    tdgShortestPathVerts($1,$2,$3,$4,$5);'
USING   linktable_,
        verttable_,
        minfromvert,
        mintovert,
        stress_;
--followed by empty RETURN???
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgShortestPathIntersections(REGCLASS,REGCLASS,REGCLASS,INT,INT,INT) OWNER TO gis;
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
            EXECUTE format('DROP TABLE IF EXISTS %s',output_table||'_intersections');
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
            query := query || ',' || quote_ident(name_field);
            END IF;
        IF id_field IS NOT NULL THEN
            query := query || ',' || quote_ident(id_field);
            END IF;
        IF func_field IS NOT NULL THEN
            query := query || ',' || quote_ident(func_field);
            END IF;
        IF oneway_field IS NOT NULL THEN
            query := query || ',' || quote_ident(oneway_field);
            END IF;
        IF speed_field IS NOT NULL THEN
            query := query || ',' || quote_ident(speed_field);
            END IF;
        IF adt_field IS NOT NULL THEN
            query := query || ',' || quote_ident(adt_field);
            END IF;
        query := query || ' FROM ' ||tabname|| ' r';

        EXECUTE query;
    END;

    --indexes
    BEGIN
        EXECUTE format('
            CREATE INDEX sidx_%s_geom ON %s USING GIST(geom);
            CREATE INDEX idx_%s_oneway ON %s (one_way);
            CREATE INDEX idx_%s_sourceid ON %s (source_id);
            CREATE INDEX idx_%s_funcclass ON %s (functional_class);
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

    --intersection indexes
    BEGIN
        EXECUTE format('
            CREATE INDEX idx_%s_intfrom ON %s (intersection_from);
            CREATE INDEX idx_%s_intto ON %s (intersection_to);
            ',  output_table,
                outtabname,
                output_table,
                outtabname);
    END;

    BEGIN
        EXECUTE format('ANALYZE %s;', output_table);
    END;

    --not null on intersections
    BEGIN
        EXECUTE format('
            ALTER TABLE %s ALTER COLUMN intersection_from SET NOT NULL;
            ALTER TABLE %s ALTER COLUMN intersection_to SET NOT NULL;
            ',  outtabname,
                outtabname);
    END;

    --triggers
    BEGIN
        EXECUTE format('
            CREATE TRIGGER tdg%sGeomIntersectionUpdate
                BEFORE UPDATE OF geom ON %s
                FOR EACH ROW
                EXECUTE PROCEDURE tdgUpdateIntersections();
            ',  output_table,
                output_table);
        EXECUTE format('
            CREATE TRIGGER tdg%sGeomIntersectionAddDel
                BEFORE INSERT OR DELETE ON %s
                FOR EACH ROW
                EXECUTE PROCEDURE tdgUpdateIntersections();
            ',  output_table,
                output_table);
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgStandardizeRoadLayer( REGCLASS,TEXT,TEXT,TEXT,TEXT,TEXT,
                                        TEXT,TEXT,BOOLEAN,BOOLEAN) OWNER TO gis;
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
            RAISE EXCEPTION 'Could not determine SRID of ', input_table;
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

    -- add intersection data to roads
    BEGIN
        RAISE NOTICE 'populating intersection data in roads table';
        EXECUTE format('
            UPDATE  %s
            SET     intersection_from = if.id,
                    intersection_to = it.id
            FROM    %s if,
                    %s it
            WHERE   ST_StartPoint(%s.geom) = if.geom
            and     ST_EndPoint(%s.geom) = it.geom;
            ',  input_table,
                inttable,
                inttable,
                input_table,
                input_table);
    END;

    --triggers
    BEGIN
        EXECUTE format('
            CREATE TRIGGER tdg%sGeomPreventUpdate
                BEFORE UPDATE OF geom ON %s
                FOR EACH ROW
                EXECUTE PROCEDURE tdgTriggerDoNothing();
            ',  table_name || '_ints',
                inttable);
        EXECUTE format('
            CREATE TRIGGER tdg%sPreventInsDel
                BEFORE INSERT OR DELETE ON %s
                FOR EACH ROW
                EXECUTE PROCEDURE tdgTriggerDoNothing();
            ',  table_name || '_ints',
                inttable);
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgMakeIntersections(REGCLASS) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdgGenerateIntersectionStreets (input_table REGCLASS, intids INT[])
RETURNS BOOLEAN AS $func$

DECLARE

BEGIN

RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgGenerateIntersectionStreets(REGCLASS, INT[]) OWNER TO gis;
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
ALTER FUNCTION tdgGetSRID(REGCLASS,TEXT) OWNER TO gis;
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
ALTER FUNCTION tdgCalculateStress(REGCLASS,BOOLEAN,BOOLEAN,BOOLEAN,INT[]) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdgTableDetails(input_table TEXT)
RETURNS TABLE (schema_name TEXT, table_name TEXT) AS $func$

BEGIN
    RETURN QUERY EXECUTE '
        SELECT  nspname::TEXT, relname::TEXT
        FROM    pg_namespace n JOIN pg_class c ON n.oid = c.relnamespace
        WHERE   c.oid = to_regclass(' || quote_literal(input_table) || ')';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgTableDetails(TEXT) OWNER TO gis;
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
CREATE OR REPLACE FUNCTION tdgUpdateIntersections ()
RETURNS TRIGGER
AS $BODY$

--------------------------------------------------------------------------
-- This function is called automatically anytime a change is made to the
-- geometry of a record in a TDG-standardized road layer. It snaps
-- the new geometry to a 2-ft grid and then updates the intersection
-- information. The geometry matches an existing intersection if it
-- is within 5 ft of another intersection.
--
-- N.B. If the end of a cul-de-sac is moved, the old intersection point
-- is deleted and a new one is created. This should be an edge case
-- and wouldn't cause any problems anyway. A fix to move the intersection
-- point rather than create a new one would complicate the code and the
-- current behavior isn't really problematic.
--------------------------------------------------------------------------

DECLARE
    inttable TEXT;
    legs INT;
    startintersection RECORD;
    endintersection RECORD;

BEGIN
    --get the intersection table
    inttable := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME || '_intersections';

    --suspend triggers on the intersections table so that our
    --changes are not ignored.
    EXECUTE 'ALTER TABLE ' || inttable || ' DISABLE TRIGGER ALL;';

    --trigger operation
    IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
        --snap new geom
        NEW.geom := ST_SnapToGrid(NEW.geom,2);

        -------------------
        --  START POINT  --
        -------------------
        --do nothing if startpoint didn't change
        IF (TG_OP = 'INSERT' OR NOT (ST_StartPoint(NEW.geom) = ST_StartPoint(OLD.geom))) THEN
            -- get new start intersection data if it already exists
            EXECUTE '
                SELECT  id, geom, legs
                FROM ' || inttable || '
                WHERE       ST_DWithin(geom,ST_StartPoint($1.geom),5)
                AND         geom <#> $1.geom <= 5
                ORDER BY    geom <#> ST_StartPoint($1.geom) ASC
                LIMIT       1;'
            INTO    startintersection
            USING   NEW,
                    NEW,
                    NEW;

            -- insert/update intersections and new record
            IF startintersection.id IS NULL THEN
                EXECUTE '
                    INSERT INTO ' || inttable || ' (geom, legs)
                    SELECT ST_StartPoint($1.geom), 1
                    RETURNING id;'
                INTO    NEW.intersection_from
                USING   NEW;
            ELSE
                NEW.intersection_from := startintersection.id;
                EXECUTE '
                    UPDATE ' || inttable || '
                    SET     legs = COALESCE(legs,0) + 1
                    WHERE   id = $1;'
                USING   startintersection.id;
            END IF;
        END IF;


        -------------------
        --   END POINT   --
        -------------------
        --do nothing if startpoint didn't change
        IF (TG_OP = 'INSERT' OR NOT (ST_EndPoint(NEW.geom) = ST_EndPoint(OLD.geom))) THEN
            -- get end intersection data if it already exists
            EXECUTE '
                SELECT  id, geom, legs
                FROM ' || inttable || '
                WHERE       ST_DWithin(geom,ST_EndPoint($1.geom),5)
                AND         geom <#> $1.geom <= 5
                ORDER BY    geom <#> ST_EndPoint($1.geom) ASC
                LIMIT       1;'
            INTO    endintersection
            USING   NEW,
                    NEW,
                    NEW;

            -- insert/update intersections and new record
            IF endintersection.id IS NULL THEN
                EXECUTE '
                    INSERT INTO ' || inttable || ' (geom, legs)
                    SELECT ST_EndPoint($1.geom), 1
                    RETURNING id;'
                INTO    NEW.intersection_to
                USING   NEW;
            ELSE
                NEW.intersection_to := endintersection.id;
                EXECUTE '
                    UPDATE ' || inttable || '
                    SET     legs = COALESCE(legs,0) + 1
                    WHERE   id = $1;'
                USING   endintersection.id;
            END IF;
        END IF;
    END IF;

    IF (TG_OP = 'DELETE' OR TG_OP = 'UPDATE') THEN
        -------------------
        --  START POINT  --
        -------------------
        --do nothing if startpoint didn't change
        IF (TG_OP = 'DELETE' OR NOT (ST_StartPoint(NEW.geom) = ST_StartPoint(OLD.geom))) THEN
            -- get start intersection legs
            EXECUTE '
                SELECT  legs
                FROM ' || inttable || '
                WHERE   id = $1.intersection_from;'
            INTO    legs
            USING   OLD;

            IF legs > 1 THEN
                EXECUTE '
                    UPDATE ' || inttable || '
                    SET     legs = legs - 1
                    WHERE   id = $1.intersection_from;'
                USING   OLD;
            ELSE
                EXECUTE '
                    DELETE FROM ' || inttable || '
                    WHERE   id = $1.intersection_from;'
                USING   OLD;
            END IF;
        END IF;


        -------------------
        --   END POINT   --
        -------------------
        --do nothing if endpoint didn't change
        IF (TG_OP = 'DELETE' OR NOT (ST_EndPoint(NEW.geom) = ST_EndPoint(OLD.geom))) THEN
            -- get end intersection legs
            EXECUTE '
                SELECT  legs
                FROM ' || inttable || '
                WHERE   id = $1.intersection_to;'
            INTO    legs
            USING   OLD;

            IF legs > 1 THEN
                EXECUTE '
                    UPDATE ' || inttable || '
                    SET     legs = legs - 1
                    WHERE   id = $1.intersection_to;'
                USING   OLD;
            ELSE
                EXECUTE '
                    DELETE FROM ' || inttable || '
                    WHERE   id = $1.intersection_to;'
                USING   OLD;
            END IF;
        END IF;
    END IF;

    --re-enable triggers on the intersections table
    EXECUTE 'ALTER TABLE ' || inttable || ' ENABLE TRIGGER ALL;';

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdgUpdateIntersections() OWNER TO gis;
