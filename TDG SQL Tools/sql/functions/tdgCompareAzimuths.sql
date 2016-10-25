CREATE OR REPLACE FUNCTION tdg.tdgCompareAzimuths(
    base_geom_ geometry,
    comp_geom_ geometry,
    line_start_ FLOAT DEFAULT 0.33,
    line_end_ FLOAT DEFAULT 0.67
)
RETURNS FLOAT AS $func$

DECLARE
    angle_diff FLOAT;

BEGIN
    angle_diff = degrees(
        acos(
            abs(
                cos(
                    ST_Azimuth(
                        ST_LineInterpolatePoint(
                            comp_geom_,
                            line_start_
                        ),
                        ST_LineInterpolatePoint(
                            comp_geom_,
                            line_end_
                        )
                    ) -
                    ST_Azimuth(
                        ST_LineInterpolatePoint(
                            base_geom_,
                            line_start_
                        ),
                        ST_LineInterpolatePoint(
                            base_geom_,
                            line_end_
                        )
                    )
                )
            )
        )
    );

    RETURN angle_diff;

END $func$ LANGUAGE plpgsql;
ALTER FUNCTION tdg.tdgCompareAzimuths(geometry,geometry,FLOAT,FLOAT) OWNER TO gis;
