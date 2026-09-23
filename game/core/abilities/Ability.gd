## Base class for a squad-triggerable ability (Breach, Focused Volley, Line
## Charge, ...). Subclasses implement `_apply` only; cooldown bookkeeping and
## trait modifiers (Energetic, Heavy Load, Skillful) are handled generically
## here so new abilities never duplicate that logic (ARCHITECTURE.md §6).
class_name Ability
extends RefCounted

var id: String
var data: Dictionary # the raw data/unit_abilities.json entry

func _init(p_id: String, p_data: Dictionary) -> void:
	id = p_id
	data = p_data

func can_activate(squad: Squad) -> bool:
	return squad.ability_cooldown_remaining <= 0.0 and squad.commander.alive

## `context` must include: grid (TacticalGrid), enemies (Array), rng (SimRng),
## trait_data (TraitData).
func activate(squad: Squad, target_tile: Vector2i, context: Dictionary) -> Array:
	if not can_activate(squad):
		return []
	var trait_data: TraitData = context.get("trait_data")
	var cooldown: float = data.get("cooldown_seconds", 10.0)
	if trait_data != null:
		cooldown *= trait_data.get_modifier(squad.commander.trait_id, "ability_cooldown_mult", 1.0)
	squad.ability_cooldown_remaining = cooldown
	return _apply(squad, target_tile, context)

func cooldown_remaining(squad: Squad) -> float:
	return squad.ability_cooldown_remaining

## Subclasses override this to implement the ability's actual effect and
## return the list of CombatResult objects it produced (for FX/audio hooks).
func _apply(_squad: Squad, _target_tile: Vector2i, _context: Dictionary) -> Array:
	return []
