# Changelog

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions are project milestones (`M0`, `M1`, ...) until a first numbered release ships.

## [Unreleased]

### Fixed
- `.github/workflows/ci.yml` downloaded a nonexistent Godot version (`4.3.0` instead of the correct release tag `4.3`), and `curl` lacked `-f` so it silently saved the resulting error page as `godot.zip` instead of failing loudly. Corrected the version string, added `-f`/retries, and a GitHub-release fallback if the tuxfamily mirror is unreachable.
- CI: added a `godot --headless --path game --import` warm-up step before running tests — a fresh checkout has no `.godot/global_script_class_cache.cfg` yet, so a bare `--script` invocation failed to resolve any cross-file `class_name` reference (`Identifier "X" not declared in the current scope`). Also made `game/tests/run_tests.gd` `preload()` its four test-file dependencies instead of relying on the global cache for those specific references.
- `game/data_runtime/UnitData.gd` — `get_class()` shadowed the native `Object.get_class()` method, a fatal compile error that cascaded into `CombatResolver`, `BreachAbility`, `AbilityRegistry`, and `DataLoader` all failing to load. Renamed to `get_unit_class()` (and updated its call sites in `Squad.gd`, `MissionController.gd`).
- `game/core/combat/CombatResolver.gd` — the `staggered` local variable failed Godot's static type inference; added an explicit `: bool` annotation.

Note: the CI pipeline was briefly removed by request and then restored once confirmed to be wanted — see git history on `dev` around commits `333e031`/this one if that back-and-forth needs tracing.

### Added
- Full M0 documentation set: GDD, TDD, ARCHITECTURE, DECISIONS (ADR-0001..0010), ROADMAP, BACKLOG (90+ tasks), TASKS, CONTRIBUTING, CODE_STYLE, GLOSSARY, BALANCE, ASSET_PIPELINE, DATA_SCHEMA, ART_BIBLE, AUDIO_BIBLE, UX_UI, PLAYTEST_CHECKLIST, ONBOARDING, PERFORMANCE, HANDOFF.
- Data-driven content: `data/units.json`, `unit_abilities.json`, `enemies.json`, `waves.json`, `traits.json`, `relics.json`, `economy.json`, `difficulty.json`, `districts.json`, `biomes.json`, `campaign_nodes.json`, plus matching `schemas/*.schema.json`.
- Godot 4 project scaffold (`game/`) with engine-agnostic `core/` simulation modules: grid, pathfinding (A*), combat resolver, squad/unit/commander, abilities (Breach), enemy AI, waves, economy, procedural map generation.
- Vertical-slice playable mission scene: grid rendering with elevation, squad selection/movement with slow-mo, wave spawner, safehouse damage states, win/lose resolution, minimal HUD, placeholder audio hooks.
- `game/tests/` headless GDScript test runner + tests for pathfinding, combat RPS rules, economy, and procgen determinism.
- `tools/validate_data.py` (JSON Schema validation) and `tools/balance_report.py` (derived balance tables).
- CI pipeline (`.github/workflows/ci.yml`): data validation + headless unit tests on push.
- Repo scaffolding: `LICENSE` (MIT), `.gitignore`, `.editorconfig`, `AGENTS.md`, `CONTRIBUTORS.md`.

## [M0] — Foundations
Documentation, schemas, and backlog established. See Roadmap for milestone criteria.
