## Tests core/run/RunState.gd + core/run/SaveManager.gd: a populated
## RunState saved and reloaded must match on every field (TDD §8).
## Uses a high slot number (99/98) to avoid colliding with any real save.
class_name TestSaveLoadRoundtrip
extends RefCounted

const TEST_SLOT := 99
const TEST_SLOT_B := 98

static func _make_populated_run_state() -> RunState:
	var run_state := RunState.new_run(12345, "hard", 42)

	var alive_commander := Commander.new("cmdr_a", "Alpha", Commander.DEFAULT_MAX_HP, "ironskin", "mines")
	run_state.add_commander(alive_commander, "riot", 2, 5)

	var dead_commander := Commander.new("cmdr_b", "Beta", Commander.DEFAULT_MAX_HP, "", "")
	run_state.add_commander(dead_commander, "marksman", 1, 3)
	dead_commander.die()

	run_state.campaign_state["visited_nodes"] = ["n0", "n1"]
	run_state.campaign_state["lost_nodes"] = ["n2"]
	run_state.campaign_state["progress_line_layer"] = 2
	run_state.campaign_state["current_node"] = "n1"

	return run_state

static func run(reporter: TestReporter) -> void:
	reporter.current_file = "test_save_load_roundtrip.gd"
	_test_roundtrip_preserves_fields(reporter)
	_test_dead_commander_has_no_roster_meta_after_load(reporter)
	_test_missing_slot_returns_null(reporter)

static func _test_roundtrip_preserves_fields(reporter: TestReporter) -> void:
	var original := _make_populated_run_state()
	SaveManager.save(original, TEST_SLOT)
	var loaded := SaveManager.load(TEST_SLOT)
	SaveManager.delete_save(TEST_SLOT)

	reporter.expect_true(loaded != null, "load() returns a RunState for an existing slot")
	if loaded == null:
		return

	reporter.expect_eq(loaded.seed_value, 12345, "seed round-trips")
	reporter.expect_eq(loaded.difficulty_id, "hard", "difficulty round-trips")
	reporter.expect_eq(loaded.gold, 42, "gold round-trips")
	reporter.expect_eq(loaded.commanders.size(), 2, "both commanders round-trip")

	reporter.expect_eq(loaded.campaign_state["visited_nodes"], ["n0", "n1"], "campaign_state.visited_nodes round-trips")
	reporter.expect_eq(loaded.campaign_state["lost_nodes"], ["n2"], "campaign_state.lost_nodes round-trips")
	reporter.expect_eq(loaded.campaign_state["progress_line_layer"], 2, "campaign_state.progress_line_layer round-trips")
	reporter.expect_eq(loaded.campaign_state["current_node"], "n1", "campaign_state.current_node round-trips")

	var alive: Commander = loaded.commanders[0]
	reporter.expect_eq(alive.id, "cmdr_a", "alive commander id round-trips")
	reporter.expect_eq(alive.display_name, "Alpha", "alive commander name round-trips")
	reporter.expect_eq(alive.trait_id, "ironskin", "trait_id round-trips")
	reporter.expect_eq(alive.relic_id, "mines", "relic_id round-trips")
	reporter.expect_true(alive.alive, "alive commander stays alive after round-trip")

	var alive_meta := loaded.get_roster_meta("cmdr_a")
	reporter.expect_eq(alive_meta.get("unit_class"), "riot", "unit_class round-trips")
	reporter.expect_eq(alive_meta.get("level"), 2, "level round-trips")
	reporter.expect_eq(alive_meta.get("unit_count"), 5, "unit_count round-trips")

	var dead: Commander = loaded.commanders[1]
	reporter.expect_eq(dead.id, "cmdr_b", "dead commander id round-trips")
	reporter.expect_false(dead.alive, "dead commander stays dead after round-trip")
	reporter.expect_eq(dead.hp, 0, "dead commander has 0 hp after round-trip")

static func _test_dead_commander_has_no_roster_meta_after_load(reporter: TestReporter) -> void:
	var original := _make_populated_run_state()
	SaveManager.save(original, TEST_SLOT_B)
	var loaded := SaveManager.load(TEST_SLOT_B)
	SaveManager.delete_save(TEST_SLOT_B)

	reporter.expect_eq(loaded.get_roster_meta("cmdr_b"), {}, "dead commander has no roster_meta after load")
	reporter.expect_false(loaded.is_run_over(), "run is not over while the alive commander remains")

static func _test_missing_slot_returns_null(reporter: TestReporter) -> void:
	SaveManager.delete_save(97) # ensure it doesn't exist
	var loaded := SaveManager.load(97)
	reporter.expect_true(loaded == null, "load() on a nonexistent slot returns null")
