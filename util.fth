\ Misc

: 3DROP ( n n n -- ) DROP DROP DROP ;

: 4DUP ( d d -- d d d d ) 2OVER 2OVER ;

: 4DROP ( d d -- ) 4 0 DO DROP LOOP ;

: SGN ( n -- n , Return the sign coefficient of the number )
  DUP 0> IF
    DROP 1
  ELSE
    0= IF
      0
    ELSE
      -1
    THEN
  THEN
;

\ Shorthand for postpone which makes it easier to write lambdas.
: | POSTPONE POSTPONE ; IMMEDIATE

: L | LITERAL ; IMMEDIATE
