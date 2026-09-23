## Riot class ability: the squad jumps down from an elevation tile onto
## `target_tile`, dealing amplified damage + knockback to every enemy there.
## data/unit_abilities.json id: "breach", effect: "plunge_damage_knockback".
class_name BreachAbility
extends Ability

func can_activate(squad: Squad) -> bool:
	if not super.can_activate(squad):
		return false
	return squad.unit_class == "riot"

func _apply(squad: Squad, target_tile: Vector2i, context: Dictionary) -> Array:
	var grid: TacticalGrid = context.get("grid")
	var enemies: Array = context.get("enemies", [])
	var rng: SimRng = context.get("rng")
	var trait_data: TraitData = context.get("trait_data")

	if squad.units.is_empty():
		return []
	var source_unit: Unit = squad.units[0]
	var elevation_delta: int = grid.elevation_at(source_unit.position) - grid.elevation_at(target_tile)
	var min_delta: int = data.get("min_elevation_delta", 1)
	if elevation_delta < min_delta:
		return []

	var damage_mult: float = data.get("damage_multiplier", 1.5)
	var radius: int = data.get("radius", 1)
	var results: Array = []

	for enemy in enemies:
		if not enemy.is_alive():
			continue
		var dist: int = maxi(absi(enemy.get_position().x - target_tile.x), absi(enemy.get_position().y - target_tile.y))
		if dist > radius:
			continue
		var attacker_data := source_unit.to_combat_data(squad.commander.traits())
		attacker_data["damage"] = int(attacker_data["damage"] * damage_mult)
		var result: CombatResult = CombatResolver.resolve_engagement(
			attacker_data, enemy.to_combat_data(), {"is_frontal": true, "rng": rng, "trait_data": trait_data}
		)
		if not result.blocked:
			enemy.apply_damage(result.damage_dealt)
		results.append(result)

	squad.order_move_to(target_tile, grid)
	return results
