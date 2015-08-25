CREATE OR REPLACE FUNCTION tdgTableCheck (input_table REGCLASS)
RETURNS BOOLEAN AS $func$

DECLARE
    namecheck RECORD;

BEGIN
    RAISE NOTICE 'Checking % exists',input_table;
    EXECUTE '   SELECT  schema_name,
                        table_name
                FROM    tdgTableDetails('||quote_literal(input_table)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
    IF namecheck.schema_name IS NULL OR namecheck.table_name IS NULL THEN
        RETURN 'f';
    END IF;

RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgTableCheck(REGCLASS) OWNER TO gis;
