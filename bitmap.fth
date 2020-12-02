\ Pixels

: DISP.BUF_SIZE ( -- n , Get the size of the display buffer in bytes )
  DISP.PIXSIZE DISP.WIDTH DISP.HEIGHT * * CHARS
;

\ Create a temporary drawing buffer which can be used to incrementally set up a
\ frame.
DISP.BUF_SIZE ALLOCATE 0= NOT ABORT" Could not allocate draw buffer!"
CONSTANT DRAW_BUF

: BLIT ( -- , Draw the contents on the drawing buffer onto the display buffer )
  \ TODO Merge pixels with alpha
  DRAW_BUF DISP.PIXBUF DISP.BUF_SIZE MOVE
;

\ Get the X pixel address offset. 
: X_OFF ( n -- n ) DISP.PIXSIZE * ;

\ Get the Y pixel address offset.
: Y_OFF ( n -- n ) DISP.PIXSIZE * DISP.WIDTH * ;

: PIX_ADDR ( x y -- a ) Y_OFF SWAP X_OFF + DRAW_BUF + ;

\ Set the pixel at (x,y) to n.
: SET_PIX ( c x y -- ) PIX_ADDR ! ;

\ Get the pixel value at (x,y).
: GET_PIX ( x y -- n ) PIX_ADDR @ ;

:STRUCT ARGB
  BYTE ARGB.BLUE
  BYTE ARGB.GREEN
  BYTE ARGB.RED
  BYTE ARGB.ALPHA
;STRUCT

\ Convenience words for one half/quarter of the display width.
: HALF_WIDTH DISP.WIDTH 2 / ;
: HALF_HEIGHT DISP.HEIGHT 2 / ;
: HALF HALF_WIDTH HALF_HEIGHT ;

: QUARTER_WIDTH HALF_WIDTH 2 / ;
: QUARTER_HEIGHT HALF_HEIGHT 2 / ;
: QUARTER QUARTER_WIDTH QUARTER_HEIGHT ;

\ Colors

HEX
: WHITE FFFFFFFF ;
: RED   FFFF0000 ;
: GREEN FF00FF00 ;
: BLUE  FF0000FF ;
DECIMAL

\ Shapes

\ Draw a horizontal line in a given color.
: DRAW.HLINE ( c x y w -- )
  DUP 0> IF
    0
  ELSE
    0 SWAP
  THEN
  DO
    3DUP
    SWAP I + SWAP
    SET_PIX
  LOOP
  3DROP
;

\ Draw a vertical line in a given color.
: DRAW.VLINE ( c x y h -- )
  0 DO
    3DUP
    I +
    SET_PIX
  LOOP
  3DROP
;

\ Draw a rectangle in a given color.
: DRAW.RECT ( c x y w h -- )
  DUP 0> IF
    0
  ELSE
    0 SWAP
  THEN
  DO
    4DUP
    SWAP I + SWAP
    DRAW.HLINE
  LOOP
  4DROP
;

\ : DRAW.CIRCLE ( c x y d -- )
\ TODO
\ ;

\ Draw a test pattern.
: DRAW.TEST ( -- )
  DISP.LOCK
  WHITE QUARTER 2DUP DRAW.RECT
  RED HALF_WIDTH QUARTER_HEIGHT QUARTER DRAW.RECT
  BLUE QUARTER_WIDTH HALF_HEIGHT QUARTER DRAW.RECT
  GREEN HALF QUARTER DRAW.RECT
  DISP.UNLOCK
  DISP.RENDER
;
