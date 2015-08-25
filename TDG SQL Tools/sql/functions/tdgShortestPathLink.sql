CREATE OR REPLACE FUNCTION tdgShortestPath (input_table REGCLASS,
                                            _stress INT DEFAULT NULL)
RETURNS TABLE ( link_id INT,
                vert_id INT,
                road_id INT,
                int_id INT,
                move_cost INT) AS $$

# read input stress
stress = 99
if not _stress is None:
    stress = _stress

# get table names
verttable = input_table + '_net_vert'
linktable = input_table + '_net_link'

# check tables
if not plpy.execute('SELECT tdgTableCheck(%s);' % plpy.quote_literal(verttable)):
    # this error isn't working properly. need to improve error catching
    # generally.
    plpy.error('No vertex table found. Please create network first.')


# if all is well, proceed
import networkx as nx
DG=nx.DiGraph()

# edges first
edges = plpy.execute('SELECT * FROM %s;' % linktable)
for e in edges:
    DG.add_edge(e['node_source'],
                e['node_target'],
                weight=e['link_cost'],
                stress=e['link_stress'],
                road_id=e['road_id'])

# then vertices
verts = plpy.execute('SELECT * FROM %s;' % verttable)
for v in verts:
    vid = v['node_id']
    DG[vid]['weight'] = v['node_cost']
    DG[vid]['intersection_id'] = v['intersection_id']

#plpy.execute("UPDATE tbl SET %s = %s WHERE key = %s" % (
#    plpy.quote_ident(colname),
#    plpy.quote_nullable(newvalue),
#    plpy.quote_literal(keyvalue)))



return ([1,2,3,4,5],[6,5,4,3,2])

$$ LANGUAGE plpythonu;
ALTER FUNCTION tdgShortestPath(REGCLASS,INT) OWNER TO gis;
