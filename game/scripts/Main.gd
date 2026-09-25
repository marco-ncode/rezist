## Bootstrap entry point (project.godot run/main_scene). Immediately hands
## off to the Main Menu (RZ-074) — New Run vs. Continue vs. Quit is decided
## there, not here.
extends Node

func _ready() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
