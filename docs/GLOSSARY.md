# REZIST — Glossary

Domain terms, alphabetical. When code, data, or docs use one of these words, they mean exactly this.

- **Ability** — A commander/squad-triggerable action with a cooldown (Breach, Focused Volley, Line Charge). See `data/unit_abilities.json`.
- **Barricade** — Allied class using polearms/reach weapons; static chokepoint defense. Bad North equivalent: Pikemen.
- **Boss / Colossus** — Rare high-HP mobile siege enemy; GDD §10 top-priority target.
- **Campaign** — The full run's procedural node graph of districts (the meta-layer above individual missions).
- **Commander** — The named leader of a Squad. Permadeath is tied to the Commander, not to rank-and-file Units.
- **Core (`core/`)** — The engine-agnostic simulation code layer; see `docs/ARCHITECTURE.md`.
- **Difficulty tier** — Easy/Normal/Hard/Very Hard; a `data/difficulty.json` entry scaling spawn/HP/damage/gold.
- **District** — A type of city neighborhood (`data/districts.json`) determining a mission's generation params and enemy palette.
- **Entry Point** — A tile where zombies spawn into a mission (subway stairs, storm drain, breached gate, collapsed bridge). Bad North equivalent: longship landing.
- **Field Gear (Relic)** — A one-per-commander equippable item bought with gold (`data/relics.json`). Bad North term: Relic.
- **Fog of War** — The partial-visibility rule on the campaign node graph; only frontier-adjacent nodes are revealed.
- **Marksman** — Allied class using ranged weapons; high DPS, weak in melee. Bad North equivalent: Archers.
- **Mission** — A single tactical encounter on one generated district grid; the "level" of the moment-to-moment loop.
- **Node** — A single district on the campaign graph.
- **Permadeath** — Irreversible loss of a Commander (and their Squad + invested upgrades) on death.
- **Progress Line** — The campaign's advancing frontier; nodes left behind unvisited are lost forever.
- **Recruit** — Base allied unit before class specialization. Bad North equivalent: Militia.
- **RPS (Rock-Paper-Scissors)** — The combat counter-play layer: shields block ranged, reach beats melee, etc. See GDD §7 and `docs/BALANCE.md` §6.
- **Riot** — Allied class with frontal shield, melee tank. Bad North equivalent: Infantry.
- **Run** — One full playthrough from campaign start to wipe or completion; has one seed.
- **Safehouse** — A structure to defend on a mission grid; pays gold if it survives. Bad North equivalent: House.
- **Seed** — The integer that deterministically drives all procedural generation and randomized combat rolls for a run.
- **Slow-mo (order slow-motion)** — The `Engine.time_scale` dip triggered while the player issues an order; never a full pause. See GDD §6, ADR-0004.
- **Squad** — A group of Units led by one Commander; the player's unit of command (never individual soldiers).
- **Tile** — One cell of the discrete mission grid; carries type, elevation, occupancy.
- **Trait** — A permanent modifier rolled once per commander at recruitment (`data/traits.json`).
- **Unit** — One rank-and-file soldier within a Squad (not individually orderable).
- **Vertical Slice** — A single, fully playable end-to-end mission demonstrating all core systems (Milestone M1).
- **Wave** — A timed batch of enemy spawns during a mission, defined in `data/waves.json`.
