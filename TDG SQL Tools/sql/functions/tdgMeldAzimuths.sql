CREATE OR REPLACE FUNCTION tdg.tdgMeldAzimuths(
    target_table_ REGCLASS,
    target_column_ TEXT,
    target_geom_ TEXT,
    source_table_ REGCLASS,
    source_column_ TEXT,
    source_geom_ TEXT,
    tolerance_ FLOAT,
    buffer_geom_ TEXT DEFAULT NULL,
    max_angle_diff_ INTEGER DEFAULT 15,
    line_start_ FLOAT DEFAULT 0.33,
    line_end_ FLOAT DEFAULT 0.67,
    only_nulls_ BOOLEAN DEFAULT 't',
    nullify_ BOOLEAN DEFAULT 'f'
)
RETURNS BOOLEAN AS $func$

DECLARE
    sql TEXT;
    target_srid INTEGER;
    source_srid INTEGER;
    buffer_srid INTEGER;
    temp_buffers BOOLEAN;
    target_pkid TEXT;
    source_pkid TEXT;

BEGIN
    raise notice 'PROCESSING:';

    -- check columns
    IF NOT tdgColumnCheck(target_table_,target_column_) THEN
        RAISE EXCEPTION 'Column % not found', target_column_;
    END IF;
    IF NOT tdgColumnCheck(target_table_,target_geom_) THEN
        RAISE EXCEPTION 'Column % not found', target_geom_;
    END IF;
    IF buffer_geom_ IS NOT NULL AND NOT tdgColumnCheck(target_table_,buffer_geom_) THEN
        RAISE EXCEPTION 'Column % not found', buffer_geom_;
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
        target_srid := tdgGetSRID(target_table_,target_geom_);
        IF target_srid IS NULL THEN
            RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', target_table_;
        END IF;
        raise NOTICE '  -----> SRID found %',target_srid;

        RAISE NOTICE 'Getting SRID of source geometry';
        source_srid := tdgGetSRID(source_table_,source_geom_);
        IF source_srid IS NULL THEN
            RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', source_table_;
        END IF;
        raise NOTICE '  -----> SRID found %',source_srid;

        IF NOT target_srid = source_srid THEN
            RAISE EXCEPTION 'SRID on geometry columns do not match';
        END IF;

        IF buffer_geom_ IS NOT NULL THEN
            RAISE NOTICE 'Getting SRID of buffer geometry';
            buffer_srid := tdgGetSRID(target_table_,buffer_geom_);
            IF NOT target_srid = buffer_srid THEN
                RAISE EXCEPTION 'SRID on geometry columns do not match';
            END IF;
        END IF;
    END;

    -- get target and source pkid columns
    target_pkid := tdg.tdgGetPkColumn(target_table_);
    source_pkid := tdg.tdgGetPkColumn(source_table_);

    BEGIN
        -- set nulls
        IF nullify_ THEN
            EXECUTE '
                UPDATE  '||target_table_||'
                SET     '||target_column_||' = NULL';
        END IF;

        -- add buffer geom column
        IF buffer_geom_ IS NULL THEN
            temp_buffers := 't';
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

            buffer_geom_ := 'tmp_buffer_geom';
        ELSE
            temp_buffers := 'f';
        END IF;

        -- check for matches
        RAISE NOTICE 'Getting azimuth matches';
        sql := '
            WITH target_azi AS (
                SELECT  '||target_pkid' AS id,
                        ST_Azimuth(
                            ST_LineInterpolatePoint(
                                src.'||target_geom_||',
                                '||line_start_::TEXT||'
                            ),
                            ST_LineInterpolatePoint(
                                src.'||target_geom_||',
                                '||line_end_::TEXT||'
                            )
                        )
            ),
            source_azi AS (
                SELECT  '||source_pkid||' AS id
                        ST_Azimuth(
                            ST_LineInterpolatePoint(
                                src.'||source_geom_||',
                                '||line_start_::TEXT||'
                            ),
                            ST_LineInterpolatePoint(
                                src.'||source_geom_||',
                                '||line_end_::TEXT||'
                            )
                        )
            )
            UPDATE  '||target_table_||'
            SET     '||target_column_||' = (
                        SELECT      src.'||source_column_||'
                        FROM        '||source_table_||' src,
                                    target_azi,
                                    source_azi
                        WHERE       '||target_table_||'.'||target_pkid||' = target_azi.id
                        AND         '||source_table_||'.'||source_pkid||' = source_azi.id
                        AND         ST_Intersects(
                                        '||target_table_||'.'||buffer_geom_||',
                                        src.'||source_geom_||'
                                    )
                        AND         '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                        ORDER BY    ST_Distance(
                                        ST_LineInterpolatePoint(
                                            '||target_table_||'.'||target_geom_||',
                                            '||line_start_::TEXT||'
                                        ),
                                        src.'||source_geom_||'
                                    ) + ST_Distance(
                                        ST_LineInterpolatePoint(
                                            '||target_table_||'.'||target_geom_||',
                                            '||line_end_::TEXT||'
                                        ),
                                        src.'||source_geom_||'
                                    ) / 2
                                    ASC
                        LIMIT       1
                    )';

        IF only_nulls_ THEN
            EXECUTE sql || ' AND '||target_table_||'.'||target_column_||' IS NULL';
        ELSE
            EXECUTE sql;
        END IF;

        IF temp_buffers THEN
            -- drop temporary buffers
            RAISE NOTICE 'Dropping temporary buffers';
            EXECUTE 'ALTER TABLE '||target_table_||' DROP COLUMN tmp_buffer_geom';
        END IF;
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMeldAzimuths(REGCLASS,TEXT,TEXT,REGCLASS,TEXT,TEXT,FLOAT,
    TEXT,INTEGER,FLOAT,FLOAT,BOOLEAN,BOOLEAN) OWNER TO gis;
