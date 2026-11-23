class_name Trainer

var maze: Maze
var agent: QAgent
var robot: Robot
var total_reward: float = 0.0
var stuck_reason: String = ""
var settings: LevelSettings
var practice_routes: Dictionary = {}
var practice_moves: Dictionary = {}     # practice run number → its moves, kept for the replay
var last_moves: Array = []              # the direction tried on each step of the latest run, so the replay can show bumps

const STUCK_VISITS := 10

func run_one_episode(max_steps: int) -> Array:
	robot.position = maze.start
	total_reward = 0.0
	var collected := 0                      # every one-time sticker is back at the start of a run
	var route: Array = [maze.start]
	last_moves = []

	for i in range(max_steps):
		var old_pos := robot.position
		var old_state := Vector3i(old_pos.x, old_pos.y, collected)
		var dir := agent.choose_direction(old_state)
		robot.move(dir)
		last_moves.append(robot.position - old_pos)    # the direction it tried, even if it bumps

		if not maze.can_enter(robot.position): # if robot is trying to exit the maze return it back to its old pos
			robot.position = old_pos

		var new_pos := robot.position
		route.append(new_pos)

		var done := maze.is_finish(new_pos)
		var reward := -settings.step_cost
		if new_pos != old_pos:                  # only claim reward if the robot actually moved, prevents farming at a wall
			reward += maze.get_reward(new_pos)
			var bit := one_time_bit(new_pos)
			if bit != 0 and (collected & bit) == 0:    # a one-time sticker it hasn't collected yet
				reward += maze.one_time_stickers[new_pos]
				collected |= bit
		total_reward += reward
		reward += get_bonus(old_pos, new_pos, done)

		var new_state := Vector3i(new_pos.x, new_pos.y, collected)
		agent.learn(old_state, dir, reward, new_state, done)

		if done:
			break

	return route


func train(episodes: int, max_steps: int) -> void:
	var keep := []
	for e in range(1, episodes + 1):
		var practice_route := run_one_episode(max_steps)
		if e in keep:
			practice_routes[e] = practice_route
			practice_moves[e] = last_moves

func run_final_episode(max_steps: int) -> Array:
	robot.position = maze.start
	total_reward = 0.0
	stuck_reason = ""
	var collected := 0
	var route: Array = [maze.start]

	var start_state := Vector3i(maze.start.x, maze.start.y, 0)
	var visits := {start_state: 1}          # counted per state, so passing a square again after collecting isn't "stuck"
	var reward_at_first_visit := {start_state: 0.0}
	last_moves = []

	for i in range(max_steps):
		var old_pos := robot.position
		var dir := agent.choose_direction(Vector3i(old_pos.x, old_pos.y, collected))
		robot.move(dir)
		last_moves.append(robot.position - old_pos)

		if not maze.can_enter(robot.position):
			robot.position = old_pos

		var new_pos := robot.position
		route.append(new_pos)

		total_reward -= settings.step_cost
		if new_pos != old_pos:
			total_reward += maze.get_reward(new_pos)
			var bit := one_time_bit(new_pos)
			if bit != 0 and (collected & bit) == 0:
				total_reward += maze.one_time_stickers[new_pos]
				collected |= bit

		if maze.is_finish(new_pos):
			break

		var state := Vector3i(new_pos.x, new_pos.y, collected)
		visits[state] = visits.get(state, 0) + 1
		if visits[state] == 1:
			reward_at_first_visit[state] = total_reward

		if visits[state] >= STUCK_VISITS:
			if total_reward > reward_at_first_visit[state]:
				stuck_reason = "reward_hacking"
			else:
				stuck_reason = "gave_up"
			break
	return route

# walking distance to goal (BFS, around walls)
func distance_to_goal(pos: Vector2i) -> int:
	return maze.walking_distance(pos)

# potential = what the goal reward is worth from this square, highest next to the goal
func get_bonus(old_pos: Vector2i, new_pos: Vector2i, done: bool) -> float:
	if not settings.progress_bonus:
		return 0.0
	var old_potential := settings.reward_sticker_value * pow(agent.gamma, distance_to_goal(old_pos) - 1)
	var new_potential := 0.0                # run ends here so nothing comes after (otherwise the bonus secretly rewards the goal)
	if not done:
		new_potential = settings.reward_sticker_value * pow(agent.gamma, distance_to_goal(new_pos) - 1)
	return agent.gamma * new_potential - old_potential

# the bit for this square's one-time sticker in "collected" (0 if there isn't one)
func one_time_bit(pos: Vector2i) -> int:
	var index := maze.one_time_stickers.keys().find(pos)
	if index == -1:
		return 0
	return 1 << index
