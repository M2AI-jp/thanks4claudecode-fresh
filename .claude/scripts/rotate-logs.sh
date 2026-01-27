#!/usr/bin/env bash
#
# rotate-logs.sh - Log rotation and archival script
#
# Moves old logs to archive directory and optionally compresses them.
#
# Usage:
#   rotate-logs.sh [--days N] [--compress] [--dry-run]
#
# Options:
#   --days N      Number of days to keep (default: 14)
#   --compress    Compress archived logs with gzip
#   --dry-run     Show what would be done without doing it
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load common library if available
source "$REPO_ROOT/.claude/lib/common.sh" 2>/dev/null || {
    # Fallback logging
    log_info() { echo "[INFO] $1"; }
    log_warn() { echo "[WARN] $1" >&2; }
    log_error() { echo "[ERROR] $1" >&2; }
}

# Configuration
LOGS_DIR="$REPO_ROOT/.claude/logs"
ARCHIVE_DIR="$LOGS_DIR/archive"
DAYS_TO_KEEP=14
COMPRESS=false
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --days)
            DAYS_TO_KEEP="$2"
            shift 2
            ;;
        --compress)
            COMPRESS=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Ensure archive directory exists
ensure_archive_dir() {
    if [[ ! -d "$ARCHIVE_DIR" ]]; then
        if $DRY_RUN; then
            log_info "[DRY-RUN] Would create: $ARCHIVE_DIR"
        else
            mkdir -p "$ARCHIVE_DIR"
            touch "$ARCHIVE_DIR/.gitkeep"
            log_info "Created archive directory: $ARCHIVE_DIR"
        fi
    fi
}

# Move old session logs to archive
archive_session_logs() {
    log_info "Archiving session logs older than $DAYS_TO_KEEP days..."

    local count=0
    while IFS= read -r -d '' log_file; do
        local filename
        filename="$(basename "$log_file")"
        local dest="$ARCHIVE_DIR/$filename"

        if $DRY_RUN; then
            log_info "[DRY-RUN] Would move: $log_file -> $dest"
        else
            mv "$log_file" "$dest"
            log_info "Archived: $filename"
        fi
        ((count++))
    done < <(find "$LOGS_DIR" -maxdepth 1 -name 'session-*.log' -mtime "+$DAYS_TO_KEEP" -print0 2>/dev/null || true)

    log_info "Archived $count session log(s)"
}

# Archive old telemetry logs
archive_telemetry_logs() {
    local telemetry_dir="$LOGS_DIR/telemetry"

    if [[ ! -d "$telemetry_dir" ]]; then
        return 0
    fi

    log_info "Archiving telemetry logs older than $DAYS_TO_KEEP days..."

    local count=0
    while IFS= read -r -d '' log_file; do
        local filename
        filename="$(basename "$log_file")"
        local dest="$ARCHIVE_DIR/telemetry-$filename"

        if $DRY_RUN; then
            log_info "[DRY-RUN] Would move: $log_file -> $dest"
        else
            mv "$log_file" "$dest"
            log_info "Archived: telemetry-$filename"
        fi
        ((count++))
    done < <(find "$telemetry_dir" -name '*.jsonl' -mtime "+$DAYS_TO_KEEP" -print0 2>/dev/null || true)

    log_info "Archived $count telemetry log(s)"
}

# Compress archived logs
compress_archived_logs() {
    if ! $COMPRESS; then
        return 0
    fi

    log_info "Compressing archived logs..."

    local count=0
    while IFS= read -r -d '' log_file; do
        if $DRY_RUN; then
            log_info "[DRY-RUN] Would compress: $log_file"
        else
            gzip "$log_file"
            log_info "Compressed: $(basename "$log_file")"
        fi
        ((count++))
    done < <(find "$ARCHIVE_DIR" -type f \( -name '*.log' -o -name '*.jsonl' \) -print0 2>/dev/null || true)

    log_info "Compressed $count file(s)"
}

# Clean up very old archives (over 90 days)
cleanup_old_archives() {
    log_info "Cleaning up archives older than 90 days..."

    local count=0
    while IFS= read -r -d '' archive_file; do
        if $DRY_RUN; then
            log_info "[DRY-RUN] Would delete: $archive_file"
        else
            rm "$archive_file"
            log_info "Deleted: $(basename "$archive_file")"
        fi
        ((count++))
    done < <(find "$ARCHIVE_DIR" -type f -mtime +90 -print0 2>/dev/null || true)

    log_info "Deleted $count old archive(s)"
}

# Print summary
print_summary() {
    echo ""
    echo "=== Log Rotation Summary ==="
    echo "  Logs directory: $LOGS_DIR"
    echo "  Archive directory: $ARCHIVE_DIR"
    echo "  Days to keep: $DAYS_TO_KEEP"
    echo "  Compress: $COMPRESS"
    echo "  Dry run: $DRY_RUN"

    if [[ -d "$LOGS_DIR" ]]; then
        local active_count
        active_count="$(find "$LOGS_DIR" -maxdepth 1 -name '*.log' -type f 2>/dev/null | wc -l | tr -d ' ')"
        echo "  Active logs: $active_count"
    fi

    if [[ -d "$ARCHIVE_DIR" ]]; then
        local archive_count
        archive_count="$(find "$ARCHIVE_DIR" -type f -not -name '.gitkeep' 2>/dev/null | wc -l | tr -d ' ')"
        echo "  Archived logs: $archive_count"
    fi
}

# Main
main() {
    log_info "Starting log rotation..."

    ensure_archive_dir
    archive_session_logs
    archive_telemetry_logs
    compress_archived_logs
    cleanup_old_archives
    print_summary

    log_info "Log rotation complete"
}

main "$@"
