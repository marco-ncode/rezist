## Armory / Upgrade screen (RZ-085, UX_UI.md §6): spend gold on a selected
## commander's squad. Reached from Mission Prep's bottom bar; [Back] returns
## there. Select a commander in the roster strip first (nothing is shown
## until one is picked, per the wireframe), then switch between the three
## tabs to see that commander's contextual options. Built entirely in code,
## same convention as MainMenu/MissionPrepController/RunSummary (no
## hand-authored .tscn UI tree).
##
## Class Tiers and Relics are real, functional purchases: leveling up
## changes the stats `UnitData.get_level_stats()` hands the squad next
## mission, and equipping a relic sets the same `Commander.relic_id` field
## SaveManager already round-trips. Abilities is informational only in v1 —
## every class's ability already works unconditionally regardless of squad
## level (no gating exists in MissionController/AbilityRegistry today), so
## there is nothing a gold purchase would actually unlock yet. Wiring real
## enforcement (GDD's "L2: ability purchasable") is tracked separately as
## RZ-144, since it touches already-working ability-activation code and
## deserves its own careful pass rather than riding in here.
class_name ArmoryController
extends Control

enum Tab { CLASS_TIERS, ABILITIES, RELICS }

var _economy: Economy
var _roster: Array = [] # Array[Commander]
var _selected_commander_index := -1
var _selected_tab: Tab = Tab.CLASS_TIERS

var _gold_label: Label
var _roster_strip: HBoxContainer
var _roster_buttons: Array = []
var _tab_buttons: Dictionary = {} # Tab -> Button
var _content_root: VBoxContainer

func _ready() -> void:
	if GameState.run_state == null:
		# Armory.tscn loaded directly (e.g. quick manual testing in the
		# editor) without going through Main Menu/Mission Prep first.
		GameState.start_new_run(-1, "normal")
	_roster = GameState.run_state.alive_commanders()
	if _roster.is_empty():
		# No commanders left to manage — same total-wipe fallback as
		# MissionPrepController (RZ-089).
		get_tree().change_scene_to_file("res://scenes/RunSummary.tscn")
		return

	_economy = DataLoader.make_economy()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_refresh_content()

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

	_gold_label = Label.new()
	_gold_label.add_theme_color_override("font_color", Color.WHITE)
	top_bar.add_child(_gold_label)
	_refresh_gold_label()

	var back_button := Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(96, 40)
	back_button.pressed.connect(_on_back_pressed)
	top_bar.add_child(back_button)

	_roster_strip = HBoxContainer.new()
	_roster_strip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_roster_strip.position = Vector2(16, 60)
	add_child(_roster_strip)

	for i in _roster.size():
		var commander: Commander = _roster[i]
		var button := Button.new()
		button.text = commander.display_name
		button.custom_minimum_size = Vector2(140, 40)
		button.pressed.connect(_on_commander_selected.bind(i))
		_roster_strip.add_child(button)
		_roster_buttons.append(button)

	var tab_bar := HBoxContainer.new()
	tab_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tab_bar.position = Vector2(16, 108)
	add_child(tab_bar)

	_add_tab_button(tab_bar, "Class Tiers", Tab.CLASS_TIERS)
	_add_tab_button(tab_bar, "Abilities", Tab.ABILITIES)
	_add_tab_button(tab_bar, "Relics", Tab.RELICS)

	_content_root = VBoxContainer.new()
	_content_root.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_content_root.position = Vector2(16, 156)
	_content_root.add_theme_constant_override("separation", 10)
	add_child(_content_root)

func _add_tab_button(parent: HBoxContainer, label: String, tab: Tab) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(140, 36)
	button.toggle_mode = true
	button.pressed.connect(_on_tab_selected.bind(tab))
	parent.add_child(button)
	_tab_buttons[tab] = button

func _refresh_gold_label() -> void:
	_gold_label.text = "Gold: %d" % GameState.run_state.gold

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MissionPrep.tscn")

func _on_commander_selected(index: int) -> void:
	_selected_commander_index = index
	for i in _roster_buttons.size():
		_roster_buttons[i].button_pressed = (i == index)
	_refresh_content()

func _on_tab_selected(tab: Tab) -> void:
	_selected_tab = tab
	for t in _tab_buttons:
		_tab_buttons[t].button_pressed = (t == tab)
	_refresh_content()

func _refresh_content() -> void:
	for child in _content_root.get_children():
		child.queue_free()

	if _selected_commander_index < 0:
		var hint := Label.new()
		hint.text = "Select a commander above to see their squad's upgrade options."
		hint.add_theme_color_override("font_color", Color.WHITE)
		_content_root.add_child(hint)
		return

	var commander: Commander = _roster[_selected_commander_index]
	match _selected_tab:
		Tab.CLASS_TIERS:
			_build_class_tiers_panel(commander)
		Tab.ABILITIES:
			_build_abilities_panel(commander)
		Tab.RELICS:
			_build_relics_panel(commander)

