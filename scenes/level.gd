extends Node2D

var maze: Maze
var settings: LevelSettings
var route: Array = []
var selected_sticker := ""

@onready var reward_button: Button = $UI/Screen/SidePanel/RewardButton
@onready var penalty_button: Button = $UI/Screen/SidePanel/PenaltyButton
@onready var one_time_button: Button = $UI/Screen/SidePanel/OneTimeButton

const TILE_SPACE := 64
const TILE_SIZE := 60
const OFFSET_X := 100
const OFFSET_Y := 100

func _ready():
	match  Game.current_level:
		1:
			maze = Level1.create_maze()
			settings = Level1.create_settings()
		2: 
			maze = Level2.create_maze()
			settings = Level2.create_settings()
		3: 
			maze = Level3.create_maze()
			settings = Level3.create_settings()
		4: 
			maze = Level4.create_maze()
			settings = Level4.create_settings()
		5:
			maze = Level5.create_maze()
			settings = Level5.create_settings()
		6: 
			maze = Level6.create_maze()
			settings = Level6.create_settings()
		7:
			maze = Level7.create_maze()
			settings = Level7.create_settings()

	$UI/Screen/SidePanel/BackButton.pressed.connect(Game.go_to_home)
	$UI/Screen/SidePanel/TrainButton.pressed.connect(train)

	setup_sticker_buttons()

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
			elif maze.crystals.has(pos):
				colour = Color.CYAN
			elif pos in maze.stars:
				colour = Color.PURPLE
			elif maze.is_finish(pos):
				colour = Color.GOLD
			elif pos in maze.spikes:
				colour = Color.DARK_RED
			elif maze.thorns.has(pos):
				colour = Color.DARK_GREEN
			elif pos in maze.walls:
				colour = Color.BLACK
			var corner := Vector2(OFFSET_X + x * TILE_SPACE, OFFSET_Y + y * TILE_SPACE)
			draw_rect(Rect2(OFFSET_X + x * TILE_SPACE, OFFSET_Y + y * TILE_SPACE, TILE_SIZE, TILE_SIZE), colour)

			if maze.stickers.has(pos):
				var centre := corner + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
				var sticker_colour := Color.BLUE
				if maze.stickers[pos] < 0:
					sticker_colour = Color.ORANGE
				draw_circle(centre, TILE_SIZE / 4.0, sticker_colour)
			if maze.one_time_stickers.has(pos):
				var centre := corner + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
				draw_circle(centre, TILE_SIZE / 4.0, Color.WHITE)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
			var grid_pos := screen_to_grid(get_local_mouse_position())
			if event.button_index == MOUSE_BUTTON_LEFT:
				place_selected_sticker(grid_pos)
			elif event.button_index == MOUSE_BUTTON_RIGHT:     # right click removes whatever sticker is there
				maze.stickers.erase(grid_pos)
				maze.one_time_stickers.erase(grid_pos)
			stickers_changed()

func screen_to_grid(screen_pos: Vector2) -> Vector2i:
	var x := floori((screen_pos.x - OFFSET_X) / TILE_SPACE)
	var y := floori((screen_pos.y - OFFSET_Y) / TILE_SPACE)
	return Vector2i(x, y)

func train() -> void:
	var trainer := Trainer.new()
	trainer.maze = maze
	trainer.agent = QAgent.new()
	trainer.agent.gamma = settings.patience
	trainer.agent.epsilon = settings.curiosity
	trainer.robot = Robot.new()
	trainer.settings = settings

	print("Training start")
	var start_time := Time.get_ticks_msec()
	trainer.train(settings.episodes, settings.max_steps)
	print("Training complete in ", Time.get_ticks_msec() - start_time, "ms")

	print ("Evaluation run")
	trainer.agent.epsilon = 0
	route = trainer.run_final_episode(settings.max_steps)
	$UI/Screen/SidePanel/ResultLabel.text = get_result(trainer)
	print(get_result(trainer))
	print("Total reward: ", trainer.total_reward)
	print("Stuck: ", trainer.stuck_reason)
	queue_redraw()

func grid_to_centre(pos: Vector2i) -> Vector2:
	return Vector2(OFFSET_X + pos.x * TILE_SPACE + TILE_SIZE / 2.0, OFFSET_Y + pos.y * TILE_SPACE + TILE_SIZE / 2.0)

func get_result(trainer: Trainer) -> String:
	if trainer.stuck_reason != "":
		return "FAIL: stuck (" + trainer.stuck_reason + ")"

	for pos in route:
		if pos in maze.spikes:
			return "FAIL: hit spikes"

	if maze.crystals.has(route.back()):
		return "FAIL: took the crystal"

	if route.back() == maze.finish:
		return "PASS"

	return "FAIL: ran out of steps"

func setup_sticker_buttons() -> void:
	var group := ButtonGroup.new()
	for button in [reward_button, penalty_button, one_time_button]:
		button.toggle_mode = true
		button.button_group = group

	reward_button.pressed.connect(func(): selected_sticker = "reward")
	penalty_button.pressed.connect(func(): selected_sticker = "penalty")
	one_time_button.pressed.connect(func(): selected_sticker = "one_time")
	$UI/Screen/SidePanel/ClearButton.pressed.connect(clear_stickers)

	# hide sticker types that the level doesn't allow
	reward_button.visible = settings.max_reward_stickers > 0
	penalty_button.visible = settings.max_penalty_stickers > 0
	one_time_button.visible = settings.max_one_time_stickers > 0

	update_sticker_counts()

func update_sticker_counts() -> void:
	var rewards := 0
	var penalties := 0
	for value in maze.stickers.values():
		if value > 0:
			rewards += 1
		else:
			penalties += 1
	reward_button.text = "Reward (%d left)" % (settings.max_reward_stickers - rewards)
	penalty_button.text = "Penalty (%d left)" % (settings.max_penalty_stickers - penalties)
	one_time_button.text = "One-time (%d left)" % (settings.max_one_time_stickers - maze.one_time_stickers.size())

func place_selected_sticker(grid_pos: Vector2i) -> void:
	match selected_sticker:
		"reward":
			maze.place_reward_sticker(grid_pos, settings)
		"penalty":
			maze.place_penalty_sticker(grid_pos, settings)
		"one_time":
			maze.place_one_time_sticker(grid_pos, settings)

func clear_stickers() -> void:
	maze.stickers.clear()
	maze.one_time_stickers.clear()
	stickers_changed()

# after any sticker change the old route no longer matches so hide it
func stickers_changed() -> void:
	route = []
	$UI/Screen/SidePanel/ResultLabel.text = "Place stickers, then press Train"
	update_sticker_counts()
	queue_redraw()
