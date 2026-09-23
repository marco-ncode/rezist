# REZIST — Handoff

Live snapshot of "where things actually stand," updated at the end of every work session. If this file and `docs/ROADMAP.md` disagree, trust this one for current state and `docs/ROADMAP.md` for the plan. Read this after `docs/ONBOARDING.md` and before picking a task from `docs/TASKS.md`.

**Last updated:** 2026-09-23, Session 1 (see `AGENTS.md`), post-PR follow-up on the `dev` branch.

---

## Where We Are

Milestone **M0 is complete**: the full documentation set, all data files + schemas, and a 90+ item backlog exist. Milestone **M1 (vertical slice) is partially complete**: the core engine and a genuinely playable single mission exist in code. Work is currently on the **`dev` branch** (the original PR to `main` was closed per request without merging — see `AGENTS.md`/git log for the merge commit).

**CI exists and is active** (`.github/workflows/ci.yml`). It was briefly removed and then restored within the same session at the owner's request — see git history on `dev` if that back-and-forth needs tracing, it doesn't affect current state. Both real bugs CI caught (see "CI / Build Status" below) are now fixed; the fix has not yet been confirmed by an actual green CI run as of this update. A few M1 checklist items (Main Menu, Mission Prep/deployment screen, danger indicator) also remain open regardless.

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

**Data runtime wrappers** (`game/data_runtime/`) — one per data file, all thin typed accessors.

**Autoloads** (`game/autoload/`): `DataLoader` (loads + validates all data at boot, builds `AbilityRegistry`), `AudioManager` (event→bus table, no real audio assets yet), `GameState` (seed/difficulty/gold holder — will be superseded by `RunState` once RZ-054 lands).

**Playable scene** (`game/scenes/Main.tscn` → `Mission.tscn`, `game/scripts/`):
- Boots straight into a generated `residential` district mission (no Main Menu yet)
- 3 Riot squads (4 units each) spawn near the first safehouse
- Click a squad button (or squad, once map-click-to-select is added — currently HUD-button-only) → click a tile → squad paths there, engaging enemies in range automatically
- Slow-mo eases in on squad selection, out on order confirm (`Engine.time_scale`, per ADR-0004)
- Breach ability wired to the HUD ability button (arm → click target tile)
- Wave controller spawns Walker/Riot Zombie/Brute per `data/waves.json`'s `district_default_3wave` set
- Safehouses take damage-state hits when a zombie reaches them unopposed; visuals update
- Win (all waves cleared + battlefield clear) / lose (all squads wiped) both resolve to a simple HUD panel with gold payout
- 8 audio events fire through `AudioManager.play_event()` (no real SFX yet, but the pipeline is proven end-to-end)

**Tests** (`game/tests/`, run via `godot --headless --path game --script res://tests/run_tests.gd`):
`test_pathfinding.gd`, `test_combat_rps.gd`, `test_economy.gd`, `test_procgen_determinism.gd`, plus `test_reporter.gd`/`run_tests.gd` infrastructure.

**Tooling:** `tools/validate_data.py` (schema + cross-reference validation), `tools/balance_report.py` (TTK matrices, gold curves — run it, output is sane).

**CI:** `.github/workflows/ci.yml` — data validation job + headless unit test job (downloads Godot 4.3 in-runner, cached, plus an `--import` warm-up step). See "CI / Build Status" below for current confidence level.

### What's documented but NOT implemented

- **Marksman, Barricade classes' abilities** — data entries exist (`data/units.json`, `data/unit_abilities.json`), but `focused_ranged_burst`/`line_impale_charge` have no `Ability` subclass yet (RZ-048). `AbilityRegistry` and `DataLoader`'s boot-time check will `assert()`-fail loudly if you try to activate them, by design (ARCHITECTURE.md §6 invariant) — this is expected until RZ-048 lands, not a bug.
- **Traits/relics beyond data** — all 10 traits and 8 relics are fully specified in `data/traits.json`/`data/relics.json` and `CombatResolver`/`Economy` already read trait modifiers generically, but relics have no runtime effect implementation yet (no `RelicEffect` system exists — tracked as RZ-109).
- **Campaign layer** — `CampaignGenerator`, `CampaignState`, the Campaign Map scene, fog of war, split-the-party: none exist yet (RZ-080/081/082/084). The vertical slice plays exactly one hardcoded district.
- **Run/meta layer** — `RunState`, `SaveManager`: don't exist yet (RZ-054/055). `GameState` autoload is a deliberately temporary stand-in holding just seed/difficulty/gold.
- **Main Menu, Mission Prep (deployment), Armory/Upgrade, Roster, Game Over/Run Summary screens** — none exist (RZ-074, RZ-075, RZ-085, RZ-086, RZ-089). `Main.gd` skips straight into a mission with auto-placed squads.
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

**Not yet confirmed:** whether a fresh CI run on the current `dev` head is fully green — these fixes haven't been observed passing in an actual CI run yet, only reasoned through by hand. This is the immediate next thing to check.

**Command reference (also in `README.md`):**
```
godot --headless --path game --import
godot --headless --path game --script res://tests/run_tests.gd
```
Update this section once a CI run (or a manual run of the two commands above) confirms all tests pass, and note it in `docs/CHANGELOG.md`.

## Next 3 Tasks (recommended order)

1. **Confirm CI is fully green on `dev`** (see "CI / Build Status" above) — if anything still fails, fix it next; only then open the project in the editor and actually play the vertical slice mission.
2. **RZ-075 — Mission Prep screen**, so squads are player-deployed instead of auto-placed; this is the last real gap in the GDD's described mission structure (GDD §9) that's still missing from the playable loop.
3. **RZ-054 + RZ-055 — RunState + SaveManager**, unlocking the whole M2 run-systems chain (permadeath persistence, save/load, and everything the Campaign Map / Armory screens need to hang off of).

## Known Simplifications (intentional, not bugs)

- `EnemyAI._is_frontal_attack` uses a coarse dot-product facing check, not a full facing-arc model (noted in code comment) — fine for v1, revisit during the M4 balance pass if shield-blocking feels unreliable.
- `MapGenerator` only ever emits `open`/`wall`/`rubble` tile types + elevation 0/1 — `water`/`stairs`/`door`/`roof`/`sewer` exist in `TacticalGrid`'s type list and are handled generically by movement/LOS code, but nothing generates them yet. Adding them is a `MapGenerator` content task, not an architecture change.
- Ability cooldown is shown only as enabled/disabled on the HUD button, not a filling ring (UX_UI.md's documented target) — cosmetic gap, tracked implicitly under RZ-124.
- `Squad.order_move_to` formation spread uses a simple expanding-ring search, not true crowd/flow-field formation — good enough at 4-6 units per squad; revisit only if playtesting shows units colliding/overlapping badly.
