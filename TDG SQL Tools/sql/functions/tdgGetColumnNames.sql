CREATE OR REPLACE FUNCTION tdg.tdgGetColumnNames(
    input_table_ REGCLASS,
    with_pk_ BOOLEAN)
RETURNS SETOF TEXT AS $func$

BEGIN
    IF with_pk_ THEN
        RETURN QUERY EXECUTE '
            SELECT  a.attname::TEXT AS col_nm
            FROM    pg_attribute a
            WHERE   a.attrelid = $1
            AND     a.attnum > 0
            AND     NOT a.attisdropped;'
        USING input_table_;
    ELSE
        RETURN QUERY EXECUTE '
            SELECT  a.attname::TEXT AS col_nm
            FROM    pg_attribute a
            WHERE   a.attrelid = $1
            AND     a.attnum > 0
            AND     NOT a.attisdropped
            AND     NOT EXISTS (
                        SELECT  1
                        FROM    pg_index i
                        WHERE   a.attrelid = i.indrelid
                        AND     a.attnum = ANY(i.indkey)
            );'
        USING input_table_;
    END IF;

END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgGetColumnNames(REGCLASS,BOOLEAN) OWNER TO gis;
