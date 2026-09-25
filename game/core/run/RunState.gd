## Top-level run state: commander roster, gold, campaign progress (ARCHITECTURE.md
## §10). Persists at campaign-map granularity only (ADR-0007) — never
## mid-mission state. `commanders` holds live `Commander` objects (identity,
## trait/relic, alive flag); per-commander squad metadata (class, level,
## current unit count) that `Commander` itself doesn't carry lives in a
## parallel roster table here, since that data is meaningless outside an
## active mission's `Squad` instance.
##
## `campaign_state` mirrors schemas/save_file.schema.json's shape but is a
## placeholder Dictionary until core/campaign/CampaignGenerator.gd and
## CampaignState.gd land (RZ-080/RZ-081) — the save format is already
## forward-compatible with the real campaign graph once that exists.
class_name RunState
extends RefCounted

## Bump whenever the save Dictionary's shape changes, and add a migration
## step in from_save_dict() for older versions — never silently
## reinterpret an old save under a new shape (TDD §8).
## v2 (RZ-089) added total_safehouses_saved; from_save_dict() defaults it to
## 0 for a v1 save, which has no such key.
## v3 (RZ-144) added ability_unlocks; from_save_dict() defaults it to an
## empty Dictionary for a v1/v2 save, which has no such key.
const SAVE_VERSION := 3

signal commander_died(commander: Commander)

var seed_value: int
var difficulty_id: String
var gold: int
var commanders: Array = [] # Array[Commander]
var campaign_state: Dictionary
## RZ-089: cumulative safehouses saved across every mission this run, shown
## on the Run Summary screen (UX_UI.md §8). Per-mission counts are read off
## Safehouse.is_saved() in MissionController and folded in here at mission
## end — nothing else needs a per-mission breakdown.
var total_safehouses_saved: int = 0
var _roster_meta: Dictionary = {} # commander.id -> {"unit_class", "level", "unit_count"}
## RZ-144: commander.id -> true once that commander's class ability has been
## purchased (Economy.ability_cost(), spent in the Armory's Abilities tab).
## A separate table rather than a new roster_meta key so update_roster_meta()
## — called after every mission and on every level-up purchase — can't
## accidentally wipe a prior unlock by replacing the whole roster_meta entry.
## Absence means "not purchased"; nothing ever erases an entry once true
## (buying it is permanent for that commander, same spirit as a relic
## equip), including on death — matches trait_id/relic_id, which also
## aren't cleared when a commander falls (Roster screen history, RZ-086).
var _ability_unlocks: Dictionary = {} # commander.id -> bool

func _init(p_seed: int, p_difficulty_id: String) -> void:
	seed_value = p_seed
	difficulty_id = p_difficulty_id
	gold = 0
	campaign_state = {
		"visited_nodes": [],
		"lost_nodes": [],
		"progress_line_layer": 0,
		"current_node": null,
	}

## Starts a brand new run. `starting_gold` is supplied by the caller
## (economy.json's starting_gold, read by the scripts/ layer) rather than
## read from DataLoader here — core/ must never reference autoloads
## (ADR-0002).
static func new_run(p_seed: int, p_difficulty_id: String, starting_gold: int) -> RunState:
	var run_state := RunState.new(p_seed, p_difficulty_id)
	run_state.gold = starting_gold
	return run_state

## Adds a commander to the roster with their squad's current class/level/
## unit count — called when a commander is recruited, and again after each
## mission to refresh unit_count from the squad's surviving headcount.
func add_commander(commander: Commander, unit_class: String, level: int, unit_count: int) -> void:
	commanders.append(commander)
	_roster_meta[commander.id] = {"unit_class": unit_class, "level": level, "unit_count": unit_count}
	commander.died.connect(on_commander_died)

func update_roster_meta(commander_id: String, unit_class: String, level: int, unit_count: int) -> void:
	if _roster_meta.has(commander_id):
		_roster_meta[commander_id] = {"unit_class": unit_class, "level": level, "unit_count": unit_count}

func get_roster_meta(commander_id: String) -> Dictionary:
	return _roster_meta.get(commander_id, {})

## Called whenever a commander's HP reaches 0 (permadeath, GDD pillar 2).
## Removes their roster metadata so they can never field a squad again —
## the commander stays in `commanders` (marked not alive) so a
## fallen-commander history can still be shown (UX_UI.md §7).
func on_commander_died(commander: Commander) -> void:
	_roster_meta.erase(commander.id)
	commander_died.emit(commander)

