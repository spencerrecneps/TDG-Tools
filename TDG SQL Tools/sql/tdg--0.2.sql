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
CREATE OR REPLACE FUNCTION tdg.tdgGenerateCrossStreetData(road_table_ REGCLASS)
--populate cross-street data
RETURNS BOOLEAN AS $func$

DECLARE
    int_table REGCLASS;

BEGIN
    raise notice 'PROCESSING:';

    int_table = road_table_ || '_intersections';

    RAISE NOTICE 'Clearing old values';
    EXECUTE '
        UPDATE ' || road_table_ || ' SET road_from = NULL, road_to = NULL;';

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
        AND     '||road_table_||'.road_id != r.road_id;';
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
        AND     '||road_table_||'.road_id != r.road_id;';

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
        )
        UPDATE  '||road_table_||'
        SET     road_from = (   SELECT      x.road_name
                                FROM        x
                                WHERE       '||road_table_||'.road_id = x.this_id
                                ORDER BY    ABS(SIN(RADIANS(MOD(360 + x.xing_azi - x.this_azi,360)))) DESC
                                LIMIT       1)';
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
        )
        UPDATE  '||road_table_||'
        SET     road_to = (     SELECT      x.road_name
                                FROM        x
                                WHERE       '||road_table_||'.road_id = x.this_id
                                ORDER BY    ABS(SIN(RADIANS(MOD(360 + x.xing_azi - x.this_azi,360)))) DESC
                                LIMIT       1)';

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgGenerateCrossStreetData(REGCLASS) OWNER TO gis;
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
        RAISE NOTICE 'Getting table details for %',input_table;
        EXECUTE '   SELECT  schema_name, table_name
                    FROM    tdgTableDetails($1)'
        USING   input_table
        INTO    schema_name, table_name;

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
CREATE OR REPLACE FUNCTION tdg.tdgUpdateIntersections(
    road_table_ REGCLASS,
    int_table_ REGCLASS
)
RETURNS BOOLEAN
AS $BODY$

--------------------------------------------------------------------------
-- This function update road and intersection information based on
-- a set of road_ids passed in as an array.
--------------------------------------------------------------------------

BEGIN
    --suspend triggers on the intersections table so that our
    --changes are not ignored.
    EXECUTE 'ALTER TABLE ' || int_table_ || ' DISABLE TRIGGER ALL;';

    --update intersection leg count
    BEGIN
        RAISE NOTICE 'Updating intersections';

        --update intersection leg counts
        EXECUTE '
            UPDATE  '||int_table_||'
            SET     legs = (SELECT  COUNT(roads.road_id)
                            FROM    '||road_table_||' roads
                            WHERE   '||int_table_||'.int_id
                                        IN (roads.intersection_from,roads.intersection_to))
            WHERE   int_id IN ( SELECT new_int_from FROM tmp_roadgeomchange
                                UNION
                                SELECT new_int_to FROM tmp_roadgeomchange
                                UNION
                                SELECT old_int_from FROM tmp_roadgeomchange
                                UNION
                                SELECT old_int_to FROM tmp_roadgeomchange);';
    END;

    --delete intersections with no legs
    EXECUTE 'DELETE FROM ' || int_table_ || ' WHERE legs < 1;';

    --re-enable triggers on the intersections table
    EXECUTE 'ALTER TABLE ' || int_table_ || ' ENABLE TRIGGER ALL;';

    RETURN 't';
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgUpdateIntersections(REGCLASS,REGCLASS) OWNER TO gis;
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
        EXECUTE 'DROP TABLE IF EXISTS ' || road_table || ';';
        EXECUTE 'DROP TABLE IF EXISTS ' || intersection_table || ';';
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

    BEGIN
        IF z_from_field_ IS NOT NULL AND z_to_field_ IS NOT NULL THEN
            PERFORM tdgMakeIntersections(road_table::REGCLASS,'t'::BOOLEAN);
        ELSE
            PERFORM tdgMakeIntersections(road_table::REGCLASS,'f'::BOOLEAN);
        END IF;

    END;

    --intersection indexes
    BEGIN
        EXECUTE format('
            CREATE INDEX idx_%s_intfrom ON %s (intersection_from);
            CREATE INDEX idx_%s_intto ON %s (intersection_to);
            ',  output_table_name_,
                road_table,
                output_table_name_,
                road_table);
    END;

    BEGIN
        EXECUTE format('ANALYZE %s;',road_table);
    END;

    --not null on intersections
    BEGIN
        EXECUTE format('
            ALTER TABLE %s ALTER COLUMN intersection_from SET NOT NULL;
            ALTER TABLE %s ALTER COLUMN intersection_to SET NOT NULL;
            ',  road_table,
                road_table);
    END;

    --triggers
    BEGIN
    -- refer to http://stackoverflow.com/questions/27837511/how-to-properly-emulate-statement-level-triggers-with-access-to-data-in-postgres
        --------------------
        --road geom changes
        --------------------
        -- create temp table
        EXECUTE format('
            CREATE TRIGGER tr_tdg%sGeomUpdateTable
                BEFORE UPDATE OF geom, z_from, z_to ON %s
                FOR EACH STATEMENT
                EXECUTE PROCEDURE tdgRoadGeomChangeTable();
            ',  output_table_name_,
                output_table_name_);
        -- populate with vals
        EXECUTE format('
            CREATE TRIGGER tr_tdg%sGeomUpdateVals
                BEFORE UPDATE OF geom, z_from, z_to ON %s
                FOR EACH ROW
                EXECUTE PROCEDURE tdgRoadGeomChangeVals();
            ',  output_table_name_,
                output_table_name_);
        -- update intersections
        EXECUTE format('
            CREATE TRIGGER tr_tdg%sGeomUpdateIntersections
                AFTER UPDATE OF geom, z_from, z_to ON %s
                FOR EACH STATEMENT
                EXECUTE PROCEDURE tdgRoadGeomUpdate();
            ',  output_table_name_,
                output_table_name_);
        --------------------
        --road insert/delete
        --------------------
        -- create temp table
        EXECUTE format('
            CREATE TRIGGER tr_tdg%sGeomAddDelTable
                BEFORE INSERT OR DELETE ON %s
                FOR EACH STATEMENT
                EXECUTE PROCEDURE tdgRoadGeomChangeTable();
            ',  output_table_name_,
                output_table_name_);
        -- populate with vals
        EXECUTE format('
            CREATE TRIGGER tr_tdg%sGeomAddDelVals
                BEFORE INSERT OR DELETE ON %s
                FOR EACH ROW
                EXECUTE PROCEDURE tdgRoadGeomChangeVals();
            ',  output_table_name_,
                output_table_name_);
        -- update intersections
        EXECUTE format('
            CREATE TRIGGER tr_tdg%sGeomAddDelIntersections
                AFTER INSERT OR DELETE ON %s
                FOR EACH STATEMENT
                EXECUTE PROCEDURE tdgRoadGeomUpdate();
            ',  output_table_name_,
                output_table_name_);
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgStandardizeRoadLayer(
    REGCLASS,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,
    TEXT,TEXT,TEXT,BOOLEAN,BOOLEAN) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgMakeIntersections (
    input_table_ REGCLASS,
    z_vals_ BOOLEAN DEFAULT 'f')
