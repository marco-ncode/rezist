# REZIST

**Real-time tactics roguelite — a contemporary city under zombie siege.** Mechanical spiritual clone of *Bad North* (same "low-granularity tactics" design philosophy — command squads at the tile level, they fight autonomously), reskinned: survivor squads (Riot/Marksman/Barricade) defend city districts against zombie hordes streaming from subway exits, storm drains, and breached gates, across a procedurally generated campaign with permadeath commanders.

**Status:** Pre-alpha. Milestone M0 (documentation, data, schemas) is complete; M1 (playable vertical slice) is in progress — see `docs/HANDOFF.md` for the exact current state before touching anything.

---

## Start Here

If you're a new contributor (human or agent), read in this order:
1. This file
2. `docs/ONBOARDING.md` — first 30 minutes, what to read, how to find work
3. `docs/HANDOFF.md` — live "where things actually stand right now" snapshot
4. `docs/TASKS.md` — ready-to-pick-up task list

The full design contract lives in `docs/GAME_DESIGN_DOCUMENT.md` (what the game is) and `docs/TECHNICAL_DESIGN_DOCUMENT.md` + `docs/ARCHITECTURE.md` (how it's built). Every non-trivial technical decision is logged as an ADR in `docs/DECISIONS.md`.

## Repository Structure

```
rezist/
├── docs/            # design docs, ADRs, roadmap, backlog, style guides (start here)
├── data/            # all gameplay-tunable content as JSON (units, enemies, economy, ...)
├── schemas/         # JSON Schema for every file in data/
├── tools/           # Python: validate_data.py, balance_report.py
├── game/            # the Godot 4 project
│   ├── project.godot
│   ├── autoload/     # DataLoader, AudioManager, GameState singletons
│   ├── core/          # engine-agnostic simulation logic (grid, pathfinding, combat,
│   │                  #   squad, abilities, enemy AI, waves, economy, procgen)
│   ├── data_runtime/  # typed wrappers over parsed data/*.json
│   ├── scripts/       # thin Node adapters wiring core/ to scenes/input
│   ├── scenes/        # .tscn scene trees
│   └── tests/         # GDScript unit tests, run headlessly (see below)
└── .github/workflows/ # CI
```

## Requirements

- **Godot 4.3.x** (stable) — [download](https://godotengine.org/download) or use the `godotengine/godot:4.3` Docker image / a CI runner.
- **Python 3.10+** with `pip install -r tools/requirements.txt` — only needed for `tools/` scripts, not to play the game.

## Running the Game

```
godot --path game
```
Opens the project in the Godot editor; press F5 (or the Play button) to run. It boots straight into a procedurally generated mission (no Main Menu yet — see `docs/HANDOFF.md`). Click a squad button at the bottom of the screen, then click a tile on the map to move that squad; click "Ability" then a tile to Breach.

To run headless (e.g. for a dedicated server / smoke test, no window):
```
godot --headless --path game
```

## Running Tests

On a **fresh checkout** (or after pulling changes that touch `.gd` files), warm up Godot's global class cache first — a plain `--script` run fails to resolve `class_name` references otherwise:
```
godot --headless --path game --import
```
Then run the suite:
```
godot --headless --path game --script res://tests/run_tests.gd
```
Runs the full GDScript unit test suite (`game/tests/`) and exits non-zero on any failure. See `docs/CODE_STYLE.md` for test conventions and ADR-0010 (`docs/DECISIONS.md`) for why tests live inside `game/` rather than at the repo root. Opening the project in the editor once (instead of `--import`) has the same warm-up effect.

## Validating Data

```
pip install -r tools/requirements.txt
python tools/validate_data.py
```
Validates every `data/*.json` file against its `schemas/*.schema.json` pair, plus cross-file reference checks (e.g. a unit class's `ability_id` must exist in `data/unit_abilities.json`). Run this after any change to `data/`.

```
python tools/balance_report.py
```
Prints derived balance tables (TTK matrices, gold-per-mission curves) from the current data — a diagnostic aid for tuning, not authoritative (see `docs/BALANCE.md`).

## Building / Exporting

Not yet set up — export presets are tracked as `docs/BACKLOG.md` RZ-138. For now, run from source via the editor or `--headless`.

## Contributing

See `docs/CONTRIBUTING.md` (branch/commit/PR conventions) and `docs/CODE_STYLE.md` (naming, typing, the project's non-negotiable rules: no hardcoded gameplay numbers outside `data/`, no `core/` code touching `Node`/rendering, no numeric HP readouts in UI, combat/behavior rules stay data-driven). Work items live in `docs/BACKLOG.md` / `docs/TASKS.md`.

## License

MIT — see `LICENSE`. Third-party art/audio assets (once added) carry their own license per `docs/ASSET_PIPELINE.md`.
