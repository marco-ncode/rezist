## Roster / Commander screen (RZ-086, UX_UI.md §7): an overview of every
## commander in the run — alive ones with their trait/relic/squad size, and
## a permanent history of fallen ones (GDD pillar 2 — permadeath should
## sting, and be remembered; RunState never removes a dead commander from
## `commanders`, only from the active roster metadata). Reached from a new
## "Roster" button on Mission Prep's bottom bar, alongside Armory (RZ-085);
## [Back] returns there — no Campaign Map to reach it from yet, same
## substitution as elsewhere. Built entirely in code, same convention as
## MainMenu/MissionPrepController/RunSummary/Armory (no hand-authored .tscn
## UI tree).
##
## The wireframe's "died Mission 4 (Brute)" annotation isn't shown — nothing
## in the codebase records which mission or which enemy type killed a
## commander (RunState.on_commander_died() only erases roster metadata and
## emits a signal). Adding that tracking is a real feature, not a UI
## detail, and is out of scope here; the fallen list shows names only.
## Squad size is dots only, never a "(5/6)" fraction like the wireframe
## shows — ADR-0005 bans a number for squad strength on every other screen
## (HUD.update_squad_button() already only ever shows dots), and this
## screen shouldn't be the one exception.
class_name RosterController
extends Control

func _ready() -> void:
	if GameState.run_state == null:
		# Roster.tscn loaded directly (e.g. quick manual testing in the
		# editor) without going through Main Menu/Mission Prep first.
		GameState.start_new_run(-1, "normal")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.08, 0.09, 0.11)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var top_bar := HBoxContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.position = Vector2(16, 12)
	add_child(top_bar)

	var title := Label.new()
	title.text = "Roster"
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_font_size_override("font_size", 24)
	top_bar.add_child(title)

	var back_button := Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(96, 40)
	back_button.pressed.connect(_on_back_pressed)
	top_bar.add_child(back_button)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 60
	scroll.offset_left = 16
	scroll.offset_right = -16
	scroll.offset_bottom = -16
	add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)

	for commander in GameState.run_state.alive_commanders():
		list.add_child(_build_commander_card(commander))

	var separator := HSeparator.new()
	list.add_child(separator)

	var fallen_header := Label.new()
	fallen_header.text = "Fallen Commanders:"
	fallen_header.add_theme_color_override("font_color", Color.WHITE)
	fallen_header.add_theme_font_size_override("font_size", 18)
	list.add_child(fallen_header)

	var fallen: Array = GameState.run_state.commanders.filter(func(c: Commander): return not c.alive)
	if fallen.is_empty():
		var none_label := Label.new()
		none_label.text = "None yet."
		none_label.add_theme_color_override("font_color", Color.WHITE)
		list.add_child(none_label)
	else:
		for commander in fallen:
			var fallen_label := Label.new()
			fallen_label.text = "• %s" % commander.display_name
			fallen_label.add_theme_color_override("font_color", Color.WHITE)
			list.add_child(fallen_label)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MissionPrep.tscn")

func _build_commander_card(commander: Commander) -> PanelContainer:
	var card := PanelContainer.new()
	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	var meta := GameState.run_state.get_roster_meta(commander.id)
	var unit_class: String = meta.get("unit_class", "riot")
	var level: int = meta.get("level", 1)
	var unit_count: int = meta.get("unit_count", 0)
	var class_data := DataLoader.units.get_unit_class(unit_class)

	var name_label := Label.new()
	name_label.text = "%s — %s L%d" % [commander.display_name, class_data.get("name", unit_class), level]
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_label)

	var trait_label := Label.new()
	if commander.trait_id != "" and DataLoader.traits.has_trait(commander.trait_id):
		var trait_data := DataLoader.traits.get_trait(commander.trait_id)
		trait_label.text = "Trait: %s (%s)" % [trait_data.get("name", commander.trait_id), trait_data.get("description", "")]
	else:
		trait_label.text = "Trait: None"
	trait_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(trait_label)

	var relic_label := Label.new()
	if commander.relic_id != "" and DataLoader.relics.has_relic(commander.relic_id):
		relic_label.text = "Relic: %s" % DataLoader.relics.get_relic(commander.relic_id).get("name", commander.relic_id)
	else:
		relic_label.text = "Relic: None"
	relic_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(relic_label)

	var max_size: int = DataLoader.units.squad_base_max_size + int(DataLoader.traits.get_modifier(commander.trait_id, "squad_max_size_add", 0))
	var filled: int = clampi(unit_count, 0, max_size)
	var squad_label := Label.new()
	squad_label.text = "Squad size: %s%s" % ["●".repeat(filled), "○".repeat(max_size - filled)]
	squad_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(squad_label)

	var status_label := Label.new()
	status_label.text = "Status: Active"
	status_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(status_label)

	return card
