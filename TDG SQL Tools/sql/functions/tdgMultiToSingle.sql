CREATE OR REPLACE FUNCTION tdgMultiToSingle (   temp_table_ REGCLASS,
                                                new_table_ TEXT,
                                                schema_ TEXT,
                                                srid_ INTEGER,
                                                overwrite_ BOOLEAN)
RETURNS BOOLEAN AS $func$

DECLARE
    namecheck TEXT;
    primarykeycolumn TEXT;
    columndetails RECORD;
    newcolumnname TEXT;

BEGIN
    --create schema if needed
    EXECUTE 'CREATE SCHEMA IF NOT EXISTS ' || schema_ || ';';

    --drop table if overwrite
    IF overwrite_ THEN
        EXECUTE 'DROP TABLE IF EXISTS ' || schema_ || '.' || new_table_ || ';';
    ELSE
        RAISE NOTICE 'Checking whether table % exists',new_table_;
        EXECUTE '   SELECT  table_name
                    FROM    tdgTableDetails($1)'
        USING   schema_ || '.' || new_table_
        INTO    namecheck;

        IF NOT namecheck IS NULL THEN
            RAISE EXCEPTION 'Table % already exists', new_table_;
        END IF;
    END IF;

    --get temp table primary key column name
    EXECUTE '
        SELECT a.attname
        FROM   pg_index i
        JOIN   pg_attribute a
                    ON a.attrelid = i.indrelid
                    AND a.attnum = ANY(i.indkey)
        WHERE  i.indrelid = $1::regclass
        AND    i.indisprimary;'
    USING   schema_ || '.' || temp_table_
    INTO    primarykeycolumn;

    --create new table
    RAISE NOTICE 'Creating table %',new_table_;
    EXECUTE '   CREATE TABLE ' || schema_ || '.' || new_table_ || '
                    ( ' || primarykeycolumn || ' SERIAL PRIMARY KEY,
                        temp_id INTEGER,
                        tdg_id TEXT NOT NULL DEFAULT uuid_generate_v4()::TEXT,
                        geom geometry(LINESTRING,' || srid_::TEXT || '));';

    --insert info from temporary table
    EXECUTE '   INSERT INTO ' || schema_ || '.' || new_table_ || ' (temp_id,geom)
                SELECT ' || primarykeycolumn || ',ST_Transform((ST_Dump(geom)).geom,$1)
                FROM ' || temp_table_ || ';'
    USING   srid_;


    --copy table structure from temporary table
    RAISE NOTICE 'Copying table structure from %', temp_table_;

    --loop through temp table columns
    FOR columndetails IN
    EXECUTE '
        SELECT  a.attname AS col,
                pg_catalog.format_type(a.atttypid, a.atttypmod) AS datatype
        FROM    pg_catalog.pg_attribute a
        WHERE   a.attnum > 0
        AND     NOT a.attisdropped
        AND     a.attrelid = ' || quote_literal(temp_table_) || '::REGCLASS;'
    LOOP
        IF columndetails.col NOT IN (primarykeycolumn,'geom','tdg_id') THEN
            --sanitize column name
            newcolumnname := regexp_replace(LOWER(columndetails.col), '[^a-zA-Z_]', '', 'g');
            EXECUTE '   ALTER TABLE ' || schema_ || '.' || new_table_ || '
                        ADD COLUMN ' || newcolumnname || ' ' || columndetails.datatype || ';';

            --copy data over
            EXECUTE '   UPDATE ' || schema_ || '.' || new_table_ || '
                        SET ' || newcolumnname || ' = t.' || quote_ident(columndetails.col) || '
                        FROM ' || temp_table_ || ' t
                        WHERE t.id = ' || schema_ || '.' || new_table_ || '.temp_id;';
        END IF;
    END LOOP;

    --drop the temp_id column
    EXECUTE 'ALTER TABLE ' || schema_ || '.' || new_table_ || ' DROP COLUMN temp_id;';

    --drop the temporary table
    EXECUTE 'DROP TABLE ' || temp_table_ || ';';

    RETURN 't';

END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdgMultiToSingle(REGCLASS,TEXT,TEXT,INTEGER,BOOLEAN) OWNER TO gis;
