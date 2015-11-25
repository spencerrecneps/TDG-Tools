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
    data = str(response.read())
    return json.loads(data)


def is_number(s):
    if s is None:
        return True
    if isinstance(s,bool):
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
        plpy.info('Retreiving %s' % system.get('system_name'))

        # grab json from url and save as an object
        data = get_jsonparsed_data(system.get('url'))

        # traverse tree to get station data
        branch = None
        for limb in system.get('tree'):
            branch = data.get(limb)
        if branch is None:
            stationData = data
        else:
            stationData = branch

        # drop existing table
        plpy.execute('drop table if exists %s' % system.get('table_name'))

        # set column types
        plpy.info('    -> Setting column types')
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

        plpy.info('    -> Building table')
        # sql = 'create table generated.%s ( \
        #     id serial primary key, \
        #     geom geometry(point,%d)' % (system.get('table_name'), system.get('srid'))
        sql = 'create table received.%s ( \
            geom geometry(point,%d)' % (plpy.quote_ident(system.get('table_name')), system.get('srid'))
        for col, colType in columnTypes.iteritems():
            # sql += ',"%s" %s' % (col,colType)
            sql += ',%s text' % plpy.quote_ident(col)
        sql += ')'

        # drop old table if exists
        plpy.execute('drop table if exists %s' % plpy.quote_ident(system.get('table_name')))

        # create new table
        plpy.execute(sql)

        # insert new values
        plpy.info('    -> Inserting data')
        values = ''
        cols = columnTypes.keys()
        cols.sort()
        plpy.info(str(columnTypes))
        plpy.info(str(columnTypes.keys()))
        plpy.info(str(cols))
        sql = 'insert into received.%s (' % plpy.quote_ident(system.get('table_name'))
        for col in cols:
            sql += '%s,' % plpy.quote_ident(col)
        sql = sql[:-1]
        sql += ') values '
        for row in stationData:
            sql += '('
            for col in cols:
                sql += "%s," % plpy.quote_nullable(str(row.get(col)))
                # if columnTypes.get(col) == 'text':
                #     sql += "%s," % plpy.quote_nullable(str(row.get(col)))
                # else:
                #     sql += '%s,' % row.get(col)
            sql = sql[:-1]
            sql += '),'
        sql = sql[:-1]

        plpy.info(sql)
        plpy.execute(sql)

        # now try to cast each column to a different type, catching fails



return True

$$ LANGUAGE plpythonu;
ALTER FUNCTION tdg.tdgUpdateBikeShareStations(REGCLASS,TEXT) OWNER TO gis;
