class_name Level2

static func create_maze() -> Maze:
    var maze := Maze.new()
    maze.start = Vector2i(1,6)
    maze.finish = Vector2i(1,0)
    maze.width = 3
    maze.height = 7
    maze.spikes = [Vector2i(0,4), Vector2i(1,4), Vector2i(1,2), Vector2i(2,2)]
    return maze

static func create_settings() -> LevelSettings:
    var settings := LevelSettings.new()
    settings.max_reward_stickers = 1
    settings.max_penalty_stickers = 4
    settings.episodes = 10000
    settings.max_steps = 100
    return settings
