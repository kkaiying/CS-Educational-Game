extends Node2D

var maze: Maze
var settings: LevelSettings
var route: Array = []

const TILE_SPACE := 64
const TILE_SIZE := 60
const OFFSET_X := 100
const OFFSET_Y := 100
const LEVEL := 2

func _ready():
	match LEVEL:
		1:
			maze = Level1.create_maze()
			settings = Level1.create_settings()
		2: 
			maze = Level2.create_maze()
			settings = Level2.create_settings()

func _draw():
	draw_maze(maze)

	if route.size() > 1:
				var points := PackedVector2Array()
				for pos in route:
					points.append(grid_to_centre(pos))
				draw_polyline(points, Color.RED,4.0)

func draw_maze(maze: Maze) -> void:
	for x in range(maze.width):
		for y in range(maze.height):
			var pos := Vector2i(x, y)
			var colour := Color.GRAY
			if pos == maze.start:
				colour = Color.GREEN
			elif maze.is_finish(pos):
				colour = Color.GOLD
			elif pos in maze.spikes:
				colour = Color.DARK_RED
			var corner := Vector2(OFFSET_X + x * TILE_SPACE, OFFSET_Y + y * TILE_SPACE)
			draw_rect(Rect2(OFFSET_X + x * TILE_SPACE, OFFSET_Y + y * TILE_SPACE, TILE_SIZE, TILE_SIZE), colour)

			if maze.stickers.has(pos):
				var centre := corner + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
				var sticker_colour := Color.BLUE
				if maze.stickers[pos] < 0:
					sticker_colour = Color.ORANGE
				draw_circle(centre, TILE_SIZE / 4.0, sticker_colour)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var grid_pos := screen_to_grid(get_local_mouse_position())
		if maze.place_reward_sticker(grid_pos, settings):
			queue_redraw()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var grid_pos := screen_to_grid(get_local_mouse_position())
		if maze.place_penalty_sticker(grid_pos, settings):
			queue_redraw()

	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		train()

func screen_to_grid(screen_pos: Vector2) -> Vector2i:
	var x := floori((screen_pos.x - OFFSET_X) / TILE_SPACE)
	var y := floori((screen_pos.y - OFFSET_Y) / TILE_SPACE)
	return Vector2i(x, y)

func train() -> void:
	var trainer := Trainer.new()
	trainer.maze = maze
	trainer.agent = QAgent.new()
	trainer.robot = Robot.new()

	print("Training start")
	var start_time := Time.get_ticks_msec()
	trainer.train(settings.episodes, settings.max_steps)
	print("Training complete in ", Time.get_ticks_msec() - start_time, "ms")

	print ("Evaluation run")
	trainer.agent.epsilon = 0
	route = trainer.run_final_episode(settings.max_steps)
	print("Total reward: ", trainer.total_reward)
	print("Stuck: ", trainer.stuck_reason)
	queue_redraw()

func grid_to_centre(pos: Vector2i) -> Vector2:
	return Vector2(OFFSET_X + pos.x * TILE_SPACE + TILE_SIZE / 2.0, OFFSET_Y + pos.y * TILE_SPACE + TILE_SIZE / 2.0)
