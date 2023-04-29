include <track_common.scad>

module parallel_fork() {
    // 2-Connector Parallel Fork Tracks
    // NOTE: we only want to bevel the outer edges, because otherwise it leaves a divet in the center.
    // this extra negative space causes a lot of additional extruder movement, and may cause the small piece
    // there to come unstuck, leading to print failure.
    distribute([100, 0, 0]) {
        r1 = 139.60; a1 = 31.05;  // Values computed using SolveSpace sketch
        flip_track()
            multi_track([
                [MALE, [Medium], BEVEL_LEFT],
                [MALE, [path_node(r1, a1), path_node(r1, -a1)], BEVEL_LEFT],
            ]);
        multi_track([
            [FEMALE, [Medium], BEVEL_LEFT],
            [FEMALE, [path_node(r1, a1), path_node(r1, -a1)], BEVEL_LEFT],
        ], MALE);
    }
}

parallel_fork();