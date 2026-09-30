## Marksman class ability: the squad fires a synchronized, amplified burst at
## target_tile, dealing bonus damage to every enemy within `radius` of it.
## data/unit_abilities.json id: "focused_volley", effect: "focused_ranged_burst".
## Unlike Breach, the squad does not move -- this is a stationary ranged
## attack, not a repositioning ability.
class_name FocusedVolleyAbility
extends Ability

func can_activate(squad: Squad) -> bool:
	if not super.can_activate(squad):
		return false
	return squad.unit_class == "marksman"

func _apply(squad: Squad, target_tile: Vector2i, context: Dictionary) -> Array:
	var enemies: Array = context.get("enemies", [])
	var rng: SimRng = context.get("rng")
	var trait_data: TraitData = context.get("trait_data")

	if squad.units.is_empty():
		return []
	var source_unit: Unit = squad.units[0]

	var damage_mult: float = data.get("damage_multiplier", 2.0)
	var radius: int = data.get("radius", 1)
	var results: Array = []

	# ignores_partial_cover (docs/GAME_DESIGN_DOCUMENT.md's Marksman row): no
	# cover mechanic exists anywhere in the sim yet, so this data field is a
	# documented no-op for now -- there's nothing to bypass.
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

	return results
