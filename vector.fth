\ Vector drawing utilities.
\
\ This file provides vector primitives which loosely mirror those defined by the
\ Gerber file format, with the aim of enabling easy conversion into that format.

\ "There are four types of graphics objects:
\
\ 1. Draws are straight-line segments, stroked with the current aperture, which
\ must be a solid circular one.
\ 2. Arcs are circular segments, stroked with the current aperture, which must
\ be a solid circular one.
\ 3. Flashes are replications of the current aperture in the image plane. Any
\ valid aperture can be flashed (see 4.7.5). An aperture is typically flashed
\ many times.
\ 4. Regions are defined by its contour (see 4.10.1). A contour is a closed
\ sequence of connected linear or circular segments.
\
\ In PCB copper layers, tracks are typically represented by draws and arcs, pads
\ by flashes and copper pours by regions. Tracks is then a generic name for
\ draws and arcs."
\
\ Gerber File Format Specification, Section 2.3

0 CONSTANT POL.SUBTRACT
1 CONSTANT POL.ADD

\ Shape tags for structure below
0 CONSTANT SHAPE.RECT      \ Rectangle
1 CONSTANT SHAPE.CIRCLE    \ Circle
2 CONSTANT SHAPE.LINE      \ Straight line
3 CONSTANT SHAPE.ARC       \ Circular arc
4 CONSTANT SHAPE.COMPOSITE \ Composite shape

\ Vector shapes are defined in terms of two XY coordinates. These coordinates
\ are in a standard right-up cartesian coordinate system, and are interpreted as
\ follows for each shape:
\
\ RECT:      Diagonal endpoints.
\ CIRCLE:    XY1 is center, XY2 is on the diameter. Radius is cartesian distance
\            between the two.
\ LINE:      Straight line between the two points.
\ ARC:       Clockwise arc from XY1 to XY2, both on the diameter of a circle.
\ COMPOSITE: XY1 is the origin offset for the contained shapes, XY2 ignored.
:STRUCT VECTOR
  LONG VEC.X1       \ First X coordinate for this shape
  LONG VEC.Y1       \ First Y coordinate for this shape
  LONG VEC.X2       \ Second X coordinate for this shape
  LONG VEC.Y2       \ Second Y coordinate for this shape
  RPTR VEC.DATA     \ Additional data needed to fully describe the shape
  BYTE VEC.TYPE     \ Shape tag
  BYTE VEC.POLARITY \ Whether to add or subtract from the image
;STRUCT

: VEC.INIT ( x1 y1 x2 y2 type addr -- addr , Initialize a vector )
  SWAP OVER S! VEC.TYPE
  SWAP OVER S! VEC.Y2
  SWAP OVER S! VEC.X2
  SWAP OVER S! VEC.Y1
  SWAP OVER S! VEC.X1

  \ Set default values
  0       OVER S! VEC.DATA
  POL.ADD OVER S! VEC.POLARITY
;

: VEC.CREATE ( x1 y1 x2 y2 type -- addr , Create an anonymous vector )
  HERE \ Avoid assigning name to this vector by creating memory directly
  [ SIZEOF() VECTOR ] LITERAL ALLOT
  VEC.INIT
;

: VEC.RECT ( x1 y1 x2 y2 -- addr , Create a rectangle )
  SHAPE.RECT VEC.CREATE
;

: VEC.CIRCLE_CR ( x y r -- addr , Create a circle by center and radius )
  0 2OVER 2SWAP DROP + \ Create XY2 coordinate (x, y+r)
  SHAPE.CIRCLE VEC.CREATE
;
