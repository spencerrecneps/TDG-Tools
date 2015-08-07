CREATE TABLE stress_seg_bike_w_park (
    speed integer,
    bike_park_lane_wd_ft integer,
    lanes integer,
    stress integer
);

INSERT INTO stress_seg_bike_w_park (speed, bike_park_lane_wd_ft, lanes, stress)
VALUES  (20,99,1,1),
        (20,14,1,2),
        (20,13,1,2),
        (20,99,99,3),
        (20,14,99,3),
        (25,99,1,1),
        (25,14,1,2),
        (25,13,1,23),
        (25,99,99,3),
        (25,14,99,3),
        (30,99,1,2),
        (30,14,1,2),
        (30,13,1,23),
        (30,99,99,3),
        (30,14,99,3),
        (35,99,1,3),
        (35,14,1,3),
        (35,13,1,3),
        (35,99,99,3),
        (35,14,99,3),
        (99,99,1,3),
        (99,14,1,4),
        (99,13,1,4),
        (99,99,99,3),
        (99,14,99,4);
