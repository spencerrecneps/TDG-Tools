CREATE OR REPLACE FUNCTION tdgMakeRouter (input_table REGCLASS)
RETURNS BOOLEAN AS $func$

DECLARE
    namecheck RECORD;
    schema_name TEXT;
    table_name TEXT;
    routetable TEXT;
    linktable TEXT;
    verttable TEXT;

BEGIN
    BEGIN
        --make sure the input table exists and get infos
        RAISE NOTICE 'Checking % exists',input_table;
        EXECUTE '   SELECT  schema_name,
                            table_name
                    FROM    tdgTableDetails('||quote_literal(input_table)||') AS (schema_name TEXT, table_name TEXT)' INTO namecheck;
        schema_name=namecheck.schema_name;
        table_name=namecheck.table_name;
        IF schema_name IS NULL OR table_name IS NULL THEN
            RAISE NOTICE '-------> % not found',input_table;
            RETURN 'f';
        END IF;

        --set table names
        routetable = schema_name || '.' || table_name || '_net_router';
        linktable = schema_name || '.' || table_name || '_net_link';
        verttable = schema_name || '.' || table_name || '_net_vert';

        --check whether link and vert tables exist
        IF tdgTableCheck(linktable) = 'f' THEN
            RAISE NOTICE '--------> % not found',linktable;
            RETURN 'f';
        END IF;
        IF tdgTableCheck(verttable) = 'f' THEN
            RAISE NOTICE '--------> % not found',verttable;
            RETURN 'f';
        END IF;

        --create new routing table
        RAISE NOTICE 'Creating routing table %',routetable;
        EXECUTE format('DROP TABLE IF EXISTS %s;',routetable);
        EXECUTE format('
            CREATE TABLE %s (
                id SERIAL PRIMARY KEY,
                net_id TEXT,
                net_cost INT,
                net_stress INT
            )
            ',  routetable);
        EXECUTE format('
            CREATE INDEX %s ON %s (net_id);'
            ,  'idx_'||table_name||'_router_netid',
                routetable);
    END;

    BEGIN
        RAISE NOTICE 'Inserting data';
        EXECUTE format('
            INSERT INTO %s (net_id,net_cost,net_stress)
            SELECT  l.source_node::TEXT || %L || l.target_node::TEXT,
                    COALESCE(link_cost,0),
                    COALESCE(link_stress,1)
            FROM    %s l
            ',  routetable,
                '-',
                linktable);
    END;

RETURN 't';
END $func$ LANGUAGE plpgsql;
