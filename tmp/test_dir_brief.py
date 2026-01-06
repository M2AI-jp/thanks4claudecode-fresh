"""Tests for dir_brief.py"""

import os
import sys
import tempfile
from pathlib import Path

import pytest

# Import the module under test
sys.path.insert(0, str(Path(__file__).parent))
from dir_brief import (
    format_size,
    format_datetime,
    get_entry_type,
    get_entries,
    print_table,
    print_summary,
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

    def test_gigabytes(self):
        assert "GB" in format_size(2 * 1024 * 1024 * 1024)

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

    def test_symlink(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            target = Path(tmpdir) / "target.txt"
            target.write_text("content")
            link = Path(tmpdir) / "link.txt"
            link.symlink_to(target)
            assert get_entry_type(link) == "LINK"


class TestGetEntries:
    """Tests for get_entries function."""

    def test_empty_directory(self):
        """Empty directory should return empty list."""
        with tempfile.TemporaryDirectory() as tmpdir:
            entries = get_entries(Path(tmpdir))
            assert entries == []

    def test_with_files(self):
        """Directory with files should list all files."""
        with tempfile.TemporaryDirectory() as tmpdir:
            (Path(tmpdir) / "file1.txt").write_text("hello")
            (Path(tmpdir) / "file2.txt").write_text("world")

            entries = get_entries(Path(tmpdir))
            assert len(entries) == 2
            names = [e["name"] for e in entries]
            assert "file1.txt" in names
            assert "file2.txt" in names

    def test_with_subdirectory(self):
        """Directory with subdirectory should list it as DIR type."""
        with tempfile.TemporaryDirectory() as tmpdir:
            subdir = Path(tmpdir) / "subdir"
            subdir.mkdir()

            entries = get_entries(Path(tmpdir))
            assert len(entries) == 1
            assert entries[0]["type"] == "DIR"
            assert entries[0]["name"] == "subdir"

    def test_entry_has_required_fields(self):
        """Each entry should have name, type, size, mtime fields."""
        with tempfile.TemporaryDirectory() as tmpdir:
            (Path(tmpdir) / "test.txt").write_text("content")

            entries = get_entries(Path(tmpdir))
            assert len(entries) == 1
            entry = entries[0]
            assert "name" in entry
            assert "type" in entry
            assert "size" in entry
            assert "mtime" in entry


class TestPrintTable:
    """Tests for print_table function."""

    def test_empty_entries(self, capsys):
        """Empty entries should show '(empty directory)' message."""
        print_table([])
        captured = capsys.readouterr()
        assert "(empty directory)" in captured.out
        assert "+" in captured.out  # Table border

    def test_with_entries(self, capsys):
        """Entries should be displayed in table format."""
        entries = [
            {"name": "test.txt", "type": "FILE", "size": 100, "mtime": 1705318245.0}
        ]
        print_table(entries)
        captured = capsys.readouterr()
        assert "test.txt" in captured.out
        assert "FILE" in captured.out


class TestPrintSummary:
    """Tests for print_summary function."""

    def test_empty_entries(self, capsys):
        """Empty entries should show summary with zero counts."""
        print_summary([])
        captured = capsys.readouterr()
        assert "Total: 0 items" in captured.out
        assert "0 files" in captured.out
        assert "0 directories" in captured.out

    def test_with_files(self, capsys):
        """Summary should show correct file count and max size."""
        entries = [
            {"name": "a.txt", "type": "FILE", "size": 100, "mtime": 1705318245.0},
            {"name": "b.txt", "type": "FILE", "size": 200, "mtime": 1705318246.0},
        ]
        print_summary(entries)
        captured = capsys.readouterr()
        assert "Total: 2 items" in captured.out
        assert "2 files" in captured.out
        assert "Max size:" in captured.out


class TestMain:
    """Tests for main function (CLI)."""

    def test_nonexistent_path(self, monkeypatch, capsys):
        """Non-existent path should return error code 1."""
        monkeypatch.setattr(sys, "argv", ["dir_brief.py", "/nonexistent/path/xyz123"])
        result = main()
        assert result == 1
        captured = capsys.readouterr()
        assert "does not exist" in captured.out

    def test_file_instead_of_directory(self, monkeypatch, capsys):
        """File path (not directory) should return error code 1."""
        with tempfile.NamedTemporaryFile(delete=False) as f:
            try:
                monkeypatch.setattr(sys, "argv", ["dir_brief.py", f.name])
                result = main()
                assert result == 1
                captured = capsys.readouterr()
                assert "not a directory" in captured.out
            finally:
                os.unlink(f.name)

    def test_empty_directory(self, monkeypatch, capsys):
        """Empty directory should display summary with zero items."""
        with tempfile.TemporaryDirectory() as tmpdir:
            monkeypatch.setattr(sys, "argv", ["dir_brief.py", tmpdir])
            result = main()
            assert result == 0
            captured = capsys.readouterr()
            assert "(empty directory)" in captured.out
            assert "Total: 0 items" in captured.out
            assert "Max size:" in captured.out
            assert "Latest modification:" in captured.out

    def test_valid_directory_with_files(self, monkeypatch, capsys):
        """Valid directory with files should display table and summary."""
        with tempfile.TemporaryDirectory() as tmpdir:
            (Path(tmpdir) / "test.txt").write_text("content")
            (Path(tmpdir) / "another.txt").write_text("more content")

            monkeypatch.setattr(sys, "argv", ["dir_brief.py", tmpdir])
            result = main()
            assert result == 0
            captured = capsys.readouterr()
            assert "test.txt" in captured.out
            assert "another.txt" in captured.out
            assert "Total:" in captured.out
            assert "2 files" in captured.out

    def test_valid_directory_with_subdirs(self, monkeypatch, capsys):
        """Valid directory with subdirectories should count them correctly."""
        with tempfile.TemporaryDirectory() as tmpdir:
            (Path(tmpdir) / "subdir1").mkdir()
            (Path(tmpdir) / "subdir2").mkdir()
            (Path(tmpdir) / "file.txt").write_text("content")

            monkeypatch.setattr(sys, "argv", ["dir_brief.py", tmpdir])
            result = main()
            assert result == 0
            captured = capsys.readouterr()
            assert "subdir1" in captured.out
            assert "subdir2" in captured.out
            assert "file.txt" in captured.out
            assert "1 files" in captured.out
            assert "2 directories" in captured.out
