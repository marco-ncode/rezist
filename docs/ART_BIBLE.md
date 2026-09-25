# REZIST — Art Bible

## 1. Visual Identity

Stylized urban diorama, **readable before pretty**. The player must identify unit type, enemy type, and structure state at a glance, at zoomed-out tactical camera distance, without reading a label. Silhouette and color-coding carry all the information.

- **Style:** clean low-poly / flat-vector hybrid. No painterly texture detail, no photorealism, no fine facial detail on any character (pillar 3 + tone — see GDD "not horror gratuito").
- **Camera:** fixed-angle orthographic, high tactical top-down-ish angle (matches Bad North's diorama read), slight isometric tilt.
- **Diorama scale:** a single mission district reads as a "tabletop model of a city block" — buildings are simplified blocks, not habitable interiors.

## 2. Palette

Desaturated urban base, punched through by a small set of high-saturation functional accent colors that never mean anything else:

| Role | Color | Hex (reference) |
|---|---|---|
| Concrete / base ground | Cool grey | `#8A8D91` |
| Asphalt / roads | Dark grey | `#3C3F42` |
| Rubble / damaged tile | Warm brown-grey | `#6E645A` |
| Water/flood tile | Desaturated teal | `#4C6B6B` |
| **Player squads** | Emergency amber | `#F2A93B` |
| **Player commander accent** (flag/hi-vis) | Bright amber-white | `#FFD37A` |
| **Zombies (base)** | Sickly desaturated green-grey | `#6B7A5E` |
| **Zombies (armored/riot)** | Darker olive + red accent (danger) | `#4B5940` / `#B23A3A` |
| Safehouse intact | Off-white / warm light | `#D9D2C4` |
| Safehouse damaged | Ash grey | `#8C8478` |
| Safehouse burning | Amber-orange glow | `#E2712B` |
| Safehouse collapsed | Charcoal black | `#231F1D` |
| UI danger/critical | Red | `#C23B3B` |
| UI neutral/info | Slate blue | `#5C7A99` |

**Rule:** amber = player-controlled, always. Red = danger/critical only. Never reuse amber for enemies or red for anything non-threatening — color-role consistency is part of the readability contract.

Dark-mode/night missions (future content) shift the base palette's value down but keep hue relationships and the amber/red functional-color rule intact.

## 3. Unit & Enemy Silhouettes

Each class/enemy type must be identifiable by **silhouette alone** at small size:
- **Riot:** wide rectangular shield silhouette, low stance.
- **Marksman:** narrow profile, visible long-gun silhouette.
- **Barricade:** tall vertical polearm silhouette, wider stance.
- **Recruit:** plain, smallest silhouette (visually "unfinished" to read as base tier).
- **Walker:** slouched, arms loose, no read-able gear.
- **Riot Zombie:** blocky torso (worn riot armor/vest silhouette).
- **Spitter/Thrower:** raised-arm silhouette (throwing pose readable even static).
- **Brute:** oversized, hunched, broad shoulders — largest non-boss silhouette.
- **Leaper:** crouched, elongated limbs, coiled posture.
- **Colossus:** largest silhouette in the game, unmistakable, always rendered above fog/occlusion.

No detailed faces on any character model — zombies read as shapes/postures/gear, not gore-focused. This is a hard rule tied to the "survival urbano, non horror gratuito" tone requirement.

## 4. Structures

Safehouses use the 4-state damage system from ADR-0005 (intact/damaged/burning/collapsed) driven entirely by sprite/particle swap — never a bar. Building shapes vary slightly by district type (`data/districts.json`) but stay simple blocky forms consistent with the diorama scale.

## 5. UI Kit

- Minimal chrome, semi-transparent panels over the diorama, never full-screen opaque overlays during gameplay (keep the battlefield visible — tactical awareness > menu polish, per pillar 3).
- Icons: flat, single-color-on-transparent, one icon per ability/relic/trait, no text-in-icon.
- Typography: a single clean grotesque/sans family across all UI (family TBD at asset-sourcing time — record the final choice as an ADR-adjacent note in `docs/ASSET_PIPELINE.md` once picked); no serif, no decorative fonts (keeps the "modern emergency signage" feel).

## 6. Do / Don't

**Do:** communicate state through color + silhouette + simple motion (shake, flash, particle burst). Keep contrast high between player-amber, enemy-green/olive, and neutral-grey terrain.

**Don't:** add gore detail beyond what the blood/gore toggle's "on" state needs (impact particles, not dismemberment detail). Don't add numeric HP/damage text anywhere (ADR-0005). Don't give zombies detailed faces. Don't introduce a second "friendly" color besides amber.

## 7. v1 Placeholder Art

Per `docs/ASSET_PIPELINE.md`, v1 ships with primitive `Polygon2D`/`ColorRect` placeholders using exactly this palette, so even unfinished art reads correctly in playtests.

## 8. Character Art Production Spec (for the real art pass, RZ-122)

Concrete production specs for whoever — person or agent — draws the actual unit/enemy sprites, filling the gap `docs/ASSET_PIPELINE.md` leaves open (it defines naming/import conventions but not canvas size, perspective, or the exact roster). Everything here follows from `docs/TECHNICAL_DESIGN_DOCUMENT.md`'s actual rendering approach, not just design intent — cross-check against it if the engine setup ever changes.

### Perspective and framing

The engine renders **flat 2D sprites**, not 3D models — `TECHNICAL_DESIGN_DOCUMENT.md`: "2.5D — orthographic camera over a 2D tile grid with a per-tile elevation offset." Concretely (`GridRenderer.tile_to_screen()`): a tile's screen position is `(x * TILE_SIZE, y * TILE_SIZE - elevation * ELEVATION_OFFSET)` — a straight top-down grid, not a 2:1 isometric diamond; elevation only nudges a tile's Y position upward to fake height. Draw characters accordingly:
- **Top-down / slight three-quarter-front view** (think *Into the Breach* or *Bad North*'s actual read) — not a side profile, not a classic isometric diamond projection.
- Must read correctly both stationary and mid-move — v1 needs no walk-cycle frames (see "What's NOT needed" below), so one static pose per sprite must carry the silhouette on its own.

### File specs

| Parameter | Value |
|---|---|
| Format | `.png`, transparent background (alpha) |
| Working canvas | **256×256 px**, square, character centered with breathing room at the edges — today's placeholder `TILE_SIZE` is only 32px (`GridRenderer.gd`), real art works at a higher native resolution and gets scaled down at import/runtime, not drawn at 32px |
| Color | palette in §2 only — no new hues |
| Godot import | `Filter = Off` (crisp edges, matches the vector-clean direction — `docs/ASSET_PIPELINE.md`) |

### Full character roster

**Player squads** — 4 classes, some with multiple levels (`data/units.json`), filename `unit_<class>_<level>.png` per `docs/ASSET_PIPELINE.md`:

| Class | Levels | Silhouette requirement (§3) |
|---|---|---|
| Recruit | 1 | plainest/"least finished" of all — reads as base tier |
| Riot | 3 (L1/L2/L3) | wide rectangular frontal shield, low stance |
| Marksman | 3 | narrow profile, visible long-gun silhouette |
| Barricade | 3 | tall vertical polearm, wider stance |

10 sprites total. A commander is the same class body with the amber-white accent (`#FFD37A`) applied to one detail (hi-vis vest or a small flag/marker) — not a separate character model.

**Zombies** — 8 types (`data/enemies.json`), filename `enemy_<type>.png`:

| Type | Silhouette requirement (§3) |
|---|---|
| Walker | slouched, arms loose, no readable gear |
| Riot Zombie | blocky torso (worn riot armor/vest silhouette) |
| Spitter | raised-arm throwing pose, readable even static |
| Thrower | same throwing-pose family as Spitter |
| Brute | oversized, hunched, broad shoulders — largest non-boss silhouette |
| Brute Spitter | armed variant of Brute |
| Leaper | crouched, elongated limbs, coiled posture |
| Colossus | largest silhouette in the game, unmistakable |

**Structures** — 4 damage states (ADR-0005), filename `structure_safehouse_<state>.png`: `intact` / `damaged` / `burning` / `collapsed`. State change is sprite/particle swap only, never a bar or number.

### What's NOT needed (v1)

- No frame-by-frame walk/attack animation — state and motion read through sprite swap, scale, and particles, not an animation sheet.
- No HP/damage numerals drawn on a character (ADR-0005) — "health" is dot-per-unit in the UI only, never on the sprite itself.
- No gore beyond generic impact particles.

### Naming and folders (from `docs/ASSET_PIPELINE.md`)

```
game/assets/art/units/unit_riot_l2.png
game/assets/art/enemies/enemy_walker.png
game/assets/art/structures/structure_safehouse_burning.png
```

Every non-original asset needs CC0 or another clearly-permissive license, documented in a sibling `LICENSE`/`CREDITS.txt`, per `docs/ASSET_PIPELINE.md`'s licensing rule.
