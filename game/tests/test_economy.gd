## Tests core/economy/Economy.gd formulas against docs/BALANCE.md §1.
class_name TestEconomy
extends RefCounted

static func _make_economy() -> Economy:
	return Economy.new(EconomyData.new({
		"starting_gold": 20,
		"gold_per_safehouse": 10,
		"squad_survival_base_gold": 5,
		"gold_per_surviving_unit": 1,
		"upgrade_cost": {"l1_to_l2": 12, "l2_to_l3": 20},
		"ability_unlock_cost": 15,
		"trait_discounts": {
			"collector": {"applies_to": "relic", "mult": 0.5},
			"skillful": {"applies_to": "ability", "mult": 0.75},
		}
	}))

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
	reporter.current_file = "test_economy.gd"
	_test_upgrade_cost(reporter)
	_test_ability_cost_with_skillful_discount(reporter)
	_test_relic_discount_only_applies_to_relics(reporter)
	_test_mission_payout_formula(reporter)

static func _test_upgrade_cost(reporter: TestReporter) -> void:
	var economy := _make_economy()
	reporter.expect_eq(economy.upgrade_cost(1, 2), 12, "L1->L2 upgrade costs 12 gold")
	reporter.expect_eq(economy.upgrade_cost(2, 3), 20, "L2->L3 upgrade costs 20 gold")

static func _test_ability_cost_with_skillful_discount(reporter: TestReporter) -> void:
	var economy := _make_economy()
	reporter.expect_eq(economy.ability_cost(""), 15, "base ability cost with no trait is 15")
	reporter.expect_eq(economy.ability_cost("skillful"), 11, "Skillful discounts ability cost to 15*0.75=11.25 -> round 11")

static func _test_relic_discount_only_applies_to_relics(reporter: TestReporter) -> void:
	var economy := _make_economy()
	# Skillful only discounts abilities, not relics — apply_trait_discount should no-op.
	var relic_cost := economy.apply_trait_discount(20, ["skillful"], "relic")
	reporter.expect_eq(relic_cost, 20, "Skillful trait does not discount relic costs")
	var discounted := economy.apply_trait_discount(20, ["collector"], "relic")
	reporter.expect_eq(discounted, 10, "Collector halves relic costs")

static func _test_mission_payout_formula(reporter: TestReporter) -> void:
	var economy := _make_economy()
	var unit_data := _make_unit_data()
	var commander := Commander.new("c1", "Test Commander", 20)
	var squad := Squad.new("sq1", commander, "recruit", 1, unit_data, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	reporter.expect_eq(squad.unit_count(), 3, "squad spawned with 3 units")

	# 2 safehouses saved * 10 = 20; one squad of 3 units: 5 + 3*1 = 8; total 28; normal gold_mult 1.0
	var payout := economy.mission_payout(2, [squad], {"gold_mult": 1.0})
	reporter.expect_eq(payout, 28, "mission_payout matches docs/BALANCE.md §1 formula")

	var payout_easy := economy.mission_payout(2, [squad], {"gold_mult": 1.2})
	reporter.expect_eq(payout_easy, 34, "mission_payout scales with difficulty gold_mult (28*1.2=33.6 -> round 34)")