func _build_class_tiers_panel(commander: Commander) -> void:
	var meta := GameState.run_state.get_roster_meta(commander.id)
	var unit_class: String = meta.get("unit_class", "riot")
	var level: int = meta.get("level", 1)
	var class_data := DataLoader.units.get_unit_class(unit_class)
	var max_level: int = class_data["levels"].size()

	var header := Label.new()
	header.text = "%s — %s, level %d/%d" % [commander.display_name, class_data.get("name", unit_class), level, max_level]
	header.add_theme_color_override("font_color", Color.WHITE)
	_content_root.add_child(header)

	if level >= max_level:
		var maxed := Label.new()
		maxed.text = "Already at max level."
		maxed.add_theme_color_override("font_color", Color.WHITE)
		_content_root.add_child(maxed)
		return

	var cost: int = _economy.upgrade_cost(level, level + 1)
	var button := Button.new()
	button.text = "Upgrade to level %d — %d gold" % [level + 1, cost]
	button.custom_minimum_size = Vector2(260, 40)
	button.disabled = GameState.run_state.gold < cost
	button.pressed.connect(_on_upgrade_pressed.bind(commander, unit_class, level, meta.get("unit_count", 0)))
	_content_root.add_child(button)

func _on_upgrade_pressed(commander: Commander, unit_class: String, level: int, unit_count: int) -> void:
	var cost: int = _economy.upgrade_cost(level, level + 1)
	if not GameState.run_state.spend_gold(cost):
		return
	GameState.run_state.update_roster_meta(commander.id, unit_class, level + 1, unit_count)
	AudioManager.play_event("upgrade_purchased")
	_refresh_gold_label()
	_refresh_content()

func _build_abilities_panel(commander: Commander) -> void:
	var meta := GameState.run_state.get_roster_meta(commander.id)
	var unit_class: String = meta.get("unit_class", "riot")
	var class_data := DataLoader.units.get_unit_class(unit_class)
	# class_data["ability_id"] is JSON null for a class with no ability
	# (e.g. Recruit) — the key exists, so .get(key, "") does not fall back
	# to "": assigning null straight to a String-typed var would be a
	# runtime type error, so the null check has to happen explicitly.
	var ability_id: String = class_data["ability_id"] if class_data.get("ability_id") != null else ""

	var header := Label.new()
	header.text = "%s — %s" % [commander.display_name, class_data.get("name", unit_class)]
	header.add_theme_color_override("font_color", Color.WHITE)
	_content_root.add_child(header)

	if ability_id == "":
		var none_label := Label.new()
		none_label.text = "This class has no ability."
		none_label.add_theme_color_override("font_color", Color.WHITE)
		_content_root.add_child(none_label)
		return

	var ability_available: bool = DataLoader.abilities.has_ability(ability_id)
	var cost: int = _economy.ability_cost(commander.trait_id)
	var detail := Label.new()
	if ability_available:
		var ability := DataLoader.abilities.get_ability(ability_id)
		detail.text = "%s — %d gold\nAlready available to this squad in v1: ability access isn't gated by level or purchase yet." % [ability.get("name", ability_id), cost]
	else:
		detail.text = "%s — %d gold\nNot yet implemented (no Ability subclass exists for this effect)." % [ability_id.capitalize(), cost]
	detail.add_theme_color_override("font_color", Color.WHITE)
	_content_root.add_child(detail)

func _build_relics_panel(commander: Commander) -> void:
	var equipped_name := "None"
	if commander.relic_id != "":
		equipped_name = DataLoader.relics.get_relic(commander.relic_id).get("name", commander.relic_id)

	var header := Label.new()
	header.text = "%s — Equipped relic: %s" % [commander.display_name, equipped_name]
	header.add_theme_color_override("font_color", Color.WHITE)
	_content_root.add_child(header)

	for relic_id in DataLoader.relics.all_relic_ids():
		var relic := DataLoader.relics.get_relic(relic_id)
		var equipped: bool = commander.relic_id == relic_id
		var cost: int = _economy.relic_cost(DataLoader.relics, relic_id, commander.trait_id)

		var row := HBoxContainer.new()
		_content_root.add_child(row)

		var label := Label.new()
		label.custom_minimum_size = Vector2(280, 0)
		label.text = "%s%s — %d gold" % [relic.get("name", relic_id), " (equipped)" if equipped else "", cost]
		label.add_theme_color_override("font_color", Color.WHITE)
		row.add_child(label)

		var button := Button.new()
		button.text = "Equipped" if equipped else "Equip"
		button.custom_minimum_size = Vector2(100, 36)
		button.disabled = equipped or GameState.run_state.gold < cost
		button.pressed.connect(_on_relic_pressed.bind(commander, relic_id, cost))
		row.add_child(button)

func _on_relic_pressed(commander: Commander, relic_id: String, cost: int) -> void:
	if not GameState.run_state.spend_gold(cost):
		return
	commander.relic_id = relic_id
	AudioManager.play_event("upgrade_purchased")
	_refresh_gold_label()
	_refresh_content()
