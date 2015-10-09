CREATE OR REPLACE FUNCTION tdg.tdgShortestPathIntersections (
    int_table_ REGCLASS,
    link_table_ REGCLASS,
    vert_table_ REGCLASS,
    from_to_pairs_ INTEGER[],
    stress_ INTEGER DEFAULT NULL)
RETURNS SETOF tdg.tdgShortestPathType AS $$

import itertools

# switch to pythonic variable names
intTable = int_table_
linkTable = link_table_
vertTable = vert_table_
fromToPairs = from_to_pairs_

# check the intersections to make sure there isn't an unpaired number
if not len(fromToPairs)%2 == 0:
    plpy.error('Unpaired intersection given')

# split fromToPairs into pairs
intPairs = zip(fromToPairs[::2], fromToPairs[1::2])

# check intersection's existence
plpy.info('Checking intersections')
for pair in intPairs:
    for i in pair:
        qc = plpy.execute('SELECT EXISTS (SELECT 1 FROM %s WHERE int_id = %s)' % (intTable,i))
        if not qc[0]['exists']:
            plpy.error('Intersection ' + str(i) + ' does not exist.')

# routine to get min cost from a list of pairIds
def minCostPair(table, pairIds):
    minPair = -1
    for pairId in pairIds:
        cost = 0
        for row in table:
            if row['pair_id'] == pairId:
                cost = cost + row['move_cost']
        if minPair > 0:
            if cost < minPair:
                minPair = pairId
        else:
            minPair = pairId
    return minPair

# routine to return pairs that correspond to the first intersection
def getPairsFromMin(table, intId):
    pairs = []
    for row in table:
        if row['move_sequence'] == 1 and row['int_id'] == intId:
            pairs.append(row['pair_id'])
    return pairs

# routine to return pairs that correspond to the last intersection
def getPairsFromMax(table, intId):
    pairs = []
    maxs = dict()
    for row in table:
        if row['pair_id'] in maxs:
            if maxs[row['pair_id']]['move_sequence'] < row['move_sequence']:
                maxs[row['pair_id']] = row
        else:
            maxs[row['pair_id']] = row
    plpy.info(str(maxs))
    for k, row in maxs.iteritems():
        if row['int_id'] == intId:
            pairs.append(row['pair_id'])
    return pairs

# get the verts
plpy.info('Getting vertices')
verts = []
for fromInt, toInt in intPairs:
    fromVerts = plpy.execute('SELECT vert_id FROM %s WHERE int_id = %s' % (vertTable,fromInt))
    toVerts = plpy.execute('SELECT vert_id FROM %s WHERE int_id = %s' % (vertTable,toInt))

    for f, t in itertools.product(fromVerts,toVerts):
        verts.append(f['vert_id'])
        verts.append(t['vert_id'])

# get all possible shortest paths
plpy.info('Getting candidate paths')
sql = plpy.prepare(
    'SELECT * FROM tdg.tdgShortestPathVerts($1,$2,$3,$4)',
    ["text","text","integer[]","integer"]
)
paths = plpy.execute(
    sql,
    [linkTable, vertTable, verts, stress_]
)

# parse through returned table and get shortest path for each
ret = []
for fromInt, toInt in intPairs:
    pairIds = list(
        set( getPairsFromMin(paths, fromInt) ) & set( getPairsFromMax(paths, toInt) )
    )
    minPair = minCostPair(paths, pairIds)
    for row in paths:
        if row['pair_id'] == minPair:
            ret.append(row)

return ret

$$ LANGUAGE plpythonu;
ALTER FUNCTION tdg.tdgShortestPathIntersections(REGCLASS,REGCLASS,REGCLASS,INTEGER[],INTEGER) OWNER TO gis;
