CREATE OR REPLACE FUNCTION tdg.tdgInsertStandardizedRoad(
    input_table_ REGCLASS,
    road_table_ REGCLASS,
    name_field_ TEXT,
    z_from_field_ TEXT,
    z_to_field_ TEXT,
    adt_field_ TEXT,
    speed_field_ TEXT,
    func_field_ TEXT,
    oneway_field_ TEXT,
    input_ids_ INTEGER[] DEFAULT NULL)
RETURNS BOOLEAN AS $func$

DECLARE
    tdg_id_exists BOOLEAN;
    id_column TEXT;
    table_name TEXT;
    road_table TEXT;
    querytext TEXT;
    bad_one_way_id INT;
BEGIN
    -- get column name of primary key
    EXECUTE '
        SELECT a.attname
        FROM   pg_index i
        JOIN   pg_attribute a ON a.attrelid = i.indrelid
                             AND a.attnum = ANY(i.indkey)
        WHERE  i.indrelid = $1
        AND    i.indisprimary;'
    USING   input_table_
    INTO    id_column;

    -- check for tdg_id field in source data
    tdg_id_exists := tdgColumnCheck(input_table_,'tdg_id');

    --copy features over
    BEGIN
        RAISE NOTICE 'Copying features to %', road_table_;
        --querytext := '';
        querytext := '   INSERT INTO ' || road_table_ || ' (geom';
        querytext := querytext || ',source_data';
        IF name_field_ IS NOT NULL THEN
            querytext := querytext || ',road_name';
            END IF;
        IF tdg_id_exists THEN
            querytext := querytext || ',tdg_id';
            END IF;
        IF func_field_ IS NOT NULL THEN
            querytext := querytext || ',functional_class';
            END IF;
        IF oneway_field_ IS NOT NULL THEN
            querytext := querytext || ',one_way';
            END IF;
        IF speed_field_ IS NOT NULL THEN
            querytext := querytext || ',speed_limit';
            END IF;
        IF adt_field_ IS NOT NULL THEN
            querytext := querytext || ',adt';
            END IF;
        IF z_from_field_ IS NOT NULL THEN
            querytext := querytext || ',z_from';
            END IF;
        IF z_to_field_ IS NOT NULL THEN
            querytext := querytext || ',z_to';
            END IF;
        querytext := querytext || ') SELECT ST_SnapToGrid(r.geom,2)';
        querytext := querytext || ',' || quote_literal(input_table_);
        IF name_field_ IS NOT NULL THEN
            querytext := querytext || ',' || quote_ident(name_field_);
            END IF;
        IF tdg_id_exists IS NOT NULL THEN
            querytext := querytext || ',tdg_id';
            END IF;
        IF func_field_ IS NOT NULL THEN
            querytext := querytext || ',' || quote_ident(func_field_);
            END IF;
        IF oneway_field_ IS NOT NULL THEN
            querytext := querytext || ',' || quote_ident(oneway_field_);
            END IF;
        IF speed_field_ IS NOT NULL THEN
            querytext := querytext || ',' || quote_ident(speed_field_);
            END IF;
        IF adt_field_ IS NOT NULL THEN
            querytext := querytext || ',' || quote_ident(adt_field_);
            END IF;
        IF z_from_field_ IS NOT NULL THEN
            querytext := querytext || ',' || quote_ident(z_from_field_);
            END IF;
        IF z_to_field_ IS NOT NULL THEN
            querytext := querytext || ',' || quote_ident(z_to_field_);
            END IF;
        querytext := querytext || ' FROM ' ||input_table_|| ' r ';

        IF input_ids_ IS NULL THEN
            EXECUTE querytext;
        ELSE
            EXECUTE querytext || '
                WHERE r.'||id_column||' = ANY ('||quote_literal(input_ids_::TEXT)||')';
        END IF;

    EXCEPTION
        WHEN check_violation THEN
            EXECUTE '
                SELECT  '||id_column||'
                FROM    '||input_table_||'
                WHERE   '||quote_ident(oneway_field_)||' IS NOT NULL
                AND     '||quote_ident(oneway_field_)||' NOT IN ($1,$2)
                LIMIT   1'
            INTO    bad_one_way_id
            USING   'ft',
                    'tf';
            RAISE EXCEPTION 'Bad one_way value on feature id %', bad_one_way_id
            USING HINT = 'Value must be "ft" or "tf"';
    END;

    RETURN 't';
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgInsertStandardizedRoad(
    REGCLASS,REGCLASS,TEXT,TEXT,TEXT,TEXT,TEXT,
    TEXT,TEXT,INTEGER[]) OWNER TO gis;
