# REZIST — Architecture

Module map for the Godot project under `game/`. Each module lists **responsibility**, **public API**, **dependencies**, and **invariants**. Engine-agnostic modules live in `game/core/<module>/`; their thin Node adapters live in `game/scripts/<module>/`.

Layering rule (enforced by code review, see `docs/CODE_STYLE.md`):

```
scenes/ (Node trees, input)
   │  calls into
   ▼
scripts/ (thin adapters: translate Node/input events ↔ core calls)
   │  calls into
   ▼
core/ (pure logic, no Node/SceneTree/rendering/audio references)
   │  reads
   ▼
data_runtime/ (typed wrappers over DataLoader dictionaries)
   │  populated from
   ▼
data/*.json (validated against schemas/*.schema.json)
```

Autoloads (Godot singletons, `game/autoload/`) are the only classes allowed to be globally reachable; everything else is passed explicit references. See `docs/CODE_STYLE.md` for why (testability, no hidden global mutation).

---

## 1. Grid / Terrain — `core/grid/`

**Responsibility:** represent a mission's tile grid: tile type, elevation, occupancy, movement cost.

**Public API** (`core/grid/TacticalGrid.gd`):
- `TacticalGrid.new(width: int, height: int)`
- `set_tile(pos: Vector2i, tile_data: Dictionary) -> void`
- `get_tile(pos: Vector2i) -> Dictionary`
- `is_walkable(pos: Vector2i, mover_type: String) -> bool`
- `movement_cost(from: Vector2i, to: Vector2i, mover_type: String) -> float`
- `elevation_at(pos: Vector2i) -> int`
- `has_line_of_sight(from: Vector2i, to: Vector2i) -> bool`
- `neighbors(pos: Vector2i) -> Array[Vector2i]`

**Depends on:** nothing (leaf module).

**Invariants:** grid is immutable in shape after generation (width/height fixed for the mission); tile dictionaries always contain the keys defined in `docs/DATA_SCHEMA.md` §"Tile"; `is_walkable` must agree with `movement_cost` (a tile with infinite/`-1` cost is never walkable).

---

## 2. Pathfinding — `core/pathfinding/AStarPathfinder.gd`

**Responsibility:** A* search over a `TacticalGrid`, elevation- and mover-type-aware.

**Public API:**
- `AStarPathfinder.find_path(grid: TacticalGrid, start: Vector2i, goal: Vector2i, mover_type: String) -> Array[Vector2i]` — empty array if unreachable.
- `AStarPathfinder.find_nearest_reachable(grid, start, goal, mover_type) -> Vector2i` — used when the exact goal tile is occupied (formation spreading).

**Depends on:** `core/grid/TacticalGrid.gd`.

**Invariants:** pure function, no internal state retained between calls (safe to call concurrently for multiple squads in the same tick); must return a path whose consecutive tiles are always adjacent per `TacticalGrid.neighbors`.

---

## 3. Spawn / Entry Points — `core/waves/EntryPoint.gd`, `core/waves/WaveController.gd`

**Responsibility:** define zombie arrival points on the grid (the "longship landing" equivalent) and drive timed wave spawning from `data/waves.json`.

**Public API:**
- `EntryPoint` — data holder: `position: Vector2i`, `entry_type: String` (subway/drain/bridge/gate).
- `WaveController.new(wave_set: Dictionary, entry_points, enemy_data: EnemyData, rng: SimRng, hp_mult, damage_mult, spawn_count_mult)` — pre-flattens the whole spawn schedule at construction (TDD §5 determinism).
- `WaveController.tick(delta: float) -> Array[Enemy]` — returns newly spawned `Enemy` instances for this tick, already positioned at their entry point.
- `WaveController.is_finished() -> bool`
- `WaveController.current_wave_number() -> int` — for HUD display only.

**Depends on:** `core/grid/TacticalGrid.gd`, `core/sim/SimRng.gd`, `data_runtime/WaveData.gd`.

