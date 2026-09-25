## Tests RZ-142 (exposed-commander last-stand combat): Squad's exposure
## transition (core/squad/Squad.gd) and Commander's duck-typed combat
## interface (core/squad/Commander.gd).
class_name TestCommanderExposure
extends RefCounted

static func _make_unit_data() -> UnitData:
	return UnitData.new({
		"squad_base_max_size": 6,
		"classes": [{
			"id": "recruit", "name": "Recruit",
			"levels": [{"level": 1, "hp": 10, "damage": 2, "reach": 1, "attack_type": "melee", "speed": 2.0, "cost": 0}],
			"blocks_ranged_frontal": false, "armor_type": "none", "ability_id": null, "promotes_to": [],
		}]
	})

static func run(reporter: TestReporter) -> void:
	reporter.current_file = "test_commander_exposure.gd"
	_test_exposure_transition_fires_once(reporter)
	_test_zero_unit_squad_exposed_immediately(reporter)
	_test_commander_is_valid_combat_target(reporter)
	_test_commander_death_signal_fires(reporter)

static func _test_exposure_transition_fires_once(reporter: TestReporter) -> void:
	var unit_data := _make_unit_data()
	var commander := Commander.new("c1", "Cmdr", Commander.DEFAULT_MAX_HP)
	var squad := Squad.new("sq1", commander, "recruit", 1, unit_data, [Vector2i(2, 2), Vector2i(3, 3)], Vector2i(5, 5))

	# A plain `int` captured by a lambda is captured by value in GDScript —
	# mutating it inside the closure does not affect the outer variable. A
	# single-element Array is a reference type, so mutating its contents
	# does.
	var exposure_count := [0]
	squad.commander_lost.connect(func(_s): exposure_count[0] += 1)

	var grid := TacticalGrid.new(10, 10)
	var rng := SimRng.new(1)
	var trait_data := TraitData.new({"traits": []})

	for unit in squad.units:
		unit.apply_damage(9999)

	squad.tick(0.1, grid, {"enemies": [], "rng": rng, "trait_data": trait_data})
	reporter.expect_eq(exposure_count[0], 1, "commander_lost fires exactly once on the exposure transition")
	reporter.expect_eq(squad.unit_count(), 0, "squad has 0 units after all die")
	reporter.expect_true(commander.alive, "commander survives the squad wipe (last stand)")
	reporter.expect_eq(commander.position, Vector2i(3, 3), "commander takes the last-processed unit's position on exposure")

	squad.tick(0.1, grid, {"enemies": [], "rng": rng, "trait_data": trait_data})
	reporter.expect_eq(exposure_count[0], 1, "commander_lost does not re-fire on a later empty-unit tick")

static func _test_zero_unit_squad_exposed_immediately(reporter: TestReporter) -> void:
	var unit_data := _make_unit_data()
	var commander := Commander.new("c2", "Cmdr2", Commander.DEFAULT_MAX_HP)
	var squad := Squad.new("sq2", commander, "recruit", 1, unit_data, [], Vector2i(7, 7))
	reporter.expect_eq(commander.position, Vector2i(7, 7), "commander position defaults to deployment_center for a squad spawned with 0 units")

	var exposure_count := [0]
	squad.commander_lost.connect(func(_s): exposure_count[0] += 1)
	var grid := TacticalGrid.new(10, 10)
	var rng := SimRng.new(1)
	var trait_data := TraitData.new({"traits": []})

	squad.tick(0.1, grid, {"enemies": [], "rng": rng, "trait_data": trait_data})
	reporter.expect_eq(exposure_count[0], 1, "commander_lost fires on the first tick for a squad that starts with 0 units")
	reporter.expect_eq(commander.position, Vector2i(7, 7), "commander position is unchanged (no unit to inherit a position from)")

static func _test_commander_is_valid_combat_target(reporter: TestReporter) -> void:
	var commander := Commander.new("c3", "Cmdr3", 5)
	commander.position = Vector2i(4, 4)
	var trait_data := TraitData.new({"traits": []})
	var rng := SimRng.new(1)

	var attacker_data := {"damage": 10, "attack_type": "melee", "armor_type": "none", "traits": []}
	var result: CombatResult = CombatResolver.resolve_engagement(
		attacker_data, commander.to_combat_data([]), {"is_frontal": true, "rng": rng, "trait_data": trait_data}
	)
	reporter.expect_false(result.blocked, "a commander never blocks a frontal attack (no shield)")
	reporter.expect_eq(result.damage_dealt, 10, "commander takes full damage (no armor)")

	commander.apply_damage(result.damage_dealt)
	reporter.expect_false(commander.alive, "commander dies once accumulated damage meets/exceeds hp")
	reporter.expect_eq(commander.hp, 0, "commander hp floors at 0")

static func _test_commander_death_signal_fires(reporter: TestReporter) -> void:
	var commander := Commander.new("c4", "Cmdr4", 1)
	var died_count := [0]
	commander.died.connect(func(_c): died_count[0] += 1)

	commander.apply_damage(1)
	reporter.expect_eq(died_count[0], 1, "died signal fires exactly once when hp reaches 0")

	commander.apply_damage(1)
	reporter.expect_eq(died_count[0], 1, "died does not re-fire once already dead")
