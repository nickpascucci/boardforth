\ Misc

: 3DROP ( n n n -- ) 3 0 DO DROP LOOP ;

: 4DUP ( d d -- d d d d ) 2OVER 2OVER ;

: 4DROP ( d d -- ) 4 0 DO DROP LOOP ;

\ Pixels

\ Get the X pixel address offset. 
: X_OFF ( n -- n ) DISP.PIXSIZE * ;

\ Get the Y pixel address offset.
: Y_OFF ( n -- n ) DISP.PIXSIZE * DISP.WIDTH * ;

: PIX_ADDR ( x y -- a ) Y_OFF SWAP X_OFF + ;

\ Set the pixel at (x,y) to n.
: SET_PIX ( c x y -- ) PIX_ADDR DISP.PIXBUF + ! ;

\ Get the pixel value at (x,y).
: GET_PIX ( x y -- n ) PIX_ADDR DISP.PIXBUF + @ ;

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

: DRAW.HLINE ( c x y w -- )
  0 DO
    3DUP
    SWAP I + SWAP
    SET_PIX
  LOOP
  3DROP
;

: DRAW.VLINE ( c x y h -- )
  0 DO
    3DUP
    I +
    SET_PIX
  LOOP
  3DROP
;

: DRAW.RECT ( c x y w h -- )
  0 DO
    4DUP
    SWAP I + SWAP
    DRAW.HLINE
  LOOP
  4DROP
;

: DRAW.TEST ( -- )
  DISP.LOCK
  WHITE QUARTER 2DUP DRAW.RECT
  RED HALF_WIDTH QUARTER_HEIGHT QUARTER DRAW.RECT
  BLUE QUARTER_WIDTH HALF_HEIGHT QUARTER DRAW.RECT
  GREEN HALF QUARTER DRAW.RECT
  DISP.UNLOCK
  DISP.RENDER
;

\ DRAW_TEST
