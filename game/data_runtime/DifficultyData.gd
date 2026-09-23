## Typed wrapper over data/difficulty.json.
class_name DifficultyData
extends RefCounted

var _tiers_by_id: Dictionary = {}

func _init(parsed_json: Dictionary) -> void:
	for tier_entry in parsed_json.get("tiers", []):
		_tiers_by_id[tier_entry["id"]] = tier_entry

func has_tier(tier_id: String) -> bool:
	return _tiers_by_id.has(tier_id)

func get_tier(tier_id: String) -> Dictionary:
	assert(has_tier(tier_id), "Unknown difficulty tier id: %s" % tier_id)
	return _tiers_by_id[tier_id]

func all_tier_ids() -> Array:
	return _tiers_by_id.keys()
