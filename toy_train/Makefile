
COMMON=track_common.scad

PARTS=\
	simple.stl

.PHONY: all
all: ${PARTS}

%.stl: %.scad ${COMMON}
	openscad -o $@ $<