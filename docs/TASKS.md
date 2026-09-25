# REZIST — Task Board (ready for assignment)

This is the actionable subset of `docs/BACKLOG.md`: tasks whose dependencies are already satisfied, formatted so an agent can start immediately without cross-referencing anything else. Pick the highest-priority row you're equipped for (match your role to Owner-slot), update its row here to `In Progress` with your name/id, and when done move it back to `docs/BACKLOG.md` as `Done` and remove the row here.

For full context on any task, its ID links back to `docs/BACKLOG.md`.

| Task ID | Title | Files to touch | Definition of Done | Deps (met) | Owner-slot | State |
|---|---|---|---|---|---|---|
| RZ-048 | Implement Focused Volley + Line Charge abilities | `game/core/abilities/focused_volley.gd`, `game/core/abilities/line_charge.gd`, register in `AbilityRegistry.gd`, add entries to `data/unit_abilities.json` | Both abilities activate from `Ability.activate()`, respect cooldown + trait modifiers, covered by a new `tests/test_abilities.gd` case each, `tools/validate_data.py` still passes | RZ-047 ✅ | engine | Open |
| RZ-068 | Danger indicator UI | `game/scripts/ui/DangerIndicator.gd`, wire into `HUD.tscn` | Arrow/ping appears near screen edge pointing at active entry points during a wave; hidden between waves | RZ-067 ✅ | ui | Open |
| RZ-080 | `core/campaign/CampaignGenerator.gd` | `game/core/campaign/CampaignGenerator.gd` | `generate(seed, params) -> CampaignGraph` produces a fully traversable layered DAG per TDD §7; deterministic (same seed ⇒ identical graph), covered by `tests/test_campaign_determinism.gd` | RZ-030 ✅, RZ-043 ✅ | engine | Open |
| RZ-081 | `core/campaign/CampaignState.gd` | `game/core/campaign/CampaignState.gd` | Fog of war (`visible_nodes()`), `advance_to()`, `mark_lost_behind_line()` one-directional per ARCHITECTURE.md §9 invariant | RZ-080 | engine | Blocked on RZ-080 |
| RZ-082 | Campaign Map scene | `game/scenes/ui/CampaignMap.tscn`, `game/scripts/ui/CampaignMapController.gd` | Renders node graph, fog of war, click a reachable node to preview then commit | RZ-081 | ui | Blocked on RZ-081 |
| RZ-100 | Marksman class data + implementation | `data/units.json`, `data/unit_abilities.json`, class-specific tuning only (no new code path per ADR-0006) | L1-L3 stats present, Focused Volley referenced and functional, `tools/validate_data.py` passes | RZ-048 | content | Blocked on RZ-048 |
| RZ-101 | Barricade class data + implementation | `data/units.json`, `data/unit_abilities.json` | L1-L3 stats present, Line Charge referenced and functional | RZ-048 | content | Blocked on RZ-048 |
| RZ-103 | Spitter enemy type | `data/enemies.json` | New entry with `behavior: "ranged_kite"`, no `EnemyAI.gd` code changes needed (data-only per ADR-0006), reachable in a test mission | RZ-049 ✅ | content | Open |
| RZ-137 | CI headless export smoke-build | `.github/workflows/ci.yml` | Adds a job that runs `godot --headless --export-debug` for Linux and fails the build on export error | RZ-136 ✅ | tooling | Open |

---

## Notes for the next agent

- Rows marked `Blocked on RZ-0xx` become `Open` automatically once that ID's status flips to `Done` in `docs/BACKLOG.md` — re-derive this table from the backlog rather than trusting it's fully in sync if it's been a while.
- `RZ-047` (Breach ability + AbilityRegistry), `RZ-049` (EnemyAI), `RZ-051` (Economy), `RZ-060/061/062` (Main scene + grid render + mission controller), `RZ-075` (Mission Prep), `RZ-054/055/135` (RunState + SaveManager + round-trip test) are already implemented in this session — see `docs/HANDOFF.md` for exactly what's in and what's stubbed. Note `RunState` is NOT yet wired into `MissionController` — a mission's `Squad`/`Commander` objects are still separate, freshly-created instances per mission, not sourced from a `RunState` roster. That's RZ-141 (open, above); RZ-088 and RZ-086 both build on top of RZ-141 once it lands.
- Don't invent new top-level systems without an ADR (`docs/DECISIONS.md`) — extend existing modules per `docs/ARCHITECTURE.md`.
