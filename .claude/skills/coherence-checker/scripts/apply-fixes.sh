#!/usr/bin/env bash
# apply-fixes.sh: Apply auto_fix suggestions to ARCHITECTURE.md
# Usage: bash .claude/skills/coherence-checker/scripts/apply-fixes.sh
#
# This script:
# 1. Runs check.sh to get current issues
# 2. Extracts auto_fix suggestions (severity: low only)
# 3. Shows proposed changes and asks for user confirmation
# 4. Creates backup of ARCHITECTURE.md
# 5. Applies approved fixes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
CHECK_SCRIPT="$SCRIPT_DIR/check.sh"
ARCHITECTURE_FILE="$REPO_ROOT/docs/ARCHITECTURE.md"
BACKUP_DIR="$REPO_ROOT/tmp"

# Colors for output (disabled if not interactive)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
if [[ ! -f "$CHECK_SCRIPT" ]]; then
    echo_error "check.sh not found at $CHECK_SCRIPT"
    exit 1
fi

if [[ ! -f "$ARCHITECTURE_FILE" ]]; then
    echo_error "ARCHITECTURE.md not found at $ARCHITECTURE_FILE"
    exit 1
fi

# Run check.sh and capture output
echo_info "Running coherence check..."
CHECK_OUTPUT=$(bash "$CHECK_SCRIPT" 2>/dev/null)

# Parse summary
MISSING_COUNT=$(echo "$CHECK_OUTPUT" | grep -E '^\s+missing:' | head -1 | sed 's/.*: *//')
MISSING_COUNT=${MISSING_COUNT:-0}

if [[ "$MISSING_COUNT" -eq 0 ]]; then
    echo_info "No missing documentation found. Nothing to fix."
    exit 0
fi

echo_info "Found $MISSING_COUNT items with missing documentation (severity: low)"
echo ""

# Extract auto_fix sections
# Format in check.sh output:
#     - severity: low
#       type: missing
#       target: ".claude/hooks/session-start.sh"
#       auto_fix:
#         action: "add_to_architecture"
#         section: "Section 1. SessionStart"
#         content: |
#           ### session-start.sh
#           ...

# Parse recommendations and extract auto_fix content
echo "=========================================="
echo "Proposed fixes for ARCHITECTURE.md:"
echo "=========================================="
echo ""

# Extract targets and their auto_fix content
declare -a TARGETS=()
declare -a SECTIONS=()
declare -a CONTENTS=()
FIX_INDEX=0

# Parse auto_fix entries from check.sh output
# The format is:
#     - severity: low
#       type: missing
#       target: "path"
#       auto_fix:
#         action: "add_to_architecture"
#         section: "Section X"
#         content: |
#           ...content lines with 10 spaces indent...

# Get all low severity targets
while IFS= read -r target; do
    [[ -z "$target" ]] && continue

    # Extract section using grep
    section=$(echo "$CHECK_OUTPUT" | awk -v target="$target" '
        /target: "/ && index($0, target) { found=1 }
        found && /section:/ { gsub(/.*section: *"/, ""); gsub(/".*/, ""); print; exit }
    ')

    # Extract content using sed - get lines between "content: |" and next "- severity:" or empty line
    content=$(echo "$CHECK_OUTPUT" | awk -v target="$target" '
        /target: "/ && index($0, target) { found=1 }
        found && /content: \|/ { capture=1; next }
        capture && /^          / { sub(/^          /, ""); print }
        capture && /^    - severity:/ { exit }
        capture && /^  [a-z]/ { exit }
    ')

    if [[ -n "$section" ]] && [[ -n "$content" ]]; then
        TARGETS+=("$target")
        SECTIONS+=("$section")
        CONTENTS+=("$content")

        echo "Fix #$((FIX_INDEX + 1)): $target"
        echo "  Section: $section"
        echo "  Content to add:"
        echo "$content" | sed 's/^/    /'
        echo ""
        ((FIX_INDEX++))
    fi
done < <(echo "$CHECK_OUTPUT" | grep -A2 'severity: low' | grep 'target:' | sed 's/.*target: *"\([^"]*\)".*/\1/')

if [[ ${#TARGETS[@]} -eq 0 ]]; then
    echo_warn "No auto_fix content could be extracted."
    echo "Run 'bash .claude/skills/coherence-checker/scripts/check.sh' for details."
    exit 0
fi

echo "=========================================="
echo ""

# Ask for confirmation
echo_warn "This will modify ARCHITECTURE.md"
echo ""

# Check if running interactively
if [[ -t 0 ]]; then
    read -r -p "Apply these fixes? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            ;;
        *)
            echo_info "Aborted by user."
            exit 0
            ;;
    esac
else
    # Non-interactive mode - output instructions for Claude
    echo "=========================================="
    echo "NON-INTERACTIVE MODE DETECTED"
    echo "=========================================="
    echo ""
    echo "To apply these fixes, Claude should:"
    echo "1. Create a backup: cp docs/ARCHITECTURE.md tmp/ARCHITECTURE.md.backup.\$(date +%Y%m%d%H%M%S)"
    echo "2. Add the above content to the appropriate sections in ARCHITECTURE.md"
    echo "3. Verify the changes are correct"
    echo ""
    echo "Or run this script interactively: bash .claude/skills/coherence-checker/scripts/apply-fixes.sh"
    exit 0
fi

# Create backup
echo_info "Creating backup..."
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/ARCHITECTURE.md.backup.$(date +%Y%m%d%H%M%S)"
cp "$ARCHITECTURE_FILE" "$BACKUP_FILE"
echo_info "Backup created at: $BACKUP_FILE"

# Apply fixes
echo_info "Applying fixes..."

for i in "${!TARGETS[@]}"; do
    target="${TARGETS[$i]}"
    section="${SECTIONS[$i]}"
    content="${CONTENTS[$i]}"

    echo_info "Adding documentation for: $target"

    # Append content to ARCHITECTURE.md
    # For now, append to the end of the file with a note
    {
        echo ""
        echo "<!-- Auto-generated by apply-fixes.sh for: $target -->"
        echo "<!-- Suggested section: $section -->"
        echo "$content"
    } >> "$ARCHITECTURE_FILE"
done

echo ""
echo_info "Fixes applied successfully!"
echo_info "Backup available at: $BACKUP_FILE"
echo ""
echo "Please review the changes and move content to appropriate sections if needed."
echo "Run 'git diff docs/ARCHITECTURE.md' to see changes."
