extends Node2D

var maze: Maze
var settings: LevelSettings
var route: Array = []
var selected_sticker := ""
var replay_queue: Array = []     # [name, route, moves] still to play
var anim_route: Array = []       # the route being animated right now
var anim_moves: Array = []       # the direction tried on each step of it (to show bumps)
var anim_step := 0               # which square of it robot is on
var anim_timer := 0.0
var result_text := ""            # shown once the replay finishes
const STEP_TIME := 0.05
const BUMP_TIME := 0.25          # a bump is shown slower than a normal step so it can be seen
const PAUSE_TIME := 0.8          # seconds to hold the finished route before the next one
const MOVE_STEPS := {"U": Vector2i.UP, "D": Vector2i.DOWN, "L": Vector2i.LEFT, "R": Vector2i.RIGHT}

@onready var reward_button: Button = $UI/Screen/SidePanel/RewardButton
@onready var penalty_button: Button = $UI/Screen/SidePanel/PenaltyButton
@onready var one_time_button: Button = $UI/Screen/SidePanel/OneTimeButton
@onready var patience_slider = $UI/Screen/SidePanel/SettingsPanel/PatienceSlider
@onready var step_cost_slider = $UI/Screen/SidePanel/SettingsPanel/StepCostSlider
@onready var curiosity_slider = $UI/Screen/SidePanel/SettingsPanel/CuriositySlider
@onready var bonus_checkbox: CheckBox = $UI/Screen/SidePanel/SettingsPanel/BonusCheckBox

const TILE_SPACE := 64
const TILE_SIZE := 60
const OFFSET_X := 100
const OFFSET_Y := 100

func _ready():
	match  Game.current_level:
		0:
			maze = Tutorial.create_maze()
			settings = Tutorial.create_settings()
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
	
	draw_ground()

	$UI/Screen/SidePanel/BackButton.pressed.connect(Game.go_to_home)
	$UI/Screen/SidePanel/TrainButton.pressed.connect(train)

	setup_sticker_buttons()
	setup_settings()

	if Game.current_level == 0:
		play_demo()

func _draw():
	draw_maze(maze)

	if not anim_route.is_empty():              # mid-replay: the trail so far + the robot's dot
		var points := PackedVector2Array()
		for i in range(anim_step + 1):
			points.append(grid_to_centre(anim_route[i]))
		if points.size() > 1:
			draw_polyline(points, Color.RED, 4.0)
		draw_circle(points[-1] + bump_offset(), TILE_SIZE / 3.0, Color.WHITE)
	elif route.size() > 1:                     # replay finished: the real run's route
		var points := PackedVector2Array()
		for pos in route:
			points.append(grid_to_centre(pos))
		draw_polyline(points, Color.RED, 4.0)

func draw_maze(maze: Maze) -> void:
	for x in range(maze.width):
		for y in range(maze.height):
			var pos := Vector2i(x, y)
			var colour := Color.GRAY
			var corner := Vector2(OFFSET_X + x * TILE_SPACE, OFFSET_Y + y * TILE_SPACE)

			if colour != Color.GRAY:
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

func _process(delta: float) -> void:
	if anim_route.is_empty():
		return
	anim_timer += delta
	var at_end := anim_step >= anim_route.size() - 1
	if at_end and anim_timer >= PAUSE_TIME:          # finished this route: hold it a moment, then the next one
		play_next()
	elif not at_end and anim_timer >= step_time(anim_step):
		anim_timer = 0.0
		anim_step += 1
	queue_redraw()                                   # every frame, so the bump nudge moves smoothly

func screen_to_grid(screen_pos: Vector2) -> Vector2i:
	var x := floori((screen_pos.x - OFFSET_X) / TILE_SPACE)
	var y := floori((screen_pos.y - OFFSET_Y) / TILE_SPACE)
	return Vector2i(x, y)

