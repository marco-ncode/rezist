# REZIST — Handoff

Live snapshot of "where things actually stand," updated at the end of every work session. If this file and `docs/ROADMAP.md` disagree, trust this one for current state and `docs/ROADMAP.md` for the plan. Read this after `docs/ONBOARDING.md` and before picking a task from `docs/TASKS.md`.

**Last updated:** 2026-09-25, Session 1 (see `AGENTS.md`), continuing on the `dev` branch. Most recent landed work: RZ-142 (exposed-commander last-stand combat), RZ-074 (Main Menu scene), RZ-088 (permadeath UI feedback), RZ-090 (mission-end autosave, wired to Continue), RZ-143 (fixed two scripts silently unable to load in the real engine since the original bootstrap — see "CI / Build Status" below, point 4, before trusting any earlier green-CI claim in this file).

---

## Where We Are

Milestone **M0 is complete**: the full documentation set, all data files + schemas, and a 90+ item backlog exist. Milestone **M1 (vertical slice) is partially complete**: the core engine and a genuinely playable single mission exist in code. Work is currently on the **`dev` branch** (the original PR to `main` was closed per request without merging — see `AGENTS.md`/git log for the merge commit).

**CI exists, is active, and was last confirmed green** on commit `50230ba` (`Passed: 52  Failed: 0`, see git log for the latest confirmation). It was briefly removed and then restored within the same session at the owner's request — see git history on `dev` if that back-and-forth needs tracing, it doesn't affect current state. See "CI / Build Status" below for the fuller story and one benign log quirk worth knowing about. A few M1 checklist items (danger indicator, minimap) also remain open regardless — Mission Prep (RZ-075) and the Main Menu (RZ-074) are now both done.

### What's actually implemented (code exists, matches its docs)

**Data layer** — all 12 `data/*.json` files + matching `schemas/*.schema.json`, validated clean:
```
python tools/validate_data.py   # → OK
```

