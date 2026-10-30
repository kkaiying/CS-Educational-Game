class_name Maze

var start: Vector2i
var finish: Vector2i
var width: int
var height: int
var stickers: Dictionary[Vector2i, float] = {}
var spikes: Array[Vector2i] = []


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