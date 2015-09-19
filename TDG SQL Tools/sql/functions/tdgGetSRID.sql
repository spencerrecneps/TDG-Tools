CREATE OR REPLACE FUNCTION tdg.tdgGetSRID(input_table REGCLASS,geom_name TEXT)
RETURNS INT AS $func$

DECLARE
    geomdetails RECORD;

BEGIN
    EXECUTE '
        SELECT  ST_SRID('|| geom_name || ') AS srid
        FROM    ' || input_table || '
        WHERE   $1 IS NOT NULL LIMIT 1'
    USING   --geom_name,
            --input_table,
            geom_name
    INTO    geomdetails;

    RETURN geomdetails.srid;
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgGetSRID(REGCLASS,TEXT) OWNER TO gis;
