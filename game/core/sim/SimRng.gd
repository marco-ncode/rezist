## Deterministic RNG wrapper. Every source of randomness in the simulation
## (combat rolls, procgen, wave composition) must go through an instance of
## this class, seeded explicitly — never Godot's global randi()/randf().
## This is what makes a run's seed reproduce identical outcomes (TDD §5).
class_name SimRng
extends RefCounted

var _rng: RandomNumberGenerator

func _init(seed_value: int) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value

## Derives a new, independent-but-deterministic SimRng from this one, keyed
## by an arbitrary string (e.g. a campaign node id). Lets subsystems (mission
## grid gen for node "n3") reproduce their own output without consuming the
## parent RNG's stream, and without needing the full run seed stored per-node.
func derive(key: String) -> SimRng:
	var combined := "%d:%s" % [_rng.seed, key]
	return SimRng.new(hash(combined))

func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)

func randf() -> float:
	return _rng.randf()

func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)

## Returns true with probability `chance` (0.0-1.0).
func chance(chance_value: float) -> bool:
	return _rng.randf() < chance_value

## Picks a random element from a non-empty array.
func pick(array: Array) -> Variant:
	assert(not array.is_empty(), "SimRng.pick called with empty array")
	return array[_rng.randi_range(0, array.size() - 1)]

func get_seed() -> int:
	return _rng.seed
