class_name Level3

static func create_maze() -> Maze:
    var maze := Maze.new()
    maze.start = Vector2i(4,6)
    maze.finish = Vector2i(0,0)
    maze.width = 10
    maze.height = 8
    maze.walls = [
        Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(4,1), Vector2i(5,1), Vector2i(6,1), Vector2i(7,1), Vector2i(9,1),
        Vector2i(3,2), Vector2i(6,2),
        Vector2i(0,3), Vector2i(1,3), Vector2i(5,3), Vector2i(7,3), Vector2i(9,3),
        Vector2i(3,4), Vector2i(5,4), Vector2i(9,4),
        Vector2i(1,5), Vector2i(2,5), Vector2i(3,5), Vector2i(5,5), Vector2i(6,5), Vector2i(7,5), Vector2i(9,5),
        Vector2i(0,7), Vector2i(1,7), Vector2i(2,7), Vector2i(3,7), Vector2i(5,7), Vector2i(6,7), Vector2i(8,7), Vector2i(9,7),
    ]
    return maze

static func create_settings() -> LevelSettings:
    var settings := LevelSettings.new()
    settings.max_reward_stickers = 3
    settings.max_penalty_stickers = 0
    settings.episodes = 100
    settings.max_steps = 150
    return settings