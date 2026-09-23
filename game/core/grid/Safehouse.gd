## A structure to defend on a mission grid (GDD §11). Health is tracked as
## a small state enum, never a numeric bar (ADR-0005) — intact -> damaged ->
## burning -> collapsed, each step triggered by an unanswered zombie attack
## against the structure's tile.
class_name Safehouse
extends RefCounted

enum State { INTACT, DAMAGED, BURNING, COLLAPSED }

var id: String
var position: Vector2i
var state: State = State.INTACT

func _init(p_id: String, p_position: Vector2i) -> void:
	id = p_id
	position = p_position

## Called when an unanswered zombie attack lands on this safehouse's tile.
## Advances exactly one step per call; collapsed is terminal.
func take_hit() -> void:
	match state:
		State.INTACT:
			state = State.DAMAGED
		State.DAMAGED:
			state = State.BURNING
		State.BURNING:
			state = State.COLLAPSED
		State.COLLAPSED:
			pass # already lost, no further effect

## Counted toward mission gold payout if not collapsed — a damaged or
## burning safehouse still pays out (reduced by the economy formula's
## discretion at the call site), only a fully collapsed one pays nothing.
func is_saved() -> bool:
	return state != State.COLLAPSED
