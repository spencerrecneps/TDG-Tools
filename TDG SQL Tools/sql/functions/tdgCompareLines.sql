CREATE OR REPLACE FUNCTION tdg.tdgCompareLines(
    base_geom_ geometry,
    comp_geom_ geometry,
    seg_length_ FLOAT
)
RETURNS FLOAT AS $func$

DECLARE
    base_length FLOAT;
    num_points INTEGER;
    avg_dist FLOAT;

BEGIN
    base_length := ST_Length(base_geom_);
    num_points := CEILING(base_length::FLOAT/seg_length_);

    avg_dist := AVG(
                    ST_Distance(
                        ST_LineInterpolatePoint(base_geom_,i::FLOAT * seg_length_ / base_length),
                        -- comp_geom_
                        ST_LineInterpolatePoint(
                            comp_geom_,
                            ST_LineLocatePoint(
                                comp_geom_,
                                ST_LineInterpolatePoint(base_geom_,i::FLOAT * seg_length_ / base_length)
                            )
                        )
                    )
                )
    FROM        generate_series(0,num_points) i
    WHERE       i * seg_length_ <= base_length;

    RETURN avg_dist;
END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgCompareLines(geometry,geometry,FLOAT) OWNER TO gis;
