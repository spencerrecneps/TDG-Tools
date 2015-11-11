CREATE OR REPLACE FUNCTION tdg.tdgMeld(
    target_table_ REGCLASS,
    target_column_ TEXT,
    source_table_ REGCLASS,
    source_column_ TEXT,
    tolerance FLOAT)
RETURNS BOOLEAN AS $func$

DECLARE
    target_record RECORD;

BEGIN
    raise notice 'PROCESSING:';

    -- check columns
    IF NOT tdgColumnCheck(target_table_,target_column_) THEN
        RAISE EXCEPTION 'Column % not found', target_column_;
    END IF;
    IF NOT tdgColumnCheck(source_table_,source_column_) THEN
        RAISE EXCEPTION 'Column % not found', source_column_;
    END IF;

    -- iterate target records
    FOR target_record IN EXECUTE 'SELECT * FROM '||target_table_
    LOOP

    END LOOP;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMeld(REGCLASS,TEXT,REGCLASS,TEXT,FLOAT) OWNER TO gis;
