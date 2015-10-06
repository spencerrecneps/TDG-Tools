CREATE OR REPLACE FUNCTION tdg.tdgRoadGeomUpdate ()
RETURNS TRIGGER
AS $BODY$

--------------------------------------------------------------------------
-- This function is called automatically anytime a change is made to the
-- geometry or intersection z value of a record in a TDG-standardized
-- road layer. It creates an array of changed road_ids and then calls
-- tdgUpdateIntersections() to make updates.
--------------------------------------------------------------------------

DECLARE
    road_table REGCLASS;
    int_table REGCLASS;
    road_ids INTEGER[];
    int_ids INTEGER[];

BEGIN
    -- get the intersection and road tables
    road_table := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME;
    int_table := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME || '_intersections';

    -- gather affected road_ids into an array
    EXECUTE 'SELECT array_agg(road_id) FROM tmp_roadgeomchange'
    INTO    road_ids;

    --suspend triggers on the intersections table so that our
    --changes are not ignored.
    EXECUTE 'ALTER TABLE ' || int_table || ' DISABLE TRIGGER ALL;';

    -- update intersection and road data on affected road_ids
    PERFORM tdgInsertIntersections(int_table,road_table,road_ids);
    PERFORM tdgSetRoadIntersections(int_table,road_table,road_ids);

    --EXECUTE 'ANALYZE ' || road_table;
    --EXECUTE 'ANALYZE ' || int_table;

    -- gather intersections into an array
    EXECUTE '
        SELECT  array_agg(int_id)
        FROM    '||int_table||'
        WHERE EXISTS (  SELECT  1
                        FROM    '||road_table||' roads
                        WHERE   road_id = ANY ($1)
                        AND     ('||int_table||'.int_id = roads.intersection_from
                                OR '||int_table||'.int_id = roads.intersection_to));'
    USING   road_ids
    INTO    int_ids;

    -- update legs on intersections
    PERFORM tdgSetIntersectionLegs(int_table,road_table,int_ids);

    -- remove obsolete intersections
    EXECUTE '
        DELETE FROM '||int_table||'
        WHERE NOT EXISTS (  SELECT  1
                            FROM    '||road_table||' roads
                            WHERE   '||int_table||'.int_id = roads.intersection_from
                            OR      '||int_table||'.int_id = roads.intersection_to);';

    --re-enable triggers on the intersections table
    EXECUTE 'ALTER TABLE ' || int_table || ' ENABLE TRIGGER ALL;';

    DROP TABLE tmp_roadgeomchange;

    RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgRoadGeomUpdate() OWNER TO gis;