**Core simulation** (`game/core/`, all pure/engine-agnostic per ADR-0002):
- `grid/TacticalGrid.gd`, `grid/Safehouse.gd` — tile grid, elevation, safehouse damage states
- `pathfinding/AStarPathfinder.gd` — A*, elevation-aware
- `sim/SimRng.gd` — seeded RNG with deterministic `derive()` for sub-streams
- `combat/CombatResolver.gd`, `combat/CombatResult.gd` — data-driven RPS combat (ADR-0006)
- `squad/Unit.gd`, `squad/Squad.gd`, `squad/Commander.gd` — squad movement/engagement, permadeath signal chain; once a squad's units are all dead, the exposed `Commander` becomes a duck-typed, targetable combat entity in their own right (RZ-142) — permadeath is now actually reachable through normal play, not just theoretically wired
- `abilities/Ability.gd`, `abilities/AbilityRegistry.gd`, `abilities/BreachAbility.gd` — only Breach (Riot) is implemented; Focused Volley/Line Charge are not (RZ-048)
- `enemy/Enemy.gd`, `enemy/EnemyAI.gd` — behavior-table-driven AI (swarm/tank_advance/ranged_kite/etc.)
- `waves/EntryPoint.gd`, `waves/WaveController.gd` — deterministic pre-flattened spawn schedule
- `economy/Economy.gd` — mission payout, upgrade/ability/relic cost formulas
- `procgen/MapGenerator.gd` — seeded mission-grid generation with a reachability-repair pass
- `run/RunState.gd`, `run/SaveManager.gd` (RZ-054/RZ-055) — roster (`Commander` + parallel class/level/unit_count metadata), gold, a placeholder `campaign_state` Dictionary shaped like the save schema, permadeath tracking (`on_commander_died`), `is_run_over()` (wipe only — campaign completion isn't modeled yet), and JSON save/load to `user://saves/<slot>.json`. **Now wired into the live mission flow** (RZ-141, see below) — but see the still-open gap noted under "What's documented but NOT implemented".

**Data runtime wrappers** (`game/data_runtime/`) — one per data file, all thin typed accessors.

**Autoloads** (`game/autoload/`): `DataLoader` (loads + validates all data at boot, builds `AbilityRegistry`), `AudioManager` (event→bus table, no real audio assets yet), `GameState` (RZ-141 — now the Node-side holder of a `RunState` instance, `GameState.run_state`, plus mission-scoped transient state: district id and MissionPrep's deployment-tile choice).

**Main Menu scene** (`game/scenes/MainMenu.tscn`, `game/scripts/ui/MainMenu.gd`, RZ-074):
- New Run opens an inline difficulty-select sub-panel (Easy/Normal/Hard/Very Hard, read from `data/difficulty.json` via `DataLoader.difficulty`, plus an optional seed field) per UX_UI.md §1, then calls `GameState.start_new_run()` and transitions to Mission Prep. UX_UI.md's wireframe says New Run/Continue go to the Campaign Map — both go to Mission Prep instead here, since the Campaign Map doesn't exist yet (RZ-080/081/082)
- Continue calls `SaveManager.load()`/`has_save()` against a single hardcoded save slot (`SaveManager.DEFAULT_SLOT = 0`) — disabled when no save exists. Since RZ-090 (see below), that's no longer always the case: `MissionController` now writes a save after every mission
- Quit calls `get_tree().quit()`
- No Settings screen (`docs/BACKLOG.md` marks it "Should", no spec exists to build from) and no save-slot selection UI (v1 is single-slot)

**Mission Prep scene** (`game/scenes/MissionPrep.tscn`, `game/scripts/ui/MissionPrepController.gd`, RZ-075, roster-aware since RZ-141):
- Regenerates the same mission grid `Mission.tscn` will (same seed + derive key, MapGenerator's determinism contract — no data passed between scenes except the final deployment choice)
- Highlights a deployment zone (open tiles within 3 tiles of the first safehouse)
- Squad count and names come from `GameState.run_state.alive_commanders()` — no longer hardcoded to 3. Player selects each squad via a bottom bar button labeled with the commander's real name, then clicks a highlighted tile to place it; a tile already taken by another squad is rejected
- `[Start]` only enables once every squad is placed; hands the chosen tiles to `GameState.mission_deployment_positions` and transitions to `Mission.tscn`. If the roster is empty (total wipe), `[Start]` stays disabled with a "this run is over" message instead of letting the player walk into a broken 0-squad mission — there's no real run-over screen yet (RZ-089)
- Still no hero-recruitment/army-composition choice (who's *in* the roster) — that's RZ-087, unrelated to squad placement
- Has its own fallback (`if GameState.run_state == null: GameState.start_new_run(-1, "normal")`) for when it's loaded directly in the editor without going through Main Menu first

**Playable scene** (`game/scenes/Main.tscn` → `MainMenu.tscn` → `MissionPrep.tscn` → `Mission.tscn`, `game/scripts/`):
- `Main.gd` is now a thin bootstrap that immediately hands off to `MainMenu.tscn` — New Run vs. Continue vs. Quit is decided there (RZ-074, see above)
- New Run seeds the same 3 placeholder Riot commanders (`J. Alvarez`/`D. Okafor`/`M. Torres`) the vertical slice always used — recruited once into the roster instead of being re-created fresh every mission
- Squads spawn from `GameState.run_state`'s roster at the player's chosen deployment tiles, with each squad's actual surviving unit count from the *previous* mission (not always a fresh 4) — falls back to auto-placement near the first safehouse if `Mission.tscn` is loaded directly, e.g. for quick manual testing
- At mission end, surviving squads' unit counts (and gold, on a win) are written back to `RunState` — losses now persist into the next mission instead of resetting
- Click a squad button (labeled with the commander's real name) → click a tile → squad paths there, engaging enemies in range automatically
- Slow-mo eases in on squad selection, out on order confirm (`Engine.time_scale`, per ADR-0004)
- Breach ability wired to the HUD ability button (arm → click target tile)
- Wave controller spawns Walker/Riot Zombie/Brute per `data/waves.json`'s `district_default_3wave` set
- Safehouses take damage-state hits when a zombie reaches them unopposed; visuals update
- Win (all waves cleared + battlefield clear) / lose (all squads wiped) both resolve to a simple HUD panel with gold payout
- A commander's exposure and death (RZ-142) each get a dedicated moment (RZ-088): a fading HUD toast (`HUD.show_toast()`) plus a distinct audio cue (`commander_exposed`/`commander_died`) — "%s is exposed!" the tick their last unit dies, "%s has fallen." the tick they do. Backs up the squad button's own persistent "✕"/disabled state, which only tells the player if they happen to already be looking at the HUD bar.
- **Every mission end now writes a save** (RZ-090): `_end_mission()` calls `SaveManager.save(GameState.run_state, SaveManager.DEFAULT_SLOT)` unconditionally, win or lose, right after roster metadata/gold are updated. This is the only save checkpoint that exists (no mid-mission saves, ADR-0007) and it's what makes the Main Menu's Continue button (RZ-074) actually usable in practice, not just correctly wired.
- 9 audio events fire through `AudioManager.play_event()` (no real SFX yet, but the pipeline is proven end-to-end)

**Tests** (`game/tests/`, run via `godot --headless --path game --script res://tests/run_tests.gd`):
`test_pathfinding.gd`, `test_combat_rps.gd`, `test_economy.gd`, `test_procgen_determinism.gd`, `test_save_load_roundtrip.gd`, `test_commander_exposure.gd`, plus `test_reporter.gd`/`run_tests.gd` infrastructure.

**Tooling:** `tools/validate_data.py` (schema + cross-reference validation), `tools/balance_report.py` (TTK matrices, gold curves — run it, output is sane).

**CI:** `.github/workflows/ci.yml` — data validation job + headless unit test job (downloads Godot 4.3 in-runner, cached, plus an `--import` warm-up step). See "CI / Build Status" below for current confidence level.

### What's documented but NOT implemented

- **Marksman, Barricade classes' abilities** — data entries exist (`data/units.json`, `data/unit_abilities.json`), but `focused_ranged_burst`/`line_impale_charge` have no `Ability` subclass yet (RZ-048). `AbilityRegistry` and `DataLoader`'s boot-time check will `assert()`-fail loudly if you try to activate them, by design (ARCHITECTURE.md §6 invariant) — this is expected until RZ-048 lands, not a bug.
- **Traits/relics beyond data** — all 10 traits and 8 relics are fully specified in `data/traits.json`/`data/relics.json` and `CombatResolver`/`Economy` already read trait modifiers generically, but relics have no runtime effect implementation yet (no `RelicEffect` system exists — tracked as RZ-109).
- **Campaign layer** — `CampaignGenerator`, `CampaignState`, the Campaign Map scene, fog of war, split-the-party: none exist yet (RZ-080/081/082/084). The vertical slice plays exactly one hardcoded district. `RunState.campaign_state` is a placeholder Dictionary shaped like the save schema, ready for these to populate once they exist.
- **Armory/Upgrade, Roster, Game Over/Run Summary screens** — none exist (RZ-085, RZ-086, RZ-089). There's a Main Menu now (RZ-074) and mission-end saving now works (RZ-090), but there's still no way to view the roster or spend gold outside a mission, and a total wipe just leaves `[Start]` disabled on Mission Prep with a text message rather than a real run-over screen.
- **Danger indicator, minimap** — not implemented (RZ-068, RZ-127).
- **Enemy types beyond the 3 wired into the default wave set** — Spitter, Brute Spitter, Thrower, Leaper, Colossus all have full `data/enemies.json` entries and `EnemyAI` behaviors already support their `behavior` values generically, but no wave_set currently spawns them except `transit_hub_5wave` (unused by the vertical slice's hardcoded `residential` district).
- **Real art/audio** — 100% primitive placeholder (`ColorRect`s, palette-matched) per ADR-0008/`docs/ASSET_PIPELINE.md`. No audio streams at all yet, only the event pipeline.

## CI / Build Status

The authoring session had no network access to fetch the Godot binary, so none of this code had ever been engine-verified before its first push. Once pushed, CI (which does have network access) found and — in order — these got fixed:

1. **Godot download itself was broken.** `GODOT_VERSION: "4.3.0"` is wrong; Godot tags stable releases as `"4.3"` (no patch component), and `curl` lacked `-f` so it silently saved the resulting 404 page as `godot.zip`. Fixed: correct version string, `curl -f` with retries, GitHub-release fallback.
2. **Global `class_name` resolution failed on a fresh checkout.** A bare `--script` invocation doesn't build `.godot/global_script_class_cache.cfg`. Fixed: CI now runs `godot --headless --path game --import` once first. `game/tests/run_tests.gd` also `preload()`s its four direct test-file dependencies as defense in depth.
3. **Two real GDScript bugs**, found once the above stopped masking them (last observed run: 18/21 test assertions passing, all 3 failures traceable to bug (a) below):
   - `game/data_runtime/UnitData.gd` — `get_class()` shadowed the native `Object.get_class()`, a fatal compile error that cascaded into `CombatResolver`, `BreachAbility`, `AbilityRegistry`, `DataLoader` all failing to load. **Fixed:** renamed to `get_unit_class()`, call sites updated (`Squad.gd`, `MissionController.gd`).
   - `game/core/combat/CombatResolver.gd` — the `staggered` local failed Godot's static type inference. **Fixed:** added an explicit `: bool` annotation.
4. **RZ-143 (found much later, 2026-09-25): `EnemyAI.gd` and `MissionController.gd` had been silently failing to load in the real engine since the original bootstrap commit.** `--import`'s log printed `ERROR: Failed to load script ... with error "Parse error"` for both files on *every single CI run from the very first one* — `Vector2i` has no `dot()` method (`EnemyAI._is_frontal_attack`, always broken), plus two `:=`-inferred-from-a-Variant-value errors in each file (Godot treats that specific case as a hard error, not a suppressible warning). This was never caught because no test file references either script, so it never affected the Passed/Failed count, and every "CI confirmed green" claim in this doc up to this point — including the `dd680cf`/`628af0e`/`50230ba` ones directly above — was made by reading only the Test Summary line, not the full `--import` log. **The practical impact was severe: the mission scene could never have actually run in the Godot editor**, since `MissionController.gd` (the scene's own script) failed to parse. **Fixed:** manual dot-product in `_is_frontal_attack` (`to_enemy.x * facing.x + to_enemy.y * facing.y`), explicit `: Variant` / `: int` / `: bool` annotations in place of `:=` at the four inference sites. Also fixed a related bug in `test_commander_exposure.gd` itself (added same day, RZ-142): a plain `int` captured by a signal-connected lambda is captured **by value** in GDScript, so `func(_s): exposure_count += 1` was silently mutating a local copy — all 5 of that file's signal-count assertions read back `0` instead of `1`. Fixed by capturing a single-element `Array` instead (a reference type) and mutating `exposure_count[0]`.

**Confirmed:** CI run on `dev` commit `dd680cf` was the first run where the *headless test suite itself* went green (`Passed: 29  Failed: 0`), but per RZ-143 above, that did **not** mean the codebase was actually loadable end-to-end — two scene-layer scripts were broken the whole time and no test caught it. Every commit since has kept the test suite green; most recently before RZ-143's fix, commit `50230ba` reported `Passed: 52  Failed: 0`. **The lesson going forward: always check the full CI log for `SCRIPT ERROR`/`Failed to load script` lines, not just the final Passed/Failed count** — a full green test summary only proves the specific files the tests import are loadable, not the whole project. If you're picking this up after a gap, don't trust any of these numbers — check the actual latest CI run on `dev`, logs included.

**One benign log quirk, worth knowing about:** right after the "Passed: 29 Failed: 0" summary, the log shows `SCRIPT ERROR: Assertion failed: DataLoader: ability 'focused_volley' declares effect 'focused_ranged_burst' with no registered implementation` — this is `DataLoader._validate_ability_implementations()` (ARCHITECTURE.md §6) doing exactly what it's documented to do (Focused Volley genuinely has no `Ability` subclass yet, RZ-048). It doesn't fail the job because **`assert()` in GDScript only halts execution when a debugger is attached** — outside the editor (headless, or an exported build) it just logs and continues. This means ARCHITECTURE.md §6's "DataLoader fails boot if not" is currently aspirational, not actually enforced outside the editor. Worth a real fix later (e.g. `push_error` + explicit early exit, or moving the check into a test) if RZ-048 stays unimplemented for a while and someone wants a build that hard-fails on this rather than silently continuing — not urgent since the vertical slice never activates Focused Volley (only Riot squads spawn).

**Command reference (also in `README.md`):**
```
godot --headless --path game --import
godot --headless --path game --script res://tests/run_tests.gd
```

## Next 3 Tasks (recommended order)

1. **RZ-089 — Run-over detection (total wipe) + summary screen.** Today a total wipe just leaves `[Start]` disabled on Mission Prep with a text message ("this run is over") — there's no actual Game Over / Run Summary screen (UX_UI.md §8) with a way to start a new run from there. `RunState.is_run_over()` already detects the wipe correctly; nothing consumes it yet.
2. **RZ-086 — Roster/Commander screen.** Spec exists (UX_UI.md §7), its only dependency (RZ-054) is done, and it's now more useful than before RZ-090: a player picking Continue on the Main Menu has no way to see who's in the roster, their trait/relic, or the fallen-commander history before jumping into Mission Prep.
3. Open the project in the actual Godot editor and playtest Main → Main Menu → Mission Prep → Mission → (repeat) by eye (CI proves the code *compiles and the unit tests pass*, not that the flow *feels* right). In particular: verify the new Main Menu's difficulty sub-panel reads clearly, that Continue actually offers a save after playing one mission and loading it resumes the right roster/gold state (RZ-090), deployment-zone tiles are visually distinct enough, squad buttons showing real commander names read well, a squad's unit count visibly carrying over between missions is legible without a number (ADR-0005), that an exposed last-stand commander (RZ-142) reads clearly as "vulnerable" on screen (currently just a slightly larger amber square, same color as a normal commander marker), and that the RZ-088 permadeath toasts are readable/well-timed rather than flashing past too fast.

## Known Simplifications (intentional, not bugs)

- `EnemyAI._is_frontal_attack` uses a coarse dot-product facing check, not a full facing-arc model (noted in code comment) — fine for v1, revisit during the M4 balance pass if shield-blocking feels unreliable.
- `MapGenerator` only ever emits `open`/`wall`/`rubble` tile types + elevation 0/1 — `water`/`stairs`/`door`/`roof`/`sewer` exist in `TacticalGrid`'s type list and are handled generically by movement/LOS code, but nothing generates them yet. Adding them is a `MapGenerator` content task, not an architecture change.
- Ability cooldown is shown only as enabled/disabled on the HUD button, not a filling ring (UX_UI.md's documented target) — cosmetic gap, tracked implicitly under RZ-124.
- `Squad.order_move_to` formation spread uses a simple expanding-ring search, not true crowd/flow-field formation — good enough at 4-6 units per squad; revisit only if playtesting shows units colliding/overlapping badly.
