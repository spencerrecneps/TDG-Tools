CREATE OR REPLACE FUNCTION tdgGetSRID(input_table REGCLASS,geom_name TEXT)
RETURNS INT AS $func$

DECLARE
    geomdetails RECORD;

BEGIN
    EXECUTE format ('
        SELECT  ST_SRID(%s) AS srid
        FROM    %s
        WHERE   %s IS NOT NULL LIMIT 1
        ',  geom_name,
            input_table,
            geom_name) INTO geomdetails;

    RETURN geomdetails.srid;
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgGetSRID(REGCLASS,TEXT) OWNER TO gis;
