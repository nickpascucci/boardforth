50 50 100 100 vec.rect
150 150 250 250 vec.rect
2 vec.group

constant test_group

blue test_group vec.draw blit disp.render

50 50 test_group vec.translate

red test_group vec.draw blit disp.render

2 test_group vec.zoom

green test_group vec.draw blit disp.render
