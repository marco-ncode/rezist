## Tests RZ-105's burst-then-melee behavior (Thrower): core/enemy/Enemy.gd's
## effective_damage()/effective_range()/mark_burst(), and their integration
## through EnemyAI.tick_enemy(). melee_followup_damage is read generically
## off the enemy's data entry (docs/BALANCE.md's "Burst then closes to
## melee") -- a value of 0 (every enemy type but Thrower) must be a
## complete no-op, verified here too.
class_name TestEnemyAI
extends RefCounted

static func _make_thrower(position: Vector2i) -> Enemy:
	return Enemy.new("e_thrower", {
		"id": "thrower", "hp": 8, "damage": 5, "attack_type": "ranged",
		"range": 3, "speed": 1.3, "behavior": "swarm_ranged",
		"melee_followup_damage": 2,
	}, position)

static func run(reporter: TestReporter) -> void:
	reporter.current_file = "test_enemy_ai.gd"
	_test_burst_switches_damage_and_range(reporter)
	_test_mark_burst_is_a_noop_without_followup_damage(reporter)
	_test_thrower_closes_distance_after_bursting(reporter)

static func _test_burst_switches_damage_and_range(reporter: TestReporter) -> void:
	var thrower := _make_thrower(Vector2i(0, 0))
	reporter.expect_eq(thrower.effective_damage(), 5, "before bursting, effective_damage is the base burst damage")
	reporter.expect_eq(thrower.effective_range(), 3, "before bursting, effective_range is the full ranged range")

	thrower.mark_burst()
	reporter.expect_eq(thrower.effective_damage(), 2, "after bursting, effective_damage switches to melee_followup_damage")
	reporter.expect_eq(thrower.effective_range(), 1, "after bursting, effective_range shrinks to melee range")

static func _test_mark_burst_is_a_noop_without_followup_damage(reporter: TestReporter) -> void:
	var walker := Enemy.new("e_walker", {"id": "walker", "hp": 6, "damage": 2, "attack_type": "melee", "range": 1, "speed": 1.2, "behavior": "swarm"}, Vector2i(0, 0))
	walker.mark_burst()
	reporter.expect_eq(walker.effective_damage(), 2, "mark_burst() is a no-op for an enemy without melee_followup_damage")
	reporter.expect_eq(walker.effective_range(), 1, "mark_burst() never changes range for an enemy without melee_followup_damage")

static func _test_thrower_closes_distance_after_bursting(reporter: TestReporter) -> void:
	var thrower := _make_thrower(Vector2i(0, 0))
	var grid := TacticalGrid.new(10, 10)
	var unit_data := UnitData.new({
		"squad_base_max_size": 6,
		"classes": [{
			"id": "recruit", "name": "Recruit",
			"levels": [{"level": 1, "hp": 100, "damage": 0, "reach": 1, "attack_type": "melee", "speed": 1.0, "cost": 0}],
			"blocks_ranged_frontal": false, "armor_type": "none", "ability_id": null, "promotes_to": [],
		}]
	})
	var commander := Commander.new("c_target", "Target", Commander.DEFAULT_MAX_HP)
	var squad := Squad.new("sq_target", commander, "recruit", 1, unit_data, [Vector2i(3, 0)])
	var target_unit: Unit = squad.units[0]

	reporter.expect_true(thrower.in_range_of(target_unit.position), "Thrower starts in range (distance 3 <= base range 3)")

	var rng := SimRng.new(1)
	var combat_context := {"rng": rng, "trait_data": null, "relic_data": null, "unit_traits_by_id": {}}
	var events := EnemyAI.tick_enemy(thrower, 0.1, grid, [target_unit], [], combat_context)

	reporter.expect_true(events["attacked_unit"] != null, "the first tick attacks (bursts) from range")
	reporter.expect_gt(100, target_unit.hp, "the burst attack damages the target")
	reporter.expect_false(thrower.in_range_of(target_unit.position), "after bursting, the same distance-3 target is no longer in the Thrower's (now melee) effective range")
