## Discrete tile grid for one mission: tile type, elevation, occupancy,
## movement cost. Pure data + queries, no rendering (ARCHITECTURE.md §1).
## Grid shape is fixed after construction; tile contents can change
## (e.g. a safehouse tile's damage state) but width/height never do.
class_name TacticalGrid
extends RefCounted

## Movement cost of -1 means "impassable."
const IMPASSABLE := -1.0

const TILE_TYPES := ["open", "road", "rubble", "water", "stairs", "wall", "door", "roof", "sewer"]

var width: int
var height: int
var _tiles: Dictionary = {} # Vector2i -> Dictionary tile data

func _init(p_width: int, p_height: int) -> void:
	width = p_width
	height = p_height

func default_tile() -> Dictionary:
	return {
		"type": "open",
		"elevation": 0,
		"occupant_id": "",
	}

func set_tile(pos: Vector2i, tile_data: Dictionary) -> void:
	assert(_in_bounds(pos), "set_tile out of bounds: %s" % str(pos))
	_tiles[pos] = tile_data

func get_tile(pos: Vector2i) -> Dictionary:
	if not _tiles.has(pos):
		return default_tile()
	return _tiles[pos]

func _in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height

func elevation_at(pos: Vector2i) -> int:
	return get_tile(pos).get("elevation", 0)

## `mover_type` is "ground" (default infantry/zombies) or "flying"/"leaper"
## for movers that ignore certain blockers (e.g. Leapers crossing gaps).
func is_walkable(pos: Vector2i, mover_type: String = "ground") -> bool:
	if not _in_bounds(pos):
		return false
	var tile := get_tile(pos)
	var tile_type: String = tile.get("type", "open")
	if tile_type == "wall":
		return false
	if tile_type == "water" and mover_type == "ground":
		return false
	return true

func movement_cost(from: Vector2i, to: Vector2i, mover_type: String = "ground") -> float:
	if not is_walkable(to, mover_type):
		return IMPASSABLE
	var tile := get_tile(to)
	var tile_type: String = tile.get("type", "open")
	var base_cost := 1.0
	match tile_type:
		"rubble":
			base_cost = 2.0
		"water":
			base_cost = 3.0 # only reachable by non-ground movers per is_walkable
		"stairs":
			base_cost = 1.5
		_:
			base_cost = 1.0
	var elevation_delta := absi(elevation_at(to) - elevation_at(from))
	if elevation_delta > 0 and tile_type != "stairs" and mover_type != "leaper":
		# Climbing without stairs is expensive but not impossible for ground
		# movers with a small delta; Leapers ignore this cost entirely.
		base_cost += float(elevation_delta) * 1.5
	return base_cost

func neighbors(pos: Vector2i) -> Array:
	var result: Array = []
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n: Vector2i = pos + offset
		if _in_bounds(n):
			result.append(n)
	return result

## Simple Bresenham-style line-of-sight check: walks the tile line between
## `from` and `to` and fails if any intermediate tile is a `wall` at an
## elevation that would occlude the shot (same-or-higher elevation than the
## lower of the two endpoints).
func has_line_of_sight(from: Vector2i, to: Vector2i) -> bool:
	if from == to:
		return true
	var dx := to.x - from.x
	var dy := to.y - from.y
	var steps := maxi(absi(dx), absi(dy))
	var min_elevation := mini(elevation_at(from), elevation_at(to))
	for i in range(1, steps):
		var t := float(i) / float(steps)
		var sample := Vector2i(round(from.x + dx * t), round(from.y + dy * t))
		if sample == from or sample == to:
			continue
		var tile := get_tile(sample)
		if tile.get("type", "open") == "wall" and elevation_at(sample) >= min_elevation:
			return false
	return true

func set_occupant(pos: Vector2i, occupant_id: String) -> void:
	var tile := get_tile(pos)
	tile["occupant_id"] = occupant_id
	set_tile(pos, tile)

func all_positions() -> Array:
	var result: Array = []
	for x in range(width):
		for y in range(height):
			result.append(Vector2i(x, y))
	return result
