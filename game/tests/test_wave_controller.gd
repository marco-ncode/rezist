## Tests core/waves/WaveController.gd's active_entry_points() (RZ-068):
## drives the HUD danger indicator — "pings near active entry points during
## a wave; hidden between waves" (UX_UI.md §4).
class_name TestWaveController
extends RefCounted

static func _make_enemy_data() -> EnemyData:
	return EnemyData.new({
		"enemies": [
			{"id": "walker", "name": "Walker", "hp": 5, "damage": 1, "speed": 1.0, "behavior": "swarm", "range": 1, "attack_type": "melee", "armor_type": "none"},
		]
	})

## Wave 1 (start_time 2.0) spawns twice from entry_a (t=2.0, t=5.0). Wave 2
## (start_time 20.0) spawns once from entry_b (t=20.0). Distinct entry_type
## strings let each spawn target a specific EntryPoint deterministically —
## WaveController._select_entry_point() matches on entry_type, not id.
static func _make_wave_set() -> Dictionary:
	return {
		"waves": [
			{"start_time": 2.0, "spawns": [
				{"enemy_id": "walker", "count": 2, "interval": 3.0, "entry_point": "type_a"},
			]},
			{"start_time": 20.0, "spawns": [
				{"enemy_id": "walker", "count": 1, "interval": 0.0, "entry_point": "type_b"},
			]},
		]
	}

static func _make_entry_points() -> Array:
	return [
		EntryPoint.new("entry_a", Vector2i(0, 0), "type_a"),
		EntryPoint.new("entry_b", Vector2i(5, 5), "type_b"),
	]

static func _ids(entry_points: Array) -> Array:
	return entry_points.map(func(e: EntryPoint): return e.id)

static func run(reporter: TestReporter) -> void:
	reporter.current_file = "test_wave_controller.gd"
	_test_empty_before_first_wave(reporter)
	_test_active_during_wave_with_pending_spawn(reporter)
	_test_empty_between_waves_once_dispatched(reporter)

static func _test_empty_before_first_wave(reporter: TestReporter) -> void:
	var rng := SimRng.new(1)
	var wave_controller := WaveController.new(_make_wave_set(), _make_entry_points(), _make_enemy_data(), rng)
	reporter.expect_eq(wave_controller.active_entry_points(), [], "no entry point is active before the first wave starts (elapsed_time 0.0 < start_time 2.0)")

static func _test_active_during_wave_with_pending_spawn(reporter: TestReporter) -> void:
	var rng := SimRng.new(1)
	var wave_controller := WaveController.new(_make_wave_set(), _make_entry_points(), _make_enemy_data(), rng)
	wave_controller.tick(3.0) # elapsed_time 3.0: dispatches entry_a's t=2.0 spawn, one more (t=5.0) still pending this wave
	reporter.expect_eq(_ids(wave_controller.active_entry_points()), ["entry_a"], "entry_a stays active mid-wave while it still has a pending spawn this wave")

static func _test_empty_between_waves_once_dispatched(reporter: TestReporter) -> void:
	var rng := SimRng.new(1)
	var wave_controller := WaveController.new(_make_wave_set(), _make_entry_points(), _make_enemy_data(), rng)
	wave_controller.tick(6.0) # elapsed_time 6.0: both of wave 1's spawns (t=2.0, t=5.0) dispatched; wave 2 (t=20.0) hasn't started
	reporter.expect_eq(wave_controller.active_entry_points(), [], "no entry point is active once wave 1 finishes spawning and before wave 2 starts")
