include <track_common.scad>

module simple_tracks() {
    // Simple Tracks
    distribute([50, 0, 0]) {
        simple_track([TurnL]);
        simple_track([WideL]);
        simple_track([Medium]);
        simple_track([Short]);
        simple_track([Short], near=MALE);
        simple_track([Short], far=FEMALE);
    }
}

simple_tracks();