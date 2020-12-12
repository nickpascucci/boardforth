\ Color space
: ARGB_ALPHA ( c -- n , Get the alpha channel of a color )
  24 RSHIFT
;

: ARGB_RED ( c -- n , Get the alpha channel of a color )
  16 RSHIFT 255 AND
;

: ARGB_GREEN ( c -- n , Get the alpha channel of a color )
  8 RSHIFT 255 AND
;

: ARGB_BLUE ( c -- n , Get the alpha channel of a color )
  255 AND
;

: ARGB_JOIN ( b g r a -- c , Combine channels into a color )
  24 LSHIFT
  SWAP 16 LSHIFT +
  SWAP 8 LSHIFT +
  SWAP +
;

: ARGB_BLEND { ctop cbot -- cmix , Blend colors together with alpha transparency }
  \ For each channel:
  \ C_out = C_top * alpha_top + C_bot * alpha_bot * (1 - alpha_top)

  CTOP ARGB_BLUE CTOP ARGB_ALPHA 255 */
  255 CTOP ARGB_ALPHA -
  CBOT ARGB_BLUE CBOT ARGB_ALPHA 255 */ 255 */
  +

  CTOP ARGB_GREEN CTOP ARGB_ALPHA 255 */
  255 CTOP ARGB_ALPHA -
  CBOT ARGB_GREEN CBOT ARGB_ALPHA 255 */ 255 */
  +

  CTOP ARGB_RED CTOP ARGB_ALPHA 255 */
  255 CTOP ARGB_ALPHA -
  CBOT ARGB_RED CBOT ARGB_ALPHA 255 */ 255 */
  +

  \ alpha_out = alpha_top + (alpha_bottom * (255 - alpha_top) / 255)
  255 CTOP ARGB_ALPHA -
  CBOT ARGB_ALPHA 255 */
  CTOP ARGB_ALPHA +

  ARGB_JOIN
;

: OPACITY ( c a -- c , Set the opacity of the color )
  SWAP
  DUP DUP
  ARGB_BLUE ROT
  ARGB_GREEN ROT
  ARGB_RED
  3 ROLL
  ARGB_JOIN
;

\ Pixels

HEX
FFFFFFFF CONSTANT PIX_MASK
DECIMAL

: COLOR@ ( addr -- c , Get the color at a given address )
  @ PIX_MASK AND
;

: COLOR! ( c addr -- , Set the color stored at a given address )
  DUP @ PIX_MASK INVERT AND
  ROT PIX_MASK AND OR SWAP !
;

: PIXELS ( -- n , Get the size of a pixel in bytes )
  DISP.PIXSIZE
;

: COLORS ( -- n , Get the size of a color in bytes )
  PIXELS
;

: DISP.BUF_SIZE ( -- n , Get the size of the display buffer in bytes )
  PIXELS DISP.WIDTH DISP.HEIGHT * * CHARS
;

\ Create a temporary drawing buffer which can be used to incrementally set up a
\ frame.
DISP.BUF_SIZE ALLOCATE 0= NOT ABORT" Could not allocate draw buffer!"
CONSTANT DRAW_BUF

\ Get the X pixel address offset.
: X_OFF ( n -- n ) DISP.PIXSIZE * ;

\ Get the Y pixel address offset.
: Y_OFF ( n -- n ) DISP.PIXSIZE * DISP.WIDTH * ;

VARIABLE DIRTY_X_MIN
VARIABLE DIRTY_Y_MIN

DISP.WIDTH  DIRTY_X_MIN !
DISP.HEIGHT DIRTY_Y_MIN !

VARIABLE DIRTY_X_MAX
VARIABLE DIRTY_Y_MAX

0 DIRTY_X_MAX !
0 DIRTY_Y_MAX !

: BLIT ( -- , Draw the contents of the drawing buffer onto the display buffer )
  DIRTY_Y_MAX @ DIRTY_Y_MIN @ > IF
    DIRTY_X_MAX @ DIRTY_X_MIN @ > IF
      DIRTY_Y_MAX @ DIRTY_Y_MIN @ DO
        DIRTY_X_MAX @ DIRTY_X_MIN @ DO
          DRAW_BUF    I X_OFF J Y_OFF + + COLOR@
          DISP.PIXBUF I X_OFF J Y_OFF + + COLOR@ ARGB_BLEND
          DISP.PIXBUF I X_OFF J Y_OFF + + COLOR!
        LOOP
      LOOP
    THEN
  THEN
;

: CLEAR ( addr -- , Clear a render buffer )
  DRAW_BUF DISP.BUF_SIZE ERASE
  0 DIRTY_X_MAX !
  0 DIRTY_Y_MAX !

  DISP.WIDTH  DIRTY_X_MIN !
  DISP.HEIGHT DIRTY_Y_MIN !
;

: PIX_ADDR ( x y -- a ) Y_OFF SWAP X_OFF + DRAW_BUF + ;

: IN_BOUNDS? ( x y -- f , Test if an XY coordinate is on the screen )
  DUP 0 >= SWAP DISP.HEIGHT < AND
  SWAP
  DUP 0 >= SWAP DISP.WIDTH < AND
  AND
;

: SET_DIRTY ( x y -- , Set the dirty region bounds )
  DUP DIRTY_Y_MIN @ < IF DUP DIRTY_Y_MIN ! THEN
  DUP DIRTY_Y_MAX @ > IF DIRTY_Y_MAX ! ELSE DROP THEN
  DUP DIRTY_X_MIN @ < IF DUP DIRTY_X_MIN ! THEN
  DUP DIRTY_X_MAX @ > IF DIRTY_X_MAX ! ELSE DROP THEN
;

\ Set the pixel at (x,y) to n.
: SET_PIX ( c x y -- )
  2DUP IN_BOUNDS? IF
    2DUP SET_DIRTY
    PIX_ADDR \ c addr
    SWAP PIX_MASK AND \ addr c
    OVER @ PIX_MASK INVERT AND
    OR
    SWAP !
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
: TRANSPARENT 00000000 ;
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
: COPPER     FFB87333 ;

\ Custom colors
: FR4        FF204F35 ;
DECIMAL


\ Shapes

\ Draw a horizontal line in a given color.
: DRAW.HLINE ( c x y w -- )
  DUP 0> IF
    0
  ELSE
    0 SWAP
  THEN
  2DUP = NOT IF
    DO
      3DUP
      SWAP I + SWAP
      SET_PIX
    LOOP
  ELSE
    2DROP
  THEN
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
  CLEAR
  WHITE QUARTER_WIDTH QUARTER_HEIGHT 2DUP QUARTER TRANSLATE DRAW.RECT
  RED   HALF_WIDTH    QUARTER_HEIGHT 2DUP QUARTER TRANSLATE DRAW.RECT
  BLUE  QUARTER_WIDTH HALF_HEIGHT    2DUP QUARTER TRANSLATE DRAW.RECT
  GREEN HALF_WIDTH    HALF_HEIGHT    2DUP QUARTER TRANSLATE DRAW.RECT
  DISP.LOCK
  BLIT
  DISP.UNLOCK
  DISP.RENDER
;
