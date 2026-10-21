class_name Robot

enum Direction { NORTH, EAST, SOUTH, WEST }

var position: Vector2i

func move(dir: Direction) -> void:
    match dir:
        Direction.NORTH:
            position.y -= 1
        Direction.EAST:
            position.x += 1
        Direction.SOUTH:
            position.y += 1
        Direction.WEST:
            position.x -= 1
        
