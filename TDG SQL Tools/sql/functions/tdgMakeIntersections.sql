CREATE OR REPLACE FUNCTION tdg.tdgMakeIntersections (
    road_table_ REGCLASS,
    z_vals_ BOOLEAN DEFAULT 'f')
RETURNS BOOLEAN AS $func$

DECLARE
    namecheck RECORD;
    schema_name TEXT;
    table_name TEXT;
    int_table TEXT;
    srid INT;

BEGIN
    RAISE NOTICE 'PROCESSING:';

    --check table and schema
    BEGIN
        RAISE NOTICE 'Getting table details for %',road_table_;
        EXECUTE '   SELECT  schema_name, table_name
                    FROM    tdgTableDetails($1::TEXT)'
        USING   road_table_
        INTO    schema_name, table_name;

        int_table = schema_name || '.' || table_name || '_intersections';
    END;

    --get srid of the geom
    BEGIN
        RAISE NOTICE 'Getting SRID of geometry';
        EXECUTE 'SELECT tdgGetSRID($1,$2);'
        USING   road_table_,
                'geom'
        INTO    srid;

        IF srid IS NULL THEN
            RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', table_name;
        END IF;
        raise NOTICE '  -----> SRID found %',srid;
    END;

    BEGIN
        RAISE NOTICE 'creating intersection table';
        EXECUTE format('
            CREATE TABLE %s (   int_id serial PRIMARY KEY,
                                geom geometry(point,%L),
                                z_elev INT NOT NULL DEFAULT 0,
                                legs INT,
                                signalized BOOLEAN);
            ',  int_table,
                srid);
    END;

    --add intersections to table
    BEGIN
        RAISE NOTICE 'adding intersections';

        EXECUTE '
            CREATE TEMP TABLE v (i INT, z INT, geom geometry(POINT,'||srid::TEXT||'))
            ON COMMIT DROP;
            INSERT INTO v (i, z, geom)
                SELECT      road_id, z_from, ST_StartPoint(geom)
                FROM        ' || road_table_ || '
                ORDER BY    road_id ASC;
            INSERT INTO v (i, z, geom)
                SELECT      road_id, z_to, ST_EndPoint(geom)
                FROM        ' || road_table_ || '
                ORDER BY    road_id ASC;
            INSERT INTO ' || int_table || ' (legs, z_elev, geom)
                SELECT      COUNT(i), COALESCE(z,0), geom
                FROM        v
                GROUP BY    COALESCE(z,0), geom;';
    END;

    EXECUTE format('ANALYZE %s;', int_table);

    -- add intersection data to roads
    BEGIN
        RAISE NOTICE 'populating intersection data in roads table';
        EXECUTE format('
            UPDATE  %s
            SET     intersection_from = if.int_id,
                    intersection_to = it.int_id
            FROM    %s if,
                    %s it
            WHERE   ST_StartPoint(%s.geom) = if.geom
            AND     %s.z_from = if.z_elev
            AND     ST_EndPoint(%s.geom) = it.geom
            AND     %s.z_to = it.z_elev;
            ',  road_table_,
                int_table,
                int_table,
                road_table_,
                road_table_,
                road_table_,
                road_table_);
    END;

    --triggers to prevent changes
    BEGIN
        EXECUTE format('
            CREATE TRIGGER tdg%sGeomPreventUpdate
                BEFORE UPDATE OF geom ON %s
                FOR EACH ROW
                EXECUTE PROCEDURE tdgTriggerDoNothing();
            ',  table_name || '_ints',
                int_table);
        EXECUTE format('
            CREATE TRIGGER tdg%sPreventInsDel
                BEFORE INSERT OR DELETE ON %s
                FOR EACH ROW
                EXECUTE PROCEDURE tdgTriggerDoNothing();
            ',  table_name || '_ints',
                int_table);
    END;

    --triggers to update intersections when changes are made to roads
    BEGIN
    -- refer to http://stackoverflow.com/questions/27837511/how-to-properly-emulate-statement-level-triggers-with-access-to-data-in-postgres
        --------------------
        --road geom changes
        --------------------
        -- create temp table
        EXECUTE '
            CREATE TRIGGER tr_tdg'||table_name||'GeomUpdateTable
                BEFORE UPDATE OF geom, z_from, z_to ON '||road_table_||'
                FOR EACH STATEMENT
                EXECUTE PROCEDURE tdgRoadGeomChangeTable();';
        -- populate with vals
        EXECUTE '
            CREATE TRIGGER tr_tdg'||table_name||'GeomUpdateVals
                BEFORE UPDATE OF geom, z_from, z_to ON '||road_table_||'
                FOR EACH ROW
                EXECUTE PROCEDURE tdgRoadGeomChangeVals();';
        -- update intersections
        EXECUTE '
            CREATE TRIGGER tr_tdg'||table_name||'GeomUpdateIntersections
                AFTER UPDATE OF geom, z_from, z_to ON '||road_table_||'
                FOR EACH STATEMENT
                EXECUTE PROCEDURE tdgRoadGeomUpdate();';
        --------------------
        --road insert/delete
        --------------------
        -- create temp table
        EXECUTE '
            CREATE TRIGGER tr_tdg'||table_name||'GeomAddDelTable
                BEFORE INSERT OR DELETE ON '||road_table_||'
                FOR EACH STATEMENT
                EXECUTE PROCEDURE tdgRoadGeomChangeTable();';
        -- populate with vals
        EXECUTE '
            CREATE TRIGGER tr_tdg'||table_name||'GeomAddDelVals
                BEFORE INSERT OR DELETE ON '||road_table_||'
                FOR EACH ROW
                EXECUTE PROCEDURE tdgRoadGeomChangeVals();';
        -- update intersections
        EXECUTE '
            CREATE TRIGGER tr_tdg'||table_name||'GeomAddDelIntersections
                AFTER INSERT OR DELETE ON '||road_table_||'
                FOR EACH STATEMENT
                EXECUTE PROCEDURE tdgRoadGeomUpdate();';
    END;

    --road intersection indexes
    BEGIN
        EXECUTE '
            CREATE INDEX idx_'||table_name||'_intfrom ON '||road_table_||' (intersection_from);
            CREATE INDEX idx_'||table_name||'_intto ON '||road_table_||' (intersection_to);';
    END;

    --not null on road intersections
    BEGIN
        EXECUTE '
            ALTER TABLE '||table_name||' ALTER COLUMN intersection_from SET NOT NULL;
            ALTER TABLE '||table_name||' ALTER COLUMN intersection_to SET NOT NULL;';
    END;

    EXECUTE 'ANALYZE '||road_table_||';';
    EXECUTE 'ANALYZE '||int_table||';';

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMakeIntersections(REGCLASS,BOOLEAN) OWNER TO gis;
