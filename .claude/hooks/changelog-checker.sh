#!/bin/bash
# changelog-checker.sh - Claude Code CHANGELOG の自動監視 + サジェスト機能
#
# 設計方針:
#   - SessionStart で呼び出される
#   - 24時間キャッシュで API 負荷を軽減
#   - 新バージョン検出時に通知
#   - repo-profile.json とマッチングしてサジェストを生成
#
# キャッシュ場所:
#   - .claude/cache/changelog-latest.md: CHANGELOG 本文
#   - .claude/cache/changelog-meta.json: メタデータ（バージョン、タイムスタンプ）
#   - .claude/cache/repo-profile.json: リポジトリプロファイル

set -e

# === 設定 ===
CACHE_DIR=".claude/cache"
META_FILE="$CACHE_DIR/changelog-meta.json"
CHANGELOG_FILE="$CACHE_DIR/changelog-latest.md"
PROFILE_FILE="$CACHE_DIR/repo-profile.json"
SOURCE_URL="https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md"
CACHE_TTL=86400  # 24時間（秒）
SUGGESTION_MESSAGE=""

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

# === キーワード抽出とマッチング ===
keyword_extraction() {
    if [ ! -f "$CHANGELOG_FILE" ] || [ ! -f "$PROFILE_FILE" ]; then
        return 1
    fi

    local high_matches=""
    local medium_matches=""
    local low_matches=""

    # repo-profile.json から優先度キーワードを読み取り
    # High priority keywords
    local high_keywords=$(jq -r '.priority_keywords.high[].keyword' "$PROFILE_FILE" 2>/dev/null || echo "")
    for kw in $high_keywords; do
        if grep -qi "$kw" "$CHANGELOG_FILE" 2>/dev/null; then
            local reason=$(jq -r ".priority_keywords.high[] | select(.keyword==\"$kw\") | .reason" "$PROFILE_FILE" 2>/dev/null || echo "")
            high_matches="$high_matches\n    [HIGH] $kw: $reason"
        fi
    done

    # Medium priority keywords
    local medium_keywords=$(jq -r '.priority_keywords.medium[].keyword' "$PROFILE_FILE" 2>/dev/null || echo "")
    for kw in $medium_keywords; do
        if grep -qi "$kw" "$CHANGELOG_FILE" 2>/dev/null; then
            local reason=$(jq -r ".priority_keywords.medium[] | select(.keyword==\"$kw\") | .reason" "$PROFILE_FILE" 2>/dev/null || echo "")
            medium_matches="$medium_matches\n    [MEDIUM] $kw: $reason"
        fi
    done

    # Low priority keywords
    local low_keywords=$(jq -r '.priority_keywords.low[].keyword' "$PROFILE_FILE" 2>/dev/null || echo "")
    for kw in $low_keywords; do
        if grep -qi "$kw" "$CHANGELOG_FILE" 2>/dev/null; then
            local reason=$(jq -r ".priority_keywords.low[] | select(.keyword==\"$kw\") | .reason" "$PROFILE_FILE" 2>/dev/null || echo "")
            low_matches="$low_matches\n    [LOW] $kw: $reason"
        fi
    done

    # サジェストメッセージをフォーマット
    format_suggestions "$high_matches" "$medium_matches" "$low_matches"
}

# === サジェストメッセージのフォーマット ===
format_suggestions() {
    local high="$1"
    local medium="$2"
    local low="$3"

    if [ -z "$high" ] && [ -z "$medium" ] && [ -z "$low" ]; then
        SUGGESTION_MESSAGE=""
        return
    fi

    SUGGESTION_MESSAGE="  📌 Suggested features for this repo:"

    if [ -n "$high" ]; then
        SUGGESTION_MESSAGE="$SUGGESTION_MESSAGE\n  ┌─────────────────────────────────────┐"
        SUGGESTION_MESSAGE="$SUGGESTION_MESSAGE\n  │ ⭐ High Priority                    │"
        SUGGESTION_MESSAGE="$SUGGESTION_MESSAGE$high"
        SUGGESTION_MESSAGE="$SUGGESTION_MESSAGE\n  └─────────────────────────────────────┘"
    fi

    if [ -n "$medium" ]; then
        SUGGESTION_MESSAGE="$SUGGESTION_MESSAGE\n  ┌─────────────────────────────────────┐"
        SUGGESTION_MESSAGE="$SUGGESTION_MESSAGE\n  │ 🔶 Medium Priority                  │"
        SUGGESTION_MESSAGE="$SUGGESTION_MESSAGE$medium"
        SUGGESTION_MESSAGE="$SUGGESTION_MESSAGE\n  └─────────────────────────────────────┘"
    fi

    SUGGESTION_MESSAGE="$SUGGESTION_MESSAGE\n"
    SUGGESTION_MESSAGE="$SUGGESTION_MESSAGE\n  詳細: /changelog --suggest"
}

# === 出力フォーマット ===
output_notification() {
    local version_old="$1"
    local version_new="$2"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🆕 Claude Code 新バージョン検出"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  現在: ${version_old:-unknown} → 最新: $version_new"
    echo ""

    # サジェストがあれば出力
    if [ -n "$SUGGESTION_MESSAGE" ]; then
        echo -e "$SUGGESTION_MESSAGE"
    fi

    echo "  詳細: /changelog コマンドで確認"
    echo ""
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
        # キーワード抽出とサジェスト生成
        keyword_extraction

        # 通知出力
        output_notification "$CURRENT_VERSION" "$LATEST_VERSION"

        # current_version を更新（次回は通知しない）
        CURRENT_VERSION="$LATEST_VERSION"
        update_meta "$LATEST_VERSION"
    fi
}

main "$@"