RETURNS BOOLEAN AS $func$

DECLARE
    namecheck RECORD;
    schema_name TEXT;
    table_name TEXT;
    inttable text;
    sridinfo record;
    srid INT;

BEGIN
    RAISE NOTICE 'PROCESSING:';

    --check table and schema
    BEGIN
        RAISE NOTICE 'Getting table details for %',input_table_;
        EXECUTE '   SELECT  schema_name, table_name
                    FROM    tdgTableDetails($1::TEXT)'
        USING   input_table_
        INTO    schema_name, table_name;

        inttable = schema_name || '.' || table_name || '_intersections';
    END;

    --get srid of the geom
    BEGIN
        RAISE NOTICE 'Getting SRID of geometry';
        EXECUTE 'SELECT tdgGetSRID($1,$2);'
        USING   input_table_,
                'geom'
        INTO    srid;

        IF srid IS NULL THEN
            RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', table_name;
        END IF;
        raise NOTICE '  -----> SRID found %',srid;
    END;

    BEGIN
        RAISE NOTICE 'creating intersection table';
        EXECUTE format('
            CREATE TABLE %s (   int_id serial PRIMARY KEY,
                                geom geometry(point,%L),
                                z_elev INT NOT NULL DEFAULT 0,
                                legs INT,
                                signalized BOOLEAN);
            ',  inttable,
                srid);
    END;

    --add intersections to table
    BEGIN
        RAISE NOTICE 'adding intersections';

        EXECUTE '
            CREATE TEMP TABLE v (i INT, z INT, geom geometry(POINT,'||srid::TEXT||'))
            ON COMMIT DROP;
            INSERT INTO v (i, z, geom)
                SELECT      road_id, z_from, ST_StartPoint(geom)
                FROM        ' || input_table_ || '
                ORDER BY    road_id ASC;
            INSERT INTO v (i, z, geom)
                SELECT      road_id, z_to, ST_EndPoint(geom)
                FROM        ' || input_table_ || '
                ORDER BY    road_id ASC;
            INSERT INTO ' || inttable || ' (legs, z_elev, geom)
                SELECT      COUNT(i), COALESCE(z,0), geom
                FROM        v
                GROUP BY    COALESCE(z,0), geom;';
    END;

    EXECUTE format('ANALYZE %s;', inttable);

    -- add intersection data to roads
    BEGIN
        RAISE NOTICE 'populating intersection data in roads table';
        EXECUTE format('
            UPDATE  %s
            SET     intersection_from = if.int_id,
                    intersection_to = it.int_id
            FROM    %s if,
                    %s it
            WHERE   ST_StartPoint(%s.geom) = if.geom
            AND     %s.z_from = if.z_elev
            AND     ST_EndPoint(%s.geom) = it.geom
            AND     %s.z_to = it.z_elev;
            ',  input_table_,
                inttable,
                inttable,
                input_table_,
                input_table_,
                input_table_,
                input_table_);
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
ALTER FUNCTION tdg.tdgMakeIntersections(REGCLASS,BOOLEAN) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdgGenerateIntersectionStreets (input_table REGCLASS, intids INT[])
RETURNS BOOLEAN AS $func$

