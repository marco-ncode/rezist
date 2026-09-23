# REZIST — Onboarding (first 30 minutes)

You're a new contributor — human or agent — with zero prior context on this repo. Follow this in order; don't skip ahead.

## 1. Read (≈15 min)

1. `README.md` — what this repo is, how to run it.
2. This file (already doing that).
3. `docs/GAME_DESIGN_DOCUMENT.md` — skim in full once. This is the contract for *what* the game is. Pay special attention to §2 (Design Pillars) — they're non-negotiable and every task must respect them.
4. `docs/ARCHITECTURE.md` — skim the module list and the layering diagram at the top. You don't need to memorize every API, just know which module owns what.
5. `docs/DECISIONS.md` — skim the ADR titles. These are settled decisions; don't re-litigate them without proposing a new ADR.

## 2. Orient (≈5 min)

6. `docs/HANDOFF.md` — the live "where are we right now" snapshot. This tells you what's actually built vs. documented-but-not-yet-built.
7. `docs/ROADMAP.md` — which milestone is currently active.

## 3. Find work (≈5 min)

8. `docs/TASKS.md` — the ready-to-pick-up subset of the backlog. Pick a row matching your role (engine/content/ui/art/audio/tooling/docs) with no unmet dependencies.
9. If nothing in `docs/TASKS.md` fits, check `docs/BACKLOG.md` directly (larger list, includes blocked items — see if their blockers have since cleared).

## 4. Before you write anything (≈5 min)

10. `docs/CODE_STYLE.md` (if touching code/data) — naming, typing, the "no hardcoded gameplay numbers" rule, the `core/` purity rule.
11. `docs/CONTRIBUTING.md` — branch naming, commit format, PR checklist.
12. If touching data files specifically, also read the relevant section of `docs/DATA_SCHEMA.md` and `docs/BALANCE.md`.

## First Suggested Task

If you have no strong preference, `docs/TASKS.md` is sorted so the top few rows are good "get familiar with the codebase" starting points (currently: RZ-048 Focused Volley/Line Charge abilities, or RZ-103 Spitter enemy type — both are small, self-contained, and touch exactly one module each). Check the file for the current top row since it changes as tasks complete.

## Rules That Apply to Every Task, No Exceptions

- No gameplay-tunable number hardcoded outside `data/*.json` (see `docs/CODE_STYLE.md`).
- No numeric HP/damage readout in any UI (ADR-0005).
- `core/` code never references `Node`/`SceneTree`/rendering/audio (ADR-0002).
- Combat/behavior rules are data-driven, not per-type code branches (ADR-0006).
- Every task's Definition of Done includes updated docs (`docs/BACKLOG.md` status, `docs/CHANGELOG.md`, `docs/ROADMAP.md` if a milestone criterion closes).

## If You Get Stuck

- Missing a decision that affects other modules? Draft an ADR in `docs/DECISIONS.md` rather than guessing silently — pick the simplest, most scalable option and document why.
- Found a bug or missing task while working? Add it to `docs/BACKLOG.md` with the next free `RZ-###` id instead of scope-creeping your current task.
- Genuinely blocked (missing tool, unclear requirement only a human can answer)? Say so explicitly rather than shipping a guess — this is a roguelite tactics game with tight interlocking design pillars; a wrong guess here compounds across every future content task.
