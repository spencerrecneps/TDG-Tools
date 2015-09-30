CREATE OR REPLACE FUNCTION tdg.tdgMakeIntersectionIndexes (int_table_ REGCLASS)
RETURNS BOOLEAN AS $func$

DECLARE
    table_name TEXT;

BEGIN
    --get base table name
    EXECUTE 'SELECT table_name FROM tdgTableDetails($1);'
    USING   int_table_::TEXT
    INTO    table_name;

    --intersection indices
    RAISE NOTICE 'Creating indexes on %', int_table_;

    EXECUTE '
        CREATE INDEX sidx_'||table_name||'_geom
            ON '||int_table_||' USING gist(geom);';
    EXECUTE '
        CREATE INDEX idx_'||table_name||'_z_elev
            ON '||int_table_||' (z_elev);';

    EXECUTE 'ANALYZE '||int_table_;

    RETURN 't';

END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeIntersectionIndexes(REGCLASS) OWNER TO gis;
