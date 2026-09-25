## scripts/ adapter (ARCHITECTURE.md layering): bridges player input and the
## Node tree to the core/ simulation modules for one mission. This is the
## only place in the vertical slice allowed to call into core/squad,
## core/enemy, core/waves, core/procgen directly from a live scene.
extends Node2D

const GridRendererScript := preload("res://scripts/mission/GridRenderer.gd")
const HUDScript := preload("res://scripts/ui/HUD.gd")

const TILE_SIZE := GridRendererScript.TILE_SIZE
const UNIT_COLOR := Color("F2A93B")
const COMMANDER_ACCENT := Color("FFD37A")
const ENEMY_COLORS := {
	"walker": Color("6B7A5E"),
	"riot_zombie": Color("4B5940"),
	"spitter": Color("7D8F6E"),
	"brute": Color("3F4A36"),
	"brute_spitter": Color("4A5940"),
	"thrower": Color("5E6E50"),
	"leaper": Color("8A9A78"),
	"colossus": Color("2A331F"),
}

var _district_id := "residential"
var _grid: TacticalGrid
var _safehouses: Array = []
var _entry_points: Array = []
var _squads: Array = [] # Array[Squad]
var _active_enemies: Array = [] # Array[Enemy]
var _wave_controller: WaveController
var _economy: Economy
var _mission_rng: SimRng
var _tick_rng: SimRng

var _selected_squad_index := -1
var _ability_target_mode := false
var _mission_over := false

var _grid_renderer: Node2D
var _unit_view_root: Node2D
var _enemy_view_root: Node2D
var _unit_views: Dictionary = {} # unit.id -> ColorRect
var _enemy_views: Dictionary = {} # enemy.id -> ColorRect
var _hud: CanvasLayer

func _ready() -> void:
	if GameState.run_state == null:
		# Mission.tscn loaded directly (e.g. quick manual testing in the
		# editor) without going through Main.gd/MissionPrep first.
		GameState.start_new_run(-1, "normal")

	_economy = DataLoader.make_economy()
	_mission_rng = GameState.make_rng("mission")
	_district_id = GameState.mission_district_id

	var district_entry := DataLoader.districts.get_district(_district_id)
	var gen_result := MapGenerator.generate(_mission_rng.derive("map"), district_entry)
	_grid = gen_result["grid"]
	_safehouses = gen_result["safehouses"]
	_entry_points = gen_result["entry_points"]

	_grid_renderer = GridRendererScript.new()
	add_child(_grid_renderer)
	_grid_renderer.render(_grid, _safehouses, _entry_points)

	var camera: Camera2D = get_node_or_null("Camera2D")
	if camera != null:
		camera.position = Vector2(_grid.width, _grid.height) * TILE_SIZE * 0.5

	_unit_view_root = Node2D.new()
	add_child(_unit_view_root)
	_enemy_view_root = Node2D.new()
	add_child(_enemy_view_root)

	_spawn_squads()

	var difficulty_tier := GameState.current_difficulty_tier()
	var wave_set := DataLoader.waves.get_wave_set(district_entry.get("default_wave_set", "district_default_3wave"))
	_wave_controller = WaveController.new(
		wave_set, _entry_points, DataLoader.enemies, _mission_rng.derive("waves"),
		difficulty_tier.get("enemy_hp_mult", 1.0),
		difficulty_tier.get("enemy_damage_mult", 1.0),
		difficulty_tier.get("spawn_count_mult", 1.0)
	)

	_hud = HUDScript.new()
	add_child(_hud)
	_hud.build(_squads.size())
	_hud.squad_button_pressed.connect(_on_squad_button_pressed)
	_hud.ability_button_pressed.connect(_on_ability_button_pressed)
	_refresh_hud()

## RZ-141: squads' commanders now persist across missions in RunState, so
## each Squad must unhook itself from its (still-alive) commander when this
## scene goes away — otherwise the commander's `died` signal keeps a live
## reference to every past mission's Squad instance forever (see
## Squad.disconnect_commander_signal()). _exit_tree fires however this
## scene is torn down (win, lose, or a future forced scene change).
func _exit_tree() -> void:
	for squad in _squads:
		squad.disconnect_commander_signal()

