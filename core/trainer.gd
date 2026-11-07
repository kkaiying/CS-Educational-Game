class_name Trainer

var maze: Maze
var agent: QAgent
var robot: Robot
var total_reward: float = 0.0
var stuck_reason: String = ""
var settings: LevelSettings

const STUCK_VISITS := 10

func run_one_episode(max_steps: int) -> Array:
	robot.position = maze.start
	total_reward = 0.0
	var route: Array = [maze.start]

	for i in range(max_steps):
		var old_pos := robot.position
		var dir := agent.choose_direction(old_pos)
		robot.move(dir)

		if not maze.can_enter(robot.position): # if robot is trying to exit the maze return it back to its old pos
			robot.position = old_pos

		var new_pos := robot.position
		route.append(new_pos)

		var done := maze.is_finish(new_pos)
		var reward := 0.0
		if new_pos != old_pos:                  # only claim reward if the robot actually moved, prevents farming at a wall
			reward = maze.get_reward(new_pos)
		total_reward += reward
		reward += get_bonus(old_pos, new_pos, done)

		agent.learn(old_pos, dir, reward, new_pos, done)

		if done:
			break

	return route


func train(episodes: int, max_steps: int) -> void:
	for e in range (episodes):
		run_one_episode(max_steps)

func run_final_episode(max_steps: int) -> Array:
	robot.position = maze.start
	total_reward = 0.0
	stuck_reason = ""
	var route: Array = [maze.start]

	var visits := {maze.start : 1}
	var reward_at_first_visit := {maze.start: 0.0}

	for i in range(max_steps):
		var old_pos := robot.position
		var dir := agent.choose_direction(old_pos)
		robot.move(dir)

		if not maze.can_enter(robot.position):
			robot.position = old_pos

		var new_pos := robot.position
		route.append(new_pos)

		if new_pos != old_pos:
			total_reward += maze.get_reward(new_pos)

		if maze.is_finish(new_pos):
			break

		visits[new_pos] = visits.get(new_pos, 0) + 1
		if visits[new_pos] == 1:
			reward_at_first_visit[new_pos] = total_reward

		if visits[new_pos] >= STUCK_VISITS:
			if total_reward > reward_at_first_visit[new_pos]:
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
