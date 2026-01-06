#!/usr/bin/env python3
"""
dir_snapshot.py - Display directory contents in table format.

Usage: ./tmp/dir_snapshot.py <path>
"""

import argparse
import os
import stat
from datetime import datetime
from pathlib import Path


def format_size(size: int) -> str:
    """Format file size in human-readable format."""
    for unit in ["B", "KB", "MB", "GB"]:
        if size < 1024:
            return f"{size:>7.1f} {unit}" if unit != "B" else f"{size:>7} {unit}"
        size /= 1024
    return f"{size:>7.1f} TB"


def format_datetime(timestamp: float) -> str:
    """Format timestamp as YYYY-MM-DD HH:MM:SS."""
    return datetime.fromtimestamp(timestamp).strftime("%Y-%m-%d %H:%M:%S")


def get_entry_type(path: Path) -> str:
    """Return entry type: DIR, FILE, or LINK."""
    if path.is_symlink():
        return "LINK"
    elif path.is_dir():
        return "DIR"
    else:
        return "FILE"


def get_entries(target_path: Path) -> list[dict]:
    """Get list of entries in the target directory (1 level only)."""
    entries = []
    for entry in sorted(target_path.iterdir()):
        try:
            st = entry.stat(follow_symlinks=False)
            entries.append({
                "name": entry.name,
                "type": get_entry_type(entry),
                "size": st.st_size if not entry.is_dir() else 0,
                "mtime": st.st_mtime,
            })
        except (PermissionError, OSError):
            entries.append({
                "name": entry.name,
                "type": "ERROR",
                "size": 0,
                "mtime": 0,
            })
    return entries


def print_table(entries: list[dict]) -> None:
    """Print entries in table format with summary."""
    # Header
    print(f"{'Name':<40} {'Type':<6} {'Size':>12} {'Modified':<19}")
    print("-" * 80)

    # Rows
    for e in entries:
        name = e["name"][:38] + ".." if len(e["name"]) > 40 else e["name"]
        size_str = format_size(e["size"]) if e["type"] == "FILE" else "-"
        mtime_str = format_datetime(e["mtime"]) if e["mtime"] > 0 else "-"
        print(f"{name:<40} {e['type']:<6} {size_str:>12} {mtime_str:<19}")

    print("-" * 80)


def print_summary(entries: list[dict]) -> None:
    """Print summary: total count, max size, latest modification."""
    total = len(entries)
    files = [e for e in entries if e["type"] == "FILE"]
    dirs = [e for e in entries if e["type"] == "DIR"]

    max_size = max((e["size"] for e in files), default=0)
    latest_mtime = max((e["mtime"] for e in entries if e["mtime"] > 0), default=0)

    print(f"Total: {total} items ({len(files)} files, {len(dirs)} directories)")
    print(f"Max size: {format_size(max_size)}")
    if latest_mtime > 0:
        print(f"Latest modification: {format_datetime(latest_mtime)}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Display directory contents in table format."
    )
    parser.add_argument("path", help="Target directory path")
    args = parser.parse_args()

    target = Path(args.path)

    if not target.exists():
        print(f"Error: Path '{target}' does not exist.")
        return 1

    if not target.is_dir():
        print(f"Error: Path '{target}' is not a directory.")
        return 1

    entries = get_entries(target)

    if not entries:
        print(f"Directory '{target}' is empty.")
        return 0

    print_table(entries)
    print_summary(entries)
    return 0


if __name__ == "__main__":
    exit(main())
