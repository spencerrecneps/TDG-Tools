CREATE OR REPLACE FUNCTION tdgGenerateCrossStreetData(input_table REGCLASS)
--populate cross-street data
RETURNS BOOLEAN AS $func$

DECLARE
    tablecheck TEXT;
    namecheck record;
    tablevert TEXT;

BEGIN
    raise notice 'PROCESSING:';

    --get schema
    BEGIN
        --net link
        RAISE NOTICE 'Checking % is network layer',input_table;
        tablecheck := '';
        tablecheck := input_table || '_net_link';
        RAISE NOTICE 'Checking for %',tablecheck;
        EXECUTE '   SELECT  schema_name,
                            table_name
                    FROM    tdgTableDetails('||quote_literal(tablecheck)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
        IF namecheck.schema_name IS NULL OR namecheck.table_name IS NULL THEN
            RAISE NOTICE '-------> % not found',tablecheck;
            RETURN 'f';
        ELSE
            RAISE NOTICE '  -----> OK';
        END IF;

        --net vert
        tablecheck := '';
        namecheck := NULL;
        tablecheck := input_table || '_net_vert';
        RAISE NOTICE 'Checking for %',tablecheck;
        EXECUTE '   SELECT  schema_name,
                            table_name
                    FROM    tdgTableDetails('||quote_literal(tablecheck)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
        IF namecheck.schema_name IS NULL OR namecheck.table_name IS NULL THEN
            RAISE NOTICE '-------> % not found',tablecheck;
            RETURN 'f';
        ELSE
            tablevert := namecheck.schema_name||'.'||namecheck.table_name;
            RAISE NOTICE '  -----> OK';
        END IF;

        --turn restriction
        tablecheck := '';
        namecheck := NULL;
        tablecheck := input_table || '_turn_restriction';
        RAISE NOTICE 'Checking for %',tablecheck;
        EXECUTE '   SELECT  schema_name,
                            table_name
                    FROM    tdgTableDetails('||quote_literal(tablecheck)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
        IF namecheck.schema_name IS NULL OR namecheck.table_name IS NULL THEN
            RAISE NOTICE '-------> % not found',tablecheck;
            RETURN 'f';
        ELSE
            RAISE NOTICE '  -----> OK';
        END IF;


    END;

    BEGIN
        RAISE NOTICE 'Clearing old values';
        EXECUTE format('
            UPDATE  %s
            SET     road_from = NULL,
                    road_to = NULL;
            ',  input_table);
    END;

    BEGIN
        --ignore culs-de-sac (order 1)
        --get road names of no intersection (order 2)
        --from streets
        RAISE NOTICE 'Assigning from streets, node order 2';
        EXECUTE format('
            UPDATE  %s
            SET     road_from = r.road_name
            FROM    %s v,
                    %s r
            WHERE   v.node_order = 2
            AND     %s.source = v.id
            AND     v.id IN (r.source,r.target)
            AND     %s.id != r.id;
            ',  input_table,
                tablevert,
                input_table,
                input_table,
                input_table);
        --to streets
        RAISE NOTICE 'Assigning to streets, node order 2';
        EXECUTE format('
            UPDATE  %s
            SET     road_to = r.road_name
            FROM    %s v,
                    %s r
            WHERE   v.node_order = 2
            AND     %s.target = v.id
            AND     v.id IN (r.source,r.target)
            AND     %s.id != r.id;
            ',  input_table,
                tablevert,
                input_table,
                input_table,
                input_table);

        --get road name of leg nearest to 90 degrees
        --from streets
        RAISE NOTICE 'Assigning from streets, node order >2';
        EXECUTE format('
            WITH    x1 AS ( SELECT  a.id AS this_id,
                                    b.id AS xing_id,
                                    b.road_name AS xing_name,
                                    ST_Intersection(ST_Buffer(v.geom,10),a.geom) AS this_geom,
                                    ST_Intersection(ST_Buffer(v.geom,10),b.geom) AS xing_geom
                            FROM    %s a,
                                    %s v,
                                    %s b
                            WHERE   a.source = v.id
                            AND     v.node_order > 2
                            AND     v.id IN (b.source,b.target)
                            AND     a.id != b.id),
                    x2 AS ( SELECT  this_id,
                                    xing_id,
                                    xing_name,
                                    degrees(ST_Azimuth(ST_StartPoint(this_geom),ST_EndPoint(this_geom)))::numeric AS this_azi,
                                    degrees(ST_Azimuth(ST_StartPoint(xing_geom),ST_EndPoint(xing_geom)))::numeric AS xing_azi
                            FROM    x1)
            UPDATE  %s
            SET     road_from =(SELECT      x2.xing_name
                                FROM        x2
                                WHERE       %s.id = x2.this_id
                                ORDER BY    ABS(90 - (mod(mod(360 + x2.xing_azi - x2.this_azi, 360), 180) )) ASC
                                LIMIT       1)
            FROM    %s v
            WHERE   source = v.id
            AND     v.node_order > 2;
            ',  input_table,
                tablevert,
                input_table,
                input_table,
                input_table,
                tablevert);
        --to streets
        EXECUTE format('
            WITH    x1 AS ( SELECT  a.id AS this_id,
                                    b.id AS xing_id,
                                    b.road_name AS xing_name,
                                    ST_Intersection(ST_Buffer(v.geom,10),a.geom) AS this_geom,
                                    ST_Intersection(ST_Buffer(v.geom,10),b.geom) AS xing_geom
                            FROM    %s a,
                                    %s v,
                                    %s b
                            WHERE   a.target = v.id
                            AND     v.node_order > 2
                            AND     v.id IN (b.source,b.target)
                            AND     a.id != b.id),
                    x2 AS ( SELECT  this_id,
                                    xing_id,
                                    xing_name,
                                    degrees(ST_Azimuth(ST_StartPoint(this_geom),ST_EndPoint(this_geom)))::numeric AS this_azi,
                                    degrees(ST_Azimuth(ST_StartPoint(xing_geom),ST_EndPoint(xing_geom)))::numeric AS xing_azi
                            FROM    x1)
            UPDATE  %s
            SET     road_to =(  SELECT      x2.xing_name
                                FROM        x2
                                WHERE       %s.id = x2.this_id
                                ORDER BY    ABS(90 - (mod(mod(360 + x2.xing_azi - x2.this_azi, 360), 180) )) ASC
                                LIMIT       1)
            FROM    %s v
            WHERE   target = v.id
            AND     v.node_order > 2;
            ',  input_table,
                tablevert,
                input_table,
                input_table,
                input_table,
                tablevert);
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgGenerateCrossStreetData(REGCLASS) OWNER TO gis;
