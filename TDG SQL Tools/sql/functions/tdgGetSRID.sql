CREATE OR REPLACE FUNCTION tdg.tdgGetSRID(input_table_ REGCLASS,geom_column_ TEXT)
RETURNS INT AS $func$

DECLARE
    geomdetails RECORD;

BEGIN
    EXECUTE '
        SELECT  ST_SRID('|| geom_column_ || ') AS srid
        FROM    ' || input_table_ || '
        WHERE   $1 IS NOT NULL LIMIT 1'
    USING   --geom_column_,
            --input_table_,
            geom_column_
    INTO    geomdetails;

    RETURN geomdetails.srid;
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgGetSRID(REGCLASS,TEXT) OWNER TO gis;
