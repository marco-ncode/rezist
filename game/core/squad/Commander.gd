## A squad's named leader. Permadeath is tied exclusively to the Commander
## (ARCHITECTURE.md §4) — losing rank-and-file Units never ends a squad by
## itself; only the commander's death does.
class_name Commander
extends RefCounted

signal died(commander: Commander)

var id: String
var display_name: String
var trait_id: String = ""
var relic_id: String = ""
var hp: int
var max_hp: int
var alive: bool = true

func _init(p_id: String, p_display_name: String, p_max_hp: int, p_trait_id: String = "", p_relic_id: String = "") -> void:
	id = p_id
	display_name = p_display_name
	max_hp = p_max_hp
	hp = p_max_hp
	trait_id = p_trait_id
	relic_id = p_relic_id

func apply_damage(amount: int) -> void:
	if not alive:
		return
	hp = maxi(0, hp - amount)
	if hp == 0:
		die()

func die() -> void:
	if not alive:
		return
	alive = false
	hp = 0
	died.emit(self)

func traits() -> Array:
	return [trait_id] if trait_id != "" else []
