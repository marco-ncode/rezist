## Tests RZ-109 (remaining relics): Tactical Radio (squad_max_size_add),
## Emergency Fund (bonus_gold_per_mission), Sledgehammer (melee area_damage
## via damage_multiplier) and Reanimation Kit (revive_commander, one-time
## charge). IED, Mines, Flare, Fast Response Vehicle are deliberately not
## implemented yet (RZ-148/RZ-149/RZ-150/RZ-151 — each needs a mission-HUD
## interaction UX_UI.md never specified), so not covered here.
class_name TestRelics
extends RefCounted

## Mirrors data/relics.json's shape for the relics this file exercises (same
## pattern as test_traits.gd's _make_trait_data()). Includes "ied" alongside
## "sledgehammer" specifically to prove the splash logic tells them apart
## despite sharing effect: "area_damage" (IED has fuse_seconds, no
## damage_multiplier).
static func _make_relic_data() -> RelicData:
	return RelicData.new({
		"relics": [
			{"id": "tactical_radio", "name": "Tactical Radio", "cost": 25, "effect": "squad_max_size_add", "amount": 1},
			{"id": "emergency_fund", "name": "Emergency Fund", "cost": 20, "effect": "bonus_gold_per_mission", "bonus_gold": 3},
			{"id": "sledgehammer", "name": "Sledgehammer", "cost": 20, "effect": "area_damage", "radius": 1, "damage_multiplier": 1.0},
			{"id": "reanimation_kit", "name": "Reanimation Kit", "cost": 35, "effect": "revive_commander", "uses": 1},
			{"id": "ied", "name": "IED", "cost": 20, "effect": "area_damage", "damage": 15, "radius": 1, "fuse_seconds": 2.0},
			{"id": "mines", "name": "Mines / Traps", "cost": 15, "effect": "trap_on_contact", "max_placed": 2, "damage": 10},
		]
	})

static func _make_unit_data() -> UnitData:
	return UnitData.new({
		"squad_base_max_size": 6,
		"classes": [{
			"id": "recruit", "name": "Recruit",
			"levels": [{"level": 1, "hp": 10, "damage": 10, "reach": 1, "attack_type": "melee", "speed": 1.0, "cost": 0}],
			"blocks_ranged_frontal": false, "armor_type": "none", "ability_id": null, "promotes_to": [],
		}]
	})

static func run(reporter: TestReporter) -> void:
	reporter.current_file = "test_relics.gd"
	_test_tactical_radio_increases_squad_max_size(reporter)
	_test_emergency_fund_adds_bonus_gold(reporter)
	_test_sledgehammer_splashes_nearby_enemies(reporter)
	_test_reanimation_kit_revives_once(reporter)
	_test_reanimation_kit_ignores_unrelated_relic(reporter)
	_test_equip_relic_resets_charge(reporter)

static func _test_tactical_radio_increases_squad_max_size(reporter: TestReporter) -> void:
	var relic_data := _make_relic_data()
	var unit_data := _make_unit_data() # squad_base_max_size 6

	var plain_commander := Commander.new("c_radio_plain", "Plain", Commander.DEFAULT_MAX_HP)
	var plain_squad := Squad.new("sq_radio_plain", plain_commander, "recruit", 1, unit_data, [], Vector2i(0, 0))
	reporter.expect_eq(plain_squad.max_size(null, relic_data), 6, "base squad max size is unchanged without Tactical Radio")

	var radio_commander := Commander.new("c_radio_eq", "Radio", Commander.DEFAULT_MAX_HP)
	radio_commander.equip_relic("tactical_radio")
	var radio_squad := Squad.new("sq_radio_eq", radio_commander, "recruit", 1, unit_data, [], Vector2i(0, 0))
	reporter.expect_eq(radio_squad.max_size(null, relic_data), 7, "Tactical Radio adds +1 to squad max size")

static func _test_emergency_fund_adds_bonus_gold(reporter: TestReporter) -> void:
	var relic_data := _make_relic_data()
	var unit_data := _make_unit_data()
	var economy := Economy.new(EconomyData.new({
		"starting_gold": 0, "gold_per_safehouse": 10, "squad_survival_base_gold": 5,
		"gold_per_surviving_unit": 1, "upgrade_cost": {"l1_to_l2": 12, "l2_to_l3": 20},
		"ability_unlock_cost": 15, "trait_discounts": {},
	}))

	var plain_commander := Commander.new("c_fund_plain", "Plain", Commander.DEFAULT_MAX_HP)
	var plain_squad := Squad.new("sq_fund_plain", plain_commander, "recruit", 1, unit_data, [Vector2i(0, 0)])
	# 0 safehouses; 1 squad of 1 unit: 5 + 1*1 = 6; no relic bonus.
	reporter.expect_eq(economy.mission_payout(0, [plain_squad], {"gold_mult": 1.0}, relic_data), 6, "no bonus gold without Emergency Fund")

	var fund_commander := Commander.new("c_fund_eq", "Funded", Commander.DEFAULT_MAX_HP)
	fund_commander.equip_relic("emergency_fund")
	var fund_squad := Squad.new("sq_fund_eq", fund_commander, "recruit", 1, unit_data, [Vector2i(0, 0)])
	# Same base 6, +3 Emergency Fund bonus = 9.
	reporter.expect_eq(economy.mission_payout(0, [fund_squad], {"gold_mult": 1.0}, relic_data), 9, "Emergency Fund adds +3 bonus gold for a surviving squad")

