## Generates a mission's TacticalGrid + entry points + safehouses from a
## seeded SimRng and a data/districts.json entry. Deterministic: the same
## SimRng seed and district always produce byte-identical output (TDD §5),
## verified by tests/test_procgen_determinism.gd.
##
## Guarantees at least one walkable path from every entry point to at least
## one safehouse (ARCHITECTURE.md §14 invariant) via a post-generation
## reachability repair pass.
class_name MapGenerator
extends RefCounted

const WALL_CHANCE := 0.14
const RUBBLE_CHANCE := 0.08
const ELEVATION_CHANCE_BY_VARIANCE := {"low": 0.05, "medium": 0.12, "high": 0.20}

## Returns { "grid": TacticalGrid, "entry_points": Array[EntryPoint], "safehouses": Array[Safehouse] }.
static func generate(rng: SimRng, district_entry: Dictionary) -> Dictionary:
	var width: int = district_entry.get("grid_width", 16)
	var height: int = district_entry.get("grid_height", 16)
	var grid := TacticalGrid.new(width, height)

	var elevation_chance: float = ELEVATION_CHANCE_BY_VARIANCE.get(
		district_entry.get("elevation_variance", "low"), 0.05
	)

	var wall_positions: Array = []
	for pos in grid.all_positions():
		var tile := grid.default_tile()
		if _is_border(pos, width, height):
			grid.set_tile(pos, tile)
			continue
		if rng.chance(WALL_CHANCE):
			tile["type"] = "wall"
			wall_positions.append(pos)
		elif rng.chance(RUBBLE_CHANCE):
			tile["type"] = "rubble"
		if rng.chance(elevation_chance):
			tile["elevation"] = 1
		grid.set_tile(pos, tile)

	var safehouse_range: Array = district_entry.get("safehouse_count_range", [2, 3])
	var safehouse_count := rng.randi_range(int(safehouse_range[0]), int(safehouse_range[1]))
	var entry_range: Array = district_entry.get("entry_point_count_range", [2, 3])
	var entry_count := rng.randi_range(int(entry_range[0]), int(entry_range[1]))

	var open_interior := _open_interior_positions(grid)
	var safehouses: Array = []
	for i in safehouse_count:
		if open_interior.is_empty():
			break
		var idx := rng.randi_range(0, open_interior.size() - 1)
		var pos: Vector2i = open_interior[idx]
		open_interior.remove_at(idx)
		safehouses.append(Safehouse.new("sh%d" % i, pos))

	var border_positions := _border_positions(width, height)
	var entry_points: Array = []
	for i in entry_count:
		if border_positions.is_empty():
			break
		var idx := rng.randi_range(0, border_positions.size() - 1)
		var pos: Vector2i = border_positions[idx]
		border_positions.remove_at(idx)
		entry_points.append(EntryPoint.new("ep%d" % i, pos, "gate"))

	_ensure_reachability(grid, entry_points, safehouses, wall_positions)

	return {"grid": grid, "entry_points": entry_points, "safehouses": safehouses}

static func _is_border(pos: Vector2i, width: int, height: int) -> bool:
	return pos.x == 0 or pos.y == 0 or pos.x == width - 1 or pos.y == height - 1

static func _border_positions(width: int, height: int) -> Array:
	var result: Array = []
	for x in range(width):
		result.append(Vector2i(x, 0))
		result.append(Vector2i(x, height - 1))
	for y in range(1, height - 1):
		result.append(Vector2i(0, y))
		result.append(Vector2i(width - 1, y))
	return result

static func _open_interior_positions(grid: TacticalGrid) -> Array:
	var result: Array = []
	for pos in grid.all_positions():
		if _is_border(pos, grid.width, grid.height):
			continue
		if grid.get_tile(pos).get("type", "open") == "open":
			result.append(pos)
	return result

## Removes the nearest blocking walls between any unreachable entry point
## and the nearest safehouse until a path exists, up to a bounded number of
## repairs (deterministic given wall_positions' construction order).
static func _ensure_reachability(grid: TacticalGrid, entry_points: Array, safehouses: Array, wall_positions: Array) -> void:
	if safehouses.is_empty() or entry_points.is_empty():
		return
	var max_repairs := wall_positions.size()
	for entry_point in entry_points:
		var attempts := 0
		while not _can_reach_any(grid, entry_point.position, safehouses) and attempts < max_repairs:
			var removed := _remove_nearest_wall(grid, entry_point.position, wall_positions)
			if not removed:
				break
			attempts += 1

static func _can_reach_any(grid: TacticalGrid, from: Vector2i, safehouses: Array) -> bool:
	for safehouse in safehouses:
		if not AStarPathfinder.find_path(grid, from, safehouse.position, "ground").is_empty():
			return true
	return false

static func _remove_nearest_wall(grid: TacticalGrid, from: Vector2i, wall_positions: Array) -> bool:
	if wall_positions.is_empty():
		return false
	var nearest_index := 0
	var nearest_dist := 999999
	for i in wall_positions.size():
		var pos: Vector2i = wall_positions[i]
		var dist: int = absi(pos.x - from.x) + absi(pos.y - from.y)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_index = i
	var pos: Vector2i = wall_positions[nearest_index]
	var tile := grid.get_tile(pos)
	tile["type"] = "open"
	grid.set_tile(pos, tile)
	wall_positions.remove_at(nearest_index)
	return true
