/*
path_tools.scad provides helper utilities for performing transformations sequentially to children geometry.

path_extrude can be used to form extrusions from child 2d geometry.

path_transform can be used to transform child 3d or 2d geometry.

path_distribute creates geometry for each segment of a path.

All these pethods accept a path parameter which must be a vector of path_node structs.

Each path_node represents a single linear or rotational transformtaion.
A path vector represents a sequential chain of those transformations.

path_transform and path_extrude will apply each path_node in a path sequentially to form the resulting geometry.

This can be used to create extruded geometry along complex multi-segment paths.

The file includes demo modules which demonstrate the basic usage.

Use demo_all to render all the demos, or render a single demo using the appropriate module.
*/

// Unit vectors serve as orientations for rotations.
X = [ 1, 0, 0 ];
Y = [ 0, 1, 0 ];
Z = [ 0, 0, 1 ];
// Same vectors, but expressed as Roll, Pitch, Yaw.
ROLL = Y;
PITCH = X;
YAW = Z;

// path_node constructs a struct representing a single transform within a path.
// if angle == 0 or orientation == Y, the path_node represents a linear extrusion of the provided distance.
// if angle != 0 and orientation == Y, the linear extrusion is twisted about the Y-axis (like an aileron roll).
// if angle != 0 and orientation in [X, Z], the path_node is a rotate_extrude around the provided orientation axis.
// for rotations, the distance is used as the radius of the rotation.
// positive rotation angles follow the right-hand rule, negative rotation angles are opposite to the right-hand rule.
// orientation must be an X, Y or Z unit-vector.
function path_node(dist = 0, angle = 0, orientation = Z) =
    // this is a pseudo-data structure
    [ angle, dist, orientation ];

// subvec is a helper function to take a sub-vector of a vector with the provided start point and length
// lengths less than zero mean to take the remainder of the list after the start point.
function subvec(v, s, l = -1) =
    let(
        _end = s + (l < 0 ? len(v) : l),
        end = min(_end, len(v))
    )
        s >= len(v) ? [] : [for (index = [s:1:end - 1]) v[index]];

// getvec is a helper function to retrieve an element from a vector at the provided index.
// a negative index returns the items from the back of the list (similar to python list indexes)
// e.g. v[-2] is the 2nd item from the end.
function getvec(v, idx) =
    let(true_idx = idx < 0 ? len(v) + idx : idx) v[true_idx];

// path_transform transforms it's children objects according to the transformations within the provided path.
// path should be a vector of path_node structs.
// the index is provided for debug messages, but doesn't affect the behavior.
// the child geometry can be 2d or 3d geometry.
module path_transform(path, index = 0) {
    if (len(path) == 0) {
        children();
    } else {
        transform_path_node(path[0], index)
            path_transform(subvec(path, 1), index = index + 1)
            children();
    }
}

// transform_path_node applies the transform of the provided path_node
// don't call this. call path_transform with a full path instead.
module transform_path_node(node, index) {
    angle = node[0];
    dist = node[1];
    orientation = node[2];
    if (angle == 0) {
        echo("transform_path_node(linear)", index = index, node = node);
        translate([ 0, dist, 0 ]) children();
    } else if (orientation == Y) {
        echo("transform_path_node(Y)", index = index, node = node);
        rotate(angle * Y) translate([ 0, dist, 0 ]) children();
    } else {
        trans = sign(angle) * dist * (orientation == X ? -Z : X);
        echo("transform_path_node(X|Z)", index=index, node=node, trans=trans);

        translate(-trans)
            rotate(angle * orientation)
            translate(trans)
            children();
    }
}

