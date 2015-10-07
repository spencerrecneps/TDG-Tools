CREATE OR REPLACE FUNCTION tdgShortestPathVerts (   linktable_ REGCLASS,
                                                    verttable_ REGCLASS,
                                                    from_to_pairs_ INTEGER[],
                                                    stress_ INTEGER DEFAULT NULL)
RETURNS SETOF tdgShortestPathType AS $$

import networkx as nx

# check vert existence
qc = plpy.execute('SELECT EXISTS (SELECT 1 FROM %s WHERE vert_id = %s)' % (verttable_,from_))
if not qc[0]['exists']:
    plpy.error('From vertex does not exist.')
qc = plpy.execute('SELECT EXISTS (SELECT 1 FROM %s WHERE vert_id = %s)' % (verttable_,to_))
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
    DG.add_edge(e['source_vert'],
                e['target_vert'],
                weight=max(e['link_cost'],0),
                link_id=e['id'],
                stress=min(e['link_stress'],99),
                road_id=e['road_id'])

# then vertices
verts = plpy.execute('SELECT * FROM %s;' % verttable_)
for v in verts:
    vid = v['vert_id']
    DG.node[vid]['weight'] = max(v['vert_cost'],0)
    DG.node[vid]['intersection_id'] = v['intersection_id']


# get the shortest path
ret = []
for pair in from_to_pairs_:
    for from_vert, to_vert in pair:
        seq = 0
        plpy.info('Checking for path existence')
        if nx.has_path(DG,source=from_vert,target=to_vert):
            plpy.info('Path found')
            shortestPath = nx.shortest_path(DG,source=from_vert,target=to_vert,weight='weight')
            for v1 in shortestPath:
                seq = seq + 1
                v2 = getNextNode(shortestPath,v1)
                if v2:
                    ret.append((from_vert,
                                to_vert,
                                seq,
                                None,
                                v1,
                                None,
                                DG.node[v1]['intersection_id'],
                                DG.node[v1]['weight']))
                    seq = seq + 1
                    ret.append((from_vert,
                                to_vert,
                                seq,
                                DG.edge[v1][v2]['link_id'],
                                None,
                                DG.edge[v1][v2]['road_id'],
                                None,
                                DG.edge[v1][v2]['weight']))
                else:
                    ret.append((from_vert,
                                to_vert,
                                seq,
                                None,
                                v1,
                                None,
                                DG.node[v1]['intersection_id'],
                                DG.node[v1]['weight']))
        else:
            plpy.error('No path between given vertices')


# set up function to return edges
def getNextNode(nodes,node):
    pos = nodes.index(node)
    try:
        return nodes[pos+1]
    except:
        return None

return ret

$$ LANGUAGE plpythonu;
ALTER FUNCTION tdgShortestPathVerts(REGCLASS,REGCLASS,INTEGER[],INTEGER) OWNER TO gis;
