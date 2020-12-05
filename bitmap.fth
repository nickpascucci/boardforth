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

: CLEAR ( addr -- , Clear a render buffer )
  DISP.BUF_SIZE ERASE
;

\ Get the X pixel address offset. 
: X_OFF ( n -- n ) DISP.PIXSIZE * ;

\ Get the Y pixel address offset.
: Y_OFF ( n -- n ) DISP.PIXSIZE * DISP.WIDTH * ;

: PIX_ADDR ( x y -- a ) Y_OFF SWAP X_OFF + DRAW_BUF + ;

: IN_BOUNDS? ( x y -- f , Test if an XY coordinate is on the screen )
  DUP 0 >= SWAP DISP.HEIGHT < AND
  SWAP
  DUP 0 >= SWAP DISP.WIDTH < AND
  AND
;

\ Set the pixel at (x,y) to n.
: SET_PIX ( c x y -- )
  2DUP IN_BOUNDS? IF
    PIX_ADDR !
  ELSE
    3DROP
    \ TODO When clipping is implemented, ABORT if asked to render outside the
    \ viewport so that errors can be detected earlier.
  THEN
;

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
\ Basic colors
: CLEAR 00000000 ;
: BLACK FF000000 ;
: WHITE FFFFFFFF ;
: RED   FFFF0000 ;
: GREEN FF00FF00 ;
: BLUE  FF0000FF ;

\ Basic combinations
: CYAN    FF00FFFF ;
: FUSCHIA FFFF00FF ;
: YELLOW  FFFFFF00 ;
: GRAY    FF808080 ;

\ CSS Colors
: DARK_RED   FF8B0000 ;
: DARK_GREEN FF006400 ;
: DARK_BLUE  FF00008B ;
: GOLD       FFFFD700 ;
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
: DRAW.RECT ( c x1 y1 x2 y2 -- )
 \ Get coordinates in the right order: highest to lowest in x and y.
  ROT -2SORT 2SWAP 2SORT 2SWAP
  DO
    3DUP
    2DUP - ABS
    NIP I SWAP
    DRAW.HLINE
  LOOP
  3DROP
;

\ : DRAW.CIRCLE ( c x y d -- )
\ TODO
\ ;

\ Draw a test pattern.
\ w r
\ b g
: DRAW.TEST ( -- )
  DRAW_BUF CLEAR
  WHITE QUARTER_WIDTH QUARTER_HEIGHT 2DUP QUARTER TRANSLATE DRAW.RECT
  RED   HALF_WIDTH    QUARTER_HEIGHT 2DUP QUARTER TRANSLATE DRAW.RECT
  BLUE  QUARTER_WIDTH HALF_HEIGHT    2DUP QUARTER TRANSLATE DRAW.RECT
  GREEN HALF_WIDTH    HALF_HEIGHT    2DUP QUARTER TRANSLATE DRAW.RECT
  DISP.LOCK
  BLIT
  DISP.UNLOCK
  DISP.RENDER
;
