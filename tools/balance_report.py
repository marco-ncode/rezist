#!/usr/bin/env python3
"""Prints derived balance tables from data/*.json so numbers can be sanity
checked without opening the Godot editor. Diagnostic only — data/*.json
and docs/BALANCE.md remain authoritative; this script never writes back.

Usage: python tools/balance_report.py
"""
from __future__ import annotations

import json
import math
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = REPO_ROOT / "data"


def load(name: str) -> dict:
    with (DATA_DIR / name).open("r", encoding="utf-8") as f:
        return json.load(f)


def ttk_matrix() -> None:
    """Time-to-kill (in hits) for each allied class level vs each enemy,
    ignoring blocks/RPS bonuses (a first-order estimate, not exact combat
    resolution — see docs/BALANCE.md §6 for the full formula)."""
    units = load("units.json")
    enemies = load("enemies.json")

    print("=== TTK matrix (hits to kill, base damage only) ===")
    header = ["class@lvl"] + [e["id"] for e in enemies["enemies"]]
    print(" | ".join(f"{h:>14}" for h in header))

    for cls in units["classes"]:
        for level in cls["levels"]:
            label = f"{cls['id']}@L{level['level']}"
            row = [label]
            for enemy in enemies["enemies"]:
                dmg = level["damage"]
                if cls.get("armor_type") == "reach" and enemy.get("weak_to") == "reach":
                    dmg *= 1.5
                hits = math.ceil(enemy["hp"] / max(dmg, 1))
                row.append(str(hits))
            print(" | ".join(f"{c:>14}" for c in row))
    print()


def enemy_ttk_vs_units() -> None:
    """How many hits an enemy needs to kill each allied class level."""
    units = load("units.json")
    enemies = load("enemies.json")

    print("=== Enemy TTK vs allied units (hits to kill) ===")
    header = ["enemy"] + [f"{c['id']}@L{lv['level']}" for c in units["classes"] for lv in c["levels"]]
    print(" | ".join(f"{h:>14}" for h in header))

    for enemy in enemies["enemies"]:
        row = [enemy["id"]]
        for cls in units["classes"]:
            for level in cls["levels"]:
                hp = level["hp"]
                hits = math.ceil(hp / max(enemy["damage"], 1))
                row.append(str(hits))
        print(" | ".join(f"{c:>14}" for c in row))
    print()


def gold_curve() -> None:
    economy = load("economy.json")
    difficulty = load("difficulty.json")

    print("=== Gold-per-mission estimate (2 safehouses saved, 3 squads of 5 survive) ===")
    safehouses_saved = 2
    squads = 3
    units_per_squad = 5
    base = safehouses_saved * economy["gold_per_safehouse"]
    base += squads * (economy["squad_survival_base_gold"] + units_per_squad * economy["gold_per_surviving_unit"])

    for tier in difficulty["tiers"]:
        total = round(base * tier["gold_mult"])
        print(f"  {tier['id']:>10}: {total} gold (mult {tier['gold_mult']})")
    print()


def upgrade_cost_summary() -> None:
    economy = load("economy.json")
    print("=== Upgrade costs ===")
    print(f"  L1 -> L2: {economy['upgrade_cost']['l1_to_l2']} gold")
    print(f"  L2 -> L3: {economy['upgrade_cost']['l2_to_l3']} gold")
    print(f"  Ability unlock: {economy['ability_unlock_cost']} gold")
    print()


def main() -> None:
    ttk_matrix()
    enemy_ttk_vs_units()
    gold_curve()
    upgrade_cost_summary()


if __name__ == "__main__":
    main()
