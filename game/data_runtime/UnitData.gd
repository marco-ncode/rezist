## Typed wrapper over the parsed contents of data/units.json.
## Pure data holder (RefCounted) — safe for core/ modules to reference
## per ARCHITECTURE.md §11.
class_name UnitData
extends RefCounted

var _classes_by_id: Dictionary = {} # id -> Dictionary
var squad_base_max_size: int = 6

func _init(parsed_json: Dictionary) -> void:
	squad_base_max_size = parsed_json.get("squad_base_max_size", 6)
	for class_entry in parsed_json.get("classes", []):
		_classes_by_id[class_entry["id"]] = class_entry

func has_class(class_id: String) -> bool:
	return _classes_by_id.has(class_id)

func get_class(class_id: String) -> Dictionary:
	assert(has_class(class_id), "Unknown unit class id: %s" % class_id)
	return _classes_by_id[class_id]

## Returns the stat dictionary for a class at a given level (1-based).
func get_level_stats(class_id: String, level: int) -> Dictionary:
	var class_data := get_class(class_id)
	for level_entry in class_data.get("levels", []):
		if level_entry["level"] == level:
			return level_entry
	assert(false, "No level %d defined for class %s" % [level, class_id])
	return {}

func max_level(class_id: String) -> int:
	var class_data := get_class(class_id)
	var levels: Array = class_data.get("levels", [])
	return levels.back()["level"] if not levels.is_empty() else 1

func all_class_ids() -> Array:
	return _classes_by_id.keys()
