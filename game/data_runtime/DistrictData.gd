## Typed wrapper over data/districts.json + data/biomes.json.
class_name DistrictData
extends RefCounted

var _districts_by_id: Dictionary = {}
var _biomes_by_id: Dictionary = {}

func _init(districts_json: Dictionary, biomes_json: Dictionary) -> void:
	for district_entry in districts_json.get("districts", []):
		_districts_by_id[district_entry["id"]] = district_entry
	for biome_entry in biomes_json.get("biomes", []):
		_biomes_by_id[biome_entry["id"]] = biome_entry

func has_district(district_id: String) -> bool:
	return _districts_by_id.has(district_id)

func get_district(district_id: String) -> Dictionary:
	assert(has_district(district_id), "Unknown district id: %s" % district_id)
	return _districts_by_id[district_id]

func get_biome(biome_id: String) -> Dictionary:
	return _biomes_by_id.get(biome_id, {})

func all_district_ids() -> Array:
	return _districts_by_id.keys()
