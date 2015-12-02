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
        plpy.info(u'Retreiving %s' % system.get('system_name'))

        # grab json from url and save as an object
        data = get_jsonparsed_data(system.get('url'))

        # traverse tree to get station data
        branch = None
        trunk = data
        for i, limb in enumerate(system.get('tree')):
            trunk = trunk.get(limb)
        stationData = trunk

        # # drop existing table
        # plpy.execute(u'drop table if exists %s' % system.get('table_name'))

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

        # set up the create statement with all text columns
        plpy.info('    -> Building table')
        sql = u'create table received.%s ( \
            geom geometry(point,%d)' % (plpy.quote_ident(system.get('table_name')), system.get('srid'))
        sql += u',retrieval_date date'
        for col, colType in columnTypes.iteritems():
            sql += u',%s text' % plpy.quote_ident(col)
        sql += u')'

        # drop old table if exists
        # plpy.execute(u'drop table if exists %s' % plpy.quote_ident(system.get('table_name')))
        # delete any stations retrieved today (if table exists)
        if plpy.execute(u'select tdgTableCheck(%s)' % plpy.quote_literal(system.get('table_name'))):
            plpy.execute(u'delete from %s where retrieval_date = current_date' % plpy.quote_ident(system.get('table_name')))

        # create new table
        plpy.execute(sql)

        # insert new values
        plpy.info(u'    -> Inserting data')
        values = u''
        cols = columnTypes.keys()
        cols.sort()
        sql = u'insert into received.%s (' % plpy.quote_ident(system.get('table_name'))
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

        # now try to cast each column to its proper type, catching fails
        for col, colType in columnTypes.iteritems():
            try:
                sql = u'alter table %s ' % plpy.quote_ident(system.get('table_name'))
                sql += u'alter column %s ' % plpy.quote_ident(col)
                sql += u'type %s ' % colType
                sql += u'using %s::%s' % (plpy.quote_ident(col),colType)
                plpy.execute(sql)
            except:
                pass

        # add id column and primary key
        idCol = createUniqueColumnName('id',cols)
        sql = u'alter table %s add column %s serial primary key' % (plpy.quote_ident(system.get('table_name')),idCol)
        plpy.execute(sql)

        # set the geom
        sql = u'update %s set geom = st_setSRID(st_makepoint(' % plpy.quote_ident(system.get('table_name'))
        sql += u'%s,%s)' % (plpy.quote_ident(system.get('lon')),plpy.quote_ident(system.get('lat')))
        sql += u',%d)' % system.get(u'srid')
        plpy.execute(sql)

        # and finally set the retrieval dates
        sql = u'update %s set retrieval_date = current_date' % plpy.quote_ident(system.get('table_name'))
        plpy.execute(sql)


return True

$$ LANGUAGE plpythonu;
ALTER FUNCTION tdg.tdgUpdateBikeShareStations(REGCLASS,TEXT) OWNER TO gis;
