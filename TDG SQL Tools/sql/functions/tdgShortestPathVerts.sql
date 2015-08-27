CREATE OR REPLACE FUNCTION tdgShortestPath (_linktable REGCLASS,
                                            _verttable REGCLASS,
                                            _from INT,
                                            _to INT,
                                            _stress INT DEFAULT NULL)
RETURNS SETOF tdgShortestPathType AS $$

import networkx as nx

# check node existence
qc = plpy.execute('SELECT EXISTS (SELECT 1 FROM %s WHERE node_id = %s)' % (_verttable,_from))
if not qc[0]['exists']:
    plpy.error('From vertex does not exist.')
qc = plpy.execute('SELECT EXISTS (SELECT 1 FROM %s WHERE node_id = %s)' % (_verttable,_to))
if not qc[0]['exists']:
    plpy.error('To vertex does not exist.')

# create the graph
DG=nx.DiGraph()

# read input stress
stress = 99
if not _stress is None:
    stress = _stress

# edges first
edges = plpy.execute('SELECT * FROM %s;' % _linktable)
for e in edges:
    DG.add_edge(e['source_node'],
                e['target_node'],
                weight=max(e['link_cost'],0),
                link_id=e['id'],
                stress=min(e['link_stress'],99),
                road_id=e['road_id'])

# then vertices
verts = plpy.execute('SELECT * FROM %s;' % _verttable)
for v in verts:
    vid = v['node_id']
    DG.node[vid]['weight'] = max(v['node_cost'],0)
    DG.node[vid]['intersection_id'] = v['intersection_id']


# get the shortest path
plpy.info('Checking for path existence')
if nx.has_path(DG,source=_from,target=_to):
    plpy.info('Path found')
    shortestPath = nx.shortest_path(DG,source=_from,target=_to,weight='weight')
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
for v1 in shortestPath:
    v2 = getNextNode(shortestPath,v1)
    if v2:
        ret.append((None,
                    v1,
                    None,
                    DG.node[v1]['intersection_id'],
                    DG.node[v1]['weight']))
        ret.append((DG.edge[v1][v2]['link_id'],
                    None,
                    DG.edge[v1][v2]['road_id'],
                    None,
                    DG.edge[v1][v2]['weight']))
    else:
        ret.append((None,
                    v1,
                    None,
                    DG.node[v1]['intersection_id'],
                    DG.node[v1]['weight']))

#return ([1,2,3,4,5],[6,5,4,3,2])
return ret


# link_id INT,
# vert_id INT,
# road_id INT,
# int_id INT,
# move_cost INT

#with b (f) as ( select bar())
#select (b.f).a, (b.f).b from b

$$ LANGUAGE plpythonu;
ALTER FUNCTION tdgShortestPath(REGCLASS,REGCLASS,INT,INT,INT) OWNER TO gis;
