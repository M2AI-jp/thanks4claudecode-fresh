# architecture.md

> **ユーザー体験ベースの状態遷移マップ**
>
> Hook → Skill → SubAgent の動線と、全ての参照関係・情報移動を表現。
> 修正作業時のナビゲーションマップとして機能する。

---

## 概要

```
4QV+ 導火線モデル:
  Hook（トリガー）→ Skill（パッケージ）→ SubAgent（専門検証）

Single Source of Truth:
  state.md → playbook → 実行
```

---

## 0. Hook リファレンス（公式）

> **参照: https://code.claude.com/docs/ja/hooks**

### 利用可能な Hook イベント

| イベント名 | 説明 | マッチャー |
|-----------|------|----------|
| **PreToolUse** | ツール実行前（パラメータ作成後、実行前） | `Write\|Edit` 等で絞り込み可 |
| **PostToolUse** | ツール正常完了直後 | 同上 |
| **UserPromptSubmit** | ユーザープロンプト送信時（Claude 処理前） | なし |
| **Stop** | メイン Claude エージェント応答完了時 | なし |
| **SubagentStop** | サブエージェント（Task）応答完了時 | なし |
| **PreCompact** | コンパクト操作実行前 | `manual`/`auto` |
| **SessionStart** | セッション開始/再開時 | `startup`/`resume`/`clear`/`compact` |
| **SessionEnd** | セッション終了時 | なし |
| **Notification** | Claude が通知を送信するとき | なし |

### 入力パラメータ（stdin JSON）

```json
// 共通フィールド（全イベント）
{
  "session_id": "abc123",
  "cwd": "/path/to/project",
  "hook_event_name": "PreToolUse | PostToolUse | ...",
  "transcript_path": "/Users/.../.claude/projects/.../xxxxx.jsonl"
}

// PreToolUse 固有
{
  "tool_name": "Write | Edit | Read | Bash | Task | ...",
  "tool_input": { "file_path": "...", "content": "..." }
}

// PostToolUse 固有
{
  "tool_response": { "filePath": "...", "success": true }
}

// UserPromptSubmit 固有
{
  "prompt": "ユーザーが入力したテキスト"
}

// SessionStart 固有
{
  "source": "startup | resume | clear | compact"
}
```

### Exit Code の意味

| Exit Code | 動作 | 用途 |
|-----------|------|------|
| **0** | 成功・続行 | ツール実行を許可 |
| **2** | ブロック | ツール実行をブロック、stderr を Claude に表示 |
| **その他** | エラー（続行） | stderr をユーザーに表示、実行は続行 |

### JSON 出力（高度な制御）

```json
{
  "continue": true,
  "systemMessage": "Claude に表示するメッセージ",
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow | deny | ask",
    "updatedInput": { "field": "modified value" }
  }
}
```

### MCP ツールのマッチャー

```json
{
  "matcher": "mcp__memory__.*",     // 全メモリ操作
  "matcher": "mcp__.*__write.*"     // 全サーバーの書き込み
}
```

---

## 1. SessionStart（セッション開始）

### 発火条件

**Hook イベント**: `SessionStart`

| source | 説明 |
|--------|------|
| `startup` | 新規セッション開始 |
| `resume` | 既存セッション再開 |
| `clear` | `/clear` コマンド後 |
| `compact` | コンパクト後の再開 |

### Hook
```
.claude/hooks/session.sh
    │
    └─→ .claude/skills/session-manager/handlers/start.sh
```

### 状態遷移

| Before | 処理 | After |
|--------|------|-------|
| 前セッションの状態不明 | state.md 読み込み | focus, playbook 把握 |
| last_start 古い | タイムスタンプ更新 | last_start 現在時刻 |
| 状態不整合の可能性 | DRIFT チェック実行 | 整合性確認済み |

### 参照ファイル（読み取り）

| ファイル | 取得データ | 用途 |
|----------|-----------|------|
| state.md | focus.current, playbook.active | 現在状態把握 |
| plan/playbook-*.md | phases, done_criteria | 作業計画確認 |
| docs/repository-map.yaml | ファイル構造 | 変更検出 |

### 書き込み

| ファイル | 書き込みデータ |
|----------|---------------|
| state.md | session.last_start |
| .claude/logs/session.log | セッション開始ログ |

### 関連 SubAgent

| SubAgent | トリガー条件 | 参照ファイル |
|----------|-------------|-------------|
| setup-guide | focus.current == 'setup' | .claude/skills/session-manager/agents/setup-guide.md |

