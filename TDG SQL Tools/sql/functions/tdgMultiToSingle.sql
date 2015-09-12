CREATE OR REPLACE FUNCTION tdgMultiToSingle (   temp_table_ REGCLASS,
                                                new_table_ TEXT,
                                                schema_ TEXT,
                                                srid_ INTEGER,
                                                overwrite_ BOOLEAN)
RETURNS BOOLEAN AS $func$

DECLARE
    columndetails RECORD;
    newcolumnname TEXT;

BEGIN
    --create schema if needed
    EXECUTE 'CREATE SCHEMA IF NOT EXISTS ' || schema_ || ';';

    --drop table if overwrite
    IF overwrite_ THEN
        EXECUTE 'DROP TABLE IF EXISTS ' || schema_ || '.' || new_table_ || ';';
    END IF;

    --create new table
    EXECUTE '   CREATE TABLE ' || schema_ || '.' || new_table_ || '
                    (   id SERIAL PRIMARY KEY,
                        temp_id INTEGER,
                        tdg_id TEXT NOT NULL DEFAULT uuid_generate_v4()::TEXT,
                        geom geometry(LINESTRING,' || srid_::TEXT || '));';

    --insert info from temporary table
    EXECUTE '   INSERT INTO ' || schema_ || '.' || new_table_ || ' (temp_id,geom)
                SELECT id,ST_Transform((ST_Dump(geom)).geom,$1)
                FROM ' || temp_table_ || ';'
    USING   srid_;

    --copy table structure from temporary table
    RAISE NOTICE 'Copying table structure from %', temp_table_;
    FOR columndetails IN
    EXECUTE '
        SELECT  a.attname AS col,
                pg_catalog.format_type(a.atttypid, a.atttypmod) AS datatype
        FROM    pg_catalog.pg_attribute a
        WHERE   a.attnum > 0
        AND     NOT a.attisdropped
        AND     a.attrelid = ' || quote_literal(temp_table_) || '::REGCLASS;'
    LOOP
        IF columndetails.col NOT IN ('id','geom','tdg_id') THEN
            --sanitize column name
            newcolumnname := regexp_replace(LOWER(columndetails.col), '[^a-zA-Z_]', '', 'g');
            EXECUTE '   ALTER TABLE ' || new_table_ || '
                        ADD COLUMN ' || newcolumnname || ' ' || columndetails.datatype || ';';

            --copy data over
            EXECUTE '   UPDATE ' || new_table_ || '
                        SET ' || newcolumnname || ' = t.' || quote_ident(columndetails.col) || '
                        FROM ' || temp_table_ || ' t
                        WHERE t.id = ' || new_table_ || '.temp_id;';
        END IF;
    END LOOP;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgMultiToSingle(REGCLASS,TEXT,TEXT,INTEGER,BOOLEAN) OWNER TO gis;
