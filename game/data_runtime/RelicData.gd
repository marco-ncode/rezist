## Typed wrapper over data/relics.json.
class_name RelicData
extends RefCounted

var _relics_by_id: Dictionary = {}

func _init(parsed_json: Dictionary) -> void:
	for relic_entry in parsed_json.get("relics", []):
		_relics_by_id[relic_entry["id"]] = relic_entry

func has_relic(relic_id: String) -> bool:
	return _relics_by_id.has(relic_id)

func get_relic(relic_id: String) -> Dictionary:
	assert(has_relic(relic_id), "Unknown relic id: %s" % relic_id)
	return _relics_by_id[relic_id]

func get_effect(relic_id: String) -> Dictionary:
	return get_relic(relic_id)

func all_relic_ids() -> Array:
	return _relics_by_id.keys()
