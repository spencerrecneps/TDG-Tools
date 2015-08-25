-- CREATE OR REPLACE FUNCTION tdgShortestPath (input_table REGCLASS)
-- RETURNS TABLE ( link_id INT,
--                 vert_id INT,
--                 road_id INT,
--                 int_id INT,
--                 move_cost INT) AS $$
--
-- import networkx
-- return ([1,2,3,4,5],[6,5,4,3,2])
--
-- $$ LANGUAGE plpythonu;
-- ALTER FUNCTION tdgShortestPath(REGCLASS) OWNER TO gis;

CREATE FUNCTION pyversion() RETURNS text AS $$
import sys
return sys.version + '\n' + '\n'.join(sys.path)
$$ LANGUAGE plpythonu;
ALTER FUNCTION pyversion() OWNER TO gis;

CREATE OR REPLACE FUNCTION foo()
RETURNS BOOLEAN AS $$

import networkx
return True

$$ LANGUAGE plpythonu;
ALTER FUNCTION foo() OWNER TO gis;
