# REZIST — Architecture Decision Records (ADR)

Format: **Context / Decision / Consequences**. Append-only — never edit a merged ADR's decision, only add a new ADR that supersedes it (and link back). Number sequentially, zero-padded.

---

## ADR-0001 — Engine & language: Godot 4.x + GDScript

**Context:** Need an engine that supports a 2.5D grid-tactics game, ships fast, and produces text-diffable project files so LLM agents and human reviewers can review changes without binary diffs. Candidates considered: Godot 4 (GDScript), Unity (C#), TypeScript + Three.js/Babylon/Pixi (web).

**Decision:** Godot 4.x stable, GDScript, 2.5D orthographic rendering over a 2D tile grid with elevation offsets (not full 3D meshes).

**Consequences:** Text-based `.tscn`/`.tres`/`.gd` files diff and merge cleanly. Headless CI (`godot --headless`) is straightforward for tests and export smoke-builds. GDScript has weaker tooling/typing than C# or TS, mitigated by strict typing hints (`docs/CODE_STYLE.md`) and pure-function `core/` modules that are trivially unit-testable. We give up Unity's asset-store ecosystem and TS's npm ecosystem; acceptable since v1 has no third-party asset dependency (`docs/ASSET_PIPELINE.md`).

---

## ADR-0002 — Simulation core is engine-agnostic (`core/` has no Node references)

**Context:** Gameplay logic (pathfinding, combat, economy, procgen) needs to be unit-testable headlessly and independent of scene-tree lifecycle quirks, per the project's "niente valori hardcoded / testabilità" requirement.

**Decision:** All simulation logic lives under `game/core/` as plain GDScript classes (`RefCounted`-based, not `Node`-based) that take/return plain data (Dictionaries, typed arrays, small value classes). `game/scripts/` is a thin Node-adapter layer that is the only place allowed to call into `core/` from a live scene.

**Consequences:** Enables running `tests/` with a lightweight headless script runner without instancing scenes. Slightly more boilerplate translating between Node signals and core calls in `scripts/`, judged worth it for testability and for keeping the codebase legible to an agent with no scene-tree context.

---

## ADR-0003 — Data-driven content via JSON + JSON Schema, not Godot `.tres` Resources

**Context:** Need all gameplay-tunable values (`docs/BALANCE.md`) external to code, editable and validatable outside the Godot editor (important for CI and for agents that only have text tools).

**Decision:** Content lives in `data/*.json`, each with a paired `schemas/*.schema.json`. `autoload/DataLoader.gd` parses and validates at boot (basic required-field/type checks); `tools/validate_data.py` provides a full JSON Schema validation pass usable from the CLI/CI without opening Godot at all.

**Consequences:** Slight duplication of validation logic (a lightweight check in GDScript at boot, a full check in Python for CI) — acceptable, the two are allowed to drift toward "Python is authoritative, GDScript boot-check is a fast-fail sanity net." `.tres` Resources remain in use only for engine-specific non-gameplay assets (e.g. imported textures, audio streams), never for tunable gameplay numbers.

---

## ADR-0004 — Fixed timestep simulation, slow-motion via `Engine.time_scale` only

**Context:** GDD requires a Bad-North-style "orders trigger slow-mo, never a full pause" feel, while also requiring deterministic, seed-reproducible simulation for procgen and save/load correctness.

**Decision:** Simulation runs in `_physics_process` at a fixed tick rate. Slow-motion is implemented purely via `Engine.time_scale`, which scales wall-clock-to-tick mapping but never changes tick count or in-tick logic.

**Consequences:** Determinism is preserved "for free" — no special-casing needed in `core/` for slow-mo. UI/input code in `scripts/` is responsible for easing `time_scale` in/out; `core/` never reads `Engine.time_scale` directly (would violate ADR-0002's no-engine-reference rule) — instead `scripts/mission/MissionController.gd` reads it and only affects presentation smoothing, not `core/` calls.

---

## ADR-0005 — No numeric HP display; squad strength = unit count

**Context:** GDD pillar 3 ("total readability") explicitly bans numeric stat readouts, mirroring Bad North's UI philosophy.

**Decision:** Units still have integer HP internally (`core/combat` needs it for deterministic resolution), but no UI surface ever renders a number for it. The **only** player-visible signal of squad strength is `Squad.unit_count()` (how many soldiers are visibly present) and, for structures, a small enum of damage states (intact/damaged/burning/collapsed) driving sprite/particle swaps, never a bar or number.

**Consequences:** Slightly harder to playtest-tune by eye (testers can't see "how much HP is left"), mitigated by `tools/balance_report.py` which prints numeric TTK/HP tables for designers without ever putting them in the shipped UI.

---

## ADR-0006 — Combat rules are data-driven, not per-class code branches

**Context:** Adding new allied classes or enemy types should not require touching `CombatResolver.gd`.

**Decision:** RPS interactions (shield-blocks-ranged, reach-beats-melee, etc.) are expressed as boolean/enum fields on unit/enemy data entries (`blocks_ranged_frontal`, `reach`, `armor_type`) which `CombatResolver.resolve_engagement` reads generically. No `if unit_class == "riot"` branches in combat code.

**Consequences:** Slightly more upfront data-schema design work (`docs/DATA_SCHEMA.md`), but keeps `docs/BACKLOG.md` content-expansion tasks (new enemy types, new classes) purely data + art/audio tasks, not engine-code tasks — critical for a multi-agent backlog where many contributors will only touch `data/`.

---

## ADR-0007 — Mission state is not mid-mission-saveable; campaign checkpoints only

**Context:** Full mid-wave save/load would require serializing live simulation state (unit positions, cooldowns, wave timers), a large surface area for a vertical slice.

**Decision:** Save/load operates at the campaign-map granularity only (TDD §8). A mission is atomic: either completed/retreated-from, or (if the app closes mid-mission) resumed from the last campaign checkpoint before that mission started.

**Consequences:** Much smaller, simpler save schema and much less risk of desync bugs. Cost: closing mid-mission loses that mission's progress (acceptable for a ~5-6 min mission length per GDD §1, matches Bad North's own behavior).

---

## ADR-0008 — 2.5D orthographic rendering over full 3D diorama meshes (v1)

**Context:** Bad North uses hand-crafted 3D low-poly dioramas; matching that fully is a large art-production task out of scope for a vertical slice.

**Decision:** v1 renders a 2D tile grid with per-tile elevation expressed as a Y-offset/parallax layering trick (2.5D), using primitive/placeholder art (`docs/ASSET_PIPELINE.md`). Full 3D remains an option for a post-slice art pass.

**Consequences:** Faster iteration, lower art bar to reach a playable vertical slice. Revisit via a new ADR if/when a dedicated art track starts.

---

## ADR-0009 — No cross-run meta-progression in v1

**Context:** GDD open question: should losing a run still grant some persistent unlock (common in modern roguelites)?

**Decision:** v1 has **no** persistent unlocks across runs — every run starts from the same baseline roster/gold per `data/economy.json`. Only in-run knowledge (the player's own skill) carries forward, matching Bad North's own design and pillar 2 (permadeath must sting).

**Consequences:** Simpler save format (no separate "meta save" file needed yet), consistent with pillar 2. Flagged as an open design question in GDD §17 for post-v1 reconsideration; if added later, it must get its own ADR plus a save-schema version bump (`docs/DATA_SCHEMA.md`).

---

## ADR-0010 — Testing without the Godot editor: headless custom test runner over GUT

**Context:** Need automated tests for pathfinding, combat, economy, procgen determinism, and save/load, runnable in CI. Godot Unit Test (GUT) addon is the community standard but adds an external addon dependency and its own DSL to learn.

**Decision:** For v1, use a minimal custom headless test runner (`game/tests/run_tests.gd`, executed via `godot --headless --path game --script res://tests/run_tests.gd`) that discovers `test_*.gd` files, calls their `run(reporter)` method, and reports pass/fail with a non-zero exit code on failure. No external addon dependency.

**Test location note:** the tests live at `game/tests/` (inside the Godot project), not a top-level `tests/` directory sibling to `game/`. Godot's `--script` argument resolves through the `res://` resource system, which cannot reliably escape the project root the way `data/`/`schemas/` (plain OS file reads via `DataLoader`, see ADR-0003) can. Keeping tests inside the project is what makes them actually runnable by `godot --headless`; `docs/`, `data/`, `schemas/`, and `tools/` stay at the repo root because none of them need `res://` resolution.

**Consequences:** Less feature-rich than GUT (no mocking/spying helpers), acceptable because `core/` modules are pure functions/data classes, so tests are plain assertions. If test complexity grows, revisit with an ADR that adopts GUT — the `core/` architecture (ADR-0002) makes that migration low-risk since tests are just calling plain functions either way.
