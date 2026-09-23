## Typed wrapper over data/traits.json. Modifiers are read generically by
## consumers (Economy, CombatResolver, AbilityRegistry) — never special-cased
## per trait id (ARCHITECTURE.md §11 invariant).
class_name TraitData
extends RefCounted

var _traits_by_id: Dictionary = {}

func _init(parsed_json: Dictionary) -> void:
	for trait_entry in parsed_json.get("traits", []):
		_traits_by_id[trait_entry["id"]] = trait_entry

func has_trait(trait_id: String) -> bool:
	return _traits_by_id.has(trait_id)

func get_trait(trait_id: String) -> Dictionary:
	assert(has_trait(trait_id), "Unknown trait id: %s" % trait_id)
	return _traits_by_id[trait_id]

## Returns the value of `modifier_key` for `trait_id`, or `default_value` if
## this trait doesn't define that modifier key.
func get_modifier(trait_id: String, modifier_key: String, default_value: Variant = null) -> Variant:
	if not has_trait(trait_id):
		return default_value
	var modifiers: Dictionary = get_trait(trait_id).get("modifiers", {})
	return modifiers.get(modifier_key, default_value)

func all_trait_ids() -> Array:
	return _traits_by_id.keys()
