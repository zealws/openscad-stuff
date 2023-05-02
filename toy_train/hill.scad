include <track_common.scad>

// Values computed using SolveSpace sketch
hill_length = 200;
hill_radius = 159.15;
hill_angle = 35.76;
hill_flat = 7;
underside_height = 60;

function hill_path() =
    [
        path_node(hill_flat),
        path_node(hill_radius, hill_angle, X),
        path_node(hill_radius, -hill_angle, X),
        path_node(hill_flat),
    ];


module center_tunnel() {
    tunnel_radius = Track_Width/2 + 10;
    // the extra -1 here puts some extra space below the connector pieces at the top of the hill.
    // if the hill is has a female connector, then a male connector can rest inside it on this extra
    // material and not fall through.
    cyl_mid_z = underside_height - tunnel_radius - 1;

    translate([0, hill_length, 0]) {
        translate([0, 0, cyl_mid_z])
            rotate([0, 90, 0])
            cylinder(h=Track_Width, r=tunnel_radius, center=true);
        translate([-Track_Width/2, -tunnel_radius, -1])
            cube([Track_Width, tunnel_radius+1, cyl_mid_z+1]);
    }
}

// duplicates it's children at regular intervals of the spacing
module array(spacing, n=2) {
    for(i = [0:n-1]) {
        translate(i*spacing)
            children();
    }
}

// generates a tiled pattern
module pattern_base(pattern="brick", depth=0.3, scale=6, line_width=0.8) {
    if (pattern == "hex") {
        radius = scale;
        alt_radius = sqrt(radius*radius - (radius/2)*(radius/2));
        line_width = 0.8;
        a = 60;
        offset = 2 * alt_radius + line_width;
        spacing = [offset * sin(a), offset * cos(a), 0];
        n = [
            1.5 * underside_height / (2 * scale),
            1.5 * hill_length / (2 * scale)
        ];

        translate([0, -n.x*spacing.y, 0])
            array(spacing, n.x)
            array([0, offset, 0], n.y)
            cylinder(2*depth, r=6, $fn=6, center=true);
    }
    if (pattern == "brick") {
        // 5:2 scale
        size = [
            0.8 * scale,
            2 * scale,
            depth*2
        ];
        spacing = [size.x+line_width, size.y+line_width, 0];
        //n = [10, 20];
        n = [
            1.2 * underside_height / size.x,
            1.4 * hill_length / size.y
        ];
        x_offset = 1.4;

        translate([-x_offset, -n.x*spacing.y/2, 0])
            array([spacing.x, spacing.y/2, 0], n.x)
            array([0, spacing.y, 0], n.y)
            translate([0, 0, -size.z/2])
            cube(size);
    }
}

module pattern_inverse(depth=0.3) {
    difference() {
        translate([-5, -5, -depth/2])
            cube([underside_height+10, hill_length+10, depth]);
        pattern_base(depth=depth);
    }
}

// orients the pattern in the right spot for the underside of the hill track
module side_pattern(x_dir=1) {
    translate(x_dir * [Track_Width/2-Track_Bevel, 0, 0])
        translate([0, 0, underside_height])
        rotate([0, 90, 0])
        pattern_inverse();
}

// under_fill renders geometry beneath the track to support it.
module under_fill(bottom_conn=FEMALE) {
    // form the basic shape of the 
    w = Track_Width/2-Track_Bevel;

    translate([0, 0, -Track_Height/2])
        difference() {
            // create an extruded rectangle that follows the contour of the hill
            path_extrude(hill_path())
                polygon(points=[
                    [-w, -underside_height],
                    [-w, 0],
                    [w, 0],
                    [w, -underside_height],
                ]);
            // cut the bottom off to make it flat
            translate([-Track_Width/2, -1, -(underside_height+2)])
                cube([Track_Width, hill_length+2, underside_height+2]);
            // cut out the female connector on the bottom so we don't have any extra
            // material there
            if (bottom_conn == FEMALE) {
                female_conn_negative();
            }
            // cut out the center tunnel
            center_tunnel();
            // cut out a texture for the side
            side_pattern();
            side_pattern(-1);
        }
}

module hill_track() {
    // Hill Tracks
    distribute([50, 0, 0]) {
        union() {
            under_fill();
            simple_track(hill_path(), only_top_grooves=true);
        }
        union() {
            under_fill(MALE);
            simple_track(hill_path(), near=MALE, far=FEMALE, only_top_grooves=true);
        }
    }
}

hill_track();