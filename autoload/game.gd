extends Node

var current_level: int = 1

func go_to_level(level: int) -> void:
		current_level = level
		get_tree().change_scene_to_file("res://scenes/level.tscn")

func go_to_home() -> void:
		get_tree().change_scene_to_file("res://scenes/home.tscn")
