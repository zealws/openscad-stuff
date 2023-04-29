COMMON=track_common.scad

# Every scad file except the common one is a part file...
PARTS=$(shell ls *.scad | grep -v ${COMMON} | sed 's/scad/stl/')


.PHONY: all
all: ${PARTS}


%.stl: %.scad ${COMMON}
	openscad -o $@ $<