extends SceneTree

const CASES := ["reward_only", "reward_and_penalties", "reward_misplaced", "reward_on_spike", "penalties_row_4_only", "penalty_wall"]
const RUNS := 20
const RUNS_PATH := "res://results/level_2.csv"
const SUMMARY_PATH := "res://results/level_2_summary.csv"

func _init():
    var run_lines: Array[String] = ["case,run,route_length,reached_finish,touched_spike,total_reward,train_ms,route"]
    var summary_lines: Array[String] = ["case,runs,reached_finish,avoided_spikes,avg_route_length,avg_total_reward,avg_train_ms"]

    print("case                  reached  avoided  avg_length  avg_reward  avg_ms")
    for case_name in CASES:
        var reached_count := 0
        var avoided_count := 0
        var total_length := 0
        var sum_reward := 0.0
        var total_ms := 0.0

        for run in range(RUNS):
            seed(run)
            var result := run_once(case_name)
            if result.reached:
                reached_count += 1
            if not result.touched_spike:
                avoided_count += 1
            total_length += result.length
            sum_reward += result.total_reward
            total_ms += result.ms
            run_lines.append("%s,%d,%d,%s,%s,%.1f,%.2f,\"%s\"" % [case_name, run, result.length, result.reached, result.touched_spike, result.total_reward, result.ms, result.route])

        var avg_length := float(total_length) / RUNS
        var avg_reward := sum_reward / RUNS
        var avg_ms := total_ms / RUNS
        summary_lines.append("%s,%d,%d,%d,%.1f,%.1f,%.2f" % [case_name, RUNS, reached_count, avoided_count, avg_length, avg_reward, avg_ms])
        print("%-21s %2d/%d    %2d/%d    %-10.1f  %-10.1f  %.2f" % [case_name, reached_count, RUNS, avoided_count, RUNS, avg_length, avg_reward, avg_ms])

    save_csv(RUNS_PATH, run_lines)
    save_csv(SUMMARY_PATH, summary_lines)
    quit()


# One full experiment: fresh level, place stickers for this case, train, then a test run with no random moves
func run_once(case_name: String) -> Dictionary:
    var maze := Level2.create_maze()
    var settings := Level2.create_settings()

    match case_name:
        "reward_only":
            maze.place_reward_sticker(maze.finish, settings)
        "reward_and_penalties":
            maze.place_reward_sticker(maze.finish, settings)
            for spike in maze.spikes:
                maze.place_penalty_sticker(spike, settings)
        "reward_misplaced":
            maze.place_reward_sticker(Vector2i(1,5), settings)
        "reward_on_spike":
            maze.place_reward_sticker(Vector2i(1,4), settings)
        "penalties_row_4_only":
            maze.place_reward_sticker(maze.finish, settings)
            maze.place_penalty_sticker(Vector2i(0,4), settings)
            maze.place_penalty_sticker(Vector2i(1,4), settings)
        "penalty_wall":
            maze.place_reward_sticker(maze.finish, settings)
            for x in range(maze.width):
                maze.place_penalty_sticker(Vector2i(x,3), settings)

    var trainer := Trainer.new()
    trainer.maze = maze
    trainer.agent = QAgent.new()
    trainer.robot = Robot.new()

    var start_time := Time.get_ticks_usec()
    trainer.train(settings.episodes, settings.max_steps)
    var ms := (Time.get_ticks_usec() - start_time) / 1000.0

    trainer.agent.epsilon = 0
    var route := trainer.run_one_episode(settings.max_steps)

    var touched_spike := false
    for pos in route:
        if pos in maze.spikes:
            touched_spike = true

    return {
        "length": route.size() - 1,
        "reached": route.back() == maze.finish,
        "touched_spike": touched_spike,
        "total_reward": trainer.total_reward,
        "ms": ms,
        "route": route_to_text(route),
    }

func route_to_text(route: Array) -> String:
    var parts: Array[String] = []
    for pos in route:
        parts.append("(%d,%d)" % [pos.x, pos.y])
    return " > ".join(parts)


func save_csv(path: String, lines: Array[String]) -> void:
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string("\n".join(lines) + "\n")
    print("saved ", path)
