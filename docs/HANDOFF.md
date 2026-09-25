# REZIST — Handoff

Live snapshot of "where things actually stand," updated at the end of every work session. If this file and `docs/ROADMAP.md` disagree, trust this one for current state and `docs/ROADMAP.md` for the plan. Read this after `docs/ONBOARDING.md` and before picking a task from `docs/TASKS.md`.

**Last updated:** 2026-09-25, Session 1 (see `AGENTS.md`), continuing on the `dev` branch.

---

## Where We Are

Milestone **M0 is complete**: the full documentation set, all data files + schemas, and a 90+ item backlog exist. Milestone **M1 (vertical slice) is partially complete**: the core engine and a genuinely playable single mission exist in code. Work is currently on the **`dev` branch** (the original PR to `main` was closed per request without merging — see `AGENTS.md`/git log for the merge commit).

**CI exists, is active, and was last confirmed green** on commit `50230ba` (`Passed: 52  Failed: 0`, see git log for the latest confirmation). It was briefly removed and then restored within the same session at the owner's request — see git history on `dev` if that back-and-forth needs tracing, it doesn't affect current state. See "CI / Build Status" below for the fuller story and one benign log quirk worth knowing about. A few M1 checklist items (Main Menu, danger indicator) also remain open regardless — Mission Prep itself is now done (RZ-075).

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
- `squad/Unit.gd`, `squad/Squad.gd`, `squad/Commander.gd` — squad movement/engagement, permadeath signal chain
- `abilities/Ability.gd`, `abilities/AbilityRegistry.gd`, `abilities/BreachAbility.gd` — only Breach (Riot) is implemented; Focused Volley/Line Charge are not (RZ-048)
- `enemy/Enemy.gd`, `enemy/EnemyAI.gd` — behavior-table-driven AI (swarm/tank_advance/ranged_kite/etc.)
- `waves/EntryPoint.gd`, `waves/WaveController.gd` — deterministic pre-flattened spawn schedule
- `economy/Economy.gd` — mission payout, upgrade/ability/relic cost formulas
- `procgen/MapGenerator.gd` — seeded mission-grid generation with a reachability-repair pass
- `run/RunState.gd`, `run/SaveManager.gd` (RZ-054/RZ-055) — roster (`Commander` + parallel class/level/unit_count metadata), gold, a placeholder `campaign_state` Dictionary shaped like the save schema, permadeath tracking (`on_commander_died`), `is_run_over()` (wipe only — campaign completion isn't modeled yet), and JSON save/load to `user://saves/<slot>.json`. **Now wired into the live mission flow** (RZ-141, see below) — but see the still-open gap noted under "What's documented but NOT implemented".

**Data runtime wrappers** (`game/data_runtime/`) — one per data file, all thin typed accessors.

**Autoloads** (`game/autoload/`): `DataLoader` (loads + validates all data at boot, builds `AbilityRegistry`), `AudioManager` (event→bus table, no real audio assets yet), `GameState` (RZ-141 — now the Node-side holder of a `RunState` instance, `GameState.run_state`, plus mission-scoped transient state: district id and MissionPrep's deployment-tile choice).

**Mission Prep scene** (`game/scenes/MissionPrep.tscn`, `game/scripts/ui/MissionPrepController.gd`, RZ-075, roster-aware since RZ-141):
- Regenerates the same mission grid `Mission.tscn` will (same seed + derive key, MapGenerator's determinism contract — no data passed between scenes except the final deployment choice)
- Highlights a deployment zone (open tiles within 3 tiles of the first safehouse)
- Squad count and names come from `GameState.run_state.alive_commanders()` — no longer hardcoded to 3. Player selects each squad via a bottom bar button labeled with the commander's real name, then clicks a highlighted tile to place it; a tile already taken by another squad is rejected
- `[Start]` only enables once every squad is placed; hands the chosen tiles to `GameState.mission_deployment_positions` and transitions to `Mission.tscn`. If the roster is empty (total wipe), `[Start]` stays disabled with a "this run is over" message instead of letting the player walk into a broken 0-squad mission — there's no real run-over screen yet (RZ-089)
- Still no hero-recruitment/army-composition choice (who's *in* the roster) — that's RZ-087/RZ-074, unrelated to squad placement

**Playable scene** (`game/scenes/Main.tscn` → `MissionPrep.tscn` → `Mission.tscn`, `game/scripts/`):
- `Main.gd` calls `GameState.start_new_run()`, which creates a `RunState` and seeds the same 3 placeholder Riot commanders (`J. Alvarez`/`D. Okafor`/`M. Torres`) the vertical slice always used — now recruited once into the roster instead of being re-created fresh every mission
- Boots into Mission Prep for a generated `residential` district mission (no Main Menu yet)
- Squads spawn from `GameState.run_state`'s roster at the player's chosen deployment tiles, with each squad's actual surviving unit count from the *previous* mission (not always a fresh 4) — falls back to auto-placement near the first safehouse if `Mission.tscn` is loaded directly, e.g. for quick manual testing
- At mission end, surviving squads' unit counts (and gold, on a win) are written back to `RunState` — losses now persist into the next mission instead of resetting
- Click a squad button (labeled with the commander's real name) → click a tile → squad paths there, engaging enemies in range automatically
- Slow-mo eases in on squad selection, out on order confirm (`Engine.time_scale`, per ADR-0004)
- Breach ability wired to the HUD ability button (arm → click target tile)
- Wave controller spawns Walker/Riot Zombie/Brute per `data/waves.json`'s `district_default_3wave` set
- Safehouses take damage-state hits when a zombie reaches them unopposed; visuals update
- Win (all waves cleared + battlefield clear) / lose (all squads wiped) both resolve to a simple HUD panel with gold payout
- 8 audio events fire through `AudioManager.play_event()` (no real SFX yet, but the pipeline is proven end-to-end)

**Tests** (`game/tests/`, run via `godot --headless --path game --script res://tests/run_tests.gd`):
`test_pathfinding.gd`, `test_combat_rps.gd`, `test_economy.gd`, `test_procgen_determinism.gd`, `test_save_load_roundtrip.gd`, plus `test_reporter.gd`/`run_tests.gd` infrastructure.

**Tooling:** `tools/validate_data.py` (schema + cross-reference validation), `tools/balance_report.py` (TTK matrices, gold curves — run it, output is sane).

**CI:** `.github/workflows/ci.yml` — data validation job + headless unit test job (downloads Godot 4.3 in-runner, cached, plus an `--import` warm-up step). See "CI / Build Status" below for current confidence level.

### What's documented but NOT implemented

- **Marksman, Barricade classes' abilities** — data entries exist (`data/units.json`, `data/unit_abilities.json`), but `focused_ranged_burst`/`line_impale_charge` have no `Ability` subclass yet (RZ-048). `AbilityRegistry` and `DataLoader`'s boot-time check will `assert()`-fail loudly if you try to activate them, by design (ARCHITECTURE.md §6 invariant) — this is expected until RZ-048 lands, not a bug.
- **Traits/relics beyond data** — all 10 traits and 8 relics are fully specified in `data/traits.json`/`data/relics.json` and `CombatResolver`/`Economy` already read trait modifiers generically, but relics have no runtime effect implementation yet (no `RelicEffect` system exists — tracked as RZ-109).
- **Campaign layer** — `CampaignGenerator`, `CampaignState`, the Campaign Map scene, fog of war, split-the-party: none exist yet (RZ-080/081/082/084). The vertical slice plays exactly one hardcoded district. `RunState.campaign_state` is a placeholder Dictionary shaped like the save schema, ready for these to populate once they exist.
- **Nothing ever damages a `Commander` in a live mission, so permadeath still can't actually happen through normal play.** RZ-141 wired the roster correctly — `MissionController` now hands the *same* `Commander` object to `Squad` that `RunState.commanders` holds, and `RunState.add_commander()` already connects `commander.died` to `RunState.on_commander_died()` — so if a commander ever died mid-mission, RunState would hear about it automatically, no extra glue code needed. But `Commander.apply_damage()`/`die()` are never called anywhere in `core/squad/`, `core/enemy/`, or the mission scripts today. When a squad's last unit dies, `Squad.commander_lost` fires correctly (GDD's "commander fights on alone" rule) but nothing then makes the exposed commander targetable or vulnerable — they just sit on the grid, immortal. **Tracked as RZ-142.** Until RZ-142 lands, `SaveManager.save()` also isn't called from anywhere in the mission flow yet — there's no natural "end of mission, offer to save" moment implemented (that's part of RZ-090, gated on RZ-074's Main Menu existing to have a "Continue" option to load into).
- **Main Menu, Armory/Upgrade, Roster, Game Over/Run Summary screens** — none exist (RZ-074, RZ-085, RZ-086, RZ-089). `Main.gd` calls `GameState.start_new_run()` directly with a random seed on every launch; there's no way to choose difficulty, view the roster, spend gold, or continue a save yet. (Mission Prep itself now exists — RZ-075, see above.)
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

**Confirmed:** CI run on `dev` commit `dd680cf` was the first fully green run (`Passed: 29  Failed: 0`) — the first time this codebase was confirmed to actually run correctly in a real Godot engine. Every commit since (Mission Prep, RunState/SaveManager, RunState wiring) has stayed green; most recently commit `50230ba` reported `Passed: 52  Failed: 0`. If you're picking this up after a gap, don't trust this number — check the actual latest CI run on `dev`.

**One benign log quirk, worth knowing about:** right after the "Passed: 29 Failed: 0" summary, the log shows `SCRIPT ERROR: Assertion failed: DataLoader: ability 'focused_volley' declares effect 'focused_ranged_burst' with no registered implementation` — this is `DataLoader._validate_ability_implementations()` (ARCHITECTURE.md §6) doing exactly what it's documented to do (Focused Volley genuinely has no `Ability` subclass yet, RZ-048). It doesn't fail the job because **`assert()` in GDScript only halts execution when a debugger is attached** — outside the editor (headless, or an exported build) it just logs and continues. This means ARCHITECTURE.md §6's "DataLoader fails boot if not" is currently aspirational, not actually enforced outside the editor. Worth a real fix later (e.g. `push_error` + explicit early exit, or moving the check into a test) if RZ-048 stays unimplemented for a while and someone wants a build that hard-fails on this rather than silently continuing — not urgent since the vertical slice never activates Focused Volley (only Riot squads spawn).

**Command reference (also in `README.md`):**
```
godot --headless --path game --import
godot --headless --path game --script res://tests/run_tests.gd
```

## Next 3 Tasks (recommended order)

1. **RZ-142 — Implement exposed-commander vulnerability (last-stand combat)**, so permadeath can actually happen through normal play. This is the real payoff of RZ-141's wiring — right now a dying commander is only theoretically possible, never practically reachable.
2. **RZ-074 — Main Menu scene**, so `Main.gd` stops skipping straight into Mission Prep with a random seed every launch, and has somewhere to put "New Run" (create a `RunState`) vs. "Continue" (`SaveManager.load()`) vs. difficulty selection.
3. Open the project in the actual Godot editor and playtest Main → Mission Prep → Mission → (repeat) by eye (CI proves the code *compiles and the unit tests pass*, not that the flow *feels* right). In particular: verify deployment-zone tiles are visually distinct enough, that squad buttons showing real commander names read well, and that a squad's unit count visibly carrying over between missions is legible without a number (ADR-0005 — currently just fewer dots on the HUD button).

## Known Simplifications (intentional, not bugs)

- `EnemyAI._is_frontal_attack` uses a coarse dot-product facing check, not a full facing-arc model (noted in code comment) — fine for v1, revisit during the M4 balance pass if shield-blocking feels unreliable.
- `MapGenerator` only ever emits `open`/`wall`/`rubble` tile types + elevation 0/1 — `water`/`stairs`/`door`/`roof`/`sewer` exist in `TacticalGrid`'s type list and are handled generically by movement/LOS code, but nothing generates them yet. Adding them is a `MapGenerator` content task, not an architecture change.
- Ability cooldown is shown only as enabled/disabled on the HUD button, not a filling ring (UX_UI.md's documented target) — cosmetic gap, tracked implicitly under RZ-124.
- `Squad.order_move_to` formation spread uses a simple expanding-ring search, not true crowd/flow-field formation — good enough at 4-6 units per squad; revisit only if playtesting shows units colliding/overlapping badly.
