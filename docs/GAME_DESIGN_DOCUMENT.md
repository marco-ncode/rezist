# REZIST — Game Design Document (GDD)

**Working title:** REZIST
**Genre:** Real-time tactics roguelite, wave defense
**Spiritual ancestor:** *Bad North* (Plausible Concept, 2018) — same mechanical skeleton, new skin
**Target platforms (v1):** Desktop (Windows/Linux/macOS) via Godot 4 export
**Status:** Pre-production / Vertical slice (see `docs/ROADMAP.md` for milestone state)

> This document is the single source of truth for *what the game is*. `docs/TECHNICAL_DESIGN_DOCUMENT.md` covers *how it's built*. If the two disagree, this document wins for design intent, the TDD wins for implementation reality — flag the conflict in `docs/DECISIONS.md` and reconcile.

---

## 1. High Concept

A contemporary city has fallen to a zombie outbreak. The player commands small squads of **survivors** — riot police, hunters, barricade crews, and armed civilians — across a **procedurally generated city under siege**. Each mission is a tight, ~5–6 minute real-time tactical defense: zombies stream in from fixed entry points (subway exits, storm drains, collapsed bridges, breached gates), and the player repositions squads on a discrete grid to intercept them before they reach the neighborhood's safehouses.

It is **not** an RTS of unit-by-unit micromanagement. The player gives **high-level orders** — "this squad, to this tile" — and the squad's soldiers fight autonomously using their class rules. Depth comes from **reading terrain, chokepoints, and enemy composition**, not from clicking faster.

Runs are **roguelite**: commanders permadie, squads are lost forever when their commander falls, and the campaign map is procedurally generated and only partially visible. Progress is measured in how far into the city you push before your force is spent — not in a binary win state.

---

## 2. Design Pillars (non-negotiable)

1. **Real-time tactics, not mass RTS.** 4–5 squads max per mission, short missions (~5–6 min), few but meaningful orders.
2. **Roguelite permadeath.** A dead commander means the squad and every gold invested in it is gone. Total wipe ends the run.
3. **Total readability.** No numeric HP bars. A squad's strength **is** its visible headcount. Every outcome must be legible by sight and by sound alone.
4. **Terrain is strategy.** Discrete grid, elevation, chokepoints, walls, tunnels. The map layout decides the battle, not unit stats.
5. **Procedural generation.** Missions and the campaign map are generated from a seed. Enemy variety and resource placement scale with progress.
6. **Economy of hope.** You don't "win," you **survive**. Every safehouse saved matters; every one lost hurts, but the run continues.
7. **Replayability.** Death teaches. The next run starts smarter, not stronger — knowledge is the only permanent currency between runs (see `docs/BALANCE.md` for what, if anything, is meta-persistent).

Any feature that violates pillar 3 (adding a numeric stat readout) or pillar 1 (encouraging per-unit micromanagement) is out of scope unless it goes through an ADR in `docs/DECISIONS.md` explaining why the pillar bends.

---

## 3. Core Gameplay Loop

```
┌─────────────────────────────────────────────────────────────────┐
│  CAMPAIGN MAP (meta loop)                                       │
│  1. View partially fogged node graph of the city                │
│  2. Choose next district node to deploy to (can back out)       │
│  3. Optionally split squads across multiple simultaneously-     │
│     accessible nodes if enough squads are available             │
│         │                                                       │
│         ▼                                                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  MISSION (moment-to-moment loop)                          │ │
│  │  1. PREP: view generated district grid, deploy squads      │ │
│  │  2. WAVES: zombies spawn from entry points in timed waves  │ │
│  │     - select squad → click destination tile → squad moves  │ │
│  │       and fights automatically                              │ │
│  │     - issuing an order triggers brief slow-motion            │ │
│  │     - use class abilities (plunge/volley/charge) at cooldown │ │
│  │  3. RESOLUTION: survive all waves → mission won;             │ │
│  │     all safehouses lost or all squads wiped → mission lost;  │ │
│  │     retreat early → keep commanders, lose rewards            │ │
│  └───────────────────────────────────────────────────────────┘ │
│         │                                                       │
│         ▼                                                       │
│  4. Collect gold from saved safehouses + surviving squads        │
│  5. Spend gold: upgrade unit classes (L1→L2→L3), unlock          │
│     abilities, buy relics, recruit rescued survivors as heroes   │
│  6. Advance the campaign progress line — unvisited nodes behind  │
│     the line are lost                                            │
└─────────────────────────────────────────────────────────────────┘
```

