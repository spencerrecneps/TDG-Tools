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

--create tdg schemas
CREATE SCHEMA IF NOT EXISTS generated AUTHORIZATION gis;
CREATE SCHEMA IF NOT EXISTS received AUTHORIZATION gis;
CREATE SCHEMA IF NOT EXISTS scratch AUTHORIZATION gis;

--drop tdg schemas from the extension so they get backed up
--ALTER EXTENSION TDG DROP SCHEMA generated;
--ALTER EXTENSION TDG DROP SCHEMA received;
--ALTER EXTENSION TDG DROP SCHEMA scratch;
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
CREATE OR REPLACE FUNCTION tdg.tdgUpdateBikeShareStations (
    system_table REGCLASS,
    system_name TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$

try:
    # For Python 3.0 and later
    from urllib.request import urlopen
except ImportError:
    # Fall back to Python 2's urllib2
    from urllib2 import urlopen

import json


def get_jsonparsed_data(url):
    """Receive the content of ``url``, parse it as JSON and return the
       object.
    """
    response = urlopen(url)
    data = unicode(response.read(), 'utf-8')
    return json.loads(data)


def createUniqueColumnName(colName, colList):
    name = str(colName)
    i = -1
    while name in colList:
        i += 1
        name = str(colName) + '_' + str(i)
    return name


def is_number(s):
    if s is None:
        return True
    if isinstance(s,bool):
        return False
    if isinstance(s,list):
        return False
    if isinstance(s,dict):
        return False
    try:
        float(s)
        return True
    except ValueError:
        return False


# switch to pythonic variable names
systemName = system_name
systemTable = system_table

# # set station infos
# systems = {
#     'seattle': {
#         'url': 'https://secure.prontocycleshare.com/data/stations.json',
#         'lat': 'la',
#         'lon': 'lo',
#         'tree': ['stations'],
#         'table': 'seattle_pronto'
#     },
#     'chicago': {
#         'url': 'https://www.divvybikes.com/stations/json',
#         'lat': 'latitude',
#         'lon': 'longitude',
#         'tree': ['stationBeanList'],
#         'table': 'chicago_divvy'
#     }
# }

systems = plpy.execute('select * from %s;' % plpy.quote_ident(systemTable))

stationData = None
for system in systems:
    if systemName is None or systemName == system.get('system_name'):
        try:
            plpy.info(u'Retreiving %s' % system.get('system_name'))

            # set vars
            tableName = system.get('table_name')
            bufferTableName = tableName + '_buffer'
            lat = system.get('lat')
            lon = system.get('lon')
            tree = system.get('tree')
            url = system.get('url')
            sourceSrid = system.get('source_srid')
            localSrid = system.get('local_srid')

            # set var for whether the table already exists
            tableCheck = plpy.execute(u'select * from tdgTableCheck(%s)' % plpy.quote_literal(tableName))
            exists = tableCheck[0].get('tdgtablecheck')

            # grab json from url and save as an object
            data = get_jsonparsed_data(url)

            # traverse tree to get station data
            branch = None
            trunk = data
            for i, limb in enumerate(tree):
                trunk = trunk.get(limb)
            stationData = trunk

            # set column types
            plpy.info(u'    -> Setting column types')
            columnTypes = {}
            for row in stationData:
                for col, val in row.iteritems():
                    if col in columnTypes:
                        if columnTypes.get(col) == 'integer':
                            if is_number(val):
                                if not isinstance(val, int):
                                    columnTypes[col] = 'float'
                            else:
                                columnTypes[col] = 'text'
                        else:
                            if not is_number(val):
                                columnTypes[col] = 'text'
                    else:
                        if is_number(val):
                            if isinstance(val,int):
                                columnTypes[col] = 'integer'
                            else:
                                columnTypes[col] = 'float'
                        else:
                            columnTypes[col] = 'text'

            if exists:
                plpy.info('    -> Removing indexes and pre-existing values from today (if applicable)')
                plpy.execute(u'delete from %s where retrieval_date = current_date' % plpy.quote_ident(tableName))
                plpy.execute(u'drop index if exists sidx_%s_geom' % tableName)
                plpy.execute(u'drop index if exists idx_%s_date' % tableName)
                plpy.info('    -> Deleting old buffers from %s' % bufferTableName)
                plpy.execute(u'truncate %s' % bufferTableName)
            else:
                # set up the create statement with all text columns
                plpy.info('    -> Building table %s' % tableName)
                sql = u'create table received.%s ( \
                    geom geometry(point,%d)' % (plpy.quote_ident(tableName), localSrid)
                sql += u',retrieval_date date'
                for col, colType in columnTypes.iteritems():
                    sql += u',%s text' % plpy.quote_ident(col)
                sql += u')'

                # create new table
                plpy.execute(sql)

                # create the buffer table
                plpy.info('    -> Building table %s' % bufferTableName)
                sql = u'create table generated.%s ( \
                    id serial primary key, \
                    geom geometry(multipolygon,%d))' % (plpy.quote_ident(bufferTableName), localSrid)
                plpy.execute(sql)

            # insert new values
            plpy.info(u'    -> Inserting data into %s' % tableName)
            values = u''
            cols = columnTypes.keys()
            cols.sort()
            sql = u'insert into received.%s (' % plpy.quote_ident(tableName)
            for col in cols:
                sql += '%s,' % plpy.quote_ident(col)
            sql = sql[:-1]
            sql += u') values '
            for row in stationData:
                sql += u'('
                for col in cols:
                    val = unicode(row.get(col))
                    val = val.encode('ascii','ignore')
                    sql += u"%s," % plpy.quote_nullable(val)
                sql = sql[:-1]
                sql += '),'
            sql = sql[:-1]
            plpy.execute(sql)

            if not exists:
                plpy.info('    -> Setting data types on columns')
                # now try to cast each column to its proper type, catching fails
                for col, colType in columnTypes.iteritems():
                    try:
                        sql = u'alter table %s ' % plpy.quote_ident(tableName)
                        sql += u'alter column %s ' % plpy.quote_ident(col)
                        sql += u'type %s ' % colType
                        sql += u'using %s::%s' % (plpy.quote_ident(col),colType)
                        plpy.execute(sql)
                    except:
                        plpy.info('error setting column types')

                # add id column and primary key
                idCol = createUniqueColumnName('id',cols)
                sql = u'alter table %s add column %s serial primary key' % (plpy.quote_ident(tableName),idCol)
                plpy.execute(sql)

            # set the geom
            sql = u'update %s set geom = st_transform(st_setSRID(st_makepoint(' % plpy.quote_ident(tableName)
            sql += u'%s,%s)' % (plpy.quote_ident(lon),plpy.quote_ident(lat))
            sql += u',%d)' % sourceSrid
            sql += u',%d) ' % localSrid
            sql += u'where geom is null'
            plpy.execute(sql)

            # set the retrieval dates
            sql = u'update %s set retrieval_date = current_date ' % plpy.quote_ident(tableName)
            sql += u'where retrieval_date is null '
            plpy.execute(sql)

            # set indexes
            plpy.execute(u'create index sidx_%s_geom on %s using gist (geom)' % (tableName,plpy.quote_ident(tableName)))
            plpy.execute(u'create index idx_%s_date on %s (retrieval_date)' % (tableName,plpy.quote_ident(tableName)))

            # create buffer
            plpy.info('Creating buffer in %s' % bufferTableName)
            sql = u'insert into generated.%s (geom) ' % bufferTableName
            sql += u'select st_multi(st_buffer(st_union(st_multi(st_buffer(geom,2640))),-1320)) '
            sql += u'from received.%s ' % tableName
            sql += u'where retrieval_date = current_date '
            plpy.execute(sql)

            # create view of latest data (if table doesn't already exist)
            if not exists:
                plpy.execute('drop view if exists received.%s_latest' % tableName)
                sql = u'create view received.%s_latest as ' % tableName
                sql += u'select * from %s ' % plpy.quote_ident(tableName)
                sql += u'where retrieval_date = '
                sql += u'(select max(retrieval_date) from %s)' % plpy.quote_ident(tableName)
                plpy.execute(sql)

            # update the input table with success and timestamp
            sql = u"update %s set retrieval_status='success' " % plpy.quote_ident(systemTable)
            sql += u', retrieval_time=current_timestamp '
            sql += u'where system_name = %s ' % plpy.quote_literal(system.get('system_name'))
            plpy.info(sql)
            plpy.execute(sql)

        except Exception, e:
            sql = u"update %s set retrieval_status='fail' " % plpy.quote_ident(systemTable)
            sql += u', retrieval_time=current_timestamp '
            sql += u'where system_name = %s ' % plpy.quote_literal(system.get('system_name'))
            plpy.execute(sql)
            plpy.info(u'Error on table %s: %s' % (tableName, e))


return True

$$ LANGUAGE plpythonu;
ALTER FUNCTION tdg.tdgUpdateBikeShareStations(REGCLASS,TEXT) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgGetPkColumn (input_table_ REGCLASS)
RETURNS TEXT AS $func$

DECLARE
    col TEXT;

BEGIN
    RAISE NOTICE 'Getting primary key column for %',input_table_;
    EXECUTE '
        SELECT a.attname
        FROM   pg_index i
        JOIN   pg_attribute a ON a.attrelid = i.indrelid
                             AND a.attnum = ANY(i.indkey)
        WHERE  i.indrelid = $1::regclass
        AND    i.indisprimary
        LIMIT  1;'
    USING   input_table_
    INTO    col;

    RAISE NOTICE '  -> column is %',col;

    RETURN col;

END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgGetPkColumn(REGCLASS) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgInsertStandardizedRoad(
    input_table_ REGCLASS,
    road_table_ REGCLASS,
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
    tdg_id_exists BOOLEAN;
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

    -- check for tdg_id field in source data
    tdg_id_exists := tdgColumnCheck(input_table_,'tdg_id');

    --copy features over
    BEGIN
        RAISE NOTICE 'Copying features to %', road_table_;
        --querytext := '';
        querytext := '   INSERT INTO ' || road_table_ || ' (geom';
        querytext := querytext || ',source_data';
        IF name_field_ IS NOT NULL THEN
            querytext := querytext || ',road_name';
            END IF;
        IF tdg_id_exists THEN
            querytext := querytext || ',tdg_id';
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
            querytext := querytext || ',r.' || quote_ident(name_field_);
            END IF;
        IF tdg_id_exists IS NOT NULL THEN
            querytext := querytext || ',r.tdg_id';
            END IF;
        IF func_field_ IS NOT NULL THEN
            querytext := querytext || ',r.' || quote_ident(func_field_);
            END IF;
        IF oneway_field_ IS NOT NULL THEN
            querytext := querytext || ',r.' || quote_ident(oneway_field_);
            END IF;
        IF speed_field_ IS NOT NULL THEN
            querytext := querytext || ',r.' || quote_ident(speed_field_);
            END IF;
        IF adt_field_ IS NOT NULL THEN
            querytext := querytext || ',r.' || quote_ident(adt_field_);
            END IF;
        IF z_from_field_ IS NOT NULL THEN
            querytext := querytext || ',r.' || quote_ident(z_from_field_);
            END IF;
        IF z_to_field_ IS NOT NULL THEN
            querytext := querytext || ',r.' || quote_ident(z_to_field_);
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
    REGCLASS,REGCLASS,TEXT,TEXT,TEXT,TEXT,TEXT,
    TEXT,TEXT,INTEGER[]) OWNER TO gis;
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
CREATE OR REPLACE FUNCTION tdg.tdgNetworkCostFromTime(
    road_table_ REGCLASS,
    speed_ FLOAT,
    feet_per_second_ BOOLEAN DEFAULT NULL,
    road_ids_ INTEGER[] DEFAULT NULL)
--populate cross-street data
RETURNS BOOLEAN AS $func$

DECLARE
    link_table REGCLASS;
    speed_fps FLOAT;

BEGIN
    raise notice 'PROCESSING:';

    IF speed_ = 0 THEN
        RETURN 'f';
    END IF;

    link_table = road_table_ || '_net_link';

    -- convert to feet per second if necessary
    IF feet_per_second_ IS NULL THEN
        speed_fps := speed_ * 5280 / 3600;
    ELSE
        speed_fps := speed_;
    END IF;

    IF road_ids_ IS NULL THEN
        EXECUTE '
            UPDATE  '||link_table||'
            SET     link_cost = ST_Length(r.geom) / $1
            FROM    '||road_table_||' r
            WHERE   r.road_id = '||link_table||'.road_id;'
        USING   speed_fps;
    ELSE
        EXECUTE '
            UPDATE  '||link_table||'
            SET     link_cost = ST_Length(r.geom) / $1
            FROM    '||road_table_||' r
            WHERE   r.road_id = '||link_table||'.road_id
            AND     r.road_id = ANY ($1);'
        USING   speed_fps,
                road_ids_;
    END IF;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgNetworkCostFromTime(REGCLASS,FLOAT,BOOLEAN,INTEGER[]) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgTableCheck (input_table_ TEXT)
RETURNS BOOLEAN AS $func$

DECLARE
    namecheck RECORD;

BEGIN
    RAISE NOTICE 'Checking % exists',input_table_;
    EXECUTE 'SELECT '||quote_literal(input_table_)||'::REGCLASS';
    RETURN 't';
EXCEPTION
    WHEN undefined_table THEN
        RETURN 'f';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgTableCheck(TEXT) OWNER TO gis;
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
                tdg_id TEXT,
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
                ft_int_lanes_rt_rad_mph INT,
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
                tf_int_lanes_rt_rad_mph INT,
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
    input_table_ REGCLASS,
    geom_column_ TEXT)
