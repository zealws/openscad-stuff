include <track_common.scad>

module curved_forks() {
    // Curved Fork Tracks
    distribute([100, 0, 0]) {
        flip_track()
            multi_track([[MALE, [Medium]], [MALE, [WideL]]]);
        multi_track([[FEMALE, [Medium]], [FEMALE, [WideL]], ], MALE);
    }
}

curved_forks();