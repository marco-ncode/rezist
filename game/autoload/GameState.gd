## Autoload singleton. Node-side holder of the active `RunState` (RZ-054),
## plus mission-scoped transient state that only needs to cross one scene
## transition (deployment tiles from MissionPrep). This autoload is the only
## place allowed to construct/replace `run_state` — everything else reads
## `GameState.run_state` directly.
extends Node

var run_state: RunState = null

## District for the upcoming mission and the player's chosen squad
## deployment tiles from MissionPrep (RZ-075). MissionController regenerates
## the same grid independently from `run_state.seed_value` (determinism
## contract, TDD §5) rather than receiving it directly — only the small
## deployment decision needs to cross the MissionPrep -> Mission scene
## transition. Empty `mission_deployment_positions` means "no prep happened"
## and MissionController falls back to its own auto-placement, so Mission.tscn
## keeps working standalone (e.g. for quick manual testing in the editor).
var mission_district_id: String = "residential"
var mission_deployment_positions: Array = [] # Array[Vector2i], one per squad

## Starts a brand new run and seeds a starting roster. There's no Main Menu
## or hero-recruitment flow yet (RZ-074/RZ-087), so the starting roster is
## the same 3 placeholder Riot squads the vertical slice always used —
## previously hardcoded inside MissionController, now recruited once here so
## permadeath and unit losses actually persist across missions instead of
## being silently reset every time a mission scene loads.
func start_new_run(p_seed: int = -1, p_difficulty_id: String = "normal") -> void:
	var seed_value := p_seed if p_seed >= 0 else int(Time.get_unix_time_from_system())
	run_state = RunState.new_run(seed_value, p_difficulty_id, DataLoader.economy.starting_gold)
	_seed_starting_roster()
	mission_deployment_positions = []

func _seed_starting_roster() -> void:
	var commander_names := ["J. Alvarez", "D. Okafor", "M. Torres"]
	for i in commander_names.size():
		var commander := Commander.new("cmdr_%d" % i, commander_names[i], Commander.DEFAULT_MAX_HP)
		run_state.add_commander(commander, "riot", 1, 4)

func clear_mission_deployment() -> void:
	mission_deployment_positions = []

func make_rng(derive_key: String = "") -> SimRng:
	var seed_value: int = run_state.seed_value if run_state != null else 0
	var rng := SimRng.new(seed_value)
	return rng.derive(derive_key) if derive_key != "" else rng

func current_difficulty_tier() -> Dictionary:
	var difficulty_id: String = run_state.difficulty_id if run_state != null else "normal"
	return DataLoader.difficulty.get_tier(difficulty_id)
