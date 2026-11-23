class_name Tutorial

static func create_maze() -> Maze:
	var maze := Maze.new()
	maze.start = Vector2i(0,4)
	maze.finish = Vector2i(4,0)
	maze.width = 5
	maze.height = 5
	return maze

static func create_settings() -> LevelSettings:
	return Level1.create_settings()

static func demo_runs() -> Array:
	return [
		["Practice run 1", "URDDLLUURDRLDDRULURLLURDL"],
		["Practice run 50", "RULLDURULLDUURDDRDRULUL"],
		["Practice run 100", "URDURULURDLRRUDRDLUUUUR"],
		["Practice run 200", "URDUURRLURUR"],
		["Practice run 300", "URRURRULRU"],
		["Practice run 400", "URRURLRUUR"],
		["Practice run 500", "URURURUR"],
	]
