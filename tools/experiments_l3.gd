extends SceneTree

const EPISODE_COUNTS := [200, 500, 1000, 2000, 5000, 10000]
const RUNS := 20
const SHORTEST_ROUTE := 18
const RUNS_PATH := "res://results/level_3.csv"
const SUMMARY_PATH := "res://results/level_3_summary.csv"

func _init():
    var run_lines: Array[String] = ["episodes,run,route_length,reached_finish,shortest,stuck_reason,train_ms,route"]
    var summary_lines: Array[String] = ["episodes,runs,reached_finish,shortest,stuck_gave_up,stuck_reward_hacking,avg_route_length,avg_train_ms"]

    print("episodes  reached  shortest  gave_up  hacking  avg_length  avg_ms")
    for episodes in EPISODE_COUNTS:
        var reached_count := 0
        var shortest_count := 0
        var gave_up_count := 0
        var hacking_count := 0
        var total_length := 0
        var total_ms := 0.0

        for run in range(RUNS):
            seed(run)
            var result := run_once(episodes)
            if result.reached:
                reached_count += 1
            if result.shortest:
                shortest_count += 1
            if result.stuck_reason == "gave_up":
                gave_up_count += 1
            if result.stuck_reason == "reward_hacking":
                hacking_count += 1
            total_length += result.length
            total_ms += result.ms
            run_lines.append("%d,%d,%d,%s,%s,%s,%.2f,\"%s\"" % [episodes, run, result.length, result.reached, result.shortest, result.stuck_reason, result.ms, result.route])

        var avg_length := float(total_length) / RUNS
        var avg_ms := total_ms / RUNS
        summary_lines.append("%d,%d,%d,%d,%d,%d,%.1f,%.2f" % [episodes, RUNS, reached_count, shortest_count, gave_up_count, hacking_count, avg_length, avg_ms])
        print("%-9d %2d/%d    %2d/%d     %2d       %2d       %-10.1f  %.2f" % [episodes, reached_count, RUNS, shortest_count, RUNS, gave_up_count, hacking_count, avg_length, avg_ms])

    save_csv(RUNS_PATH, run_lines)
    save_csv(SUMMARY_PATH, summary_lines)
    quit()


# One full experiment: fresh level, one reward sticker on the goal (sparse), train, then the final run.
func run_once(episodes: int) -> Dictionary:
    var maze := Level3.create_maze()
    var settings := Level3.create_settings()
    maze.place_reward_sticker(maze.finish, settings)

    var trainer := Trainer.new()
    trainer.maze = maze
    trainer.agent = QAgent.new()
    trainer.robot = Robot.new()
    trainer.settings = settings

    var start_time := Time.get_ticks_usec()
    trainer.train(episodes, settings.max_steps)
    var ms := (Time.get_ticks_usec() - start_time) / 1000.0

    trainer.agent.epsilon = 0
    var route := trainer.run_final_episode(settings.max_steps)
    var length := route.size() - 1
    var reached: bool = route.back() == maze.finish

    return {
        "length": length,
        "reached": reached,
        "shortest": reached and length == SHORTEST_ROUTE,
        "stuck_reason": trainer.stuck_reason,
        "ms": ms,
        "route": route_to_text(route),
    }


# e.g. "(1,6) > (1,5) > (2,5)"
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