DECLARE

BEGIN

RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgGenerateIntersectionStreets(REGCLASS, INT[]) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgUpdateIntersections(
    road_table_ REGCLASS,
    int_table_ REGCLASS,
    road_ids_ INTEGER[]
)
RETURNS BOOLEAN
AS $BODY$

--------------------------------------------------------------------------
-- This function update road and intersection information based on
-- a set of road_ids passed in as an array.
--------------------------------------------------------------------------

DECLARE
    int_ids INTEGER[];

BEGIN
    --suspend triggers on the intersections table so that our
    --changes are not ignored.
    EXECUTE 'ALTER TABLE ' || int_table_ || ' DISABLE TRIGGER ALL;';

    --identify affected intersections
    EXECUTE '
        SELECT
            ARRAY(
                SELECT  intersection_from
                FROM  ' || road_table_ || '
                WHERE road_id = ANY ($1)
            ) ||
            ARRAY(
                SELECT  intersection_to
                FROM  ' || road_table_ || '
                WHERE road_id = ANY ($1)
            );'
    INTO    int_ids
    USING   road_ids_;
    RAISE NOTICE 'Identified intersections: %', int_ids;

    --update intersection leg count
    BEGIN
        RAISE NOTICE 'Updating intersections';

        --road start points first
        EXECUTE '
            UPDATE  ' || int_table_ || '
            SET legs = (SELECT  COUNT(road_id)
                        FROM  ' || road_table_ || ' r
                        WHERE ' || int_table_ || '.geom = ST_StartPoint(r.geom)
                        AND   ' || int_table_ || '.z_elev = r.z_from)
            WHERE ' || int_table_ || '.int_id = ANY ($1);'
        USING   int_ids;
        --road end points next
        EXECUTE '
            UPDATE  ' || int_table_ || '
            SET legs = legs + ( SELECT  COUNT(road_id)
                                FROM  ' || road_table_ || ' r
                                WHERE ' || int_table_ || '.geom = ST_EndPoint(r.geom)
                                AND   ' || int_table_ || '.z_elev = r.z_to)
            WHERE ' || int_table_ || '.int_id = ANY ($1);'
        USING   int_ids;
    END;

    --update from/to intersections on roads
    BEGIN
        RAISE NOTICE 'Updating road intersection info';

        --road start points first
        EXECUTE '
            UPDATE  ' || road_table_ || '
            SET intersection_from = ints.int_id
            FROM    ' || int_table_ || ' ints
            WHERE   ' || road_table_ || '.road_id = ANY ($1)
            AND     ST_StartPoint(' || road_table_ || '.geom) = ints.geom
            AND     ' || road_table_ || '.z_from = ints.z_elev;'
        USING   road_ids_;
        --road end points next
        EXECUTE '
            UPDATE  ' || road_table_ || '
            SET intersection_to = ints.int_id
            FROM    ' || int_table_ || ' ints
            WHERE   ' || road_table_ || '.road_id = ANY ($1)
            AND     ST_EndPoint(' || road_table_ || '.geom) = ints.geom
            AND     ' || road_table_ || '.z_to = ints.z_elev;'
        USING   road_ids_;
    END;

    --re-enable triggers on the intersections table
    EXECUTE 'ALTER TABLE ' || int_table_ || ' ENABLE TRIGGER ALL;';

    RETURN 't';
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgUpdateIntersections(REGCLASS,REGCLASS,INTEGER[]) OWNER TO gis;
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
CREATE OR REPLACE FUNCTION tdg.tdgTableDetails(input_table TEXT)
RETURNS TABLE (schema_name TEXT, table_name TEXT) AS $func$

BEGIN
    RETURN QUERY EXECUTE '
        SELECT  nspname::TEXT, relname::TEXT
        FROM    pg_namespace n JOIN pg_class c ON n.oid = c.relnamespace
        WHERE   c.oid = ' || quote_literal(input_table) || '::REGCLASS';

