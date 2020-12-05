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
0 CONSTANT SHAPE.NONE   \ Blank
1 CONSTANT SHAPE.RECT   \ Rectangle
2 CONSTANT SHAPE.CIRCLE \ Circle
3 CONSTANT SHAPE.LINE   \ Straight line
4 CONSTANT SHAPE.ARC    \ Circular arc
5 CONSTANT SHAPE.GROUP  \ Composite shape

\ Vector shapes are defined in terms of two XY coordinates. These coordinates
\ are in a standard right-up cartesian coordinate system, and are interpreted as
\ follows for each shape:
\
\ RECT:   Diagonal endpoints.
\ CIRCLE: XY1 is center, XY2 is on the diameter. Radius is cartesian distance
\         between the two.
\ LINE:   Straight line between the two points.
\ ARC:    Clockwise arc from XY1 to XY2, both on the diameter of a circle.
\ GROUP:  XY1 is the origin offset for the contained shapes, XY2 ignored.
:STRUCT VECTOR
  LONG VEC.X1       \ First X coordinate for this shape
  LONG VEC.Y1       \ First Y coordinate for this shape
  LONG VEC.X2       \ Second X coordinate for this shape
  LONG VEC.Y2       \ Second Y coordinate for this shape
  RPTR VEC.DATA     \ Additional data needed to fully describe the shape
  BYTE VEC.TYPE     \ Shape tag
  BYTE VEC.POLARITY \ Whether to add or subtract from the image
;STRUCT

:STRUCT GROUP_INFO
  LONG GROUP.N       \ Number of child vectors in this group
  RPTR GROUP.MEMBERS \ Dummy value, start of address space for members
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

: VEC.SHOW ( addr -- , Display a human-friendly printout of the vector )
  \ TODO Add support for showing groups
  CR
  ." => "
  DUP S@ VEC.X1 ." X1: " .
  DUP S@ VEC.Y1 ." Y1: " .
  DUP S@ VEC.X2 ." X2: " .
  DUP S@ VEC.Y2 ." Y2: " .
  DUP S@ VEC.TYPE ." TYPE: " .
  DUP S@ VEC.POLARITY ." POLARITY: " .
  DROP
;

: VEC.CREATE ( x1 y1 x2 y2 type -- addr , Create an anonymous vector )
  HERE \ Avoid assigning name to this vector by creating memory directly
  [ SIZEOF() VECTOR ] LITERAL ALLOT
  VEC.INIT
;

: VEC.NONE ( -- addr , Create an empty vector object )
  0 0 0 0 SHAPE.NONE VEC.CREATE
;

: VEC.RECT ( x1 y1 x2 y2 -- addr , Create a rectangle )
  SHAPE.RECT VEC.CREATE
;

: VEC.CIRCLE_CR ( x y r -- addr , Create a circle by center and radius )
  0 2OVER 2SWAP DROP + \ Create XY2 coordinate (x, y+r)
  SHAPE.CIRCLE VEC.CREATE
;

: GROUP_INFO.CREATE ( n -- addr , Create an anonymous group info struct )
  \ Avoid assigning name to this vector by creating memory directly
  HERE SWAP
  [ SIZEOF() GROUP_INFO ] LITERAL ALLOT
  DUP CELLS ALLOT
  OVER S! GROUP.N
;

: GROUP.MEMBER_ADDR ( n addr -- addr , Get the address of a group member )
  \ Get base address of members field
  S@ VEC.DATA
  .. GROUP.MEMBERS
  SWAP
  CELLS +
;

: GROUP.INIT ( n -- vaddr n , Create a group object to hold n members )
  0 0 0 0 SHAPE.GROUP VEC.CREATE \ addr* n vaddr
  SWAP
  2DUP \ a* v n v n
  GROUP_INFO.CREATE \ a* v n v g
  SWAP S! VEC.DATA \ a* v n
;

: GROUP.ADD_MEMBERS ( addr* vaddr n -- vaddr , Add n members to a group )
  0 DO \ a* v
    DUP \ a* v v
    -ROT \ a*' v a' v
    I SWAP GROUP.MEMBER_ADDR ! \ Index to I'th member and set value
  LOOP
;

\ A group defines a local coordinate system which can contain other vector
\ objects, all of which are translated and scaled relative to the group origin.
: VEC.GROUP ( addr* n -- addr , Group n vectors together )
  GROUP.INIT GROUP.ADD_MEMBERS
;

: VEC.WH ( addr -- w h , Get the width and height of a vector container )
  DUP DUP DUP
  S@ VEC.X2
  SWAP S@ VEC.X1 -
  -ROT S@ VEC.Y2
  SWAP S@ VEC.Y1 -
;

: VEC.XY1 ( addr -- x1 y1 , Get the XY1 coordinates of the vector )
  DUP \ addr addr
  S@ VEC.X1 SWAP \ x1 addr
  S@ VEC.Y1 \ x1 y1
;

: VEC.XY2 ( addr -- x2 y2 , Get the XY2 coordinates of the vector )
  DUP
  S@ VEC.X2 SWAP
  S@ VEC.Y2
;

\ Positive zoom factor zooms in. A negative zoom factor will zoom out.
\ TODO Implement zoom for groups
: VEC.ZOOM ( addr n -- , Apply a zoom transformation to the vector )
  2DUP SWAP \ addr n n addr
  VEC.XY1 ROT ZOOM \ addr n x1' y1'
  3 PICK TUCK  \ addr n x1' addr y1'
  S! VEC.Y1
  S! VEC.X1 \ addr n
  OVER \ addr n addr
  VEC.XY2 ROT ZOOM \ addr x2' y2'
  ROT TUCK  \ x2' addr y2' addr
  S! VEC.Y2
  S! VEC.X2
;

: VEC.SCREEN_COORDS ( addr -- sx1 sy1 sx2 sy2 , Get screen coords of vector )
  DUP VEC.XY1 REFLECT_Y DISP.HEIGHT TRANSLATE_Y
  ROT VEC.XY2 REFLECT_Y DISP.HEIGHT TRANSLATE_Y
;

: VEC.DRAW_RECT ( c addr -- , Draw a vector rectangle to a pixel buffer )
  VEC.SCREEN_COORDS DRAW.RECT
;

: VEC.DRAW ( c addr -- , Draw a vector shape to a pixel buffer )
  DUP S@ VEC.TYPE
  CASE
    SHAPE.NONE OF DROP DROP ( Do nothing ) ENDOF
    SHAPE.RECT OF VEC.DRAW_RECT ENDOF
    \ TODO Implement drawing for groups
  ENDCASE
;
