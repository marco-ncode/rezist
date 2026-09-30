## Tests RZ-048 (Focused Volley + Line Charge) and, retroactively (no prior
## coverage existed), Breach: each class ability's actual damage/AoE/
## movement behavior when activated through the real Ability.activate()
## entry point (cooldown bookkeeping included, not just _apply() in
## isolation).
class_name TestAbilities
extends RefCounted

static func _make_unit_data(class_id: String, damage: int, attack_type: String, armor_type: String, ability_id: String) -> UnitData:
	return UnitData.new({
		"squad_base_max_size": 6,
		"classes": [{
			"id": class_id, "name": class_id.capitalize(),
			"levels": [{"level": 1, "hp": 10, "damage": damage, "reach": 5, "attack_type": attack_type, "speed": 1.4, "cost": 0}],
			"blocks_ranged_frontal": false, "armor_type": armor_type, "ability_id": ability_id, "promotes_to": [],
		}]
	})

static func run(reporter: TestReporter) -> void:
	reporter.current_file = "test_abilities.gd"
	_test_breach_deals_plunge_damage_from_elevation(reporter)
	_test_focused_volley_hits_every_enemy_in_radius_without_moving(reporter)
	_test_line_charge_hits_enemies_along_the_path_and_advances(reporter)

static func _test_breach_deals_plunge_damage_from_elevation(reporter: TestReporter) -> void:
	var unit_data := _make_unit_data("riot", 10, "melee", "shield", "breach")
	var grid := TacticalGrid.new(10, 10)
	grid.set_tile(Vector2i(2, 2), {"type": "open", "elevation": 1, "occupant_id": ""}) # source, elevated
	# target tile (2, 3) stays at the grid's default elevation 0.
	var rng := SimRng.new(1)

	var commander := Commander.new("c_breach", "Breacher", Commander.DEFAULT_MAX_HP)
	var squad := Squad.new("sq_breach", commander, "riot", 1, unit_data, [Vector2i(2, 2)], Vector2i(2, 2))
	var ability := BreachAbility.new("breach", {"cooldown_seconds": 12.0, "min_elevation_delta": 1, "radius": 1, "damage_multiplier": 1.5})

	var in_radius := Enemy.new("e_in", {"id": "walker", "hp": 100, "damage": 0}, Vector2i(2, 3))
	var out_of_radius := Enemy.new("e_out", {"id": "walker", "hp": 100, "damage": 0}, Vector2i(2, 6))
	var context := {"grid": grid, "enemies": [in_radius, out_of_radius], "rng": rng, "trait_data": null}

	reporter.expect_true(ability.can_activate(squad), "Breach is usable by a fresh riot squad")
	ability.activate(squad, Vector2i(2, 3), context)

	reporter.expect_eq(in_radius.hp, 85, "Breach deals damage*1.5 (10*1.5=15) to an enemy within radius of the target tile")
	reporter.expect_eq(out_of_radius.hp, 100, "an enemy outside Breach's radius is untouched")
	reporter.expect_false(ability.can_activate(squad), "Breach starts its cooldown on activation")

static func _test_focused_volley_hits_every_enemy_in_radius_without_moving(reporter: TestReporter) -> void:
	var unit_data := _make_unit_data("marksman", 6, "ranged", "none", "focused_volley")
	var grid := TacticalGrid.new(10, 10)
	var rng := SimRng.new(1)

	var commander := Commander.new("c_volley", "Marksman", Commander.DEFAULT_MAX_HP)
	var squad := Squad.new("sq_volley", commander, "marksman", 1, unit_data, [Vector2i(0, 0)], Vector2i(0, 0))
	var ability := FocusedVolleyAbility.new("focused_volley", {"cooldown_seconds": 10.0, "radius": 1, "damage_multiplier": 2.0, "ignores_partial_cover": true})

	var primary := Enemy.new("e_primary", {"id": "walker", "hp": 100, "damage": 0}, Vector2i(5, 5))
	var within_radius := Enemy.new("e_within", {"id": "walker", "hp": 100, "damage": 0}, Vector2i(6, 5))
	var out_of_radius := Enemy.new("e_out", {"id": "walker", "hp": 100, "damage": 0}, Vector2i(5, 8))
	var context := {"grid": grid, "enemies": [primary, within_radius, out_of_radius], "rng": rng, "trait_data": null}

	reporter.expect_true(ability.can_activate(squad), "Focused Volley is usable by a fresh marksman squad")
	ability.activate(squad, Vector2i(5, 5), context)

	reporter.expect_eq(primary.hp, 88, "Focused Volley deals damage*2.0 (6*2.0=12) to the directly-targeted enemy")
	reporter.expect_eq(within_radius.hp, 88, "Focused Volley hits every enemy within its own declared radius, not just the target tile")
	reporter.expect_eq(out_of_radius.hp, 100, "an enemy outside Focused Volley's radius is untouched")
	reporter.expect_eq(squad.units[0].position, Vector2i(0, 0), "Focused Volley is a stationary ranged attack -- the squad does not move")

static func _test_line_charge_hits_enemies_along_the_path_and_advances(reporter: TestReporter) -> void:
	var unit_data := _make_unit_data("barricade", 10, "melee", "reach", "line_charge")
	var grid := TacticalGrid.new(10, 10)
	var rng := SimRng.new(1)

	var commander := Commander.new("c_charge", "Charger", Commander.DEFAULT_MAX_HP)
	var squad := Squad.new("sq_charge", commander, "barricade", 1, unit_data, [Vector2i(0, 0)], Vector2i(0, 0))
	var ability := LineChargeAbility.new("line_charge", {"cooldown_seconds": 14.0, "line_length": 3, "damage_multiplier": 1.3, "knockback_strength": 2})

	var on_line := Enemy.new("e_on_line", {"id": "walker", "hp": 100, "damage": 0}, Vector2i(2, 0))
	var off_line := Enemy.new("e_off_line", {"id": "walker", "hp": 100, "damage": 0}, Vector2i(0, 5))
	var beyond_line := Enemy.new("e_beyond", {"id": "walker", "hp": 100, "damage": 0}, Vector2i(4, 0))
	var context := {"grid": grid, "enemies": [on_line, off_line, beyond_line], "rng": rng, "trait_data": null}

	reporter.expect_true(ability.can_activate(squad), "Line Charge is usable by a fresh barricade squad")
	ability.activate(squad, Vector2i(1, 0), context) # aims straight along +x

	reporter.expect_eq(on_line.hp, 87, "Line Charge deals damage*1.3 (10*1.3=13) to an enemy on the charge line")
	reporter.expect_eq(off_line.hp, 100, "an enemy off the charge line is untouched")
	reporter.expect_eq(beyond_line.hp, 100, "an enemy beyond line_length is untouched")

	# Line Charge also advances the squad along the line (unlike Focused
	# Volley) -- a single generous tick with no enemies to fight is enough to
	# cross the first tile of the path Line Charge's _apply() just ordered.
	squad.tick(2.0, grid, {"enemies": [], "rng": rng, "trait_data": null})
	reporter.expect_eq(squad.units[0].position, Vector2i(1, 0), "Line Charge orders the squad to advance along the charge line")