RETURNS BOOLEAN AS $func$

DECLARE
    srid INT;
    cols TEXT[];
    cols_text TEXT;

BEGIN
    -- get srid of the geom
    RAISE NOTICE 'Getting SRID of geometry';
    EXECUTE 'SELECT tdgGetSRID($1,$2);'
    USING   input_table_, geom_column_
    INTO    srid;

    IF srid IS NULL THEN
        RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', input_table_;
    END IF;
    RAISE NOTICE '  -----> SRID found %',srid;

    -- create temp table and copy features
    EXECUTE '
        CREATE TEMP TABLE tmp_multitosingle (LIKE '||input_table_||')
        ON COMMIT DROP;
    ';
    EXECUTE 'INSERT INTO tmp_multitosingle SELECT * FROM '||input_table_||';';

    -- delete from input_table_ and change geom type
    EXECUTE 'DELETE FROM '||input_table_||';';
    EXECUTE '
        ALTER TABLE '||input_table_||' ALTER COLUMN '||geom_column_||'
        TYPE geometry(linestring,'||srid::TEXT||');
    ';

    -- get column names and remove geom_column_
    EXECUTE 'SELECT ARRAY(SELECT * FROM tdgGetColumnNames($1,$2))'
    USING   input_table_, 'f'::BOOLEAN
    INTO    cols;
    cols_text := array_to_string(array_remove(cols, geom_column_),',');


    -- check if tdg_id column exists. if not, add it.
    IF tdgColumnCheck(input_table_,'tdg_id') THEN
        RAISE NOTICE 'Column tdg_id already exists';
        EXECUTE '
            ALTER TABLE '||input_table_||'
            ALTER COLUMN tdg_id TYPE TEXT,
            ALTER COLUMN tdg_id SET DEFAULT uuid_generate_v4()::TEXT,
            ALTER COLUMN tdg_id SET NOT NULL;
        ';
    ELSE
        RAISE NOTICE 'Creating column tdg_id';
        -- add tdg_id column
        EXECUTE '
            ALTER TABLE '||input_table_||'
            ADD COLUMN tdg_id TEXT NOT NULL DEFAULT uuid_generate_v4()::TEXT;
        ';
    END IF;

    -- copy back to input_table_
    EXECUTE '
        INSERT INTO '||input_table_||' (geom,'||cols_text||')
        SELECT  (ST_Dump('||geom_column_||')).geom, '||cols_text||'
        FROM    tmp_multitosingle;
    ';

    RETURN 't';

