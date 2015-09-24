CREATE OR REPLACE FUNCTION tdg.tdgShortestPathIntersections (   
    inttable_ REGCLASS,
    linktable_ REGCLASS,
    verttable_ REGCLASS,
    from_ INT,
    to_ INT,
    stress_ INT DEFAULT NULL)
RETURNS SETOF tdgShortestPathType AS $func$

DECLARE
    vertcheck BOOLEAN;
    fromtestvert INT;
    totestvert INT;
    minfromvert INT;
    mintovert INT;
    mincost INT;
    comparecost INT;

BEGIN
    --check intersections for existence
    RAISE NOTICE 'Checking intersections';

    EXECUTE 'SELECT EXISTS (SELECT 1 FROM '|| inttable_ || ' WHERE id IN ($1,$2));'
    INTO    vertcheck
    USING   from_,
            to_;

    IF NOT vertcheck THEN
        EXECUTE 'SELECT EXISTS (SELECT 1 FROM '|| inttable_ || ' WHERE id = $1);'
        INTO    vertcheck
        USING   from_;

        IF NOT vertcheck THEN
            RAISE EXCEPTION 'Nonexistent intersection --> %', from_::TEXT
            USING HINT = 'Please check your intersections';
        END IF;

        EXECUTE 'SELECT EXISTS (SELECT 1 FROM '|| inttable_ || ' WHERE id = $1);'
        INTO    vertcheck
        USING   to_;

        IF NOT vertcheck THEN
            RAISE EXCEPTION 'Nonexistent intersection --> %', to_::TEXT
            USING HINT = 'Please check your intersections';
        END IF;
    END IF;

    RAISE NOTICE 'Testing shortest paths';
    --do shortest path starting at first vertex to other vertices
    --then do another and compare SUM(move_cost) to first. Keep lowest.
    FOR fromtestvert IN
    EXECUTE '   SELECT  node_id
                FROM ' || verttable_ || '
                WHERE   intersection_id = $1;'
    USING   from_
    LOOP
        FOR totestvert IN
        EXECUTE '   SELECT  node_id
                    FROM ' || verttable_ || '
                    WHERE   intersection_id = $1;'
        USING   to_
        LOOP
            EXECUTE '   SELECT SUM(move_cost)
                        FROM    tdgShortestPathVerts($1,$2,$3,$4,$5);'
            USING   linktable_,
                    verttable_,
                    fromtestvert,
                    totestvert,
                    stress_
            INTO    comparecost;

            IF mincost IS NULL OR comparecost < mincost THEN
                mincost := comparecost;
                minfromvert := fromtestvert;
                mintovert := totestvert;
            END IF;
        END LOOP;
    END LOOP;

RETURN QUERY
EXECUTE '   SELECT  *
            FROM    tdgShortestPathVerts($1,$2,$3,$4,$5);'
USING   linktable_,
        verttable_,
        minfromvert,
        mintovert,
        stress_;
--followed by empty RETURN???
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgShortestPathIntersections(REGCLASS,REGCLASS,REGCLASS,INT,INT,INT) OWNER TO gis;
