// Measurements and piece layout from:
// https://woodenrailway.info/track/brio-track-guide

include <../paths/path_tools.scad>

/* [Part Properties] */

// Length of a medium straight track piece (default 144)
Medium_Length = 144;

// Length of a mini track piece (default 54)
Mini_Length = 54;

// Length of a curved piece as an angle in degrees (default 45)
Curve_Angle = 45;

// Radius of small curved pieces (default 90)
Sharp_Radius = 90;

// Radius of wide curved pieces (default 182)
Wide_Radius = 182;

/* [Track Properties] */

// Width of the track cross-section (default 40)
Track_Width = 40;

// Height of the track cross-section (default 12)
Track_Height = 12;

// Width of the bevel on the track edges (default 1)
Track_Bevel = 1;

/* [Rail Properties] */

// Spacing between rail lines, center to center (default 26)
Rail_Spacing = 26;

// Depth of the rail groove, from the surface of the track (default 3)
Rail_Depth = 3;

// Width of the rail groove, at the top of the groove (default 6)
Rail_Width = 6;

// Width of the rail groove, at the bottom of the groove, expressed as a ratio of the Rail Width (default 0.8)
Rail_Trapezoid = 0.8;

/* [Connector Properties] */

// Distance from the edge of a track piece to the center of the head (default 7)
Connector_Neck_Length = 7;

// Male connector head diameter (default 11.5)
Male_Connector_Diameter = 11.5;

// Male connector neck width (default 5)
Male_Neck_Width = 5;

// Female connector head diameter (default 16)
Female_Connector_Diameter = 14;

// Female connector neck width (default 7)
Female_Neck_Width = 7;

/* [Computed - DO NOT CHANGE] */

$fn = $preview ? 20 : 120;
angle_fn = $fn * (360 / Curve_Angle);
Male_Connector_Length = Connector_Neck_Length + Male_Connector_Diameter + 5;
function curve_sweep(radius) = Male_Connector_Length * 360 / (2 * PI * radius);

FEMALE = 0;
MALE = 1;
function connector_extension(kind, node) = (kind == FEMALE
                                                ? 0
                                                : (node[0] == 0
                                                       ? Male_Connector_Length
                                                       : curve_sweep(node[1])));

// we need to figure out how far away the head of the connector is from the
// neck. pythagorean formula in use here... point A = center of the end of the
// connector neck facing the head point B = center of the connector head circle
// point C = corner of the connector neck, which is on the connector head
// circle angle BAC is a right angle, because the connector neck is rectangular
// distance AC = half the connector neck width
// dinstance BC = radius of the connector head
// distance AB is the thing we want to find
_ab = sqrt((Male_Connector_Diameter / 2) ^ 2 - (Male_Neck_Width / 2) ^ 2);
Male_Connector_Offset = Connector_Neck_Length + _ab;
Female_Connector_Offset = Connector_Neck_Length + _ab - 1;

function rail_groove(l, m) = let(
    x = Track_Width / 2 + (l ? -Rail_Spacing : Rail_Spacing) / 2 -
        Rail_Width / 2,
    y = m ? Track_Height : 0,
    trap_offset = Rail_Width * (1 - Rail_Trapezoid) / 2,
    rail_y_depth = m ? -Rail_Depth : Rail_Depth,
    b = m ? 1
          : -1)[[ x, y ], [ x + trap_offset, y + rail_y_depth ],
                [ x + Rail_Width - trap_offset, y + rail_y_depth ],
                [ x + Rail_Width, y ], [ x + Rail_Width, y + b ], [ x, y + b ],
];

function profile_verts() =
    let(b = Track_Bevel,
        left_wall = [[b, 0], [0, b], [0, Track_Height - b], [b, Track_Height]],
        right_wall = [[Track_Width - b, Track_Height],
                      [Track_Width, Track_Height - b], [Track_Width, b],
                      [Track_Width - b, 0]]) concat(left_wall, right_wall);

// returns the positive geometry of the 2-dimensional track profile
module track_profile() {
  translate([ -Track_Width / 2, -Track_Height / 2, 0 ])
      polygon(profile_verts());
}

// returns the negative groove geometry of the 2-dimensional track profile
// the profile will will be flat on the X-Y plane, with the bottom center at
// the origin.
module track_grooves(only_top_grooves) {
  translate([ -Track_Width / 2, -Track_Height / 2, 0 ]) {
    polygon(rail_groove(true, true));
    polygon(rail_groove(false, true));
    if (!only_top_grooves) {
        polygon(rail_groove(false, false));
        polygon(rail_groove(true, false));
    }
  }
}

