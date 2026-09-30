## Barricade class ability: the squad advances in a straight line toward
## target_tile, dealing bonus damage to every enemy on a tile along that
## line, then moves there. data/unit_abilities.json id: "line_charge",
## effect: "line_impale_charge".
class_name LineChargeAbility
extends Ability

func can_activate(squad: Squad) -> bool:
	if not super.can_activate(squad):
		return false
	return squad.unit_class == "barricade"

func _apply(squad: Squad, target_tile: Vector2i, context: Dictionary) -> Array:
	var grid: TacticalGrid = context.get("grid")
	var enemies: Array = context.get("enemies", [])
	var rng: SimRng = context.get("rng")
	var trait_data: TraitData = context.get("trait_data")

	if squad.units.is_empty():
		return []
	var source_unit: Unit = squad.units[0]
	var origin: Vector2i = source_unit.position
	var delta: Vector2i = target_tile - origin
	var direction := Vector2i(_sign_i(delta.x), _sign_i(delta.y))
	if direction == Vector2i.ZERO:
		return []

	var line_length: int = data.get("line_length", 3)
	var damage_mult: float = data.get("damage_multiplier", 1.3)
	var line_tiles: Array = []
	var far_tile := origin
	for step in range(1, line_length + 1):
		far_tile = origin + direction * step
		line_tiles.append(far_tile)

	var results: Array = []
	# knockback_strength (docs/GAME_DESIGN_DOCUMENT.md's Barricade row): no
	# knockback/displacement system reads CombatResult.knockback_vector for
	# enemies yet, so this data field is a documented no-op for now, same as
	# Breach's own unread knockback intent.
	for enemy in enemies:
		if not enemy.is_alive() or not line_tiles.has(enemy.get_position()):
			continue
		var attacker_data := source_unit.to_combat_data(squad.commander.traits())
		attacker_data["damage"] = int(attacker_data["damage"] * damage_mult)
		var result: CombatResult = CombatResolver.resolve_engagement(
			attacker_data, enemy.to_combat_data(), {"is_frontal": true, "rng": rng, "trait_data": trait_data}
		)
		if not result.blocked:
			enemy.apply_damage(result.damage_dealt)
		results.append(result)

	squad.order_move_to(far_tile, grid)
	return results

## Hand-written sign (not a built-in call) — same caution RZ-143 established
## after Vector2i.dot() turned out not to exist: verify, don't assume, an
## unfamiliar Godot API is available before depending on it.
static func _sign_i(n: int) -> int:
	if n > 0:
		return 1
	if n < 0:
		return -1
	return 0
