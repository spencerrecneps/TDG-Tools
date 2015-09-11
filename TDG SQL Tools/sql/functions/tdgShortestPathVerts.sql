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
