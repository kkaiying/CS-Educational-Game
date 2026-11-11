extends SceneTree

# Tries each level's unlocked settings together, with the intended stickers placed,
# to check that no other setting solves a level the wrong way.
const RUNS := 20
const EPISODES := 500
const PATIENCE := [0.5, 0.7, 0.9, 0.95, 0.99]
const STEP_COST := [0.0, 0.5, 1.0, 2.0, 5.0, 10.0]
const CURIOSITY := [0.05, 0.1, 0.3, 0.5, 0.7, 0.9]
const OUTCOMES := ["PASS", "stuck_gave_up", "stuck_reward_hacking", "spike", "crystal", "missed_star", "out_of_steps"]
const PATH := "res://results/settings_combos.csv"

var lines: Array[String] = ["level,bonus,patience,step_cost,curiosity,runs," + ",".join(OUTCOMES)]

func _init():
    print("level bonus patience step_cost curiosity | " + " ".join(OUTCOMES))

    # L5: bonus (locked on in the game, off shown for comparison) x patience
    for bonus in [true, false]:
        for patience in PATIENCE:
            test(5, bonus, patience, 0.0, 0.1)

    # L6: bonus x patience x step cost
    for bonus in [false, true]:
        for patience in PATIENCE:
            for step_cost in STEP_COST:
                test(6, bonus, patience, step_cost, 0.1)

    # L7: curiosity x each earlier setting changed on its own
    for curiosity in CURIOSITY:
        for bonus in [false, true]:
            test(7, bonus, 0.9, 0.0, curiosity)
        for patience in PATIENCE:
            if patience != 0.9:
                test(7, false, patience, 0.0, curiosity)
        for step_cost in STEP_COST:
            if step_cost != 0.0:
                test(7, false, 0.9, step_cost, curiosity)

    save_csv()
    quit()


func test(level: int, bonus: bool, patience: float, step_cost: float, curiosity: float) -> void:
    var counts := {}
    for run in range(RUNS):
        seed(run)
        var result := run_once(level, bonus, patience, step_cost, curiosity)
        counts[result] = counts.get(result, 0) + 1

    var line := "%d,%s,%.2f,%.1f,%.2f,%d" % [level, bonus, patience, step_cost, curiosity, RUNS]
    var shown: Array[String] = []
    for outcome in OUTCOMES:
        line += ",%d" % counts.get(outcome, 0)
        if counts.has(outcome):
            shown.append("%s %d" % [outcome, counts[outcome]])
    lines.append(line)
    print("L%d bonus=%-5s patience=%.2f step_cost=%-4.1f curiosity=%.2f | %s" % [level, bonus, patience, step_cost, curiosity, ", ".join(shown)])


# One run: fresh level, the intended stickers, these settings, train, then the final run.
func run_once(level: int, bonus: bool, patience: float, step_cost: float, curiosity: float) -> String:
    var maze: Maze
    var settings: LevelSettings
    match level:
        5:
            maze = Level5.create_maze()
            settings = Level5.create_settings()
            maze.place_reward_sticker(maze.finish, settings)
            maze.place_penalty_sticker(Vector2i(3,2), settings)
        6:
            maze = Level6.create_maze()
            settings = Level6.create_settings()
            maze.place_reward_sticker(maze.finish, settings)
            maze.place_penalty_sticker(Vector2i(2,1), settings)
        7:
            maze = Level7.create_maze()
            settings = Level7.create_settings()
            maze.place_reward_sticker(maze.finish, settings)
            maze.place_one_time_sticker(Vector2i(0,4), settings)

    settings.progress_bonus = bonus
    settings.step_cost = step_cost

    var trainer := Trainer.new()
    trainer.maze = maze
    trainer.agent = QAgent.new()
    trainer.agent.gamma = patience
    trainer.agent.epsilon = curiosity
    trainer.robot = Robot.new()
    trainer.settings = settings

    trainer.train(EPISODES, settings.max_steps)
    trainer.agent.epsilon = 0
    var route := trainer.run_final_episode(settings.max_steps)
    return outcome(maze, route, trainer)


# same order of checks as get_result in level.gd, plus stars
func outcome(maze: Maze, route: Array, trainer: Trainer) -> String:
    if trainer.stuck_reason != "":
        return "stuck_" + trainer.stuck_reason
    for pos in route:
        if pos in maze.spikes:
            return "spike"
    if maze.crystals.has(route.back()):
        return "crystal"
    if route.back() != maze.finish:
        return "out_of_steps"
    for star in maze.stars:
        if not star in route:
            return "missed_star"
    return "PASS"


func save_csv() -> void:
    DirAccess.make_dir_recursive_absolute(PATH.get_base_dir())
    var file := FileAccess.open(PATH, FileAccess.WRITE)
    file.store_string("\n".join(lines) + "\n")
    print("saved ", PATH)
