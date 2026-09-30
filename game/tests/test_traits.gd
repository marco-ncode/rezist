## Tests RZ-108 (remaining traits) + RZ-112 (trait stacking coverage):
## Fleet of Foot (move_speed_mult), Heavy Load (ability_extra_uses, plus the
## ability_cooldown_remaining decrement fix it depends on), Mountain
## (mountain_hp / mountain_damage), Heavy Weapons (stagger_chance_add) and
## Popular (squad_max_size_add). Sharp Weapons/Ironskin stacking is already
## covered by test_combat_rps.gd's _test_trait_modifiers_apply.
class_name TestTraits
extends RefCounted

## Mirrors data/traits.json's modifier values for the traits this file
## exercises (same pattern as test_combat_rps.gd's _make_trait_data()).
static func _make_trait_data() -> TraitData:
	return TraitData.new({
		"traits": [
			{"id": "fleet_of_foot", "name": "Fleet of Foot", "modifiers": {"move_speed_mult": 1.25}},
			{"id": "heavy_load", "name": "Heavy Load", "modifiers": {"ability_extra_uses": 1}},
			{"id": "heavy_weapons", "name": "Heavy Weapons", "modifiers": {"stagger_chance_add": 0.25}},
			{"id": "mountain", "name": "Mountain", "modifiers": {"is_mountain": true, "mountain_hp": 30, "mountain_damage": 8}},
			{"id": "popular", "name": "Popular", "modifiers": {"squad_max_size_add": 1}},
		]
	})

static func _make_unit_data() -> UnitData:
	return UnitData.new({
		"squad_base_max_size": 6,
		"classes": [{
			"id": "recruit", "name": "Recruit",
			"levels": [{"level": 1, "hp": 10, "damage": 2, "reach": 1, "attack_type": "melee", "speed": 1.0, "cost": 0}],
			"blocks_ranged_frontal": false, "armor_type": "none", "ability_id": null, "promotes_to": [],
		}]
	})

static func run(reporter: TestReporter) -> void:
	reporter.current_file = "test_traits.gd"
	_test_fleet_of_foot_increases_speed(reporter)
	_test_heavy_load_grants_extra_use_before_cooldown(reporter)
	_test_mountain_overrides_hp_and_fights_back(reporter)
	_test_heal_to_full_restores_hp(reporter)
	_test_popular_increases_squad_max_size(reporter)
	_test_heavy_weapons_increases_stagger_chance(reporter)

static func _test_fleet_of_foot_increases_speed(reporter: TestReporter) -> void:
	var unit_data := _make_unit_data() # speed 1.0 tiles/sec
	var grid := TacticalGrid.new(10, 10)
	var rng := SimRng.new(1)
	var trait_data := _make_trait_data()
	var context := {"enemies": [], "rng": rng, "trait_data": trait_data}

	var baseline_commander := Commander.new("c_base", "Base", Commander.DEFAULT_MAX_HP)
	var baseline_squad := Squad.new("sq_base", baseline_commander, "recruit", 1, unit_data, [Vector2i(0, 0)], Vector2i(0, 0))
	baseline_squad.order_move_to(Vector2i(5, 0), grid)

	var fleet_commander := Commander.new("c_fleet", "Fleet", Commander.DEFAULT_MAX_HP, "fleet_of_foot")
	var fleet_squad := Squad.new("sq_fleet", fleet_commander, "recruit", 1, unit_data, [Vector2i(0, 0)], Vector2i(0, 0))
	fleet_squad.order_move_to(Vector2i(5, 0), grid)

	# 0.9s at speed 1.0 (base) covers 0.9 of a tile; Fleet of Foot's 1.25x
	# covers 1.125 -- enough margin either side of the 1.0 threshold to be
	# robust to floating-point rounding.
	baseline_squad.tick(0.9, grid, context)
	fleet_squad.tick(0.9, grid, context)

	reporter.expect_eq(baseline_squad.units[0].position, Vector2i(0, 0), "without Fleet of Foot, 0.9s at speed 1.0 hasn't crossed a tile yet")
	reporter.expect_eq(fleet_squad.units[0].position, Vector2i(1, 0), "Fleet of Foot's move_speed_mult lets the same 0.9s cross a tile")

static func _test_heavy_load_grants_extra_use_before_cooldown(reporter: TestReporter) -> void:
	var trait_data := _make_trait_data()
	var unit_data := _make_unit_data()
	var commander := Commander.new("c_load", "Load", Commander.DEFAULT_MAX_HP, "heavy_load")
	var squad := Squad.new("sq_load", commander, "recruit", 1, unit_data, [Vector2i(0, 0)], Vector2i(0, 0))
	var ability := Ability.new("test_ability", {"cooldown_seconds": 10.0})
	var grid := TacticalGrid.new(10, 10)
	var rng := SimRng.new(1)
	var context := {"grid": grid, "enemies": [], "rng": rng, "trait_data": trait_data}

	reporter.expect_true(ability.can_activate(squad), "ability usable before any activation")
	ability.activate(squad, Vector2i(0, 0), context)
	reporter.expect_eq(squad.ability_cooldown_remaining, 10.0, "first activation starts the full cooldown")
	reporter.expect_eq(squad.ability_charges_remaining, 1, "Heavy Load grants 1 extra charge on a fresh cooldown cycle")

	reporter.expect_true(ability.can_activate(squad), "the Heavy Load charge allows a second activation while on cooldown")
	ability.activate(squad, Vector2i(0, 0), context)
	reporter.expect_eq(squad.ability_charges_remaining, 0, "the charge is consumed by the second activation")
	reporter.expect_eq(squad.ability_cooldown_remaining, 10.0, "consuming a charge does not restart or extend the cooldown")

	reporter.expect_false(ability.can_activate(squad), "ability is unusable once charges are exhausted and the cooldown hasn't elapsed")

	# Also proves the RZ-108 fix to Squad.tick(): ability_cooldown_remaining
	# was previously never decremented, so this would still read 10.0 here
	# regardless of how much time passed, permanently locking out the ability.
	squad.tick(6.0, grid, {"enemies": [], "rng": rng, "trait_data": trait_data})
	reporter.expect_eq(squad.ability_cooldown_remaining, 4.0, "Squad.tick() decrements ability_cooldown_remaining by delta")

	squad.tick(4.0, grid, {"enemies": [], "rng": rng, "trait_data": trait_data})
	reporter.expect_true(ability.can_activate(squad), "ability is usable again once its cooldown fully elapses")

