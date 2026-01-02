# RUNBOOK.md

> **Procedures, tools, and examples for working in this repository.**
> This file CAN be updated without Change Control (unlike CLAUDE.md).

---

## Where to Put What

| Content Type | Location | Can Change? |
|--------------|----------|-------------|
| Immutable principles | CLAUDE.md | No (frozen) |
| Procedures, tools, examples | RUNBOOK.md (this file) | Yes |
| Current state | state.md | Yes (auto-updated) |
| Task details | plan/playbook-*.md | Yes |

---

## Session Start Checklist

When starting a new session:

1. **Read state.md** - Understand active playbook and task
2. **Check branch** - `git branch --show-current`
3. **Check status** - `git status -sb`
4. **Read active playbook** - If `playbook.active` is set in state.md

```bash
# Quick start commands
cat state.md
git status -sb
```

---

## Task Lifecycle

### 1. Starting a New Task

```yaml
steps:
  1. Create branch: git checkout -b {type}/{description}
  2. Create playbook
  3. Update state.md playbook.active
  4. Begin work
```

### 2. During Task

```yaml
checkpoints:
  - Commit frequently (atomic commits)
  - Mark subtasks as done: `- [ ]` → `- [x]`
  - Update playbook status
```

### 3. Completing a Task

```yaml
steps:
  1. Self-verify against acceptance criteria
  2. Commit final changes
  3. Update state.md
  4. Create PR if on feature branch
```

---

## TodoWrite と Playbook の関係

**重要**: TodoWrite と playbook のチェックボックスは別のシステムです。両方を正しく更新する必要があります。

### 2つのシステムの役割

| システム | 役割 | 永続性 |
|---------|------|--------|
| TodoWrite | LLM の作業進捗追跡 | セッション内のみ |
| Playbook チェックボックス | **公式な完了記録** | 永続（ファイル） |

### subtask 完了時の必須フロー

```yaml
subtask 完了チェックリスト:
  1. 作業を完了する
  2. Skill(skill='crit') または /crit で検証を実行
  3. validations (3点検証) を記入:
     - technical: "PASS - (技術的な検証結果)"
     - consistency: "PASS - (整合性の検証結果)"
     - completeness: "PASS - (完全性の検証結果)"
  4. チェックボックスを更新: `- [ ]` → `- [x]`
  5. validated タイムスタンプを追加
  6. TodoWrite で該当タスクを completed に更新
```

### 報酬詐欺防止ルール

```yaml
禁止行為:
  - TodoWrite だけ更新して playbook チェックボックスを更新しない
  - validations を記入せずにチェックボックスを [x] にする
  - critic 呼び出しなしで Phase を done にする
  - 全 subtask が [x] でないのに Phase を done にする

Guard による強制:
  - subtask-guard.sh: validations なしの [x] をブロック
  - phase-status-guard.sh: 未完了 subtask ありの Phase done をブロック
  - archive-playbook.sh: 未完了 subtask ありのアーカイブをブロック
```

### 正しいワークフロー例

```markdown
# 1. TodoWrite で計画（内部用）
TodoWrite([
  {content: "機能A実装", status: "in_progress", activeForm: "Implementing feature A"},
  {content: "機能Bテスト", status: "pending", activeForm: "Testing feature B"}
])

# 2. 作業完了 → playbook 更新（公式記録）
Edit: playbook の subtask を更新
  old: `- [ ] **p1.1**: 機能Aを実装する`
  new: `- [x] **p1.1**: 機能Aを実装する
    - validations:
      - technical: "PASS - ..."
      - consistency: "PASS - ..."
      - completeness: "PASS - ..."
    - validated: 2026-01-02T12:00:00Z`

# 3. TodoWrite を同期（内部用）
TodoWrite([
  {content: "機能A実装", status: "completed", ...},
  {content: "機能Bテスト", status: "in_progress", ...}
])
```

---

## Commit Message Format

```
{type}({scope}): {summary}

{body - optional}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

Types: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`

---

## Common Operations

### Edit Protected Files

Files in `.claude/protected-files.txt` require extra care:

```bash
# Check if file is protected
grep "filename" .claude/protected-files.txt

# If protected, document reason before editing
```

### Update State

```bash
# state.md fields to update:
# - playbook.active: Current task file
# - playbook.branch: Associated branch
# - session.last_start: Timestamp (auto-updated)
```

### Archive Completed Work

```bash
# Move completed playbooks
mv plan/playbook-{name}.md plan/archive/
```

---

## Repository Map Management

`docs/repository-map.yaml` はリポジトリ構造の **Single Source of Truth** です。

### 自動更新

```bash
# 手動で更新
bash .claude/hooks/generate-repository-map.sh

# 自動更新タイミング
# - playbook 完了時（archive-playbook.sh から呼び出し）
```

### 差分検出（[DRIFT]）

セッション開始時に `session-start.sh` が repository-map.yaml と実際のファイル数を比較し、
乖離があれば `[DRIFT]` メッセージを出力します。

```yaml
検出対象:
  - hooks: .claude/hooks/*.sh
  - agents: .claude/skills/*/agents/*.md
  - skills: .claude/skills/*/
  - commands: .claude/commands/*.md

[DRIFT] 検出時の対応:
  1. bash .claude/hooks/generate-repository-map.sh を実行
  2. 更新された repository-map.yaml を確認
  3. 必要に応じて git add && git commit

Claude の自動対応:
  - [DRIFT] を検出した場合、Claude は自動で generate-repository-map.sh を実行
  - コミットはユーザー確認後に行う
```

### 含まれる情報

