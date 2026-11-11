class_name LevelSettings

var max_reward_stickers: int = 0
var reward_sticker_value: float = 10.0
var max_one_time_stickers: int = 0
var one_time_sticker_value: float = 10.0
var max_penalty_stickers: int = 0
var penalty_sticker_value: float = -10.0
var progress_bonus: bool = false
var patience: float = 0.9
var step_cost: float = 0.0
var curiosity: float = 0.1
var unlocked: Array[String] = [] # settings the player can change

var episodes
var max_steps
