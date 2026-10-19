"""Reverse the most recent file operation recorded by yazi's init.lua journal."""

import json
import os
import shutil
import sys
from urllib.parse import unquote

STATE = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
JOURNAL = os.path.join(STATE, "yazi", "undo.jsonl")
DATA = os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share")
TRASH = os.path.join(DATA, "Trash")


def load():
    try:
        with open(JOURNAL, encoding="utf-8", errors="surrogateescape") as f:
            lines = [line for line in f.read().splitlines() if line.strip()]
    except FileNotFoundError:
        return []
    entries = []
    for line in lines:
        try:
            entries.append(json.loads(line))
        except ValueError:
            pass
    return entries


def save(entries):
    os.makedirs(os.path.dirname(JOURNAL), exist_ok=True)
    tmp = JOURNAL + ".tmp"
    with open(tmp, "w", encoding="utf-8", errors="surrogateescape") as f:
        for entry in entries[-200:]:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    os.replace(tmp, JOURNAL)


def name(path):
    return os.path.basename(path.rstrip("/")) or path


def undo_move(items):
    blocked = [to for _, to in items if not os.path.lexists(to)]
    blocked += [src for src, _ in items if os.path.lexists(src)]
    if blocked:
        return False, "Can't undo, something changed since: " + ", ".join(map(name, blocked[:3]))
    for src, to in reversed(items):
        shutil.move(to, src)
    if len(items) == 1:
        src, to = items[0]
        if name(src) == name(to):
            return True, f"Moved {name(src)} back to {name(os.path.dirname(src))}/"
        return True, f"Undid rename {name(to)} → {name(src)}"
    return True, f"Undid rename/move of {len(items)} items"


def trash_lookup():
    """Map original path -> list of (deletion date, trash name), newest first."""
    found = {}
    info_dir = os.path.join(TRASH, "info")
    try:
        infos = os.listdir(info_dir)
    except FileNotFoundError:
        return found
    for info in infos:
        if not info.endswith(".trashinfo"):
            continue
        path = date = None
        try:
            with open(os.path.join(info_dir, info), encoding="utf-8", errors="surrogateescape") as f:
                for line in f:
                    if line.startswith("Path="):
                        path = unquote(line[5:].rstrip("\n"), errors="surrogateescape")
                    elif line.startswith("DeletionDate="):
                        date = line[13:].rstrip("\n")
        except OSError:
            continue
        if path:
            if not os.path.isabs(path):
                path = os.path.join(os.path.dirname(TRASH), path)
            found.setdefault(path, []).append((date or "", info[: -len(".trashinfo")]))
    for candidates in found.values():
        candidates.sort(reverse=True)
    return found


def undo_trash(paths):
    lookup = trash_lookup()
    restored, problems = [], []
    for path in paths:
        if os.path.lexists(path):
            problems.append(f"{name(path)} already exists")
            continue
        candidates = lookup.get(path)
        if not candidates:
            problems.append(f"{name(path)} isn't in the Trash")
            continue
        trash_name = candidates[0][1]
        shutil.move(os.path.join(TRASH, "files", trash_name), path)
        os.remove(os.path.join(TRASH, "info", trash_name + ".trashinfo"))
        restored.append(path)
    if not restored:
        return False, "Can't restore: " + "; ".join(problems[:3])
    msg = f"Restored {name(restored[0])}" if len(restored) == 1 else f"Restored {len(restored)} items"
    if problems:
        msg += " (skipped: " + "; ".join(problems[:3]) + ")"
    return True, msg


def main():
    entries = load()
    if not entries:
        print("Nothing to undo")
        return 0
    entry = entries.pop()
    op = entry.get("op")
    if op == "delete":
        save(entries)
        n = len(entry.get("paths", []))
        print(f"Can't undo a permanent delete (D) of {n} item{'s' if n != 1 else ''}")
        return 1
    if op == "move":
        ok, msg = undo_move([tuple(pair) for pair in entry.get("items", [])])
    elif op == "trash":
        ok, msg = undo_trash(entry.get("paths", []))
    else:
        ok, msg = False, f"Unknown operation {op!r}"
    # Drop the entry even on failure so the next undo reaches older operations.
    save(entries)
    print(msg)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
