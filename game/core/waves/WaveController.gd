## Drives timed zombie spawning for one mission from a data/waves.json
## wave_set entry. All timing/composition is pre-computed at construction
## from `rng` alone (never wall-clock or frame count) so a mission replay
## from the same seed is deterministic (TDD §5).
class_name WaveController
extends RefCounted

var total_waves: int = 0

var _wave_start_times: Array = []
var _entry_points: Array # Array[EntryPoint]
var _enemy_data: EnemyData
var _hp_mult: float
var _damage_mult: float
var _spawn_queue: Array = [] # sorted [{time, enemy_id, entry_point}]
var _next_index: int = 0
var _elapsed_time: float = 0.0
var _enemy_counter: int = 0

func _init(wave_set: Dictionary, entry_points: Array, enemy_data: EnemyData, rng: SimRng,
		hp_mult: float = 1.0, damage_mult: float = 1.0, spawn_count_mult: float = 1.0) -> void:
	_entry_points = entry_points
	_enemy_data = enemy_data
	_hp_mult = hp_mult
	_damage_mult = damage_mult

	var waves: Array = wave_set.get("waves", [])
	total_waves = waves.size()

	for wave in waves:
		var start_time: float = wave.get("start_time", 0.0)
		_wave_start_times.append(start_time)
		for spawn in wave.get("spawns", []):
			var count := maxi(1, int(round(spawn.get("count", 1) * spawn_count_mult)))
			var interval: float = spawn.get("interval", 1.0)
			var entry_tag: String = spawn.get("entry_point", "any")
			for i in count:
				var entry_point: EntryPoint = _select_entry_point(entry_tag, rng)
				_spawn_queue.append({
					"time": start_time + float(i) * interval,
					"enemy_id": spawn.get("enemy_id", ""),
					"entry_point": entry_point,
				})

	_spawn_queue.sort_custom(func(a, b): return a["time"] < b["time"])

func _select_entry_point(entry_tag: String, rng: SimRng) -> EntryPoint:
	if entry_tag == "any" or _entry_points.is_empty():
		return rng.pick(_entry_points)
	for entry_point in _entry_points:
		if entry_point.entry_type == entry_tag:
			return entry_point
	return rng.pick(_entry_points)

## Advances the spawn clock by `delta` seconds and returns newly spawned
## Enemy instances (spawned at their entry point's tile) for this tick.
func tick(delta: float) -> Array:
	_elapsed_time += delta
	var spawned: Array = []
	while _next_index < _spawn_queue.size() and _spawn_queue[_next_index]["time"] <= _elapsed_time:
		var entry: Dictionary = _spawn_queue[_next_index]
		var enemy_entry := _enemy_data.get_enemy(entry["enemy_id"])
		var enemy_id := "e%d" % _enemy_counter
		_enemy_counter += 1
		var entry_point: EntryPoint = entry["entry_point"]
		spawned.append(Enemy.new(enemy_id, enemy_entry, entry_point.position, _hp_mult, _damage_mult))
		_next_index += 1
	return spawned

func is_finished() -> bool:
	return _next_index >= _spawn_queue.size()

## 1-based index of the current/most recently started wave, for HUD display.
func current_wave_number() -> int:
	var count := 0
	for start_time in _wave_start_times:
		if start_time <= _elapsed_time:
			count += 1
	return maxi(1, count)

func elapsed_time() -> float:
	return _elapsed_time

func total_spawn_count() -> int:
	return _spawn_queue.size()
