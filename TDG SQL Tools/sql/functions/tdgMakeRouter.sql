CREATE OR REPLACE FUNCTION tdgMakeRouter (input_table REGCLASS)
RETURNS BOOLEAN AS $func$

DECLARE
    routetable TEXT;
    linktable TEXT;
    verttable TEXT;

BEGIN
    --vars
    routetable = input_table || '_net_router';
    linktable = input_table || '_net_link';
    verttable = input_table || '_net_vert';

    RAISE NOTICE 'Creating routing table %', routetable;
    EXECUTE format('
        CREATE TABLE %s (
            id SERIAL PRIMARY KEY,
            net_id TEXT,
            net_cost INT,
            net_stress INT
        )
        ',  routetable);

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

RETURN 't';
END $func$ LANGUAGE plpgsql;
