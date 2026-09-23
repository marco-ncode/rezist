# Contributing to REZIST

This project is built by a mix of human and AI agent contributors. These rules exist so any of them can pick up work without a sync meeting.

## Branch Strategy

- `main` is always playable (or empty/pre-slice) — never force-push, never commit directly for anything beyond a trivial docs fix.
- Feature branches: `feature/<RZ-id>-short-slug` (e.g. `feature/RZ-100-marksman-class`).
- Fix branches: `fix/<short-slug>`.
- One task (one `RZ-###` from `docs/BACKLOG.md`) per branch/PR wherever practical. Large tasks (size L) may be split into sub-PRs — note the split in the backlog row's notes.

## Commit Convention

Conventional-commits style, task id in the subject when applicable:

```
<type>(<scope>): <summary> [RZ-###]

<body, optional — the WHY, not a restatement of the diff>
```

Types: `feat`, `fix`, `docs`, `data`, `test`, `refactor`, `chore`, `ci`, `balance`.
Scope: the module folder touched (`grid`, `combat`, `squad`, `campaign`, `ui`, `docs`, ...).

Examples:
- `feat(abilities): implement Focused Volley [RZ-048]`
- `data(units): add Marksman L1-L3 stats [RZ-100]`
- `docs(backlog): mark RZ-054 done`

## Pull Request Checklist

Before opening a PR, confirm:
- [ ] The task's Definition of Done (from `docs/TASKS.md`/`docs/BACKLOG.md`) is fully met, not partially.
- [ ] `python tools/validate_data.py` passes if any `data/*.json` changed.
- [ ] `tests/` pass headlessly (`docs/CODE_STYLE.md` has the exact command) if any `core/` code changed.
- [ ] No gameplay-tunable numeric literal was added directly in a `.gd` script — it belongs in `data/`.
- [ ] No new numeric HP/stat readout was added to any UI surface (ADR-0005).
- [ ] `docs/BACKLOG.md` status column updated for the task(s) closed.
- [ ] `docs/CHANGELOG.md` has a new entry under "Unreleased."
- [ ] If a new top-level system/module was introduced, an ADR was added to `docs/DECISIONS.md`.
- [ ] `docs/ROADMAP.md` checkboxes updated if a milestone criterion was completed.

## Code Review

- Any contributor (human or agent) may review; the bar is: does it follow `docs/ARCHITECTURE.md` layering (no `core/` referencing `Node`/`SceneTree`), does it follow `docs/CODE_STYLE.md`, does it respect the pillars in `docs/GAME_DESIGN_DOCUMENT.md` §2, does it keep RPS/combat rules data-driven (ADR-0006)?
- Reviewers should request changes rather than rewrite in-review; leave the fix to the task owner unless it's a one-line nit.
- Design disagreements (is this the right mechanic?) get resolved by proposing an ADR, not by silent override — the GDD/ADRs are the tie-breaker.

## Working Across Multiple Agents

- Always check `docs/TASKS.md` for a row already `In Progress` before starting the same ID — avoid duplicate work.
- If you discover a new task while working (a bug, a missing system), add it to `docs/BACKLOG.md` with the next free `RZ-###` id rather than doing unscoped extra work in the same PR.
- If you get blocked by a missing decision, don't guess silently on anything that affects other modules — write the options into `docs/DECISIONS.md` as a draft ADR and pick the simplest scalable option, per the project's "when in doubt, simplest+scalable+documented" rule.
