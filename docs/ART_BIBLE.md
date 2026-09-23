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
