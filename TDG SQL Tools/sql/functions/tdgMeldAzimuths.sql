CREATE OR REPLACE FUNCTION tdg.tdgMeldBuffers(
    target_table_ REGCLASS,
    target_column_ TEXT,
    target_geom_ TEXT,
    source_table_ REGCLASS,
    source_column_ TEXT,
    source_geom_ TEXT,
    tolerance_ FLOAT,
    max_angle_diff_ INTEGER DEFAULT 15,
    line_start_ FLOAT DEFAULT 0.33,
    line_end_ FLOAT DEFAULT 0.67,
    only_nulls_ BOOLEAN DEFAULT 't'
)
RETURNS BOOLEAN AS $func$

DECLARE
    sql TEXT;
    target_srid INTEGER;
    source_srid INTEGER;

BEGIN
    raise notice 'PROCESSING:';

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
        -- check for matches
        RAISE NOTICE 'Getting azimuth matches';
        sql := '
            UPDATE  '||target_table_||'
            SET     '||target_column_||' = (
                        SELECT      src.'||source_column_||'
                        FROM        '||source_table_||' src
                        WHERE       ST_DWithin(
                                        '||target_table_||'.'||target_geom_||',
                                        src.'||source_geom_||',
                                        '||tolerance_::TEXT||'
                                    )
                        AND         ST_Intersects(
                                        ST_Buffer(
                                            '||target_table_||'.'||target_geom_||',
                                            'tolerance_::TEXT'
                                        ),
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
    BOOLEAN,FLOAT,FLOAT) OWNER TO gis;
