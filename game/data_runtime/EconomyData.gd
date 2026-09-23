## Typed wrapper over data/economy.json.
class_name EconomyData
extends RefCounted

var starting_gold: int
var gold_per_safehouse: int
var squad_survival_base_gold: int
var gold_per_surviving_unit: int
var ability_unlock_cost: int
var upgrade_cost_l1_to_l2: int
var upgrade_cost_l2_to_l3: int
var trait_discounts: Dictionary

func _init(parsed_json: Dictionary) -> void:
	starting_gold = parsed_json.get("starting_gold", 0)
	gold_per_safehouse = parsed_json.get("gold_per_safehouse", 0)
	squad_survival_base_gold = parsed_json.get("squad_survival_base_gold", 0)
	gold_per_surviving_unit = parsed_json.get("gold_per_surviving_unit", 0)
	ability_unlock_cost = parsed_json.get("ability_unlock_cost", 0)
	var upgrade_cost: Dictionary = parsed_json.get("upgrade_cost", {})
	upgrade_cost_l1_to_l2 = upgrade_cost.get("l1_to_l2", 0)
	upgrade_cost_l2_to_l3 = upgrade_cost.get("l2_to_l3", 0)
	trait_discounts = parsed_json.get("trait_discounts", {})
