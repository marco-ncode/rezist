## Resolves one attacker-vs-defender engagement. Pure function (ADR-0006):
## every rule (frontal shield block, reach bonus vs weak_to, trait modifiers)
## reads generic data fields — no per-class/per-enemy branching. Adding a
## new allied class or enemy type never requires touching this file, only
## new entries in data/units.json / data/enemies.json (ARCHITECTURE.md §5).
##
## Formula reference: docs/BALANCE.md §6.
class_name CombatResolver
extends RefCounted

const BASE_STAGGER_CHANCE := 0.10
const MIN_DAMAGE := 1

## attacker / defender: Dictionary with at least:
##   damage: int, attack_type: "melee"|"ranged", armor_type: "none"|"shield"|"reach"
##   traits: Array[String] (trait ids applied to the owning commander, may be empty)
##   blocks_ranged_frontal: bool, weak_to: String|null, knockback_immune: bool (defender only)
## context: Dictionary with:
##   is_frontal: bool — whether this attack lands on the defender's front arc
##   rng: SimRng — required for the stagger roll (never call global randf())
##   trait_data: TraitData — for modifier lookups
static func resolve_engagement(attacker: Dictionary, defender: Dictionary, context: Dictionary) -> CombatResult:
	var trait_data: TraitData = context.get("trait_data")
	var rng: SimRng = context.get("rng")
	assert(rng != null, "CombatResolver.resolve_engagement requires context.rng")

	var is_frontal: bool = context.get("is_frontal", true)
	if attacker.get("attack_type", "melee") == "ranged" \
			and defender.get("blocks_ranged_frontal", false) \
			and is_frontal:
		return CombatResult.new(0, true, false, false)

	var base_damage: float = attacker.get("damage", 0)

	# Reach-beats-melee RPS bonus (ADR-0006): a reach-armed attacker deals
	# bonus damage to a defender explicitly marked weak to reach weapons.
	if attacker.get("armor_type", "none") == "reach" and defender.get("weak_to", null) == "reach":
		base_damage *= 1.5

	base_damage *= _aggregate_trait_mult(attacker.get("traits", []), "damage_dealt_mult", trait_data)
	base_damage *= _aggregate_trait_mult(defender.get("traits", []), "damage_taken_mult", trait_data)

	var damage := maxi(MIN_DAMAGE, roundi(base_damage))

	var stagger_chance := BASE_STAGGER_CHANCE
	for trait_id in attacker.get("traits", []):
		stagger_chance += trait_data.get_modifier(trait_id, "stagger_chance_add", 0.0) if trait_data else 0.0

	var staggered := rng.chance(stagger_chance) and not defender.get("knockback_immune", false)

	return CombatResult.new(damage, false, staggered, false)

## Multiplies together every modifier value found for `modifier_key` across
## the given trait ids, defaulting missing/unset modifiers to 1.0 (no-op).
static func _aggregate_trait_mult(trait_ids: Array, modifier_key: String, trait_data: TraitData) -> float:
	if trait_data == null:
		return 1.0
	var result := 1.0
	for trait_id in trait_ids:
		result *= trait_data.get_modifier(trait_id, modifier_key, 1.0)
	return result
