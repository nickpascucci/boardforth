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

0 CONSTANT BOARD_LAYER
1 CONSTANT TOP_SILK_LAYER
2 CONSTANT TOP_MASK_LAYER
3 CONSTANT TOP_COPPER_LAYER
4 CONSTANT BOT_COPPER_LAYER
5 CONSTANT BOT_MASK_LAYER
6 CONSTANT BOT_SILK_LAYER


: LAYERS ( n -- )
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

: RECTANGULAR.DRAW { w h -- }
  :NONAME ( l -- vaddr )
    BOARD_LAYER POSTPONE LITERAL POSTPONE =
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
