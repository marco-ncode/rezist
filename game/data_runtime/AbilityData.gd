## Typed wrapper over data/unit_abilities.json.
class_name AbilityData
extends RefCounted

var _abilities_by_id: Dictionary = {}

func _init(parsed_json: Dictionary) -> void:
	for ability_entry in parsed_json.get("abilities", []):
		_abilities_by_id[ability_entry["id"]] = ability_entry

func has_ability(ability_id: String) -> bool:
	return _abilities_by_id.has(ability_id)

func get_ability(ability_id: String) -> Dictionary:
	assert(has_ability(ability_id), "Unknown ability id: %s" % ability_id)
	return _abilities_by_id[ability_id]

func all_ability_ids() -> Array:
	return _abilities_by_id.keys()
