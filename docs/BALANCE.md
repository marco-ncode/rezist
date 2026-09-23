# REZIST — Balance

Authoritative numeric reference. **The values here must match `data/*.json` exactly** — if you change a number, change it in both places in the same commit, and run `python tools/validate_data.py` + `python tools/balance_report.py` to sanity-check. These are v1 placeholder-but-plausible baselines, expected to be retuned during M4 playtesting (`docs/PLAYTEST_CHECKLIST.md`); nothing here is sacred except the *shape* of the formulas.

---

## 1. Economy Formulas

```
mission_payout(safehouses_saved, squads_performance, difficulty)
  = (safehouses_saved * gold_per_safehouse)
  + sum(squad_performance_bonus for each surviving squad)
  * difficulty.gold_multiplier

squad_performance_bonus(squad)
  = squad_survival_base_gold + (squad.unit_count() * gold_per_surviving_unit)
```

Baseline constants (`data/economy.json`):
- `gold_per_safehouse` = 10
- `squad_survival_base_gold` = 5
- `gold_per_surviving_unit` = 1
- Starting gold at run start = 20

```
upgrade_cost(unit_class, from_level, to_level)
  L1 -> L2 = 12
  L2 -> L3 = 20
  (flat per-class in v1; a future ADR may make this class-specific if playtesting shows Marksman/Barricade need different curves)

ability_cost(ability_id) = 15  (flat in v1, see data/unit_abilities.json "unlock_cost")

relic_cost(relic_id) — per relic, range 15-35, see data/relics.json "cost"
```

```
apply_trait_discount(base_cost, traits)
  Collector present -> cost *= 0.5   (relics/items only)
  Skillful present  -> cost *= 0.75  (abilities only)
  (multiple discount-granting traits on the same commander stack multiplicatively)
```

## 2. Unit Class Baselines

| Class | Level | HP | Damage | Reach (tiles) | Speed (tiles/s) | Cost to reach this level |
|---|---|---|---|---|---|---|
| Recruit | L1 | 10 | 2 | 1 (melee) | 2.0 | 0 (starting) |
| Riot | L1 | 14 | 3 | 1 (melee) | 1.6 | 12 (promotion from Recruit) |
| Riot | L2 | 18 | 4 | 1 | 1.6 | +12 |
| Riot | L3 | 24 | 6 | 1 | 1.7 | +20 |
| Marksman | L1 | 8 | 3 | 4 (ranged) | 1.8 | 12 |
| Marksman | L2 | 10 | 5 | 4 | 1.8 | +12 |
| Marksman | L3 | 13 | 7 | 5 | 1.9 | +20 |
| Barricade | L1 | 12 | 4 | 2 (reach) | 1.4 | 12 |
| Barricade | L2 | 16 | 6 | 2 | 1.4 | +12 |
| Barricade | L3 | 20 | 9 | 3 | 1.5 | +20 |

`blocks_ranged_frontal`: Riot only (all levels). `armor_type`: Riot = `shield`, Barricade = `reach`, Marksman/Recruit = `none`.

Base squad max size = 6 units (excluding commander). Modified by `Popular` trait (+1) and `Tactical Radio` relic (+1), additively, computed at query time (never stored — ARCHITECTURE.md §4 invariant).

## 3. Enemy Baselines

| Enemy | HP | Damage | Range | Speed (tiles/s) | Behavior | Notes |
|---|---|---|---|---|---|---|
| Walker | 6 | 2 | melee | 1.2 | swarm | No armor, no counters needed |
| Riot Zombie | 16 | 3 | melee | 1.0 | tank_advance | `blocks_ranged_frontal = true` |
| Spitter | 5 | 4 | 4 (ranged) | 1.1 | ranged_kite | Dies to 1 melee hit |
| Brute | 40 | 8 | melee | 0.7 | tank_advance | `weak_to = "reach"` (+50% dmg taken from Barricade) |
| Brute Spitter | 30 | 6 | 5 (ranged) | 0.6 | ranged_kite | `weak_to = "reach"` too |
| Thrower | 8 | 5 (once, burst) | 3 (ranged, single use then melee) | 1.3 | swarm_ranged | Burst then closes to melee (dmg 2) |
| Leaper | 7 | 3 | melee | 2.2 | leap_flank | Can cross 1-tile gaps/walls other enemies path around |
| Colossus | 150 | 12 | melee | 0.5 | siege_boss | Immune to knockback |

