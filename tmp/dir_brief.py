#!/usr/bin/env python3
"""
dir_brief.py - Display a brief summary of directory contents.

Shows a single-level listing of files/directories with summary statistics.
"""

import os
import sys
import stat
from datetime import datetime
from typing import List, Tuple, Optional


def format_size(size: int) -> str:
    """Format size in bytes to human-readable string."""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size < 1024:
            if unit == 'B':
                return f"{size}{unit}"
            return f"{size:.1f}{unit}"
        size /= 1024
    return f"{size:.1f}PB"


def format_datetime(ts: float) -> str:
    """Format timestamp to human-readable datetime string."""
    return datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')


def get_entry_info(path: str, name: str) -> Tuple[str, str, int, float]:
    """Get info for a single directory entry.

    Returns: (name, type, size, mtime)
    """
    full_path = os.path.join(path, name)
    try:
        st = os.stat(full_path)
        is_dir = stat.S_ISDIR(st.st_mode)
        entry_type = 'DIR' if is_dir else 'FILE'
        size = 0 if is_dir else st.st_size
        mtime = st.st_mtime
        return (name, entry_type, size, mtime)
    except OSError:
        return (name, '???', 0, 0)


def list_directory(path: str) -> List[Tuple[str, str, int, float]]:
    """List directory contents (1 level only).

    Returns: list of (name, type, size, mtime) tuples
    """
    entries = []
    try:
        for name in os.listdir(path):
            entries.append(get_entry_info(path, name))
    except PermissionError:
        print(f"Error: Permission denied: {path}", file=sys.stderr)
        sys.exit(1)
    except OSError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    # Sort: directories first, then by name
    entries.sort(key=lambda x: (0 if x[1] == 'DIR' else 1, x[0].lower()))
    return entries


def calculate_column_widths(entries: List[Tuple[str, str, int, float]]) -> Tuple[int, int, int, int]:
    """Calculate column widths for the table."""
    # Minimum widths from headers
    name_width = 4  # "Name"
    type_width = 4  # "Type"
    size_width = 4  # "Size"
    mtime_width = 19  # "Modified" (YYYY-MM-DD HH:MM:SS)

    for name, entry_type, size, mtime in entries:
        name_width = max(name_width, len(name))
        type_width = max(type_width, len(entry_type))
        size_width = max(size_width, len(format_size(size)))

    return name_width, type_width, size_width, mtime_width


def print_table(entries: List[Tuple[str, str, int, float]], path: str) -> None:
    """Print entries as ASCII table with summary."""
    # Calculate column widths
    name_w, type_w, size_w, mtime_w = calculate_column_widths(entries)

    # Build separator line
    sep = f"+{'-' * (name_w + 2)}+{'-' * (type_w + 2)}+{'-' * (size_w + 2)}+{'-' * (mtime_w + 2)}+"

    # Print header
    print(f"\nDirectory: {path}")
    print(sep)
    print(f"| {'Name':<{name_w}} | {'Type':<{type_w}} | {'Size':>{size_w}} | {'Modified':<{mtime_w}} |")
    print(sep)

    # Print entries
    for name, entry_type, size, mtime in entries:
        size_str = format_size(size) if entry_type != 'DIR' else '-'
        mtime_str = format_datetime(mtime) if mtime > 0 else '-'
        print(f"| {name:<{name_w}} | {entry_type:<{type_w}} | {size_str:>{size_w}} | {mtime_str:<{mtime_w}} |")

    print(sep)

    # Calculate and print summary
    total_count = len(entries)
    file_entries = [e for e in entries if e[1] == 'FILE']
    dir_entries = [e for e in entries if e[1] == 'DIR']

    file_count = len(file_entries)
    dir_count = len(dir_entries)

    if file_entries:
        max_size = max(e[2] for e in file_entries)
        max_size_str = format_size(max_size)
    else:
        max_size = 0
        max_size_str = '0B'

    if entries:
        latest_mtime = max(e[3] for e in entries)
        latest_mtime_str = format_datetime(latest_mtime)
    else:
        latest_mtime_str = '-'

    # Summary table
    print("\nSummary:")
    summary_sep = "+----------------+----------------------+"
    print(summary_sep)
    print(f"| {'Item':<14} | {'Value':<20} |")
    print(summary_sep)
    print(f"| {'Total Count':<14} | {total_count:<20} |")
    print(f"| {'Files':<14} | {file_count:<20} |")
    print(f"| {'Directories':<14} | {dir_count:<20} |")
    print(f"| {'Max Size':<14} | {max_size_str:<20} |")
    print(f"| {'Latest Update':<14} | {latest_mtime_str:<20} |")
    print(summary_sep)


def main() -> None:
    """Main entry point."""
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <path>", file=sys.stderr)
        sys.exit(1)

    path = sys.argv[1]

    if not os.path.exists(path):
        print(f"Error: Path does not exist: {path}", file=sys.stderr)
        sys.exit(1)

    if not os.path.isdir(path):
        print(f"Error: Not a directory: {path}", file=sys.stderr)
        sys.exit(1)

    entries = list_directory(path)
    print_table(entries, path)


if __name__ == '__main__':
    main()
