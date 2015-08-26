CREATE OR REPLACE FUNCTION tdgShortestPath (_linktable REGCLASS,
                                            _verttable REGCLASS,
                                            _from INT,
                                            _to INT,
                                            _stress INT DEFAULT NULL)
RETURNS TABLE ( link_id INT,
                vert_id INT,
                road_id INT,
                int_id INT,
                move_cost INT) AS $$

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
                stress=min(e['link_stress'],99),
                road_id=e['road_id'])

# then vertices
verts = plpy.execute('SELECT * FROM %s;' % _verttable)
for v in verts:
    vid = v['node_id']
    DG[vid]['weight'] = max(v['node_cost'],0)
    DG[vid]['intersection_id'] = v['intersection_id']


# get the shortest path
plpy.info('Checking for path existence')
if nx.has_path(DG,source=_from,target=_to):
    plpy.info('Path found')
    shortestPath = nx.shortest_path(DG,source=_from,target=_to,weight='weight')
else:
    plpy.error('No path between given vertices')


return ([1,2,3,4,5],[6,5,4,3,2])

$$ LANGUAGE plpythonu;
ALTER FUNCTION tdgShortestPath(REGCLASS,REGCLASS,INT,INT,INT) OWNER TO gis;
