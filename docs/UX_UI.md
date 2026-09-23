# REZIST — UX / UI Flow

Textual wireframes for every screen (GDD §13). "Textual wireframe" = a layout description precise enough to build from without a visual mockup tool.

---

## 1. Main Menu

```
┌──────────────────────────────────────────┐
│                  REZIST                  │
│                                            │
│              [ New Run ]                  │
│              [ Continue ]  (disabled if no save) │
│              [ Settings ]                 │
│              [ Quit ]                     │
│                                            │
│  v0.1.0 · seed display N/A here           │
└──────────────────────────────────────────┘
```
`New Run` → difficulty select (inline sub-panel: Easy/Normal/Hard/Very Hard + seed field, auto-random if blank) → Campaign Map. `Continue` → loads slot 0 save → Campaign Map at saved state.

## 2. Campaign Map

```
┌──────────────────────────────────────────┐
│ Gold: 47      Seed: #1829304     [Menu]   │
│ ┌────────────────────────────────────┐   │
│ │   (node graph, layered left→right)  │   │
│ │   ○──○     ○ = unvisited, visible   │   │
│ │  ╱ │  ╲    ● = visited              │   │
│ │ ●  ○   ?   ? = fogged (type hinted) │   │
│ │  ╲ │  ╱    ▲ = boss node            │   │
│ │   ●──▲                              │   │
│ └────────────────────────────────────┘   │
│ [Roster] [Armory]      [Deploy Selected]  │
└──────────────────────────────────────────┘
```
Click a reachable (edge-connected, unvisited, not-yet-lost) node → right-side preview panel slides in showing district type icon + threat hint + "Deploy" / "Back" buttons. Multiple simultaneously reachable nodes can each be selected in the same turn if enough idle squads exist (split-the-party, GDD §12) — each selected node gets a squad-assignment mini-panel before committing.

## 3. Mission Prep

```
┌──────────────────────────────────────────┐
│  District: Residential Block   [Start >]  │
│ ┌────────────────────────────────────┐   │
│ │      (grid preview, entry points     │   │
│ │       marked, safehouses marked,     │   │
│ │       deployment zone highlighted)   │   │
│ └────────────────────────────────────┘   │
│  Squad Tray: [Sq.A][Sq.B][Sq.C][ + ]      │
│  (drag/click a squad, click a deploy tile)│
└──────────────────────────────────────────┘
```
Player must place every squad they intend to bring before `[Start]` is enabled (at least 1 required). `[Start]` transitions to Mission with a brief camera-establishing shot then normal time_scale.

## 4. Mission (core gameplay HUD)

```
┌──────────────────────────────────────────┐
│ Wave 2/3  ▓▓▓▓░░░░ (next wave timer)      │  ← wave indicator, top center
│                                            │
│         (battlefield, full-bleed)         │
│      ⚠ (danger indicator pings near        │
│         active entry points, screen edge)  │
│                                            │
│ [Sq.A●●●●●○] [Sq.B●●●●●●] [Sq.C●●●]  [Ability: Breach ⏱4s] │
└──────────────────────────────────────────┘
```
- Bottom bar: one tile per squad showing commander portrait + **dot-per-living-unit** (never a number, ADR-0005) + selection highlight. Selecting a squad reveals its ability button (icon + cooldown ring, no numeric cooldown text — a filling ring reads as "ready" visually) and triggers slow-mo easing (`order_issued` audio cue plays on confirm, not on hover).
- Click-to-move: after selecting a squad, valid destination tiles highlight; clicking one issues the order and eases back to normal time_scale.
- Danger indicator (RZ-068): small arrow/glow pulses at the screen edge in the direction of any entry point currently spawning zombies, fades once the wave's spawns are exhausted.

## 5. Mission Resolution

```
┌──────────────────────────────────────────┐
│           MISSION COMPLETE                │
│  Safehouses saved: 3/4                    │
│  Squads returned: 3/3                     │
│  Gold earned: +38                         │
│  [Hero Rescued: "M. Torres" — Add to roster] (if applicable) │
│              [ Continue ]                 │
└──────────────────────────────────────────┘
```
On loss (all squads wiped / retreat), swap the headline and gold line reflects the reduced retreat payout; no "Hero Rescued" row.

## 6. Armory / Upgrade Screen

```
┌──────────────────────────────────────────┐
│ Gold: 47                        [Back]    │
│ ┌─────────────┬─────────────┬───────────┐ │
│ │  Class Tiers │  Abilities  │  Relics   │ │
│ └─────────────┴─────────────┴───────────┘ │
│  (grid of purchasable cards, cost shown    │
│   as a gold-coin icon + number — this is   │
│   currency, not a combat stat, so a number │
│   here does not violate ADR-0005)          │
└──────────────────────────────────────────┘
```
Select a commander first (roster strip along the top) to see their squad's upgrade options contextually.

## 7. Roster / Commander Screen

```
┌──────────────────────────────────────────┐
│  [Portrait] J. Alvarez — Riot L2           │
│  Trait: Ironskin (damage taken reduced)    │
│  Relic: Mines                              │
│  Squad size: ●●●●●○ (5/6)                  │
│  Status: Active                            │
│  ───────────────────────────────────────   │
│  Fallen Commanders:                        │
│   • D. Okafor — died Mission 4 (Brute)     │
└──────────────────────────────────────────┘
```
Fallen commander log is permanent flavor/history for the run — reinforces pillar 2 (permadeath should sting, and be remembered).

## 8. Game Over / Run Summary

```
┌──────────────────────────────────────────┐
│              RUN OVER                     │
│  Reached: District 7 of ~11                │
│  Commanders lost: 4                        │
│  Safehouses saved (total): 9                │
│           [ Start New Run ]                │
└──────────────────────────────────────────┘
```
Shown on total wipe or full campaign completion (headline differs: "RUN OVER" vs "CITY SECURED").

---

## Global UX Rules

- No screen ever shows a raw unit HP or enemy HP number (ADR-0005). Gold, timers-as-progress-bars-only (never "12.4s" text during combat), and purchase costs are the only numeric UI elements.
- Every screen transition has an audio cue per `docs/AUDIO_BIBLE.md`.
- The battlefield is never fully obscured by UI during Mission (pillar 3 — tactical awareness first).