END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMultiToSingle(REGCLASS,TEXT) OWNER TO gis;
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
CREATE OR REPLACE FUNCTION tdg.tdgNetworkCostFromDistance(
    road_table_ REGCLASS,
    road_ids_ INTEGER[] DEFAULT NULL)
--populate cross-street data
RETURNS BOOLEAN AS $func$

DECLARE
    link_table REGCLASS;

BEGIN
    raise notice 'PROCESSING:';

    link_table = road_table_ || '_net_link';

    IF road_ids_ IS NULL THEN
        EXECUTE '
            UPDATE  '||link_table||'
            SET     link_cost = ST_Length(r.geom)
            FROM    '||road_table_||' r
            WHERE   r.road_id = '||link_table||'.road_id;';
    ELSE
        EXECUTE '
            UPDATE  '||link_table||'
            SET     link_cost = ST_Length(r.geom)
            FROM    '||road_table_||' r
            WHERE   r.road_id = '||link_table||'.road_id
            AND     r.road_id = ANY ($1);'
        USING   road_ids_;
    END IF;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgNetworkCostFromDistance(REGCLASS,INTEGER[]) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgCopyTable (
    input_table_ REGCLASS,
    table_ TEXT,
    schema_ TEXT DEFAULT NULL,
    overwrite_ BOOLEAN DEFAULT 'f'::BOOLEAN
)
RETURNS BOOLEAN AS $func$

