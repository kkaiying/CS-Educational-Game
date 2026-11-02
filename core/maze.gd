class_name Maze

var start: Vector2i
var finish: Vector2i
var width: int
var height: int
var stickers: Dictionary[Vector2i, float] = {}
var spikes: Array[Vector2i] = []
var walls: Array[Vector2i] = []
var distances: Dictionary[Vector2i, int] = {}


func is_finish(pos: Vector2i) -> bool:
    return pos == finish

func is_inside(target_pos: Vector2i) -> bool:
    return target_pos.x < width && target_pos.y < height && target_pos.x >= 0 && target_pos.y >= 0

func get_reward(pos: Vector2i) -> float:
    return stickers.get((pos), 0.0)

func place_reward_sticker(pos: Vector2i, settings: LevelSettings) -> bool:
    if not (is_inside(pos)):                             # if pos is outside the maze
        return false
    if (stickers.has(pos)):                             # already a sticker on that tile
        return false
    var reward_count := 0
    for value in stickers.values():                     # find number of reward stickers already in maze
        if value > 0:
            reward_count += 1
    if (reward_count >= settings.max_reward_stickers): # if there are no more reward stickers to spare
        return false
    stickers[pos] = settings.reward_sticker_value
    return true
    
func place_penalty_sticker(pos: Vector2i, settings: LevelSettings) -> bool:
    if not(is_inside(pos)):
        return false
    if (stickers.has(pos)):
        return false
    var penalty_count := 0
    for value in stickers.values():
        if value < 0 :
            penalty_count += 1
    if (penalty_count >= settings.max_penalty_stickers):
        return false
    stickers[pos] = settings.penalty_sticker_value
    return true

func can_enter(pos: Vector2i) -> bool:
    return is_inside(pos) and not (pos in walls)

func compute_distances() -> void:
    distances = {finish: 0}
    var queue: Array[Vector2i] = [finish]
    while not queue.is_empty():
        var pos: Vector2i = queue.pop_front()
        for step in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
            var next: Vector2i = pos + step
            if can_enter(next) and not distances.has(next):
                distances[next] = distances[pos] + 1
                queue.append(next)

func walking_distance(pos: Vector2i) -> int:
    if distances.is_empty():
        compute_distances()
    return distances[pos]