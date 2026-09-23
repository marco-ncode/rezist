## Autoload singleton. Minimal cross-scene state holder for the vertical
## slice (M1): the active seed, difficulty, and gold. Once core/run/RunState
## and SaveManager land (docs/BACKLOG.md RZ-054/RZ-055), this autoload
## becomes the thin Node-side holder of a RunState instance rather than
## owning these fields itself — tracked so the migration is a small,
## contained change rather than a rewrite.
extends Node

var seed_value: int = 0
var difficulty_id: String = "normal"
var gold: int = 0

## District for the upcoming mission and the player's chosen squad
## deployment tiles from MissionPrep (RZ-075). MissionController regenerates
## the same grid independently from `seed_value` (determinism contract,
## TDD §5) rather than receiving it directly — only the small deployment
## decision needs to cross the MissionPrep -> Mission scene transition.
## Empty `mission_deployment_positions` means "no prep happened" and
## MissionController falls back to its own auto-placement, so Mission.tscn
## keeps working standalone (e.g. for quick manual testing in the editor).
var mission_district_id: String = "residential"
var mission_deployment_positions: Array = [] # Array[Vector2i], one per squad

func start_new_run(p_seed: int = -1, p_difficulty_id: String = "normal") -> void:
	seed_value = p_seed if p_seed >= 0 else int(Time.get_unix_time_from_system())
	difficulty_id = p_difficulty_id
	gold = DataLoader.economy.starting_gold
	mission_deployment_positions = []

func clear_mission_deployment() -> void:
	mission_deployment_positions = []

func make_rng(derive_key: String = "") -> SimRng:
	var rng := SimRng.new(seed_value)
	return rng.derive(derive_key) if derive_key != "" else rng

func current_difficulty_tier() -> Dictionary:
	return DataLoader.difficulty.get_tier(difficulty_id)
