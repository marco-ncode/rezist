## Bootstrap entry point (project.godot run/main_scene). v1 has no Main Menu
## yet (docs/BACKLOG.md RZ-074) — starts a fresh run and drops straight into
## a mission so the vertical slice is playable end-to-end on launch.
extends Node

func _ready() -> void:
	GameState.start_new_run(-1, "normal")
	get_tree().change_scene_to_file("res://scenes/Mission.tscn")
