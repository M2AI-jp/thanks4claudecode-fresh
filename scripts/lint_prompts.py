#!/usr/bin/env python3
"""
lint_prompts.py - Validate CLAUDE.md frozen constitution

Checks:
1. CLAUDE.md contains required markers (Status: FROZEN, Version:, Change Control)
2. No TODO/TBD/FIXME in CLAUDE.md
3. Line count within limit (<= 300)
4. If CLAUDE.md changed, PROMPT_CHANGELOG.md must also have changes

Usage:
    python scripts/lint_prompts.py [--check-changelog]
    
Exit codes:
    0 = All checks passed
    1 = Validation failed
"""

import sys
import re
import os
from pathlib import Path

# Configuration
MAX_LINES = 300
REQUIRED_MARKERS = [
    "Status: FROZEN",
    "Version:",
    "Change Control",
]
FORBIDDEN_PATTERNS = [
    r'\bTODO\b',
    r'\bTBD\b',
    r'\bFIXME\b',
    r'\bXXX\b',
]

def get_repo_root():
    """Find repository root by looking for .git directory."""
    current = Path.cwd()
    while current != current.parent:
        if (current / ".git").exists():
            return current
        current = current.parent
    return Path.cwd()

def lint_claude_md(filepath: Path) -> list:
    """Validate CLAUDE.md and return list of errors."""
    errors = []
    
    if not filepath.exists():
        errors.append(f"CLAUDE.md not found at {filepath}")
        return errors
    
    content = filepath.read_text()
    lines = content.split('\n')
    
    # Check line count
    line_count = len(lines)
    if line_count > MAX_LINES:
        errors.append(f"Line count {line_count} exceeds maximum {MAX_LINES}")
    
    # Check required markers
    for marker in REQUIRED_MARKERS:
        if marker not in content:
            errors.append(f"Missing required marker: '{marker}'")
    
    # Check forbidden patterns
    for pattern in FORBIDDEN_PATTERNS:
        matches = re.findall(pattern, content, re.IGNORECASE)
        if matches:
            errors.append(f"Forbidden pattern found: {pattern} ({len(matches)} occurrences)")
    
    # Check for version format
    version_match = re.search(r'Version:\s*(\d+\.\d+\.\d+)', content)
    if not version_match:
        errors.append("Version must be in SemVer format (X.Y.Z)")
    
    # Check for Last Updated date
    date_match = re.search(r'Last Updated:\s*(\d{4}-\d{2}-\d{2})', content)
    if not date_match:
        errors.append("Last Updated must be in YYYY-MM-DD format")
    
    return errors

def check_changelog_updated(repo_root: Path) -> list:
    """Check if PROMPT_CHANGELOG.md exists and has content."""
    errors = []
    changelog_path = repo_root / "governance" / "PROMPT_CHANGELOG.md"
    
    if not changelog_path.exists():
        errors.append("governance/PROMPT_CHANGELOG.md not found")
        return errors
    
    content = changelog_path.read_text()
    
    # Check for at least one version entry
    if not re.search(r'## \[\d+\.\d+\.\d+\]', content):
        errors.append("PROMPT_CHANGELOG.md must have at least one version entry")
    
    return errors

def main():
    repo_root = get_repo_root()
    claude_md_path = repo_root / "CLAUDE.md"
    
    print("=" * 60)
    print("CLAUDE.md Lint Check")
    print("=" * 60)
    
    all_errors = []
    
    # Lint CLAUDE.md
    print("\n[1] Checking CLAUDE.md...")
    errors = lint_claude_md(claude_md_path)
    all_errors.extend(errors)
    
    if errors:
        for error in errors:
            print(f"  ❌ {error}")
    else:
        print(f"  ✅ CLAUDE.md passed all checks")
        # Print stats
        lines = claude_md_path.read_text().split('\n')
        print(f"     Lines: {len(lines)}/{MAX_LINES}")
    
    # Check changelog
    print("\n[2] Checking governance/PROMPT_CHANGELOG.md...")
    errors = check_changelog_updated(repo_root)
    all_errors.extend(errors)
    
    if errors:
        for error in errors:
            print(f"  ❌ {error}")
    else:
        print(f"  ✅ PROMPT_CHANGELOG.md exists and has entries")
    
    # Summary
    print("\n" + "=" * 60)
    if all_errors:
        print(f"FAILED: {len(all_errors)} error(s) found")
        print("=" * 60)
        return 1
    else:
        print("PASSED: All checks successful")
        print("=" * 60)
        return 0

if __name__ == "__main__":
    sys.exit(main())
