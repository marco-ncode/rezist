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
| RZ-048 | Implement core/abilities/ Focused Volley + Line Charge | Should | M | RZ-047 | engine | Backlog |
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
| RZ-068 | Danger indicator (arrows/pings toward active entry points) | Should | S | RZ-067 | ui | Backlog |
| RZ-069 | Mission win/lose detection + resolution screen | Must | M | RZ-050,066 | engine | Done |
| RZ-070 | Ability activation input (Breach) wired to HUD button | Must | S | RZ-047,067 | ui | Done |
| RZ-071 | autoload/AudioManager.gd + event→sound data table | Must | M | RZ-060 | audio | Done |
| RZ-072 | Hook ≥5 gameplay events to AudioManager (placeholder SFX) | Should | S | RZ-071 | audio | Done |
| RZ-073 | Placeholder art pass: tiles, units, zombies, safehouses (primitive shapes/colors) | Must | M | RZ-061,065,066 | art | Done |
| RZ-074 | Main Menu scene (New Run / Continue / Settings / Quit) | Should | S | RZ-060 | ui | Backlog |
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
| RZ-085 | Armory/Upgrade screen (spend gold on class levels/abilities/relics) | Must | L | RZ-051,067 | ui | Backlog |
| RZ-086 | Roster/Commander screen (traits, equipped relic, alive/dead history) | Should | M | RZ-054 | ui | Backlog |
| RZ-087 | Hero rescue mission variant (trapped survivor tile + recruit-on-win) | Should | M | RZ-052,054 | engine | Backlog |
| RZ-088 | Permadeath flow: commander death → squad removal → UI feedback | Must | M | RZ-141 ✅,RZ-142 ✅,046 ✅ | engine | Backlog |
| RZ-089 | Run-over detection (total wipe / campaign complete) + summary screen | Must | M | RZ-054,081 | ui | Backlog |
| RZ-090 | Save/Load wired to Main Menu "Continue" | Must | M | RZ-055,074 | engine | Backlog |
| RZ-091 | Difficulty selection (Easy/Normal/Hard/Very Hard) at run start | Should | S | RZ-028,080 | ui | Backlog |
| RZ-092 | Checkpoint nodes on campaign graph | Could | S | RZ-081 | engine | Backlog |
| RZ-141 | Wire `RunState` into `Main.gd`/`MissionController.gd` (roster persistence, permadeath → `RunState`, gold → `RunState`) | Must | M | RZ-054 ✅ | engine | Done |

## Section E — M3 Content Expansion

| ID | Title | Priority | Size | Deps | Owner | Status |
|---|---|---|---|---|---|---|
| RZ-100 | Marksman class: L1-L3 + Focused Volley ability | Must | M | RZ-048 | content | Backlog |
| RZ-101 | Barricade class: L1-L3 + Line Charge ability | Must | M | RZ-048 | content | Backlog |
| RZ-102 | Recruit→class promotion flow at L2 upgrade | Must | S | RZ-100,101 | engine | Backlog |
| RZ-103 | Spitter enemy type + ranged_kite behavior | Must | S | RZ-049 | content | Backlog |
| RZ-104 | Brute Spitter enemy type | Should | S | RZ-103 | content | Backlog |
| RZ-105 | Thrower enemy type | Should | S | RZ-049 | content | Backlog |
| RZ-106 | Leaper enemy type + leap_flank behavior | Must | M | RZ-049 | engine | Backlog |
| RZ-107 | Colossus boss enemy type + siege_boss behavior | Should | L | RZ-049 | engine | Backlog |
| RZ-108 | Implement remaining traits (Fleet of Foot, Heavy Load, Heavy Weapons, Ironskin, Mountain, Popular, Sharp Weapons, Skillful) | Must | M | RZ-025,046 | engine | Backlog |
| RZ-109 | Implement remaining relics (IED, Reanimation Kit, FRV, Mines, Emergency Fund, Tactical Radio, Sledgehammer, Flare) | Should | L | RZ-026,054 | engine | Backlog |
| RZ-110 | District variety: commercial, industrial, transit_hub layouts | Should | L | RZ-052,029 | content | Backlog |
| RZ-111 | Difficulty tuning pass across all 4 tiers | Should | M | RZ-091,033 | content | Backlog |
| RZ-112 | Trait stacking test coverage | Must | S | RZ-108 | tooling | Backlog |

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
