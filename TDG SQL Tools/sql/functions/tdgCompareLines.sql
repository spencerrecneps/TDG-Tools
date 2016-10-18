CREATE OR REPLACE FUNCTION tdg.tdgCompareLines(
    base_geom_ geometry,
    comp_geom_ geometry,
    seg_length_ FLOAT
)
RETURNS FLOAT AS $func$

DECLARE
    base_length FLOAT;
    num_points INTEGER;
    comp_length FLOAT;
    avg_dist FLOAT;

BEGIN
    base_length := ST_Length(base_geom_);
    num_points := CEILING(base_length::FLOAT/seg_length_);

    CREATE TEMP TABLE tmp_linecompare (
        id SERIAL PRIMARY KEY,
        geom geometry(point)
    )
    ON COMMIT DROP;

    INSERT INTO tmp_linecompare (geom)
    SELECT  ST_LineInterpolatePoint(base_geom_,i::FLOAT * seg_length_ / base_length)
    FROM    generate_series(0,num_points) i
    WHERE   i * seg_length_ <= base_length;

    avg_dist := AVG(ST_Distance(geom,comp_geom_)) FROM tmp_linecompare;

    RETURN avg_dist;
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgCompareLines(geometry,geometry,FLOAT) OWNER TO gis;
