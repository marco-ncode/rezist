## Tests core/procgen/MapGenerator.gd's determinism contract (TDD §5):
## the same seed + same district params must produce byte-identical output.
class_name TestProcgenDeterminism
extends RefCounted

static func _district_entry() -> Dictionary:
	return {
		"id": "residential", "grid_width": 12, "grid_height": 12,
		"safehouse_count_range": [2, 3], "entry_point_count_range": [2, 2],
		"elevation_variance": "medium",
	}

static func run(reporter: TestReporter) -> void:
	reporter.current_file = "test_procgen_determinism.gd"
	_test_same_seed_produces_identical_grid(reporter)
	_test_different_seed_produces_different_grid(reporter)
	_test_reachability_guarantee(reporter)

static func _generate(seed_value: int) -> Dictionary:
	var rng := SimRng.new(seed_value)
	return MapGenerator.generate(rng, _district_entry())

static func _grid_signature(grid: TacticalGrid) -> Array:
	var signature: Array = []
	for pos in grid.all_positions():
		var tile := grid.get_tile(pos)
		signature.append("%s:%s:%d" % [pos, tile.get("type", "open"), tile.get("elevation", 0)])
	return signature

static func _test_same_seed_produces_identical_grid(reporter: TestReporter) -> void:
	var a := _generate(42)
	var b := _generate(42)
	reporter.expect_eq(_grid_signature(a["grid"]), _grid_signature(b["grid"]), "same seed produces an identical tile grid")

	var safehouses_a: Array = a["safehouses"].map(func(s: Safehouse): return s.position)
	var safehouses_b: Array = b["safehouses"].map(func(s: Safehouse): return s.position)
	reporter.expect_eq(safehouses_a, safehouses_b, "same seed produces identical safehouse placement")

	var entries_a: Array = a["entry_points"].map(func(e: EntryPoint): return e.position)
	var entries_b: Array = b["entry_points"].map(func(e: EntryPoint): return e.position)
	reporter.expect_eq(entries_a, entries_b, "same seed produces identical entry point placement")

static func _test_different_seed_produces_different_grid(reporter: TestReporter) -> void:
	var a := _generate(42)
	var b := _generate(1337)
	reporter.expect_true(
		_grid_signature(a["grid"]) != _grid_signature(b["grid"]),
		"different seeds produce different tile grids (extremely low collision probability)"
	)

static func _test_reachability_guarantee(reporter: TestReporter) -> void:
	var result := _generate(7)
	var grid: TacticalGrid = result["grid"]
	var safehouses: Array = result["safehouses"]
	var entry_points: Array = result["entry_points"]

	var all_reachable := true
	for entry_point in entry_points:
		var reaches_any := false
		for safehouse in safehouses:
			if not AStarPathfinder.find_path(grid, entry_point.position, safehouse.position, "ground").is_empty():
				reaches_any = true
				break
		if not reaches_any:
			all_reachable = false
	reporter.expect_true(all_reachable, "every entry point can reach at least one safehouse")
