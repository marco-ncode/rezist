## Plain result of one CombatResolver.resolve_engagement call.
## ARCHITECTURE.md §5 — pure data, no behavior.
class_name CombatResult
extends RefCounted

var damage_dealt: int
var blocked: bool
var staggered: bool
var defender_died: bool
var knockback_vector: Vector2

func _init(p_damage_dealt: int = 0, p_blocked: bool = false, p_staggered: bool = false,
		p_defender_died: bool = false, p_knockback_vector: Vector2 = Vector2.ZERO) -> void:
	damage_dealt = p_damage_dealt
	blocked = p_blocked
	staggered = p_staggered
	defender_died = p_defender_died
	knockback_vector = p_knockback_vector
