-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION tdg" to load this file. \quit

CREATE OR REPLACE FUNCTION MakeNetwork(t_name varchar(50))
--sets triggers to automatically update vertices
RETURNS VOID AS

$func$
BEGIN

EXECUTE format('
    CREATE TABLE %I (
        id serial PRIMARY KEY,
        node_id TEXT,
        cost INT
    )
    ', t_name || '_net_vert');

END
$func$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION GenerateCrossStreetData(anyelement)
--populate cross-street data
RETURNS INT
LANGUAGE SQL AS
'SELECT 1';
