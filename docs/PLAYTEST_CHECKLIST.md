# REZIST — Playtest Checklist

Run this checklist at every build that touches gameplay (not needed for pure-docs or pure-data-typo commits). Log results as a dated entry appended to the bottom of this file (newest last) — don't overwrite prior entries, they're a history of what was tested when.

## Setup

- [ ] Fresh run, random seed, Normal difficulty
- [ ] Fresh run, fixed seed `12345`, Normal difficulty (for determinism cross-checks against a prior playtest on the same seed)
- [ ] Continue from an existing save

## Core Loop (M1 scope)

- [ ] Can select a squad and issue a move order; slow-mo engages/disengages smoothly
- [ ] Squad pathing avoids walls and respects elevation costs (no clipping through geometry)
- [ ] Squad autonomously engages enemies in range without further input
- [ ] Riot's Breach ability triggers correctly from an elevation tile onto a lower tile, deals damage + knockback
- [ ] Each of the 3 implemented enemy types (Walker, Riot Zombie, Brute) behaves distinctly and matches its documented counter (`docs/GAME_DESIGN_DOCUMENT.md` §10)
- [ ] Waves spawn from entry points on schedule per `data/waves.json`, not early/late/skipped
- [ ] A safehouse left undefended transitions intact→damaged→burning→collapsed visibly
- [ ] Mission win triggers when all waves survive with ≥1 safehouse standing (or per current win-condition rule)
- [ ] Mission loss triggers on total squad wipe
- [ ] No numeric HP/damage text appears anywhere on screen (ADR-0005 spot-check)

## Run Systems (M2 scope, once implemented)

- [ ] Gold payout matches the formula in `docs/BALANCE.md` §1 for a known mission outcome (hand-calculate and compare)
- [ ] Commander death permanently removes the squad; the same commander cannot reappear
- [ ] Save mid-run, quit, reload — campaign state, gold, and roster match pre-quit state exactly
- [ ] Fog of war only reveals frontier-adjacent nodes, never the full graph
- [ ] A node left behind the progress line becomes permanently unreachable
- [ ] Split-the-party: two squads can be sent to two different reachable nodes in the same turn when available

## Determinism

- [ ] Same seed, same difficulty, fresh run twice → identical campaign graph (compare node count/layout/district types)
- [ ] Same seed entering the same node twice (via two fresh runs) → identical mission grid layout and wave composition

## Readability / Audio

- [ ] Every event in `docs/AUDIO_BIBLE.md` §2 that's implemented actually fires audibly and distinctly
- [ ] Squad strength is readable at a glance from the HUD dot display alone, without needing to zoom
- [ ] Colorblind spot-check: amber-vs-olive (player vs zombie) distinguishable under a colorblindness simulation filter

## Performance

- [ ] Frame rate holds target (`docs/PERFORMANCE.md`) during the largest tested wave (most concurrent enemies)
- [ ] No unbounded memory growth over a full mission (rough check: memory before mission ≈ memory after, via engine profiler)

## Regression

- [ ] Previously-passing checklist items from the last log entry still pass (skim the last entry below before starting)

---

## Log

### 2026-09-23 — M0/M1 bootstrap session
Checklist not yet run against a built executable — this session produced the documentation, data, schema, and initial vertical-slice code (see `docs/HANDOFF.md` for exact scope). First real playtest pass is expected once RZ-054/RZ-055 (run state/save) and a manual Godot editor session are available. Recorded here as a placeholder entry so the log format is established for the next contributor.
