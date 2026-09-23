## Typed wrapper over data/enemies.json.
class_name EnemyData
extends RefCounted

var _enemies_by_id: Dictionary = {}

func _init(parsed_json: Dictionary) -> void:
	for enemy_entry in parsed_json.get("enemies", []):
		_enemies_by_id[enemy_entry["id"]] = enemy_entry

func has_enemy(enemy_id: String) -> bool:
	return _enemies_by_id.has(enemy_id)

func get_enemy(enemy_id: String) -> Dictionary:
	assert(has_enemy(enemy_id), "Unknown enemy id: %s" % enemy_id)
	return _enemies_by_id[enemy_id]

func all_enemy_ids() -> Array:
	return _enemies_by_id.keys()