func train() -> void:
	# copy the player's choices into the settings (locked ones keep the level's own value)
	if "patience" in settings.unlocked:
		settings.patience = patience_slider.get_value()
	if "step_cost" in settings.unlocked:
		settings.step_cost = step_cost_slider.get_value()
	if "curiosity" in settings.unlocked:
		settings.curiosity = curiosity_slider.get_value()
	if "bonus" in settings.unlocked:
		settings.progress_bonus = bonus_checkbox.button_pressed

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

	print("Evaluation run")
	trainer.agent.epsilon = 0
	route = trainer.run_final_episode(settings.max_steps)
	result_text = get_result(trainer)
	start_replay(trainer)
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

	if route.back() != maze.finish:
		return "FAIL: ran out of steps"
	
	for star in maze.stars:
		if not star in route:
			return "FAIL: missed a star"

	return "PASS"

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
	anim_route = []                     # stop any replay that's playing
	replay_queue = []
	$UI/Screen/SidePanel/ResultLabel.text = "Place stickers, then press Train"
	update_sticker_counts()
	queue_redraw()

func setup_settings() -> void:
	patience_slider.visible = "patience" in settings.unlocked
	step_cost_slider.visible = "step_cost" in settings.unlocked
	curiosity_slider.visible = "curiosity" in settings.unlocked

	bonus_checkbox.visible = "bonus" in settings.unlocked or settings.progress_bonus
	bonus_checkbox.button_pressed = settings.progress_bonus
	bonus_checkbox.disabled = not "bonus" in settings.unlocked

func start_replay(trainer: Trainer) -> void:
	replay_queue = []
	for run in trainer.practice_routes:
		replay_queue.append(["Practice run %d" % run, trainer.practice_routes[run], trainer.practice_moves[run]])
	replay_queue.append(["Real run", route, trainer.last_moves])
	play_next()

func play_next() -> void:
	if replay_queue.is_empty():
		anim_route = []
		$UI/Screen/SidePanel/ResultLabel.text = result_text
		queue_redraw()
		return
	var next: Array = replay_queue.pop_front()
	$UI/Screen/SidePanel/ResultLabel.text = next[0]
	anim_route = next[1]
	anim_moves = next[2]
	anim_step = 0
	anim_timer = 0.0

func play_demo() -> void:
	replay_queue = []
	for run in Tutorial.demo_runs():
		var moves: Array = []
		for letter in run[1]:
			moves.append(MOVE_STEPS[letter])
		replay_queue.append([run[0], route_from_moves(run[1]), moves])
	result_text = ""
	play_next()

func route_from_moves(moves: String) -> Array:
	var pos := maze.start
	var demo_route: Array = [pos]
	for move in moves:
		if maze.can_enter(pos + MOVE_STEPS[move]):   # into a wall: bump and stay put
			pos += MOVE_STEPS[move]
		demo_route.append(pos)
	return demo_route

# a bump = the robot is on the same square as the step before
func is_bump(step: int) -> bool:
	return step > 0 and anim_route[step] == anim_route[step - 1]

# how long to show this step before moving on (bumps are slower so they can be seen)
func step_time(step: int) -> float:
	if is_bump(step):
		return BUMP_TIME
	return STEP_TIME

# while showing a bump, push the dot towards the wall it walked into and back again
func bump_offset() -> Vector2:
	if not is_bump(anim_step):
		return Vector2.ZERO
	var progress: float = clamp(anim_timer / BUMP_TIME, 0.0, 1.0)
	return Vector2(anim_moves[anim_step - 1]) * sin(progress * PI) * TILE_SIZE * 0.5

func draw_ground() -> void:
	for x in range(maze.width):
		for y in range(maze.height):
			$Ground.set_cell(Vector2i(x, y), 0, Vector2i(0, 5)) # normal grass
		$Objects.set_cell(maze.finish, 1, Vector2i(3, 0)) # harvest
		$Objects.set_cell(maze.start, 6, Vector2i(2, 5))
		for wall in maze.walls:
			$Objects.set_cell(wall, 2, Vector2i(1, 3)) # walls
		for rock in maze.thorns:
			$Objects.set_cell(rock, 3, Vector2i(0,0)) # pebbles
		for flower in maze.spikes:
			$Objects.set_cell(flower, 2, Vector2i(7, 3)) # spikes
		for crop in maze.crystals:
			$Objects.set_cell(crop, 5, Vector2i(4, 17)) # l5
		for mushroom in maze.stars:
			$Objects.set_cell(mushroom, 2, Vector2i(6, 0)) # extra rewards in l7
			
