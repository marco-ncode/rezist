# REZIST — Backlog

Atomic, assignable tasks. Every task has a stable **ID** (`RZ-###`, never reused/renumbered), a **MoSCoW priority**, a **size** (S = ≤half day, M = ~1-2 days, L = ≥3 days for a competent agent/dev), its **dependencies** (other RZ-### IDs that must land first), and an **owner-slot** (which kind of agent/dev should pick it up — not a person's name, a role).

This file is the source list; `docs/TASKS.md` is the "ready to pick up right now" subset formatted for quick assignment. When a task completes: check it here, remove/replace it in TASKS.md, log it in `docs/CHANGELOG.md`, and update `docs/ROADMAP.md` checkboxes if it closes a milestone criterion.

Legend — **Priority:** Must / Should / Could / Won't(-yet). **Size:** S/M/L. **Owner-slot:** `engine` (Godot/GDScript systems), `content` (data/JSON + balance), `ui` (scenes/HUD/UX), `art`, `audio`, `tooling` (Python/CI), `docs`.

---

## Section A — M0 Foundations

| ID | Title | Priority | Size | Deps | Owner | Status |
|---|---|---|---|---|---|---|
| RZ-001 | Write GAME_DESIGN_DOCUMENT.md | Must | L | — | docs | Done |
| RZ-002 | Write TECHNICAL_DESIGN_DOCUMENT.md | Must | M | RZ-001 | docs | Done |
| RZ-003 | Write ARCHITECTURE.md | Must | M | RZ-002 | docs | Done |
| RZ-004 | Write DECISIONS.md (ADR-0001..0010) | Must | M | RZ-002 | docs | Done |
| RZ-005 | Write ROADMAP.md | Must | S | RZ-001 | docs | Done |
| RZ-006 | Write BACKLOG.md (this file) | Must | L | RZ-005 | docs | Done |
| RZ-007 | Write TASKS.md | Must | M | RZ-006 | docs | Done |
| RZ-008 | Write CONTRIBUTING.md | Must | S | RZ-003 | docs | Done |
| RZ-009 | Write CODE_STYLE.md | Must | S | RZ-003 | docs | Done |
| RZ-010 | Write GLOSSARY.md | Should | S | RZ-001 | docs | Done |
| RZ-011 | Write BALANCE.md | Must | M | RZ-001 | docs | Done |
| RZ-012 | Write ASSET_PIPELINE.md | Should | S | RZ-001 | docs | Done |
| RZ-013 | Write DATA_SCHEMA.md | Must | M | RZ-002 | docs | Done |
| RZ-014 | Write ART_BIBLE.md | Should | M | RZ-001 | art | Done |
| RZ-015 | Write AUDIO_BIBLE.md | Should | M | RZ-001 | audio | Done |
| RZ-016 | Write UX_UI.md | Must | M | RZ-001 | ui | Done |
| RZ-017 | Write PLAYTEST_CHECKLIST.md | Should | S | RZ-011 | docs | Done |
| RZ-018 | Write ONBOARDING.md | Must | S | RZ-007 | docs | Done |
| RZ-019 | Write CHANGELOG.md (seed with M0 entry) | Must | S | — | docs | Done |
| RZ-020 | Write PERFORMANCE.md | Should | S | RZ-002 | engine | Done |
| RZ-021 | Author data/units.json | Must | M | RZ-013 | content | Done |
| RZ-022 | Author data/unit_abilities.json | Must | S | RZ-021 | content | Done |
| RZ-023 | Author data/enemies.json | Must | M | RZ-013 | content | Done |
| RZ-024 | Author data/waves.json | Must | M | RZ-023 | content | Done |
| RZ-025 | Author data/traits.json | Must | S | RZ-013 | content | Done |
| RZ-026 | Author data/relics.json | Must | S | RZ-013 | content | Done |
| RZ-027 | Author data/economy.json | Must | S | RZ-013 | content | Done |
| RZ-028 | Author data/difficulty.json | Must | S | RZ-013 | content | Done |
| RZ-029 | Author data/districts.json + biomes.json | Should | M | RZ-013 | content | Done |
| RZ-030 | Author data/campaign_nodes.json (generation params) | Should | S | RZ-029 | content | Done |
| RZ-031 | Write schemas/*.schema.json for all of the above | Must | L | RZ-021..030 | tooling | Done |
| RZ-032 | Write tools/validate_data.py | Must | M | RZ-031 | tooling | Done |
| RZ-033 | Write tools/balance_report.py | Should | M | RZ-021,023,027 | tooling | Done |
| RZ-034 | Repo scaffolding: .gitignore, .editorconfig, LICENSE | Must | S | — | tooling | Done |
| RZ-035 | Write AGENTS.md + CONTRIBUTORS.md | Must | S | RZ-008 | docs | Done |
| RZ-036 | Write README.md | Must | M | RZ-001..035 | docs | Done |

## Section B — M1 Vertical Slice: Engine Core

| ID | Title | Priority | Size | Deps | Owner | Status |
|---|---|---|---|---|---|---|
| RZ-040 | Scaffold Godot 4 project (project.godot, folder layout) | Must | S | RZ-013 | engine | Done |
| RZ-041 | Implement core/grid/TacticalGrid.gd | Must | M | RZ-040 | engine | Done |
| RZ-042 | Implement core/pathfinding/AStarPathfinder.gd | Must | M | RZ-041 | engine | Done |
| RZ-043 | Implement core/sim/SimRng.gd (seeded RNG wrapper) | Must | S | RZ-040 | engine | Done |
| RZ-044 | Implement data_runtime/ typed wrappers + autoload/DataLoader.gd | Must | M | RZ-031,040 | engine | Done |
| RZ-045 | Implement core/combat/CombatResolver.gd (RPS rules from data) | Must | L | RZ-021,023,044 | engine | Done |
| RZ-046 | Implement core/squad/Unit.gd, Squad.gd, Commander.gd | Must | L | RZ-042,045 | engine | Done |
| RZ-047 | Implement core/abilities/AbilityRegistry.gd + Breach ability | Must | M | RZ-046 | engine | Done |
| RZ-048 | Implement core/abilities/ Focused Volley + Line Charge — new `FocusedVolleyAbility.gd` (Marksman, `effect: "focused_ranged_burst"`) deals `damage_multiplier`-boosted damage to every enemy within `radius` of the target tile, stationary (unlike Breach, it never moves the squad — matches GDD's "fires... at a single target/area" vs. Breach's own "jump down onto" framing). `data.ignores_partial_cover` is a documented no-op: no cover mechanic exists anywhere in the sim to bypass. New `LineChargeAbility.gd` (Barricade, `effect: "line_impale_charge"`) computes a straight 8-directional line of `line_length` tiles from the squad's position toward the target tile (hand-written sign computation, not a Godot built-in — RZ-143's lesson about verifying unfamiliar API applies even to something this small), damages every enemy on it, then advances the squad there via `order_move_to()`. `data.knockback_strength` is a documented no-op: nothing reads `CombatResult.knockback_vector` to displace an enemy yet, same gap Breach's own knockback intent already has. Both registered in `AbilityRegistry.IMPLEMENTED_EFFECTS` — this also fully resolves the `SCRIPT ERROR: DataLoader: ability 'focused_volley' declares effect... with no registered implementation` line that had shown up in every CI run's log since the original bootstrap commit (harmless per RZ-143's investigation, but noisy). New `game/tests/test_abilities.gd` (3 cases) covers all three abilities now registered, including Breach retroactively, since no ability test coverage existed before this | Should | M | RZ-047 ✅ | engine | Done |
| RZ-049 | Implement core/enemy/EnemyAI.gd (behavior table: swarm/ranged_kite/tank_advance) | Must | L | RZ-045 | engine | Done |
| RZ-050 | Implement core/waves/EntryPoint.gd + WaveController.gd | Must | M | RZ-049,024 | engine | Done |
| RZ-051 | Implement core/economy/Economy.gd | Must | M | RZ-027,044 | engine | Done |
| RZ-052 | Implement core/procgen/MapGenerator.gd (mission grid gen, seeded) | Must | L | RZ-041,029 | engine | Done |
| RZ-053 | Implement reachability validation in MapGenerator (entry→safehouse path guarantee) | Must | S | RZ-052 | engine | Done |
| RZ-054 | Implement core/run/RunState.gd (roster, gold, permadeath hook) | Must | M | RZ-046,051 | engine | Done |
| RZ-055 | Implement core/run/SaveManager.gd (JSON save/load) | Must | M | RZ-054 | engine | Done |

## Section C — M1 Vertical Slice: Presentation & Playability

| ID | Title | Priority | Size | Deps | Owner | Status |
|---|---|---|---|---|---|---|
| RZ-060 | Scene: Main.tscn bootstrap + autoload wiring | Must | S | RZ-044 | engine | Done |
| RZ-061 | Scene: Mission.tscn — grid tile rendering (2.5D elevation offset) | Must | L | RZ-041,060 | ui | Done |
| RZ-062 | scripts/mission/MissionController.gd — input → core bridge | Must | L | RZ-046,061 | ui | Done |
| RZ-063 | Squad selection + click-to-move UI incl. slow-mo easing (Engine.time_scale) | Must | M | RZ-062 | ui | Done |
| RZ-064 | Render squads as unit-count-driven sprite groups (no HP bars, ADR-0005) | Must | M | RZ-063 | ui | Done |
| RZ-065 | Render enemies with per-type placeholder silhouettes | Must | M | RZ-050,061 | ui | Done |
| RZ-066 | Safehouse rendering + damage-state (intact/damaged/burning/collapsed) | Must | M | RZ-061 | ui | Done |
| RZ-067 | HUD: squad selector bar, ability button + cooldown, wave indicator | Must | M | RZ-062 | ui | Done |
| RZ-068 | Danger indicator (arrows/pings toward active entry points) — implemented as a pulse on the entry point's own marker rather than an off-screen arrow, since the fixed camera always shows the whole grid and entry points are always on-screen (border tiles); no off-screen case ever exists for an arrow to solve | Should | S | RZ-067 | ui | Done |
| RZ-069 | Mission win/lose detection + resolution screen | Must | M | RZ-050,066 | engine | Done |
| RZ-070 | Ability activation input (Breach) wired to HUD button | Must | S | RZ-047,067 | ui | Done |
| RZ-071 | autoload/AudioManager.gd + event→sound data table | Must | M | RZ-060 | audio | Done |
| RZ-072 | Hook ≥5 gameplay events to AudioManager (placeholder SFX) | Should | S | RZ-071 | audio | Done |
| RZ-073 | Placeholder art pass: tiles, units, zombies, safehouses (primitive shapes/colors) | Must | M | RZ-061,065,066 | art | Done |
| RZ-074 | Main Menu scene (New Run / Continue / Settings / Quit) — Settings not implemented (no spec exists yet); New Run and Continue both target Mission Prep, not Campaign Map (RZ-080/081/082 don't exist yet) | Should | S | RZ-060 | ui | Done |
| RZ-075 | Mission Prep screen (deploy squads before wave 1) | Must | M | RZ-062 | ui | Done |
| RZ-142 | Implement exposed-commander vulnerability (last-stand combat) — today `Commander.apply_damage()`/`die()` are never called anywhere in a live mission, so permadeath cannot actually trigger through normal play even though `Squad.commander_lost` fires correctly when a squad's last unit dies | Must | M | RZ-046,049 | engine | Done |

## Section D — M2 Run Systems

| ID | Title | Priority | Size | Deps | Owner | Status |
|---|---|---|---|---|---|---|
| RZ-080 | core/campaign/CampaignGenerator.gd (node graph gen, seeded) | Must | L | RZ-030,043 | engine | Backlog |
| RZ-081 | core/campaign/CampaignState.gd (fog of war, progress line, node loss) | Must | M | RZ-080 | engine | Backlog |
| RZ-082 | Campaign Map scene (node graph UI, fog of war render) | Must | L | RZ-081 | ui | Backlog |
| RZ-083 | Path-choice back-out flow (preview node, cancel before commit) | Should | S | RZ-082 | ui | Backlog |
| RZ-084 | Split-the-party: deploy multiple squads to multiple nodes in one turn | Should | M | RZ-082,054 | engine | Backlog |
| RZ-085 | Armory/Upgrade screen (spend gold on class levels/abilities/relics) — Class Tiers and Relics are real functional purchases; Abilities is informational only in v1 (shows name/cost, no purchase button) since ability access isn't gated by level/purchase anywhere yet — see RZ-144 | Must | L | RZ-051,067 | ui | Done |
| RZ-086 | Roster/Commander screen (traits, equipped relic, alive/dead history) — the wireframe's "died Mission N (Enemy)" cause-of-death annotation isn't shown, since nothing tracks that anywhere (`RunState.on_commander_died()` only erases roster metadata); fallen commanders list by name only | Should | M | RZ-054 | ui | Done |
| RZ-087 | Hero rescue mission variant (trapped survivor tile + recruit-on-win) | Should | M | RZ-052,054 | engine | Backlog |
| RZ-088 | Permadeath flow: commander death → squad removal → UI feedback | Must | M | RZ-141 ✅,RZ-142 ✅,046 ✅ | engine | Done |
| RZ-089 | Run-over detection (total wipe / campaign complete) + summary screen — campaign-complete detection stays blocked on RZ-081 (no CampaignState exists), so only the total-wipe half is implemented; the summary screen always shows "RUN OVER", never the wireframe's alternate "CITY SECURED" | Must | M | RZ-054,081 | ui | Done |
| RZ-090 | Save/Load wired to Main Menu "Continue" — the Continue button itself already calls `SaveManager.load()`/`has_save()` (landed with RZ-074); what's left is deciding when a run actually gets *written* — nothing in the mission flow calls `SaveManager.save()` yet, so Continue is permanently disabled in practice until this lands | Must | M | RZ-055 ✅,074 ✅ | engine | Done |
| RZ-144 | Wire ability-unlock enforcement: gate `AbilityRegistry`/`MissionController` ability activation on squad level + a persisted per-commander purchase (paid via `Economy.ability_cost()`, currently only *displayed*, never spent, in the Armory's Abilities tab — RZ-085) — every class's ability currently works unconditionally from mission 1 regardless of level, which doesn't match GDD's "L2: class specialization unlocked, ability purchasable" intent. Deliberately deferred out of RZ-085's scope: touches already-working, engine-load-critical ability-activation code (`MissionController._squad_ability_id`/`_on_ability_button_pressed`) with real regression risk if done hastily, per the RZ-143 lesson about that exact file | Should | M | RZ-085 ✅,047 ✅ | engine | Done |
| RZ-091 | Difficulty selection (Easy/Normal/Hard/Very Hard) at run start | Should | S | RZ-028,080 | ui | Backlog |
| RZ-092 | Checkpoint nodes on campaign graph | Could | S | RZ-081 | engine | Backlog |
| RZ-141 | Wire `RunState` into `Main.gd`/`MissionController.gd` (roster persistence, permadeath → `RunState`, gold → `RunState`) | Must | M | RZ-054 ✅ | engine | Done |

## Section E — M3 Content Expansion

| ID | Title | Priority | Size | Deps | Owner | Status |
|---|---|---|---|---|---|---|
| RZ-100 | Marksman class: L1-L3 + Focused Volley ability — `data/units.json`'s Marksman entry (L1-L3 stats) already existed complete and matching `docs/BALANCE.md` §2 exactly from the original bootstrap; the only real gap was Focused Volley having no `Ability` implementation, now closed by RZ-048 in the same commit. No data changes needed here. **Unreachable in live play until RZ-102**: every starting commander is hardcoded to `unit_class: "riot"` and nothing ever promotes a squad to Marksman afterward | Must | M | RZ-048 ✅ | content | Done |
| RZ-101 | Barricade class: L1-L3 + Line Charge ability — same situation as RZ-100: `data/units.json`'s Barricade entry already existed complete and matching `docs/BALANCE.md` §2 exactly; Line Charge's `Ability` implementation (RZ-048) was the only gap. Completed as a direct side effect of implementing RZ-048 for RZ-100 — flagged here transparently since it wasn't the task explicitly asked for, but its Definition of Done is genuinely met. Same **unreachable-until-RZ-102** caveat as RZ-100 | Must | M | RZ-048 ✅ | content | Done |
| RZ-102 | Recruit→class promotion flow at L2 upgrade — the one remaining gap keeping Marksman (RZ-100 ✅) and Barricade (RZ-101 ✅) entirely unreachable in live play: `Armory.gd`'s `_on_upgrade_pressed()` bumps a squad's level but never lets the player choose a class, and `GameState._seed_starting_roster()` hardcodes every starting commander to `"riot"` — so a Recruit-class squad that could actually promote never exists either. Needs a small UI addition to the Class Tiers tab (pick Riot/Marksman/Barricade the first time a Recruit hits L2) | Must | S | RZ-100 ✅,101 ✅ | engine | Backlog |
| RZ-103 | Spitter enemy type + ranged_kite behavior — the `data/enemies.json` entry (`behavior: "ranged_kite"`) already existed complete from the original bootstrap; `EnemyAI.gd` never branches on `behavior` at all (ARCHITECTURE.md §7 — the single aggro-range/attack-if-in-range rule combined with each type's own `range`/`speed`/`damage` already produces the distinct feel, no per-type code), so the only real gap was reachability: no `wave_set` the vertical slice actually plays (`district_default_3wave`, used by both the `residential` and `commercial` districts) spawned it. Added `{"enemy_id": "spitter", "count": 2, "interval": 1.5, "entry_point": "any"}` to that wave_set's wave 2, alongside the existing Riot Zombies — fits the existing escalation shape and `commercial`'s own (currently unconsumed, purely descriptive) `enemy_palette_bias` already named Spitter. Purely data, no code changes, per ADR-0006 | Must | S | RZ-049 ✅ | content | Done |
| RZ-104 | Brute Spitter enemy type — same shape as RZ-103: `data/enemies.json`'s entry (`hp: 30, damage: 6, range: 5, behavior: "ranged_kite", weak_to: "reach"`) already existed complete; the only gap was reachability. Added to `district_default_3wave`'s wave 3, alongside the existing Brute — a tougher elite pairing (melee tank + ranged tank) for the vertical slice's climax wave, matching how `transit_hub_5wave` already treats it as a singular late-wave spawn. Pure data, no code touched | Should | S | RZ-103 ✅ | content | Done |
| RZ-105 | Thrower enemy type | Should | S | RZ-049 | content | Backlog |
| RZ-106 | Leaper enemy type + leap_flank behavior | Must | M | RZ-049 | engine | Backlog |
| RZ-107 | Colossus boss enemy type + siege_boss behavior | Should | L | RZ-049 | engine | Backlog |
| RZ-108 | Implement remaining traits (Fleet of Foot, Heavy Load, Heavy Weapons, Ironskin, Mountain, Popular, Sharp Weapons, Skillful) — auditing against actual code found 5 of the 8 already functionally wired (Heavy Weapons/Ironskin/Sharp Weapons via `CombatResolver`, Popular via `Squad.max_size()`, Skillful via `Economy`'s trait_discounts). Only 3 were genuine gaps, now closed: Fleet of Foot (`move_speed_mult` aggregated once per `Squad.tick()`, threaded into `_advance_unit()`), Heavy Load (`Squad.ability_charges_remaining` + `Ability.can_activate()`/`activate()` charge logic — an extra activation usable *while on cooldown*, granted when a fresh cycle starts), Mountain (`Commander.melee_damage`/`mountain_hp` read generically from `TraitData` in `Commander._init()`, so an exposed last-stand Mountain commander now fights back instead of always dealing 0). Mountain's "always visible" GDD wording (fighting as an active melee combatant from mission start, not only once exposed) is deliberately out of scope here — see RZ-147. No trait-assignment UI exists yet (RZ-087), so all 8 traits remain unreachable in live play until then, same caveat as every trait wired so far | Must | M | RZ-025,046 | engine | Done |
| RZ-109 | Implement remaining relics (IED, Reanimation Kit, FRV, Mines, Emergency Fund, Tactical Radio, Sledgehammer, Flare) — auditing against actual code found none wired at all (unlike RZ-108's traits, `Commander.relic_id` was purely cosmetic: persisted and displayed, never read by any gameplay system). Implemented the 4 relics that are passive modifiers on existing systems, no new UI needed (same "generic read off the relic's declared effect, never special-cased by id" pattern as traits, ARCHITECTURE.md §11): **Tactical Radio** (`Squad.max_size()`'s `relic_bonus: int` param replaced with a `relic_data: RelicData` read, same shape as `trait_data`/Popular — previously declared but never actually computed from anything), **Emergency Fund** (`Economy.mission_payout()` reads a `bonus_gold` field off the surviving squad's equipped relic), **Sledgehammer** (`Squad.tick()`'s melee-hit resolution splashes the same damage onto every other enemy within the relic's declared `radius`, read via a `damage_multiplier` key — distinguished generically from IED's `fuse_seconds`, which the two relics' shared `effect: "area_damage"` value alone doesn't distinguish), **Reanimation Kit** (`Commander.apply_damage()` intercepts a fatal blow once per equip if the relic declares `effect: "revive_commander"`, reviving at half `max_hp` — `_relic_charge_used` persisted in the save, `SAVE_VERSION` bumped to 4). The other 4 (IED, Mines/Traps, Flare/Air Horn, Fast Response Vehicle) are genuinely deferred, not implemented even partially — see RZ-148/RZ-149/RZ-150/RZ-151, each its own new backlog item: none of them fit anywhere in the existing systems the way the 4 above do, since each is a player-triggered, in-mission action (throw/place/call-in/redeploy) and `docs/UX_UI.md` §4's mission HUD wireframe only specifies one button (the class ability) — there's no existing spec for a second, relic-triggered action, unlike everything else implemented this session | Should | L | RZ-026,054 | engine | Done |
| RZ-110 | District variety: commercial, industrial, transit_hub layouts | Should | L | RZ-052,029 | content | Backlog |
| RZ-111 | Difficulty tuning pass across all 4 tiers | Should | M | RZ-091,033 | content | Backlog |
| RZ-112 | Trait stacking test coverage | Must | S | RZ-108 ✅ | tooling | Done |
| RZ-145 | Fix `Squad.ability_cooldown_remaining` never being decremented — `Squad.tick()` decremented every per-unit `attack_cooldown_remaining` but had no equivalent line for the squad-level ability cooldown, so any ability became permanently unusable for the rest of the mission after its first activation. Found while auditing Heavy Load's cooldown-interaction for RZ-108; fixed in the same commit | Must | S | RZ-108 | engine | Done |
| RZ-146 | Fix `Commander.hp` never resetting between missions, silently violating ADR-0007 ("commander HP is never persisted across missions — always full-HP at mission start") — nothing ever called a reset; a commander simply carried whatever HP they ended the previous mission at. Added `Commander.heal_to_full()`, called from `MissionController._spawn_squads()` for each roster commander. Found while auditing mission-start commander setup for RZ-108; fixed in the same commit | Must | S | RZ-141 ✅ | engine | Done |
| RZ-147 | Mountain trait: "always visible" + active melee combatant behavior — `docs/BALANCE.md`/GDD describe the commander fighting personally from the start, not only once exposed via last-stand (RZ-142). Requires including Mountain commanders in `MissionController`'s `all_units` target list unconditionally (not just when a squad's units are empty) *and* adding a commander-attacks step to `Squad.tick()`'s combat loop (currently only iterates `units`) — materially larger than the other 7 traits' pure data-modifier wiring, and unreachable anyway with no trait-assignment UI yet (RZ-087). Deliberately deferred out of RZ-108's scope | Should | M | RZ-108 ✅ | engine | Backlog |
| RZ-148 | IED relic: thrown explosive with a fuse timer — needs a second, relic-triggered target-mode button on the mission HUD (alongside the existing class-ability button, `MissionController._ability_target_mode`) plus fuse-delay bookkeeping (damage applies `fuse_seconds` after the throw, not instantly) before the area-damage-on-detonation part can reuse `Squad._apply_relic_melee_splash()`-style radius logic. No `docs/UX_UI.md` wireframe specifies this second button's layout/icon. Deliberately deferred out of RZ-109's scope | Should | M | RZ-109 ✅ | engine | Backlog |
| RZ-149 | Mines/Traps relic: placeable, contact-triggered traps (max 2 active) — needs a placement interaction mode (distinct from both movement-order and ability-target clicks), persistent trap entities on the grid surviving across ticks until triggered or the mission ends, and a per-tick contact check against `_active_enemies`. No `docs/UX_UI.md` wireframe specifies the placement UI. Deliberately deferred out of RZ-109's scope | Should | M | RZ-109 ✅ | engine | Backlog |
| RZ-150 | Flare/Air Horn relic: once-per-mission instant reinforcements — needs a third mission-HUD trigger button (distinct from the class ability and any future relic-throw button, RZ-148) plus a way to spawn fresh `Unit`s into a live `Squad` mid-mission (today a squad's `units` array is only ever populated once, at `Squad._init()` — nothing adds units after that). No `docs/UX_UI.md` wireframe specifies this button. Deliberately deferred out of RZ-109's scope | Should | M | RZ-109 ✅ | engine | Backlog |
| RZ-151 | Fast Response Vehicle relic: squad can be deployed a second time in the same mission — the most architecturally open-ended of the deferred relics: squads currently only ever deploy once, at mission start via Mission Prep (RZ-075); "deployed a second time" isn't specified precisely enough to implement without a real design decision (replace a wiped squad? bring reserve units onto an already-placed squad? a new deployment-tile click mid-mission?). Needs a design pass before an implementation plan, not just engineering time. Deliberately deferred out of RZ-109's scope | Should | L | RZ-109 ✅ | engine | Backlog |

## Section F — M4 Polish

| ID | Title | Priority | Size | Deps | Owner | Status |
|---|---|---|---|---|---|---|
| RZ-120 | Full SFX pass per AUDIO_BIBLE event table | Should | L | RZ-015,072 | audio | Backlog |
| RZ-121 | Music intensity layering (calm→siege) | Could | M | RZ-120 | audio | Backlog |
| RZ-122 | Art pass: real tile/unit/zombie sprites replacing placeholders | Should | L | RZ-014,073 | art | Backlog |
| RZ-123 | Blood/gore toggle setting | Should | S | RZ-122 | ui | Backlog |
| RZ-124 | UX pass: all screens match UX_UI.md wireframes | Should | L | RZ-016 | ui | Backlog |
| RZ-125 | Balance pass using balance_report.py output + playtests | Should | L | RZ-033,017 | content | Backlog |
| RZ-126 | Performance pass to PERFORMANCE.md budget (150 concurrent units) | Should | M | RZ-020 | engine | Backlog |
| RZ-127 | Minimap implementation | Could | M | RZ-061 | ui | Backlog |

## Section G — M5 CI/CD & Release Hygiene

| ID | Title | Priority | Size | Deps | Owner | Status |
|---|---|---|---|---|---|---|
| RZ-130 | tests/run_tests.gd headless runner | Must | M | RZ-040 | tooling | Done |
| RZ-131 | test_pathfinding.gd | Must | S | RZ-042,130 | tooling | Done |
| RZ-132 | test_combat_rps.gd | Must | S | RZ-045,130 | tooling | Done |
| RZ-133 | test_economy.gd | Must | S | RZ-051,130 | tooling | Done |
| RZ-134 | test_procgen_determinism.gd | Must | M | RZ-052,130 | tooling | Done |
| RZ-135 | test_save_load_roundtrip.gd | Must | M | RZ-055,130 | tooling | Done |
| RZ-136 | .github/workflows/ci.yml: data validation + unit tests | Must | M | RZ-032,130 | tooling | Done |
| RZ-137 | CI: headless export smoke-build | Should | M | RZ-136 | tooling | Backlog |
| RZ-138 | Export presets (Windows/Linux/macOS) | Should | S | RZ-137 | tooling | Backlog |
| RZ-139 | Fix `UnitData.get_class()` naming collision with native `Object.get_class()` | Must | S | RZ-044 | engine | Done |
| RZ-140 | Fix missing type annotation on `staggered` in `CombatResolver.gd:49` | Must | S | RZ-045 | engine | Done |
| RZ-143 | Fix `EnemyAI.gd`/`MissionController.gd` failing to load in the real engine (`Vector2i.dot()` doesn't exist; two `:=`-inferred-from-Variant errors each) — present since the original bootstrap commit, silently masked because no test file ever loads either script and every past "CI confirmed green" check only read the Passed/Failed summary line, never the full `--import` log | Must | S | RZ-049,062 | engine | Done |

## Section H — Won't (yet) — explicitly deferred, tracked not forgotten

| ID | Title | Priority | Notes |
|---|---|---|---|
| RZ-150 | Multiplayer/co-op | Won't | Out of scope per GDD §16 |
| RZ-151 | Persistent cross-run meta-progression | Won't | Blocked on ADR-0009 being superseded |
| RZ-152 | Full localization/VO | Won't | Out of scope per GDD §16 |
| RZ-153 | Mobile/touch input | Won't | Out of scope per GDD §16 |
| RZ-154 | Steam Workshop / mod support | Won't | Out of scope per GDD §16 |

---

## How to pick up a task

1. Read `docs/ONBOARDING.md` if you haven't already.
2. Find a task with `Status: Backlog` and no unmet `Deps`.
3. Move it (in `docs/TASKS.md`) to "in progress," add yourself as owner.
4. Follow `docs/CONTRIBUTING.md` for branch/commit/PR conventions and `docs/CODE_STYLE.md` for how the code should look.
5. Definition of done for **every** task includes: code/content + tests where applicable + docs updated (this file's Status column, `docs/CHANGELOG.md`, and `docs/ROADMAP.md` if it closes a milestone item).
