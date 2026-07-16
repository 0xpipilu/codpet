#!/usr/bin/env python3

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
PETS_DIR = ROOT / "pets"
INDEX_PATH = ROOT / "index.json"
CATALOG_JS_PATH = ROOT / "catalog.js"

ATLAS_ROWS = [
    {"key": "idle", "label": "Idle", "rowIndex": 0, "frames": 6, "durationMs": 1100},
    {"key": "running-right", "label": "Run Right", "rowIndex": 1, "frames": 8, "durationMs": 980},
    {"key": "running-left", "label": "Run Left", "rowIndex": 2, "frames": 8, "durationMs": 980},
    {"key": "waving", "label": "Waving", "rowIndex": 3, "frames": 4, "durationMs": 840},
    {"key": "jumping", "label": "Jumping", "rowIndex": 4, "frames": 5, "durationMs": 900},
    {"key": "failed", "label": "Failed", "rowIndex": 5, "frames": 8, "durationMs": 1120},
    {"key": "waiting", "label": "Waiting", "rowIndex": 6, "frames": 6, "durationMs": 1260},
    {"key": "running", "label": "Running", "rowIndex": 7, "frames": 6, "durationMs": 960},
    {"key": "review", "label": "Review", "rowIndex": 8, "frames": 6, "durationMs": 1080},
]

ATLAS_SPEC = {
    "columns": 8,
    "rows": 9,
    "frameWidth": 192,
    "frameHeight": 208,
    "sheetWidth": 1536,
    "sheetHeight": 1872,
}


def build_atlas(data: dict, spritesheet_file: Path) -> dict:
    """Build per-pet atlas metadata from pet.json and the actual image size."""
    raw = data.get("atlas") or {}
    atlas = {
        "columns": raw.get("columns", ATLAS_SPEC["columns"]),
        "rows": raw.get("rows", ATLAS_SPEC["rows"]),
        "frameWidth": raw.get("frameWidth", raw.get("cellWidth", ATLAS_SPEC["frameWidth"])),
        "frameHeight": raw.get("frameHeight", raw.get("cellHeight", ATLAS_SPEC["frameHeight"])),
        "sheetWidth": raw.get("sheetWidth", raw.get("width", ATLAS_SPEC["sheetWidth"])),
        "sheetHeight": raw.get("sheetHeight", raw.get("height", ATLAS_SPEC["sheetHeight"])),
    }

    # The newer installed pets use the same 192x208 cells but have 11 rows.
    # Always trust the actual spritesheet dimensions so CSS background scaling
    # cannot expose part of the next row inside a single frame window.
    try:
        with Image.open(spritesheet_file) as image:
            actual_width, actual_height = image.size
        atlas["sheetWidth"] = actual_width
        atlas["sheetHeight"] = actual_height
        if "columns" not in raw:
            atlas["columns"] = actual_width // atlas["frameWidth"]
        if "rows" not in raw:
            atlas["rows"] = actual_height // atlas["frameHeight"]
    except (FileNotFoundError, OSError, ValueError):
        pass

    return {key: int(value) for key, value in atlas.items()}


def build_preview_rows(data: dict) -> list[dict]:
    atlas_row_semantics = data.get("atlasRowSemantics") or {}
    states = data.get("states") or {}
    preview_rows = []

    for row in ATLAS_ROWS:
        semantic_key = atlas_row_semantics.get(row["key"])
        notes = states.get(semantic_key, {}).get("notes", "") if semantic_key else ""
        preview_rows.append(
            {
                **row,
                "semantic": semantic_key,
                "notes": notes,
            }
        )

    return preview_rows


def build_catalog() -> dict:
    pets = []

    # Get all pet directories
    pet_dirs = [path for path in PETS_DIR.iterdir() if path.is_dir()]
    
    # Helper to get folder creation time from /Users/chen/.codex/pets/
    def get_creation_time(p: Path) -> float:
        source_path = Path("/Users/chen/.codex/pets") / p.name
        # Fallback to local workspace pet directory if source_path does not exist
        check_path = source_path if source_path.exists() else p
        try:
            return check_path.stat().st_birthtime
        except AttributeError:
            return check_path.stat().st_mtime

    # Sort descending: newest created pet at the top (index 0), oldest at the bottom
    pet_dirs.sort(key=get_creation_time, reverse=True)

    for pet_dir in pet_dirs:
        pet_json = pet_dir / "pet.json"
        if not pet_json.exists():
            continue

        data = json.loads(pet_json.read_text(encoding="utf-8"))
        spritesheet_path = data.get("spritesheetPath", "spritesheet.webp")
        spritesheet_file = pet_dir / spritesheet_path
        state_names = sorted((data.get("states") or {}).keys())
        preview_rows = build_preview_rows(data)

        pets.append(
            {
                "slug": pet_dir.name,
                "folder": f"pets/{pet_dir.name}",
                "id": data.get("id", pet_dir.name),
                "displayName": data.get("displayName", pet_dir.name),
                "description": data.get("description", ""),
                "spritesheetPath": spritesheet_path,
                "petJsonPath": f"pets/{pet_dir.name}/pet.json",
                "spritesheetFile": f"pets/{pet_dir.name}/{spritesheet_path}",
                "stateNames": state_names,
                "stateCount": len(state_names),
                "atlas": build_atlas(data, spritesheet_file),
                "previewRows": preview_rows,
                "defaultPreviewRow": preview_rows[0]["key"] if preview_rows else None,
            }
        )

    return {
        "count": len(pets),
        "pets": pets,
    }


def main() -> None:
    catalog = build_catalog()

    INDEX_PATH.write_text(
        json.dumps(catalog, ensure_ascii=True, indent=2) + "\n",
        encoding="utf-8",
    )
    CATALOG_JS_PATH.write_text(
        "window.__CODEX_PETS__ = " + json.dumps(catalog, ensure_ascii=True, indent=2) + ";\n",
        encoding="utf-8",
    )
    print(f"Wrote {INDEX_PATH.relative_to(ROOT)}")
    print(f"Wrote {CATALOG_JS_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
