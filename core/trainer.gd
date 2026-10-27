class_name Trainer

var maze: Maze
var agent: QAgent
var robot: Robot
var total_reward: float = 0.0

func run_one_episode(max_steps: int) -> Array:
    robot.position = maze.start
    total_reward = 0.0
    var route: Array = [maze.start]

    for i in range(max_steps):
        var old_pos := robot.position
        var dir := agent.choose_direction(old_pos)
        robot.move(dir)

        if not maze.is_inside(robot.position): # if robot is trying to exit the maze return it back to its old pos
            robot.position = old_pos

        var new_pos := robot.position
        route.append(new_pos)

        var done := maze.is_finish(new_pos)
        var reward := 0.0
        if new_pos != old_pos:                  # only claim reward if the robot actually moved, prevents farming at a wall
            reward = maze.get_reward(new_pos)
        total_reward += reward

        agent.learn(old_pos, dir, reward, new_pos, done)

        if done:
            break

    return route


func train(episodes: int, max_steps: int) -> void:
    for e in range (episodes):
        run_one_episode(max_steps)