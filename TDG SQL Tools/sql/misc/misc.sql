--check for plpythonu and install if not present already
CREATE OR REPLACE FUNCTION make_plpythonu()
RETURNS VOID
LANGUAGE SQL
AS $$
    CREATE LANGUAGE plpythonu;
$$;
SELECT
    CASE
    WHEN EXISTS(
        SELECT 1
        FROM pg_catalog.pg_language
        WHERE lanname='plpythonu'
    )
    THEN NULL
    ELSE make_plpythonu() END;
DROP FUNCTION make_plpythonu();

--give permission to the tdg schema
GRANT ALL ON SCHEMA tdg TO PUBLIC;

--create tdg schemas
CREATE SCHEMA IF NOT EXISTS generated AUTHORIZATION gis;
CREATE SCHEMA IF NOT EXISTS received AUTHORIZATION gis;
CREATE SCHEMA IF NOT EXISTS scratch AUTHORIZATION gis;

--drop tdg schemas from the extension so they get backed up
ALTER EXTENSION TDG DROP SCHEMA generated;
ALTER EXTENSION TDG DROP SCHEMA received;
ALTER EXTENSION TDG DROP SCHEMA scratch;
