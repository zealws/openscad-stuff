include <track_common.scad>

module parallel_fork() {
    // 2-Connector Parallel Fork Tracks
    distribute([100, 0, 0]) {
        r1 = 139.60; a1 = 31.05;  // Values computed using SolveSpace sketch
        flip_track()
            multi_track([
                [MALE, [Medium]],
                [MALE, [path_node(r1, a1), path_node(r1, -a1)]],
            ]);
        multi_track([
            [FEMALE, [Medium]],
            [FEMALE, [path_node(r1, a1), path_node(r1, -a1)]],
        ], MALE);
    }
}

parallel_fork();