## Per-enemy-type autonomous behavior, dispatched purely off the `behavior`
## enum field on the enemy's data entry (ADR-0006) — never per-type
## branching. New enemy types are data-only additions as long as they reuse
## an existing behavior value.
##
## Targets: enemies prioritize the nearest allied Unit within `aggro_range`
## tiles; if none is in range, they path toward the nearest Safehouse. This
## single rule, combined with each type's `range`/`speed`/`behavior`, is
## enough to produce the distinct feel documented in GDD §10 without
## needing bespoke code per type.
class_name EnemyAI
extends RefCounted

const AGGRO_RANGE := 6

## Advances one enemy for one tick: attacks if a target is in range and its
## cooldown is ready, otherwise (re)paths toward its current objective and
## advances along that path.
static func tick_enemy(enemy: Enemy, delta: float, grid: TacticalGrid,
		all_units: Array, safehouses: Array, combat_context: Dictionary) -> Dictionary:
	enemy.attack_cooldown_remaining = maxf(0.0, enemy.attack_cooldown_remaining - delta)

	var target_unit: Unit = _nearest_unit_in_aggro(enemy, all_units)
	var events := {"attacked_unit": null, "attacked_safehouse": null, "result": null}

	if target_unit != null and enemy.in_range_of(target_unit.position):
		if enemy.attack_cooldown_remaining <= 0.0:
			var rng: SimRng = combat_context.get("rng")
			var trait_data: TraitData = combat_context.get("trait_data")
			var is_frontal: bool = _is_frontal_attack(enemy, target_unit)
			var unit_traits: Array = combat_context.get("unit_traits_by_id", {}).get(target_unit.id, [])
			var result: CombatResult = CombatResolver.resolve_engagement(
				enemy.to_combat_data(),
				target_unit.to_combat_data(unit_traits),
				{"is_frontal": is_frontal, "rng": rng, "trait_data": trait_data}
			)
			if not result.blocked:
				target_unit.apply_damage(result.damage_dealt)
			enemy.attack_cooldown_remaining = Enemy.ATTACK_INTERVAL
			events["attacked_unit"] = target_unit
			events["result"] = result
		return events

	var objective := _pick_objective(enemy, target_unit, safehouses)
	if objective == null:
		return events

	if not enemy.has_path() or enemy.path_goal() != objective:
		var path := AStarPathfinder.find_path(grid, enemy.position, objective, enemy.mover_type())
		enemy.set_path(path)

	if enemy.in_range_of(objective) and objective is Vector2i and _objective_is_safehouse(objective, safehouses):
		if enemy.attack_cooldown_remaining <= 0.0:
			var safehouse := _safehouse_at(objective, safehouses)
			if safehouse != null:
				safehouse.take_hit()
				enemy.attack_cooldown_remaining = Enemy.ATTACK_INTERVAL
				events["attacked_safehouse"] = safehouse
		return events

	enemy.advance(delta, grid)
	return events

static func _nearest_unit_in_aggro(enemy: Enemy, all_units: Array) -> Variant:
	var nearest: Variant = null
	var nearest_dist := AGGRO_RANGE + 1
	for unit in all_units:
		if not unit.is_alive():
			continue
		var dist: int = enemy.distance_to(unit.position)
		if dist <= AGGRO_RANGE and dist < nearest_dist:
			nearest = unit
			nearest_dist = dist
	return nearest

static func _pick_objective(enemy: Enemy, target_unit: Variant, safehouses: Array) -> Variant:
	if target_unit != null:
		return target_unit.position
	var nearest_safehouse: Safehouse = null
	var nearest_dist := 999999
	for safehouse in safehouses:
		if not safehouse.is_saved():
			continue
		var dist: int = enemy.distance_to(safehouse.position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_safehouse = safehouse
	return nearest_safehouse.position if nearest_safehouse != null else null

static func _objective_is_safehouse(objective: Vector2i, safehouses: Array) -> bool:
	return _safehouse_at(objective, safehouses) != null

static func _safehouse_at(pos: Vector2i, safehouses: Array) -> Variant:
	for safehouse in safehouses:
		if safehouse.position == pos:
			return safehouse
	return null

static func _is_frontal_attack(enemy: Enemy, unit: Unit) -> bool:
	# Simplified frontal check: an attack is frontal if the enemy is roughly
	# ahead of the unit's last movement facing. Good enough for v1 shield
	# mechanics; a full facing-arc model is tracked as future balance work.
	var to_enemy: Vector2i = enemy.position - unit.position
	return to_enemy.dot(unit.facing) >= 0
