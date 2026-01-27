# Bash Protection Issues

> **Bash 保護の誤検出パターンと修正提案**
>
> AUTO_HARD_BLOCK_PATTERNS による過剰保護の問題を文書化する。

---

## 概要

| 項目 | 説明 |
|------|------|
| 問題 | 読み取り専用コマンド（ls, cat 等）が HARD_BLOCK される |
| 原因 | AUTO_HARD_BLOCK_PATTERNS がパス名のみでマッチ |
| 影響 | 検証作業が Bash で実行できない |

---

## 1. 発生した誤検出パターン

### 1.1 ls コマンド

```bash
# 入力
ls .claude/skills/*/SKILL.md 2>/dev/null | wc -l

# 結果
========================================
  [HARD_BLOCK] Bash による自動保護ファイルへの書き込み
========================================

  コマンド: ls .claude/skills/*/SKILL.md
  保護パターン: .claude/settings.json

  AUTO_HARD_BLOCK_PATTERNS で保護されたファイルは
  Bash からも保護されています。

========================================
```

**問題**: ls は読み取り専用コマンドであり、ブロックすべきでない

### 1.2 basename コマンド

```bash
# 入力
ls .claude/agents/*.md | xargs -I{} basename {}

# 結果
[HARD_BLOCK]
```

**問題**: basename は読み取り専用コマンドであり、ブロックすべきでない

### 1.3 diff/comm コマンド

```bash
# 入力
comm -3 <(ls .claude/agents/*.md | sort) <(find .claude/skills -path '*/agents/*.md' | sort)

# 結果
[HARD_BLOCK]
```

**問題**: diff/comm は比較コマンドであり、ブロックすべきでない

---

## 2. 根本原因分析

### 2.1 現在の保護ロジック

`.claude/lib/contract.sh` の AUTO_HARD_BLOCK_PATTERNS:

```bash
AUTO_HARD_BLOCK_PATTERNS=(
  ".claude/settings.json"
  ".claude/hooks/*"
  ".claude/events/*"
  ".claude/lib/*"
  ".claude/agents/*"
  ".claude/skills/*/agents/*"
  ".claude/skills/*/guards/*"
  ".claude/skills/*/handlers/*"
  ".claude/skills/*/workflow/*"
  ".claude/skills/*/checkers/*"
  ".claude/frameworks/*"
)
```

### 2.2 問題点

1. **パス名のみでマッチ**: コマンドの種類（読み取り/書き込み）を区別しない
2. **保護が広すぎる**: `.claude/` 配下の全操作をブロック
3. **回避手段がない**: Glob/Grep では対応できないケースがある

---

## 3. 修正提案

### 3.1 コマンド種別による分岐

```bash
# 読み取り専用コマンドのリスト
READONLY_COMMANDS=(
  "ls" "cat" "head" "tail" "grep" "find" "wc"
  "diff" "comm" "sort" "uniq" "basename" "dirname"
  "stat" "file" "test" "echo"
)

# 書き込みコマンドのリスト（ブロック対象）
WRITE_COMMANDS=(
  "rm" "mv" "cp" "mkdir" "rmdir" "touch"
  "chmod" "chown" "sed" "awk" ">" ">>" "tee"
)

# 判定ロジック
is_write_command() {
  local cmd="$1"
  for write_cmd in "${WRITE_COMMANDS[@]}"; do
    if [[ "$cmd" == *"$write_cmd"* ]]; then
      return 0  # 書き込みコマンド
    fi
  done
  return 1  # 読み取り専用
}
```

### 3.2 実装場所

- `.claude/skills/access-control/guards/bash-check.sh`
- `.claude/lib/contract.sh`

### 3.3 期待される動作

| コマンド | 現在 | 修正後 |
|----------|------|--------|
| `ls .claude/` | HARD_BLOCK | PASS |
| `cat .claude/settings.json` | HARD_BLOCK | PASS |
| `rm .claude/settings.json` | HARD_BLOCK | HARD_BLOCK |
| `echo > .claude/settings.json` | HARD_BLOCK | HARD_BLOCK |
| `sed -i 's/x/y/' .claude/lib/*.sh` | HARD_BLOCK | HARD_BLOCK |

---

## 4. テストケース

### 4.1 誤検出ゼロ確認

```bash
# 読み取りコマンドが通過することを確認
echo '{"tool_input":{"command":"ls -la .claude/"}}' | \
  bash .claude/hooks/pre-tool.sh 2>&1 | \
  grep -c 'HARD_BLOCK' || echo 0
# 期待値: 0

echo '{"tool_input":{"command":"cat CLAUDE.md"}}' | \
  bash .claude/hooks/pre-tool.sh 2>&1 | \
  grep -c 'HARD_BLOCK' || echo 0
# 期待値: 0
```

### 4.2 正当ブロック確認

```bash
# 書き込みコマンドがブロックされることを確認
echo '{"tool_input":{"command":"rm CLAUDE.md"}}' | \
  bash .claude/hooks/pre-tool.sh 2>&1 | \
  grep -c 'BLOCK'
# 期待値: >= 1

echo '{"tool_input":{"command":"echo test > .claude/settings.json"}}' | \
  bash .claude/hooks/pre-tool.sh 2>&1 | \
  grep -c 'BLOCK'
# 期待値: >= 1
```

---

## 5. 優先度

| 優先度 | 理由 |
|--------|------|
| **High** | 検証作業が Bash で実行できないため、開発効率に重大な影響 |

---

## 6. 対応状況

| 状態 | 説明 |
|------|------|
| **未修正** | Phase 4 (p4.1) で対応予定 |

---

## 更新履歴

| 日付 | 変更内容 |
|------|----------|
| 2026-01-28 | 初版作成（repository-completion playbook） |