static func _test_sledgehammer_splashes_nearby_enemies(reporter: TestReporter) -> void:
	var relic_data := _make_relic_data()
	var unit_data := _make_unit_data() # unit damage 10, reach 1
	var grid := TacticalGrid.new(10, 10)
	var rng := SimRng.new(1)

	var commander := Commander.new("c_hammer", "Hammer", Commander.DEFAULT_MAX_HP)
	commander.equip_relic("sledgehammer")
	var squad := Squad.new("sq_hammer", commander, "recruit", 1, unit_data, [Vector2i(2, 3)], Vector2i(2, 3))

	var primary := Enemy.new("e_primary", {"id": "walker", "hp": 100, "damage": 0}, Vector2i(3, 3))
	var splash_victim := Enemy.new("e_splash", {"id": "walker", "hp": 100, "damage": 0}, Vector2i(4, 3))
	var out_of_range := Enemy.new("e_far", {"id": "walker", "hp": 100, "damage": 0}, Vector2i(3, 6))
	var enemies := [primary, splash_victim, out_of_range]

	var context := {"enemies": enemies, "rng": rng, "trait_data": null, "relic_data": relic_data}
	squad.tick(0.1, grid, context)

	reporter.expect_eq(primary.hp, 90, "the directly-attacked enemy takes the normal hit")
	reporter.expect_eq(splash_victim.hp, 90, "Sledgehammer splashes the same damage onto an enemy within radius 1 of the target")
	reporter.expect_eq(out_of_range.hp, 100, "an enemy outside the splash radius is untouched")

static func _test_reanimation_kit_revives_once(reporter: TestReporter) -> void:
	var relic_data := _make_relic_data()
	var commander := Commander.new("c_revive", "Revived", 20)
	commander.equip_relic("reanimation_kit")

	commander.apply_damage(19, relic_data)
	reporter.expect_true(commander.alive, "a non-fatal hit never touches the reanimation charge")
	reporter.expect_false(commander.relic_charge_used(), "charge is still unused after a non-fatal hit")

	commander.apply_damage(1, relic_data) # would-be fatal blow
	reporter.expect_true(commander.alive, "Reanimation Kit intercepts the fatal blow and keeps the commander alive")
	reporter.expect_eq(commander.hp, 10, "a revived commander comes back at half max_hp")
	reporter.expect_true(commander.relic_charge_used(), "the charge is marked used after reviving")

	commander.apply_damage(9999, relic_data) # second fatal blow, charge already spent
	reporter.expect_false(commander.alive, "a second fatal blow kills normally once the charge is spent")
	reporter.expect_eq(commander.hp, 0, "a commander who dies for real floors at 0 hp")

static func _test_reanimation_kit_ignores_unrelated_relic(reporter: TestReporter) -> void:
	var relic_data := _make_relic_data()
	var commander := Commander.new("c_no_revive", "NoRevive", 10)
	commander.equip_relic("mines")
	commander.apply_damage(10, relic_data)
	reporter.expect_false(commander.alive, "a relic with a different effect never triggers a revive")

	var commander_no_relic_data := Commander.new("c_null_relic_data", "NullData", 10)
	commander_no_relic_data.equip_relic("reanimation_kit")
	commander_no_relic_data.apply_damage(10) # relic_data omitted entirely
	reporter.expect_false(commander_no_relic_data.alive, "omitting relic_data (existing call sites) never triggers a revive")

static func _test_equip_relic_resets_charge(reporter: TestReporter) -> void:
	var relic_data := _make_relic_data()
	var commander := Commander.new("c_reequip", "Reequip", 10)
	commander.equip_relic("reanimation_kit")
	commander.apply_damage(10, relic_data) # consumes the charge, revives at half hp
	reporter.expect_true(commander.relic_charge_used(), "sanity check: charge consumed")

	commander.equip_relic("reanimation_kit") # paying to (re-)equip it again
	reporter.expect_false(commander.relic_charge_used(), "equip_relic() refreshes the charge")
