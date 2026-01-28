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

### 4. 報酬詐欺耐性（5層防御システム）

**定義**: critic/reviewer を経由しない done 宣言が構造的にブロックされること

```bash
# 検証コマンド（各guardがexit 2を返すか確認）
for guard in critic-guard subtask-guard phase-status-guard scope-guard completion-check; do
  test -f ".claude/skills/reward-guard/guards/${guard}.sh" && echo "PASS: $guard exists"
done
# 期待値: 5件のPASS
```

**5層防御システム**:

| Layer | Guard | 役割 | ブロック条件 |
|-------|-------|------|-------------|
| 1 | pre-tool.sh | critic 直接呼び出しブロック | Task(subagent_type='critic') を直接呼び出し |
| 2 | /crit Skill | Codex 経由の独立検証 | Claude 自身による done 判定 |
| 3 | critic-guard.sh | self_complete チェック | state.md の self_complete: true なしで status: done |
| 4 | subtask-guard.sh | validated_by チェック | validated_by: 'critic' なしで subtask done |
| 5 | completion-check.sh | Stop 時チェック | 未完了 subtask がある状態で応答終了 |

**追加 Guard**:

| Guard | 役割 | 動作 |
|-------|------|------|
| phase-status-guard.sh | Phase 完了チェック | 全 subtask 未完了で Phase done をブロック |
| scope-guard.sh | スコープ変更検出 | done_when/done_criteria の変更を警告/ブロック |
| progress-reminder.sh | リマインダー | progress.json 更新を促す（非ブロック） |
| coherence.sh | 整合性チェック | state.md と playbook の整合性を検証 |

**検証コマンド**:
```bash
# critic-guard.sh が exit 2 を返すか
echo '{"tool_input":{"file_path":"state.md","new_string":"status: done"}}' | \
  bash .claude/skills/reward-guard/guards/critic-guard.sh 2>&1; echo "exit: $?"
# 期待値: exit: 2

# subtask-guard.sh が validated_by なしでブロックするか
# (テスト用の一時ファイルで検証)
```

**詳細要件**:
- pre-tool.sh が Task(subagent_type='critic') の直接呼び出しをブロック
- /crit Skill 経由でのみ critic を呼び出し可能（Codex 経由）
- subtask-guard.sh が progress.json の validated_by: 'critic' を検証
- critic SubAgent なしで status: done への変更がブロックされる
- reviewer 検証なしで playbook.reviewed: true への変更がブロックされる
- completion-check.sh が未完了 subtask を検出して Stop をブロック

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
