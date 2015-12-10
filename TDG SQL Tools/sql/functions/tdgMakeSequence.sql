CREATE OR REPLACE FUNCTION tdg.tdgMakeSequence (
    input_table_ REGCLASS,
    column_ TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $func$

DECLARE
    table_name TEXT;
    column_name TEXT;
    seq_name TEXT;
    seq_max INTEGER;

BEGIN
    RAISE NOTICE 'Adding sequence to %',input_table_;

    -- get column if none given
    IF column_ IS NULL THEN
        RAISE NOTICE 'Getting column';
        column_name := tdg.tdgGetPkColumn(input_table_);
    ELSE
        column_name := column_;
    END IF;

    -- get table name
    RAISE NOTICE 'Getting base table name';
    EXECUTE 'SELECT table_name FROM tdg.tdgTableDetails($1)'
    USING   input_table_::TEXT
    INTO    table_name;

    -- build sequence name
    seq_name := table_name||'_'||column_name||'_seq';
    RAISE NOTICE 'Sequence name: %',seq_name;

    -- get maximum existing value
    RAISE NOTICE 'Getting current max value';
    EXECUTE 'SELECT MAX('||column_name||') FROM '||input_table_||';'
    INTO    seq_max;
    RAISE NOTICE 'Max value: %',seq_max::TEXT;
    seq_max := seq_max + 1;

    -- create sequence
    RAISE NOTICE 'Creating sequence';
    EXECUTE 'DROP SEQUENCE IF EXISTS '||seq_name||';';
    EXECUTE 'CREATE SEQUENCE '||seq_name||' START WITH '||seq_max::TEXT||';';

    -- assign as default on the column
    RAISE NOTICE 'Assigning sequence to column %',column_name;
    EXECUTE '
        ALTER TABLE '||input_table_||'
        ALTER COLUMN '||column_name||'
        SET DEFAULT nextval('||quote_literal(seq_name)||'::REGCLASS)';

    RETURN 't';

END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeSequence(REGCLASS,TEXT) OWNER TO gis;