DECLARE
    schema TEXT;
    table_name TEXT;
    table_check BOOLEAN;
    pk_col TEXT;

BEGIN
    -- get schema
    IF schema_ IS NULL THEN
        EXECUTE 'SELECT schema_name FROM tdg.tdgTableDetails($1)'
        USING   input_table_::TEXT
        INTO schema;
    ELSE
        schema := schema_;
    END IF;

    -- build full table name
    table_name := quote_ident(schema) || '.' || quote_ident(table_);

    -- deal with overwriting
    IF overwrite_ THEN
        EXECUTE 'DROP TABLE IF EXISTS '||table_name;
    ELSE
        -- test for existence of new table, error if exists
        IF tdg.tdgTableCheck(table_name) THEN
            RAISE EXCEPTION 'Table % already exists', table_name;
        END IF;
    END IF;

    -- create new table
    EXECUTE 'CREATE TABLE '||table_name||' (LIKE '||input_table_||' INCLUDING ALL)';
    EXECUTE 'INSERT INTO '||table_name||' SELECT * FROM '||input_table_;

    -- get pk column from source table and set on new table
    pk_col := tdg.tdgGetPkColumn(input_table_);
    --EXECUTE 'ALTER TABLE '||table_name||' ADD PRIMARY KEY ('||pk_col||')';

    -- set sequence on new table
    EXECUTE 'SELECT tdg.tdgMakeSequence($1)'
    USING   table_name;

    RETURN 't';

