## A zombie arrival point on the mission grid (subway stairs, storm drain,
## breached gate, collapsed bridge). Bad North equivalent: longship landing.
class_name EntryPoint
extends RefCounted

var id: String
var position: Vector2i
var entry_type: String # "subway" | "drain" | "bridge" | "gate"

func _init(p_id: String, p_position: Vector2i, p_entry_type: String = "gate") -> void:
	id = p_id
	position = p_position
	entry_type = p_entry_type
