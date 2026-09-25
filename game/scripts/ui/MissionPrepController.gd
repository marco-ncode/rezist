## Mission Prep screen (RZ-075, UX_UI.md §3): shows the generated grid
## before wave 1 and lets the player place each squad on a deployment-zone
## tile. [Start] only enables once every squad has a chosen tile.
##
## Regenerates the mission grid independently from
## GameState.run_state.seed_value rather than receiving it from anywhere —
## MapGenerator's determinism contract (TDD §5) guarantees Mission.tscn's
## own regeneration from the same seed/derive-key produces the
## byte-identical grid, so only the small deployment decision (one tile per
## squad) needs to cross the scene transition via
## GameState.mission_deployment_positions.
extends Node2D

const GridRendererScript := preload("res://scripts/mission/GridRenderer.gd")
const TILE_SIZE := GridRendererScript.TILE_SIZE
const DEPLOYMENT_RADIUS := 3
const ZONE_COLOR := Color(0.95, 0.66, 0.23, 0.22)
const MARKER_COLOR := Color("F2A93B")

var _grid: TacticalGrid
var _safehouses: Array = []
var _entry_points: Array = []
var _deployment_tiles: Array = [] # Array[Vector2i]
## RZ-141: sized to the run's live roster (GameState.run_state.alive_commanders()),
## not a hardcoded 3 — a run that has already lost a commander to permadeath
## deploys fewer squads, and Mission.tscn (MissionController._spawn_squads())
## reads this same roster in the same order, so the two screens agree.
var _squad_count := 0
var _roster: Array = [] # Array[Commander], same order MissionController reads
var _chosen_positions: Array = [] # size _squad_count, Vector2i or null
var _selected_squad_index := -1

var _zone_root: Node2D
var _squad_marker_root: Node2D
var _squad_markers: Array = [] # size _squad_count, ColorRect or null
var _squad_buttons: Array = []
var _start_button: Button
var _hint_label: Label

func _ready() -> void:
	if GameState.run_state == null:
		# MissionPrep.tscn loaded directly (e.g. quick manual testing in the
		# editor) without going through Main.gd first.
		GameState.start_new_run(-1, "normal")
	_roster = GameState.run_state.alive_commanders()
	_squad_count = _roster.size()

	# RZ-089: reachable now that squads persist across missions (RZ-141) —
	# every commander could have permadied, most commonly via loading a
	# stale save whose run already ended (Continue doesn't currently offer
	# to delete a finished run's save, so this is the fallback for that).
	# Redirect straight to the Run Summary screen rather than building a
	# Mission Prep UI with nothing to place.
	if _squad_count == 0:
		get_tree().change_scene_to_file("res://scenes/RunSummary.tscn")
		return

	var district_entry := DataLoader.districts.get_district(GameState.mission_district_id)
	var mission_rng := GameState.make_rng("mission")
	var gen_result := MapGenerator.generate(mission_rng.derive("map"), district_entry)
	_grid = gen_result["grid"]
	_safehouses = gen_result["safehouses"]
	_entry_points = gen_result["entry_points"]

	var grid_renderer := GridRendererScript.new()
	add_child(grid_renderer)
	grid_renderer.render(_grid, _safehouses, _entry_points)

	var camera: Camera2D = get_node_or_null("Camera2D")
	if camera != null:
		camera.position = Vector2(_grid.width, _grid.height) * TILE_SIZE * 0.5

	_zone_root = Node2D.new()
	add_child(_zone_root)
	_squad_marker_root = Node2D.new()
	add_child(_squad_marker_root)

	_chosen_positions.resize(_squad_count)
	_squad_markers.resize(_squad_count)

	_compute_deployment_zone()
	_render_deployment_zone()
	_build_ui()
	_update_ui()

func _compute_deployment_zone() -> void:
	if _safehouses.is_empty():
		return
	var center: Vector2i = _safehouses[0].position
	for x in range(center.x - DEPLOYMENT_RADIUS, center.x + DEPLOYMENT_RADIUS + 1):
		for y in range(center.y - DEPLOYMENT_RADIUS, center.y + DEPLOYMENT_RADIUS + 1):
			var pos := Vector2i(x, y)
			if maxi(absi(pos.x - center.x), absi(pos.y - center.y)) > DEPLOYMENT_RADIUS:
				continue
			if _grid.is_walkable(pos, "ground"):
				_deployment_tiles.append(pos)

