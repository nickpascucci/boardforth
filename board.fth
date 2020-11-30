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

: LAYERS ( n -- )
  CURRENT_BOARD @ S! BOARD.NUM_LAYERS
;

\ A board "component". Components are considered broadly, and include the board
\ substrate itself as well as discrete components, copper traces, silkscreen
\ legends, etc. Components can be rendered into a graphics object for view or
\ fabrication, and connected together in a netlist.
:STRUCT COMPONENT
  RPTR COMPONENT.SHAPE       \ Pointer to the component shape vector object
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

: RECTANGULAR ( w h -- , Define and link a rectangular circuit board )
  COMPONENT.CREATE \ w h caddr
  -ROT \ caddr w h
  0 0 2SWAP VEC.RECT \ caddr raddr
  OVER \ caddr raddr caddr
  S! COMPONENT.SHAPE
  COMPONENT.LINK
;
