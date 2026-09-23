# REZIST — Roadmap

Milestones, in order. Each has explicit completion criteria — a milestone is "done" only when every criterion is checked, not when it "feels close." Update the checkboxes and `docs/CHANGELOG.md` together whenever a criterion is met. Current state is also summarized in `docs/HANDOFF.md` (read that first for "where are we right now").

---

## M0 — Foundations (documentation + schemas + backlog)

**Goal:** any agent can clone the repo and start working without asking questions.

- [x] Full doc set under `docs/` (this file included) exists and cross-references correctly
- [x] All `data/*.json` files exist with realistic placeholder content
- [x] All `schemas/*.schema.json` exist and validate the corresponding `data/*.json`
- [x] `docs/BACKLOG.md` has ≥60 atomic, prioritized tasks
- [x] `docs/TASKS.md` has an assignable task table
- [x] Repo scaffolding: `.gitignore`, `.editorconfig`, `LICENSE`, `AGENTS.md`, `CONTRIBUTORS.md`

## M1 — Vertical Slice (one fully playable level)

**Goal:** boot the game, deploy squads on a generated grid, survive a multi-wave mission, win or lose, see the result.

- [ ] Godot project boots (`godot --path game`) to a playable mission scene
- [ ] Grid + elevation rendering works for at least 2 generated district layouts
- [ ] A* pathfinding moves squads correctly around walls/elevation
- [ ] Squad selection + click-to-move + slow-mo on order issuance
- [ ] At least 1 allied class (Riot) fully implemented incl. one ability (Breach)
- [ ] At least 3 enemy types implemented (Walker, Riot Zombie, Brute) with distinct behavior
- [ ] Wave spawner drives a full mission (3+ waves) from `data/waves.json`
- [ ] Safehouses can be saved or lost/burned
- [ ] Mission win/lose conditions implemented and reachable
- [ ] Minimal HUD: squad selector, ability button, wave indicator
- [ ] Placeholder audio hooked to at least 5 gameplay events
- [x] `tests/` cover pathfinding + combat RPS rules, passing in CI

## M2 — Run Systems (campaign, economy, permadeath, save/load)

**Goal:** a full single run is playable start-to-wipe or start-to-completion.

- [ ] Procedural campaign node graph + fog of war
- [ ] Mission → gold payout → armory/upgrade screen loop
- [ ] Commander permadeath removes the squad and is irreversible
- [ ] Hero rescue mission variant adds a new commander to roster
- [ ] Save/load round-trips a full `RunState` correctly
- [ ] Run-over detection (total wipe or campaign completion) with a summary screen
- [ ] `tests/` cover economy formulas, save/load round-trip, campaign determinism

## M3 — Content Expansion

**Goal:** the full roster from the GDD exists, not just the M1 subset.

- [ ] All 4 allied classes (Recruit/Riot/Marksman/Barricade), all 3 levels each, all 3 abilities
- [ ] All 8 enemy types from GDD §10 implemented
- [ ] All 10 traits implemented and stacking-tested
- [ ] All 8 field-gear relics implemented
- [ ] District variety: ≥4 `data/districts.json` types with distinct generation params
- [ ] Difficulty tiers (Easy/Normal/Hard/Very Hard) tuned and selectable

## M4 — Polish

**Goal:** the slice feels like a real game, not a prototype.

- [ ] Full audio pass per `docs/AUDIO_BIBLE.md` event table
- [ ] Art pass replacing placeholders per `docs/ART_BIBLE.md`
- [ ] UX pass on every screen in `docs/UX_UI.md`
- [ ] Balance pass using `tools/balance_report.py` + `docs/PLAYTEST_CHECKLIST.md` sessions
- [ ] Performance budget (`docs/PERFORMANCE.md`) met on target hardware

## M5 — CI/CD & Release Hygiene

**Goal:** automated confidence on every push, exportable builds.

- [x] CI: data validation + unit tests on every push (confirmed green on `dev` commit `dd680cf`, 29/29 test assertions passing)
- [ ] CI: headless export smoke-build for at least one platform
- [ ] Versioned export presets, documented build/export command in `README.md`
- [ ] `docs/CHANGELOG.md` kept current per Keep a Changelog format

## M6 — Stretch / Post-slice

Not committed, tracked for future planning only: co-op, mod support, meta-progression (needs ADR superseding ADR-0009), localization, mobile input.

---

## Current Status

See `docs/HANDOFF.md` for the live "where we are right now" snapshot — this file tracks the plan, HANDOFF tracks the instant.
