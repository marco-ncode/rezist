# AGENTS

Registry of agent/human contributions, for a multi-agent workflow where knowing "who touched what, and what's next" matters more than a standard commit log alone conveys. Append a new entry per work session — don't edit past entries except to fix a factual error.

---

## Session 1 — Foundations + Vertical Slice Bootstrap

- **Agent:** Claude (Sonnet 5), autonomous session via Claude Code
- **Date:** 2026-09-23
- **Scope:** Milestone M0 (full documentation set, data files, JSON schemas) and a first pass at M1 (Godot project scaffold, core simulation modules, a playable single-mission vertical slice, headless tests, CI, tooling).

### What was done
- Wrote the full `docs/` set: GDD, TDD, ARCHITECTURE, DECISIONS (ADR-0001..0010), ROADMAP, BACKLOG (90+ atomic tasks), TASKS, CONTRIBUTING, CODE_STYLE, GLOSSARY, BALANCE, ASSET_PIPELINE, DATA_SCHEMA, ART_BIBLE, AUDIO_BIBLE, UX_UI, PLAYTEST_CHECKLIST, ONBOARDING, CHANGELOG, PERFORMANCE, HANDOFF.
- Authored all `data/*.json` (units, unit_abilities, enemies, waves, traits, relics, economy, difficulty, districts, biomes, campaign_nodes, audio_events) with matching `schemas/*.schema.json`, validated clean by `tools/validate_data.py`.
- Scaffolded the Godot 4.3 project at `game/` with autoloads (`DataLoader`, `AudioManager`, `GameState`) and engine-agnostic `core/` modules: grid, pathfinding (A*), combat resolver, squad/unit/commander, abilities (Breach), enemy AI, waves, economy, procedural map generation (with a reachability-repair pass).
- Built a playable vertical-slice mission scene (`Main.tscn` → `Mission.tscn`): procedurally generated grid with elevation, 3 Riot squads, click-to-move with slow-mo easing, Breach ability, 8 enemy data entries (3 wired into the default wave set: Walker/Riot Zombie/Brute), safehouse damage states, win/lose resolution, a minimal HUD, and 8 audio events wired through `AudioManager`.
- Wrote a headless GDScript test suite (`game/tests/`) covering pathfinding, combat RPS rules, economy formulas, and procgen determinism, plus `tools/validate_data.py` and `tools/balance_report.py`, plus a CI workflow (data validation + headless unit tests).
- Made and documented several implementation-level decisions not fully specified by the original brief, notably: test suite location (`game/tests/`, not a top-level `tests/`, for `res://` resolvability — see ADR-0010), and the `data/`/`schemas/` path-resolution strategy for `DataLoader` (documented inline and in `docs/ARCHITECTURE.md`).

### What was NOT done (see docs/BACKLOG.md / docs/HANDOFF.md for the full list)
- Marksman and Barricade classes are data-modeled but their abilities (Focused Volley, Line Charge) are not implemented — only Breach (Riot) is.
- No campaign layer yet: `CampaignGenerator`/`CampaignState`, Campaign Map scene, Armory/Upgrade screen, Main Menu, Mission Prep (deployment) screen.
- No `RunState`/`SaveManager` — permadeath exists mechanically within a mission (a commander can die and the squad is lost) but there's no cross-mission roster/gold persistence or save/load yet.
- **The GDScript code in this session was never executed inside the actual Godot engine** — this sandboxed environment had no network access to download the Godot binary. Syntax and API usage were written carefully against Godot 4.3 conventions and cross-checked by hand, but the first real build/run by a contributor with Godot installed (or by CI once it runs) is the first actual verification. Treat this as the top priority for the next session.

### Recommended next steps
See `docs/HANDOFF.md` "Next 3 Tasks."