Run ends when: all squads are wiped (no commanders left), OR the campaign is completed (reach and clear the final node).

---

## 4. Mechanic Mapping — Bad North → REZIST

The mechanical contract with *Bad North* is preserved exactly; only the reskin changes. This table is the canonical translation layer — any new mechanic added later should find its place here first.

| # | Bad North mechanic | REZIST equivalent | Notes |
|---|---|---|---|
| 1 | Island grid w/ elevation | District grid w/ elevation (roofs, overpasses, basements, sewers) | Same pathing/LOS rules |
| 2 | Longship landings | Entry points (subway stairs, storm drains, breached gates, collapsed bridges) | Wave spawners |
| 3 | Give-order-then-resolve, background slow-mo | Same — order issuance always triggers slow-mo pulse | See §6 |
| 4 | Militia | Civilians / Recruits | Base unit, promotes into a class |
| 5 | Infantry (shieldbearer) | Tactical/Riot squad | Shield-front melee tank |
| 6 | Archers | Marksmen / Snipers | Ranged DPS, fragile in melee |
| 7 | Pikemen | Barricade / Polearm crew | Static chokepoint defense |
| 8 | Plunge attack | Breach (riot jump-assault from elevation) | Infantry-class ability |
| 9 | Volley | Focused Volley | Marksmen-class ability |
| 10 | Pike charge | Line Charge | Barricade-class ability |
| 11 | Vikings (raiders) | Walkers | Base zombie, weak, no armor |
| 12 | Shieldbearer vikings | Riot Zombies (armored) | Block ranged frontally |
| 13 | Enemy archers | Spitters | Ranged, fragile in melee |
| 14 | Brutes | Brutes | Slow, huge HP, weak to polearms |
| 15 | Brute archers | Brute Spitters | Ranged brute, deadly at range |
| 16 | Huscarls (throwing axes) | Throwers (thrown weapons/rebar) | Ranged burst before melee |
| 17 | Berserkers / Jumpers | Leapers / Climbers | Jump past front lines |
| 18 | Giant archers (mini-boss) | Colossus (siege boss) | Priority target, mobile threat |
| 19 | Houses | Safehouses (apartments, clinics, shelters) | Gold + can be lost to fire |
| 20 | Rescued villagers/heroes | Rescued survivors → recruitable heroes | Adds a commander to roster |
| 21 | Traits | Traits | See §8, ported 1:1 |
| 22 | Relics | Field gear | See §9, ported 1:1 |
| 23 | Campaign node map, fog of war | Same | Procedural, seed-based |
| 24 | Gold economy | Same | Per-mission payout formula in `docs/BALANCE.md` |
| 25 | Permadeath of commanders | Same | Core roguelite pressure |

---

## 5. Grid, Terrain, Movement

- The battlefield is a **discrete tile grid** (default 2D top-down grid with an integer **elevation** layer per tile — not full 3D voxels).
- Tile types: `open`, `road`, `rubble` (slows), `water` (impassable to infantry, slows others), `stairs`/`ramp` (elevation transition), `wall` (blocks LOS + movement), `door` (destructible chokepoint), `roof` (elevated open), `sewer` (below-grade tunnel, zombie-only entry in some tiles).
- **Elevation** matters for: line of sight (ranged units need a clear sightline), the Breach ability (Infantry class can jump down onto tiles ≥1 elevation lower), and enemy Leapers (can vault a 1-tile gap or wall other classes must path around).
- **Pathfinding** is A* over the tile graph with movement cost per tile type and elevation-change cost; see `docs/ARCHITECTURE.md` §2.
- Player interaction is **click squad → click destination tile**. The squad's individual soldiers autonomously fan out into a formation around that tile and engage whatever is in range. The player never issues per-soldier orders.

---

## 6. Time Model — Slow-Motion Orders

- The simulation runs in real time by default (`time_scale = 1.0`).
- The instant the player opens squad selection or drags an order, `time_scale` eases toward a configurable slow value (default `0.25`, see `data/difficulty.json`) over ~0.15s, and eases back to `1.0` after the order is confirmed or cancelled.
- Time **never fully stops** — this preserves urgency (pillar 7) while giving the player a readable window to issue orders (pillar 3). This matches Bad North's "tactical pause that isn't a pause."
- The slow-mo window is purely a **presentation/input-easing layer** on top of the deterministic fixed-timestep simulation (see TDD §3) — it does not change simulation tick count, only wall-clock-to-tick mapping, so it cannot desync replays or affect determinism.

---

## 7. Allied Classes