Difficulty scaling (`data/difficulty.json`) multiplies `hp` and `damage` and adjusts `spawn_count`/`spawn_interval` — see §3 below and `docs/DATA_SCHEMA.md`.

## 4. Traits — Effects & Stacking

| Trait | Effect | Stacking rule |
|---|---|---|
| Collector | Relic/item purchase cost ×0.5 | One commander, one instance — traits don't stack on the same commander (each commander rolls exactly one trait, v1) |
| Energetic | Ability cooldown ×0.75 | — |
| Fleet of Foot | Squad move speed ×1.25 | — |
| Heavy Load | +1 ability use allowed before cooldown triggers | — |
| Heavy Weapons | +25% stagger/knockback chance on hit | — |
| Ironskin | Damage taken ×0.8 | — |
| Mountain | Commander personally fights as a heavy melee combatant (hp 30, damage 8, melee reach 1); always visible, high threat priority for enemies | — |
| Popular | Squad max size +1 | — |
| Sharp Weapons | Damage dealt ×1.15 | — |
| Skillful | Ability unlock/use gold cost ×0.75 | — |

Because each commander has exactly one trait (rolled at recruitment, GDD §8), no same-trait stacking case exists in v1; the "stacking rule" column exists for forward-compatibility with a future ADR allowing multiple traits per commander (not planned for v1).

## 5. Field Gear (Relics) — Costs & Effects

| Relic | Cost | Effect |
|---|---|---|
| IED | 20 | Thrown, 2s fuse, area damage 15 in 1-tile radius |
| Reanimation Kit | 35 | Revives one fallen commander once (consumed on use) |
| Fast Response Vehicle | 25 | This squad may be deployed a 2nd time in the same mission |
| Mines / Traps | 15 | Place up to 2 per mission; 10 damage + stagger on zombie contact |
| Emergency Fund | 20 | +3 bonus gold per mission this squad participates in and survives |
| Tactical Radio | 25 | +1 max squad size |
| Sledgehammer | 20 | Melee attack becomes area-of-effect (1-tile radius) |
| Flare / Air Horn | 18 | Once per mission, instantly spawns 2 reinforcement recruits into this squad |

## 6. Combat Resolution Formula

```
resolve_engagement(attacker, defender, context):
  if attacker.is_ranged and defender.blocks_ranged_frontal and attack_is_frontal(context):
      return CombatResult(damage_dealt = 0, blocked = true)

  base = attacker.damage
  if attacker.armor_type == "reach" and defender.weak_to == "reach":
      base *= 1.5
  if attacker has trait "Sharp Weapons":
      base *= 1.15
  if defender has trait "Ironskin":
      base *= 0.8

  damage = max(1, round(base))   # minimum 1 damage, never a total whiff by rounding
  staggered = roll_stagger(attacker, context.rng)  # base 10% chance, +25% (additive) with Heavy Weapons
  return CombatResult(damage_dealt = damage, blocked = false, staggered = staggered)
```

`attack_is_frontal(context)` compares the attack vector's angle to the defender's current facing (derived from its most recent move direction) within a ±60° frontal arc.

## 7. Difficulty Tiers

| Tier | Enemy HP mult | Enemy dmg mult | Spawn count mult | Gold mult | Slow-mo time_scale |
|---|---|---|---|---|---|
| Easy | 0.8 | 0.8 | 0.8 | 1.2 | 0.30 |
| Normal | 1.0 | 1.0 | 1.0 | 1.0 | 0.25 |
| Hard | 1.25 | 1.2 | 1.25 | 0.9 | 0.22 |
| Very Hard | 1.5 | 1.4 | 1.5 | 0.8 | 0.18 |

## 8. Tuning Workflow

1. Edit values in `data/*.json` (never only here — this doc must mirror it).
2. Run `python tools/validate_data.py` (schema check).
3. Run `python tools/balance_report.py` — prints derived TTK (time-to-kill) matrices per class-vs-enemy pairing and gold-per-minute curves; use it to sanity check before booting the engine.
4. Playtest per `docs/PLAYTEST_CHECKLIST.md`, log findings, adjust, repeat.
5. Update this file's tables to match the final `data/*.json` values in the same PR.
