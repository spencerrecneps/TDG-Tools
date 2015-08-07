CREATE OR REPLACE FUNCTION MakeNetwork(input_table REGCLASS)
--need triggers to automatically update vertices and links
RETURNS VARCHAR AS $func$

DECLARE
    sname text;
    tname text;
    namecheck record;
    query text;
    sourcetable text;
    verttable text;
    linktable text;
    turnrestricttable text;
    sridinfo record;
    srid int;

BEGIN
    RAISE NOTICE 'PROCESSING:';

    --check table and schema
    --need to redo without reliance on pgrouting
    BEGIN
        RAISE DEBUG 'Checking % exists',input_table;
        execute 'SELECT tdgTableDetails('||input_table||')' INTO namecheck;
        sname=namecheck.sname;
        tname=namecheck.tname;
        IF sname IS NULL OR tname IS NULL THEN
    	RAISE NOTICE '-------> % not found',input_table;
            RETURN 'FAIL';
        ELSE
    	RAISE DEBUG '  -----> OK';
        END IF;

        sourcetable = sname || '.' || tname;
        verttable = sname || '.' || tname || '_net_vert';
        linktable = sname || '.' || tname || '_net_link';
        turnrestricttable = sname || '.' || tname || '_turn_restriction';
    END;

    --snap geom to grid to nearest 2 ft
    BEGIN
        RAISE DEBUG 'snapping road geometries';
        EXECUTE format('
            UPDATE  %s
            SET     geom = ST_SnapToGrid(geom,2);
            ',  sourcetable);
    END;

    --check for from/to columns
    BEGIN
        RAISE DEBUG 'checking for source/target columns';
        IF EXISTS (
            SELECT 1 FROM pg_attribute
            WHERE  attrelid = tname::regclass
            AND    attname = 'source'
            AND    NOT attisdropped)
        THEN
            EXECUTE format('
                UPDATE %s SET source=NULL;
                ',  sourcetable);
        ELSE
            EXECUTE format('
                ALTER TABLE %s ADD COLUMN source INT;
                ',  sourcetable);
        END IF;
        IF EXISTS (
            SELECT 1 FROM pg_attribute
            WHERE  attrelid = tname::regclass
            AND    attname = 'target'
            AND    NOT attisdropped)
        THEN
            EXECUTE format('
                UPDATE %s SET target=NULL;
                ',  sourcetable);
        ELSE
            EXECUTE format('
                ALTER TABLE %s ADD COLUMN target INT;
                ',  sourcetable);
        END IF;
    END;

    --get srid of the geom
    BEGIN
        RAISE DEBUG 'Checking the SRID of the geometry';
        query= '  SELECT ST_SRID(geom) as srid
                FROM ' || pgr_quote_ident(input_table) || '
                WHERE geom IS NOT NULL LIMIT 1';
        EXECUTE QUERY INTO sridinfo;

        IF sridinfo IS NULL OR sridinfo.srid IS NULL THEN
            RAISE NOTICE 'ERROR: Can not determine the srid of the geometry in table %', input_table;
            RETURN 'FAIL';
        END IF;
        srid := sridinfo.srid;
        raise DEBUG '  -----> SRID found %',srid;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'ERROR: Can not determine the srid of the geometry "%" in table %', the_geom,tabname;
            RETURN 'FAIL';
    END;

    --drop old tables
    BEGIN
        RAISE DEBUG 'dropping tables';
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
        raise DEBUG 'creating new tables';
        EXECUTE format('
            CREATE TABLE %s (   id serial PRIMARY KEY,
                                node_id TEXT,
                                node_order INT,
                                cost INT,
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
                                direction VARCHAR(2),
                                cost INT,
                                stress INT,
                                geom geometry(linestring,%L));
            ',  linktable,
                srid);
    END;

    --indexes
    BEGIN
        RAISE DEBUG 'creating indexes';
        EXECUTE format('
            CREATE INDEX %s ON %s USING gist (geom);
            CREATE INDEX %s ON %s (road_id);
            CREATE INDEX %s ON %s (direction);
            CREATE INDEX %s ON %s (source,target);
            ',  'sidx_' || tname || 'vert_geom',
                verttable,
                'idx_' || tname || '_link_road_id',
                linktable,
                'idx_' || tname || '_link_direction',
                linktable,
                'idx_' || tname || '_srctrgt',
                sourcetable);
    END;

    --insert points into vertices table
    BEGIN
        RAISE DEBUG 'adding points to vertices table';
        EXECUTE format('
            CREATE TEMP TABLE v (i INT, geom geometry(point,%L)) ON COMMIT DROP;
            INSERT INTO v (i, geom) SELECT id, ST_StartPoint(geom) FROM %s ORDER BY id ASC;
            INSERT INTO v (i, geom) SELECT id, ST_EndPoint(geom) FROM %s ORDER BY id ASC;
            INSERT INTO %s (node_id, node_order, geom)
            SELECT      string_agg(i::TEXT, %L),
                        COUNT(i),
                        geom
            FROM        v
            GROUP BY    geom;
            ',  srid,
                sourcetable,
                sourcetable,
                verttable,
                ' | ');
    END;

    --get source/target info
    BEGIN
        RAISE DEBUG 'getting source/target info';
        EXECUTE format('
            UPDATE  %s
            SET     source = vf.id,
                    target = vt.id
            FROM    %s vf,
                    %s vt
            WHERE   ST_StartPoint(%I.geom) = vf.geom
            AND     ST_EndPoint(%I.geom) = vt.geom
            ',  sourcetable,
                verttable,
                verttable,
                tname,
                tname);
    END;

    --populate links table
    BEGIN
        RAISE DEBUG 'adding links';
        EXECUTE format('
            CREATE TEMP TABLE lengths ( id SERIAL PRIMARY KEY,
                                        len FLOAT,
                                        f_point geometry(point, %L),
                                        t_point geometry(point, %L))
            ON COMMIT DROP;
            ',  srid,
                srid);

        EXECUTE format('
            INSERT INTO lengths (id, len, f_point, t_point)
            SELECT  s.id,
                    ST_Length(s.geom) AS len,
                    CASE    WHEN vf.node_order > 2
                            THEN ST_LineInterpolatePoint(s.geom,LEAST(0.5*ST_Length(s.geom)-5,50.0)/ST_Length(s.geom))
                            ELSE ST_StartPoint(s.geom)
                            END AS f_point,
                    CASE    WHEN vt.node_order > 2
                            THEN ST_LineInterpolatePoint(s.geom,GREATEST(0.5*ST_Length(s.geom)+5,ST_Length(s.geom)-50)/ST_Length(s.geom))
                            ELSE ST_EndPoint(s.geom)
                            END AS t_point
            FROM    %s s,
                    %s vf,
                    %s vt
            WHERE   s.source = vf.id
            AND     s.target = vt.id;
            ',  sourcetable,
                verttable,
                verttable);

        --self segment ft
        EXECUTE format('
            INSERT INTO %s (geom,
                            direction,
                            road_id,
                            cost)
            SELECT  ST_Makeline(l.f_point,l.t_point),
                    %L,
                    r.id,
                    r.cost
            FROM    %s r,
                    lengths l
            WHERE   r.id=l.id
            AND     (r.one_way IS NULL OR r.one_way = %L);
            ',  linktable,
                'ft',
                sourcetable,
                'ft');

        --self segment tf
        EXECUTE format('
            INSERT INTO %s (geom,
                            direction,
                            road_id,
                            cost)
            SELECT  ST_Makeline(l.t_point,l.f_point),
                    %L,
                    r.id,
                    r.cost
            FROM    %s r,
                    lengths l
            WHERE   r.id=l.id
            AND     (r.one_way IS NULL OR r.one_way = %L);
            ',  linktable,
                'tf',
                sourcetable,
                'tf');

        --from end to start
        EXECUTE format('
            INSERT INTO %s (geom)
            SELECT  ST_Makeline(fl.t_point,tl.f_point)
            FROM    %s f,
                    %s t,
                    lengths fl,
                    lengths tl
            WHERE   f.id != t.id
            AND     f.target = t.source
            AND     f.id = fl.id
            AND     t.id = tl.id
            AND     (f.one_way IS NULL OR f.one_way = %L)
            AND     (t.one_way IS NULL OR t.one_way = %L);
            ',  linktable,
                sourcetable,
                sourcetable,
                'ft',
                'ft');

        --from end to end
        EXECUTE format('
            INSERT INTO %s (geom)
            SELECT  ST_Makeline(fl.t_point,tl.t_point)
            FROM    %s f,
                    %s t,
                    lengths fl,
                    lengths tl
            WHERE   f.id != t.id
            AND     f.target = t.target
            AND     f.id = fl.id
            AND     t.id = tl.id
            AND     (f.one_way IS NULL OR f.one_way = %L)
            AND     (t.one_way IS NULL OR t.one_way = %L);
            ',  linktable,
                sourcetable,
                sourcetable,
                'ft',
                'tf');

        --from start to end
        EXECUTE format('
            INSERT INTO %s (geom)
            SELECT  ST_Makeline(fl.f_point,tl.t_point)
            FROM    %s f,
                    %s t,
                    lengths fl,
                    lengths tl
            WHERE   f.id != t.id
            AND     f.source = t.target
            AND     f.id = fl.id
            AND     t.id = tl.id
            AND     (f.one_way IS NULL OR f.one_way = %L)
            AND     (t.one_way IS NULL OR t.one_way = %L);
            ',  linktable,
                sourcetable,
                sourcetable,
                'tf',
                'tf');

        --from start to start
        EXECUTE format('
            INSERT INTO %s (geom)
            SELECT  ST_Makeline(fl.f_point,tl.f_point)
            FROM    %s f,
                    %s t,
                    lengths fl,
                    lengths tl
            WHERE   f.id != t.id
            AND     f.source = t.source
            AND     f.id = fl.id
            AND     t.id = tl.id
            AND     (f.one_way IS NULL OR f.one_way = %L)
            AND     (t.one_way IS NULL OR t.one_way = %L);
            ',  linktable,
                sourcetable,
                sourcetable,
                'tf',
                'ft');
    END;
RETURN 'success';
END $func$ LANGUAGE plpgsql;
