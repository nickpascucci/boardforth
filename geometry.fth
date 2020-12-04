\ Geometry manipulation routines.

: REFLECT_Y ( x y -- x y' , Reflect a coordinate pair over the Y axis )
  -1 *
;

: REFLECT_X ( x y -- x' y , Reflect a coordinate pair over the X axis )
 SWAP -1 * SWAP
;

: TRANSLATE_Y ( x y n -- x y' , Translate a coordinate pair along the Y axis )
  +
;

: TRANSLATE_X ( x y n -- x' y , Translate a coordinate pair along the X axis )
  ROT + SWAP
;

: TRANSLATE ( x y nx ny -- x' y' , Translate a coordinate pair )
  ROT +
  -ROT +
  SWAP
;
