extends SceneTree

func _init():
    print("Starting test level")

    var robot := Robot.new()
    robot.position = Vector2i(0,0)
    var maze := Maze.new()
    maze.finish = Vector2i(5,0)

    while not maze.is_finish(robot.position):
        robot.move(Robot.Direction.EAST)
        print("Moved east!")

    print("Arrived!")
    print(robot.position)
    quit()