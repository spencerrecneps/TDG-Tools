CREATE OR REPLACE FUNCTION tdg.tdgCopyTable (
    input_table_ REGCLASS,
    table_ TEXT,
    schema_ TEXT DEFAULT NULL,
    overwrite_ BOOLEAN DEFAULT 'f'::BOOLEAN
)
RETURNS BOOLEAN AS $func$

DECLARE
    schema TEXT;
    table_name TEXT;
    table_check BOOLEAN;
    pk_col TEXT;

BEGIN
    -- get schema
    IF schema_ IS NULL THEN
        EXECUTE 'SELECT schema_name FROM tdg.tdgTableDetails($1)'
        USING   input_table_::TEXT
        INTO schema;
    ELSE
        schema := schema_;
    END IF;

    -- build full table name
    table_name := quote_ident(schema) || '.' || quote_ident(table_);

    -- deal with overwriting
    IF overwrite_ THEN
        EXECUTE 'DROP TABLE IF EXISTS '||table_name;
    ELSE
        -- test for existence of new table, error if exists
        IF tdg.tdgTableCheck(table_name) THEN
            RAISE EXCEPTION 'Table % already exists', table_name;
        END IF;
    END IF;

    -- create new table
    EXECUTE 'CREATE TABLE '||table_name||' (LIKE '||input_table_||' INCLUDING ALL)';
    EXECUTE 'INSERT INTO '||table_name||' SELECT * FROM '||input_table_;

    -- get pk column from source table and set on new table
    pk_col := tdg.tdgGetPkColumn(input_table_);
    --EXECUTE 'ALTER TABLE '||table_name||' ADD PRIMARY KEY ('||pk_col||')';

    -- set sequence on new table
    EXECUTE 'SELECT tdg.tdgMakeSequence($1)'
    USING   table_name;

    RETURN 't';

END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgCopyTable(REGCLASS, TEXT, TEXT, BOOLEAN) OWNER TO gis;
