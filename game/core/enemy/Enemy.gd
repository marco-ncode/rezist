## One zombie instance on the mission grid. Implements the same duck-typed
## interface Squad.tick() expects of a combat target: get_position(),
## is_alive(), apply_damage(int), to_combat_data().
class_name Enemy
extends RefCounted

var id: String
var enemy_type: String
var hp: int
var max_hp: int
var damage: int
var attack_type: String
var range: int
var speed: float
var behavior: String
var blocks_ranged_frontal: bool
var weak_to: Variant # String | null
var can_cross_gaps: bool
var knockback_immune: bool
var is_boss: bool
var position: Vector2i
var attack_cooldown_remaining: float = 0.0
var _path: Array = []
var _path_index: int = 0
var _path_progress: float = 0.0

const ATTACK_INTERVAL := 1.0

func _init(p_id: String, enemy_entry: Dictionary, p_position: Vector2i,
		hp_mult: float = 1.0, damage_mult: float = 1.0) -> void:
	id = p_id
	enemy_type = enemy_entry.get("id", "")
	max_hp = int(round(enemy_entry.get("hp", 1) * hp_mult))
	hp = max_hp
	damage = int(round(enemy_entry.get("damage", 0) * damage_mult))
	attack_type = enemy_entry.get("attack_type", "melee")
	range = enemy_entry.get("range", 1)
	speed = enemy_entry.get("speed", 1.0)
	behavior = enemy_entry.get("behavior", "swarm")
	blocks_ranged_frontal = enemy_entry.get("blocks_ranged_frontal", false)
	weak_to = enemy_entry.get("weak_to", null)
	can_cross_gaps = enemy_entry.get("can_cross_gaps", false)
	knockback_immune = enemy_entry.get("knockback_immune", false)
	is_boss = enemy_entry.get("is_boss", false)
	position = p_position

func get_position() -> Vector2i:
	return position

func is_alive() -> bool:
	return hp > 0

func apply_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)

func to_combat_data() -> Dictionary:
	return {
		"damage": damage,
		"attack_type": attack_type,
		"armor_type": "none",
		"blocks_ranged_frontal": blocks_ranged_frontal,
		"weak_to": weak_to,
		"knockback_immune": knockback_immune,
		"traits": [],
	}

func mover_type() -> String:
	return "leaper" if can_cross_gaps else "ground"

func set_path(path: Array) -> void:
	_path = path
	_path_index = 0
	_path_progress = 0.0

func has_path() -> bool:
	return not _path.is_empty() and _path_index < _path.size() - 1

## The final tile of the currently assigned path, or null if none is set.
func path_goal() -> Variant:
	return _path.back() if not _path.is_empty() else null

func advance(delta: float, grid: TacticalGrid) -> void:
	if not has_path():
		return
	var from: Vector2i = _path[_path_index]
	var to: Vector2i = _path[_path_index + 1]
	var cost := grid.movement_cost(from, to, mover_type())
	if cost <= 0.0:
		cost = 1.0
	_path_progress += (speed * delta) / cost
	if _path_progress >= 1.0:
		_path_progress = 0.0
		_path_index += 1
		position = to

func distance_to(target: Vector2i) -> int:
	return absi(position.x - target.x) + absi(position.y - target.y)

func in_range_of(target: Vector2i) -> bool:
	return distance_to(target) <= range
