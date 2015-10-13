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
