## Headless test runner (ADR-0010). Run from the repo root with:
##   godot --headless --path game --script res://tests/run_tests.gd
## Exits with code 0 if every test passed, 1 otherwise — CI treats a
## non-zero exit as a failed build (.github/workflows/ci.yml).
extends SceneTree

func _initialize() -> void:
	var reporter := TestReporter.new()

	TestPathfinding.run(reporter)
	TestCombatRPS.run(reporter)
	TestEconomy.run(reporter)
	TestProcgenDeterminism.run(reporter)

	reporter.print_summary()
	quit(0 if reporter.all_passed() else 1)
