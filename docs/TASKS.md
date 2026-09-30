# REZIST — Task Board (ready for assignment)

This is the actionable subset of `docs/BACKLOG.md`: tasks whose dependencies are already satisfied, formatted so an agent can start immediately without cross-referencing anything else. Pick the highest-priority row you're equipped for (match your role to Owner-slot), update its row here to `In Progress` with your name/id, and when done move it back to `docs/BACKLOG.md` as `Done` and remove the row here.

For full context on any task, its ID links back to `docs/BACKLOG.md`.

| Task ID | Title | Files to touch | Definition of Done | Deps (met) | Owner-slot | State |
|---|---|---|---|---|---|---|
| RZ-080 | `core/campaign/CampaignGenerator.gd` | `game/core/campaign/CampaignGenerator.gd` | `generate(seed, params) -> CampaignGraph` produces a fully traversable layered DAG per TDD §7; deterministic (same seed ⇒ identical graph), covered by `tests/test_campaign_determinism.gd` | RZ-030 ✅, RZ-043 ✅ | engine | Open |
| RZ-081 | `core/campaign/CampaignState.gd` | `game/core/campaign/CampaignState.gd` | Fog of war (`visible_nodes()`), `advance_to()`, `mark_lost_behind_line()` one-directional per ARCHITECTURE.md §9 invariant | RZ-080 | engine | Blocked on RZ-080 |
| RZ-082 | Campaign Map scene | `game/scenes/ui/CampaignMap.tscn`, `game/scripts/ui/CampaignMapController.gd` | Renders node graph, fog of war, click a reachable node to preview then commit | RZ-081 | ui | Blocked on RZ-081 |
| RZ-102 | Recruit→class promotion flow at L2 upgrade | `game/scripts/ui/Armory.gd` (`_on_upgrade_pressed` currently keeps `unit_class` unchanged on every level-up — no promotion choice exists), possibly a small UI addition to the Class Tiers tab | A Recruit-class squad reaching L2 lets the player pick Riot/Marksman/Barricade; `unit_class` changes in `RunState`'s roster meta accordingly. Currently unreachable in practice anyway — `GameState._seed_starting_roster()` hardcodes all 3 starting commanders to `"riot"`, never `"recruit"` | RZ-100 ✅, 101 ✅ | engine | Open |
| RZ-137 | CI headless export smoke-build | `.github/workflows/ci.yml` | Adds a job that runs `godot --headless --export-debug` for Linux and fails the build on export error | RZ-136 ✅ | tooling | Open |

---

## Notes for the next agent

- Rows marked `Blocked on RZ-0xx` become `Open` automatically once that ID's status flips to `Done` in `docs/BACKLOG.md` — re-derive this table from the backlog rather than trusting it's fully in sync if it's been a while.
- `RZ-047/048` (Breach + Focused Volley + Line Charge abilities, AbilityRegistry), `RZ-049` (EnemyAI), `RZ-051` (Economy), `RZ-054/055/135` (RunState + SaveManager + round-trip test), `RZ-060/061/062` (Main scene + grid render + mission controller), `RZ-075` (Mission Prep), `RZ-100/101` (Marksman/Barricade), `RZ-103/104/105` (Spitter/Brute Spitter/Thrower reachable), `RZ-108/109` (traits/relics), `RZ-141` (RunState wired into the live mission flow) are already implemented — see `docs/HANDOFF.md` for exactly what's in and what's stubbed before picking up anything below.
- **Correction to a note this file previously had:** RZ-105 (Thrower) turned out *not* to be the same shape as RZ-103/104 — it declared a `melee_followup_damage` field nothing read anywhere (`Enemy.effective_damage()`/`effective_range()`/`mark_burst()` now do, generically). Don't assume every remaining "make an enemy type reachable" backlog row is a pure `data/waves.json` edit without first checking (`grep` the field name across `game/`) whether its `data/enemies.json` entry has a field no code consumes yet. Checked while writing this note: `RZ-106` (Leaper)'s `can_cross_gaps` **is** already read (`Enemy.mover_type()`, used by pathfinding), so RZ-106 is genuinely data-only; `RZ-107` (Colossus)'s `is_boss` is declared but **not** read anywhere (same situation `melee_followup_damage` was in) — check what, if anything, a boss enemy is meant to do differently before treating RZ-107 as a one-line wave_set edit. Both RZ-106/107 are also more of a balance/pacing decision than RZ-103/104/105's straightforward "slot a mid-tier unit into an existing wave" were — a gap-crossing flanker or a boss showing up in the 3-wave vertical slice for the first time deserves a look regardless of what the data audit finds.
- Don't invent new top-level systems without an ADR (`docs/DECISIONS.md`) — extend existing modules per `docs/ARCHITECTURE.md`.
