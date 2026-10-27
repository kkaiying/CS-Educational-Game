class_name Level1

# maze: 7 high and 3 wide corridor
static func create_maze() -> Maze:
    var maze := Maze.new()
    maze.start = Vector2i(1,6)
    maze.finish = Vector2i(1,0)
    maze.width = 3
    maze.height = 7
    return maze

# level 1 settings
static func create_settings() -> LevelSettings:
    var settings := LevelSettings.new()
    settings.max_reward_stickers = 1
    settings.episodes = 10000
    settings.max_steps = 100
    return settings
