CREATE OR REPLACE FUNCTION tdg.tdgUpdateIntersections(
    road_table_ REGCLASS,
    int_table_ REGCLASS,
    road_ids_ INTEGER[]
)
RETURNS TRIGGER
AS $BODY$

--------------------------------------------------------------------------
-- This function update road and intersection information based on
-- a set of road_ids passed in as an array.
--------------------------------------------------------------------------

DECLARE
    int_ids INTEGER[];

BEGIN
    --suspend triggers on the intersections table so that our
    --changes are not ignored.
    EXECUTE 'ALTER TABLE ' || int_table_ || ' DISABLE TRIGGER ALL;';

    --identify affected intersections
    EXECUTE '
        SELECT ARRAY(
            SELECT  intersection_from
            FROM  ' || road_table_ || '
            WHERE road_id = ANY ($1);
        )';
    USING   road_ids_
    INTO    int_ids;

    --update intersection leg count
    BEGIN
        RAISE NOTICE 'Updating intersections';

        --road start points first
        EXECUTE '
            UPDATE  ' || int_table_ || '
            SET legs = (SELECT  COUNT(road_id)
                        FROM  ' || road_table_ || ' r
                        WHERE ' || int_table_ || '.int_id = ANY (int_ids)
                        AND   ' || int_table_ || '.geom = ST_StartPoint(r.geom)
                        AND   ' || int_table_ || '.z_elev = r.z_from;)'
        USING   int_ids;
        --road end points next
        EXECUTE '
            UPDATE  ' || int_table_ || '
            SET legs = legs + ( SELECT  COUNT(road_id)
                                FROM  ' || road_table_ || ' r
                                WHERE ' || int_table_ || '.int_id = ANY (int_ids)
                                AND   ' || int_table_ || '.geom = ST_EndPoint(r.geom)
                                AND   ' || int_table_ || '.z_elev = r.z_to;)'
        USING   int_ids;
    END;

    --update from/to intersections on roads
    BEGIN
        RAISE NOTICE 'Updating road intersection info';

        --road start points first
        EXECUTE '
            UPDATE  ' || road_table_ || '
            SET intersection_from = ints.int_id
            FROM    ' || int_table_ || ' ints
            WHERE   ' || road_table_ || '.road_id = ANY ($1)
            AND     ST_StartPoint(' || road_table_ || '.geom) = ints.geom
            AND     ' || road_table_ || '.z_from = ints.z_elev;'
        USING   road_ids_;
        --road end points next
        EXECUTE '
            UPDATE  ' || road_table_ || '
            SET intersection_to = ints.int_id
            FROM    ' || int_table_ || ' ints
            WHERE   ' || road_table_ || '.road_id = ANY ($1)
            AND     ST_EndPoint(' || road_table_ || '.geom) = ints.geom
            AND     ' || road_table_ || '.z_to = ints.z_elev;'
        USING   road_ids_;
    END;

    --re-enable triggers on the intersections table
    EXECUTE 'ALTER TABLE ' || int_table_ || ' ENABLE TRIGGER ALL;';

END;
$BODY$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgUpdateIntersections(REGCLASS,REGCLASS,INTEGER[]) OWNER TO gis;
