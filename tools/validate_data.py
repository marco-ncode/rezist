#!/usr/bin/env python3
"""Validates every data/*.json file against its schemas/*.schema.json pair,
plus a handful of cross-file reference checks that JSON Schema alone can't
express (e.g. a unit class's ability_id must exist in unit_abilities.json).

Usage: python tools/validate_data.py
Exit code 0 = all data valid, non-zero = at least one failure (message printed).

See docs/DATA_SCHEMA.md for the authoritative description of each file's
shape, and ADR-0003 (docs/DECISIONS.md) for why this script — not the
Godot editor — is the source of truth for data validity.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

try:
    import jsonschema
except ImportError:
    print("ERROR: jsonschema is not installed. Run: pip install -r tools/requirements.txt")
    sys.exit(2)

REPO_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = REPO_ROOT / "data"
SCHEMAS_DIR = REPO_ROOT / "schemas"

# data filename -> schema filename (same basename by convention)
DATA_FILES = [
    "units.json",
    "unit_abilities.json",
    "enemies.json",
    "waves.json",
    "traits.json",
    "relics.json",
    "economy.json",
    "difficulty.json",
    "districts.json",
    "biomes.json",
    "campaign_nodes.json",
    "audio_events.json",
]


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def validate_schema(name: str) -> list[str]:
    errors: list[str] = []
    data_path = DATA_DIR / name
    schema_name = name.replace(".json", ".schema.json")
    schema_path = SCHEMAS_DIR / schema_name

    if not data_path.exists():
        return [f"missing data file: {data_path.relative_to(REPO_ROOT)}"]
    if not schema_path.exists():
        return [f"missing schema file: {schema_path.relative_to(REPO_ROOT)}"]

    data = load_json(data_path)
    schema = load_json(schema_path)

    validator_cls = jsonschema.validators.validator_for(schema)
    validator_cls.check_schema(schema)
    validator = validator_cls(schema)

    for error in sorted(validator.iter_errors(data), key=lambda e: list(e.path)):
        path_str = ".".join(str(p) for p in error.path) or "<root>"
        errors.append(f"{name}: [{path_str}] {error.message}")

    return errors


def cross_reference_checks() -> list[str]:
    errors: list[str] = []

    units = load_json(DATA_DIR / "units.json")
    abilities = load_json(DATA_DIR / "unit_abilities.json")
    traits = load_json(DATA_DIR / "traits.json")
    relics = load_json(DATA_DIR / "relics.json")
    economy = load_json(DATA_DIR / "economy.json")
    enemies = load_json(DATA_DIR / "enemies.json")
    waves = load_json(DATA_DIR / "waves.json")
    districts = load_json(DATA_DIR / "districts.json")
    biomes = load_json(DATA_DIR / "biomes.json")

    ability_ids = {a["id"] for a in abilities.get("abilities", [])}
    trait_ids = {t["id"] for t in traits.get("traits", [])}
    relic_ids = {r["id"] for r in relics.get("relics", [])}
    enemy_ids = {e["id"] for e in enemies.get("enemies", [])}
    wave_set_ids = {w["id"] for w in waves.get("wave_sets", [])}
    biome_ids = {b["id"] for b in biomes.get("biomes", [])}

    # Every unit class's ability_id (if set) must exist in unit_abilities.json,
    # and that ability's unit_class must point back to this class.
    for cls in units.get("classes", []):
        ability_id = cls.get("ability_id")
        if ability_id is None:
            continue
        if ability_id not in ability_ids:
            errors.append(f"units.json: class '{cls['id']}' references unknown ability_id '{ability_id}'")
            continue
        ability = next(a for a in abilities["abilities"] if a["id"] == ability_id)
        if ability.get("unit_class") != cls["id"]:
            errors.append(
                f"unit_abilities.json: ability '{ability_id}' unit_class "
                f"'{ability.get('unit_class')}' does not match owning class '{cls['id']}'"
            )

    # Every trait_discounts key in economy.json must be a real trait id.
    for trait_id in economy.get("trait_discounts", {}):
        if trait_id not in trait_ids:
            errors.append(f"economy.json: trait_discounts references unknown trait id '{trait_id}'")

    # Every wave_set's spawns must reference a real enemy id.
    for wave_set in waves.get("wave_sets", []):
        for wave in wave_set.get("waves", []):
            for spawn in wave.get("spawns", []):
                if spawn["enemy_id"] not in enemy_ids:
                    errors.append(
                        f"waves.json: wave_set '{wave_set['id']}' references unknown enemy_id '{spawn['enemy_id']}'"
                    )

    # Every district's default_wave_set and biome_id must exist, and its
    # enemy_palette_bias entries must be real enemy ids.
    for district in districts.get("districts", []):
        if district["default_wave_set"] not in wave_set_ids:
            errors.append(
                f"districts.json: district '{district['id']}' references unknown "
                f"default_wave_set '{district['default_wave_set']}'"
            )
        if district["biome_id"] not in biome_ids:
            errors.append(f"districts.json: district '{district['id']}' references unknown biome_id '{district['biome_id']}'")
        for enemy_id in district.get("enemy_palette_bias", []):
            if enemy_id not in enemy_ids:
                errors.append(
                    f"districts.json: district '{district['id']}' enemy_palette_bias references unknown enemy_id '{enemy_id}'"
                )

    # relic_ids/trait_ids sets are currently only referenced from campaign
    # save data (runtime, not static data) — nothing else to cross-check here.
    _ = relic_ids

    return errors


def main() -> int:
    all_errors: list[str] = []

    for name in DATA_FILES:
        all_errors.extend(validate_schema(name))

    if not all_errors:
        all_errors.extend(cross_reference_checks())

    if all_errors:
        print(f"FAILED — {len(all_errors)} issue(s):\n")
        for error in all_errors:
            print(f"  - {error}")
        return 1

    print(f"OK — {len(DATA_FILES)} data files validated against their schemas, cross-references clean.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
