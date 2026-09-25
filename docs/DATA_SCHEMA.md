# REZIST — Data Schema Reference

Every file below has a paired JSON Schema at `schemas/<name>.schema.json`, enforced by `tools/validate_data.py` and sanity-checked at boot by `autoload/DataLoader.gd`. This doc explains each field's *meaning*; the schema file is the enforced *contract*. If they disagree, fix the schema (or the data) — this doc is descriptive, the schema is normative.

---

## `data/units.json` → `schemas/units.schema.json`

Allied unit classes.

```json
{
  "classes": [
    {
      "id": "riot",
      "name": "Riot",
      "levels": [
        {"level": 1, "hp": 14, "damage": 3, "reach": 1, "attack_type": "melee", "speed": 1.6, "cost": 12}
      ],
      "blocks_ranged_frontal": true,
      "armor_type": "shield",
      "ability_id": "breach"
    }
  ]
}
```

| Field | Type | Meaning |
|---|---|---|
| `id` | string | Stable identifier, referenced by saves/other data files |
| `name` | string | Display name |
| `levels` | array | One entry per level (1-3); `cost` is gold to *reach* that level from the previous |
| `levels[].attack_type` | enum `melee`\|`ranged` | Drives `CombatResolver` frontal-block check |
| `blocks_ranged_frontal` | bool | ADR-0006: read generically by `CombatResolver`, no class-name branching |
| `armor_type` | enum `none`\|`shield`\|`reach` | Used for RPS bonus lookups (`weak_to` on enemies) |
| `ability_id` | string, nullable | Cross-reference into `unit_abilities.json`; `null` for Recruit |
| `promotes_to` | array of string, Recruit only | Class ids the Recruit can promote into at L2 upgrade |

## `data/unit_abilities.json` → `schemas/unit_abilities.schema.json`

```json
{
  "abilities": [
    {"id": "breach", "name": "Breach", "unit_class": "riot", "unlock_cost": 15,
     "cooldown_seconds": 12, "effect": "plunge_damage_knockback",
     "min_elevation_delta": 1, "radius": 1, "damage_multiplier": 1.5}
  ]
}
```

`effect` is an enum consumed by `AbilityRegistry` to pick the implementing class (`plunge_damage_knockback` → Breach, `focused_ranged_burst` → Focused Volley, `line_impale_charge` → Line Charge). Every `effect` value here must have a matching registered `Ability` — `DataLoader` fails boot if not (ARCHITECTURE.md §6 invariant).

## `data/enemies.json` → `schemas/enemies.schema.json`

```json
{
  "enemies": [
    {"id": "brute", "name": "Brute", "hp": 40, "damage": 8, "attack_type": "melee",
     "range": 1, "speed": 0.7, "behavior": "tank_advance", "blocks_ranged_frontal": false,
     "weak_to": "reach", "can_cross_gaps": false, "knockback_immune": false}
  ]
}
```

`behavior` is an enum consumed generically by `EnemyAI` (`swarm`, `tank_advance`, `ranged_kite`, `swarm_ranged`, `leap_flank`, `siege_boss`) — new enemy types never require new `EnemyAI` code, only a new data entry with an existing (or, rarely, a new) behavior value (ADR-0006).

## `data/waves.json` → `schemas/waves.schema.json`

```json
{
  "wave_sets": [
    {"id": "district_default_3wave", "waves": [
      {"index": 1, "start_time": 5.0, "spawns": [
        {"enemy_id": "walker", "count": 6, "interval": 1.0, "entry_point": "any"}
      ]}
    ]}
  ]
}
```

A `wave_set` is referenced by id from `data/districts.json`. `entry_point: "any"` means the `WaveController` picks a random valid entry point per spawn (seeded); a specific entry-point tag restricts to entry points tagged that way in the generated grid.

## `data/traits.json` → `schemas/traits.schema.json`

```json
{"traits": [{"id": "collector", "name": "Collector", "modifiers": {"relic_cost_mult": 0.5}}]}
```

`modifiers` keys are read generically by consumers (`Economy`, `CombatResolver`, `AbilityRegistry`) — see `docs/BALANCE.md` §4 for the full key list: `relic_cost_mult`, `ability_cooldown_mult`, `move_speed_mult`, `ability_extra_uses`, `stagger_chance_add`, `damage_taken_mult`, `is_mountain`, `squad_max_size_add`, `damage_dealt_mult`, `ability_cost_mult`.

## `data/relics.json` → `schemas/relics.schema.json`

```json
{"relics": [{"id": "ied", "name": "IED", "cost": 20, "effect": "area_damage", "damage": 15, "radius": 1, "fuse_seconds": 2}]}
```