func _spawn_squads() -> void:
	if _safehouses.is_empty():
		return
	var center: Vector2i = _safehouses[0].position
	var used_positions: Dictionary = {}

	# RZ-075: prefer the player's chosen deployment tiles from MissionPrep.
	# Falls back to auto-placement near the first safehouse if Mission.tscn
	# was loaded directly (e.g. quick manual testing in the editor) without
	# going through the prep screen.
	var deployment := GameState.mission_deployment_positions
	GameState.clear_mission_deployment()

	# RZ-141: squads are sourced from RunState's roster — the same Commander
	# objects RunState already tracks (and already has `died` connected to
	# RunState.on_commander_died) — instead of fresh throwaway instances, so
	# permadeath and per-squad unit losses persist across missions rather
	# than silently resetting every time a mission scene loads.
	var roster: Array = GameState.run_state.alive_commanders()
	for i in roster.size():
		var commander: Commander = roster[i]
		var meta := GameState.run_state.get_roster_meta(commander.id)
		var unit_class: String = meta.get("unit_class", "riot")
		var level: int = meta.get("level", 1)
		var unit_count: int = meta.get("unit_count", 0)

		var squad_center: Vector2i = deployment[i] if i < deployment.size() and deployment[i] != null \
			else center + Vector2i(i - 1, 2)
		var spawn_positions := _pick_spawn_positions(squad_center, unit_count, used_positions)

		var squad := Squad.new("sq_%d" % i, commander, unit_class, level, DataLoader.units, spawn_positions)
		squad.wiped.connect(_on_squad_wiped.bind(i))
		squad.commander_lost.connect(_on_commander_exposed)
		_squads.append(squad)
		for unit in squad.units:
			_create_unit_view(unit, i)

func _pick_spawn_positions(center: Vector2i, count: int, used_positions: Dictionary) -> Array:
	var result: Array = []
	var radius := 0
	while result.size() < count and radius < 6:
		for x in range(center.x - radius, center.x + radius + 1):
			for y in range(center.y - radius, center.y + radius + 1):
				var pos := Vector2i(x, y)
				if used_positions.has(pos):
					continue
				if maxi(absi(pos.x - center.x), absi(pos.y - center.y)) != radius:
					continue
				if _grid.is_walkable(pos, "ground"):
					result.append(pos)
					used_positions[pos] = true
					if result.size() >= count:
						break
			if result.size() >= count:
				break
		radius += 1
	return result

func _create_unit_view(unit: Unit, squad_index: int) -> void:
	var rect := ColorRect.new()
	rect.size = Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
	rect.color = COMMANDER_ACCENT if squad_index == 0 else UNIT_COLOR
	rect.position = GridRendererScript.tile_to_screen(unit.position, _grid.elevation_at(unit.position)) + Vector2(TILE_SIZE * 0.25, TILE_SIZE * 0.25)
	_unit_view_root.add_child(rect)
	_unit_views[unit.id] = rect

func _create_enemy_view(enemy: Enemy) -> void:
	var rect := ColorRect.new()
	rect.size = Vector2(TILE_SIZE * 0.45, TILE_SIZE * 0.45)
	rect.color = ENEMY_COLORS.get(enemy.enemy_type, Color("6B7A5E"))
	rect.position = GridRendererScript.tile_to_screen(enemy.position, _grid.elevation_at(enemy.position)) + Vector2(TILE_SIZE * 0.27, TILE_SIZE * 0.27)
	_enemy_view_root.add_child(rect)
	_enemy_views[enemy.id] = rect

func _physics_process(delta: float) -> void:
	if _mission_over:
		return

	_tick_rng = GameState.make_rng("tick_%d" % Engine.get_physics_frames())
	var trait_data := DataLoader.traits

	var newly_spawned: Array = _wave_controller.tick(delta)
	for enemy in newly_spawned:
		_active_enemies.append(enemy)
		_create_enemy_view(enemy)
	if newly_spawned.size() > 0:
		AudioManager.play_event("wave_incoming")

	var all_units: Array = []
	var unit_traits_by_id: Dictionary = {}
	for squad in _squads:
		all_units.append_array(squad.units)
		for unit in squad.units:
			unit_traits_by_id[unit.id] = squad.commander.traits()

	var combat_context := {
		"enemies": _active_enemies, "rng": _tick_rng, "trait_data": trait_data,
		"unit_traits_by_id": unit_traits_by_id,
	}
	for squad in _squads:
		if squad.is_wiped():
			continue
		var pre_count := squad.unit_count()
		squad.tick(delta, _grid, combat_context)
		if squad.unit_count() < pre_count:
			AudioManager.play_event("unit_death_ally")

	for enemy in _active_enemies:
		if not enemy.is_alive():
			continue
		var events := EnemyAI.tick_enemy(enemy, delta, _grid, all_units, _safehouses, combat_context)
		if events.get("attacked_safehouse") != null:
			AudioManager.play_event("safehouse_damaged")
			_grid_renderer.refresh_safehouses()
		if events.get("attacked_unit") != null:
			AudioManager.play_event("unit_attack_melee")

	_prune_dead_enemy_views()
	_update_unit_view_positions()
	_update_enemy_view_positions()
	_refresh_hud()
	_check_mission_end()

func _prune_dead_enemy_views() -> void:
	var still_alive: Array = []
	for enemy in _active_enemies:
		if enemy.is_alive():
			still_alive.append(enemy)
		else:
			if _enemy_views.has(enemy.id):
				_enemy_views[enemy.id].queue_free()
				_enemy_views.erase(enemy.id)
	_active_enemies = still_alive

