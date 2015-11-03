CREATE OR REPLACE FUNCTION tdg.tdgMultiToSingle (
    input_table_ REGCLASS,
    geom_column_ TEXT)
RETURNS BOOLEAN AS $func$

DECLARE
    srid INT;
    cols TEXT[];
    cols_text TEXT;

BEGIN
    -- get srid of the geom
    RAISE NOTICE 'Getting SRID of geometry';
    EXECUTE 'SELECT tdgGetSRID($1,$2);'
    USING   input_table_, geom_column_
    INTO    srid;

    IF srid IS NULL THEN
        RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', input_table_;
    END IF;
    RAISE NOTICE '  -----> SRID found %',srid;

    -- create temp table and copy features
    EXECUTE '
        CREATE TEMP TABLE tmp_multitosingle (LIKE '||input_table_||')
        ON COMMIT DROP;
    ';
    EXECUTE 'INSERT INTO tmp_multitosingle SELECT * FROM '||input_table_||';';

    -- delete from input_table_ and change geom type
    EXECUTE 'DELETE FROM '||input_table_||';';
    EXECUTE '
        ALTER TABLE '||input_table_||' ALTER COLUMN '||geom_column_||'
        TYPE geometry(linestring,'||srid::TEXT||');
    ';

    -- get column names and remove geom_column_
    EXECUTE 'SELECT ARRAY(SELECT * FROM tdgGetColumnNames($1,$2))'
    USING   input_table_, 'f'::BOOLEAN
    INTO    cols;
    cols_text := array_to_string(array_remove(cols, geom_column_),',');


    -- check if tdg_id column exists. if not, add it.
    IF tdgColumnCheck(input_table_,'tdg_id') THEN
        RAISE NOTICE 'Column tdg_id already exists';
        EXECUTE '
            ALTER TABLE '||input_table_||'
            ALTER COLUMN tdg_id TYPE TEXT,
            ALTER COLUMN tdg_id SET DEFAULT uuid_generate_v4()::TEXT,
            ALTER COLUMN tdg_id SET NOT NULL;
        ';
    ELSE
        RAISE NOTICE 'Creating column tdg_id';
        -- add tdg_id column
        EXECUTE '
            ALTER TABLE '||input_table_||'
            ADD COLUMN tdg_id TEXT NOT NULL DEFAULT uuid_generate_v4()::TEXT;
        ';
    END IF;

    -- copy back to input_table_
    EXECUTE '
        INSERT INTO '||input_table_||' (geom,'||cols_text||')
        SELECT  (ST_Dump('||geom_column_||')).geom, '||cols_text||'
        FROM    tmp_multitosingle;
    ';

    RETURN 't';

END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMultiToSingle(REGCLASS,TEXT) OWNER TO gis;
