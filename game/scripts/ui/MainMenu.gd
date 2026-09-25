## Main Menu (RZ-074): the game's actual entry point (UX_UI.md §1). New Run
## opens an inline difficulty-select sub-panel (Easy/Normal/Hard/Very Hard +
## an optional seed field, matching the wireframe) before creating a fresh
## RunState and starting a mission. UX_UI.md's flow reads "→ Campaign Map",
## but the Campaign Map doesn't exist yet (RZ-080/081/082) — this targets
## Mission Prep instead, the same substitution Main.gd already made before
## RZ-074 existed. Continue loads the single save slot via SaveManager if
## one exists (disabled otherwise); Quit exits. No Settings screen yet
## (BACKLOG.md marks it "Should", no spec exists to build from). Built
## entirely in code, same convention as MissionPrepController/HUD (no
## hand-authored .tscn UI tree).
##
## Continue only loads an *existing* save — nothing here ever calls
## SaveManager.save(). No call site anywhere in the mission flow writes a
## save yet (that's RZ-090's job: deciding when a run actually gets
## persisted, e.g. after each mission), so in practice Continue stays
## disabled until RZ-090 lands. It's wired now so RZ-090 only has to add
## save call sites, not touch this menu again.
class_name MainMenuController
extends Control

const SAVE_SLOT := 0

var _continue_button: Button
var _root_menu: VBoxContainer
var _difficulty_panel: VBoxContainer
var _seed_field: LineEdit

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.08, 0.09, 0.11)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var title := Label.new()
	title.text = "REZIST"
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_font_size_override("font_size", 48)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-80, 120)
	add_child(title)

	_build_root_menu()
	_build_difficulty_panel()
	_difficulty_panel.visible = false

func _build_root_menu() -> void:
	_root_menu = VBoxContainer.new()
	_root_menu.set_anchors_preset(Control.PRESET_CENTER)
	_root_menu.position = Vector2(-90, -60)
	_root_menu.add_theme_constant_override("separation", 12)
	add_child(_root_menu)

	var new_run_button := Button.new()
	new_run_button.text = "New Run"
	new_run_button.custom_minimum_size = Vector2(180, 48)
	new_run_button.pressed.connect(_on_new_run_pressed)
	_root_menu.add_child(new_run_button)

	_continue_button = Button.new()
	_continue_button.text = "Continue"
	_continue_button.custom_minimum_size = Vector2(180, 48)
	_continue_button.disabled = not SaveManager.has_save(SAVE_SLOT)
	_continue_button.pressed.connect(_on_continue_pressed)
	_root_menu.add_child(_continue_button)

	var quit_button := Button.new()
	quit_button.text = "Quit"
	quit_button.custom_minimum_size = Vector2(180, 48)
	quit_button.pressed.connect(_on_quit_pressed)
	_root_menu.add_child(quit_button)

func _build_difficulty_panel() -> void:
	_difficulty_panel = VBoxContainer.new()
	_difficulty_panel.set_anchors_preset(Control.PRESET_CENTER)
	_difficulty_panel.position = Vector2(-110, -130)
	_difficulty_panel.add_theme_constant_override("separation", 10)
	add_child(_difficulty_panel)

	var label := Label.new()
	label.text = "Select Difficulty"
	label.add_theme_color_override("font_color", Color.WHITE)
	_difficulty_panel.add_child(label)

	for tier_id in DataLoader.difficulty.all_tier_ids():
		var tier := DataLoader.difficulty.get_tier(tier_id)
		var button := Button.new()
		button.text = tier.get("name", tier_id)
		button.custom_minimum_size = Vector2(220, 40)
		button.pressed.connect(_on_difficulty_selected.bind(tier_id))
		_difficulty_panel.add_child(button)

	var seed_row := HBoxContainer.new()
	_difficulty_panel.add_child(seed_row)

	var seed_label := Label.new()
	seed_label.text = "Seed (blank = random): "
	seed_label.add_theme_color_override("font_color", Color.WHITE)
	seed_row.add_child(seed_label)

	_seed_field = LineEdit.new()
	_seed_field.custom_minimum_size = Vector2(100, 0)
	_seed_field.placeholder_text = "random"
	seed_row.add_child(_seed_field)

	var back_button := Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(220, 40)
	back_button.pressed.connect(_on_difficulty_back_pressed)
	_difficulty_panel.add_child(back_button)

func _on_new_run_pressed() -> void:
	_root_menu.visible = false
	_difficulty_panel.visible = true

func _on_difficulty_back_pressed() -> void:
	_difficulty_panel.visible = false
	_root_menu.visible = true

func _on_difficulty_selected(tier_id: String) -> void:
	var seed_value := -1
	var seed_text := _seed_field.text.strip_edges()
	if seed_text.is_valid_int():
		seed_value = int(seed_text)
	GameState.start_new_run(seed_value, tier_id)
	get_tree().change_scene_to_file("res://scenes/MissionPrep.tscn")

func _on_continue_pressed() -> void:
	var loaded := SaveManager.load(SAVE_SLOT)
	if loaded == null:
		return
	GameState.run_state = loaded
	GameState.clear_mission_deployment()
	get_tree().change_scene_to_file("res://scenes/MissionPrep.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
