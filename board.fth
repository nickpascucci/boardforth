\ Board and component layout primitives.

\ A structure representing a printed circuit board.
:STRUCT BOARD
  RPTR BOARD.FIRST_PART \ Pointer to the first part
  RPTR BOARD.LAST_PART  \ Pointer to the last part
  BYTE BOARD.NUM_LAYERS \ Number of layers in the board
;STRUCT

: BOARD.INIT ( addr -- addr, Initialize a board's memory )
  [ SIZEOF() BOARD ] LITERAL ERASE
;

\ Most operations act on the current board.
VARIABLE CURRENT_BOARD

0 CONSTANT BOARD_OUTLINE_LAYER
1 CONSTANT BOT_SILK_LAYER
2 CONSTANT BOT_MASK_LAYER
3 CONSTANT BOT_COPPER_LAYER
4 CONSTANT TOP_COPPER_LAYER
5 CONSTANT TOP_MASK_LAYER
6 CONSTANT TOP_SILK_LAYER

32 CONSTANT MAX_LAYERS

\ Each bit corresponds to a layer; if the layer is visible, it is one.
VARIABLE LAYER_VISIBLE_BITFIELD
HEX FFFF DECIMAL LAYER_VISIBLE_BITFIELD !

: LAYER_MASK ( n -- n , Create bitmask for layer )
  1 SWAP LSHIFT
;

: LAYER_ON? ( n -- f , Return a truthy value if layer n is enabled )
  LAYER_MASK LAYER_VISIBLE_BITFIELD @ AND
;

: SHOW_LAYER ( n -- , Turn on a layer for rendering )
  LAYER_MASK
  LAYER_VISIBLE_BITFIELD @
  OR
  LAYER_VISIBLE_BITFIELD !
;

: HIDE_LAYER ( n -- , Turn on a layer for rendering )
  LAYER_MASK
  LAYER_VISIBLE_BITFIELD @
  XOR
  LAYER_VISIBLE_BITFIELD !
;

VARIABLE UNITS_PER_PIXEL
100 UM UNITS_PER_PIXEL !

: BOARD_ZOOM ( -- n , Get the zoom factor for the board )
  -1 UNITS_PER_PIXEL @ *
;

VARIABLE LAYER_COLORS MAX_LAYERS DISP.PIXSIZE * ALLOT

: LAYER_COLOR_ADDR ( n -- addr , Get the address of the layer color cell )
  DISP.PIXSIZE * LAYER_COLORS +
;

: LAYER_COLOR ( n -- c , Get the color for a given layer)
  LAYER_COLOR_ADDR @
;

: SET_LAYER_COLOR ( c n -- , Set the color of a layer )
  LAYER_COLOR_ADDR !
;

DARK_GREEN BOARD_OUTLINE_LAYER SET_LAYER_COLOR

WHITE BOT_SILK_LAYER SET_LAYER_COLOR
BLUE  BOT_MASK_LAYER SET_LAYER_COLOR
RED   BOT_COPPER_LAYER SET_LAYER_COLOR

\ TODO Use separate colors for bottom/top layers.
RED   TOP_COPPER_LAYER SET_LAYER_COLOR
BLUE  TOP_MASK_LAYER SET_LAYER_COLOR
WHITE TOP_SILK_LAYER SET_LAYER_COLOR

\ TODO Set other layer colors

: LAYERS ( n -- )
  DUP MAX_LAYERS > ABORT" Can't use that many layers; check MAX_LAYERS"
  CURRENT_BOARD @ S! BOARD.NUM_LAYERS
;

\ A board "component". Components are considered broadly, and include the board
\ substrate itself as well as discrete components, copper traces, silkscreen
\ legends, etc. Components can be rendered into a graphics object for view or
\ fabrication, and connected together in a netlist.
\
\ Rendering is done by EXECUTE'ing the execution token stored in the DRAW field.
\ The DRAW logic should have the stack effect ( l -- vaddr ), where l is the
\ layer number and vaddr is the address of the resulting vector object.
\
\ TODO How do we want to handle cleaning up vector objects after use? Right now
\ they are just leaked; this is probably fine for a small project.
:STRUCT COMPONENT
  RPTR COMPONENT.DRAW        \ Execution token to draw the component as vector
  RPTR COMPONENT.NEXT_PART   \ Next component in the list
  RPTR COMPONENT.PORT_COORDS \ Pointer to table with coordinates for each port
  BYTE COMPONENT.NUM_PORTS   \ Number of ports in this component
;STRUCT

: COMPONENT.INIT ( addr -- addr , Initialize a component)
  DUP [ SIZEOF() COMPONENT ] LITERAL ERASE \ Zero memory
;

: COMPONENT.CREATE ( -- addr , Create an anonymous component )
  HERE \ Avoid assigning name to this vector by creating memory directly
  [ SIZEOF() COMPONENT ] LITERAL ALLOT
  COMPONENT.INIT
;

: COMPONENT.NAMED ( <name> -- addr , Create a named component and leave its address )
  CREATE COMPONENT.CREATE COMPONENT.INIT
;

: COMPONENT.LINK ( addr -- , Link a component to the current board )
  DUP \ Check if the current board has any components set.
  CURRENT_BOARD @ S@ BOARD.FIRST_PART 0=
  IF
    \ If not, set the first part to our component.
    CURRENT_BOARD @ S! BOARD.FIRST_PART
  ELSE
    \ Otherwise, we need to find the last part in the chain and extend.
    CURRENT_BOARD @ S@ BOARD.LAST_PART
    S! COMPONENT.NEXT_PART
  THEN
  \ The new part is always the last one.
  CURRENT_BOARD @ S! BOARD.LAST_PART
;

: BOARD.DRAW_LAYER ( l -- , Draw a board layer to the temporary draw buffer )
  CURRENT_BOARD @ S@ BOARD.FIRST_PART \ l paddr
  DUP 0= NOT IF \ l paddr
    BEGIN
      2DUP \ l paddr l paddr
      \ Create the vector object representing the component at this layer
      S@ COMPONENT.DRAW EXECUTE \ l paddr vaddr
      2 PICK LAYER_COLOR \ l paddr vaddr c
      SWAP VEC.DRAW \ l paddr
      DUP S@ COMPONENT.NEXT_PART
      0=
    UNTIL
  THEN
  2DROP
;

: BOARD.DRAW ( -- , Draw the board to the screen )
  DISP.LOCK
  DRAW_BUF CLEAR
  CURRENT_BOARD @ S@ BOARD.NUM_LAYERS 0 DO
    I BOARD.DRAW_LAYER
    BLIT
  LOOP
  DISP.UNLOCK
  DISP.RENDER
;

: RECTANGULAR.DRAW { w h -- }
  :NONAME ( l -- vaddr )
    BOARD_OUTLINE_LAYER POSTPONE LITERAL POSTPONE =
    POSTPONE IF
      0 POSTPONE LITERAL
      0 POSTPONE LITERAL
      w POSTPONE LITERAL
      h POSTPONE LITERAL
      POSTPONE VEC.RECT
    POSTPONE ELSE
      POSTPONE VEC.NONE
    POSTPONE THEN
  POSTPONE ; \ caddr xt
;

: RECTANGULAR ( w h -- , Define and link a rectangular circuit board )
  COMPONENT.CREATE \ w h caddr
  -ROT \ caddr w h
  RECTANGULAR.DRAW \ caddr xt
  OVER \ caddr xt caddr
  S! COMPONENT.DRAW \ caddr
  COMPONENT.LINK
;
