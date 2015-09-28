CREATE OR REPLACE FUNCTION tdg.tdgMakeRoadTriggers(
    road_table_ REGCLASS,
    table_name_ TEXT)
RETURNS BOOLEAN AS $func$

BEGIN
    RAISE NOTICE 'Creating triggers on %', road_table_;

    --------------------
    --road geom changes
    --------------------
    -- create temp table
    EXECUTE '
        CREATE TRIGGER tr_tdg'||table_name_||'GeomUpdateTable
            BEFORE UPDATE OF geom, z_from, z_to ON '||road_table_||'
            FOR EACH STATEMENT
            EXECUTE PROCEDURE tdgRoadGeomChangeTable();';
    -- populate with vals
    EXECUTE '
        CREATE TRIGGER tr_tdg'||table_name_||'GeomUpdateVals
            BEFORE UPDATE OF geom, z_from, z_to ON '||road_table_||'
            FOR EACH ROW
            EXECUTE PROCEDURE tdgRoadGeomChangeVals();';
    -- update intersections
    EXECUTE '
        CREATE TRIGGER tr_tdg'||table_name_||'GeomUpdateIntersections
            AFTER UPDATE OF geom, z_from, z_to ON '||road_table_||'
            FOR EACH STATEMENT
            EXECUTE PROCEDURE tdgRoadGeomUpdate();';


    --------------------
    --road insert/delete
    --------------------
    -- create temp table
    EXECUTE '
        CREATE TRIGGER tr_tdg'||table_name_||'GeomAddDelTable
            BEFORE INSERT OR DELETE ON '||road_table_||'
            FOR EACH STATEMENT
            EXECUTE PROCEDURE tdgRoadGeomChangeTable();';
    -- populate with vals
    EXECUTE '
        CREATE TRIGGER tr_tdg'||table_name_||'GeomAddDelVals
            BEFORE INSERT OR DELETE ON '||road_table_||'
            FOR EACH ROW
            EXECUTE PROCEDURE tdgRoadGeomChangeVals();';
    -- update intersections
    EXECUTE '
        CREATE TRIGGER tr_tdg'||table_name_||'GeomAddDelIntersections
            AFTER INSERT OR DELETE ON '||road_table_||'
            FOR EACH STATEMENT
            EXECUTE PROCEDURE tdgRoadGeomUpdate();';

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeRoadTriggers(REGCLASS,TEXT) OWNER TO gis;
