\ Units of measure.

\ BoardForth's internal representation nominally uses millimeters, in
\ conformance with The Gerber File Format Specification. In order to represent
\ the 6 decimal places required by the spec in a fixed-point format, the actual
\ representation is in nanometers.
\
\ Inches are not supported, here or in the Gerber format:
\ "Inch is only there for historic reasons and is now a useless
\ embellishment. It will be revoked at some future date."

: NM ( n -- n , Convert a value in nanometers to internal representation )
  \ noop
;

: UM ( n -- n , Convert a value in whole micrometers to internal representation )
  1000 *
;

: MM ( n -- n , Convert a value in whole millimeters to internal representation )
  UM 1000 *
;

: >NM ( n -- n , Convert a value in internal representation to nanometers )
  \ noop
;

: >UM ( n -- n , Convert a value in internal representation to whole micrometers )
  1000 /
;

: >MM ( n -- n , Convert a value in internal representation to whole millimeters )
  UM 1000 /
;