// path_extrude extrudes the children geometry according to the transformations in the path
// path should be a vector of path_node structs.
// the child geometry should be 2d geometry in the X-Y plane centered at the origin for best results.
// the index is provided for debug messages, but doesn't affect the behavior.
// begin_extra and end_extra enable extra extrusion at the start or end of the path, which can be helpful
// when preparing subtractive geometry so that it doesn't clip with other geometry using the same path.
module path_extrude(path, index = 0, begin_extra = 0, end_extra = 0) {
    if (len(path) > 1) {
        transform_path_node(path[0], index)
            path_extrude(subvec(path, 1), index + 1, 0, end_extra)
            children();
    }
    // amount of extra extrusion at the beginning and end of the path
    true_end_extra = len(path) == 1 ? end_extra : 0;
    extrude_path_node(path[0], index, begin_extra, true_end_extra)
        children();
}

// extrude_path_node extrudes it's children according to the provided path_node struct.
// don't call this. call path_extrude with a full path instead.
module extrude_path_node(node, index, begin_extra, end_extra) {
    angle = node[0];
    dist = node[1];
    orientation = node[2];
    angular_fn = (angle == 0 ? 0 : $fn * (360 / abs(angle)));
    if (angle == 0) {
        echo("extrude_path_node(linear)",
        index = index,
        node = node,
        begin_extra = begin_extra,
        end_extra = end_extra);

        rotate([ -90, 0, 0 ])
            translate([ 0, 0, -begin_extra ])
            linear_extrude(dist + end_extra + begin_extra)
            rotate([0, 0, 180])
            children();
    } else if (orientation == Y) {
        // Trying to do a rotate_extrude about the Y axis is meaningless since it's
        // in the direction of motion. We interpret that path as a sort of aileron
        // roll instead, which we perform as a linear_extrude with a twist.
        echo("extrude_path_node(Y)",
        index = index,
        node = node,
        begin_extra = begin_extra,
        end_extra = end_extra);

        rotate([ -90, 0, 0 ])
            translate([ 0, 0, -begin_extra ])
            linear_extrude(dist + end_extra + begin_extra, twist=-angle, $fn=angular_fn * 4)
            rotate(180 * Z)
            children();
    } else {
        true_dist = angle < 0 ? -dist : dist;

        msg = str("extrude_path_node(", (orientation == X ? "X" : "Z"), ")");
        echo(msg, index = index, node = node, true_dist = true_dist, begin_extra = begin_extra, end_extra = end_extra);

        pre_rotate = (orientation == X ? 90 : 0) * Z;
        pre_translate = true_dist * X;
        extrude_angle = sign(angle) * (abs(angle) + begin_extra + end_extra);
        mid_rotate = sign(angle) * -begin_extra * Z;
        post_translate = -pre_translate;
        post_rotate = 90 * cross(Z, orientation);

        rotate(post_rotate)
            translate(post_translate)
            rotate(mid_rotate)
            rotate_extrude(angle=extrude_angle, $fn=angular_fn)
            translate(pre_translate)
            rotate(pre_rotate)
            children();
    }
}

// path_distribute duplicates the child geometry at every segment along the path, including at the origin.
// No attempt is made to join, align, or hull the separate copies. This will nearly always create disjoint geometry.
module path_distribute(path, index=0) {
    children();
    if (len(path) > 0) {
        transform_path_node(path[0], index)
            path_distribute(subvec(path, 1), index=index+1)
            children();
    }
}

// distribute is a helper modules which applies spacing between each of it's children
module distribute(spacing) {
    for (i = [0:$children - 1]) {
        translate(spacing * i) children(i);
    }
}


/*******************************
 * ONLY DEMOS BELOW THIS POINT *
 *******************************/


// _demo_proto_geometry prepares 2d geometry for the demos 
module _demo_proto_geometry() {
    translate([0, -2])
        polygon([
            // This is an up-arrow, which is helpful for demonstrating the orientation
            // of the result in a way that a square or circle wouldn't.
            [ -1, 0 ],
            [ -1, 3 ],
            [ -2, 3 ],
            [ 0, 6 ],
            [ 2, 3 ],
            [ 1, 3 ],
            [ 1, 0 ],
        ]);
}

