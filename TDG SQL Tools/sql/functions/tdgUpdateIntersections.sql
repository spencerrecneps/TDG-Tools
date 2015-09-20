CREATE OR REPLACE FUNCTION tdg.tdgUpdateIntersections(
    road_table_ REGCLASS,
    int_table_ REGCLASS
)
RETURNS BOOLEAN
AS $BODY$

--------------------------------------------------------------------------
-- This function update road and intersection information based on
-- a set of road_ids passed in as an array.
--------------------------------------------------------------------------

BEGIN
    --suspend triggers on the intersections table so that our
    --changes are not ignored.
    EXECUTE 'ALTER TABLE ' || int_table_ || ' DISABLE TRIGGER ALL;';

    --update intersection leg count
    BEGIN
        RAISE NOTICE 'Updating intersections';

        --update intersection leg counts
        EXECUTE '
            UPDATE  '||int_table_||'
            SET     legs = (SELECT  COUNT(roads.road_id)
                            FROM    '||road_table_||' roads
                            WHERE   '||int_table_||'.int_id
                                        IN (roads.intersection_from,roads.intersection_to))
            WHERE   int_id IN ( SELECT new_int_from FROM tmp_roadgeomchange
                                UNION
                                SELECT new_int_to FROM tmp_roadgeomchange
                                UNION
                                SELECT old_int_from FROM tmp_roadgeomchange
                                UNION
                                SELECT old_int_to FROM tmp_roadgeomchange);';
    END;

    --delete intersections with no legs
    EXECUTE 'DELETE FROM ' || int_table_ || ' WHERE legs < 1;';

    --re-enable triggers on the intersections table
    EXECUTE 'ALTER TABLE ' || int_table_ || ' ENABLE TRIGGER ALL;';

    RETURN 't';
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgUpdateIntersections(REGCLASS,REGCLASS) OWNER TO gis;