func _render_deployment_zone() -> void:
	for pos in _deployment_tiles:
		var marker := ColorRect.new()
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.size = Vector2(TILE_SIZE - 2, TILE_SIZE - 2)
		marker.position = GridRendererScript.tile_to_screen(pos, _grid.elevation_at(pos)) + Vector2(1, 1)
		marker.color = ZONE_COLOR
		_zone_root.add_child(marker)

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	_hint_label = Label.new()
	_hint_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hint_label.position = Vector2(-180, 16)
	_hint_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(_hint_label)

	var bottom_bar := HBoxContainer.new()
	bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar.position = Vector2(16, -64)
	bottom_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(bottom_bar)

	for i in _squad_count:
		var button := Button.new()
		button.custom_minimum_size = Vector2(150, 48)
		button.pressed.connect(_on_squad_button_pressed.bind(i))
		bottom_bar.add_child(button)
		_squad_buttons.append(button)

	_start_button = Button.new()
	_start_button.text = "Start"
	_start_button.custom_minimum_size = Vector2(96, 48)
	_start_button.disabled = true
	_start_button.pressed.connect(_on_start_pressed)
	bottom_bar.add_child(_start_button)

	# RZ-085: Armory entry point. Mission Prep is the natural stop between
	# missions to spend gold earned from the last one before deploying the
	# next — there's no Campaign Map (UX_UI.md's own reach point for it)
	# yet, RZ-080/081/082.
	var armory_button := Button.new()
	armory_button.text = "Armory"
	armory_button.custom_minimum_size = Vector2(96, 48)
	armory_button.pressed.connect(_on_armory_pressed)
	bottom_bar.add_child(armory_button)

	# RZ-086: Roster entry point, same reasoning as Armory above.
	var roster_button := Button.new()
	roster_button.text = "Roster"
	roster_button.custom_minimum_size = Vector2(96, 48)
	roster_button.pressed.connect(_on_roster_pressed)
	bottom_bar.add_child(roster_button)

func _on_armory_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Armory.tscn")

func _on_roster_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Roster.tscn")

func _on_squad_button_pressed(index: int) -> void:
	_selected_squad_index = index
	_update_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = get_global_mouse_position()
		var tile := Vector2i(int(floor(local_pos.x / TILE_SIZE)), int(floor(local_pos.y / TILE_SIZE)))
		_on_tile_clicked(tile)

func _on_tile_clicked(tile: Vector2i) -> void:
	if _selected_squad_index < 0:
		return
	if not _deployment_tiles.has(tile):
		return
	if _is_tile_taken_by_other_squad(tile, _selected_squad_index):
		return

	_chosen_positions[_selected_squad_index] = tile
	_refresh_squad_marker(_selected_squad_index)
	AudioManager.play_event("order_issued")
	_selected_squad_index = -1
	_update_ui()

func _is_tile_taken_by_other_squad(tile: Vector2i, ignore_index: int) -> bool:
	for i in _squad_count:
		if i != ignore_index and _chosen_positions[i] == tile:
			return true
	return false

func _refresh_squad_marker(index: int) -> void:
	if _squad_markers[index] != null:
		_squad_markers[index].queue_free()
		_squad_markers[index] = null

	var pos = _chosen_positions[index]
	if pos == null:
		return

	var marker := ColorRect.new()
	marker.size = Vector2(TILE_SIZE * 0.6, TILE_SIZE * 0.6)
	marker.position = GridRendererScript.tile_to_screen(pos, _grid.elevation_at(pos)) + Vector2(TILE_SIZE * 0.2, TILE_SIZE * 0.2)
	marker.color = MARKER_COLOR
	_squad_marker_root.add_child(marker)
	_squad_markers[index] = marker

func _update_ui() -> void:
	# _squad_count == 0 redirects to RunSummary.tscn in _ready() before this
	# is ever called (RZ-089) — no dead-roster case to handle here.
	var all_placed := true
	for i in _squad_count:
		var placed: bool = _chosen_positions[i] != null
		if not placed:
			all_placed = false
		var commander_name: String = _roster[i].display_name if i < _roster.size() else "Sq.%d" % (i + 1)
		_squad_buttons[i].text = "%s %s" % [commander_name, "✓" if placed else "(place)"]
		_squad_buttons[i].button_pressed = (i == _selected_squad_index)

	_start_button.disabled = not all_placed
	_hint_label.text = "All squads placed — press Start." if all_placed \
		else "Select a squad below, then click a highlighted tile to deploy it."

func _on_start_pressed() -> void:
	GameState.mission_deployment_positions = _chosen_positions.duplicate()
	get_tree().change_scene_to_file("res://scenes/Mission.tscn")
