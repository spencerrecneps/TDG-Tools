-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION tdg" to load this file. \quit

CREATE OR REPLACE FUNCTION MakeNetwork(anyelement)
--sets triggers to automatically update vertices
RETURNS INT
LANGUAGE SQL AS
'SELECT 1';

CREATE OR REPLACE FUNCTION GenerateCrossStreetData(anyelement)
--populate cross-street data
RETURNS INT
LANGUAGE SQL AS
'SELECT 1';
