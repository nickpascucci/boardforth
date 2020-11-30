board b
b current_board !
2 layers
30 40 rectangular

\ Case 1: Render to board layer
\ Create a vector representation of the board
board_layer \ Vector layer to render to
b S@ board.first_part S@ component.draw execute

\ Check that the coordinates line up
dup S@ vec.x1 dup . 0= not abort" X1 coordinate does not equal 0!"
dup S@ vec.y1 dup . 0= not abort" Y1 coordinate does not equal 0!"
dup S@ vec.x2 dup . 30 = not abort" X2 coordinate does not equal 30!"
dup S@ vec.y2 dup . 40 = not abort" Y2 coordinate does not equal 40!"
dup S@ vec.type dup . shape.rect = not abort" Board shape does not equal SHAPE.RECT!"
dup S@ vec.polarity dup . pol.add = not abort" Board polarity does not equal POL.ADD!"

drop \ Forget vector

\ Case 2: Render to non-board layer
\ Create a vector representation of the board
top_copper_layer \ Vector layer to render to
b S@ board.first_part S@ component.draw execute

\ Check that the coordinates line up
dup S@ vec.x1 dup . 0= not abort" X1 coordinate does not equal 0!"
dup S@ vec.y1 dup . 0= not abort" Y1 coordinate does not equal 0!"
dup S@ vec.x2 dup . 0= not abort" X2 coordinate does not equal 0!"
dup S@ vec.y2 dup . 0= not abort" Y2 coordinate does not equal 0!"
dup S@ vec.type dup . shape.none = not abort" Board shape does not equal SHAPE.NONE!"
dup S@ vec.polarity dup . pol.add = not abort" Board polarity does not equal POL.ADD!"

drop \ Forget vector