---

## 2. UserPromptSubmit（ユーザープロンプト送信）

### 発火条件

**Hook イベント**: `UserPromptSubmit`

ユーザーがプロンプトを送信した時（Claude が処理する前）。
プロンプトの検証やコンテキスト追加が可能。

### Hook
```
.claude/hooks/prompt.sh
    │
    └─→ State Injection（systemMessage への情報注入）
```

### 状態遷移

| Before | 処理 | After |
|--------|------|-------|
| プロンプト未処理 | State Injection | コンテキスト付加 |
| playbook=null | playbook-init 提案表示 | ユーザーに案内表示 |
| タスク依頼パターン検出 | understanding-check 必須通知 | 理解確認フロー開始 |

### 参照ファイル（読み取り）

| ファイル | 取得データ | 用途 |
|----------|-----------|------|
| state.md | playbook.active | playbook 存在確認 |
| state.md | focus.current | 現在コンテキスト |

### 書き込み
なし（systemMessage への出力のみ）

### タスク依頼パターン検出時のチェーン

```
prompt.sh
    │ playbook=null + タスク依頼パターン
    │
    └─→ Skill(skill='playbook-init') を呼べと案内
            │
            ├─→ .claude/skills/playbook-init/SKILL.md
            │       │
            │       └─→ 参照: .claude/skills/understanding-check/SKILL.md
            │
            └─→ Task(subagent_type='pm')
                    │
                    ├─→ .claude/skills/golden-path/agents/pm.md
                    │       │
                    │       ├─→ 参照: plan/template/playbook-format.md
                    │       ├─→ 参照: docs/criterion-validation-rules.md
                    │       └─→ 参照: .claude/frameworks/playbook-review-criteria.md
                    │
                    └─→ Task(subagent_type='reviewer')
                            │
                            ├─→ .claude/skills/quality-assurance/agents/reviewer.md
                            │       │
                            │       ├─→ 参照: .claude/frameworks/playbook-review-criteria.md
                            │       └─→ 参照: .claude/frameworks/playbook-reviewer-spec.md
                            │
                            └─→ 書き込み: playbook.reviewed = true
```

---

## 3. PreToolUse:*（全ツール共通）

### 発火条件

**Hook イベント**: `PreToolUse`

Claude がツール名と入力パラメータを決定した後、実際の実行前に発火。
`tool_name` でツール種別を判定し、条件分岐が可能。

```json
// stdin で受け取る JSON
{
  "tool_name": "Edit | Write | Read | Bash | Task | ...",
  "tool_input": { ... }
}
```

### Hook
```
.claude/hooks/pre-tool.sh
    │
    ├─→ .claude/skills/session-manager/handlers/init-guard.sh
    │       └─→ 必須ファイル Read 強制
    │
    └─→ .claude/skills/access-control/guards/main-branch.sh
            └─→ main ブランチでの作業ブロック
```

### 状態遷移

| Before | 処理 | After |
|--------|------|-------|
| 必須ファイル未読 | init-guard チェック | Read 強制 or BLOCK |
| main ブランチ | main-branch チェック | focus 依存で許可/ブロック |

### 参照ファイル（読み取り）

