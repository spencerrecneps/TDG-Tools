CREATE OR REPLACE FUNCTION tdg.tdgMakeIntersectionTriggers(
    int_table_ REGCLASS,
    table_name_ TEXT)
RETURNS BOOLEAN AS $func$

BEGIN
    RAISE NOTICE 'Creating triggers on %', int_table_;

    --prevent updates/changes
    EXECUTE format('
        CREATE TRIGGER tdg%sGeomPreventUpdate
            BEFORE UPDATE OF geom ON %s
            FOR EACH ROW
            EXECUTE PROCEDURE tdgTriggerDoNothing();
        ',  table_name_ || '_ints',
            int_table_);
    EXECUTE format('
        CREATE TRIGGER tdg%sPreventInsDel
            BEFORE INSERT OR DELETE ON %s
            FOR EACH ROW
            EXECUTE PROCEDURE tdgTriggerDoNothing();
        ',  table_name_ || '_ints',
            int_table_);

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeIntersectionTriggers(REGCLASS,TEXT) OWNER TO gis;