END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgCopyTable(REGCLASS, TEXT, TEXT, BOOLEAN) OWNER TO gis;
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
CREATE OR REPLACE FUNCTION tdg.tdgMakeSequence (
    input_table_ REGCLASS,
    column_ TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $func$

DECLARE
    table_name TEXT;
    column_name TEXT;
    seq_name TEXT;
    seq_max INTEGER;

BEGIN
    RAISE NOTICE 'Adding sequence to %',input_table_;

    -- get column if none given
    IF column_ IS NULL THEN
        RAISE NOTICE 'Getting column';
        column_name := tdg.tdgGetPkColumn(input_table_);
    ELSE
        column_name := column_;
    END IF;

    -- get table name
    RAISE NOTICE 'Getting base table name';
    EXECUTE 'SELECT table_name FROM tdg.tdgTableDetails($1)'
    USING   input_table_::TEXT
    INTO    table_name;

    -- build sequence name
    seq_name := table_name||'_'||column_name||'_seq';
    RAISE NOTICE 'Sequence name: %',seq_name;

    -- get maximum existing value
    RAISE NOTICE 'Getting current max value';
    EXECUTE 'SELECT MAX('||column_name||') FROM '||input_table_||';'
    INTO    seq_max;
    RAISE NOTICE 'Max value: %',seq_max::TEXT;
    seq_max := seq_max + 1;

    -- create sequence
    RAISE NOTICE 'Creating sequence';
    EXECUTE 'DROP SEQUENCE IF EXISTS '||seq_name||';';
    EXECUTE 'CREATE SEQUENCE '||seq_name||' START WITH '||seq_max::TEXT||';';

    -- assign as default on the column
    RAISE NOTICE 'Assigning sequence to column %',column_name;
    EXECUTE '
        ALTER TABLE '||input_table_||'
        ALTER COLUMN '||column_name||'
        SET DEFAULT nextval('||quote_literal(seq_name)||'::REGCLASS)';

    RETURN 't';

END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeSequence(REGCLASS,TEXT) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdgUpdateNetwork (input_table REGCLASS, rowids INT[])
RETURNS BOOLEAN AS $func$

DECLARE

BEGIN

RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgUpdateNetwork(REGCLASS,INT[]) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgMeldAzimuths(
    target_table_ REGCLASS,
    target_column_ TEXT,
    target_geom_ TEXT,
    source_table_ REGCLASS,
    source_column_ TEXT,
    source_geom_ TEXT,
    tolerance_ FLOAT,
    buffer_geom_ TEXT DEFAULT NULL,
    max_angle_diff_ INTEGER DEFAULT 15,
    line_start_ FLOAT DEFAULT 0.33,
    line_end_ FLOAT DEFAULT 0.67,
    only_nulls_ BOOLEAN DEFAULT 't',
    nullify_ BOOLEAN DEFAULT 'f'
)
RETURNS BOOLEAN AS $func$

DECLARE
    sql TEXT;
    target_srid INTEGER;
    source_srid INTEGER;
    buffer_srid INTEGER;
    temp_buffers BOOLEAN;
    target_pkid TEXT;
    source_pkid TEXT;

BEGIN
    raise notice 'PROCESSING:';

    -- check columns
    IF NOT tdgColumnCheck(target_table_,target_column_) THEN
        RAISE EXCEPTION 'Column % not found', target_column_;
    END IF;
    IF NOT tdgColumnCheck(target_table_,target_geom_) THEN
        RAISE EXCEPTION 'Column % not found', target_geom_;
    END IF;
    IF buffer_geom_ IS NOT NULL AND NOT tdgColumnCheck(target_table_,buffer_geom_) THEN
        RAISE EXCEPTION 'Column % not found', buffer_geom_;
    END IF;
    IF NOT tdgColumnCheck(source_table_,source_column_) THEN
        RAISE EXCEPTION 'Column % not found', source_column_;
    END IF;
    IF NOT tdgColumnCheck(source_table_,source_geom_) THEN
        RAISE EXCEPTION 'Column % not found', source_geom_;
    END IF;

    -- srid check
    BEGIN
        RAISE NOTICE 'Getting SRID of target geometry';
        target_srid := tdgGetSRID(target_table_,target_geom_);
        IF target_srid IS NULL THEN
            RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', target_table_;
        END IF;
        raise NOTICE '  -----> SRID found %',target_srid;

        RAISE NOTICE 'Getting SRID of source geometry';
        source_srid := tdgGetSRID(source_table_,source_geom_);
        IF source_srid IS NULL THEN
            RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', source_table_;
        END IF;
        raise NOTICE '  -----> SRID found %',source_srid;

        IF NOT target_srid = source_srid THEN
            RAISE EXCEPTION 'SRID on geometry columns do not match';
        END IF;

        IF buffer_geom_ IS NOT NULL THEN
            RAISE NOTICE 'Getting SRID of buffer geometry';
            buffer_srid := tdgGetSRID(target_table_,buffer_geom_);
            IF NOT target_srid = buffer_srid THEN
                RAISE EXCEPTION 'SRID on geometry columns do not match';
            END IF;
        END IF;
    END;

    -- get target and source pkid columns
    target_pkid := tdg.tdgGetPkColumn(target_table_);
    source_pkid := tdg.tdgGetPkColumn(source_table_);

    BEGIN
        -- set nulls
        IF nullify_ THEN
            EXECUTE '
                UPDATE  '||target_table_||'
                SET     '||target_column_||' = NULL';
        END IF;

        -- add buffer geom column
        IF buffer_geom_ IS NULL THEN
            temp_buffers := 't';
            RAISE NOTICE 'Buffering...';
            EXECUTE '
                ALTER TABLE '||target_table_||'
                ADD COLUMN  tmp_buffer_geom geometry(multipolygon,'||target_srid::TEXT||')';

            sql := '
                UPDATE  '||target_table_||'
                SET     tmp_buffer_geom = ST_Multi(
                            ST_Buffer(
                                '||target_geom_||',
                                '||tolerance_::TEXT||',
                                ''endcap=flat''
                            )
                        )';
            IF only_nulls_ THEN
                EXECUTE sql || ' WHERE '||target_column_||' IS NULL';
            ELSE
                EXECUTE sql;
            END IF;

            -- add buffer index
            RAISE NOTICE 'Indexing buffer...';
            EXECUTE '
                CREATE INDEX tsidx_meldgeom
                ON '||target_table_||'
                USING GIST (tmp_buffer_geom)';
            EXECUTE 'ANALYZE '||target_table_||' (tmp_buffer_geom)';

            buffer_geom_ := 'tmp_buffer_geom';
        ELSE
            temp_buffers := 'f';
        END IF;

        -- set up temp tables
        EXECUTE '
            CREATE TEMP TABLE tmp_meld_target_azis (
                id INTEGER PRIMARY KEY,
                azi FLOAT
            )
            ON COMMIT DROP';
        EXECUTE '
            INSERT INTO tmp_meld_target_azis (id, azi)
            SELECT  '||target_pkid||',
                    ST_Azimuth(
                        ST_LineInterpolatePoint(
                            '||target_geom_||',
                            '||line_start_::TEXT||'
                        ),
                        ST_LineInterpolatePoint(
                            '||target_geom_||',
                            '||line_end_::TEXT||'
                        )
                    )
            FROM    '||target_table_;
        EXECUTE '
            CREATE TEMP TABLE tmp_meld_source_azis (
                id INTEGER PRIMARY KEY,
                azi FLOAT
            )
            ON COMMIT DROP';
        EXECUTE '
            INSERT INTO tmp_meld_source_azis (id, azi)
            SELECT  '||source_pkid||',
                    ST_Azimuth(
                        ST_LineInterpolatePoint(
                            '||source_geom_||',
                            '||line_start_::TEXT||'
                        ),
                        ST_LineInterpolatePoint(
                            '||source_geom_||',
                            '||line_end_::TEXT||'
                        )
                    )
            FROM    '||source_table_;

        -- check for matches
        RAISE NOTICE 'Getting azimuth matches';
        sql := '
            UPDATE  '||target_table_||'
            SET     '||target_column_||' = (
                        SELECT      src.'||source_column_||'
                        FROM        '||source_table_||' src,
                                    tmp_meld_target_azis target_azi,
                                    tmp_meld_source_azis source_azi
                        WHERE       '||target_table_||'.'||target_pkid||' = target_azi.id
                        AND         src.'||source_pkid||' = source_azi.id
                        AND         ST_Intersects(
                                        '||target_table_||'.'||buffer_geom_||',
                                        src.'||source_geom_||'
                                    )
                        AND         abs(cos(source_azi.azi - target_azi.azi)) >= cos(radians('||max_angle_diff_||'))
                        ORDER BY    ST_Distance(
                                        ST_LineInterpolatePoint(
                                            '||target_table_||'.'||target_geom_||',
                                            '||line_start_::TEXT||'
                                        ),
                                        src.'||source_geom_||'
                                    ) + ST_Distance(
                                        ST_LineInterpolatePoint(
                                            '||target_table_||'.'||target_geom_||',
                                            '||line_end_::TEXT||'
                                        ),
                                        src.'||source_geom_||'
                                    ) ASC
                        LIMIT       1
                    )';

        IF only_nulls_ THEN
            EXECUTE sql || ' WHERE '||target_table_||'.'||target_column_||' IS NULL';
        ELSE
            EXECUTE sql;
        END IF;

        IF temp_buffers THEN
            -- drop temporary buffers
            RAISE NOTICE 'Dropping temporary buffers';
            EXECUTE 'ALTER TABLE '||target_table_||' DROP COLUMN tmp_buffer_geom';
        END IF;

        DROP TABLE IF EXISTS tmp_meld_target_azis;
        DROP TABLE IF EXISTS tmp_meld_source_azis;
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMeldAzimuths(REGCLASS,TEXT,TEXT,REGCLASS,TEXT,TEXT,FLOAT,
    TEXT,INTEGER,FLOAT,FLOAT,BOOLEAN,BOOLEAN) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgMeldBuffers(
    target_table_ REGCLASS,
    target_column_ TEXT,
    target_geom_ TEXT,
    source_table_ REGCLASS,
    source_column_ TEXT,
    source_geom_ TEXT,
    tolerance_ FLOAT,
    buffer_geom_ TEXT DEFAULT NULL,
    min_target_length_ FLOAT DEFAULT NULL,
    min_shared_length_pct_ FLOAT DEFAULT 0.9,
    nullify_ BOOLEAN DEFAULT 'f',
    only_nulls_ BOOLEAN DEFAULT 't'
)
RETURNS BOOLEAN AS $func$

DECLARE
    sql TEXT;
    target_srid INTEGER;
    source_srid INTEGER;
    buffer_srid INTEGER;
    temp_buffers BOOLEAN;

BEGIN
    raise notice 'PROCESSING:';

    -- set vars
    IF min_target_length_ IS NULL THEN
        min_target_length_ := tolerance_ * 2.4;
    END IF;

    -- check columns
    IF NOT tdgColumnCheck(target_table_,target_column_) THEN
        RAISE EXCEPTION 'Column % not found', target_column_;
    END IF;
    IF NOT tdgColumnCheck(target_table_,target_geom_) THEN
        RAISE EXCEPTION 'Column % not found', target_geom_;
    END IF;
    IF buffer_geom_ IS NOT NULL AND NOT tdgColumnCheck(target_table_,buffer_geom_) THEN
        RAISE EXCEPTION 'Column % not found', buffer_geom_;
    END IF;
    IF NOT tdgColumnCheck(source_table_,source_column_) THEN
        RAISE EXCEPTION 'Column % not found', source_column_;
    END IF;
    IF NOT tdgColumnCheck(source_table_,source_geom_) THEN
        RAISE EXCEPTION 'Column % not found', source_geom_;
    END IF;

    -- srid check
    BEGIN
        RAISE NOTICE 'Getting SRID of target geometry';
        target_srid := tdgGetSRID(target_table_,target_geom_);
        IF target_srid IS NULL THEN
            RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', target_table_;
        END IF;
        raise NOTICE '  -----> SRID found %',target_srid;

        RAISE NOTICE 'Getting SRID of source geometry';
        source_srid := tdgGetSRID(source_table_,source_geom_);
        IF source_srid IS NULL THEN
            RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', source_table_;
        END IF;
        raise NOTICE '  -----> SRID found %',source_srid;

        IF NOT target_srid = source_srid THEN
            RAISE EXCEPTION 'SRID on geometry columns do not match';
        END IF;

        IF buffer_geom_ IS NOT NULL THEN
            RAISE NOTICE 'Getting SRID of buffer geometry';
            buffer_srid := tdgGetSRID(target_table_,buffer_geom_);
            IF NOT target_srid = buffer_srid THEN
                RAISE EXCEPTION 'SRID on geometry columns do not match';
            END IF;
        END IF;
    END;

    BEGIN
        -- set nulls
        IF nullify_ THEN
            EXECUTE '
                UPDATE  '||target_table_||'
                SET     '||target_column_||' = NULL';
        END IF;

        -- add buffer geom column
        IF buffer_geom_ IS NULL THEN
            temp_buffers := 't';
            RAISE NOTICE 'Buffering...';
            EXECUTE '
                ALTER TABLE '||target_table_||'
                ADD COLUMN  tmp_buffer_geom geometry(multipolygon,'||target_srid::TEXT||')';

            sql := '
                UPDATE  '||target_table_||'
                SET     tmp_buffer_geom = ST_Multi(
                            ST_Buffer(
                                '||target_geom_||',
                                '||tolerance_::TEXT||',
                                ''endcap=flat''
                            )
                        )';
            IF only_nulls_ THEN
                EXECUTE sql || ' WHERE '||target_column_||' IS NULL';
            ELSE
                EXECUTE sql;
            END IF;

            -- add buffer index
            RAISE NOTICE 'Indexing buffer...';
            EXECUTE '
                CREATE INDEX tsidx_meldgeom
                ON '||target_table_||'
                USING GIST (tmp_buffer_geom)';
            EXECUTE 'ANALYZE '||target_table_||' (tmp_buffer_geom)';

            buffer_geom_ := 'tmp_buffer_geom';
        ELSE
            temp_buffers := 'f';
        END IF;

        -- check for matches
        RAISE NOTICE 'Getting buffer matches';
        sql := '
            UPDATE  '||target_table_||'
            SET     '||target_column_||' = (
                        SELECT      src.'||source_column_||'
                        FROM        '||source_table_||' src
                        WHERE       ST_Intersects(
                                        '||target_table_||'.'||buffer_geom_||',
                                        src.'||source_geom_||'
                                    )
                        AND         ST_Length(
                                        ST_Intersection(
                                            '||target_table_||'.'||buffer_geom_||',
                                            src.'||source_geom_||'
                                        )
                                    ) >= '||min_shared_length_pct_::FLOAT||' * ST_Length('||target_table_||'.'||target_geom_||')
                        ORDER BY    ST_Length(
                                        ST_Intersection(
                                            '||target_table_||'.'||buffer_geom_||',
                                            src.'||source_geom_||'
                                        )
                                    ) DESC
                        LIMIT       1
                    )
            WHERE   ST_Length('||target_table_||'.'||target_geom_||') > '||min_target_length_::TEXT;

        IF only_nulls_ THEN
            EXECUTE sql || ' AND '||target_table_||'.'||target_column_||' IS NULL';
        ELSE
            EXECUTE sql;
        END IF;

        IF temp_buffers THEN
            -- drop temporary buffers
            RAISE NOTICE 'Dropping temporary buffers';
            EXECUTE 'ALTER TABLE '||target_table_||' DROP COLUMN tmp_buffer_geom';
        END IF;
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMeldBuffers(REGCLASS,TEXT,TEXT,REGCLASS,TEXT,TEXT,FLOAT,
    TEXT,FLOAT,FLOAT,BOOLEAN,BOOLEAN) OWNER TO gis;
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
CREATE OR REPLACE FUNCTION tdgColumnCheck (input_table_ REGCLASS, column_name_ TEXT)
RETURNS BOOLEAN AS $func$

BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_attribute
        WHERE  attrelid = input_table_
        AND    attname = column_name_
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
            link_stress,
            geom)
        SELECT  road.road_id,
                $1,
                vertsf.vert_id,
                vertst.vert_id,
                road.ft_seg_stress,
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
            link_stress,
            geom)
        SELECT  road.road_id,
                $1,
                vertst.vert_id,
                vertsf.vert_id,
                road.tf_seg_stress,
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
    EXECUTE 'SELECT table_name FROM tdg.tdgTableDetails($1);'
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
CREATE OR REPLACE FUNCTION tdg.tdgGetColumnNames(
    input_table_ REGCLASS,
    with_pk_ BOOLEAN)
