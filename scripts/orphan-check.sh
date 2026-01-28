#!/usr/bin/env bash
#
# orphan-check.sh - Detect orphan files in the repository
#
# An orphan file is one that is not referenced from anywhere:
# - Not referenced in any .md files
# - Not referenced in any .sh scripts
# - Not referenced in any .yaml/.yml or .json configuration files
# - Not imported/required by any code
#
# Usage: ./scripts/orphan-check.sh
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Colors for output (disabled if not a tty)
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  NC='\033[0m'
else
  RED=''
  NC=''
fi

# Build list of all files to check (excluding specific patterns)
get_candidate_files() {
  find . -type f \
    ! -path "./.git/*" \
    ! -path "./node_modules/*" \
    ! -path "./tmp/*" \
    ! -name ".DS_Store" \
    ! -name "*.log" \
    ! -path "./play/archive/*" \
    ! -path "./.claude/session-state/*" \
    ! -path "./.claude/logs/*" \
    | sed 's|^\./||' \
    | sort
}

# Check if a file is a root configuration file (should not be flagged)
is_root_config() {
  local file="$1"
  
  # Root-level dotfiles and common config files
  case "$file" in
    .gitignore|.gitattributes|.editorconfig|.eslintrc*|.prettierrc*|\
    .shellcheckrc|.env|.env.example|.mcp.json|README.md|\
    LICENSE|LICENSE.md|package.json|package-lock.json|tsconfig.json|\
    Makefile|Dockerfile|docker-compose.yml|.dockerignore)
      return 0
      ;;
  esac
  
  # Root level uppercase .md files are typically project docs
  if [[ "$file" =~ ^[A-Z][A-Z0-9_-]*\.md$ ]]; then
    return 0
  fi
  
  return 1
}

# Check if a file is a settings/schema file (inherently referenced by the system)
is_system_file() {
  local file="$1"
  
  case "$file" in
    .claude/settings.json|.claude/settings.local.json)
      return 0
      ;;
    .claude/protected-files.txt)
      return 0
      ;;
    # Schema files are referenced by validation tools
    .claude/schema/*.json|.claude/schema/*.sh)
      return 0
      ;;
    # .gitkeep files are placeholders
    */.gitkeep)
      return 0
      ;;
    # Hook entry point files
    .claude/hooks/*.sh)
      return 0
      ;;
    # Session init marker files
    .claude/.session-init/*)
      return 0
      ;;
  esac
  
  return 1
}

# Get all reference files (files that can contain references to other files)
get_reference_files() {
  find . -type f \( \
    -name "*.md" \
    -o -name "*.sh" \
    -o -name "*.yaml" \
    -o -name "*.yml" \
    -o -name "*.json" \
    -o -name "*.ts" \
    -o -name "*.js" \
    -o -name "*.py" \
    -o -name "*.txt" \
  \) \
    ! -path "./.git/*" \
    ! -path "./node_modules/*" \
    ! -path "./tmp/*" \
    2>/dev/null
}

# Build a cache of all references found in the codebase
build_reference_cache() {
  local cache_file
  cache_file=$(mktemp)
  
  # Extract potential file references from all source files
  # Look for patterns like:
  # - path/to/file.ext
  # - "path/to/file.ext"
  # - 'path/to/file.ext'
  # - ./path/to/file.ext
  # - source path/to/file.sh
  # - . path/to/file.sh
  
  get_reference_files | while read -r ref_file; do
    if [[ -f "$ref_file" ]]; then
      # Extract all potential file paths from the content
      # This regex is intentionally broad to catch various reference patterns
      grep -oE '(\.?\.?/)?[a-zA-Z0-9_.-]+(/[a-zA-Z0-9_.-]+)+\.[a-zA-Z0-9]+' "$ref_file" 2>/dev/null || true
      # Also extract bare filenames that might be referenced
      grep -oE '\b[a-zA-Z0-9_-]+\.(sh|md|yaml|yml|json|ts|js|py|txt)\b' "$ref_file" 2>/dev/null || true
    fi
  done | sort -u > "$cache_file"
  
  echo "$cache_file"
}

# Check if a file is referenced in the cache
is_referenced() {
  local file="$1"
  local cache_file="$2"
  
  local basename
  basename=$(basename "$file")
  
  # Check if the full path (with or without ./) is referenced
  if grep -qF "$file" "$cache_file" 2>/dev/null; then
    return 0
  fi
  
  # Check if path with ./ prefix is referenced
  if grep -qF "./$file" "$cache_file" 2>/dev/null; then
    return 0
  fi
  
  # Check if the basename alone is referenced
  if grep -qF "$basename" "$cache_file" 2>/dev/null; then
    return 0
  fi
  
  # For files in known locations, check if their containing directory is referenced
  # (e.g., skills, agents, events directories might be referenced as a whole)
  local dir
  dir=$(dirname "$file")
  if grep -qF "$dir" "$cache_file" 2>/dev/null; then
    return 0
  fi
  
  return 1
}

# Main logic
main() {
  local orphan_count=0
  local cache_file
  
  # Build reference cache
  cache_file=$(build_reference_cache)
  trap "rm -f '$cache_file'" EXIT
  
  # Check each candidate file
  while IFS= read -r file; do
    # Skip root config files
    if is_root_config "$file"; then
      continue
    fi
    
    # Skip system files
    if is_system_file "$file"; then
      continue
    fi
    
    # Check if the file is referenced anywhere
    if ! is_referenced "$file" "$cache_file"; then
      echo -e "${RED}ORPHAN:${NC} $file"
      ((orphan_count++)) || true
    fi
  done < <(get_candidate_files)
  
  echo ""
  echo "Total orphans: $orphan_count"
  
  if [[ $orphan_count -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
