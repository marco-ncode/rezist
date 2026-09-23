## A group of Units under one Commander — the player's sole unit of command
## (GDD pillar 1). The player only ever calls order_move_to(); everything
## else (formation spread, autonomous engagement, advancing) happens inside
## tick(). ARCHITECTURE.md §4.
##
## Enemies passed into tick() via combat_context are duck-typed: any object
## exposing get_position()->Vector2i, is_alive()->bool, apply_damage(int),
## to_combat_data()->Dictionary works (core/enemy/Enemy.gd implements this).
class_name Squad
extends RefCounted

signal wiped(squad: Squad)
signal commander_lost(squad: Squad)

const ATTACK_INTERVAL := Unit.ATTACK_INTERVAL

var id: String
var commander: Commander
var unit_class: String
var level: int
var units: Array = [] # Array[Unit]
var base_max_size: int
var _unit_paths: Dictionary = {} # unit.id -> {"path": Array, "index": int, "progress": float}
var ability_cooldown_remaining: float = 0.0

func _init(p_id: String, p_commander: Commander, p_unit_class: String, p_level: int,
		unit_data: UnitData, spawn_positions: Array) -> void:
	id = p_id
	commander = p_commander
	unit_class = p_unit_class
	level = p_level
	base_max_size = unit_data.squad_base_max_size

	commander.died.connect(_on_commander_died)

	var class_data := unit_data.get_unit_class(p_unit_class)
	var level_stats := unit_data.get_level_stats(p_unit_class, p_level)
	for i in spawn_positions.size():
		var unit := Unit.new("%s_u%d" % [p_id, i], level_stats, class_data, spawn_positions[i])
		units.append(unit)

func max_size(trait_data: TraitData = null, relic_bonus: int = 0) -> int:
	var bonus := 0
	if trait_data != null:
		bonus += int(trait_data.get_modifier(commander.trait_id, "squad_max_size_add", 0))
	return base_max_size + bonus + relic_bonus

func unit_count() -> int:
	return units.size()

func is_wiped() -> bool:
	return not commander.alive

## The player's only command: move this squad toward `target_tile`. Units
## fan out into a formation around it and path there autonomously.
## Uses AStarPathfinder directly (its API is entirely static).
func order_move_to(target_tile: Vector2i, grid: TacticalGrid) -> void:
	var destinations := _formation_tiles(target_tile, grid, units.size())
	for i in units.size():
		var unit: Unit = units[i]
		var dest: Vector2i = destinations[i] if i < destinations.size() else target_tile
		var path: Array = AStarPathfinder.find_path(grid, unit.position, dest, "ground")
		_unit_paths[unit.id] = {"path": path, "index": 0, "progress": 0.0}

func _formation_tiles(center: Vector2i, grid: TacticalGrid, count: int) -> Array:
	var result: Array = []
	var seen: Dictionary = {}
	var radius := 0
	while result.size() < count and radius <= maxi(grid.width, grid.height):
		for x in range(center.x - radius, center.x + radius + 1):
			for y in range(center.y - radius, center.y + radius + 1):
				var pos := Vector2i(x, y)
				if seen.has(pos):
					continue
				seen[pos] = true
				if maxi(absi(pos.x - center.x), absi(pos.y - center.y)) != radius:
					continue
				if grid.is_walkable(pos, "ground"):
					result.append(pos)
		radius += 1
	return result

## Advances autonomous behavior for one simulation tick: move along assigned
## paths, or attack the nearest in-range enemy if one exists.
func tick(delta: float, grid: TacticalGrid, combat_context: Dictionary) -> void:
	var enemies: Array = combat_context.get("enemies", [])
	var rng: SimRng = combat_context.get("rng")
	var trait_data: TraitData = combat_context.get("trait_data")
	var traits := commander.traits()

	for unit in units:
		if not unit.is_alive():
			continue
		unit.attack_cooldown_remaining = maxf(0.0, unit.attack_cooldown_remaining - delta)

		var target = _find_nearest_enemy_in_range(unit, enemies)
		if target != null:
			if unit.attack_cooldown_remaining <= 0.0:
				var result: CombatResult = CombatResolver.resolve_engagement(
					unit.to_combat_data(traits),
					target.to_combat_data(),
					{"is_frontal": true, "rng": rng, "trait_data": trait_data}
				)
				if not result.blocked:
					target.apply_damage(result.damage_dealt)
				unit.attack_cooldown_remaining = ATTACK_INTERVAL
		else:
			_advance_unit(unit, delta, grid)

	_prune_dead_units()

func _find_nearest_enemy_in_range(unit: Unit, enemies: Array) -> Variant:
	var nearest = null
	var nearest_dist := 999999
	for enemy in enemies:
		if not enemy.is_alive():
			continue
		var dist: int = unit.distance_to(enemy.get_position())
		if dist <= unit.reach and dist < nearest_dist:
			nearest = enemy
			nearest_dist = dist
	return nearest

func _advance_unit(unit: Unit, delta: float, grid: TacticalGrid) -> void:
	if not _unit_paths.has(unit.id):
		return
	var path_state: Dictionary = _unit_paths[unit.id]
	var path: Array = path_state["path"]
	var index: int = path_state["index"]
	if path.is_empty() or index >= path.size() - 1:
		_unit_paths.erase(unit.id)
		return

	var from: Vector2i = path[index]
	var to: Vector2i = path[index + 1]
	var cost := grid.movement_cost(from, to, "ground")
	if cost <= 0.0:
		cost = 1.0

	path_state["progress"] += (unit.speed * delta) / cost
	if path_state["progress"] >= 1.0:
		path_state["progress"] = 0.0
		path_state["index"] += 1
		unit.position = to
		unit.facing = to - from

	_unit_paths[unit.id] = path_state

func _prune_dead_units() -> void:
	units = units.filter(func(u: Unit): return u.is_alive())
	if units.is_empty() and commander.alive:
		commander_lost.emit(self)

func _on_commander_died(_commander: Commander) -> void:
	wiped.emit(self)
