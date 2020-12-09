draw_buf clear blit

50 50 100 100 vec.rect
150 150 250 250 vec.rect
2 vec.group

constant test_group

blue test_group vec.draw

50 50 test_group vec.translate

red 127 opacity test_group vec.draw

-40 0 test_group vec.translate

2 test_group vec.zoom

green 127 opacity test_group vec.draw

blit disp.render
