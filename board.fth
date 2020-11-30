\ Board and component layout primitives.

\ A structure representing a printed circuit board.
:STRUCT BOARD
  RPTR BOARD.FIRST_PART \ Pointer to the first part
  RPTR BOARD.LAST_PART  \ Pointer to the last part
  BYTE BOARD.NUM_LAYERS \ Number of layers in the board
;STRUCT

\ Most operations act on the current board.
VARIABLE CURRENT_BOARD

: LAYERS ( n -- )
  CURRENT_BOARD S! BOARD.NUM_LAYERS
;

\ A board "component". Components are considered broadly, and include the board
\ substrate itself as well as discrete components, copper traces, silkscreen
\ legends, etc. Components can be rendered into a graphics object for view or
\ fabrication, and connected together in a netlist.
:STRUCT COMPONENT_T
  RPTR COMPONENT.DRAW_WORD   \ Execution token to draw the component
  RPTR COMPONENT.NEXT_PART   \ Next component in the list
  RPTR COMPONENT.PORT_COORDS \ Pointer to table with coordinates for each port
  BYTE COMPONENT.NUM_PORTS   \ Number of ports in this component
;STRUCT

: COMPONENT.CREATE ( -- addr , Create a component by name and leave its address )
  SAVE-INPUT  \ COMPONENT_T will consume the input buffer to create a variable;
  COMPONENT_T \ store the input so we can retrieve that variable's address.
  RESTORE-INPUT ABORT" Couldn't restore input!"
  32 ( ASCII space ) PARSE EVALUATE
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
  COMPONENT.CREATE
  \ TODO Define draw semantics for a rectangular board region.
  COMPONENT.LINK
;

