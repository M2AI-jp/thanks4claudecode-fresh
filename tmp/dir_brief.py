#!/usr/bin/env python3
"""
dir_brief.py - Display directory contents with summary in table format.

Usage: ./tmp/dir_brief.py <path>
"""

import argparse
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
    try:
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
    except (PermissionError, OSError):
        pass
    return entries


def print_table(entries: list[dict]) -> None:
    """Print entries in ASCII table format."""
    col_name = 40
    col_type = 6
    col_size = 12
    col_mtime = 19
    total_width = col_name + col_type + col_size + col_mtime + 5

    # Top border
    print("+" + "-" * (total_width - 2) + "+")

    # Header
    print(f"| {'Name':<{col_name}} {'Type':<{col_type}} {'Size':>{col_size}} {'Modified':<{col_mtime}}|")
    print("+" + "-" * (total_width - 2) + "+")

    # Rows
    if entries:
        for e in entries:
            name = e["name"][:38] + ".." if len(e["name"]) > 40 else e["name"]
            size_str = format_size(e["size"]) if e["type"] == "FILE" else "-"
            mtime_str = format_datetime(e["mtime"]) if e["mtime"] > 0 else "-"
            print(f"| {name:<{col_name}} {e['type']:<{col_type}} {size_str:>{col_size}} {mtime_str:<{col_mtime}}|")
    else:
        print(f"| {'(empty directory)':<{total_width - 4}}|")

    # Bottom border
    print("+" + "-" * (total_width - 2) + "+")


def print_summary(entries: list[dict]) -> None:
    """Print summary: total count, max size, latest modification."""
    total = len(entries)
    files = [e for e in entries if e["type"] == "FILE"]
    dirs = [e for e in entries if e["type"] == "DIR"]

    max_size = max((e["size"] for e in files), default=0)
    latest_mtime = max((e["mtime"] for e in entries if e["mtime"] > 0), default=0)

    print()
    print("Summary:")
    print(f"  Total: {total} items ({len(files)} files, {len(dirs)} directories)")
    print(f"  Max size: {format_size(max_size)}")
    latest_label = format_datetime(latest_mtime) if latest_mtime > 0 else "-"
    print(f"  Latest modification: {latest_label}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Display directory contents with summary in table format."
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

    print_table(entries)
    print_summary(entries)
    return 0


if __name__ == "__main__":
    exit(main())