func alive_commanders() -> Array:
	return commanders.filter(func(c: Commander): return c.alive)

## True once every commander has fallen (total wipe, GDD §12). Campaign
## completion isn't modeled yet (no CampaignState, RZ-081), so this only
## covers the wipe condition for now.
func is_run_over() -> bool:
	if commanders.is_empty():
		return false
	for commander in commanders:
		if commander.alive:
			return false
	return true

func spend_gold(amount: int) -> bool:
	if amount > gold:
		return false
	gold -= amount
	return true

func add_gold(amount: int) -> void:
	gold += amount

func add_safehouses_saved(count: int) -> void:
	total_safehouses_saved += count

func has_ability_unlocked(commander_id: String) -> bool:
	return _ability_unlocks.get(commander_id, false)

func unlock_ability(commander_id: String) -> void:
	_ability_unlocks[commander_id] = true

## Serializes to a Dictionary matching schemas/save_file.schema.json.
func to_save_dict() -> Dictionary:
	var commander_dicts: Array = []
	for commander in commanders:
		var meta: Dictionary = _roster_meta.get(commander.id, {"unit_class": "", "level": 1, "unit_count": 0})
		commander_dicts.append({
			"id": commander.id,
			"name": commander.display_name,
			"unit_class": meta.get("unit_class", ""),
			"level": meta.get("level", 1),
			"trait_id": commander.trait_id if commander.trait_id != "" else null,
			"relic_id": commander.relic_id if commander.relic_id != "" else null,
			"alive": commander.alive,
			"unit_count": meta.get("unit_count", 0),
		})
	return {
		"save_version": SAVE_VERSION,
		"seed": seed_value,
		"difficulty": difficulty_id,
		"gold": gold,
		"campaign_state": campaign_state.duplicate(true),
		"commanders": commander_dicts,
		"total_safehouses_saved": total_safehouses_saved,
		"ability_unlocks": _ability_unlocks.duplicate(),
	}

## Reconstructs a RunState from a save Dictionary. Dead commanders are
## restored via Commander.restore_state() (not die()) so this doesn't
## re-trigger on_commander_died()'s side effects for something that
## already happened in a previous session.
static func from_save_dict(data: Dictionary) -> RunState:
	var run_state := RunState.new(data.get("seed", 0), data.get("difficulty", "normal"))
	run_state.gold = data.get("gold", 0)
	# v1 saves (save_version 1) predate total_safehouses_saved (v2, RZ-089) —
	# default to 0 rather than failing to load an older save.
	run_state.total_safehouses_saved = data.get("total_safehouses_saved", 0)
	# v1/v2 saves predate ability_unlocks (v3, RZ-144) — default to an empty
	# Dictionary (nothing purchased) rather than failing to load an older save.
	run_state._ability_unlocks = (data.get("ability_unlocks", {}) as Dictionary).duplicate()

	var campaign: Dictionary = data.get("campaign_state", {})
	run_state.campaign_state = {
		"visited_nodes": (campaign.get("visited_nodes", []) as Array).duplicate(),
		"lost_nodes": (campaign.get("lost_nodes", []) as Array).duplicate(),
		"progress_line_layer": campaign.get("progress_line_layer", 0),
		"current_node": campaign.get("current_node", null),
	}

	for commander_dict in data.get("commanders", []):
		var trait_id: String = commander_dict.get("trait_id", "") if commander_dict.get("trait_id") != null else ""
		var relic_id: String = commander_dict.get("relic_id", "") if commander_dict.get("relic_id") != null else ""
		var commander := Commander.new(
			commander_dict.get("id", ""),
			commander_dict.get("name", ""),
			Commander.DEFAULT_MAX_HP,
			trait_id,
			relic_id,
		)
		commander.restore_state(commander_dict.get("alive", true))
		run_state.commanders.append(commander)

		if commander.alive:
			commander.died.connect(run_state.on_commander_died)
			run_state._roster_meta[commander.id] = {
				"unit_class": commander_dict.get("unit_class", ""),
				"level": commander_dict.get("level", 1),
				"unit_count": commander_dict.get("unit_count", 0),
			}

	return run_state