static func _test_mountain_overrides_hp_and_fights_back(reporter: TestReporter) -> void:
	var trait_data := _make_trait_data()

	var plain_commander := Commander.new("c_plain", "Plain", Commander.DEFAULT_MAX_HP)
	reporter.expect_eq(plain_commander.to_combat_data([]).get("damage"), 0, "a commander without Mountain deals 0 damage (fights on alone rule)")

	var mountain_commander := Commander.new("c_mountain", "Giant", Commander.DEFAULT_MAX_HP, "mountain", "", trait_data)
	reporter.expect_eq(mountain_commander.max_hp, 30, "Mountain's mountain_hp modifier overrides max_hp")
	reporter.expect_eq(mountain_commander.hp, 30, "a freshly created Mountain commander starts at full (overridden) hp")
	reporter.expect_eq(mountain_commander.to_combat_data([]).get("damage"), 8, "Mountain's mountain_damage modifier makes the commander fight back")

static func _test_heal_to_full_restores_hp(reporter: TestReporter) -> void:
	var commander := Commander.new("c_heal", "Healer", 20)
	commander.apply_damage(15)
	reporter.expect_eq(commander.hp, 5, "sanity check: commander took damage")
	commander.heal_to_full()
	reporter.expect_eq(commander.hp, 20, "heal_to_full restores hp to max_hp (ADR-0007: never persisted across missions)")

	var dead_commander := Commander.new("c_dead", "Deadman", 5)
	dead_commander.apply_damage(5)
	reporter.expect_false(dead_commander.alive, "sanity check: commander died")
	dead_commander.heal_to_full()
	reporter.expect_eq(dead_commander.hp, 0, "heal_to_full does not resurrect a dead commander")

static func _test_popular_increases_squad_max_size(reporter: TestReporter) -> void:
	var trait_data := _make_trait_data()
	var unit_data := _make_unit_data() # squad_base_max_size 6

	var plain_commander := Commander.new("c_size_plain", "Plain", Commander.DEFAULT_MAX_HP)
	var plain_squad := Squad.new("sq_size_plain", plain_commander, "recruit", 1, unit_data, [], Vector2i(0, 0))
	reporter.expect_eq(plain_squad.max_size(trait_data), 6, "base squad max size is unchanged without Popular")

	var popular_commander := Commander.new("c_size_pop", "Pop", Commander.DEFAULT_MAX_HP, "popular")
	var popular_squad := Squad.new("sq_size_pop", popular_commander, "recruit", 1, unit_data, [], Vector2i(0, 0))
	reporter.expect_eq(popular_squad.max_size(trait_data), 7, "Popular adds +1 to squad max size")

static func _test_heavy_weapons_increases_stagger_chance(reporter: TestReporter) -> void:
	var trait_data := _make_trait_data()
	var baseline_attacker := {"damage": 5, "attack_type": "melee", "armor_type": "none", "traits": []}
	var heavy_attacker := {"damage": 5, "attack_type": "melee", "armor_type": "none", "traits": ["heavy_weapons"]}
	var defender := {"blocks_ranged_frontal": false, "weak_to": null, "knockback_immune": false, "traits": []}

	var trials := 200
	var baseline_staggers := 0
	var heavy_staggers := 0
	for i in range(1, trials + 1):
		var baseline_result: CombatResult = CombatResolver.resolve_engagement(
			baseline_attacker, defender, {"is_frontal": true, "rng": SimRng.new(i), "trait_data": trait_data}
		)
		if baseline_result.staggered:
			baseline_staggers += 1
		var heavy_result: CombatResult = CombatResolver.resolve_engagement(
			heavy_attacker, defender, {"is_frontal": true, "rng": SimRng.new(i), "trait_data": trait_data}
		)
		if heavy_result.staggered:
			heavy_staggers += 1

	# Base stagger chance is 0.10, Heavy Weapons adds 0.25 (-> 0.35). Over 200
	# deterministic seeds the boosted count is reliably well above baseline
	# (expected ~20 vs ~70), so the assertion doesn't hinge on any single
	# seed's exact roll matching a hand-computed value.
	reporter.expect_gt(heavy_staggers, baseline_staggers, "Heavy Weapons' stagger_chance_add measurably increases stagger frequency")
	reporter.expect_gt(heavy_staggers, trials / 10, "boosted stagger count is well above the unmodified ~10% base rate")
