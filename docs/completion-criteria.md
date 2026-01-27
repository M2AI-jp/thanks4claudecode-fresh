# COMPLETION_CRITERIA

> **リポジトリ完成状態の定義**
>
> このドキュメントは、リポジトリが「完成」と判定されるための必要十分条件を定義する。
> 報酬詐欺耐性を担保するため、全ての条件は自動検証可能でなければならない。

---

## 概要

| 項目 | 説明 |
|------|------|
| 対象 | thanks4claudecode-v2 リポジトリ |
| 目的 | Claude Code の Hook → Skill → SubAgent アーキテクチャの完成 |
| 判定基準 | 7 項目全てが PASS であること |

---

## 完成条件（7項目）

### 1. Skill 構造の完全性

**定義**: 全 13 種の Skill が SKILL.md を持ち、配下モジュールが整合していること

```bash
# 検証コマンド
find .claude/skills -maxdepth 2 -name 'SKILL.md' | wc -l
# 期待値: 13
```

**詳細要件**:
- 各 Skill ディレクトリに SKILL.md が存在
- SKILL.md に Purpose, When to Use, Related Files セクションが存在
- 配下モジュール（agents/, guards/, handlers/, workflow/, checkers/）が SKILL.md に記載

---

### 2. SubAgent の整合性

**定義**: .claude/agents/ と skills/*/agents/ の SubAgent が一致していること

```bash
# 検証コマンド
diff <(basename -a .claude/agents/*.md | sort) <(find .claude/skills -path '*/agents/*.md' -exec basename {} \; | sort) | wc -l
# 期待値: 0
```

**詳細要件**:
- .claude/agents/: 7 ファイル（シンボリックリンク）
- skills/*/agents/: 7 ファイル（実体）
- 全 SubAgent: pm, critic, reviewer, prompt-analyzer, executor-resolver, codex-delegate, coderabbit-delegate

---

### 3. Hook → Skill → SubAgent チェーンの動作

**定義**: 全 6 種の Hook が正しく Skill/SubAgent を呼び出すこと

```bash
# 検証コマンド（Hook 存在確認）
find .claude/hooks -name '*.sh' -type f | wc -l
# 期待値: >= 5
```

**詳細要件**:
- SessionStart: session.sh → start.sh
- UserPromptSubmit: prompt.sh → playbook-init Skill
- PreToolUse: pre-tool.sh → guards/*.sh
- PostToolUse: post-tool.sh → archive-playbook.sh
- SubagentStop: subagent-stop.sh → archive-playbook.sh
- Stop: (ブロック用)

---

### 4. 報酬詐欺耐性

**定義**: critic/reviewer を経由しない done 宣言が構造的にブロックされること

```bash
# 検証コマンド（テストスクリプト）
bash scripts/reward-fraud-test.sh
# 期待値: exit 0
```

**詳細要件**:
- subtask-guard.sh が progress.json の validated_by: 'critic' を検証
- critic SubAgent なしで status: done への変更がブロックされる
- reviewer 検証なしで playbook.reviewed: true への変更がブロックされる

---

### 5. MECE 状態（重複・欠落なし）

**定義**: モジュール間の重複・欠落がないこと

```bash
# 検証コマンド（孤立ファイルなし）
find .claude -name '*.md' -o -name '*.sh' | wc -l
# 孤立ファイル検出は file-inventory.md で管理
```

**詳細要件**:
- 全ファイルが state.md または playbook から参照可能
- 同一機能の重複実装がない
- docs/file-inventory.md で孤立ファイルが 0 件

---

### 6. Bash 保護の適正動作

**定義**: 読み取り専用コマンド（ls, cat, grep 等）がブロックされないこと

```bash
# 検証コマンド（誤検出ゼロ）
echo '{"tool_input":{"command":"ls -la .claude/"}}' | bash .claude/hooks/pre-tool.sh 2>&1 | grep -c 'HARD_BLOCK' || echo 0
# 期待値: 0

# 検証コマンド（正当ブロック）
echo '{"tool_input":{"command":"rm CLAUDE.md"}}' | bash .claude/hooks/pre-tool.sh 2>&1 | grep -c 'BLOCK'
# 期待値: >= 1
```

**詳細要件**:
- AUTO_HARD_BLOCK_PATTERNS が破壊的コマンドのみをブロック
- 読み取り専用コマンドは通過
- 保護ファイルへの書き込みコマンドはブロック

---

### 7. ドキュメント完全性

**定義**: 全アーキテクチャが文書化されていること

```bash
# 検証コマンド
test -f CLAUDE.md && test -f state.md && test -f docs/ARCHITECTURE.md && echo 'PASS'
# 期待値: PASS
```

**詳細要件**:
- CLAUDE.md: Core Contract 定義
- state.md: 現在状態（SSOT）
- docs/ARCHITECTURE.md: Event Unit 設計
- docs/core-feature-reclassification.md: Hook Unit マッピング
- docs/repository-map.yaml: ファイル構造（自動生成）

---

## 判定マトリックス

| # | 条件 | 検証方法 | 期待値 |
|---|------|----------|--------|
| 1 | Skill 構造 | find + wc | 13 |
| 2 | SubAgent 整合 | diff | 0 |
| 3 | Hook チェーン | find | >= 5 |
| 4 | 報酬詐欺耐性 | test script | exit 0 |
| 5 | MECE 状態 | inventory | 孤立 0 |
| 6 | Bash 保護 | echo + hook | 誤検出 0 |
| 7 | ドキュメント | test -f | PASS |

---

## 検証スクリプト

完全な検証は以下のスクリプトで実行可能:

```bash
# 全条件を一括検証
bash scripts/completion-check.sh
```

---

## 更新履歴

| 日付 | 変更内容 |
|------|----------|
| 2026-01-28 | 初版作成（repository-completion playbook） |
