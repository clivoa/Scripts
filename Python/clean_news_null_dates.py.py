#!/usr/bin/env python3
import json
from pathlib import Path
from datetime import datetime

INPUT = Path("news_recent.json")
BACKUP = Path("news_recent_backup.json")

def is_valid_item(item: dict) -> bool:
    """Return True if item has valid date fields."""
    if not isinstance(item, dict):
        return False

    if item.get("published") in (None, "", "null"):
        return False
    if item.get("published_ts") in (None, "", "null"):
        return False

    # Optional: sanity check (timestamps antes de 2000 ou muito futuros)
    ts = item.get("published_ts")
    try:
        dt = datetime.utcfromtimestamp(ts)
        if dt.year < 2000 or dt.year > 2100:
            return False
    except Exception:
        return False

    return True


def find_items_list_container(data):
    """
    Dado o JSON já carregado, descobre onde está a lista de notícias.

    Retorna:
      (container, key, items_list)

    - Se o próprio data for a lista, retorna (None, None, data)
    - Se for dict, tenta achar uma lista em chaves comuns.
    """
    if isinstance(data, list):
        return None, None, data

    if not isinstance(data, dict):
        return None, None, None

    # chaves preferidas se existirem
    preferred_keys = ["items", "entries", "news", "results", "data"]

    for key in preferred_keys:
        value = data.get(key)
        if isinstance(value, list):
            return data, key, value

    # fallback: primeira lista encontrada em qualquer chave
    for key, value in data.items():
        if isinstance(value, list):
            return data, key, value

    # não encontrou lista
    return None, None, None


def main():
    if not INPUT.exists():
        print(f"ERROR: {INPUT} not found.")
        return

    print(f"[INFO] Loading {INPUT}...")
    raw_text = INPUT.read_text(encoding="utf-8")
    try:
        data = json.loads(raw_text)
    except json.JSONDecodeError as e:
        print(f"[ERROR] Failed to parse JSON: {e}")
        return

    # Sempre cria backup do arquivo original
    print(f"[INFO] Creating backup: {BACKUP}")
    BACKUP.write_text(raw_text, encoding="utf-8")

    container, key, items = find_items_list_container(data)
    if items is None:
        print("[ERROR] Could not find a list of entries in JSON structure.")
        print("        Root type:", type(data).__name__)
        if isinstance(data, dict):
            print("        Available keys:", ", ".join(data.keys()))
        return

    if container is None:
        print("[INFO] Detected JSON root as a list of entries.")
    else:
        print(f"[INFO] Detected entries list under key '{key}'.")

    total_before = len(items)
    cleaned = [item for item in items if is_valid_item(item)]
    removed = total_before - len(cleaned)

    print(f"[INFO] Found {total_before} entries.")
    print(f"[INFO] Removed {removed} invalid items (with null/invalid dates).")

    # Ordena por published_ts desc, se disponível
    cleaned.sort(key=lambda x: x.get("published_ts", 0), reverse=True)

    # Reinsere na estrutura original
    if container is None:
        out_data = cleaned
    else:
        container[key] = cleaned
        out_data = data

    print(f"[INFO] Writing cleaned data back to {INPUT}")
    INPUT.write_text(
        json.dumps(out_data, indent=2, ensure_ascii=False),
        encoding="utf-8"
    )

    print("[DONE] Cleaning finished successfully.")


if __name__ == "__main__":
    main()
