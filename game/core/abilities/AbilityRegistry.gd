## Maps ability ids (from data/unit_abilities.json) to their Ability
## implementation. DataLoader calls has_implementation() for every ability
## the data declares and fails boot if one is missing (ARCHITECTURE.md §6
## invariant) — this keeps "data declares an ability with no code behind it"
## from silently shipping.
class_name AbilityRegistry
extends RefCounted

# effect enum (schemas/unit_abilities.schema.json) -> implementing class
const IMPLEMENTED_EFFECTS := ["plunge_damage_knockback"]
# Not yet implemented in code (tracked as RZ-048 in docs/BACKLOG.md):
#   "focused_ranged_burst" (Focused Volley), "line_impale_charge" (Line Charge)

var _abilities: Dictionary = {} # ability id -> Ability instance

func _init(ability_data: AbilityData) -> void:
	for ability_id in ability_data.all_ability_ids():
		var entry := ability_data.get_ability(ability_id)
		var effect: String = entry.get("effect", "")
		match effect:
			"plunge_damage_knockback":
				_abilities[ability_id] = BreachAbility.new(ability_id, entry)
			_:
				pass # unimplemented effect; validated separately at boot

func has_implementation(effect: String) -> bool:
	return effect in IMPLEMENTED_EFFECTS

func get_ability(ability_id: String) -> Ability:
	assert(_abilities.has(ability_id), "No Ability implementation registered for id: %s" % ability_id)
	return _abilities[ability_id]

func has_ability(ability_id: String) -> bool:
	return _abilities.has(ability_id)
