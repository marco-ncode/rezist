## Typed wrapper over data/waves.json.
class_name WaveData
extends RefCounted

var _wave_sets_by_id: Dictionary = {}

func _init(parsed_json: Dictionary) -> void:
	for wave_set_entry in parsed_json.get("wave_sets", []):
		_wave_sets_by_id[wave_set_entry["id"]] = wave_set_entry

func has_wave_set(wave_set_id: String) -> bool:
	return _wave_sets_by_id.has(wave_set_id)

func get_wave_set(wave_set_id: String) -> Dictionary:
	assert(has_wave_set(wave_set_id), "Unknown wave_set id: %s" % wave_set_id)
	return _wave_sets_by_id[wave_set_id]