`effect` enum: `area_damage` (IED, Sledgehammer), `revive_commander` (Reanimation Kit), `redeploy` (FRV), `trap_on_contact` (Mines), `bonus_gold_per_mission` (Emergency Fund), `squad_max_size_add` (Tactical Radio), `instant_reinforcements` (Flare).

## `data/economy.json` → `schemas/economy.schema.json`

```json
{
  "starting_gold": 20,
  "gold_per_safehouse": 10,
  "squad_survival_base_gold": 5,
  "gold_per_surviving_unit": 1,
  "upgrade_cost": {"l1_to_l2": 12, "l2_to_l3": 20},
  "ability_unlock_cost": 15,
  "trait_discounts": {
    "collector": {"applies_to": "relic", "mult": 0.5},
    "skillful": {"applies_to": "ability", "mult": 0.75}
  }
}
```

Implements the formulas in `docs/BALANCE.md` §1 exactly — `Economy.gd` must not hardcode any of these numbers.

## `data/difficulty.json` → `schemas/difficulty.schema.json`

```json
{"tiers": [{"id": "normal", "name": "Normal", "enemy_hp_mult": 1.0, "enemy_damage_mult": 1.0,
            "spawn_count_mult": 1.0, "gold_mult": 1.0, "slow_mo_time_scale": 0.25}]}
```

## `data/districts.json` → `schemas/districts.schema.json`

```json
{"districts": [{"id": "residential", "name": "Residential Block", "grid_width": 16, "grid_height": 16,
                "safehouse_count_range": [2, 4], "entry_point_count_range": [2, 3],
                "elevation_variance": "low", "enemy_palette_bias": ["walker", "riot_zombie"],
                "default_wave_set": "district_default_3wave"}]}
```

## `data/biomes.json` → `schemas/biomes.schema.json`

Purely presentational grouping (tile palette, ambient lighting mood) referenced by a district's optional `biome_id`; does not affect simulation.

```json
{"biomes": [{"id": "urban_core", "tile_palette": "concrete_grey", "ambient_mood": "overcast"}]}
```

## `data/audio_events.json` → `schemas/audio_events.schema.json`

```json
{"events": [{"id": "order_issued", "bus": "SFX_UI", "description": "Short clean radio-blip on order confirm."}]}
```

Backs `AudioManager.play_event(event_id)` (ARCHITECTURE.md §13) — the event→sound mapping is this data table, never a hardcoded `match` in `AudioManager.gd`. Full event list and rationale: `docs/AUDIO_BIBLE.md` §2.

## `data/campaign_nodes.json` → `schemas/campaign_nodes.schema.json`

Generation *parameters* (not a saved graph — the graph itself is generated at runtime by `CampaignGenerator` and stored only in a save file, TDD §7-8).

```json
{
  "node_count_range": [8, 14],
  "layers_range": [4, 6],
  "nodes_per_layer_range": [2, 4],
  "edge_density": 0.6,
  "boss_node_layer_from_end": 1,
  "district_weights": {"residential": 0.4, "commercial": 0.25, "industrial": 0.2, "transit_hub": 0.15}
}
```

## Save File → `schemas/save_file.schema.json`

```json
{
  "save_version": 2,
  "seed": 123456789,
  "difficulty": "normal",
  "gold": 47,
  "campaign_state": {
    "visited_nodes": ["n0", "n1"],
    "lost_nodes": ["n3"],
    "progress_line_layer": 2,
    "current_node": "n1"
  },
  "commanders": [
    {"id": "cmdr_001", "name": "J. Alvarez", "unit_class": "riot", "level": 2,
     "trait_id": "ironskin", "relic_id": "mines", "alive": true, "unit_count": 5}
  ],
  "total_safehouses_saved": 12
}
```

`save_version` gates migration logic in `SaveManager.gd` — bump it and add a migration step whenever the shape changes; never silently reinterpret an old save under a new shape. `total_safehouses_saved` (added in v2, RZ-089) is the run's cumulative safehouse count across every mission played, shown on the Run Summary screen (UX_UI.md §8); `RunState.from_save_dict()` defaults it to `0` when loading a v1 save that predates it.

---

## Adding a New Data File

1. Design the shape here first (this doc), get it reviewed against `docs/ARCHITECTURE.md` (which module consumes it, does it violate ADR-0006's "no per-type code branch" rule).
2. Write `schemas/<name>.schema.json`.
3. Write `data/<name>.json` conforming to it.
4. Add a `data_runtime/<Name>Data.gd` typed wrapper and a `DataLoader` accessor.
5. Run `python tools/validate_data.py`.
