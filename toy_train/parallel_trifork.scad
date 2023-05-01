include <track_common.scad>
use <parallel_fork.scad>

module parallel_trifork() {
    // 3-Connector Parallel Fork Tracks
    // NOTE: we only want to bevel the outer edges, because otherwise it leaves a divet in the center.
    // this extra negative space causes a lot of additional extruder movement, and may cause the small piece
    // there to come unstuck, leading to print failure.
    distribute([100, 0, 0]) {
        flip_track() union() {
            bevel_fill(left=true, right=true);
            multi_track([
                [MALE, [Medium]],
                [MALE, [
                    path_node(parallel_radius(), parallel_angle()),
                    path_node(parallel_radius(), -parallel_angle())
                ]],
                [MALE, [
                    path_node(parallel_radius(), -parallel_angle()),
                    path_node(parallel_radius(), parallel_angle())
                ]],
            ]);
        }
        union() {
            bevel_fill(left=true, right=true);
            multi_track([
                [FEMALE, [Medium]],
                [FEMALE, [
                    path_node(parallel_radius(), parallel_angle()),
                    path_node(parallel_radius(), -parallel_angle())
                ]],
                [FEMALE, [
                    path_node(parallel_radius(), -parallel_angle()),
                    path_node(parallel_radius(), parallel_angle())
                ]],
            ], MALE);
        }
    }
}

parallel_trifork();