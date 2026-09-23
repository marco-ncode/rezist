## Tests core/combat/CombatResolver.gd's rock-paper-scissors rules
## (docs/BALANCE.md §6): frontal shield blocks ranged, reach beats
## weak_to == "reach", trait modifiers stack correctly, minimum damage floor.
class_name TestCombatRPS
extends RefCounted

static func _make_trait_data() -> TraitData:
	return TraitData.new({
		"traits": [
			{"id": "sharp_weapons", "name": "Sharp Weapons", "modifiers": {"damage_dealt_mult": 1.15}},
			{"id": "ironskin", "name": "Ironskin", "modifiers": {"damage_taken_mult": 0.8}},
		]
	})

static func run(reporter: TestReporter) -> void:
	reporter.current_file = "test_combat_rps.gd"
	_test_shield_blocks_frontal_ranged(reporter)
	_test_shield_does_not_block_melee(reporter)
	_test_reach_bonus_vs_weak_to(reporter)
	_test_no_bonus_without_weak_to_match(reporter)
	_test_trait_modifiers_apply(reporter)
	_test_minimum_damage_floor(reporter)

static func _test_shield_blocks_frontal_ranged(reporter: TestReporter) -> void:
	var attacker := {"damage": 5, "attack_type": "ranged", "armor_type": "none", "traits": []}
	var defender := {"blocks_ranged_frontal": true, "weak_to": null, "knockback_immune": false, "traits": []}
	var rng := SimRng.new(1)
	var result := CombatResolver.resolve_engagement(attacker, defender, {"is_frontal": true, "rng": rng})
	reporter.expect_true(result.blocked, "frontal ranged attack against a shield defender is blocked")
	reporter.expect_eq(result.damage_dealt, 0, "blocked attack deals zero damage")

static func _test_shield_does_not_block_melee(reporter: TestReporter) -> void:
	var attacker := {"damage": 5, "attack_type": "melee", "armor_type": "none", "traits": []}
	var defender := {"blocks_ranged_frontal": true, "weak_to": null, "knockback_immune": false, "traits": []}
	var rng := SimRng.new(1)
	var result := CombatResolver.resolve_engagement(attacker, defender, {"is_frontal": true, "rng": rng})
	reporter.expect_false(result.blocked, "melee attacks are never blocked by blocks_ranged_frontal")
	reporter.expect_eq(result.damage_dealt, 5, "unblocked melee attack deals its base damage")

static func _test_reach_bonus_vs_weak_to(reporter: TestReporter) -> void:
	var attacker := {"damage": 4, "attack_type": "melee", "armor_type": "reach", "traits": []}
	var defender := {"blocks_ranged_frontal": false, "weak_to": "reach", "knockback_immune": false, "traits": []}
	var rng := SimRng.new(1)
	var result := CombatResolver.resolve_engagement(attacker, defender, {"is_frontal": true, "rng": rng})
	# 4 * 1.5 = 6
	reporter.expect_eq(result.damage_dealt, 6, "reach attacker deals 1.5x damage to a weak_to=reach defender")

static func _test_no_bonus_without_weak_to_match(reporter: TestReporter) -> void:
	var attacker := {"damage": 4, "attack_type": "melee", "armor_type": "reach", "traits": []}
	var defender := {"blocks_ranged_frontal": false, "weak_to": null, "knockback_immune": false, "traits": []}
	var rng := SimRng.new(1)
	var result := CombatResolver.resolve_engagement(attacker, defender, {"is_frontal": true, "rng": rng})
	reporter.expect_eq(result.damage_dealt, 4, "no reach bonus applies when defender is not weak_to reach")

static func _test_trait_modifiers_apply(reporter: TestReporter) -> void:
	var trait_data := _make_trait_data()
	var attacker := {"damage": 10, "attack_type": "melee", "armor_type": "none", "traits": ["sharp_weapons"]}
	var defender := {"blocks_ranged_frontal": false, "weak_to": null, "knockback_immune": false, "traits": ["ironskin"]}
	var rng := SimRng.new(1)
	var result := CombatResolver.resolve_engagement(
		attacker, defender, {"is_frontal": true, "rng": rng, "trait_data": trait_data}
	)
	# 10 * 1.15 (Sharp Weapons) * 0.8 (Ironskin) = 9.2 -> round to 9
	reporter.expect_eq(result.damage_dealt, 9, "Sharp Weapons and Ironskin modifiers both apply multiplicatively")

static func _test_minimum_damage_floor(reporter: TestReporter) -> void:
	var attacker := {"damage": 0, "attack_type": "melee", "armor_type": "none", "traits": []}
	var defender := {"blocks_ranged_frontal": false, "weak_to": null, "knockback_immune": false, "traits": []}
	var rng := SimRng.new(1)
	var result := CombatResolver.resolve_engagement(attacker, defender, {"is_frontal": true, "rng": rng})
	reporter.expect_eq(result.damage_dealt, 1, "damage is floored at 1, never a total whiff")
