# REZIST — Asset Pipeline

## Directory Layout

```
game/assets/
├── placeholder/       # v1 primitive art (see below) — safe to delete wholesale once real art lands
│   ├── tiles/
│   ├── units/
│   ├── enemies/
│   ├── structures/
│   ├── ui/
│   └── audio/
├── art/                # future real art, mirrors placeholder/ subfolders
└── audio/               # future real audio, mirrors placeholder/audio/ layout
```

## Naming Convention

`snake_case`, prefixed by category, suffixed by variant/state:

- Tiles: `tile_<type>_<variant>.png` (e.g. `tile_road_01.png`, `tile_rubble_01.png`)
- Units: `unit_<class>_<level>.png` (e.g. `unit_riot_l2.png`)
- Enemies: `enemy_<type>.png` (e.g. `enemy_walker.png`)
- Structures: `structure_safehouse_<state>.png` (`intact`/`damaged`/`burning`/`collapsed`)
- UI: `ui_<screen>_<element>.png`
- Audio: `sfx_<event_id>.ogg`, `music_<mood>_<variant>.ogg` — `event_id` must match a key in the AudioManager event table (`docs/AUDIO_BIBLE.md`)

## v1 Placeholder Art Policy

Per ADR-0008, v1 uses **primitive placeholder art**: flat-colored `Polygon2D`/`ColorRect`/simple procedural meshes generated at runtime or trivial `.png` swatches — no external art assets required to reach a playable vertical slice. This unblocks engine/gameplay work without waiting on an art track. Placeholder palette follows `docs/ART_BIBLE.md` §1 so the "feel" is directionally correct even before real art lands.

## Import Settings (Godot)

- Sprites: `Filter = Off` (crisp pixel/vector look, matches the low-poly/vector-clean direction in `docs/ART_BIBLE.md`), `Mipmaps = Off` for 2.5D UI-adjacent sprites, `On` for anything seen at varying zoom.
- Audio: import as `.ogg` (Vorbis) for music/ambience, `.wav` for short SFX needing minimal latency.
- Godot's `.import/` cache is gitignored (`.gitignore`) — never commit it.

## Licensing

- Every third-party asset added under `game/assets/art/` or `game/assets/audio/` must ship with a sibling `LICENSE` or `CREDITS.txt` naming source + license terms.
- Only CC0, permissively-licensed, or project-original assets are acceptable — no asset whose license is unclear or restrictive gets merged. If in doubt, flag it in the PR rather than merging.
- `CONTRIBUTORS.md` tracks who/what agent produced which asset batch for attribution purposes.

## Export/Pipeline Notes

- No external DCC (Blender/Aseprite) round-trip is required for v1 placeholder art.
- When real art lands (M4, RZ-122), source files (`.blend`, `.aseprite`, etc.) live outside the git repo (or in Git LFS if adopted — not set up in v1, propose via ADR if needed) and only exported `.png`/`.glb`/`.ogg` are committed.
