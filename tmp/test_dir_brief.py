#!/usr/bin/env python3
"""
test_dir_brief.py - Tests for dir_brief.py

Run with: pytest tmp/test_dir_brief.py
"""

import os
import sys
import tempfile
import subprocess
from pathlib import Path

# Add tmp directory to path for importing
sys.path.insert(0, str(Path(__file__).parent))

import dir_brief


class TestFormatSize:
    """Tests for format_size function."""

    def test_bytes(self):
        assert dir_brief.format_size(0) == '0B'
        assert dir_brief.format_size(512) == '512B'
        assert dir_brief.format_size(1023) == '1023B'

    def test_kilobytes(self):
        assert dir_brief.format_size(1024) == '1.0KB'
        assert dir_brief.format_size(2048) == '2.0KB'

    def test_megabytes(self):
        assert dir_brief.format_size(1024 * 1024) == '1.0MB'

    def test_gigabytes(self):
        assert dir_brief.format_size(1024 * 1024 * 1024) == '1.0GB'


class TestFormatDatetime:
    """Tests for format_datetime function."""

    def test_format(self):
        # 2026-01-01 00:00:00 UTC
        ts = 1735689600.0
        result = dir_brief.format_datetime(ts)
        # Should be in YYYY-MM-DD HH:MM:SS format
        assert len(result) == 19
        assert result[4] == '-'
        assert result[7] == '-'
        assert result[10] == ' '
        assert result[13] == ':'
        assert result[16] == ':'


class TestGetEntryInfo:
    """Tests for get_entry_info function."""

    def test_file_entry(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create a test file
            test_file = os.path.join(tmpdir, 'test.txt')
            with open(test_file, 'w') as f:
                f.write('hello')

            name, entry_type, size, mtime = dir_brief.get_entry_info(tmpdir, 'test.txt')
            assert name == 'test.txt'
            assert entry_type == 'FILE'
            assert size == 5
            assert mtime > 0

    def test_directory_entry(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create a subdirectory
            subdir = os.path.join(tmpdir, 'subdir')
            os.mkdir(subdir)

            name, entry_type, size, mtime = dir_brief.get_entry_info(tmpdir, 'subdir')
            assert name == 'subdir'
            assert entry_type == 'DIR'
            assert size == 0  # Directories always show size 0
            assert mtime > 0


class TestListDirectory:
    """Tests for list_directory function."""

    def test_empty_directory(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            entries = dir_brief.list_directory(tmpdir)
            assert entries == []

    def test_directory_with_files(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create some test files
            with open(os.path.join(tmpdir, 'a.txt'), 'w') as f:
                f.write('aaa')
            with open(os.path.join(tmpdir, 'b.txt'), 'w') as f:
                f.write('bbbbb')

            entries = dir_brief.list_directory(tmpdir)
            assert len(entries) == 2
            # Sorted by name
            assert entries[0][0] == 'a.txt'
            assert entries[1][0] == 'b.txt'

    def test_directories_come_first(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create file first, then directory
            with open(os.path.join(tmpdir, 'a_file.txt'), 'w') as f:
                f.write('test')
            os.mkdir(os.path.join(tmpdir, 'z_dir'))

            entries = dir_brief.list_directory(tmpdir)
            assert len(entries) == 2
            # Directory comes first even though 'z' > 'a'
            assert entries[0][0] == 'z_dir'
            assert entries[0][1] == 'DIR'
            assert entries[1][0] == 'a_file.txt'
            assert entries[1][1] == 'FILE'


class TestCLI:
    """Integration tests for CLI behavior."""

    def test_nonexistent_path(self):
        result = subprocess.run(
            [sys.executable, 'tmp/dir_brief.py', '/nonexistent/path'],
            capture_output=True,
            text=True
        )
        assert result.returncode != 0
        assert 'Error' in result.stderr

    def test_file_instead_of_directory(self):
        with tempfile.NamedTemporaryFile(delete=False) as f:
            try:
                result = subprocess.run(
                    [sys.executable, 'tmp/dir_brief.py', f.name],
                    capture_output=True,
                    text=True
                )
                assert result.returncode != 0
                assert 'Not a directory' in result.stderr
            finally:
                os.unlink(f.name)

    def test_missing_argument(self):
        result = subprocess.run(
            [sys.executable, 'tmp/dir_brief.py'],
            capture_output=True,
            text=True
        )
        assert result.returncode != 0
        assert 'Usage' in result.stderr

    def test_empty_directory_output(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            result = subprocess.run(
                [sys.executable, 'tmp/dir_brief.py', tmpdir],
                capture_output=True,
                text=True
            )
            assert result.returncode == 0
            assert 'Summary' in result.stdout
            assert 'Total Count' in result.stdout
            assert '| 0' in result.stdout  # Total count is 0

    def test_normal_directory_output(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create test files
            with open(os.path.join(tmpdir, 'test.txt'), 'w') as f:
                f.write('test content')

            result = subprocess.run(
                [sys.executable, 'tmp/dir_brief.py', tmpdir],
                capture_output=True,
                text=True
            )
            assert result.returncode == 0
            assert 'test.txt' in result.stdout
            assert 'FILE' in result.stdout
            assert 'Summary' in result.stdout
            assert 'Max Size' in result.stdout
            assert 'Latest Update' in result.stdout


if __name__ == '__main__':
    import pytest
    pytest.main([__file__, '-v'])
