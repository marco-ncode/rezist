## A squad's named leader. Permadeath is tied exclusively to the Commander
## (ARCHITECTURE.md §4) — losing rank-and-file Units never ends a squad by
## itself; only the commander's death does.
class_name Commander
extends RefCounted

signal died(commander: Commander)

## v1 placeholder baseline commander HP (docs/BALANCE.md doesn't cover
## commanders yet — no per-class/per-hero variance exists). Used wherever a
## fresh Commander needs default HP: MissionController spawning a new
## mission's squads, and RunState.from_save_dict() reconstructing a
## commander after a save/load (a run's save granularity is campaign-map
## level, ADR-0007 — commander HP isn't persisted, they're full-HP whenever
## a new mission starts).
const DEFAULT_MAX_HP := 20

var id: String
var display_name: String
var trait_id: String = ""
var relic_id: String = ""
var hp: int
var max_hp: int
var alive: bool = true

## RZ-142: last-stand combat. Once a squad's rank-and-file are all dead
## (Squad.commander_lost), the commander stands alone at `position` and
## becomes a valid EnemyAI target — duck-typed the same way Unit/Enemy are
## (get position via the `position` field, `is_alive()`, `apply_damage()`,
## `to_combat_data()`). By default the commander does not fight back
## (`damage: 0` below) per GDD's "commander fights on alone" rule — only
## the (not yet implemented) Mountain trait changes that.
var position: Vector2i = Vector2i.ZERO
var facing: Vector2i = Vector2i(0, 1)

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

## Restores alive/hp state directly, without emitting `died` — used only by
## RunState.from_save_dict() when reconstructing a commander from a save.
## die() is the live-gameplay path and must keep emitting the signal so
## RunState.on_commander_died() reacts to an in-mission permadeath; this is
## the load-time path, where the caller (RunState) is doing that same
## bookkeeping itself as it rebuilds the roster.
func restore_state(p_alive: bool) -> void:
	alive = p_alive
	hp = 0 if not p_alive else max_hp

func traits() -> Array:
	return [trait_id] if trait_id != "" else []

func is_alive() -> bool:
	return alive

## Dictionary shape consumed by CombatResolver as a `defender` — matches
## Unit.to_combat_data()'s shape so EnemyAI can target an exposed commander
## with no special-casing (ADR-0006).
func to_combat_data(p_traits: Array) -> Dictionary:
	return {
		"damage": 0,
		"attack_type": "melee",
		"armor_type": "none",
		"blocks_ranged_frontal": false,
		"weak_to": null,
		"knockback_immune": false,
		"traits": p_traits,
	}
