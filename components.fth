\ Component library.

\ Resistors

\ SMT resistors have two pads, which are applied only to a single copper
\ layer. The pad dimensions are given as a set of three values specifying the
\ height, width, and gap:
\  v-v width (b)
\  [ ]  [ ] } height (a)
\    ^--^ gap (c)
\
\ | Imperial Code | Metric Code | a (mm) | b (mm) | c (mm) |
\ | ------------- | ----------- | ------ | ------ | ------ |
\ |      0201     |     0603    | 0.3    | 0.3    | 0.3    |
\ |      0402     |     1005    | 0.6    | 0.5    | 0.5    |
\ |      0603     |     1608    | 0.9    | 0.6    | 0.9    |
\ |      0805     |     2012    | 1.3    | 0.7    | 1.2    |
\ |      1206     |     3216    | 1.6    | 0.9    | 2.0    |
\ |      1812     |     3246    | 4.8    | 0.9    | 2.0    |
\ |      2010     |     5025    | 2.8    | 0.9    | 3.8    |
\ |      2512     |     6332    | 3.5    | 1.6    | 3.8    |
\
\ Commonly the imperial code is used to specify the part number, but the metric
\ measurements are used. (It's confusing.) Here we will follow the convention of
\ prefixing each part word with an I for imperial or M for metric; the imperial
\ word is an alias for the metric one.

: SMT_RESISTOR.DRAW_PADS { x y a b c -- addr }
  \ Left pad
  0 0 b a VEC.RECT

  \ Right pad: x is offset from the left pad by the gap size
  b c +
  0
  b c b + +
  a
  VEC.RECT

  2 VEC.GROUP
  \ Translate pads to the right overall position
  DUP x y ROT VEC.TRANSLATE
;

: SMT_RESISTOR.DRAW_LAYER { lyr x y a b c -- addr }
  FALSE
  lyr
  CASE
    TOP_COPPER_LAYER OF
      DROP
      x y a b c SMT_RESISTOR.DRAW_PADS
      TRUE
    ENDOF
    TOP_MASK_LAYER OF
      DROP
      x y a b c SMT_RESISTOR.DRAW_PADS
      POL.SUB OVER S! VEC.POL
      TRUE
    ENDOF
  ENDCASE
  NOT IF
    VEC.NONE
  THEN
;

\ Create xt which draws an SMT resistor with the given location and
\ dimensions. The pads are arranged horizontally.
: SMT_RESISTOR.DRAW { x y a b c -- addr }
  :NONAME ( l -- vaddr )
    x | LITERAL
    y | LITERAL
    a | LITERAL
    b | LITERAL
    c | LITERAL
    | SMT_RESISTOR.DRAW_LAYER
    | ; \ caddr xt
;

: M0603 ( x y -- , Define a metric 0603 resistor )
  COMPONENT.CREATE -ROT
  300 UM 300 UM 300 UM SMT_RESISTOR.DRAW
  OVER S! COMPONENT.DRAW
;

: M1005
  COMPONENT.CREATE -ROT
  600 UM 500 UM 500 UM SMT_RESISTOR.DRAW
  OVER S! COMPONENT.DRAW
;

: M1608
  COMPONENT.CREATE -ROT
  900 UM 600 UM 900 UM SMT_RESISTOR.DRAW
  OVER S! COMPONENT.DRAW
;

: M2012
  COMPONENT.CREATE -ROT
  1300 UM 700 UM 1200 UM SMT_RESISTOR.DRAW
  OVER S! COMPONENT.DRAW
;

: M3216
  COMPONENT.CREATE -ROT
  1600 UM 900 UM 2000 UM SMT_RESISTOR.DRAW
  OVER S! COMPONENT.DRAW
;

: M3246
  COMPONENT.CREATE -ROT
  4800 UM 900 UM 2000 UM SMT_RESISTOR.DRAW
  OVER S! COMPONENT.DRAW
;

: M5025
  COMPONENT.CREATE -ROT
  2800 UM 900 UM 3800 UM SMT_RESISTOR.DRAW
  OVER S! COMPONENT.DRAW
;

: M6332
  COMPONENT.CREATE -ROT
  3500 UM 1600 UM 3800 UM SMT_RESISTOR.DRAW
  OVER S! COMPONENT.DRAW
;

\ Imperial aliases
: I0201 M0603 ;
: I0402 M1005 ;
: I0603 M1608 ;
: I0805 M2012 ;
: I1206 M3216 ;
: I1812 M3246 ;
: I2010 M5025 ;
: I2512 M6332 ;
