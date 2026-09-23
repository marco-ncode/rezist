## Autoload singleton. Loads every data/*.json file at boot, wraps each in
## its data_runtime typed class, and exposes typed lookup APIs to the rest
## of the game (TDD §4). This is the ONLY class allowed to read data/ off
## disk — everything else consumes the typed accessors below.
##
## Path resolution note: data/ and schemas/ live one directory above the
## Godot project root (game/) by design (ADR-0003 — data must be editable
## and validatable by tools/validate_data.py without opening the editor).
## We resolve the repo root at runtime via ProjectSettings.globalize_path
## and read plain OS files. This works when running from source (the
## documented `godot --path game` workflow) or the editor; a packaged
## export needs data/ bundled explicitly — tracked as RZ-137/RZ-138 in
## docs/BACKLOG.md.
extends Node

var units: UnitData
var enemies: EnemyData
var abilities: AbilityData
var traits: TraitData
var relics: RelicData
var economy: EconomyData
var difficulty: DifficultyData
var districts: DistrictData
var waves: WaveData
var campaign_params: CampaignParamsData
var audio_events: Dictionary = {} # event_id -> {"bus": String, "description": String}

var ability_registry: AbilityRegistry

var _data_dir: String

func _ready() -> void:
	_data_dir = _resolve_data_dir()
	_load_all()
	_validate_ability_implementations()

func _resolve_data_dir() -> String:
	var project_root := ProjectSettings.globalize_path("res://")
	var repo_root := project_root.trim_suffix("/").get_base_dir()
	return repo_root.path_join("data")

func _read_json(filename: String) -> Dictionary:
	var path := _data_dir.path_join(filename)
	var file := FileAccess.open(path, FileAccess.READ)
	assert(file != null, "DataLoader: could not open %s" % path)
	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	assert(parsed is Dictionary, "DataLoader: %s did not parse to a JSON object" % filename)
	return parsed

func _load_all() -> void:
	units = UnitData.new(_read_json("units.json"))
	enemies = EnemyData.new(_read_json("enemies.json"))
	abilities = AbilityData.new(_read_json("unit_abilities.json"))
	traits = TraitData.new(_read_json("traits.json"))
	relics = RelicData.new(_read_json("relics.json"))
	economy = EconomyData.new(_read_json("economy.json"))
	difficulty = DifficultyData.new(_read_json("difficulty.json"))
	districts = DistrictData.new(_read_json("districts.json"), _read_json("biomes.json"))
	waves = WaveData.new(_read_json("waves.json"))
	campaign_params = CampaignParamsData.new(_read_json("campaign_nodes.json"))

	var audio_json := _read_json("audio_events.json")
	for event_entry in audio_json.get("events", []):
		audio_events[event_entry["id"]] = event_entry

	ability_registry = AbilityRegistry.new(abilities)

func _validate_ability_implementations() -> void:
	for ability_id in abilities.all_ability_ids():
		var entry := abilities.get_ability(ability_id)
		var effect: String = entry.get("effect", "")
		assert(
			ability_registry.has_implementation(effect),
			"DataLoader: ability '%s' declares effect '%s' with no registered implementation" % [ability_id, effect]
		)

func make_economy() -> Economy:
	return Economy.new(economy)
