# REZIST — Technical Design Document (TDD)

Companion to `docs/GAME_DESIGN_DOCUMENT.md` (design intent) and `docs/ARCHITECTURE.md` (module map). This document covers engine choice, engineering constraints, data flow, determinism, and save format.

---

## 1. Stack Decision

**Chosen:** Godot 4.x (latest stable 4.x, GDScript), see `docs/DECISIONS.md` ADR-0001 for the full rationale.

Summary of why (over TypeScript+Three.js alternative):
- Native 2D/2.5D tilemap + pathfinding primitives reduce boilerplate for a grid-tactics game.
- GDScript is plain text, diffs cleanly, and is friendly to headless CI (`godot --headless`) for both automated tests and CI builds — important for a multi-agent workflow where reviewers are LLMs reading diffs.
- `.tscn`/`.tres` are text-based (non-binary) by default, so scenes and resources are also diffable and mergeable.
- Single self-contained editor+runtime binary, easy to pin a version in CI.
- Godot's `RandomNumberGenerator` with explicit seeds gives us deterministic procgen without extra dependencies.

**Rendering approach:** 2.5D — orthographic camera over a 2D tile grid with a per-tile elevation offset applied to Y-position/sprite-layering (see `docs/ART_BIBLE.md` §2). This is simpler and faster to iterate than full 3D low-poly meshes while preserving the "diorama" read. Full 3D is not ruled out post-slice; revisit in an ADR if art direction demands it.

**Engine version pin:** Godot `4.3.x` stable. Recorded in `game/project.godot` (`config/features`).

---

## 2. Project Structure

