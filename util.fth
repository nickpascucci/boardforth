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

: SAVE-STR ( addr n -- addr' n , Copy a string into a permanent memory buffer )
  HERE OVER \ addr n addr' n
  2SWAP \ addr' n addr n
  HERE SWAP \ addr' n addr addr' n
  DUP CHARS ALLOT MOVE
;

VARIABLE _PEEK_PTR
VARIABLE _PEEK_COUNT

: PEEK-INPUT ( -- addr u , Peek at the input buffer and store the next word )
  SAVE-INPUT
  BL PARSE
  SAVE-STR
  _PEEK_COUNT !
  _PEEK_PTR !
  RESTORE-INPUT ABORT" PEEK-INPUT: Failed to restore input"
  _PEEK_PTR @
  _PEEK_COUNT @
;

: S= ( addr1 u1 addr2 u2 -- f , Test if two strings are equal )
  ROT \ addr1 addr2 u2 u1
  OVER =
  IF \ addr1 addr2 u2
    TRUE SWAP \ addr1 addr2 f u2
    DUP 0> IF
      0 DO \ addr1 addr2 f
        DROP
        2DUP
        I CHARS + C@
        SWAP
        I CHARS + C@
        = NOT
        IF
          FALSE
          LEAVE
        ELSE
          TRUE
        THEN
      LOOP
    ELSE
      DROP \ zero-length strings are trivially equal
    THEN
    -ROT
    2DROP
  ELSE
    3DROP
    FALSE
  THEN
;

S" " S" " S= NOT ABORT" Sanity check failed"

: TEST[ ( -- , Begin a postponed block )
  ." BEGINNING TEST BLOCK " CR
  s" ]TEST" SAVE-STR
  BEGIN
    PEEK-INPUT
    2DUP ." '" TYPE ." ' SEEN (LEN " DUP . ." )" CR
    2OVER
    S= NOT
  WHILE
    BL PARSE
    2DROP
  REPEAT
  2DROP
; IMMEDIATE

: ]TEST ( -- , End a postponed block )
  ( Just a marker! )
;


\ Known issue: This form can't be used across lines. I'm not sure how to drop
\ the carriage return character from the TIB. See test_postpone.fth for a test
\ case that triggers this condition.
\ TODO This doesn't seem to work; I get segfaults when calling a word which
\ contains one of these blocks.
: P[ ( -- , Begin a postponed block. Must end on the same line with ]P. )
  ." BEGINNING POSTPONE BLOCK " CR
  s" ]P" SAVE-STR \ addr u
  BEGIN
    PEEK-INPUT  \ addr u addr' u'
    2DUP ." '" TYPE ." ' SEEN (" DUP . ." CHARS)" CR
    2OVER  \ addr u addr' u' addr u
    S= NOT
  WHILE
    PEEK-INPUT \ TODO This is a heavy-handed way to see if the input is empty.
    SWAP DROP 0= ABORT" P[: Reached end of line before delimiter"
    POSTPONE POSTPONE
  REPEAT
  2DROP
; IMMEDIATE

: ]P ( -- , End a postponed block )
  ( Just a marker! )
;

\ Shorthand for postpone which makes it easier to write lambdas.
: | POSTPONE POSTPONE ; IMMEDIATE

: L | LITERAL ; IMMEDIATE
