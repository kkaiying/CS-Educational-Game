class_name QAgent

var alpha: float = 0.5    # learning rate: how much one experience changes a score
var gamma: float = 0.9    # discount ("patience"): how much future rewards count
var epsilon: float = 0.1  # exploration ("curiosity"): chance of a random move

# The Q-table. Key = a position, value = 4 scores in Robot.Direction order: [N, E, S, W].
var q_table: Dictionary = {}


# Returns the 4 scores for a square. Squares not seen yet start at all zeros.
func get_scores(pos: Vector2i) -> Array:
    if not q_table.has(pos):
        q_table[pos] = [0.0, 0.0, 0.0, 0.0]
    return q_table[pos]


# The highest-scoring direction from this square.
# Ties are broken randomly, otherwise an untrained robot (all zeros) would always pick NORTH.
func best_direction(pos: Vector2i) -> Robot.Direction:
    var scores := get_scores(pos)
    var best_score: float = scores.max()
    var best_dirs: Array = []
    for dir in range(4):
        if scores[dir] == best_score:
            best_dirs.append(dir)
    return best_dirs.pick_random() as Robot.Direction


# Explore (random move) with probability epsilon, otherwise exploit (best known move).
func choose_direction(pos: Vector2i) -> Robot.Direction:
    if randf() < epsilon:
        return randi_range(0, 3) as Robot.Direction
    return best_direction(pos)


# Q-learning update, called after every move.
# done = true if the move ended the run so nothing comes after it.
func learn(old_pos: Vector2i, dir: Robot.Direction, reward: float, new_pos: Vector2i, done: bool) -> void:
    var scores := get_scores(old_pos)
    var target := reward
    if not done:
        target += gamma * get_scores(new_pos).max()
    scores[dir] += alpha * (target - scores[dir])
