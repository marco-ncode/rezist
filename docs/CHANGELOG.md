# Changelog

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions are project milestones (`M0`, `M1`, ...) until a first numbered release ships.

## [Unreleased]

### Removed
- `.github/workflows/ci.yml` — removed by explicit request; no CI pipeline is wanted in this repo at this time. Before removal it ran long enough to catch two real GDScript bugs (still unfixed, tracked as RZ-139/RZ-140 in `docs/BACKLOG.md`) and two workflow-itself issues (fixed while it existed, see below, and preserved in `docs/HANDOFF.md` "CI Findings (Historical)" in case CI is reintroduced later).

### Fixed (while CI still existed — the workflow file above is gone, but these fixes to other files remain)
- `.github/workflows/ci.yml` (now removed) downloaded a nonexistent Godot version (`4.3.0` instead of the correct release tag `4.3`), and `curl` lacked `-f` so it silently saved the resulting error page as `godot.zip` instead of failing loudly.
- `.github/workflows/ci.yml` (now removed) lacked a step to warm up Godot's global script-class cache before running tests — a fresh checkout has no `.godot/global_script_class_cache.cfg` yet, so a bare `--script` invocation failed to resolve any cross-file `class_name` reference (`Identifier "X" not declared in the current scope`). `game/tests/run_tests.gd` still `preload()`s its four test-file dependencies as defense in depth, regardless of CI's presence.

### Added
- Full M0 documentation set: GDD, TDD, ARCHITECTURE, DECISIONS (ADR-0001..0010), ROADMAP, BACKLOG (90+ tasks), TASKS, CONTRIBUTING, CODE_STYLE, GLOSSARY, BALANCE, ASSET_PIPELINE, DATA_SCHEMA, ART_BIBLE, AUDIO_BIBLE, UX_UI, PLAYTEST_CHECKLIST, ONBOARDING, PERFORMANCE, HANDOFF.
- Data-driven content: `data/units.json`, `unit_abilities.json`, `enemies.json`, `waves.json`, `traits.json`, `relics.json`, `economy.json`, `difficulty.json`, `districts.json`, `biomes.json`, `campaign_nodes.json`, plus matching `schemas/*.schema.json`.
- Godot 4 project scaffold (`game/`) with engine-agnostic `core/` simulation modules: grid, pathfinding (A*), combat resolver, squad/unit/commander, abilities (Breach), enemy AI, waves, economy, procedural map generation.
- Vertical-slice playable mission scene: grid rendering with elevation, squad selection/movement with slow-mo, wave spawner, safehouse damage states, win/lose resolution, minimal HUD, placeholder audio hooks.
- `game/tests/` headless GDScript test runner + tests for pathfinding, combat RPS rules, economy, and procgen determinism (run manually — see README, no CI).
- `tools/validate_data.py` (JSON Schema validation) and `tools/balance_report.py` (derived balance tables).
- Repo scaffolding: `LICENSE` (MIT), `.gitignore`, `.editorconfig`, `AGENTS.md`, `CONTRIBUTORS.md`.

## [M0] — Foundations
Documentation, schemas, and backlog established. See Roadmap for milestone criteria.
