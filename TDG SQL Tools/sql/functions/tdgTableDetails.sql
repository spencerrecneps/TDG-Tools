CREATE OR REPLACE FUNCTION tdgTableDetails(input_table REGCLASS)
RETURNS RECORD AS $func$

DECLARE
    tabledetails RECORD;

BEGIN
    EXECUTE format ('
        SELECT  nspname AS schema_name,
                relname AS table_name
        FROM    pg_namespace n JOIN pg_class c ON n.oid = c.relnamespace
        WHERE   c.oid = %L::regclass
        ',  input_table) INTO tabledetails;

    RETURN tabledetails;
END $func$ LANGUAGE plpgsql;
