CREATE OR REPLACE FUNCTION tdgGenerateCrossStreetData(base_table REGCLASS)
--populate cross-street data
RETURNS BOOLEAN AS $func$

DECLARE
    schema_name TEXT;
    table_name TEXT;
    tablelink REGCLASS;
    tablevert REGCLASS;
    tableturnrestrict REGCLASS;

BEGIN
    raise notice 'PROCESSING:';

    --get schema
    BEGIN
        RAISE NOTICE 'Checking % is network layer',base_table;
        EXECUTE '   SELECT  schema_name, table_name
                    FROM    tdgTableDetails($1::TEXT)'
        USING   base_table
        INTO    schema_name, table_name;
        RAISE NOTICE 'Schema is %', schema_name;

        --get network tables
        --  (returns error if table doesn't exist so this also
        --  checks to make sure this is a true network layer)
        tablelink := schema_name||'.'||table_name||'_net_link';
        tablevert := schema_name||'.'||table_name||'_net_vert';
        tableturnrestrict := schema_name||'.'||table_name||'_turn_restriction';
    END;

    BEGIN
        RAISE NOTICE 'Clearing old values';
        EXECUTE '
            UPDATE ' || base_table || '
            SET     road_from = NULL,
                    road_to = NULL;';
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
            ',  base_table,
                tablevert,
                base_table,
                base_table,
                base_table);
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
            ',  base_table,
                tablevert,
                base_table,
                base_table,
                base_table);

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
            ',  base_table,
                tablevert,
                base_table,
                base_table,
                base_table,
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
            ',  base_table,
                tablevert,
                base_table,
                base_table,
                base_table,
                tablevert);
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgGenerateCrossStreetData(REGCLASS) OWNER TO gis;
