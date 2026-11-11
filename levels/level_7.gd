class_name Level7

static func create_maze() -> Maze:
    var maze := Maze.new()
    maze.start = Vector2i(4,6)
    maze.finish = Vector2i(2,0)
    maze.width = 9
    maze.height = 7
    maze.walls = [
        Vector2i(1,0), Vector2i(4,0),
        Vector2i(1,1), Vector2i(3,1), Vector2i(4,1), Vector2i(6,1), Vector2i(7,1),
        Vector2i(3,2), Vector2i(6,2),
        Vector2i(1,3), Vector2i(3,3), Vector2i(5,3), Vector2i(6,3),
        Vector2i(1,4), Vector2i(7,4),
        Vector2i(0,5), Vector2i(1,5), Vector2i(3,5), Vector2i(5,5), Vector2i(7,5),
        Vector2i(3,6), Vector2i(5,6),
    ]
    maze.stars = [Vector2i(0,4)]
    return maze
  
static func create_settings() -> LevelSettings:
    var settings := LevelSettings.new()
    settings.max_reward_stickers = 1
    settings.max_one_time_stickers = 1
    settings.max_penalty_stickers = 0
    settings.episodes = 500
    settings.max_steps = 200
    settings.unlocked = ["bonus", "patience", "step_cost", "curiosity"]
    return settings