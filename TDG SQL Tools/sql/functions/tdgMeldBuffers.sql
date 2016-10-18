CREATE OR REPLACE FUNCTION tdg.tdgMeldBuffers(
    target_table_ REGCLASS,
    target_column_ TEXT,
    target_geom_ TEXT,
    source_table_ REGCLASS,
    source_column_ TEXT,
    source_geom_ TEXT,
    tolerance_ FLOAT,
    min_target_length_ FLOAT DEFAULT NULL,
    min_shared_length_pct_ FLOAT DEFAULT 0.9,
    only_nulls_ BOOLEAN DEFAULT 't'
)
RETURNS BOOLEAN AS $func$

DECLARE
    sql TEXT;
    target_srid INTEGER;
    source_srid INTEGER;

BEGIN
    raise notice 'PROCESSING:';

    -- set vars
    IF min_target_length_ IS NULL THEN
        min_target_length_ := tolerance_ * 2.4;
    END IF;

    -- check columns
    IF NOT tdgColumnCheck(target_table_,target_column_) THEN
        RAISE EXCEPTION 'Column % not found', target_column_;
    END IF;
    IF NOT tdgColumnCheck(target_table_,target_geom_) THEN
        RAISE EXCEPTION 'Column % not found', target_geom_;
    END IF;
    IF NOT tdgColumnCheck(source_table_,source_column_) THEN
        RAISE EXCEPTION 'Column % not found', source_column_;
    END IF;
    IF NOT tdgColumnCheck(source_table_,source_geom_) THEN
        RAISE EXCEPTION 'Column % not found', source_geom_;
    END IF;

    -- srid check
    BEGIN
        RAISE NOTICE 'Getting SRID of target geometry';
        EXECUTE 'SELECT tdgGetSRID($1,$2);'
        USING   target_table_,
                target_geom_
        INTO    target_srid;

        IF target_srid IS NULL THEN
            RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', target_table_;
        END IF;
        raise NOTICE '  -----> SRID found %',target_srid;

        RAISE NOTICE 'Getting SRID of source geometry';
        EXECUTE 'SELECT tdgGetSRID($1,$2);'
        USING   source_table_,
                source_geom_
        INTO    source_srid;

        IF source_srid IS NULL THEN
            RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', source_table_;
        END IF;
        raise NOTICE '  -----> SRID found %',source_srid;

        IF NOT target_srid = source_srid THEN
            RAISE EXCEPTION 'SRID on geometry columns do not match';
        END IF;
    END;

    BEGIN
        -- add buffer geom column
        RAISE NOTICE 'Buffering...';
        EXECUTE '
            ALTER TABLE '||target_table_||'
            ADD COLUMN  tmp_buffer_geom geometry(multipolygon,'||target_srid::TEXT||')';

        sql := '
            UPDATE  '||target_table_||'
            SET     tmp_buffer_geom = ST_Multi(
                        ST_Buffer(
                            '||target_geom_||',
                            '||tolerance_::TEXT||',
                            ''endcap=flat''
                        )
                    )';
        IF only_nulls_ THEN
            EXECUTE sql || ' WHERE '||target_column_||' IS NULL';
        ELSE
            EXECUTE sql;
        END IF;

        -- add buffer index
        RAISE NOTICE 'Indexing buffer...';
        EXECUTE '
            CREATE INDEX tsidx_meldgeom
            ON '||target_table_||'
            USING GIST (tmp_buffer_geom)';
        EXECUTE 'ANALYZE '||target_table_||' (tmp_buffer_geom)';

        -- check for matches
        RAISE NOTICE 'Getting buffer matches';
        sql := '
            UPDATE  '||target_table_||'
            SET     '||target_column_||' = (
                        SELECT      src.'||source_column_||'
                        FROM        '||source_table_||' src
                        WHERE       ST_Intersects(
                                        tmp_buffer_geom,
                                        src.'||source_geom_||'
                                    )
                        AND         ST_Length(
                                        ST_Intersection(
                                            tmp_buffer_geom,
                                            src.'||source_geom_||'
                                        )
                                    ) >= '||min_shared_length_pct_::FLOAT||' * ST_Length('||target_table_||'.'||target_geom_||')
                        ORDER BY    ST_Length(
                                        ST_Intersection(
                                            tmp_buffer_geom,
                                            src.'||source_geom_||'
                                        )
                                    ) DESC
                        LIMIT       1
                    )
            WHERE   ST_Length('||target_table_||'.'||target_geom_||') > '||min_target_length_::TEXT;

        IF only_nulls_ THEN
            EXECUTE sql || ' AND '||target_table_||'.'||target_column_||' IS NULL';
        ELSE
            EXECUTE sql;
        END IF;

        -- drop temporary buffers
        RAISE NOTICE 'Dropping temporary buffers';
        EXECUTE 'ALTER TABLE '||target_table_||' DROP COLUMN tmp_buffer_geom';
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMeldBuffers(REGCLASS,TEXT,TEXT,REGCLASS,TEXT,TEXT,FLOAT,
    FLOAT,FLOAT,BOOLEAN) OWNER TO gis;
