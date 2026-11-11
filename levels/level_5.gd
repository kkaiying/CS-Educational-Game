class_name Level5

static func create_maze() -> Maze:
    var maze := Maze.new()
    maze.start = Vector2i(4,4)
    maze.finish = Vector2i(0,0)
    maze.width = 8
    maze.height = 6
    maze.crystals = {Vector2i(2,5): 5.0}
    maze.walls = [
        Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(4,1), Vector2i(6,1),
        Vector2i(2,2), Vector2i(6,2),
        Vector2i(2,3), Vector2i(4,3), Vector2i(5,3), Vector2i(6,3),
        Vector2i(0,4),
        Vector2i(0,5), Vector2i(1,5), Vector2i(3,5), Vector2i(4,5), Vector2i(6,5),
    ]
    maze.spikes = [Vector2i(3,2)]
    return maze
      
static func create_settings() -> LevelSettings:
    var settings := LevelSettings.new()
    settings.max_reward_stickers = 1
    settings.max_penalty_stickers = 1
    settings.episodes = 500
    settings.max_steps = 150
    settings.progress_bonus = true
    settings.unlocked = ["patience"]
    return settings