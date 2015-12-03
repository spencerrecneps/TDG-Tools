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
            lat = system.get('lat')
            lon = system.get('lon')
            tree = system.get('tree')
            url = system.get('url')
            srid = system.get('srid')

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
            else:
                # set up the create statement with all text columns
                plpy.info('    -> Building table')
                sql = u'create table received.%s ( \
                    geom geometry(point,%d)' % (plpy.quote_ident(tableName), srid)
                sql += u',retrieval_date date'
                for col, colType in columnTypes.iteritems():
                    sql += u',%s text' % plpy.quote_ident(col)
                sql += u')'

                # create new table
                plpy.execute(sql)

            # insert new values
            plpy.info(u'    -> Inserting data')
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
            sql = u'update %s set geom = st_setSRID(st_makepoint(' % plpy.quote_ident(tableName)
            sql += u'%s,%s)' % (plpy.quote_ident(lon),plpy.quote_ident(lat))
            sql += u',%d) ' % srid
            sql += u'where geom is null'
            plpy.execute(sql)

            # set the retrieval dates
            sql = u'update %s set retrieval_date = current_date ' % plpy.quote_ident(tableName)
            sql += u'where retrieval_date is null '
            plpy.execute(sql)

            # set indexes
            plpy.execute(u'create index sidx_%s_geom on %s using gist (geom)' % (tableName,plpy.quote_ident(tableName)))
            plpy.execute(u'create index idx_%s_date on %s (retrieval_date)' % (tableName,plpy.quote_ident(tableName)))

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
            plpy.execute(u"update %s set retrieval_status='fail', retrieval_time=current_timestamp;" % plpy.quote_ident(systemTable))
            plpy.info(u'Error on table %s: %s' % (tableName, e))


return True

$$ LANGUAGE plpythonu;
ALTER FUNCTION tdg.tdgUpdateBikeShareStations(REGCLASS,TEXT) OWNER TO gis;
