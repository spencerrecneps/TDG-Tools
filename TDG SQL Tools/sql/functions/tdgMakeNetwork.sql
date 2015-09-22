CREATE OR REPLACE FUNCTION tdgMakeNetwork(input_table_ REGCLASS)
--need triggers to automatically update vertices and links
RETURNS BOOLEAN AS $func$

DECLARE
    schema_name TEXT;
    table_name TEXT;
    query TEXT;
    vert_table TEXT;
    link_table TEXT;
    turnrestrict_table TEXT;
    int_table TEXT;
    srid INT;
    indexcheck TEXT;
    int_ids INT[];

BEGIN
    RAISE NOTICE 'PROCESSING:';


    --check table and schema
    BEGIN
        RAISE NOTICE 'Getting table details for %',input_table_;
        EXECUTE '   SELECT  schema_name, table_name
                    FROM    tdgTableDetails($1)'
        USING   input_table_
        INTO    schema_name, table_name;

        vert_table = schema_name || '.' || table_name || '_net_vert';
        link_table = schema_name || '.' || table_name || '_net_link';
        turnrestrict_table = schema_name || '.' || table_name || '_turn_restriction';
        int_table = schema_name || '.' || table_name || '_intersections';
    END;


    --get srid of the geom
    BEGIN
        RAISE NOTICE 'Getting SRID of geometry';
        EXECUTE 'SELECT tdgGetSRID($1,$2);'
        USING   input_table_,
                'geom'
        INTO    srid;

        IF srid IS NULL THEN
            RAISE EXCEPTION 'ERROR: Cannot determine the srid of the geometry in table %', t_name;
        END IF;
        raise NOTICE '  -----> SRID found %',srid;
    END;


    --drop old tables
    BEGIN
        RAISE NOTICE 'dropping tables';
        EXECUTE format('
            DROP TABLE IF EXISTS %s;
            DROP TABLE IF EXISTS %s;
            DROP TABLE IF EXISTS %s;
            ',  turnrestrict_table,
                vert_table,
                link_table);
    END;


    --create new tables
    BEGIN
        RAISE NOTICE 'creating vertices table';
        EXECUTE '
            CREATE TABLE '||vert_table||' (
                vert_id serial PRIMARY KEY,
                int_id INT,
                vert_cost INT,
                geom geometry(point,$1));'
        USING   srid;

        RAISE NOTICE 'creating turn restrictions table';
        EXECUTE '
            CREATE TABLE '||turnrestrict_table||' (
                from_id integer NOT NULL,
                to_id integer NOT NULL,
                CONSTRAINT '||turnrestrict_table||'_trn_rstrctn_check CHECK (from_id <> to_id));';

        RAISE NOTICE 'creating link table';
        EXECUTE '
            CREATE TABLE '||link_table||' (
                link_id SERIAL PRIMARY KEY,
                road_id INT,
                source_vert INT,
                target_vert INT,
                int_id INT,
                direction VARCHAR(2),
                movement TEXT,
                link_cost INT,
                link_stress INT,
                geom geometry(linestring,$1));'
        USING   srid;
    END;


    --create temporary table of all possible vertices
    EXECUTE '
        CREATE TEMP TABLE v (
            id SERIAL PRIMARY KEY,
            road_id INT,
            vert_id INT,
            int_id INT,
            loc VARCHAR(1),
            int_geom geometry(point,$1),
            vert_geom geometry(point,$1))
        ON COMMIT DROP;'
    USING   srid;


    --insert vertices
    BEGIN
        RAISE NOTICE 'Adding points to vertices table';

        EXECUTE format('
            INSERT INTO v (road_id, loc, int_geom, vert_geom)
            SELECT      id,
                        %L,
                        ST_StartPoint(geom),
                        ST_LineInterpolatePoint(s.geom,LEAST(0.5*ST_Length(s.geom)-2,4)/ST_Length(s.geom))
            FROM        %s s
            ORDER BY    id ASC;
            ',  'f',
                input_table_);

        EXECUTE format('
            INSERT INTO v (road_id, loc, int_geom, vert_geom)
            SELECT      id,
                        %L,
                        ST_EndPoint(geom),
                        ST_LineInterpolatePoint(s.geom,GREATEST(0.5*ST_Length(s.geom)+2,ST_Length(s.geom)-4)/ST_Length(s.geom))
            FROM        %s s
            ORDER BY    id ASC;
            ',  't',
                input_table_);

        --get intersections for v
        EXECUTE format('
            UPDATE  v
            SET     int_id = intersection.id
            FROM    %s intersection
            WHERE   v.int_geom = intersection.geom;
            ',  int_table);

        --insert points into vertices table
        EXECUTE format('
            INSERT INTO %s (int_id, geom)
            SELECT      intersection.id,
                        v.vert_geom
            FROM        v,
                        %s intersection
            WHERE       v.int_id = intersection.id
            AND         intersection.legs > 2
            GROUP BY    intersection.id,
                        v.vert_geom;
            ',  vert_table,
                int_table);

        EXECUTE format('
            INSERT INTO %s (int_id, geom)
            SELECT      intersection.id,
                        v.int_geom
            FROM        v,
                        %s intersection
            WHERE       v.int_id = intersection.id
            AND         intersection.legs < 3
            GROUP BY    intersection.id,
                        v.int_geom;
            ',  vert_table,
                int_table);
    END;

    --vertex indexes
    BEGIN
        RAISE NOTICE 'creating vertex indexes';
        EXECUTE format('
            CREATE INDEX %s ON %s USING gist (geom);
            CREATE INDEX %s ON %s (int_id);
            ',  'sidx_' || table_name || 'vert_geom',
                vert_table,
                'idx_' || table_name || 'vert_intid',
                vert_table);
    END;

    EXECUTE format('ANALYZE %s;', vert_table);

    --join back the vertices to v
    BEGIN
        EXECUTE format('
            UPDATE  v
            SET     vert_id = vx.vert_id
            FROM    %s vx
            WHERE   v.vert_geom = vx.geom;
            ',  vert_table);
        EXECUTE format('
            UPDATE  v
            SET     vert_id = vx.vert_id
            FROM    %s vx
            WHERE   v.int_geom = vx.geom;
            ',  vert_table);
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
            FROM    %s s
            JOIN    v vf
                    ON s.id = vf.road_id AND vf.loc = %L
            JOIN    %s f_int
                    ON vf.int_id = f_int.id
            JOIN    v vt
                    ON s.id = vt.road_id AND vt.loc = %L
            JOIN    %s t_int
                    ON vt.int_id = t_int.id;
            ',  input_table_,
                'f',
                int_table,
                't',
                int_table);

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
            ',  link_table,
                'ft',
                input_table_,
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
            ',  link_table,
                'tf',
                input_table_,
                'tf');
    END;

    --set source/target info
    BEGIN
        RAISE NOTICE 'setting source/target info';
        EXECUTE format('
            UPDATE  %s
            SET     source_vert = vf.vert_id,
                    target_vert = vt.vert_id
            FROM    v vf,
                    v vt
            WHERE   %s.direction = %L
            AND     %s.road_id = vf.road_id AND vf.loc = %L
            AND     %s.road_id = vt.road_id AND vt.loc = %L;
            ',  link_table,
                link_table,
                'ft',
                link_table,
                'f',
                link_table,
                't');
        EXECUTE format('
            UPDATE  %s
            SET     source_vert = vt.vert_id,
                    target_vert = vf.vert_id
            FROM    v vf,
                    v vt
            WHERE   %s.direction = %L
            AND     %s.road_id = vf.road_id AND vf.loc = %L
            AND     %s.road_id = vt.road_id AND vt.loc = %L;
            ',  link_table,
                link_table,
                'tf',
                link_table,
                'f',
                link_table,
                't');
    END;


    --populate connector links
    BEGIN
        EXECUTE format('
            INSERT INTO %s (geom,
                            direction,
                            int_id,
                            source_vert,
                            target_vert,
                            link_cost,
                            link_stress)
            SELECT  ST_Makeline(v1.geom,v2.geom),
                    NULL,
                    v1.int_id,
                    v1.vert_id,
                    v2.vert_id,
                    NULL,
                    NULL
            FROM    %s v1,
                    %s v2,
                    %s s1,
                    %s s2
            WHERE   v1.vert_id != v2.vert_id
            AND     v1.int_id = v2.int_id
            AND     s1.target_vert = v1.vert_id
            AND     s2.source_vert = v2.vert_id
            AND     NOT s1.road_id = s2.road_id;
            ',  link_table,
                vert_table,
                vert_table,
                link_table,
                link_table);
    END;


    --set turn information intersection by intersections
    BEGIN
        EXECUTE format('SELECT array_agg(id) from %s',int_table) INTO int_ids;
        EXECUTE format('
            SELECT tdgSetTurnInfo(%L,%L,%L,%L);
            ',  link_table,
                int_table,
                vert_table,
                int_ids);
    END;


    --link indexes
    BEGIN
        RAISE NOTICE 'creating link indexes';
        EXECUTE format('
            CREATE INDEX %s ON %s (road_id);
            CREATE INDEX %s ON %s (direction);
            CREATE INDEX %s ON %s (source_vert,target_vert);
            ',  'idx_' || table_name || '_link_road_id',
                link_table,
                'idx_' || table_name || '_link_direction',
                link_table,
                'idx_' || table_name || '_link_src_trgt',
                link_table);
    END;

    BEGIN
        EXECUTE format('ANALYZE %s;', link_table);
        EXECUTE format('ANALYZE %s;', turnrestrict_table);
    END;
RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgMakeNetwork(REGCLASS) OWNER TO gis;
