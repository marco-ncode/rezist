## Minimal assertion collector used by every tests/test_*.gd file
## (ADR-0010 — no GUT dependency in v1). Each test file calls
## `reporter.expect_*` for every assertion; run_tests.gd prints the summary
## and sets the process exit code.
class_name TestReporter
extends RefCounted

var passed := 0
var failed := 0
var _failures: Array = []
var current_file := ""

func expect_eq(actual, expected, description: String) -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		_failures.append("%s :: %s — expected %s, got %s" % [current_file, description, str(expected), str(actual)])

func expect_true(value: bool, description: String) -> void:
	expect_eq(value, true, description)

func expect_false(value: bool, description: String) -> void:
	expect_eq(value, false, description)

func expect_gt(actual, threshold, description: String) -> void:
	if actual > threshold:
		passed += 1
	else:
		failed += 1
		_failures.append("%s :: %s — expected > %s, got %s" % [current_file, description, str(threshold), str(actual)])

func print_summary() -> void:
	print("\n--- Test Summary ---")
	print("Passed: %d  Failed: %d" % [passed, failed])
	if not _failures.is_empty():
		print("\nFailures:")
		for failure in _failures:
			print("  ✗ %s" % failure)

func all_passed() -> bool:
	return failed == 0
