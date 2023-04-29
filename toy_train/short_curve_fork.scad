include <track_common.scad>

module short_curves() {
    // Short Curved tracks
    distribute([80, 0, 0]) {
        flip_track(80)
        multi_track([
            [MALE, [SharpL]],
            [MALE, [SharpR]],
        ]);
        multi_track([
            [FEMALE, [SharpL]],
            [FEMALE, [SharpR]],
        ], near=MALE);
    }
}

short_curves();