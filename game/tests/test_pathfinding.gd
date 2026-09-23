## Tests core/pathfinding/AStarPathfinder.gd against core/grid/TacticalGrid.gd.
## Run via game/tests/run_tests.gd.
class_name TestPathfinding
extends RefCounted

static func run(reporter: TestReporter) -> void:
	reporter.current_file = "test_pathfinding.gd"
	_test_simple_path(reporter)
	_test_avoids_walls(reporter)
	_test_unreachable_returns_empty(reporter)
	_test_path_tiles_are_adjacent(reporter)

static func _make_open_grid(size: int) -> TacticalGrid:
	return TacticalGrid.new(size, size)

static func _test_simple_path(reporter: TestReporter) -> void:
	var grid := _make_open_grid(5)
	var path := AStarPathfinder.find_path(grid, Vector2i(0, 0), Vector2i(4, 4))
	reporter.expect_true(not path.is_empty(), "path exists on an open grid")
	if not path.is_empty():
		reporter.expect_eq(path[0], Vector2i(0, 0), "path starts at the requested start tile")
		reporter.expect_eq(path[path.size() - 1], Vector2i(4, 4), "path ends at the requested goal tile")

static func _test_avoids_walls(reporter: TestReporter) -> void:
	var grid := _make_open_grid(5)
	# Wall off column x=2 except a single gap at y=4, forcing the path around.
	for y in range(0, 4):
		var tile := grid.default_tile()
		tile["type"] = "wall"
		grid.set_tile(Vector2i(2, y), tile)

	var path := AStarPathfinder.find_path(grid, Vector2i(0, 0), Vector2i(4, 0))
	reporter.expect_true(not path.is_empty(), "path exists around a partial wall")
	var passes_through_wall := false
	for pos in path:
		if grid.get_tile(pos).get("type", "open") == "wall":
			passes_through_wall = true
	reporter.expect_false(passes_through_wall, "path never crosses a wall tile")

static func _test_unreachable_returns_empty(reporter: TestReporter) -> void:
	var grid := _make_open_grid(5)
	# Fully enclose (4, 4) with walls.
	for pos in [Vector2i(3, 4), Vector2i(4, 3)]:
		var tile := grid.default_tile()
		tile["type"] = "wall"
		grid.set_tile(pos, tile)
	# (4,4) is a corner, so walling its two orthogonal neighbors isolates it.
	var path := AStarPathfinder.find_path(grid, Vector2i(0, 0), Vector2i(4, 4))
	reporter.expect_true(path.is_empty(), "no path returned when goal is fully enclosed")

static func _test_path_tiles_are_adjacent(reporter: TestReporter) -> void:
	var grid := _make_open_grid(6)
	var path := AStarPathfinder.find_path(grid, Vector2i(0, 0), Vector2i(5, 3))
	var all_adjacent := true
	for i in range(path.size() - 1):
		var a: Vector2i = path[i]
		var b: Vector2i = path[i + 1]
		if absi(a.x - b.x) + absi(a.y - b.y) != 1:
			all_adjacent = false
	reporter.expect_true(all_adjacent, "every consecutive pair of path tiles is orthogonally adjacent")