| ファイル | 取得データ | 用途 |
|----------|-----------|------|
| state.md | focus.current | main 許可判定 |
| .claude/session-state/* | 既読ファイル | init-guard 判定 |

### main ブランチ許可ルール

| focus 値 | main での Edit/Write |
|----------|---------------------|
| setup | 許可 |
| product | 許可 |
| plan-template | 許可 |
| thanks4claudecode | ブロック（ブランチ必須） |
| その他 | ブロック |

---

## 4. PreToolUse:Edit/Write（編集/書き込み前）

### 発火条件

**Hook イベント**: `PreToolUse`（マッチャー: `Edit|Write`）

```json
// stdin で受け取る JSON（Edit の場合）
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "/path/to/file",
    "old_string": "...",
    "new_string": "..."
  }
}
```

ブロック時は `exit 2` + stderr にメッセージ。

### Hook チェーン
```
.claude/hooks/pre-tool.sh
    │
    ├─→ .claude/skills/access-control/guards/protected-edit.sh
    │       │
    │       └─→ 参照: .claude/protected-files.txt
    │
    ├─→ .claude/skills/playbook-gate/guards/playbook-guard.sh
    │       │
    │       ├─→ playbook=null → BLOCK + playbook-init 案内
    │       └─→ reviewed=false → BLOCK + reviewer 必須案内
    │
    ├─→ .claude/skills/playbook-gate/guards/depends-check.sh
    │       │
    │       └─→ 参照: plan/playbook-*.md（depends_on）
    │
    ├─→ .claude/skills/playbook-gate/guards/executor-guard.sh
    │       │
    │       └─→ 参照: plan/playbook-*.md（executor）
    │
    ├─→ .claude/skills/reward-guard/guards/critic-guard.sh
    │       │
    │       └─→ done 変更前に critic 必須
    │
    ├─→ .claude/skills/reward-guard/guards/subtask-guard.sh
    │       │
    │       ├─→ - [ ] → - [x] 変更時に 3点検証確認
    │       └─→ 参照: plan/template/playbook-format.md（validations）
    │
    └─→ .claude/skills/reward-guard/guards/scope-guard.sh
            │
            └─→ done_criteria 変更検出
```

### 状態遷移

| Before | 処理 | After |
|--------|------|-------|
| 保護ファイル編集試行 | protected-edit | BLOCK |
| playbook=null | playbook-guard | BLOCK + 案内 |
| reviewed=false | playbook-guard | BLOCK + reviewer 必要 |
| 依存 Phase 未完了 | depends-check | BLOCK + 依存表示 |
| executor 不一致 | executor-guard | WARN |
| done 変更試行 | critic-guard | critic 必須通知 |
| subtask 未検証で [x] | subtask-guard | BLOCK |
| scope 変更試行 | scope-guard | WARN + 確認要求 |

### 参照ファイル（読み取り）

| ファイル | 取得データ | チェック内容 |
|----------|-----------|-------------|
| state.md | playbook.active | playbook 存在 |
| plan/playbook-*.md | reviewed, phases, subtasks | 各種ガードチェック |
| .claude/protected-files.txt | 保護リスト | 編集可否 |

---

## 5. PreToolUse:Bash（Bash 前）

### 発火条件

**Hook イベント**: `PreToolUse`（マッチャー: `Bash`）

```json
// stdin で受け取る JSON
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "git status"
  }
}
```

### Hook チェーン
```
.claude/hooks/pre-tool.sh
    │
    ├─→ .claude/skills/access-control/guards/bash-check.sh
    │       │
    │       └─→ 破壊的コマンドの検出・警告
    │
    ├─→ .claude/skills/reward-guard/guards/coherence.sh
    │       │
    │       └─→ state.md と playbook の整合性チェック
    │
    └─→ .claude/skills/quality-assurance/checkers/lint.sh
            │
            └─→ git commit 前の静的解析
```

### 状態遷移

| Before | 処理 | After |
|--------|------|-------|
| 破壊的コマンド | bash-check | WARN or BLOCK |
| state/playbook 不整合 | coherence | WARN + 修正提案 |
| git commit 試行 | lint | 静的解析実行 |

### 参照ファイル（読み取り）

| ファイル | 取得データ | チェック内容 |
|----------|-----------|-------------|
| state.md | playbook.active, goal | 整合性確認 |
| plan/playbook-*.md | phases.status | 状態一致確認 |

---

## 6. PostToolUse:Edit（編集後）

### 発火条件

**Hook イベント**: `PostToolUse`（マッチャー: `Edit`）

ツール正常完了直後に発火。成功時のみ実行される。
`tool_response` でツール実行結果を取得可能。

```json
// stdin で受け取る JSON
{
  "tool_name": "Edit",
  "tool_input": { "file_path": "...", ... },
  "tool_response": { "filePath": "...", "success": true }
}
```

### Hook チェーン
```
.claude/hooks/post-tool.sh
    │
    ├─→ .claude/skills/playbook-gate/workflow/archive-playbook.sh
    │       │
    │       ├─→ 全 Phase done → アーカイブ提案
    │       └─→ 書き込み: plan/archive/playbook-*.md
    │
    ├─→ .claude/skills/playbook-gate/workflow/cleanup.sh
    │       │
    │       └─→ tmp/ クリーンアップ
    │
    └─→ .claude/skills/git-workflow/handlers/create-pr-hook.sh
            │
            └─→ playbook 完了時に PR 作成提案
```

### 状態遷移

| Before | 処理 | After |
|--------|------|-------|
| 全 Phase done | archive-playbook | playbook アーカイブ |
| tmp/ に一時ファイル | cleanup | 一時ファイル削除 |
| playbook 完了 | create-pr-hook | PR 作成提案 |

### 書き込み

| ファイル | 書き込みデータ | 条件 |
|----------|---------------|------|
| plan/archive/playbook-*.md | アーカイブ済み playbook | 全 Phase done |
| state.md | playbook.active = null, last_archived | アーカイブ時 |
| tmp/ | ファイル削除 | playbook 完了時 |

---

## 7. SubAgent 呼び出し（Task ツール）

### pm SubAgent

```
Task(subagent_type='pm')
    │
    ├─→ .claude/skills/golden-path/agents/pm.md
    │
    ├─→ 参照（読み取り）:
    │   ├─→ plan/template/playbook-format.md（テンプレート）
    │   ├─→ plan/template/planning-rules.md（計画ルール）
    │   ├─→ docs/criterion-validation-rules.md（禁止パターン）
    │   ├─→ docs/ai-orchestration.md（役割定義）
    │   └─→ .claude/skills/understanding-check/SKILL.md（理解確認）
    │
    ├─→ 書き込み:
    │   ├─→ plan/playbook-{name}.md（新規 playbook）
    │   └─→ state.md（playbook.active 更新）
    │
    └─→ 呼び出し:
        └─→ Task(subagent_type='reviewer')
```

### reviewer SubAgent

```
Task(subagent_type='reviewer')
    │
    ├─→ .claude/skills/quality-assurance/agents/reviewer.md
    │
    ├─→ 参照（読み取り）:
    │   ├─→ .claude/frameworks/playbook-review-criteria.md（評価基準）
    │   ├─→ .claude/frameworks/playbook-reviewer-spec.md（LOOP 仕様）
    │   └─→ .claude/frameworks/done-criteria-validation.md（done_criteria 評価）
    │
    └─→ 書き込み:
        └─→ plan/playbook-*.md（reviewed: true に更新）
```

### critic SubAgent

```
Task(subagent_type='critic')
    │
    ├─→ .claude/skills/reward-guard/agents/critic.md
    │
    ├─→ 参照（読み取り）:
    │   ├─→ .claude/frameworks/done-criteria-validation.md（評価フレームワーク）
    │   ├─→ docs/criterion-validation-rules.md（禁止パターン）
    │   └─→ plan/playbook-*.md（subtasks, validations）
    │
    ├─→ 呼び出し:
    │   ├─→ Skill: lint-checker（コード変更時）
    │   └─→ Skill: test-runner（テスト変更時）
    │
    └─→ 出力:
        └─→ CRITIQUE 結果（PASS/FAIL + 証拠）
```

### codex-delegate SubAgent

```
Task(subagent_type='codex-delegate')
    │
    ├─→ .claude/skills/golden-path/agents/codex-delegate.md
    │
    ├─→ MCP 呼び出し:
    │   └─→ mcp__codex__codex（Codex CLI）
    │
    └─→ 出力:
        └─→ コード実装結果（要約）
```

### health-checker SubAgent

```
Task(subagent_type='health-checker')
    │
    ├─→ .claude/skills/quality-assurance/agents/health-checker.md
    │
    ├─→ 参照（読み取り）:
    │   ├─→ state.md（整合性チェック）
    │   ├─→ plan/playbook-*.md（存在確認）
    │   └─→ docs/repository-map.yaml（DRIFT 検出）
    │
    └─→ 出力:
        └─→ 健全性レポート
```

### setup-guide SubAgent

```
Task(subagent_type='setup-guide')
    │
    ├─→ .claude/skills/session-manager/agents/setup-guide.md
    │
    ├─→ 参照（読み取り）:
    │   └─→ plan/template/state-initial.md（初期状態テンプレート）
    │
    └─→ 書き込み:
        ├─→ state.md（セットアップ状態）
        └─→ CLAUDE.md（カスタマイズ）
```

### SubAgent ツール制限（報酬詐欺防止）

> **参照: https://code.claude.com/docs/ja/sub-agents**
>
> `tools` フィールドを省略すると全ツール継承。明示的に制限することで責務を限定。

| SubAgent | 許可ツール | 意図 |
|----------|-----------|------|
| **critic** | Read, Grep, Bash | 書き込み不可 → 自己完了防止 |
| **reviewer** | Read, Grep, Glob, Bash | 検証専念（編集権限なし） |
| **pm** | Read, Write, Edit, Grep, Glob, Bash | playbook 作成に書き込み必要 |
| **health-checker** | Read, Grep, Glob, Bash | 読み取り専用の健全性チェック |
| **setup-guide** | Read, Write, Edit, Bash, Grep, Glob | 初期設定に書き込み必要 |
| **codex-delegate** | Bash, mcp__codex__codex, mcp__codex__codex-reply | Codex MCP 専用 |

```yaml
設計原則:
  - 検証系（critic, reviewer, health-checker）は書き込み権限を与えない
  - 作成系（pm, setup-guide）は必要最小限の書き込み権限
  - 外部連携（codex-delegate）は専用ツールのみ
```

---

## 8. Skills 一覧と内部構成

### session-manager/
```
.claude/skills/session-manager/
├── SKILL.md                    # Skill 定義
├── agents/
│   └── setup-guide.md          # setup-guide SubAgent
└── handlers/
    ├── init-guard.sh           # 必須ファイル Read 強制
    └── start.sh                # セッション開始処理
        └─→ source: .claude/lib/common.sh
```

### access-control/
```
.claude/skills/access-control/
├── SKILL.md                    # Skill 定義
└── guards/
    ├── main-branch.sh          # main ブランチ作業ブロック
    │   └─→ 参照: state.md（focus.current）
    ├── protected-edit.sh       # 保護ファイルブロック
    │   └─→ 参照: .claude/protected-files.txt
    └── bash-check.sh           # 破壊的コマンド検出
```

### playbook-gate/
```
.claude/skills/playbook-gate/
├── SKILL.md                    # Skill 定義
├── guards/
│   ├── playbook-guard.sh       # playbook 必須チェック
│   │   └─→ 参照: state.md, plan/playbook-*.md
│   ├── depends-check.sh        # Phase 依存チェック
│   │   └─→ 参照: plan/playbook-*.md（depends_on）
│   └── executor-guard.sh       # executor 制御
│       └─→ 参照: plan/playbook-*.md（executor）
└── workflow/
    ├── archive-playbook.sh     # playbook アーカイブ
    │   └─→ 書き込み: plan/archive/, state.md
    └── cleanup.sh              # tmp/ クリーンアップ
```

### reward-guard/
```
.claude/skills/reward-guard/
├── SKILL.md                    # Skill 定義
├── agents/
│   └── critic.md               # critic SubAgent
│       └─→ 参照: .claude/frameworks/done-criteria-validation.md
└── guards/
    ├── critic-guard.sh         # done 変更前チェック
    ├── subtask-guard.sh        # subtask 3検証
    │   └─→ 参照: plan/template/playbook-format.md（validations）
    ├── scope-guard.sh          # done_criteria 変更検出
    └── coherence.sh            # 整合性チェック
```

### quality-assurance/
```
.claude/skills/quality-assurance/
├── SKILL.md                    # Skill 定義
├── agents/
│   ├── reviewer.md             # reviewer SubAgent
│   │   └─→ 参照: .claude/frameworks/playbook-review-criteria.md
│   └── health-checker.md       # health-checker SubAgent
└── checkers/
    └── lint.sh                 # 静的解析
```

### golden-path/
```
.claude/skills/golden-path/
├── SKILL.md                    # Skill 定義
└── agents/
    ├── pm.md                   # pm SubAgent（エントリーポイント）
    │   ├─→ 参照: plan/template/playbook-format.md
    │   ├─→ 参照: docs/criterion-validation-rules.md
    │   └─→ 呼び出し: understanding-check, reviewer
    └── codex-delegate.md       # codex-delegate SubAgent
```

### git-workflow/
```
.claude/skills/git-workflow/
├── SKILL.md                    # Skill 定義
└── handlers/
    └── create-pr-hook.sh       # PR 作成提案
```

---

## 9. テンプレート・フレームワーク一覧

### plan/template/（playbook 作成時参照）

| ファイル | 用途 | 参照元 |
|----------|------|--------|
| playbook-format.md | playbook テンプレート（V16） | pm, subtask-guard |
| planning-rules.md | 計画ルール | pm |
| playbook-examples.md | 具体例 | pm |
| state-initial.md | 初期 state テンプレート | setup-guide |
| vercel-nextjs-saas-structure.md | Next.js SaaS 構造 | pm（参考） |

### .claude/frameworks/（検証時参照）

| ファイル | 用途 | 参照元 |
|----------|------|--------|
| done-criteria-validation.md | done_criteria 評価基準 | critic（必須） |
| playbook-review-criteria.md | playbook レビュー基準 | reviewer |
| playbook-reviewer-spec.md | reviewer LOOP 仕様 | reviewer |

### docs/（全般参照）

| ファイル | 用途 | 参照元 |
|----------|------|--------|
| criterion-validation-rules.md | criterion 禁止パターン | pm, critic |
| ai-orchestration.md | 役割定義（executor） | pm |
| git-operations.md | git 操作ルール | pm |
| folder-management.md | フォルダ管理 | cleanup |
| current-definitions.md | 用語定義 | 全般 |

---

## 10. 情報フロー図

### タスク開始から完了まで

```
ユーザー: 「〜を作って」
    │
    ▼
[UserPromptSubmit]
    │ prompt.sh → playbook=null 検出
    │
    ▼
Skill(skill='playbook-init')
    │
    ▼
pm SubAgent
    ├─→ Read: plan/template/playbook-format.md
    ├─→ Read: .claude/skills/understanding-check/SKILL.md
    │       │
    │       └─→ 5W1H 分析 → AskUserQuestion
    │
    ├─→ Write: plan/playbook-{name}.md
    │
    └─→ Task(subagent_type='reviewer')
            │
            ├─→ Read: .claude/frameworks/playbook-review-criteria.md
            │
            ├─→ PASS → Edit: playbook.reviewed = true
            └─→ FAIL → pm に差し戻し（最大3回）
    │
    ▼
[PreToolUse:Edit]
    │ playbook-guard.sh → playbook 存在 + reviewed=true 確認
    │
    ▼
実装作業（Edit/Write/Bash）
    │
    ▼
Phase 完了判定
    │
    ├─→ subtask-guard.sh: validations 3点検証
    │
    └─→ Task(subagent_type='critic')
            │
            ├─→ Read: .claude/frameworks/done-criteria-validation.md
            │
            ├─→ PASS → Phase を done に更新
            └─→ FAIL → 修正して再判定
    │
    ▼
[PostToolUse:Edit]
    │ 全 Phase done?
    │
    ├─→ YES: archive-playbook.sh
    │       ├─→ Move: plan/playbook-*.md → plan/archive/
    │       └─→ Edit: state.md（playbook.active = null）
    │
    └─→ NO: 次の Phase へ
```

---

## 11. SSOT（Single Source of Truth）

### 信頼度階層

```
1. state.md          ← 最優先（現在状態）
2. playbook          ← タスク定義・進捗
3. チャット履歴      ← コンテキストリセットで消失
```

### state.md 構造

```yaml
focus:
  current: {focus値}      # 現在コンテキスト

playbook:
  active: {path}          # 現在の playbook（null = なし）
  branch: {branch}        # 作業ブランチ
  last_archived: {path}   # 最後にアーカイブした playbook

goal:
  milestone: {id}         # 現在のマイルストーン
  phase: {id}            # 現在の Phase
  done_criteria: []      # 完了条件

session:
  last_start: {timestamp}
  last_end: {timestamp}

config:
  security: {mode}       # normal | admin
  toolstack: {A|B|C}     # 使用ツール構成
  roles:
    orchestrator: claudecode
    worker: codex | claudecode
    reviewer: coderabbit | claudecode
```

---

## 12. コア契約（回避不可）

### Golden Path（タスク開始）

```yaml
trigger: 作って/実装して/修正して/追加して
required_chain:
  1. Skill(skill='playbook-init')
  2. playbook-init → pm SubAgent
  3. pm → understanding-check
  4. pm → reviewer
prohibited:
  - Task(subagent_type='pm') 直接呼び出し
  - understanding-check スキップ
  - reviewer スキップ
```

### Playbook Gate

```yaml
condition: playbook.active == null
action: Edit/Write をブロック
bypass: なし（admin モードでも無効）
```

### Reward Fraud Prevention

```yaml
rule: 自分の作業を自分で「完了」と判定しない
required: critic SubAgent による独立検証
evidence: PASS 判定には実行可能な証拠が必要
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-25 | 公式 Hook リファレンス追加（イベント一覧、入力 JSON、exit code） |
| 2025-12-25 | 全面改訂: ユーザー体験ベースの状態遷移マップに変更 |
| 2025-12-24 | docs 整理: 重複ファイル削除、統計値更新 |
| 2025-12-18 | 初版作成（cleanup/architecture-audit） |
