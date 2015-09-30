CREATE OR REPLACE FUNCTION tdg.tdgMakeStandardizedRoadIndexes(road_table_ REGCLASS)
RETURNS BOOLEAN AS $func$

DECLARE
    table_name TEXT;

BEGIN
    EXECUTE 'SELECT table_name FROM tdgTableDetails($1);'
    USING   road_table_::TEXT
    INTO    table_name;

    raise notice 'Creating indices on: %', road_table_;

    EXECUTE format('
        CREATE INDEX sidx_%s_geom ON %s USING GIST(geom);
        CREATE INDEX idx_%s_oneway ON %s (one_way);
        CREATE INDEX idx_%s_sourceid ON %s (source_id);
        CREATE INDEX idx_%s_funcclass ON %s (functional_class);
        CREATE INDEX idx_%s_zf ON %s (z_from);
        CREATE INDEX idx_%s_zt ON %s (z_to);
        ',  table_name,
            road_table_,
            table_name,
            road_table_,
            table_name,
            road_table_,
            table_name,
            road_table_,
            table_name,
            road_table_,
            table_name,
            road_table_);

    EXECUTE '
        CREATE INDEX idx_'||table_name||'_intfrom ON '||road_table_||' (intersection_from);
        CREATE INDEX idx_'||table_name||'_intto ON '||road_table_||' (intersection_to);';

    EXECUTE format('ANALYZE %s;',road_table_);

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeStandardizedRoadIndexes(REGCLASS) OWNER TO gis;
