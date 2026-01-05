#!/usr/bin/env python3
"""
filesearch.py - Display file/directory listing with metadata.

Usage:
    python filesearch.py [path]
    python filesearch.py --help
"""

import argparse
import os
from datetime import datetime
from pathlib import Path


def format_size(size_bytes: int) -> str:
    """Convert bytes to human-readable format."""
    if size_bytes < 1024:
        return f"{size_bytes}B"
    elif size_bytes < 1024 * 1024:
        return f"{size_bytes / 1024:.1f}KB"
    elif size_bytes < 1024 * 1024 * 1024:
        return f"{size_bytes / (1024 * 1024):.1f}MB"
    else:
        return f"{size_bytes / (1024 * 1024 * 1024):.1f}GB"


def format_datetime(timestamp: float) -> str:
    """Format timestamp to readable datetime string."""
    return datetime.fromtimestamp(timestamp).strftime("%Y-%m-%d %H:%M:%S")


def list_directory(path: Path) -> None:
    """List directory contents with metadata."""
    if not path.exists():
        print(f"Error: Path '{path}' does not exist.")
        return

    if not path.is_dir():
        print(f"Error: Path '{path}' is not a directory.")
        return

    print(f"Path: {path.resolve()}")
    print("-" * 40)

    entries = []
    max_size = 0
    max_size_name = ""

    try:
        for entry in sorted(path.iterdir(), key=lambda x: (x.is_file(), x.name.lower())):
            stat_info = entry.stat()
            mtime = format_datetime(stat_info.st_mtime)

            if entry.is_dir():
                entry_type = "[D]"
                size_str = ""
                size = 0
            else:
                entry_type = "[F]"
                size = stat_info.st_size
                size_str = format_size(size)
                if size > max_size:
                    max_size = size
                    max_size_name = entry.name

            entries.append({
                "type": entry_type,
                "name": entry.name,
                "size_str": size_str,
                "size": size,
                "mtime": mtime,
            })
    except PermissionError:
        print("Error: Permission denied.")
        return

    # Calculate column widths
    if entries:
        max_name_len = max(len(e["name"]) for e in entries)
        max_size_len = max(len(e["size_str"]) for e in entries) if entries else 0

        for e in entries:
            if e["size_str"]:
                print(f"{e['type']} {e['name']:<{max_name_len}}  {e['size_str']:>{max_size_len}} {e['mtime']}")
            else:
                print(f"{e['type']} {e['name']:<{max_name_len}}  {' ' * max_size_len} {e['mtime']}")

    print("-" * 40)
    print(f"Total: {len(entries)} entries")

    if max_size > 0:
        print(f"Max size: {format_size(max_size)} ({max_size_name})")
    else:
        print("Max size: N/A (no files)")


def main():
    parser = argparse.ArgumentParser(
        description="Display file/directory listing with metadata.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    python filesearch.py .
    python filesearch.py /path/to/directory
        """,
    )
    parser.add_argument(
        "path",
        nargs="?",
        default=".",
        help="Path to list (default: current directory)",
    )

    args = parser.parse_args()
    list_directory(Path(args.path))


if __name__ == "__main__":
    main()
