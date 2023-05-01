include <track_common.scad>

module _bevel_fill_proto(position) {
    length = 23;
    translate([0, position - length/2, 0])
        cube([2 * Track_Bevel + 1, length, Track_Height], center=true);
}

// NOTE: The parallel tracks have beveled edges, like all the other tracks.
// But in the parallel track, this creates a crease between the two edges where they're connected.
// We fill that in using this bevel_fill module, which adds a cuboid into the space so it's filled.
module bevel_fill(length=Medium_Length, left=false, right=false) {
    if (left) {
        translate([-Track_Width/2, 0, 0])
            _bevel_fill_proto(length);
    }
    if (right) {
        translate([Track_Width/2, 0, 0])
            _bevel_fill_proto(length);
    }
}

// Values computed using SolveSpace sketch
function parallel_radius() = 139.60;
function parallel_angle() = 31.05;

module parallel_fork() {
    // 2-Connector Parallel Fork Tracks
    distribute([100, 0, 0]) {
        flip_track() {
            bevel_fill(left=true);
            multi_track([
                [MALE, [Medium]],
                [MALE, [path_node(parallel_radius(), parallel_angle()), path_node(parallel_radius(), -parallel_angle())]],
            ]);
        }
        union() {
            bevel_fill(left=true);
            multi_track([
                [FEMALE, [Medium]],
                [FEMALE, [path_node(parallel_radius(), parallel_angle()), path_node(parallel_radius(), -parallel_angle())]],
            ], MALE);
        }
    }
}

parallel_fork();