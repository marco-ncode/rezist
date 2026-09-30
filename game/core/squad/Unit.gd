## One rank-and-file soldier within a Squad. Never individually orderable by
## the player (GDD pillar 1) — Squad.tick() moves/engages units autonomously.
class_name Unit
extends RefCounted

var id: String
var class_id: String
var level: int
var hp: int
var max_hp: int
var damage: int
var reach: int
var attack_type: String # "melee" | "ranged"
var speed: float # tiles per second
var armor_type: String # "none" | "shield" | "reach"
var blocks_ranged_frontal: bool
var position: Vector2i
var facing: Vector2i = Vector2i(0, 1)
var attack_cooldown_remaining: float = 0.0

const ATTACK_INTERVAL := 1.0 # seconds between autonomous attacks, v1 constant

func _init(p_id: String, level_stats: Dictionary, class_data: Dictionary, p_position: Vector2i) -> void:
	id = p_id
	class_id = class_data.get("id", "")
	level = level_stats.get("level", 1)
	max_hp = level_stats.get("hp", 1)
	hp = max_hp
	damage = level_stats.get("damage", 0)
	reach = level_stats.get("reach", 1)
	attack_type = level_stats.get("attack_type", "melee")
	speed = level_stats.get("speed", 1.0)
	armor_type = class_data.get("armor_type", "none")
	blocks_ranged_frontal = class_data.get("blocks_ranged_frontal", false)
	position = p_position

func is_alive() -> bool:
	return hp > 0

## `relic_data` is accepted and ignored — pure signature parity with
## Commander.apply_damage() (RZ-109's Reanimation Kit), which needs it, so
## EnemyAI.tick_enemy()'s single duck-typed call site (a Unit or an exposed
## Commander, RZ-142) can pass it unconditionally without knowing which.
func apply_damage(amount: int, _relic_data: RelicData = null) -> void:
	hp = maxi(0, hp - amount)

## Dictionary shape consumed by CombatResolver as `attacker`/`defender`.
func to_combat_data(traits: Array) -> Dictionary:
	return {
		"damage": damage,
		"attack_type": attack_type,
		"armor_type": armor_type,
		"blocks_ranged_frontal": blocks_ranged_frontal,
		"weak_to": null,
		"knockback_immune": false,
		"traits": traits,
	}

func distance_to(target: Vector2i) -> int:
	return absi(position.x - target.x) + absi(position.y - target.y)

func in_range_of(target: Vector2i) -> bool:
	return distance_to(target) <= reach