module bare_connector(d, w, o, buffer = 1, bevel = 0) {
  // d is the diameter of the head
  // w is the width of the neck
  // o is the offset of the neck
  // buffer is the extra padding to add around the interfaces of the model
  // bevel is how much to bevel the connector by
  if (bevel == 0) {
    // connector head
    translate([ 0, o, -buffer ]) cylinder(h = Track_Height + 2 * buffer, d = d);
    // connector neck
    translate([ -w / 2, -buffer, -buffer ]) cube(
        [ w, Connector_Neck_Length + 2 * buffer, Track_Height + 2 * buffer ]);
  } else {
    // connector head
    translate([ 0, o, 0 ]) {
      // bottom
      hull() {
        translate([ 0, 0, -buffer ]) cylinder(h = buffer, d = d + 2 * bevel);
        cylinder(h = bevel, d = d);
      }
      // top
      hull() {
        translate([ 0, 0, Track_Height ])
            cylinder(h = buffer, d = d + 2 * bevel);
        translate([ 0, 0, Track_Height - bevel ]) cylinder(h = buffer, d = d);
      }
      // middle
      cylinder(h = Track_Height, d = d);
    }
    // connector neck
    translate([ -w / 2, 0, 0 ]) {
      // bottom
      hull() {
        translate([ -bevel, -buffer, -buffer ])
            cube([ w + 2 * bevel, Connector_Neck_Length + 2 * buffer, buffer ]);
        translate([ 0, -buffer, 0 ])
            cube([ w, Connector_Neck_Length + 2 * buffer, bevel ]);
      }
      // top
      hull() {
        translate([ -bevel, -buffer, Track_Height ])
            cube([ w + 2 * bevel, Connector_Neck_Length + 2 * buffer, buffer ]);
        translate([ 0, -buffer, Track_Height - bevel ])
            cube([ w, Connector_Neck_Length + 2 * buffer, bevel ]);
      }
      // middle
      translate([ 0, -buffer, 0 ])
          cube([ w, Connector_Neck_Length + 2 * buffer, Track_Height ]);
    }
  }
}

module male_conn_negative() {
  // need enough buffer space to cover straight track clipping issues,
  // but also curved tracks which might curve out to one side or another
  length = Connector_Neck_Length + Male_Connector_Diameter + 20;
  difference() {
    rotate([ 0, 0, 180 ]) translate([ -Track_Width / 2 - 5, 0, -10 ])
        cube([ Track_Width + 10, length, Track_Height + 20 ]);
    rotate([ 0, 0, 180 ])
        bare_connector(d = Male_Connector_Diameter, w = Male_Neck_Width,
                       o = Male_Connector_Offset, buffer = 2);
  }
}

module female_conn_negative() {
    bare_connector(
        d=Female_Connector_Diameter,
        w=Female_Neck_Width,
        o=Female_Connector_Offset,
        buffer=4,
        bevel=Track_Bevel
    );
}

module make_connector(kind = FEMALE) {
  translate([ 0, 0, -Track_Height / 2 ]) if (kind == MALE) {
    male_conn_negative();
  }
  else {
    female_conn_negative();
  }
}

// targets is a list of tuples [connector_type, path]
module multi_track(targets, near = FEMALE, only_top_grooves=false) {
  difference() {
    // add the track profile, extruded along the path
    for (target = targets) {
      far = target[0];
      path = target[1];
      path_extrude(path, begin_extra = connector_extension(near, path[0]),
                   end_extra = connector_extension(far, getvec(path, -1)))
          track_profile();
    }
    // subtract the near and far connector
    make_connector(near);
    for (target = targets) {
      far = target[0];
      path = target[1];
      // subtract the track grooves along the whole path
      path_extrude(path, begin_extra = 2, end_extra = 2) track_grooves(only_top_grooves);
      path_transform(path) rotate([ 0, 0, 180 ]) make_connector(far);
    }
  }
}

module flip_track(length=Medium_Length) {
    rotate([0, 0, 180])
        translate([0, -length, 0])
        children();
}

// Basic path_node structs for common track types.

Medium = path_node(Medium_Length, 0);
Short = path_node(Mini_Length, 0);
WideL = path_node(Wide_Radius, Curve_Angle);
WideR = path_node(Wide_Radius, -Curve_Angle);
SharpL = path_node(Sharp_Radius, Curve_Angle);
SharpR = path_node(Sharp_Radius, -Curve_Angle);
TurnL = path_node(Sharp_Radius, 90);
TurnR = path_node(Sharp_Radius, -90);