```
rezist/
├── docs/                  # all design & process documentation (this file's siblings)
├── data/                  # data-driven game content (JSON)
├── schemas/               # JSON Schema for every file in data/
├── tools/                 # Python CLI utilities: validate_data.py, balance_report.py
├── game/                  # the Godot project itself
│   ├── project.godot
│   ├── autoload/          # singletons (see ARCHITECTURE.md)
│   ├── core/               # engine-agnostic simulation logic (plain GDScript classes,
│   │                       #   no Node inheritance where possible → unit-testable)
│   ├── scenes/             # .tscn scene trees (Main, CampaignMap, Mission, UI screens)
│   ├── scripts/            # Node-attached .gd scripts (thin, delegate to core/)
│   ├── data_runtime/        # DataLoader-parsed resource wrappers
│   ├── tests/               # GDScript unit tests, run headlessly (ADR-0010 — lives
│   │                       #   inside the project so `godot --script res://...` resolves)
│   └── assets/              # art/audio (placeholders in v1, see ASSET_PIPELINE.md)
```

No `.github/workflows/` currently — CI was removed by explicit request (see `docs/CHANGELOG.md`); §9 below keeps the local commands to run the same checks manually.

**Hard rule:** anything in `game/core/` must not reference `SceneTree`, `Node`, or do any rendering/audio calls. It takes plain data in, returns plain data out. This is what makes the simulation unit-testable without booting a scene (see §5). `game/scripts/` is the thin adapter layer that wires `core/` logic to Nodes, input, and rendering.

---

## 3. Simulation Model — Fixed Timestep + Interpolation

- The tactical simulation (unit movement, combat resolution, ability cooldowns, wave spawning) runs on a **fixed timestep** via `_physics_process(delta)` at Godot's configured physics tick (60 Hz default, `game/project.godot`).
- Rendering (`_process(delta)`) reads the latest simulation state and interpolates visual transforms between the last two simulation ticks for smooth motion independent of framerate.
- The slow-motion order-input feature (GDD §6) scales `Engine.time_scale`, which affects how many *wall-clock* seconds a tick takes but not tick *count* or tick *logic* — the simulation is agnostic to time_scale by construction. This is what keeps determinism intact under slow-mo.
- All simulation randomness goes through a single seeded `RandomNumberGenerator` instance owned by `core/sim/SimRng.gd` — never `randi()`/global randomness — so a given seed always reproduces the same tick-by-tick outcome (procgen, wave composition, and any randomized combat rolls).

---

## 4. Data-Driven Design

**Rule: no gameplay-tunable value is hardcoded in a script.** Unit stats, ability numbers, enemy stats, wave composition, traits, relics, economy formulk-constants, and difficulty multipliers all live in `data/*.json`, loaded at boot by `autoload/DataLoader.gd` and validated against `schemas/*.schema.json`.

Flow:
```
data/*.json  --(loaded + schema-checked at boot)-->  DataLoader (autoload)
                                                          │
                                        exposes typed lookup APIs, e.g.
                                        DataLoader.get_unit("riot")
                                        DataLoader.get_enemy("walker")
                                                          │
                                                          ▼
                                    core/ simulation classes consume data
                                    dictionaries, never literal numbers
```

Full schema-by-schema documentation: `docs/DATA_SCHEMA.md`. Validation tool: `tools/validate_data.py` (run manually — see §9 for why there's no CI right now).

---

## 5. Determinism & Procedural Generation

- Every run has an explicit **seed** (u64), shown in the campaign map UI and stored in the save file.
- `core/procgen/MapGenerator.gd` (mission-grid generator) and `core/procgen/CampaignGenerator.gd` (node-graph generator) both take `(seed: int, params: Dictionary)` and return pure data structures (grid + entry points + safehouses, or node graph) with no side effects and no reliance on engine global state.
- **Determinism contract:** same seed + same params ⇒ byte-identical generation output, verified by `game/tests/test_procgen_determinism.gd` (hash the generated structure and compare across two independent generations from the same seed).
- Wave composition and enemy spawn timing (`core/waves/WaveController.gd`) draw exclusively from `SimRng`, so a full mission replay from the same seed is also deterministic — this is required for save/load correctness (§8) and is a precondition for any future replay/spectator feature.

---

## 6. Combat Resolution Model

- Combat is resolved per simulation tick by `core/combat/CombatResolver.gd`, a pure function: `resolve_engagement(attacker_data, defender_data, context) -> CombatResult`.
- Damage formula, rock-paper-scissors modifiers (shield-blocks-ranged, reach-beats-melee, etc.), knockback, and stagger are all parameterized from `data/units.json` / `data/enemies.json` / `data/traits.json` fields — see `docs/DATA_SCHEMA.md` and `docs/BALANCE.md` §6 for the exact formula.
- Health is tracked as **integer HP internally** (needed for deterministic, reproducible combat) but is **never displayed as a number** — the presentation layer only ever shows unit *count* per squad and simple damage-state visuals per structure (GDD pillar 3). This separation (integer sim state vs. non-numeric UI) is itself an architectural rule, not just an art choice.

---

## 7. Campaign Generation Algorithm (summary)

Full parameter reference: `docs/DATA_SCHEMA.md` (`campaign_nodes.schema.json`) and `data/districts.json`.

1. Seed RNG from run seed.
2. Generate a **branching DAG** of N nodes (N from `difficulty.json`) using a randomized layered graph: each layer has 2–4 nodes, edges connect a subset of layer *i* nodes to layer *i+1* nodes such that every node has ≥1 outgoing edge and the graph stays fully traversable from the start node to at least one end node.
3. Assign each node a **district type** (from `data/districts.json`: e.g. `residential`, `commercial`, `industrial`, `transit_hub`) which determines its mission grid generation params and enemy palette bias.
4. Assign threat hints (visible in fog-of-war) without revealing exact wave composition.
5. Place the boss/Colossus node(s) at or near terminal layers per `difficulty.json`.

Mission-grid generation (`MapGenerator.gd`) then independently generates the actual tile grid for whichever node the player enters, seeded by `hash(run_seed, node_id)` so it's reproducible per-node without needing to store the full grid in the campaign save (see §8).

---

## 8. Save / Load

- A run's full state is serialized to a single JSON file under `game/user://saves/<slot>.json` (Godot's user data dir).
- Contents: run seed, campaign graph state (visited/lost/remaining nodes, progress line position), commander roster (id, name, class, level, XP/gold spent, traits, equipped field gear, alive/dead), gold balance, current difficulty, and a monotonic save version integer for future migration.
- **Not** stored: the in-progress mission tick state — a mission is atomic; if the game closes mid-mission the player resumes at the last completed mission boundary (campaign-map level checkpoint), never mid-wave. This significantly simplifies the save format and matches Bad North's own save granularity.
- Save/load round-trip correctness is covered by `game/tests/test_save_load_roundtrip.gd`.
- Save schema documented in `docs/DATA_SCHEMA.md` §"Save File".

---

## 9. Tooling & CI

**No CI pipeline is currently configured for this repository** — removed by explicit request (`docs/CHANGELOG.md`, `docs/HANDOFF.md`). Run the checks below manually before pushing until/unless CI is reintroduced.

- `tools/validate_data.py` — validates every `data/*.json` against its `schemas/*.schema.json` using `jsonschema` (Python). Run via `python tools/validate_data.py`.
- `tools/balance_report.py` — reads `data/*.json` and prints derived tables (effective DPS, TTK matrices, gold-per-minute curves) to help balance tuning without opening the engine. Not authoritative, just a diagnostic aid — see `docs/BALANCE.md`.
- `game/tests/` — GDScript unit tests executed headlessly: `godot --headless --path game --script res://tests/run_tests.gd` (run from the repo root). See `docs/CONTRIBUTING.md` for the exact command and `docs/CODE_STYLE.md` for test conventions, and ADR-0010 for why tests live inside `game/` rather than at the repo root. **On a checkout with no `.godot/` cache yet, run `godot --headless --path game --import` once first** — a bare `--script` invocation doesn't build the global `class_name` lookup table, so every cross-file class reference fails to resolve until that warm-up runs.

If CI is reintroduced later, `docs/HANDOFF.md` "CI / Build Status" records two real issues already found and fixed once (a Godot download version-string bug, and the `--import` warm-up requirement above) — reuse that fix rather than rediscovering it.

---

## 10. Performance Budget

See `docs/PERFORMANCE.md` for the authoritative budget (entity counts, target FPS, draw call ceiling). Summary: target 60 FPS on mid-range hardware with up to ~150 concurrent simulated units (5 squads × ~6 units + up to ~100 zombies across active waves).

---

## 11. Engineering Non-Goals (v1)

- No networking/multiplayer code paths.
- No custom C++/GDExtension modules — pure GDScript until profiling proves a specific hot path needs it (record that decision as an ADR if it happens).
- No dependency on external asset marketplaces for the vertical slice — placeholder primitives only (`docs/ASSET_PIPELINE.md`).