Four classes, each with 3 upgrade levels and one unlockable ability. Numeric baselines live in `data/units.json`; this table is the design intent.

| Class | Role | Strength | Weakness | Unique Ability |
|---|---|---|---|---|
| **Recruit** (Civilian) | Base unit | Cheap, available immediately | Weak vs everything | — (promotes into one of the three classes below when upgraded to L2) |
| **Riot** (Tactical/Shield) | Melee tank, front line | Shield blocks ranged damage frontally; holds chokepoints | Slow turn rate, vulnerable from behind/flank, weak vs polearm-wielding zombies | **Breach** — jump down from elevation onto a target tile, dealing impact damage + knockback to everyone there |
| **Marksman** (Sniper) | Ranged DPS | High single-target damage, kills Walkers/Spitters fast | Very weak in melee, no armor | **Focused Volley** — squad fires a synchronized burst at a single target/area, ignoring partial cover |
| **Barricade** (Polearm) | Static defense | Reach weapon hits before being hit; strong vs Brutes and armored zombies; anchors a tile | Cannot move and fight at once effectively; weak vs ranged Spitters | **Line Charge** — squad advances in a line, impaling everything in a straight path |

**Rock-paper-scissors combat layer:**
- Riot shields **block** frontal ranged damage (Spitters, Throwers) → counters ranged zombies.
- Marksmen **outrange and out-damage** unshielded/unarmored zombies (Walkers, Leapers) before they close.
- Barricade **reach weapons** counter big melee bodies (Brutes, Riot Zombies) by hitting first and staggering.
- Riot Zombies (shielded) **counter** Marksmen (their shields block the volley) → must be flanked or broken by Barricade/Breach.
- Leapers **counter** Riot's frontal shield by jumping over/behind it → countered by Barricade's reach or Marksman's early pick-off.

**Levels:** L1 (base recruit-issued gear), L2 (class specialization unlocked, ability purchasable), L3 (veteran gear, ability cooldown/effect improved). Costs and stat deltas: `docs/BALANCE.md` §2.

**Hero recruitment:** Missions may contain a **trapped survivor** marker. Clearing the mission with that survivor still alive adds them to the commander roster as a new hero (with a randomly rolled trait) at the post-mission screen.

---

## 8. Traits

Rolled once per commander at recruitment, visible on their card. Full effect table and stacking rules: `docs/BALANCE.md` §4.

| Trait | Effect |
|---|---|
| Collector | Items/relics cost 50% less when this commander's squad picks them up |
| Energetic | Ability cooldowns reduced |
| Fleet of Foot | Squad movement speed increased |
| Heavy Load | +1 ability use per level before cooldown is required |
| Heavy Weapons | Attacks apply extra knockback/stagger |
| Ironskin | Damage taken reduced |
| Mountain | Commander is a giant who fights personally in melee (visible, high-priority target) |
| Popular | +1 to this squad's maximum size |
| Sharp Weapons | +damage |
| Skillful | Abilities cost less gold to unlock/use |

---

## 9. Field Gear (Relics)

One-per-commander equippable, purchased with gold between missions. Ported 1:1 from Bad North's relic list; full costs/cooldowns in `docs/BALANCE.md` §5.

| Field Gear | Bad North origin | Effect |
|---|---|---|
| IED (Improvised Explosive) | Bomb | Thrown, delayed area damage |
| Reanimation Kit | Holy Grail | Revives one fallen commander (once) |
| Fast Response Vehicle | Jabena | Squad can be deployed a second time in the same mission |
| Mines / Traps | Mines | Placeable, triggers on zombie contact |
| Emergency Fund | Philosopher's Stone | This squad generates bonus gold per mission cleared |
| Tactical Radio | Ring of Command | +1 max squad size |
| Sledgehammer | Warhammer | Melee area-of-effect strike |
| Flare / Air Horn | War Horn | Calls in instant reinforcements mid-mission |

---

## 10. Enemies (Zombie Bestiary)

Full stat baselines: `data/enemies.json`. Every type must have a **readable, teachable counter** (pillar 3).

| Type | Behavior | Counter |
|---|---|---|
| **Walker** | Slow, weak, unarmored, swarms | Anything; dies to 1–2 Marksman hits |
| **Riot Zombie** | Wears riot/armor gear, blocks frontal ranged | Flank, or Barricade reach |
| **Spitter** | Ranged (thrown bile/debris), fragile | Rush with melee, or snipe before it reaches range |
| **Brute** | Huge HP, slow, high melee damage | Barricade reach + focus fire, avoid frontal melee trade |
| **Brute Spitter** | Ranged brute, deadly at range, slow | Close distance fast or snipe from cover |
| **Thrower** | Throws weapon before contact for burst damage | Close distance quickly or use Riot shield to block |
| **Leaper** | Jumps over front lines / gaps, flanks | Barricade reach on landing, or pre-pick with Marksman |
| **Colossus (boss)** | Rare, mobile siege unit, very high HP/damage | Priority target for all squads, use abilities on cooldown |

