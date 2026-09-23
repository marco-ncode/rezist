# REZIST — Performance Budget

## Targets

- **Target frame rate:** 60 FPS on mid-range hardware (reference: a 2020-era integrated-GPU laptop or equivalent), never dropping below 30 FPS as a hard floor during the largest tested wave.
- **Target platforms:** Windows/Linux/macOS desktop export (`docs/TECHNICAL_DESIGN_DOCUMENT.md` §1). No mobile target in v1.

## Entity Budget (per mission)

| Entity type | Typical | Peak (must stay ≥30 FPS) |
|---|---|---|
| Allied squads | 4-5 | 5 |
| Allied units (incl. commanders) | ~24-30 | 36 (5 squads × max size 6 + commanders) |
| Concurrent zombies | 20-40 | 100 |
| Active projectiles/effects | <20 | 50 |
| Safehouses | 2-4 | 6 |
| **Total simulated combat entities** | ~60 | **~150** |

150 concurrent units is the hard performance budget referenced throughout the docs (TDD §10, ROADMAP M4). `EnemyAI.gd` and `CombatResolver.gd` must be profiled against a 150-entity synthetic stress mission before M4 sign-off (RZ-126).

## Simulation Budget

- Fixed timestep at 60 Hz (`game/project.godot` physics tick).
- `core/` simulation tick (pathfinding re-evaluation, combat resolution, AI decisions for up to 150 entities) must complete within a fraction of the 16.6ms frame budget — target ≤6ms for simulation, leaving headroom for rendering + audio + UI.
- Pathfinding requests are not recomputed every tick per unit — units repath only on order issuance, on losing their current target, or on a fixed low-frequency re-evaluation interval (avoid A* thrashing under load); the exact interval is a tuning constant in `core/pathfinding/` config, not hardcoded inline (see `docs/CODE_STYLE.md`).

## Rendering Budget

- Draw calls: target <500 per frame at peak entity count (favor sprite batching / `MultiMeshInstance2D` for repeated unit/zombie visuals over individually unique nodes once past placeholder art).
- No per-frame allocation in hot paths (`core/` tick functions, rendering interpolation) — reuse buffers/arrays where profiling shows GC/allocation pressure.

## Memory Budget

- A full mission (peak entity count) should not exceed a modest, stable working-set delta from menu idle — flag any unbounded growth over a single mission's duration as a leak (see `docs/PLAYTEST_CHECKLIST.md` "Performance" section).
- Save files are small (single JSON, campaign-map granularity per ADR-0007) — no performance concern expected there; if a save ever exceeds a few hundred KB, investigate what's being over-serialized.

## Profiling Workflow

1. Use Godot's built-in profiler (`Debugger > Profiler` / `Monitors`) during a stress-test mission (synthetic wave config with peak entity counts, kept as a dedicated test district in `data/districts.json` or a debug-only wave set — do not hack peak values into normal content).
2. Record frame time breakdown (simulation vs. rendering vs. physics vs. audio).
3. Log findings as a dated entry in `docs/PLAYTEST_CHECKLIST.md`'s "Performance" checks, and open a `docs/BACKLOG.md` task for any regression found.

## Non-Goals

No effort is spent optimizing for entity counts beyond the 150 budget in v1 — pillar 1 ("few squads, not mass RTS") means the game is not meant to scale to thousands of units; if a future mode needs that, it gets its own ADR and budget revision.
