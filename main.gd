extends Node2D

const TILE_SPACE := 64
const TILE_SIZE := 60
const OFFSET_X := 100
const OFFSET_Y := 100

func _draw():
	for i in range(6):
		var x = OFFSET_X + i * TILE_SPACE
		draw_rect(Rect2(x, OFFSET_Y, TILE_SIZE, TILE_SIZE), Color.BLUE)
