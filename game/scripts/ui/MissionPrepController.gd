## Mission Prep screen (RZ-075, UX_UI.md §3): shows the generated grid
## before wave 1 and lets the player place each squad on a deployment-zone
## tile. [Start] only enables once every squad has a chosen tile.
##
## Regenerates the mission grid independently from GameState.seed_value
## rather than receiving it from anywhere — MapGenerator's determinism
## contract (TDD §5) guarantees Mission.tscn's own regeneration from the
## same seed/derive-key produces the byte-identical grid, so only the
## small deployment decision (one tile per squad) needs to cross the scene
## transition via GameState.mission_deployment_positions.
extends Node2D

const GridRendererScript := preload("res://scripts/mission/GridRenderer.gd")
const TILE_SIZE := GridRendererScript.TILE_SIZE
const DEPLOYMENT_RADIUS := 3
const SQUAD_COUNT := 3
const ZONE_COLOR := Color(0.95, 0.66, 0.23, 0.22)
const MARKER_COLOR := Color("F2A93B")

var _grid: TacticalGrid
var _safehouses: Array = []
var _entry_points: Array = []
var _deployment_tiles: Array = [] # Array[Vector2i]
var _chosen_positions: Array = [] # size SQUAD_COUNT, Vector2i or null
var _selected_squad_index := -1

var _zone_root: Node2D
var _squad_marker_root: Node2D
var _squad_markers: Array = [] # size SQUAD_COUNT, ColorRect or null
var _squad_buttons: Array = []
var _start_button: Button
var _hint_label: Label

func _ready() -> void:
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

	_chosen_positions.resize(SQUAD_COUNT)
	_squad_markers.resize(SQUAD_COUNT)

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

	for i in SQUAD_COUNT:
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
	for i in SQUAD_COUNT:
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
	var all_placed := true
	for i in SQUAD_COUNT:
		var placed: bool = _chosen_positions[i] != null
		if not placed:
			all_placed = false
		_squad_buttons[i].text = "Sq.%d %s" % [i + 1, "✓" if placed else "(place)"]
		_squad_buttons[i].button_pressed = (i == _selected_squad_index)

	_start_button.disabled = not all_placed
	_hint_label.text = "All squads placed — press Start." if all_placed \
		else "Select a squad below, then click a highlighted tile to deploy it."

func _on_start_pressed() -> void:
	GameState.mission_deployment_positions = _chosen_positions.duplicate()
	get_tree().change_scene_to_file("res://scenes/Mission.tscn")
