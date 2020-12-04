\ Misc

: 3DROP ( n n n -- ) DROP DROP DROP ;

: 4DUP ( d d -- d d d d ) 2OVER 2OVER ;

: 4DROP ( d d -- ) 4 0 DO DROP LOOP ;
