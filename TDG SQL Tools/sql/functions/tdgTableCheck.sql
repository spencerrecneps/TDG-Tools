CREATE OR REPLACE FUNCTION tdg.tdgTableCheck (input_table_ TEXT)
RETURNS BOOLEAN AS $func$

DECLARE
    namecheck RECORD;

BEGIN
    RAISE NOTICE 'Checking % exists',input_table_;
    EXECUTE 'SELECT '||quote_literal(input_table_)||'::REGCLASS';
    RETURN 't';
EXCEPTION
    WHEN undefined_table THEN
        RETURN 'f';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgTableCheck(TEXT) OWNER TO gis;
