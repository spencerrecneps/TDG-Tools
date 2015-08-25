CREATE OR REPLACE FUNCTION tdgGenerateIntersectionStreets (input_table REGCLASS, intids INT[])
RETURNS BOOLEAN AS $func$

DECLARE

BEGIN

RETURN 't';
END $func$ LANGUAGE plpgsql;
