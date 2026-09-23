# REZIST — Audio Bible

## 1. Philosophy

Every meaningful gameplay event must be identifiable **with eyes closed** (GDD pillar 3 extended to audio). Sound is not decoration here — it is a second, parallel information channel: a player who only listens should still know roughly what's happening (an order was given, a squad is fighting, a safehouse is burning, a commander died).

Tone: tense survival-urban, not horror-jumpscare. Deep, physical bass for zombie hordes; sharp, clean, "emergency broadcast" tones for UI and player actions. No cheap stingers.

## 2. Event → Sound Table

This table is the authoritative event list `AudioManager.play_event(event_id)` must support. Implementation tracks it as data (`data_runtime` lookup, ARCHITECTURE.md §13 invariant — never a hardcoded `match` in `AudioManager.gd`).

| `event_id` | Trigger | Sound character |
|---|---|---|
| `order_issued` | Player confirms a squad move order | Short clean radio-blip, distinct from UI clicks |
| `slow_mo_enter` / `slow_mo_exit` | Engine.time_scale easing starts/ends | Subtle low-pass filter sweep on the mix bus, not a discrete SFX |
| `unit_attack_melee` | Any melee hit resolves | Sharp physical impact (varies slightly by weapon: shield bash / polearm thrust) |
| `unit_attack_ranged` | Any ranged hit/shot resolves | Gunshot/thrown-object whoosh depending on attacker |
| `unit_blocked` | `CombatResult.blocked == true` | Distinct metallic "clang" (shield block) — must never be confused with a hit landing |
| `unit_death_ally` | An allied `Unit` dies (not commander) | Short somber cue, low volume (frequent event, must not fatigue) |
| `unit_death_enemy` | A zombie dies | Wet/blunt "drop" cue, lower priority in the mix than ally events |
| `commander_died` | Permadeath trigger | Distinct, unmistakable, non-repeating "loss" sting — the single most important audio cue in the game |
| `ability_activated_breach` / `_volley` / `_charge` | Ability triggers | Each ability gets its own unique, loud, satisfying cue — players should want to hear these |
| `ability_on_cooldown_denied` | Player tries an ability still cooling down | Soft negative UI tone |
| `safehouse_damaged` | Structure state intact→damaged | Glass break / alarm blip |
| `safehouse_burning` | Structure state →burning | Fire crackle loop starts, spatialized at structure position |
| `safehouse_collapsed` | Structure state →collapsed | Heavy rubble collapse, one-shot |
| `safehouse_saved` (mission end) | Structure survives to mission resolution | Short positive chime |
| `wave_incoming` | `WaveController` starts a new wave | Rising tension stinger + music intensity bump |
| `wave_cleared` | Wave's zombies fully eliminated | Brief tension release |
| `mission_won` / `mission_lost` | Resolution state | Distinct musical stingers, opposite emotional valence |
| `gold_earned` | Payout screen tally | Coin/cash-register style tick per unit tallied (capped rate to avoid spam on large payouts) |
| `upgrade_purchased` | Armory screen purchase confirmed | Positive mechanical "click-thunk" |
| `hero_rescued` | Trapped survivor mission variant won | Warm, hopeful short cue — the game's "good news" sound |
| `entry_point_breached` | First zombie crosses into the grid from an entry point this wave | Low rumble ping, spatialized, distinguishable from `wave_incoming` |

## 3. Music

- **Calm/prep layer:** sparse, low-key ambient bed during Mission Prep and Campaign Map — tension held in reserve, not absent.
- **Siege layers:** additive stems (bass, percussion, tension pad) that fade in as `AudioManager.set_music_intensity(level)` rises with active wave density and proximity of zombies to safehouses. Never a hard music track swap — always a crossfade/stem-additive approach to avoid jarring cuts.
- **Boss layer:** an additional distinct stem/motif triggers when a Colossus is active on the grid, on top of the siege layers (not replacing them).

## 4. Mixing / Ducking

- Buses: `Music`, `SFX_Combat`, `SFX_UI`, `SFX_Ambience`, `Master`.
- `commander_died` and `mission_won`/`mission_lost` duck `Music` and `SFX_Combat` briefly so they always read clearly — these are the highest-priority cues in the game.
- `SFX_Combat` has its own internal priority/ducking so simultaneous events (a 5-unit melee scrum) don't clip into an indistinct wall of noise — favor `commander_died` > `ability_activated_*` > `unit_blocked` > `safehouse_*` > `unit_attack_*` > `unit_death_*` when the mixer must drop overlapping voices.

## 5. v1 Placeholder Audio

Per `docs/BACKLOG.md` RZ-072, v1 wires at minimum: `order_issued`, `unit_attack_melee`, `unit_death_ally`, `safehouse_damaged`, `wave_incoming` to short placeholder/generated tones — proving the event pipeline end-to-end before a full audio pass (RZ-120, M4).