RETURNS SETOF TEXT AS $func$

BEGIN
    IF with_pk_ THEN
        RETURN QUERY EXECUTE '
            SELECT  quote_ident(a.attname::TEXT) AS col_nm
            FROM    pg_attribute a
            WHERE   a.attrelid = $1
            AND     a.attnum > 0
            AND     NOT a.attisdropped;'
        USING input_table_;
    ELSE
        RETURN QUERY EXECUTE '
            SELECT  quote_ident(a.attname::TEXT) AS col_nm
            FROM    pg_attribute a
            WHERE   a.attrelid = $1
            AND     a.attnum > 0
            AND     NOT a.attisdropped
            AND     NOT EXISTS (
                        SELECT  1
                        FROM    pg_index i
                        WHERE   a.attrelid = i.indrelid
                        AND     a.attnum = ANY(i.indkey)
            );'
        USING input_table_;
    END IF;

END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgGetColumnNames(REGCLASS,BOOLEAN) OWNER TO gis;
CREATE OR REPLACE FUNCTION tdg.tdgCompareLines(
    base_geom_ geometry,
    comp_geom_ geometry,
    seg_length_ FLOAT
)
RETURNS FLOAT AS $func$

DECLARE
    base_length FLOAT;
    num_points INTEGER;
    avg_dist FLOAT;

