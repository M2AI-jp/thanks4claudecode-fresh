#!/bin/bash
# changelog-checker.sh - Claude Code CHANGELOG の自動監視
#
# 設計方針:
#   - SessionStart で呼び出される
#   - 24時間キャッシュで API 負荷を軽減
#   - 新バージョン検出時に通知
#
# キャッシュ場所:
#   - .claude/cache/changelog-latest.md: CHANGELOG 本文
#   - .claude/cache/changelog-meta.json: メタデータ（バージョン、タイムスタンプ）

set -e

# === 設定 ===
CACHE_DIR=".claude/cache"
META_FILE="$CACHE_DIR/changelog-meta.json"
CHANGELOG_FILE="$CACHE_DIR/changelog-latest.md"
SOURCE_URL="https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md"
CACHE_TTL=86400  # 24時間（秒）

# === キャッシュディレクトリ確認 ===
if [ ! -d "$CACHE_DIR" ]; then
    mkdir -p "$CACHE_DIR"
fi

# === メタデータ読み込み ===
if [ -f "$META_FILE" ]; then
    CACHED_AT=$(jq -r '.cached_at // ""' "$META_FILE" 2>/dev/null || echo "")
    CURRENT_VERSION=$(jq -r '.current_version // ""' "$META_FILE" 2>/dev/null || echo "")
else
    CACHED_AT=""
    CURRENT_VERSION=""
fi

# === キャッシュ有効期限チェック ===
check_cache_age() {
    if [ -z "$CACHED_AT" ]; then
        return 1  # キャッシュなし
    fi

    # macOS と Linux の両方に対応
    if date -j >/dev/null 2>&1; then
        # macOS
        CACHED_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${CACHED_AT%+*}" "+%s" 2>/dev/null || echo "0")
    else
        # Linux
        CACHED_EPOCH=$(date -d "${CACHED_AT}" "+%s" 2>/dev/null || echo "0")
    fi

    NOW_EPOCH=$(date "+%s")
    cache_age=$((NOW_EPOCH - CACHED_EPOCH))

    if [ "$cache_age" -lt "$CACHE_TTL" ]; then
        return 0  # キャッシュ有効
    else
        return 1  # キャッシュ期限切れ
    fi
}

# === CHANGELOG 取得（curl が使える環境のみ） ===
fetch_changelog() {
    if ! command -v curl >/dev/null 2>&1; then
        return 1
    fi

    # 取得試行（タイムアウト 5秒）
    if curl -sf --max-time 5 "$SOURCE_URL" -o "$CHANGELOG_FILE.tmp" 2>/dev/null; then
        mv "$CHANGELOG_FILE.tmp" "$CHANGELOG_FILE"
        return 0
    else
        rm -f "$CHANGELOG_FILE.tmp"
        return 1
    fi
}

# === バージョン抽出 ===
extract_version() {
    if [ ! -f "$CHANGELOG_FILE" ]; then
        echo ""
        return
    fi

    # "## 2.0.XX" 形式のバージョンを抽出
    grep -oE "^## [0-9]+\.[0-9]+\.[0-9]+" "$CHANGELOG_FILE" 2>/dev/null | head -1 | sed 's/## //' || echo ""
}

# === メタデータ更新 ===
update_meta() {
    local new_version="$1"
    local timestamp=$(date -Iseconds 2>/dev/null || date "+%Y-%m-%dT%H:%M:%S+09:00")

    cat > "$META_FILE" << EOF
{
  "cached_at": "$timestamp",
  "current_version": "$CURRENT_VERSION",
  "latest_version": "$new_version",
  "source_url": "$SOURCE_URL",
  "cache_ttl_seconds": $CACHE_TTL,
  "last_check_result": "$([ "$CURRENT_VERSION" = "$new_version" ] && echo "up_to_date" || echo "new_version_available")"
}
EOF
}

# === バージョン比較 ===
compare_versions() {
    local old="$1"
    local new="$2"

    if [ -z "$old" ] || [ -z "$new" ]; then
        return 1  # 比較不可
    fi

    if [ "$old" != "$new" ]; then
        return 0  # 新バージョンあり
    else
        return 1  # 同じ
    fi
}

# === メイン処理 ===
main() {
    # キャッシュ有効なら何もしない
    if check_cache_age; then
        # サイレント終了（24時間以内）
        exit 0
    fi

    # CHANGELOG 取得
    if ! fetch_changelog; then
        # 取得失敗（ネットワークエラー等）→ サイレント終了
        exit 0
    fi

    # バージョン抽出
    LATEST_VERSION=$(extract_version)

    if [ -z "$LATEST_VERSION" ]; then
        # バージョン抽出失敗 → サイレント終了
        exit 0
    fi

    # メタデータ更新
    update_meta "$LATEST_VERSION"

    # 新バージョン検出時の通知
    if compare_versions "$CURRENT_VERSION" "$LATEST_VERSION"; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  🆕 Claude Code 新バージョン検出"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  現在: ${CURRENT_VERSION:-unknown}"
        echo "  最新: $LATEST_VERSION"
        echo ""
        echo "  詳細: /changelog コマンドで確認"
        echo ""

        # current_version を更新（次回は通知しない）
        CURRENT_VERSION="$LATEST_VERSION"
        update_meta "$LATEST_VERSION"
    fi
}

main "$@"
