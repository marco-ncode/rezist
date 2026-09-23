# REZIST — Code Style

## GDScript (primary language)

- **Typing:** use static typing everywhere it's expressible (`var hp: int = 10`, `func foo(x: int) -> bool:`). Untyped `var` only for genuinely dynamic dictionary/Variant payloads coming from JSON data.
- **Naming:** `snake_case` for variables/functions/files, `PascalCase` for classes/scene root node names, `SCREAMING_SNAKE_CASE` for constants, `_private_prefixed_with_underscore` for internals not part of a class's public API.
- **File = one class.** Every `.gd` file that defines a reusable type starts with `class_name PascalName`. Scene-attached scripts that are not reusable types (a single scene's controller) don't need `class_name` but must still have `extends`.
- **No magic numbers.** Any gameplay-tunable value comes from `data/` via `DataLoader`/`data_runtime/`. Engine/structural constants (e.g. "3 retry attempts on X") are fine as local `const`.
- **`core/` purity (ADR-0002):** files under `game/core/` must not `extends Node` (use `extends RefCounted` or plain `class_name` with no `extends`), must not reference `SceneTree`, `get_node`, signals tied to the scene tree, or call into `AudioManager`/rendering. If a `core/` class needs to notify listeners, expose a plain `Signal`-typed member manually or return event/result objects — the adapter layer in `scripts/` connects those to Node signals.
- **Pure functions where possible.** Modules like `CombatResolver`, `Economy`, `AStarPathfinder`, `MapGenerator` should have no `core/` module implicitly reachable except via constructor injection.
- **Comments:** document the *why*, not the *what* — see the repo-wide rule in `README.md`. A one-line comment above a non-obvious formula (cite the `docs/BALANCE.md` section) is good; a comment restating the line below it is not.
- **Error handling:** `core/` functions fail loudly during development (`assert()`) for programmer errors (invalid data shape) and return explicit sentinel values (empty array, `null`, a `.ok`-flagged result struct) for expected "no result" cases (e.g. unreachable path). Never silently swallow an error.
- **Signals:** name them as past-tense events (`commander_died`, `wave_completed`, `safehouse_lost`), not commands.
- **Formatting:** tabs for indentation (Godot/GDScript default, matches `.editorconfig`), one statement per line, braces N/A (GDScript is indentation-based). Run the Godot editor's built-in formatter (`Format Document`) before committing if available; otherwise match surrounding style by hand.

## JSON Data Files

- 2-space indentation (see `.editorconfig`).
- Every entry has an explicit, stable string `id` field (used for cross-referencing from other data files and from save files) — never rely on array index.
- Keys are `snake_case`.
- No comments (JSON doesn't support them) — put rationale in `docs/BALANCE.md` or `docs/DATA_SCHEMA.md`, referenced from a sibling `_notes` field only if truly necessary for a non-obvious value.

## Python (tools/)

- Python 3.10+, type hints on function signatures, `pathlib.Path` over raw strings for paths.
- `tools/` scripts must run standalone (`python tools/validate_data.py`) with only `jsonschema` as a non-stdlib dependency (documented in a `tools/requirements.txt`).

## Tests (tests/)

- One `test_<module>.gd` file per module under test, `class_name` not required.
- Each test file exposes `static func run(reporter: TestReporter) -> void` iterating its own test cases and calling `reporter.expect_eq(actual, expected, "description")` etc. (see `tests/test_reporter.gd`).
- Test names read as assertions: `test_astar_avoids_walls`, `test_shield_blocks_frontal_ranged_damage`.
- Determinism tests must generate twice from the same seed and compare, never rely on a hardcoded "golden" hash unless that hash is committed alongside the test with a comment on how to regenerate it.

## What's Forbidden

- Hardcoded gameplay numbers outside `data/`.
- `core/` code depending on `Node`/`SceneTree`/rendering/audio.
- Per-class/per-enemy `if`/`match` branches in `CombatResolver`/`EnemyAI` for anything expressible as a data field (ADR-0006).
- Numeric HP/stat readouts in any UI scene (ADR-0005).
- New top-level systems without a corresponding ADR in `docs/DECISIONS.md`.
