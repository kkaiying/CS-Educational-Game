extends Control

func _ready():
	$PlayButton.get_popup().id_pressed.connect(_on_level_chosen)   # when an item in the list is picked, call _on_level_chosen

func _on_level_chosen(id: int) -> void:
	Game.go_to_level(id)