EXCEPTION
    WHEN undefined_table THEN
        RETURN;
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgTableDetails(TEXT) OWNER TO gis;




-- CREATE OR REPLACE FUNCTION tdgTableDetails(input_table TEXT)
-- RETURNS TABLE (schema_name TEXT, table_name TEXT) AS $func$
--
-- BEGIN
--     RETURN QUERY EXECUTE '
--         SELECT  nspname::TEXT, relname::TEXT
--         FROM    pg_namespace n JOIN pg_class c ON n.oid = c.relnamespace
--         WHERE   c.oid = to_regclass(' || quote_literal(input_table) || ')';
-- END $func$ LANGUAGE plpgsql;
-- ALTER FUNCTION tdgTableDetails(TEXT) OWNER TO gis;
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

        INSERT INTO tmp_roadgeomchange (
            road_id,
            old_int_from,
            old_int_to)
        VALUES (
            OLD.road_id,
            OLD.intersection_from,
            OLD.intersection_to);
    ELSEIF TG_OP = 'INSERT' THEN
        NEW.geom := ST_SnapToGrid(NEW.geom,2);

        INSERT INTO tmp_roadgeomchange (road_id)
        VALUES (NEW.road_id);
    ELSEIF TG_OP = 'DELETE' THEN
        INSERT INTO tmp_roadgeomchange (
            road_id,
            old_int_from,
            old_int_to)
        VALUES (
            OLD.road_id,
            OLD.intersection_from,
            OLD.intersection_to);
        RETURN OLD;
    END IF;

    --suspend triggers on the intersections table so that our
    --changes are not ignored.
    EXECUTE 'ALTER TABLE ' || int_table || ' DISABLE TRIGGER ALL;';

    --add new intersections
    IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
        --startpoint
        EXECUTE '
            SELECT  1
            FROM    '||int_table||' i
            WHERE   i.geom = ST_StartPoint($1)
            AND     i.z_elev = $2;'
        USING   NEW.geom,
                NEW.z_from;
        GET DIAGNOSTICS i = ROW_COUNT;
        IF i = 0 THEN
            EXECUTE 'INSERT INTO '||int_table||' (geom) SELECT ST_StartPoint($1);'
            USING   NEW.geom;
        END IF;

        --endpoint
        EXECUTE '
            SELECT  1
            FROM    '||int_table||' i
            WHERE   i.geom = ST_EndPoint($1)
            AND     i.z_elev = $2;'
        USING   NEW.geom,
                NEW.z_to;
        GET DIAGNOSTICS i = ROW_COUNT;
        IF i = 0 THEN
            EXECUTE 'INSERT INTO '||int_table||' (geom) SELECT ST_EndPoint($1);'
            USING   NEW.geom;
        END IF;

        --re-enable triggers on the intersections table
        EXECUTE 'ALTER TABLE ' || int_table || ' ENABLE TRIGGER ALL;';

        --assign intersections to road
        EXECUTE '
            UPDATE  tmp_roadgeomchange
            SET     new_int_from = (SELECT  int_id
                                    FROM    '||int_table||' i
                                    WHERE   ST_StartPoint($1) = i.geom
                                    AND     $2 = i.z_elev),
                    new_int_to = (  SELECT  int_id
                                            FROM    '||int_table||' i
                                            WHERE   ST_EndPoint($1) = i.geom
                                            AND     $3 = i.z_elev)
            WHERE   tmp_roadgeomchange.road_id = $4;'
        USING   NEW.geom,
                NEW.z_from,
                NEW.z_to,
                NEW.road_id;

        --set new from intersection
        EXECUTE 'SELECT new_int_from FROM tmp_roadgeomchange WHERE road_id = $1'
        USING   NEW.road_id
        INTO    NEW.intersection_from;

        --set new to intersection
        EXECUTE 'SELECT new_int_to FROM tmp_roadgeomchange WHERE road_id = $1'
        USING   NEW.road_id
        INTO    NEW.intersection_to;

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

BEGIN
    --get the intersection and road tables
    road_table := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME;
    int_table := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME || '_intersections';

    PERFORM tdgUpdateIntersections(road_table,int_table);

    DROP TABLE tmp_roadgeomchange;

    RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgRoadGeomUpdate() OWNER TO gis;
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
        CREATE TEMPORARY TABLE tmp_roadgeomchange (
            road_id INTEGER,
            old_int_from INTEGER,
            new_int_from INTEGER,
            old_int_to INTEGER,
            new_int_to INTEGER
        )
        ON COMMIT DROP;';

    RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgRoadGeomChangeTable() OWNER TO gis;
