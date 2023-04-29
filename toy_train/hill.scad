include <track_common.scad>

module hill_track() {
    // Hill Tracks
    distribute([50, 0, 0]) {
        r2 = 150.28; a2 = 33.53; // Values computed using SolveSpace sketch
        simple_track([
            path_node(7),
            path_node(r2, a2, X),
            path_node(r2, -a2, X),
            path_node(7),
        ], only_top_grooves=true);
        simple_track([
            path_node(7),
            path_node(r2, a2, X),
            path_node(r2, -a2, X),
            path_node(7),
        ], near=MALE, far=FEMALE, only_top_grooves=true);
    }
}

hill_track();