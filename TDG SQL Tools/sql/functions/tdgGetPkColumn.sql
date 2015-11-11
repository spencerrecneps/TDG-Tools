CREATE OR REPLACE FUNCTION tdg.tdgGetPkColumn (input_table_ REGCLASS)
RETURNS TEXT AS $func$

DECLARE
    col TEXT;

BEGIN
    RAISE NOTICE 'Getting primary key column for %',input_table_;
    EXECUTE '
        SELECT a.attname
        FROM   pg_index i
        JOIN   pg_attribute a ON a.attrelid = i.indrelid
                             AND a.attnum = ANY(i.indkey)
        WHERE  i.indrelid = $1::regclass
        AND    i.indisprimary
        LIMIT  1;'
    USING   input_table_
    INTO    col;

    RAISE NOTICE '  -> column is %',col;

    RETURN col;

END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgGetPkColumn(REGCLASS) OWNER TO gis;
