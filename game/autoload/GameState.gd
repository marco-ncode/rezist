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

func start_new_run(p_seed: int = -1, p_difficulty_id: String = "normal") -> void:
	seed_value = p_seed if p_seed >= 0 else int(Time.get_unix_time_from_system())
	difficulty_id = p_difficulty_id
	gold = DataLoader.economy.starting_gold

func make_rng(derive_key: String = "") -> SimRng:
	var rng := SimRng.new(seed_value)
	return rng.derive(derive_key) if derive_key != "" else rng

func current_difficulty_tier() -> Dictionary:
	return DataLoader.difficulty.get_tier(difficulty_id)
