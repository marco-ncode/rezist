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

## Usable either on a fresh cooldown, or while on cooldown if a Heavy Load
## charge (RZ-108) is still available from the current cycle.
func can_activate(squad: Squad) -> bool:
	if not squad.commander.alive:
		return false
	return squad.ability_cooldown_remaining <= 0.0 or squad.ability_charges_remaining > 0

## `context` must include: grid (TacticalGrid), enemies (Array), rng (SimRng),
## trait_data (TraitData).
func activate(squad: Squad, target_tile: Vector2i, context: Dictionary) -> Array:
	if not can_activate(squad):
		return []
	var trait_data: TraitData = context.get("trait_data")
	# Only a fresh cycle (cooldown already at 0) restarts the cooldown and
	# grants this cycle's Heavy Load charges; an activation spent on a
	# carried-over charge consumes it without touching the cooldown that's
	# already counting down (RZ-108 — see core/squad/Squad.gd's field doc).
	if squad.ability_cooldown_remaining <= 0.0:
		var cooldown: float = data.get("cooldown_seconds", 10.0)
		if trait_data != null:
			cooldown *= trait_data.get_modifier(squad.commander.trait_id, "ability_cooldown_mult", 1.0)
			squad.ability_charges_remaining = int(trait_data.get_modifier(squad.commander.trait_id, "ability_extra_uses", 0))
		else:
			squad.ability_charges_remaining = 0
		squad.ability_cooldown_remaining = cooldown
	else:
		squad.ability_charges_remaining -= 1
	return _apply(squad, target_tile, context)

func cooldown_remaining(squad: Squad) -> float:
	return squad.ability_cooldown_remaining

## Subclasses override this to implement the ability's actual effect and
## return the list of CombatResult objects it produced (for FX/audio hooks).
func _apply(_squad: Squad, _target_tile: Vector2i, _context: Dictionary) -> Array:
	return []