func _update_unit_view_positions() -> void:
	for squad in _squads:
		for unit in squad.units:
			if _unit_views.has(unit.id):
				_unit_views[unit.id].position = GridRendererScript.tile_to_screen(unit.position, _grid.elevation_at(unit.position)) + Vector2(TILE_SIZE * 0.25, TILE_SIZE * 0.25)

func _update_enemy_view_positions() -> void:
	for enemy in _active_enemies:
		if _enemy_views.has(enemy.id):
			_enemy_views[enemy.id].position = GridRendererScript.tile_to_screen(enemy.position, _grid.elevation_at(enemy.position)) + Vector2(TILE_SIZE * 0.27, TILE_SIZE * 0.27)

func _unhandled_input(event: InputEvent) -> void:
	if _mission_over:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = get_global_mouse_position()
		var tile := Vector2i(int(local_pos.x / TILE_SIZE), int(local_pos.y / TILE_SIZE))
		_on_tile_clicked(tile)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_clear_selection()

func _on_tile_clicked(tile: Vector2i) -> void:
	if _selected_squad_index < 0:
		return
	var squad: Squad = _squads[_selected_squad_index]
	if squad.is_wiped():
		return

	if _ability_target_mode:
		var ability := DataLoader.ability_registry.get_ability(_squad_ability_id(squad))
		ability.activate(squad, tile, {"grid": _grid, "enemies": _active_enemies, "rng": _tick_rng, "trait_data": DataLoader.traits})
		AudioManager.play_event("ability_activated_breach")
		_ability_target_mode = false
	else:
		squad.order_move_to(tile, _grid)
		AudioManager.play_event("order_issued")

	_ease_time_scale(1.0)
	_selected_squad_index = -1
	_refresh_hud()

func _on_squad_button_pressed(index: int) -> void:
	if index >= _squads.size() or _squads[index].is_wiped():
		return
	_selected_squad_index = index
	_ability_target_mode = false
	_ease_time_scale(GameState.current_difficulty_tier().get("slow_mo_time_scale", 0.25))
	_refresh_hud()

func _on_ability_button_pressed() -> void:
	if _selected_squad_index < 0:
		return
	_ability_target_mode = true

func _clear_selection() -> void:
	_selected_squad_index = -1
	_ability_target_mode = false
	_ease_time_scale(1.0)
	_refresh_hud()

func _ease_time_scale(target: float) -> void:
	var tween := create_tween()
	tween.tween_property(Engine, "time_scale", target, 0.15)

func _squad_ability_id(squad: Squad) -> String:
	return DataLoader.units.get_unit_class(squad.unit_class).get("ability_id", "")

func _refresh_hud() -> void:
	for i in _squads.size():
		var squad: Squad = _squads[i]
		_hud.update_squad_button(i, squad.unit_count(), i == _selected_squad_index, squad.is_wiped(), squad.commander.display_name)
	var wave_text := "Wave %d/%d" % [_wave_controller.current_wave_number(), _wave_controller.total_waves]
	_hud.update_wave_label(wave_text)
	var ability_ready := _selected_squad_index >= 0 and not _squads[_selected_squad_index].is_wiped() \
		and _squads[_selected_squad_index].ability_cooldown_remaining <= 0.0
	_hud.update_ability_button(ability_ready, "Breach" if _ability_target_mode else "Ability")

func _on_squad_wiped(_squad: Squad, _index: int) -> void:
	AudioManager.play_event("commander_died")

func _on_commander_exposed(_squad: Squad) -> void:
	pass # Bad North rule: the commander alone still fights on; no extra action needed here in v1.

func _check_mission_end() -> void:
	var all_wiped := true
	for squad in _squads:
		if not squad.is_wiped():
			all_wiped = false
			break
	if all_wiped:
		_end_mission(false)
		return

	if _wave_controller.is_finished() and _active_enemies.is_empty():
		_end_mission(true)

func _end_mission(won: bool) -> void:
	_mission_over = true
	var safehouses_saved := 0
	for safehouse in _safehouses:
		if safehouse.is_saved():
			safehouses_saved += 1

	var surviving_squads: Array = _squads.filter(func(s: Squad): return not s.is_wiped())
	var difficulty_tier := GameState.current_difficulty_tier()
	var gold_earned := 0
	if won:
		gold_earned = _economy.mission_payout(safehouses_saved, surviving_squads, difficulty_tier)
		GameState.run_state.add_gold(gold_earned)

	# RZ-141: write each surviving squad's post-mission headcount back to the
	# roster so losses persist into the next mission rather than resetting.
	# Wiped squads need no action here — RunState.on_commander_died() already
	# removed their roster metadata via the signal connected in add_commander().
	for squad in surviving_squads:
		GameState.run_state.update_roster_meta(squad.commander.id, squad.unit_class, squad.level, squad.unit_count())

	AudioManager.play_event("mission_won" if won else "mission_lost")
	_hud.show_resolution(won, safehouses_saved, _safehouses.size(), gold_earned)
