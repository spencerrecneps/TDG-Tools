CREATE OR REPLACE FUNCTION tdgColumnCheck (input_table REGCLASS, column_name TEXT)
RETURNS BOOLEAN AS $func$

BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_attribute
        WHERE  attrelid = input_table
        AND    attname = column_name
        AND    NOT attisdropped)
    THEN
        RETURN 't';
    END IF;
RETURN 'f';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgColumnCheck(REGCLASS, TEXT) OWNER TO gis;