BEGIN
    base_length := ST_Length(base_geom_);
    num_points := CEILING(base_length::FLOAT/seg_length_);

    avg_dist := AVG(
                    ST_Distance(
                        ST_LineInterpolatePoint(base_geom_,i::FLOAT * seg_length_ / base_length),
                        -- comp_geom_
                        ST_LineInterpolatePoint(
                            comp_geom_,
                            ST_LineLocatePoint(
                                comp_geom_,
                                ST_LineInterpolatePoint(base_geom_,i::FLOAT * seg_length_ / base_length)
                            )
                        )
                    )
                )
    FROM        generate_series(0,num_points) i
    WHERE       i * seg_length_ <= base_length;

    RETURN avg_dist;
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgCompareLines(geometry,geometry,FLOAT) OWNER TO gis;
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
    EXECUTE 'SELECT table_name FROM tdg.tdgTableDetails($1);'
    USING   road_table_::TEXT
    INTO    table_name;

    raise notice 'Creating indices on: %', road_table_;

    EXECUTE format('
        CREATE INDEX sidx_%s_geom ON %s USING GIST(geom);
        CREATE INDEX idx_%s_oneway ON %s (one_way);
        CREATE INDEX idx_%s_tdgid ON %s (tdg_id);
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
CREATE OR REPLACE FUNCTION tdg.tdgGetSRID(input_table_ REGCLASS,geom_column_ TEXT)
RETURNS INT AS $func$

DECLARE
    geomdetails RECORD;

BEGIN
    EXECUTE '
        SELECT  ST_SRID('|| geom_column_ || ') AS srid
        FROM    ' || input_table_ || '
        WHERE   $1 IS NOT NULL LIMIT 1'
    USING   --geom_column_,
            --input_table_,
            geom_column_
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
                AND     ft_int_lanes_rt_rad_mph <= 15
                AND     ft_int_lanes_bike_straight = 1;
                UPDATE  %s
                SET     ft_int_stress = 3
                WHERE   COALESCE(ft_int_lanes_bike_wd_ft,0) >= 4
                AND     COALESCE(ft_int_lanes_rt_len_ft,0) > 0
                AND     ft_int_lanes_rt_rad_mph <= 20
                AND     ft_int_lanes_bike_straight = 1
                AND     ft_int_stress IS NOT NULL;
                UPDATE  %s
                SET     ft_int_stress = 3
                WHERE   COALESCE(ft_int_lanes_bike_wd_ft,0) >= 4
                AND     ft_int_lanes_rt_rad_mph <= 15
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
                AND     tf_int_lanes_rt_rad_mph <= 15
                AND     tf_int_lanes_bike_straight = 1;
                UPDATE  %s
                SET     tf_int_stress = 3
                WHERE   COALESCE(tf_int_lanes_bike_wd_ft,0) >= 4
                AND     COALESCE(tf_int_lanes_rt_len_ft,0) > 0
                AND     tf_int_lanes_rt_rad_mph <= 20
                AND     tf_int_lanes_bike_straight = 1
                AND     tf_int_stress IS NOT NULL;
                UPDATE  %s
                SET     tf_int_stress = 3
                WHERE   COALESCE(tf_int_lanes_bike_wd_ft,0) >= 4
                AND     tf_int_lanes_rt_rad_mph <= 15
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
CREATE OR REPLACE FUNCTION tdg.tdgMeld(
    target_table_ REGCLASS,
    target_column_ TEXT,
    target_geom_ TEXT,
    source_table_ REGCLASS,
    source_column_ TEXT,
    source_geom_ TEXT,
    tolerance_ FLOAT,
    buffer_search_ DEFAULT 't',
    azimuth_search DEFAULT 't',
    midpoint_search DEFAULT 't',
    only_nulls_ BOOLEAN DEFAULT 't',
    min_target_length_ FLOAT DEFAULT NULL,
    min_shared_length_pct_ FLOAT DEFAULT 0.9,
)
RETURNS BOOLEAN AS $func$

DECLARE
    sql TEXT;
    target_srid INTEGER;
    source_srid INTEGER;

BEGIN
    raise notice 'PROCESSING:';

    -- set vars
    IF min_target_length_ IS NULL THEN
        min_target_length_ := tolerance_ * 2.4;
    END IF;

    -- check columns
    IF NOT tdgColumnCheck(target_table_,target_column_) THEN
        RAISE EXCEPTION 'Column % not found', target_column_;
    END IF;
    IF NOT tdgColumnCheck(target_table_,target_geom_) THEN
        RAISE EXCEPTION 'Column % not found', target_geom_;
    END IF;
    IF NOT tdgColumnCheck(source_table_,source_column_) THEN
        RAISE EXCEPTION 'Column % not found', source_column_;
    END IF;
    IF NOT tdgColumnCheck(source_table_,source_geom_) THEN
        RAISE EXCEPTION 'Column % not found', source_geom_;
    END IF;

    -- srid check
    BEGIN
        RAISE NOTICE 'Getting SRID of target geometry';
        EXECUTE 'SELECT tdgGetSRID($1,$2);'
        USING   target_table_,
                target_geom_
        INTO    target_srid;

        IF target_srid IS NULL THEN
            RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', target_table_;
        END IF;
        raise NOTICE '  -----> SRID found %',target_srid;

        RAISE NOTICE 'Getting SRID of source geometry';
        EXECUTE 'SELECT tdgGetSRID($1,$2);'
        USING   source_table_,
                source_geom_
        INTO    source_srid;

        IF source_srid IS NULL THEN
            RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', source_table_;
        END IF;
        raise NOTICE '  -----> SRID found %',source_srid;

        IF NOT target_srid = source_srid THEN
            RAISE EXCEPTION 'SRID on geometry columns do not match';
        END IF;
    END;

    -- buffer search
    BEGIN
        -- add buffer geom column
        RAISE NOTICE 'Buffering...';
        EXECUTE '
            ALTER TABLE '||target_table_||'
            ADD COLUMN  tmp_buffer_geom geometry(multipolygon,'||target_srid::TEXT||')';

        sql := '
            UPDATE  '||target_table_||'
            SET     tmp_buffer_geom = ST_Multi(
                        ST_Buffer(
                            '||target_geom_||',
                            '||tolerance_::TEXT||',
                            ''endcap=flat''
                        )
                    )';
        IF only_nulls_ THEN
            EXECUTE sql || ' WHERE '||target_column_||' IS NULL';
        ELSE
            EXECUTE sql;
        END IF;

        -- add buffer index
        RAISE NOTICE 'Indexing buffer...';
        EXECUTE '
            CREATE INDEX tsidx_meldgeom
            ON '||target_table_||'
            USING GIST (tmp_buffer_geom)';
        EXECUTE 'ANALYZE '||target_table_||' (tmp_buffer_geom)';

        -- check for matches
        RAISE NOTICE 'Getting first-pass matches';
        sql := '
            UPDATE  '||target_table_||'
            SET     '||target_column_||' = (
                        SELECT      src.'||source_column_||'
                        FROM        '||source_table_||' src
                        WHERE       ST_Intersects(
                                        tmp_buffer_geom,
                                        src.'||source_geom_||'
                                    )
                        AND         ST_Length(
                                        ST_Intersection(
                                            tmp_buffer_geom,
                                            src.'||source_geom_||'
                                        )
                                    ) >= '||min_shared_length_pct_::FLOAT||' * ST_Length('||target_table_||'.'||target_geom_||')
                        ORDER BY    ST_Length(
                                        ST_Intersection(
                                            tmp_buffer_geom,
                                            src.'||source_geom_||'
                                        )
                                    ) DESC
                        LIMIT       1
                    )
            WHERE   ST_Length('||target_table_||'.'||target_geom_||') > '||min_target_length_::TEXT;

        IF only_nulls_ THEN
            EXECUTE sql || ' AND '||target_table_||'.'||target_column_||' IS NULL';
        ELSE
            EXECUTE sql;
        END IF;

        -- drop temporary buffers
        RAISE NOTICE 'Dropping temporary buffers';
        EXECUTE 'ALTER TABLE '||target_table_||' DROP COLUMN tmp_buffer_geom';
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMeld(REGCLASS,TEXT,TEXT,REGCLASS,TEXT,TEXT,FLOAT,
    BOOLEAN,FLOAT,FLOAT,BOOLEAN,BOOLEAN) OWNER TO gis;
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

    -- remove obsolete intersections
    EXECUTE '
        DELETE FROM '||int_table||'
        WHERE NOT EXISTS (  SELECT  1
                            FROM    '||road_table||' roads
                            WHERE   '||int_table||'.int_id = roads.intersection_from
                            OR      '||int_table||'.int_id = roads.intersection_to);';

    -- update legs on intersections
    PERFORM tdgSetIntersectionLegs(int_table,road_table,int_ids);

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
