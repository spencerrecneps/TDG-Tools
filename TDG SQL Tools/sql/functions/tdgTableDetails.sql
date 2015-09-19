CREATE OR REPLACE FUNCTION tdg.tdgTableDetails(input_table TEXT)
RETURNS TABLE (schema_name TEXT, table_name TEXT) AS $func$

BEGIN
    RETURN QUERY EXECUTE '
        SELECT  nspname::TEXT, relname::TEXT
        FROM    pg_namespace n JOIN pg_class c ON n.oid = c.relnamespace
        WHERE   c.oid = ' || quote_literal(input_table) || '::REGCLASS';

EXCEPTION
    WHEN undefined_table THEN
        RETURN;
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgTableDetails(TEXT) OWNER TO gis;




-- CREATE OR REPLACE FUNCTION tdgTableDetails(input_table TEXT)
-- RETURNS TABLE (schema_name TEXT, table_name TEXT) AS $func$
--
-- BEGIN
--     RETURN QUERY EXECUTE '
--         SELECT  nspname::TEXT, relname::TEXT
--         FROM    pg_namespace n JOIN pg_class c ON n.oid = c.relnamespace
--         WHERE   c.oid = to_regclass(' || quote_literal(input_table) || ')';
-- END $func$ LANGUAGE plpgsql;
-- ALTER FUNCTION tdgTableDetails(TEXT) OWNER TO gis;