// _demo_text prepares a text label in the appropriate orientation for the demos
module _demo_text(msg) {
    translate([0, -5, 0])
        rotate([0, 0, 90])
        scale([0.4, 0.4, 0.4])
        color("crimson")
        text(msg, halign="right");
}
// _demo_extrude is a helper that extrudes the demo deometry by the path, and colors it.
module _demo_extrude(path, begin_extra=0, end_extra=0) {
    color("SpringGreen")
        path_extrude(path, begin_extra=begin_extra, end_extra=end_extra)
        _demo_proto_geometry();
}

// demo_input demonstrates the input geometry for the other demos
module demo_input() {
    _demo_text("input 2d geometry for demos");
    color("SpringGreen")
        _demo_proto_geometry();
}
_demo_spacing = [15, 0, 0];

// demo_simple demonstrates the simple linear and rotation use-cases for path_extrude and path_node.
module demo_simple(dist=10, angle=60) {
    distribute(_demo_spacing) {
        group() {
            _demo_text("path_node(dist)");
            _demo_extrude([path_node(dist)]);
        }

        group() {
            _demo_text("path_node(radius,angle)");
            _demo_extrude([path_node(dist, angle)]);
        }

        group() {
            _demo_text("path_node(radius,-angle)");
            _demo_extrude([path_node(dist, -angle)]);
        }
    }
}

// demo_extra_extrude demonstrates use of begin_extra and end_extra for path_extrude.
module demo_extra_extrude(dist=10, angle=60) {
    distribute(_demo_spacing) {
        group() {
            _demo_text("path_extrude(p,begin_extra) linear");
            _demo_extrude([path_node(dist, 0)], begin_extra=dist/4);
        }

        group() {
            _demo_text("path_extrude(p,end_extra) linear");
            _demo_extrude([path_node(dist, 0)], end_extra=dist/4);
        }

        group() {
            _demo_text("path_extrude(p,begin_extra) rotation");
            _demo_extrude([path_node(dist, angle)], begin_extra=angle/4);
        }
        
        group() {
            _demo_text("path_extrude(p,end_extra) rotation");
            _demo_extrude([path_node(dist, angle)], end_extra=angle/2);
        }
    }
}

// demo_orientation demonstrates the use of orientation to affect rotation path_nodes.
module demo_orientation(radius=10, angle=60) {
    distribute(_demo_spacing) {
        group() {
            _demo_text("path_node(r, a, orientation=X)");
            _demo_extrude([path_node(radius, angle, X)]);
        }

        group() {
            _demo_text("path_node(r, a, orientation=Y)");
            _demo_extrude([path_node(radius, angle*2, Y)]);
        }

        group() {
            _demo_text("path_node(r, a, orientation=Z)");
            _demo_extrude([path_node(radius, angle, Z)]);
        }
    }
}

// _demo_multisegment_path returns a demo path with many segments
function _demo_multisegment_path(dist=10, angle=45) =
    [
        path_node(dist, 0),
        path_node(dist, angle),
        path_node(dist, -2*angle),
        path_node(dist, angle, X),
        path_node(dist, 2*angle, Y),
        path_node(dist, 2*angle, X),
    ];

// demo_multisegment demonstrates the use of a providing many path nodes to chain together transformations.
module demo_multisegment() {
    _demo_text("multi-segment path");
    _demo_extrude(_demo_multisegment_path());
}

// demo_path_distribute demonstrates the use of the path_distribute module.
module demo_path_distribute() {
    _demo_text("path_distribute(path)");
    path_distribute(_demo_multisegment_path())
        color("SpringGreen")
            linear_extrude(1)
            _demo_proto_geometry();
}

// demo_all renders all the demos
module demo_all() {
    translate(0.5 * _demo_spacing) {
        demo_input();

        translate(_demo_spacing)
            demo_simple();
        
        translate(4 * _demo_spacing)
            demo_extra_extrude();

        translate(8 * _demo_spacing)
            demo_orientation();

        translate(11 * _demo_spacing)
            demo_multisegment();
            
        translate(12 * _demo_spacing)
            demo_path_distribute();
    }
}

// Uncomment this to render the demos.
//demo_all();