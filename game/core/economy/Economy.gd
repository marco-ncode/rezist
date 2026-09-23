## Gold accounting: mission payout, upgrade/ability/relic costs, difficulty
## scaling. Every formula here implements docs/BALANCE.md §1 exactly — no
## number is hardcoded beyond what's already in data/economy.json and
## data/difficulty.json (ARCHITECTURE.md §8 invariant).
class_name Economy
extends RefCounted

var _economy_data: EconomyData

func _init(economy_data: EconomyData) -> void:
	_economy_data = economy_data

## `safehouses_saved`: int count. `surviving_squads`: Array[Squad].
## `difficulty_tier`: Dictionary (from DifficultyData.get_tier()).
func mission_payout(safehouses_saved: int, surviving_squads: Array, difficulty_tier: Dictionary) -> int:
	var total := safehouses_saved * _economy_data.gold_per_safehouse
	for squad in surviving_squads:
		total += squad_performance_bonus(squad)
	var gold_mult: float = difficulty_tier.get("gold_mult", 1.0)
	return int(round(total * gold_mult))

func squad_performance_bonus(squad: Squad) -> int:
	return _economy_data.squad_survival_base_gold + squad.unit_count() * _economy_data.gold_per_surviving_unit

func upgrade_cost(from_level: int, to_level: int) -> int:
	if from_level == 1 and to_level == 2:
		return _economy_data.upgrade_cost_l1_to_l2
	if from_level == 2 and to_level == 3:
		return _economy_data.upgrade_cost_l2_to_l3
	assert(false, "Unsupported upgrade level transition: %d -> %d" % [from_level, to_level])
	return 0

func ability_cost(trait_id: String = "") -> int:
	var base_cost := _economy_data.ability_unlock_cost
	return apply_trait_discount(base_cost, [trait_id], "ability")

func relic_cost(relic_data: RelicData, relic_id: String, trait_id: String = "") -> int:
	var base_cost: int = relic_data.get_relic(relic_id).get("cost", 0)
	return apply_trait_discount(base_cost, [trait_id], "relic")

## `applies_to`: "relic" | "ability" — matches trait_discounts[trait_id].applies_to.
func apply_trait_discount(base_cost: int, trait_ids: Array, applies_to: String) -> int:
	var cost := float(base_cost)
	for trait_id in trait_ids:
		if trait_id == "" or not _economy_data.trait_discounts.has(trait_id):
			continue
		var discount: Dictionary = _economy_data.trait_discounts[trait_id]
		if discount.get("applies_to", "") == applies_to:
			cost *= float(discount.get("mult", 1.0))
	return int(round(cost))
