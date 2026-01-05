#!/usr/bin/env python3
"""Tests for filesearch.py"""

import pytest
from pathlib import Path
from io import StringIO
import sys

from filesearch import format_size, list_directory


class TestFormatSize:
    """Tests for format_size function."""

    def test_bytes_format(self):
        """Bytes under 1024 should show as B."""
        assert format_size(0) == "0B"
        assert format_size(100) == "100B"
        assert format_size(1023) == "1023B"

    def test_kilobytes_format(self):
        """Bytes 1024-1MB should show as KB."""
        assert format_size(1024) == "1.0KB"
        assert format_size(2048) == "2.0KB"
        assert format_size(1536) == "1.5KB"
        assert format_size(1024 * 1024 - 1) == "1024.0KB"

    def test_megabytes_format(self):
        """Bytes 1MB-1GB should show as MB."""
        assert format_size(1024 * 1024) == "1.0MB"
        assert format_size(1024 * 1024 * 10) == "10.0MB"
        assert format_size(1024 * 1024 * 512) == "512.0MB"

    def test_gigabytes_format(self):
        """Bytes >= 1GB should show as GB."""
        assert format_size(1024 * 1024 * 1024) == "1.0GB"
        assert format_size(1024 * 1024 * 1024 * 2) == "2.0GB"


class TestListDirectory:
    """Tests for list_directory function."""

    def test_list_normal_directory(self, tmp_path, capsys):
        """Normal directory listing should work."""
        # Create test files and directories
        (tmp_path / "file1.txt").write_text("hello")
        (tmp_path / "file2.txt").write_text("world")
        (tmp_path / "subdir").mkdir()

        list_directory(tmp_path)
        captured = capsys.readouterr()

        assert "file1.txt" in captured.out
        assert "file2.txt" in captured.out
        assert "subdir" in captured.out
        assert "[D]" in captured.out  # directory marker
        assert "[F]" in captured.out  # file marker
        assert "Total: 3 entries" in captured.out

    def test_list_empty_directory(self, tmp_path, capsys):
        """Empty directory should show 0 entries."""
        list_directory(tmp_path)
        captured = capsys.readouterr()

        assert "Total: 0 entries" in captured.out
        assert "Max size: N/A (no files)" in captured.out

    def test_nonexistent_path(self, tmp_path, capsys):
        """Nonexistent path should show error message."""
        nonexistent = tmp_path / "does_not_exist"

        list_directory(nonexistent)
        captured = capsys.readouterr()

        assert "Error:" in captured.out
        assert "does not exist" in captured.out

    def test_file_as_path(self, tmp_path, capsys):
        """Passing a file instead of directory should show error."""
        test_file = tmp_path / "test.txt"
        test_file.write_text("content")

        list_directory(test_file)
        captured = capsys.readouterr()

        assert "Error:" in captured.out
        assert "is not a directory" in captured.out

    def test_max_size_tracking(self, tmp_path, capsys):
        """Largest file should be reported in summary."""
        (tmp_path / "small.txt").write_text("x")
        (tmp_path / "large.txt").write_text("x" * 1000)

        list_directory(tmp_path)
        captured = capsys.readouterr()

        assert "Max size:" in captured.out
        assert "large.txt" in captured.out

    def test_directories_listed_before_files(self, tmp_path, capsys):
        """Directories should be listed before files."""
        (tmp_path / "zfile.txt").write_text("content")
        (tmp_path / "adir").mkdir()

        list_directory(tmp_path)
        captured = capsys.readouterr()

        # Find positions in output
        adir_pos = captured.out.find("adir")
        zfile_pos = captured.out.find("zfile.txt")

        assert adir_pos < zfile_pos, "Directory should appear before file"