Enemy stat scaling by campaign depth and difficulty: `docs/BALANCE.md` §3, driven by `data/difficulty.json` and `data/waves.json`.

---

## 11. Structures to Defend

- **Safehouses** (apartment blocks, clinics, shelters) are the "houses" of Bad North. Each has its own tiny HP pool (represented visually, e.g. windows breaking / fire spreading — never a numeric bar) and pays out gold if it survives the mission.
- Safehouses can be **set on fire / breached** by zombies that reach them uncontested; a burning safehouse pays reduced or no gold and may collapse (permanently removed) if not extinguished/defended in time.
- Some missions contain a **trapped survivor** structure (see §7) — clearing it rescues a future hero.

---

## 12. Campaign Structure

- The campaign is a **procedurally generated node graph** representing city districts, generated from a seed (see `data/campaign_nodes.json` for generation rules and TDD §7 for the algorithm).
- **Fog of war:** only nodes adjacent to your current frontier are revealed (partially — type and threat hinted, full content hidden until entered).
- A **progress line** advances after each mission; district nodes that fall behind the line and were never visited are permanently lost (no rewards, no do-over) — this creates the core "you can't save everyone" tension.
- **Gold** earned per mission = safehouses saved + squad performance bonus (formula: `docs/BALANCE.md` §1).
- **Path choice:** the player can preview an adjacent node's type/difficulty hint and **back out** before committing squads.
- **Split the party:** if enough squads are available and the campaign graph offers multiple simultaneously reachable nodes in one turn, the player can deploy different squads to different nodes in the same turn (each is resolved as its own mission).
- **Difficulty tiers:** Easy / Normal / Hard / Very Hard, parameterized entirely via `data/difficulty.json` (spawn rates, enemy HP/damage multipliers, gold multipliers, slow-mo factor).
- **Checkpoints:** optional save points on the campaign graph; see TDD §8 for save/load contract.
- **Run end:** total squad wipe (no commanders left alive), or full campaign completion.

---

## 13. UX Flow (screens)

Detailed wireframes: `docs/UX_UI.md`. Screen list:
1. Main Menu → New Run / Continue / Settings / Quit
2. Campaign Map (node graph, fog of war, roster panel)
3. Mission Prep (grid preview, squad deployment)
4. Mission (HUD: squad selector, ability buttons, wave indicator, danger arrows)
5. Mission Resolution (rewards summary, hero rescue prompt)
6. Upgrade/Armory screen (spend gold: class upgrades, abilities, field gear)
7. Roster/Commander screen (traits, permadeath history)
8. Game Over / Run Summary (how far reached, stats, "start new run")

---

## 14. Art Direction (summary)

Full bible: `docs/ART_BIBLE.md`. Stylized low-poly diorama, desaturated urban palette (concrete grey, rust, emergency amber), silhouette-first zombie readability, no gore-for-gore's-sake, **blood/gore toggle** in settings (on by default, can be reduced to non-graphic impact FX).

## 15. Audio Direction (summary)

Full bible: `docs/AUDIO_BIBLE.md`. Every gameplay event maps to a distinct, mono-mix-legible sound cue. Tense, bass-driven score that intensifies with wave density. Eyes-closed-playable readability is a hard requirement, matching pillar 3.

---

## 16. Out of Scope (v1 vertical slice)

Explicitly deferred — tracked in `docs/BACKLOG.md`, not forgotten:
- Multiplayer / co-op
- More than 4 allied classes or 8 enemy types
- Full campaign meta-progression beyond a single run (no persistent unlocks across runs in v1 — see ADR-0009)
- Full voice-over / localization
- Mobile/touch input layer
- Steam Workshop / mod support

---

## 17. Open Design Questions

Tracked as living questions; resolve via ADR when decided.
- Exact economy curve tuning (placeholder values in `data/economy.json`, needs playtesting — see `docs/PLAYTEST_CHECKLIST.md`).
- Whether a light meta-progression layer (e.g., a persistent "safehouse network" bonus) is added post-v1 without breaking pillar 2.
- Boss (Colossus) mission frequency and whether it needs a dedicated mission type vs. a wave modifier.
