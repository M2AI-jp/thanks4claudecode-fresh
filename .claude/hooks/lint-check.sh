#!/bin/bash
# lint-check.sh - 静的解析チェック Hook
#
# 発火タイミング: PreToolUse:Bash (git commit 前)
# 目的: コミット前に Linter を実行し、問題があれば警告
#
# 入力: stdin から JSON（tool_name, tool_input）
# 出力: 警告メッセージ（問題がある場合）
# exit code: 0 = 通過、2 = ブロック（未使用）

set -euo pipefail

# stdin から入力を読み込む
INPUT=$(cat)

# ツール名を取得
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Bash ツールでない場合は無視
if [[ "$TOOL_NAME" != "Bash" ]]; then
    exit 0
fi

# コマンドを取得
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# git commit コマンドでない場合は無視
if [[ ! "$COMMAND" =~ ^git[[:space:]]+(commit|add) ]]; then
    exit 0
fi

# プロジェクトディレクトリを検出
# package.json があれば JavaScript/TypeScript プロジェクト
# pyproject.toml があれば Python プロジェクト
# .sh ファイルがあれば Shell スクリプト

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
echo "  🔍 静的解析チェック" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

LINT_ERRORS=0

# JavaScript/TypeScript プロジェクト
if [[ -f "package.json" ]]; then
    if command -v pnpm &> /dev/null && [[ -f "node_modules/.bin/eslint" ]]; then
        echo "  📦 ESLint チェック中..." >&2
        if ! pnpm lint --quiet 2>/dev/null; then
            echo "  ⚠️ ESLint: 問題が見つかりました" >&2
            echo "     → pnpm lint --fix で自動修正を試してください" >&2
            LINT_ERRORS=$((LINT_ERRORS + 1))
        else
            echo "  ✅ ESLint: PASS" >&2
        fi
    fi
fi

# Shell スクリプト（.claude/hooks/ 配下）
if [[ -d ".claude/hooks" ]]; then
    if command -v shellcheck &> /dev/null; then
        echo "  🐚 ShellCheck チェック中..." >&2
        SHELL_ERRORS=$(shellcheck -S warning .claude/hooks/*.sh 2>&1 | grep -c "^In " || true)
        if [[ "$SHELL_ERRORS" -gt 0 ]]; then
            echo "  ⚠️ ShellCheck: $SHELL_ERRORS 件の警告" >&2
            echo "     → shellcheck .claude/hooks/*.sh で詳細確認" >&2
            # ShellCheck は警告のみ、ブロックはしない
        else
            echo "  ✅ ShellCheck: PASS" >&2
        fi
    fi
fi

# Python プロジェクト
if [[ -f "pyproject.toml" ]]; then
    if command -v ruff &> /dev/null; then
        echo "  🐍 Ruff チェック中..." >&2
        if ! ruff check . --quiet 2>/dev/null; then
            echo "  ⚠️ Ruff: 問題が見つかりました" >&2
            echo "     → ruff check . --fix で自動修正を試してください" >&2
            LINT_ERRORS=$((LINT_ERRORS + 1))
        else
            echo "  ✅ Ruff: PASS" >&2
        fi
    fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

if [[ "$LINT_ERRORS" -gt 0 ]]; then
    echo "  ⚠️ 静的解析で問題が見つかりました" >&2
    echo "     コミットは続行できますが、修正を推奨します" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
fi

# 警告のみ、ブロックはしない（exit 0）
exit 0