**Invariants:** spawn timing/composition is fully determined by `(wave_definition, rng_state)` — no wall-clock or frame-count inputs — required for determinism (TDD §5).

---

## 4. Squad — `core/squad/Squad.gd`, `core/squad/Unit.gd`, `core/squad/Commander.gd`

**Responsibility:** group of units under one commander; formation, autonomous movement/engagement, permadeath.

**Public API:**
- `Squad.new(id: String, commander: Commander, unit_class: String, level: int, unit_data: UnitData, spawn_positions: Array, deployment_center: Vector2i = Vector2i.ZERO)` — `deployment_center` is where `commander.position` defaults to for a squad that starts with 0 units (a roster entry that lost all its soldiers in a previous mission); otherwise the commander starts at `spawn_positions[0]`.
- `Squad.order_move_to(target_tile: Vector2i, grid) -> void` — the **only** player-facing command (calls `AStarPathfinder`'s static API internally).
- `Squad.tick(delta, grid, combat_context) -> void` — autonomous per-unit behavior (advance, engage nearest valid target in range, retreat if isolated). Once `units` is empty, transitions the squad into "exposed" exactly once (see `commander_lost` below).
- `Squad.unit_count() -> int` (this **is** the squad's visible "health" per GDD pillar 3)
- `Squad.is_wiped() -> bool`
- `Squad.commander_lost(squad: Squad)` signal — fires exactly once, the tick a squad's rank-and-file are all dead (or immediately, for a squad that starts with 0 units). `MissionController._on_commander_exposed()` reacts by making the commander visible on the grid.
- `Squad.disconnect_commander_signal() -> void` — **must** be called (e.g. from the owning scene's `_exit_tree()`) when a Squad is discarded, if `commander` outlives it. Since RZ-141, `Commander` objects persist across missions in `RunState.commanders`; `Squad._init()` connects `commander.died` to a bound method on itself, and that connection holds a live reference to the Squad. Skipping this leaks one stale Squad (and its Units) per mission — `RefCounted` has no cycle collector.
- `Commander.die() -> void` → triggers permadeath (emits `died`, consumed by both `Squad._on_commander_died` — mission-local `wiped` signal — and `core/run/RunState.on_commander_died` when the commander came from a `RunState` roster).
- `Commander.to_combat_data(traits: Array) -> Dictionary` — duck-typed combat interface (RZ-142), same dictionary shape `Unit.to_combat_data()` produces. Lets `EnemyAI` target an exposed commander with zero special-casing (ADR-0006). Commander deals `damage: 0` — per GDD's "commander fights on alone" rule they don't fight back by default; only the (not yet implemented) Mountain trait would change that.

**Depends on:** `core/grid/`, `core/pathfinding/`, `core/combat/CombatResolver.gd`, `data_runtime/UnitData.gd`, `data_runtime/TraitData.gd`.

**Invariants:** a `Squad` with `unit_count() == 0` has no commander check left to make — commander death is the sole permadeath trigger. A squad that loses all rank-and-file units still exists as just the commander per Bad North's own rule: **the commander is the last unit standing and fights personally** — the commander takes the last-processed unit's grid position, becomes a valid `EnemyAI` target via `to_combat_data()`, and is included in `MissionController`'s `all_units` passed to `EnemyAI.tick_enemy()` (RZ-142; this is how permadeath actually becomes reachable through normal play, not just theoretically wired). The commander does not move or flee once exposed — no pathing logic was added, matching Bad North's own behavior. Squad max size is `base_max_size + trait/relic modifiers` (`Popular` trait, `Tactical Radio` relic), computed, never stored as a separate mutable field to avoid desync.

---

## 5. Combat & Damage — `core/combat/CombatResolver.gd`

**Responsibility:** resolve one attacker-vs-defender engagement tick: damage, RPS modifiers, blocking, knockback/stagger.

**Public API:**
- `CombatResolver.resolve_engagement(attacker: Dictionary, defender: Dictionary, context: Dictionary) -> CombatResult`
- `CombatResult` — plain data: `damage_dealt`, `blocked: bool`, `knockback_vector`, `staggered: bool`, `defender_died: bool`

**Depends on:** `data_runtime/UnitData.gd`, `data_runtime/EnemyData.gd`, `data_runtime/TraitData.gd` (for modifiers only — no Node/scene deps).

**Invariants:** pure function — identical inputs always produce identical outputs (any randomness comes from an `rng` field passed in `context`, never internal `randi()`); RPS rules (`docs/BALANCE.md` §6) are read from data fields (`blocks_ranged_frontal`, `reach`, `armor_type`), never hardcoded per-class `if` chains, so adding a 5th allied class or 9th enemy type requires no `CombatResolver` code changes — only new data entries.

---

## 6. Abilities — `core/abilities/AbilityRegistry.gd`, `core/abilities/*.gd`

**Responsibility:** implement Breach / Focused Volley / Line Charge (and future abilities) as self-contained effect functions with cooldown + trait/relic modifiers.

**Public API:**
- `AbilityRegistry.get_ability(id: String) -> Ability`
- `Ability.can_activate(squad, context) -> bool`
- `Ability.activate(squad, target, context) -> Array[CombatResult]`
- `Ability.cooldown_remaining(squad) -> float`

**Depends on:** `core/combat/CombatResolver.gd`, `core/squad/`, `data_runtime/AbilityData.gd`, `data_runtime/TraitData.gd` (Energetic/Skillful/Heavy Load modifiers).

**Invariants:** every ability id referenced in `data/unit_abilities.json` must have a matching registered `Ability` implementation, checked at boot by `DataLoader` (fail fast, not silently).

---

## 7. Enemy AI & Waves — `core/enemy/EnemyAI.gd`, `core/waves/WaveController.gd`

**Responsibility:** per-enemy-type behavior state machine (advance/attack/flee-never per GDD bestiary) and wave-to-wave scaling.

**Public API:**
- `EnemyAI.tick_enemy(enemy: Enemy, delta: float, grid, all_units: Array, safehouses: Array, combat_context: Dictionary) -> Dictionary` — attacks an in-range target (unit or safehouse) or advances one step toward its current objective; returns a small event dict (`attacked_unit`, `attacked_safehouse`, `result`) for the caller's audio/FX hooks. `all_units` entries are duck-typed, not strictly `Unit` — an exposed, last-stand `Commander` (RZ-142) is equally valid as long as it exposes `position`, `facing`, `id`, `is_alive()`, `apply_damage(int)`, and `to_combat_data(traits) -> Dictionary`.
- Scaling: `WaveController` reads `data/waves.json` + `data/difficulty.json` to multiply enemy HP/damage/count per campaign depth.

**Depends on:** `core/grid/`, `core/pathfinding/`, `data_runtime/EnemyData.gd`, `data_runtime/DifficultyData.gd`.

**Invariants:** behavior per enemy `type` is table-driven off `data/enemies.json.behavior` enum (`swarm`, `ranged_kite`, `tank_advance`, `leap_flank`, `siege_boss`), not per-type subclasses, keeping new enemy types data-only additions.

---

## 8. Economy — `core/economy/Economy.gd`

**Responsibility:** gold accounting: mission payout, upgrade/ability/relic costs, scaling by difficulty.

**Public API:**
- `Economy.mission_payout(safehouses_saved: int, surviving_squads: Array, difficulty_tier: Dictionary) -> int`
- `Economy.upgrade_cost(from_level: int, to_level: int) -> int`
- `Economy.ability_cost(trait_id: String) -> int`
- `Economy.relic_cost(relic_data: RelicData, relic_id: String, trait_id: String) -> int`
- `Economy.apply_trait_discount(base_cost: int, trait_ids: Array, applies_to: String) -> int` (Collector → "relic", Skillful → "ability")

**Depends on:** `data_runtime/EconomyData.gd`, `data_runtime/DifficultyData.gd`.

**Invariants:** all formulas pure functions of data + inputs — no hidden state; see `docs/BALANCE.md` §1 for the exact formulas this module implements.

---

## 9. Campaign / Progression — `core/campaign/CampaignGenerator.gd`, `core/campaign/CampaignState.gd`

**Responsibility:** procedural node graph generation, fog of war, progress line advancement, node loss.

**Public API:**
- `CampaignGenerator.generate(seed: int, params: Dictionary) -> CampaignGraph`
- `CampaignState.new(graph: CampaignGraph)`
- `CampaignState.visible_nodes() -> Array[NodeId]` (fog of war)
- `CampaignState.advance_to(node_id: NodeId) -> void`
- `CampaignState.deployable_nodes() -> Array[NodeId]` (split-the-party candidates this turn)
- `CampaignState.mark_lost_behind_line() -> Array[NodeId]`

**Depends on:** `core/sim/SimRng.gd`, `data_runtime/DistrictData.gd`, `data_runtime/DifficultyData.gd`.

**Invariants:** graph generation is deterministic per seed (TDD §5, §7); `mark_lost_behind_line` is one-directional — a node once lost can never re-enter `visible_nodes()`.

---

## 10. Run / Meta — `core/run/RunState.gd`, `core/run/SaveManager.gd`

**Responsibility:** top-level run state (roster, gold, campaign state, seed), permadeath handling, save/load.

**Public API:**
- `RunState.new_run(seed: int, difficulty: String, starting_gold: int) -> RunState` — starting_gold is supplied by the caller (`economy.json`, read at the scripts/ layer) since core/ must never reference DataLoader (ADR-0002).
- `RunState.commanders: Array[Commander]`
- `RunState.add_commander(commander, unit_class: String, level: int, unit_count: int) -> void` — adds to the roster and wires `commander.died` to `on_commander_died`.
- `RunState.get_roster_meta(commander_id: String) -> Dictionary` — class/level/unit_count, since `Commander` itself doesn't carry squad metadata (that's `Squad`'s job, and squads are mission-scoped, not persistent).
- `RunState.on_commander_died(commander)` — removes the commander's roster metadata (permadeath, GDD pillar 2); the commander stays in `commanders`, marked not alive, for fallen-commander history (UX_UI.md §7).
- `RunState.is_run_over() -> bool` — true on total wipe (campaign completion not modeled yet, pending RZ-081).
- `RunState.to_save_dict() -> Dictionary` / `RunState.from_save_dict(data: Dictionary) -> RunState` — schemas/save_file.schema.json shape.
- `SaveManager.save(run_state, slot: int) -> void`
- `SaveManager.load(slot: int) -> RunState` — null if the slot doesn't exist.

**Depends on:** `core/campaign/` (not yet implemented — `campaign_state` is currently a placeholder Dictionary matching the save schema's shape until RZ-080/RZ-081 land), `core/squad/` (`Commander`, for identity/permadeath), JSON serialization (engine `FileAccess`/`DirAccess`, isolated behind `SaveManager`).

**Invariants:** save format versioned (`docs/DATA_SCHEMA.md` §"Save File"); `SaveManager` is the only class allowed to touch `user://`.

---

## 11. Traits & Field Gear (Relics) — `data_runtime/TraitData.gd`, `data_runtime/RelicData.gd`

**Responsibility:** typed, composable modifiers consumed by combat/economy/abilities. Not a simulation module on its own — a data-access layer.

**Public API:**
- `TraitData.get_modifier(trait_id, modifier_key) -> Variant`
- `RelicData.get_effect(relic_id) -> Dictionary`

**Depends on:** `data/traits.json`, `data/relics.json`.

**Invariants:** modifiers are additive/multiplicative per documented stacking rule (`docs/BALANCE.md` §4) — consumers must not special-case a trait/relic id, only read its declared modifier keys.

---

## 12. UI/UX Layer — `game/scenes/` (flat, no `ui/` subdirectory — deviates from this section's original path, same kind of pragmatic deviation as ADR-0010's test location), `game/scripts/ui/`

**Responsibility:** HUD, squad selection, slow-mo trigger wiring, minimap, all menu screens (GDD §13).

**Screens implemented so far** (all built entirely in code — `_ready()`/`_build_ui()` construct their node tree at runtime; the `.tscn` file is just a script-bearing root node, no hand-authored UI tree, so a themed pass (RZ-124) only ever has to touch `scripts/ui/`):
- `scenes/MainMenu.tscn` + `scripts/ui/MainMenu.gd` (RZ-074) — New Run (opens an inline difficulty-select sub-panel per UX_UI.md §1, then `GameState.start_new_run()`), Continue (`SaveManager.load()`, disabled if no save at slot 0), Quit. `project.godot`'s `run/main_scene` is `scenes/Main.tscn`, a thin bootstrap that immediately hands off here. UX_UI.md's flow reads "→ Campaign Map"; both New Run and Continue instead go to Mission Prep, since the Campaign Map doesn't exist yet (RZ-080/081/082) — the same substitution `Main.gd` made before this screen existed.
- `scenes/MissionPrep.tscn` + `scripts/ui/MissionPrepController.gd` (RZ-075) — deployment-tile selection, roster-aware since RZ-141.
- `scripts/ui/HUD.gd` (no separate `.tscn` — instantiated directly by `MissionController`) — in-mission squad/ability buttons, wave indicator.

**Public API:** scene-local, not consumed cross-module; communicates with `core/` exclusively through `scripts/` adapters (e.g. `scripts/mission/MissionController.gd` mediates between `HUD.gd` input and `core/squad/Squad.order_move_to`).

**Depends on:** everything above, one-directionally (core never depends on UI).

**Invariants:** UI never reads or displays raw HP numbers (GDD pillar 3) — only `Squad.unit_count()` and enum-based damage-state for structures.

---

## 13. Audio Manager — `autoload/AudioManager.gd`

**Responsibility:** map gameplay events (signals) to sound cues, bus routing, ducking.

**Public API:**
- `AudioManager.play_event(event_id: String, at_position: Vector2 = Vector2.ZERO) -> void`
- `AudioManager.set_music_intensity(level: float) -> void`

**Depends on:** signals emitted by `core/` consumers in `scripts/` adapters (audio manager never listens to `core/` directly — core has no signals of its own by rule in §"Layering", so `scripts/` adapters re-emit as Node signals).

**Invariants:** event-id → sound mapping is data-driven from `docs/AUDIO_BIBLE.md`'s event table (implemented as a small `data_runtime` lookup, not hardcoded match statements) so new events are additive.

---

## 14. Procedural Generation — `core/procgen/MapGenerator.gd`, `core/campaign/CampaignGenerator.gd`

**Responsibility:** mission-grid generation (district layout, entry points, safehouse placement) and campaign node-graph generation (§9).

**Public API:**
- `MapGenerator.generate(seed: int, district_type: String, params: Dictionary) -> TacticalGrid` (+ metadata: entry points, safehouse tiles, hero-rescue tile if any)

**Depends on:** `core/grid/TacticalGrid.gd`, `core/sim/SimRng.gd`, `data_runtime/DistrictData.gd`.

**Invariants:** determinism contract per TDD §5; generated grids must guarantee at least one valid path from every entry point to at least one safehouse (validated by an internal reachability check before returning, re-rolling sub-layout on failure with a derived sub-seed).

---

## Dependency Graph (summary)

```
data/*.json → data_runtime/* → core/{grid, sim} → core/pathfinding
                                     │
              core/combat ──────────┼────────── core/abilities
                    │                │                │
              core/squad ────────────┴──────── core/enemy, core/waves
                    │                                  │
              core/economy                    core/procgen (MapGenerator)
                    │                                  │
              core/campaign (CampaignGenerator, CampaignState)
                    │
              core/run (RunState, SaveManager)
                    │
              scripts/* (thin adapters) → scenes/* (Nodes) → UI + AudioManager
```
