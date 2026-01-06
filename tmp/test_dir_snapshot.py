"""Tests for dir_snapshot.py"""

import tempfile
import os
from pathlib import Path

import pytest

# Import the module under test
import sys
sys.path.insert(0, str(Path(__file__).parent))
from dir_snapshot import (
    format_size,
    format_datetime,
    get_entry_type,
    get_entries,
    main,
)


class TestFormatSize:
    """Tests for format_size function."""

    def test_bytes(self):
        assert "B" in format_size(100)

    def test_kilobytes(self):
        assert "KB" in format_size(2048)

    def test_megabytes(self):
        assert "MB" in format_size(2 * 1024 * 1024)

    def test_zero(self):
        result = format_size(0)
        assert "0" in result and "B" in result


class TestFormatDatetime:
    """Tests for format_datetime function."""

    def test_format(self):
        # 2024-01-15 12:30:45
        ts = 1705318245.0
        result = format_datetime(ts)
        assert "2024" in result
        assert "01" in result
        assert ":" in result


class TestGetEntryType:
    """Tests for get_entry_type function."""

    def test_directory(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            assert get_entry_type(Path(tmpdir)) == "DIR"

    def test_file(self):
        with tempfile.NamedTemporaryFile(delete=False) as f:
            try:
                assert get_entry_type(Path(f.name)) == "FILE"
            finally:
                os.unlink(f.name)


class TestGetEntries:
    """Tests for get_entries function."""

    def test_empty_directory(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            entries = get_entries(Path(tmpdir))
            assert entries == []

    def test_with_files(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create test files
            (Path(tmpdir) / "file1.txt").write_text("hello")
            (Path(tmpdir) / "file2.txt").write_text("world")

            entries = get_entries(Path(tmpdir))
            assert len(entries) == 2
            names = [e["name"] for e in entries]
            assert "file1.txt" in names
            assert "file2.txt" in names

    def test_with_subdirectory(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            subdir = Path(tmpdir) / "subdir"
            subdir.mkdir()

            entries = get_entries(Path(tmpdir))
            assert len(entries) == 1
            assert entries[0]["type"] == "DIR"


class TestMain:
    """Tests for main function (CLI)."""

    def test_nonexistent_path(self, monkeypatch, capsys):
        monkeypatch.setattr(sys, "argv", ["dir_snapshot.py", "/nonexistent/path"])
        result = main()
        assert result == 1
        captured = capsys.readouterr()
        assert "does not exist" in captured.out

    def test_file_instead_of_directory(self, monkeypatch, capsys):
        with tempfile.NamedTemporaryFile(delete=False) as f:
            try:
                monkeypatch.setattr(sys, "argv", ["dir_snapshot.py", f.name])
                result = main()
                assert result == 1
                captured = capsys.readouterr()
                assert "not a directory" in captured.out
            finally:
                os.unlink(f.name)

    def test_empty_directory(self, monkeypatch, capsys):
        with tempfile.TemporaryDirectory() as tmpdir:
            monkeypatch.setattr(sys, "argv", ["dir_snapshot.py", tmpdir])
            result = main()
            assert result == 0
            captured = capsys.readouterr()
            assert "empty" in captured.out

    def test_valid_directory(self, monkeypatch, capsys):
        with tempfile.TemporaryDirectory() as tmpdir:
            (Path(tmpdir) / "test.txt").write_text("content")
            monkeypatch.setattr(sys, "argv", ["dir_snapshot.py", tmpdir])
            result = main()
            assert result == 0
            captured = capsys.readouterr()
            assert "test.txt" in captured.out
            assert "Total:" in captured.out
            assert "Max size:" in captured.out
