CREATE TYPE tdg.tdgShortestPathType AS (
    path_id INT,
    from_vert INT,
    to_vert INT,
    move_sequence INT,
    link_id INT,
    vert_id INT,
    road_id INT,
    int_id INT,
    move_cost INT,
    cumulative_cost INT
);
