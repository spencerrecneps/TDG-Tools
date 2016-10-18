CREATE OR REPLACE FUNCTION tdg.tdgMeldPointSeries(
    target_table_ REGCLASS,
    target_column_ TEXT,
    target_geom_ TEXT,
    source_table_ REGCLASS,
    source_column_ TEXT,
    source_geom_ TEXT,
    tolerance_ FLOAT,
    min_target_length_ FLOAT DEFAULT NULL,
    num_points_ INTEGER DEFAULT 3,
    max_avg_error_ FLOAT DEFAULT NULL,
    only_nulls_ BOOLEAN DEFAULT 't',
    nullify_ BOOLEAN DEFAULT 'f'
)
RETURNS BOOLEAN AS $func$

DECLARE
    sql TEXT;
    target_srid INTEGER;
    source_srid INTEGER;
    target_pkid TEXT;
    source_pkid TEXT;

BEGIN
    raise notice 'PROCESSING:';

    -- set vars
    IF max_avg_error_ IS NULL THEN
        max_avg_error_ := tolerance_;
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

        -- create points table
        RAISE NOTICE 'Setting points';
        EXECUTE '
            CREATE TEMP TABLE tmp_meld_points (
                id SERIAL PRIMARY KEY,
                target_id INTEGER,
                series_no INTEGER,
                geom geometry(point,'||target_srid||')
            )
            ON COMMIT DROP;'

        EXECUTE '
            INSERT INTO tmp_meld_points (
                target_id, series_no, geom
            )
            SELECT  '||target_pkid||',
                    i,
                    ST_LineInterpolatePoint(
                        '||target_table_||'.'||target_geom_||',
                        i::FLOAT/'||num_points_||'          !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                    )
            FROM    '||target_table_||',
                    generate_series(1,'||num_points_||') i'

        EXECUTE 'CREATE INDEX tidx_tmpmldptstgtid ON tmp_meld_points (target_id)';
        EXECUTE 'CREATE INDEX tsidx_tmpmldptsgeom ON tmp_meld_points USING GIST (geom)';
        EXECUTE 'ANALYZE tmp_meld_points';

        -- check for matches
        RAISE NOTICE 'Getting azimuth matches';
        sql := '
            UPDATE  '||target_table_||'
            SET     '||target_column_||' = (
                        SELECT      src.'||source_column_||'
                        FROM        '||source_table_||' src,
                                    tmp_meld_points
                        WHERE       '||target_table_||'.'||target_pkid||' = tmp_meld_points.target_id
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                        LIMIT       1
                    )';

        IF only_nulls_ THEN
            EXECUTE sql || ' AND '||target_table_||'.'||target_column_||' IS NULL';
        ELSE
            EXECUTE sql;
        END IF;

    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgMeldPointSeries(REGCLASS,TEXT,TEXT,REGCLASS,TEXT,TEXT,FLOAT,
    FLOAT,INTEGER,FLOAT,BOOLEAN,BOOLEAN) OWNER TO gis;
