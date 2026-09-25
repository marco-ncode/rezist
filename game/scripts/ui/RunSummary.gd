## Game Over / Run Summary screen (RZ-089, UX_UI.md §8): reached when the
## resolution panel's Continue button sees RunState.is_run_over() true
## (every commander has fallen — GDD §12 total wipe). Only ever shows the
## "RUN OVER" headline; the wireframe's alternate "CITY SECURED" is for full
## campaign completion, which isn't reachable yet — RunState.is_run_over()
## only detects the wipe condition, since there's no CampaignState to detect
## the other (RZ-081). "Reached: District N of ~11" is omitted for the same
## reason — nothing to report with a single hardcoded district and no
## campaign graph yet. Built entirely in code, same convention as
## MainMenu/HUD/MissionPrepController (no hand-authored .tscn UI tree).
class_name RunSummaryController
extends Control

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.08, 0.09, 0.11)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(-140, -70)
	vbox.add_theme_constant_override("separation", 14)
	add_child(vbox)

	var headline := Label.new()
	headline.text = "RUN OVER"
	headline.add_theme_color_override("font_color", Color.WHITE)
	headline.add_theme_font_size_override("font_size", 36)
	vbox.add_child(headline)

	var run_state: RunState = GameState.run_state
	var commanders_lost := 0
	var safehouses_saved := 0
	if run_state != null:
		for commander in run_state.commanders:
			if not commander.alive:
				commanders_lost += 1
		safehouses_saved = run_state.total_safehouses_saved

	var detail := Label.new()
	detail.text = "Commanders lost: %d\nSafehouses saved (total): %d" % [commanders_lost, safehouses_saved]
	detail.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(detail)

	var new_run_button := Button.new()
	new_run_button.text = "Start New Run"
	new_run_button.custom_minimum_size = Vector2(200, 48)
	new_run_button.pressed.connect(_on_start_new_run_pressed)
	vbox.add_child(new_run_button)

func _on_start_new_run_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
