CREATE OR REPLACE FUNCTION tdgMakeNetwork(input_table REGCLASS)
--need triggers to automatically update vertices and links
RETURNS BOOLEAN AS $func$

DECLARE
    schema_name text;
    table_name text;
    namecheck record;
    query text;
    sourcetable text;
    verttable text;
    linktable text;
    turnrestricttable text;
    inttable text;
    srid int;
    indexcheck TEXT;
    intersection_ids INT[];

BEGIN
    RAISE NOTICE 'PROCESSING:';


    --check table and schema
    BEGIN
        RAISE NOTICE 'Checking % exists',input_table;
        EXECUTE '   SELECT  schema_name,
                            table_name
                    FROM    tdgTableDetails('||quote_literal(input_table)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
        schema_name=namecheck.schema_name;
        table_name=namecheck.table_name;
        IF schema_name IS NULL OR table_name IS NULL THEN
    	    RAISE NOTICE '-------> % not found',input_table;
            RETURN 'f';
        ELSE
    	    RAISE NOTICE '  -----> OK';
        END IF;

        sourcetable = schema_name || '.' || table_name;
        verttable = schema_name || '.' || table_name || '_net_vert';
        linktable = schema_name || '.' || table_name || '_net_link';
        turnrestricttable = schema_name || '.' || table_name || '_turn_restriction';
        inttable = schema_name || '.' || table_name || '_intersections';
    END;


    --check for from/to/cost columns
    BEGIN
        RAISE NOTICE 'checking for source/target columns';
        IF tdgColumnCheck(table_name,'source') = 't' THEN
            EXECUTE format('
                UPDATE %s SET source=NULL;
                ',  sourcetable);
        ELSE
            EXECUTE format('
                ALTER TABLE %s ADD COLUMN source INT;
                ',  sourcetable);
        END IF;
        IF tdgColumnCheck(table_name,'target') = 't' THEN
            EXECUTE format('
                UPDATE %s SET target=NULL;
                ',  sourcetable);
        ELSE
            EXECUTE format('
                ALTER TABLE %s ADD COLUMN target INT;
                ',  sourcetable);
        END IF;
        IF tdgColumnCheck(table_name,'ft_cost') = 't' THEN
            EXECUTE format('
                UPDATE %s SET ft_cost=NULL;
                ',  sourcetable);
        ELSE
            EXECUTE format('
                ALTER TABLE %s ADD COLUMN ft_cost INT;
                ',  sourcetable);
        END IF;
        IF tdgColumnCheck(table_name,'tf_cost') = 't' THEN
            EXECUTE format('
                UPDATE %s SET tf_cost=NULL;
                ',  sourcetable);
        ELSE
            EXECUTE format('
                ALTER TABLE %s ADD COLUMN tf_cost INT;
                ',  sourcetable);
        END IF;
    END;


    --get srid of the geom
    BEGIN
        EXECUTE format('SELECT tdgGetSRID(to_regclass(%L),%s)',input_table,quote_literal('geom')) INTO srid;

        IF srid IS NULL THEN
            RAISE NOTICE 'ERROR: Can not determine the srid of the geometry in table %', t_name;
            RETURN 'f';
        END IF;
        RAISE NOTICE '  -----> SRID found %',srid;
    END;


    --drop old tables
    BEGIN
        RAISE NOTICE 'dropping tables';
        EXECUTE format('
            DROP TABLE IF EXISTS %s;
            DROP TABLE IF EXISTS %s;
            DROP TABLE IF EXISTS %s;
            ',  turnrestricttable,
                verttable,
                linktable);
    END;


    --create new tables
    BEGIN
        RAISE NOTICE 'creating new tables';
        EXECUTE format('
            CREATE TABLE %s (   node_id serial PRIMARY KEY,
                                intersection_id INT,
                                node_cost INT,
                                geom geometry(point,%L));
            ',  verttable,
                srid);

        EXECUTE format('
            CREATE TABLE %s (   from_id integer NOT NULL,
                                to_id integer NOT NULL,
                                CONSTRAINT %I CHECK (from_id <> to_id));
            ',  turnrestricttable,
                turnrestricttable || '_trn_rstrctn_check');

        EXECUTE format('
            CREATE TABLE %s (   id serial primary key,
                                road_id INT,
                                source_node INT,
                                target_node INT,
                                intersection_id INT,
                                direction VARCHAR(2),
                                movement TEXT,
                                link_cost INT,
                                link_stress INT,
                                geom geometry(linestring,%L));
            ',  linktable,
                srid);
    END;


    --indexes
    BEGIN
        RAISE NOTICE 'creating indexes';
        EXECUTE format('
            CREATE INDEX %s ON %s USING gist (geom);
            CREATE INDEX %s ON %s (intersection_id);
            CREATE INDEX %s ON %s (road_id);
            CREATE INDEX %s ON %s (direction);
            CREATE INDEX %s ON %s (source_node,target_node);
            ',  'sidx_' || table_name || 'vert_geom',
                verttable,
                'idx_' || table_name || 'vert_intid',
                verttable,
                'idx_' || table_name || '_link_road_id',
                linktable,
                'idx_' || table_name || '_link_direction',
                linktable,
                'idx_' || table_name || '_link_src_trgt',
                linktable);
        EXECUTE format('SELECT to_regclass(%L)', quote_literal(schema_name||'.idx_'||table_name||'_srctrgt')) INTO indexcheck;
        IF indexcheck IS NOT NULL THEN
            EXECUTE format('
                CREATE INDEX %s ON %s (source,target);
                ',  'idx_' || table_name || '_srctrgt',
                    sourcetable);
        END IF;
    END;


    --create temporary table of all possible vertices
    EXECUTE format('
        CREATE TEMP TABLE v (   id SERIAL PRIMARY KEY,
                                road_id INT,
                                vert_id INT,
                                int_id INT,
                                loc VARCHAR(1),
                                int_geom geometry(point,%L),
                                vert_geom geometry(point,%L))
        ON COMMIT DROP;
        ',  srid,
            srid);


    --insert vertices
    BEGIN
        RAISE NOTICE 'adding points to vertices table';

        EXECUTE format('
            INSERT INTO v (road_id, loc, int_geom, vert_geom)
            SELECT      id,
                        %L,
                        ST_StartPoint(geom),
                        ST_LineInterpolatePoint(s.geom,LEAST(0.5*ST_Length(s.geom)-5,4)/ST_Length(s.geom))
            FROM        %s s
            ORDER BY    id ASC;
            ',  'f',
                sourcetable);

        EXECUTE format('
            INSERT INTO v (road_id, loc, int_geom, vert_geom)
            SELECT      id,
                        %L,
                        ST_EndPoint(geom),
                        ST_LineInterpolatePoint(s.geom,GREATEST(0.5*ST_Length(s.geom)+5,ST_Length(s.geom)-4)/ST_Length(s.geom))
            FROM        %s s
            ORDER BY    id ASC;
            ',  't',
                sourcetable);

        --get intersections for v
        EXECUTE format('
            UPDATE  v
            SET     int_id = intersection.id
            FROM    %s intersection
            WHERE   v.int_geom = intersection.geom;
            ',  inttable);

        --insert points into vertices table
        EXECUTE format('
            INSERT INTO %s (intersection_id, geom)
            SELECT      intersection.id,
                        v.vert_geom
            FROM        v,
                        %s intersection
            WHERE       v.int_id = intersection.id
            AND         intersection.legs > 2
            GROUP BY    intersection.id,
                        v.vert_geom;
            ',  verttable,
                inttable);

        EXECUTE format('
            INSERT INTO %s (intersection_id, geom)
            SELECT      intersection.id,
                        v.int_geom
            FROM        v,
                        %s intersection
            WHERE       v.int_id = intersection.id
            AND         intersection.legs < 3
            GROUP BY    intersection.id,
                        v.int_geom;
            ',  verttable,
                inttable);
    END;


    --join back the vertices to v
    BEGIN
        EXECUTE format('
            UPDATE  v
            SET     vert_id = vx.node_id
            FROM    %s vx
            WHERE   v.vert_geom = vx.geom;
            ',  verttable);
        EXECUTE format('
            UPDATE  v
            SET     vert_id = vx.node_id
            FROM    %s vx
            WHERE   v.int_geom = vx.geom;
            ',  verttable);
    END;


    --populate direct links
    BEGIN
        RAISE NOTICE 'adding links';
        EXECUTE format('
            CREATE TEMP TABLE lengths ( id SERIAL PRIMARY KEY,
                                        len FLOAT,
                                        f_point geometry(point, %L),
                                        t_point geometry(point, %L),
                                        f_int_id INT,
                                        t_int_id INT)
            ON COMMIT DROP;
            ',  srid,
                srid);

        EXECUTE format('
            INSERT INTO lengths (id, len, f_point, t_point, f_int_id, t_int_id)
            SELECT  s.id,
                    ST_Length(s.geom) AS len,
                    CASE    WHEN f_int.legs > 2
                            THEN vf.vert_geom
                            ELSE vf.int_geom
                            END AS f_point,
                    CASE    WHEN t_int.legs > 2
                            THEN vt.vert_geom
                            ELSE vt.int_geom
                            END AS t_point,
                    vf.int_id,
                    vt.int_id
            FROM    %s s,
                    v vf,
                    %s f_int,
                    v vt,
                    %s t_int
            WHERE   s.id = vf.road_id AND vf.loc = %L
            AND     vf.int_id = f_int.id
            AND     s.id = vt.road_id AND vt.loc = %L
            AND     vt.int_id = t_int.id;
            ',  input_table,
                inttable,
                inttable,
                'f',
                't');

        --links - self segment ft
        EXECUTE format('
            INSERT INTO %s (geom,
                            direction,
                            road_id,
                            link_cost,
                            link_stress)
            SELECT  ST_Makeline(l.f_point,l.t_point),
                    %L,
                    r.id,
                    r.ft_cost,
                    GREATEST(r.ft_seg_stress,r.ft_int_stress)
            FROM    %s r,
                    lengths l
            WHERE   r.id=l.id
            AND     (r.one_way IS NULL OR r.one_way = %L);
            ',  linktable,
                'ft',
                sourcetable,
                'ft');

        --links - self segment tf
        EXECUTE format('
            INSERT INTO %s (geom,
                            direction,
                            road_id,
                            link_cost,
                            link_stress)
            SELECT  ST_Makeline(l.t_point,l.f_point),
                    %L,
                    r.id,
                    r.tf_cost,
                    GREATEST(r.tf_seg_stress,r.tf_int_stress)
            FROM    %s r,
                    lengths l
            WHERE   r.id=l.id
            AND     (r.one_way IS NULL OR r.one_way = %L);
            ',  linktable,
                'tf',
                sourcetable,
                'tf');
        --
        -- --from end to start
        -- EXECUTE format('
        --     INSERT INTO %s (geom,
        --                     direction,
        --                     intersection_id)
        --     SELECT  ST_Makeline(fl.t_point,tl.f_point),
        --             %L,
        --             fl.t_int_id
        --     FROM    %s f,
        --             %s t,
        --             lengths fl,
        --             lengths tl
        --     WHERE   f.id != t.id
        --     AND     f.target = t.source
        --     AND     f.id = fl.id
        --     AND     t.id = tl.id
        --     AND     (f.one_way IS NULL OR f.one_way = %L)
        --     AND     (t.one_way IS NULL OR t.one_way = %L);
        --     ',  linktable,
        --         'ft',
        --         sourcetable,
        --         sourcetable,
        --         'ft',
        --         'ft');
        --
        -- --from end to end
        -- EXECUTE format('
        --     INSERT INTO %s (geom,
        --                     direction,
        --                     intersection_id)
        --     SELECT  ST_Makeline(fl.t_point,tl.t_point),
        --             %L,
        --             fl.t_int_id
        --     FROM    %s f,
        --             %s t,
        --             lengths fl,
        --             lengths tl
        --     WHERE   f.id != t.id
        --     AND     f.target = t.target
        --     AND     f.id = fl.id
        --     AND     t.id = tl.id
        --     AND     (f.one_way IS NULL OR f.one_way = %L)
        --     AND     (t.one_way IS NULL OR t.one_way = %L);
        --     ',  linktable,
        --         'ft',
        --         sourcetable,
        --         sourcetable,
        --         'ft',
        --         'tf');
        --
        -- --from start to end
        -- EXECUTE format('
        --     INSERT INTO %s (geom,
        --                     direction,
        --                     intersection_id)
        --     SELECT  ST_Makeline(fl.f_point,tl.t_point),
        --             %L,
        --             fl.f_int_id
        --     FROM    %s f,
        --             %s t,
        --             lengths fl,
        --             lengths tl
        --     WHERE   f.id != t.id
        --     AND     f.source = t.target
        --     AND     f.id = fl.id
        --     AND     t.id = tl.id
        --     AND     (f.one_way IS NULL OR f.one_way = %L)
        --     AND     (t.one_way IS NULL OR t.one_way = %L);
        --     ',  linktable,
        --         'ft',
        --         sourcetable,
        --         sourcetable,
        --         'tf',
        --         'tf');
        --
        -- --from start to start
        -- EXECUTE format('
        --     INSERT INTO %s (geom,
        --                     direction,
        --                     intersection_id)
        --     SELECT  ST_Makeline(fl.f_point,tl.f_point),
        --             %L,
        --             fl.f_int_id
        --     FROM    %s f,
        --             %s t,
        --             lengths fl,
        --             lengths tl
        --     WHERE   f.id != t.id
        --     AND     f.source = t.source
        --     AND     f.id = fl.id
        --     AND     t.id = tl.id
        --     AND     (f.one_way IS NULL OR f.one_way = %L)
        --     AND     (t.one_way IS NULL OR t.one_way = %L);
        --     ',  linktable,
        --         'ft',
        --         sourcetable,
        --         sourcetable,
        --         'tf',
        --         'ft');

    END;


    --set source/target info
    BEGIN
        RAISE NOTICE 'setting source/target info';
        EXECUTE format('
            UPDATE  %s
            SET     source_node = vf.vert_id,
                    target_node = vt.vert_id
            FROM    v vf,
                    v vt
            WHERE   %s.direction = %L
            AND     %s.road_id = vf.road_id AND vf.loc = %L
            AND     %s.road_id = vt.road_id AND vt.loc = %L;
            ',  linktable,
                linktable,
                'ft',
                linktable,
                'f',
                linktable,
                't');
        EXECUTE format('
            UPDATE  %s
            SET     source_node = vt.vert_id,
                    target_node = vf.vert_id
            FROM    v vf,
                    v vt
            WHERE   %s.direction = %L
            AND     %s.road_id = vf.road_id AND vf.loc = %L
            AND     %s.road_id = vt.road_id AND vt.loc = %L;
            ',  linktable,
                linktable,
                'tf',
                linktable,
                'f',
                linktable,
                't');
    END;


    --populate connector links
    --NOT GETTING INTERSECTION ID
    BEGIN
        EXECUTE format('
            INSERT INTO %s (geom,
                            direction,
                            intersection_id,
                            source_node,
                            target_node,
                            link_cost,
                            link_stress)
            SELECT  ST_Makeline(v1.geom,v2.geom),
                    NULL,
                    v1.intersection_id,
                    v1.node_id,
                    v2.node_id,
                    NULL,
                    NULL
            FROM    %s v1,
                    %s v2,
                    %s s1,
                    %s s2
            WHERE   v1.node_id != v2.node_id
            AND     v1.intersection_id = v2.intersection_id
            AND     s1.target_node = v1.node_id
            AND     s2.source_node = v2.node_id;
            ',  linktable,
                verttable,
                verttable,
                linktable,
                linktable);
    END;


    --set turn information intersection by intersections
    BEGIN
        EXECUTE format('SELECT array_agg(id) from %s',inttable) INTO intersection_ids;
        EXECUTE format('
            SELECT tdgSetTurnInfo(%L,%L,%L,%L);
            ',  linktable,
                inttable,
                verttable,
                intersection_ids);
    END;

    BEGIN
        EXECUTE format('ANALYZE %s;', verttable);
        EXECUTE format('ANALYZE %s;', linktable);
        EXECUTE format('ANALYZE %s;', turnrestricttable);
    END;
RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgMakeNetwork(REGCLASS) OWNER TO gis;