| セクション | 内容 |
|-----------|------|
| `hooks` | 31 Hook スクリプト一覧 |
| `agents` | 6 SubAgent 定義一覧 |
| `skills` | 9 Skill 一覧 |
| `commands` | 8 コマンド一覧 |
| `docs` | 17 ドキュメント一覧 |
| `workflows` | 5 ワークフロー定義 |
| `integration_points` | コンポーネント間依存関係 |

### 参照ドキュメント

- `docs/ARCHITECTURE.md` - リポジトリ構造・Hook/Skill/SubAgent アーキテクチャ

---

## Tool Reference

### Hooks (automatic checks)

| Hook | Trigger | Purpose |
|------|---------|---------|
| playbook-guard.sh | Edit/Write | Ensures playbook exists |
| check-main-branch.sh | Edit/Write | Prevents main branch edits |
| check-protected-edit.sh | Edit/Write | Protects sensitive files |

### SubAgents (specialized tasks)

| Agent | Use For |
|-------|---------|
| critic | Verify task completion |
| pm | Project/playbook management |
| reviewer | Code/design review |

### Skills (domain knowledge)

| Skill | Purpose |
|-------|---------|
| context-management | /compact 最適化と履歴要約のガイドライン |
| deploy-checker | デプロイ準備・検証（環境変数、ビルド、セキュリティ） |
| frontend-design | プロダクション品質のフロントエンド UI 作成 |
| lint-checker | コード品質チェック（ESLint、TypeScript） |
| plan-management | Multi-layer planning と playbook 管理 |
| post-loop | playbook 完了後の自動コミット、マージ、次タスク導出 |
| state | state.md 管理、playbook 運用、done_criteria 判定 |
| test-runner | テスト実行・検証（Unit、E2E、型チェック、ビルド） |
| understanding-check | タスク依頼時の理解確認（5W1H）とリスク分析 |

---

## Admin Maintenance Mode

### When to Use

Admin mode is for **operational tasks only**, not for bypassing safety checks.

```yaml
allowed_operations:
  - Session end: archive playbook, update state.md
  - State recovery: fix corrupted state.md
  - Maintenance commits: state + archive files only

not_allowed_even_in_admin:
  - Editing code files without playbook
  - Modifying HARD_BLOCK files (CLAUDE.md, protected-files.txt, critical hooks)
  - Bypassing Core Contract (playbook requirement for semantic changes)
```

### Enabling Admin Mode

```bash
# In state.md, under ## config:
security: admin

# Remember to restore to strict when done:
security: strict
```

### Session End Procedure (Golden Path)

```bash
# 1. Enable admin mode (if not already)
# Edit state.md: security: admin

# 2. Archive the playbook
mkdir -p plan/archive
mv plan/playbook-{name}.md plan/archive/

# 3. Update state.md
# Edit: playbook.active: null

# 4. Commit maintenance changes
git add state.md plan/archive/
git commit -m "chore: session end - archive playbook"

# 5. Restore strict mode (optional but recommended)
# Edit state.md: security: strict
```

---

## Troubleshooting

### Hook Blocking Edit

```yaml
problem: "playbook 必須" error
solutions:
  1. Create a playbook: Task(subagent_type='pm', prompt='playbook を作成')
  2. For maintenance only: Set security: admin in state.md
  3. Note: Admin does NOT bypass playbook requirement for code changes
```

### Context Too Long

```yaml
problem: Context approaching limit
solutions:
  1. Run /clear to reset context
  2. Re-read state.md after reset
  3. Trust state files over chat history
```

### Stuck on Main Branch

```yaml
problem: Can't edit on main
solution:
  git checkout -b {type}/{description}
```

### [DRIFT] Repository Map Drift

```yaml
problem: "[DRIFT] repository-map.yaml に乖離あり" message at session start
cause: Files added/removed since last repository-map.yaml update

solutions:
  1. Run update script:
     bash .claude/hooks/generate-repository-map.sh

  2. Verify the update:
     git diff docs/repository-map.yaml

  3. Commit if appropriate:
     git add docs/repository-map.yaml
     git commit -m "chore: update repository-map.yaml"

note: Claude will automatically execute the update when detecting [DRIFT]
```

### Fail-Closed Recovery

When hooks block operations due to fail-closed behavior:

```yaml
problem: "[FAIL-CLOSED] state.md not found" or similar
causes:
  - state.md deleted or corrupted
  - Required files missing
  - jq not installed

solutions:
  1. Restore state.md from git:
     git checkout HEAD -- state.md

  2. Create minimal state.md manually:
     cat > state.md << 'EOF'
     # state.md
     ## playbook
     ```yaml
     active: null
     ```
     ## config
     ```yaml
     security: admin
     ```
     EOF

  3. Install missing tools:
     brew install jq  # macOS
     apt-get install jq  # Linux
```

### HARD_BLOCK File Needs Editing

```yaml
problem: Cannot edit CLAUDE.md or other HARD_BLOCK files
reason: HARD_BLOCK files are protected even in admin mode (by design)

solutions:
  1. Edit the file manually (outside Claude Code)
  2. Temporarily remove from .claude/protected-files.txt (not recommended)
  3. Follow Change Control process for CLAUDE.md modifications
```

---

## Modifying CLAUDE.md

**CLAUDE.md is FROZEN.** To modify it:

1. Document rationale in `governance/PROMPT_CHANGELOG.md`
2. Update version number in CLAUDE.md header
3. Run lint: `python scripts/lint_prompts.py`
4. Get maintainer approval
5. Commit with clear message explaining change

---

## Adding New Procedures

To add new procedures to this RUNBOOK:

1. Identify the appropriate section
2. Follow the existing format (yaml, tables, code blocks)
3. Keep instructions concrete and executable
4. Commit with descriptive message

No approval required - this file is designed to evolve.

---

## Version

Last updated: 2025-12-18 (Contract Consolidation update)
