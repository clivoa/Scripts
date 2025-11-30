#!/usr/bin/env python3
import json
from pathlib import Path
from datetime import datetime, timezone

# -------- CONFIG --------
BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
ARCHIVE_DIR = DATA_DIR / "archive"

TARGET_FILES = []

# Add main file
TARGET_FILES.append(DATA_DIR / "news_recent.json")

# Recursively add all JSON files from /archive/*
if ARCHIVE_DIR.exists():
    for f in ARCHIVE_DIR.rglob("*.json"):
        TARGET_FILES.append(f)

# Same filtering rules used in main script (ajuste aqui se mudar no build_news_json.py)
PROMO_PATTERNS = [
    "black friday", "cyber monday", "prime day",
    "deal", "deals", "on sale", "discount", "% off",
    "save up to", "gift guide", "what to buy",
    "top picks", "best deals", "price drop",
    "live-tracking", "ipad deals", "tv deals",
    "i'm live-tracking",
]

BAD_CATEGORY_TERMS = [
    "deal", "shopping", "buying guide", "reviews",
    "review", "top picks", "gift guide", "hardware deals",
]


def looks_promotional(title: str, summary: str, tags: list[str]) -> bool:
    text = f"{title} {summary}".lower()

    # Text match
    for p in PROMO_PATTERNS:
        if p in text:
            return True

    # Tag/category match
    for t in tags:
        for bad in BAD_CATEGORY_TERMS:
            if bad in t.lower():
                return True

    return False


def clean_items(items, path: Path):
    cleaned_items = []
    dropped_promotional = 0
    dropped_no_date = 0

    for item in items:
        if not isinstance(item, dict):
            # lixo inesperado, mantemos como está pra não quebrar
            cleaned_items.append(item)
            continue

        title = item.get("title", "")
        summary = item.get("summary", "")
        tags = item.get("tags", []) or item.get("smart_groups", [])

        published_ts = item.get("published_ts")
        if published_ts is None:
            dropped_no_date += 1
            continue

        if looks_promotional(title, summary, tags):
            dropped_promotional += 1
            continue

        cleaned_items.append(item)

    print(f"[INFO] Final items in {path.name}: {len(cleaned_items)}")
    print(f"[INFO] Removed promotional: {dropped_promotional}")
    print(f"[INFO] Removed missing dates: {dropped_no_date}")

    return cleaned_items


def clean_file(path: Path):
    print(f"\n[INFO] Cleaning: {path}")

    try:
        raw = path.read_text(encoding="utf-8")
        data = json.loads(raw)
    except Exception as e:
        print(f"[ERROR] Failed reading {path}: {e}")
        return

    # Caso 1: formato dict com "items" (ex: news_recent.json)
    if isinstance(data, dict) and "items" in data:
        items = data["items"]
        if not isinstance(items, list):
            print(f"[WARN] 'items' in {path} is not a list. Skipping.")
            return

        cleaned_items = clean_items(items, path)

        data["items"] = cleaned_items
        data["total_items"] = len(cleaned_items)
        data["cleaned_at"] = datetime.now(timezone.utc).isoformat()

        obj_to_write = data

    # Caso 2: raiz é uma lista de items (ex: monthly/yearly archives)
    elif isinstance(data, list):
        cleaned_items = clean_items(data, path)
        obj_to_write = cleaned_items

    else:
        print(f"[WARN] File {path} has unsupported JSON structure. Skipping.")
        return

    # Grava de volta
    try:
        path.write_text(json.dumps(obj_to_write, indent=2), encoding="utf-8")
        print(f"[INFO] Written cleaned data to {path}")
    except Exception as e:
        print(f"[ERROR] Failed writing {path}: {e}")


def main():
    print("=== JSON Cleaner for S33R News ===")
    print(f"Found {len(TARGET_FILES)} files")

    for file in TARGET_FILES:
        if file.exists():
            clean_file(file)
        else:
            print(f"[WARN] File not found: {file}")

    print("\n[OK] Cleanup complete!")


if __name__ == "__main__":
    main()
