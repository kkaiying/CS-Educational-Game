extends SceneTree

# L3 (one sticker on the goal) vs L4 (the same, plus the progress bonus), at the same settings.
# Looking for settings where L3 reliably fails and L4 reliably passes.
const ALPHAS := [0.5, 0.3, 0.1]
const EPISODE_COUNTS := [50, 100, 200, 300, 500, 1000]
const RUNS := 20
const SHORTEST_ROUTE := 18
const RUNS_PATH := "res://results/level_3_4.csv"
const SUMMARY_PATH := "res://results/level_3_4_summary.csv"

func _init():
    var run_lines: Array[String] = ["alpha,episodes,level,run,route_length,reached_finish,shortest,stuck_reason,train_ms,route"]
    var summary_lines: Array[String] = ["alpha,episodes,level,runs,reached_finish,shortest,stuck_gave_up,stuck_reward_hacking,avg_route_length,avg_train_ms"]

    print("alpha  episodes  L3 reached  L4 reached  L4 shortest")
    for alpha in ALPHAS:
        for episodes in EPISODE_COUNTS:
            var reached_by_level := {}
            var shortest_by_level := {}

            for level in [3, 4]:
                var reached_count := 0
                var shortest_count := 0
                var gave_up_count := 0
                var hacking_count := 0
                var total_length := 0
                var total_ms := 0.0

                for run in range(RUNS):
                    seed(run)
                    var result := run_once(level, alpha, episodes)
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
                    run_lines.append("%.2f,%d,%d,%d,%d,%s,%s,%s,%.2f,\"%s\"" % [alpha, episodes, level, run, result.length, result.reached, result.shortest, result.stuck_reason, result.ms, result.route])

                reached_by_level[level] = reached_count
                shortest_by_level[level] = shortest_count
                summary_lines.append("%.2f,%d,%d,%d,%d,%d,%d,%d,%.1f,%.2f" % [alpha, episodes, level, RUNS, reached_count, shortest_count, gave_up_count, hacking_count, float(total_length) / RUNS, total_ms / RUNS])

            print("%-6.2f %-9d %2d/%d       %2d/%d       %2d/%d" % [alpha, episodes, reached_by_level[3], RUNS, reached_by_level[4], RUNS, shortest_by_level[4], RUNS])

    save_csv(RUNS_PATH, run_lines)
    save_csv(SUMMARY_PATH, summary_lines)
    quit()


# One full experiment: fresh level, one reward sticker on the goal, train, then the final run.
# Level 4 differs from Level 3 only by its settings (the progress bonus).
func run_once(level: int, alpha: float, episodes: int) -> Dictionary:
    var maze: Maze
    var settings: LevelSettings
    if level == 3:
        maze = Level3.create_maze()
        settings = Level3.create_settings()
    else:
        maze = Level4.create_maze()
        settings = Level4.create_settings()
    maze.place_reward_sticker(maze.finish, settings)

    var trainer := Trainer.new()
    trainer.maze = maze
    trainer.agent = QAgent.new()
    trainer.agent.alpha = alpha
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
