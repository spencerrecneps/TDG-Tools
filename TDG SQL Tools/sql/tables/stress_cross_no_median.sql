CREATE TABLE stress_cross_no_median (
    speed integer,
    lanes integer,
    stress integer,
    CONSTRAINT stress_cross_no_median_pkey PRIMARY KEY (speed,lanes,stress)
);

INSERT INTO stress_cross_no_median (speed, lanes, stress)
VALUES  (25,3,1),
        (25,5,2),
        (25,99,4),
        (30,3,1),
        (30,5,2),
        (30,99,4),
        (35,3,2),
        (35,5,3),
        (35,99,4),
        (99,3,3),
        (99,5,4),
        (99,99,4);

GRANT ALL ON TABLE tdg.stress_cross_no_median TO public;
ANALYZE tdg.stress_cross_no_median;
