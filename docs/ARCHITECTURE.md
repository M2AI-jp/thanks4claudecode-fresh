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

### 現在のタイムアウト設定（.claude/settings.json）

| Hook イベント | タイムアウト | 備考 |
|--------------|-------------|------|
| PreToolUse | 15,000ms | V17 で 10s → 15s に調整 |
| PostToolUse | 10,000ms | |
| SessionStart | 5,000ms | |
| UserPromptSubmit | 5,000ms | V17 で 3s → 5s に調整 |
| SubagentStop | 5,000ms | |
| PreCompact | 5,000ms | |

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
| 前セッションの状態不明 | state.md 読み込み | playbook 把握 |
| last_start 古い | タイムスタンプ更新 | last_start 現在時刻 |
| 状態不整合の可能性 | DRIFT チェック実行 | 整合性確認済み |

### 参照ファイル（読み取り）

| ファイル | 取得データ | 用途 |
|----------|-----------|------|
| state.md | playbook.active | 現在状態把握 |
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
| setup-guide | playbook.active == 'setup/playbook-setup.md' | .claude/skills/session-manager/agents/setup-guide.md |

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
| state.md | playbook.active | 現在 playbook |

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
    ├─→ ログ初期化（.claude/logs/ 作成）
    │
    ├─→ .claude/skills/session-manager/handlers/init-guard.sh
    │       └─→ 必須ファイル Read 強制
    │
    ├─→ .claude/skills/access-control/guards/main-branch.sh
    │       └─→ main ブランチでの作業ブロック
    │
    └─→ 終了時: 実行時間ログ出力
            └─→ .claude/logs/hook-timing.log
```

### ログ出力（V17 新規）

| ログファイル | 内容 | 出力タイミング |
|-------------|------|---------------|
| `.claude/logs/hook-timing.log` | Hook 実行時間 | 毎回の pre-tool.sh 終了時 |
| `.claude/logs/block-reasons.log` | BLOCK 理由 | ガードが exit 2 を返した時 |

```
ログ形式:
[2026-01-01 12:34:56] pre-tool.sh tool=Edit elapsed=123ms
[2026-01-01 12:34:56] BLOCK by playbook-gate/playbook-guard.sh (exit: 2) tool=Edit
```

### 状態遷移

| Before | 処理 | After |
|--------|------|-------|
| 必須ファイル未読 | init-guard チェック | Read 強制 or BLOCK |
| main ブランチ | main-branch チェック | 常にブロック |

### 参照ファイル（読み取り）

| ファイル | 取得データ | 用途 |
|----------|-----------|------|
| state.md | playbook.active | playbook 確認 |
| .claude/session-state/* | 既読ファイル | init-guard 判定 |

### main ブランチルール

main/master ブランチでの Edit/Write は常にブロックされる。
Claude は playbook 作成時に自動でブランチを切る。

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
    ├─→ .claude/skills/post-loop/guards/pending-guard.sh
    │       │
    │       ├─→ post-loop-pending ファイル存在 → BLOCK
    │       ├─→ 許可リスト: state.md, session-state/（デッドロック防止）
    │       └─→ Skill(skill='post-loop') 呼び出しを強制
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
| post-loop-pending 存在 | pending-guard | BLOCK + post-loop 必須案内 |
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
    │       ├─→ 全 Phase done 検出
    │       ├─→ 自動実行（10ステップ）:
    │       │   1. 未コミット変更を自動コミット
    │       │   2. Push（PR 作成前に必須）
    │       │   3. PR 作成（create-pr.sh）
    │       │   4. playbook アーカイブ（plan/archive/ へ移動）
    │       │   5. state.md 更新（playbook.active = null）
    │       │   6. アーカイブ変更をコミット
    │       │   7. 追加コミットを Push
    │       │   8. PR マージ（merge-pr.sh）
    │       │   9. main 同期（checkout + pull）
    │       │   10. pending ファイル作成（post-loop 強制用）
    │       │
    │       └─→ 書き込み:
    │           ├─→ plan/archive/playbook-*.md
    │           ├─→ state.md（playbook.active = null）
    │           └─→ .claude/session-state/post-loop-pending
    │
    └─→ .claude/skills/playbook-gate/workflow/cleanup.sh
            │
            └─→ tmp/ クリーンアップ
```

### 状態遷移

| Before | 処理 | After |
|--------|------|-------|
| 全 Phase done | archive-playbook（自動実行） | コミット→Push→PR→アーカイブ→マージ→main同期 |
| tmp/ に一時ファイル | cleanup | 一時ファイル削除 |
| 自動処理完了 | pending ファイル作成 | Edit/Write ブロック状態 |

### 書き込み

| ファイル | 書き込みデータ | 条件 |
|----------|---------------|------|
| plan/archive/playbook-*.md | アーカイブ済み playbook | 全 Phase done |
| state.md | playbook.active = null, last_archived | アーカイブ時 |
| .claude/session-state/post-loop-pending | status, playbook, timestamp | 自動処理完了時 |
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

> **M088: 4QV+ 検証必須** - playbook 作成時の事前検証

```
Task(subagent_type='reviewer')
    │
    ├─→ .claude/skills/quality-assurance/agents/reviewer.md
    │
    ├─→ 4QV+ 検証ステップ（必須）:
    │   ├─→ Q1: 形式検証（playbook 構造）
    │   ├─→ Q2: 内容検証（criterion 検証可能性）
    │   ├─→ Q3: 整合性検証（state.md との整合）
    │   ├─→ Q4: 完全性検証（漏れ検出）
    │   └─→ +: 批判的思考（報酬詐欺可能性）
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

> **M088: 4QV+ 検証必須** - phase/subtask 完了時の事後検証

```
Task(subagent_type='critic')
    │
    ├─→ .claude/skills/reward-guard/agents/critic.md
    │
    ├─→ 4QV+ 検証ステップ（必須）:
    │   ├─→ Q1: 形式検証（validations 構造）
    │   ├─→ Q2: 内容検証（technical 実行結果）
    │   ├─→ Q3: 整合性検証（consistency）
    │   ├─→ Q4: 完全性検証（completeness）
    │   └─→ +: 批判的思考（自己成果物を敵対的に評価）
    │
    ├─→ validation_types 判定:
    │   ├─→ automated: 自動で PASS/FAIL
    │   ├─→ manual: user 確認を強制
    │   └─→ hybrid: 自動検証 + user 確認
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

### SubAgent ライフサイクル管理

> **問題**: Task ツールで起動した SubAgent がバックグラウンドで残存する
>
> **解決**: SubagentStop Hook でクリーンアップ + 明示的な終了確認

```yaml
ライフサイクル:
  1. Task(subagent_type='xxx') で起動
  2. SubAgent が処理を実行
  3. SubAgent が結果を返す
  4. SubagentStop イベント発火 → クリーンアップ

残存防止ルール:
  - run_in_background=true は必要な場合のみ使用
  - バックグラウンド実行後は TaskOutput で結果を回収
  - 長時間タスクは timeout を設定
  - /tasks で残存タスクを定期確認
```

#### SubagentStop Hook

```
.claude/hooks/subagent-stop.sh
    │
    └─→ SubAgent 終了時の後処理
        - ログ記録
        - リソースクリーンアップ
```

#### 設定（.claude/settings.json）

```json
{
  "hooks": {
    "SubagentStop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/subagent-stop.sh",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
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
    ├── main-branch.sh          # main ブランチ作業ブロック（常時有効）
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
│   ├── executor-guard.sh       # executor 制御（V17 強化）
│   │   ├─→ 参照: plan/playbook-*.md（executor）
│   │   └─→ 参照: docs/executor-fallback-policy.md
│   └── role-resolver.sh        # 役割解決（toolstack → roles）
│       └─→ 参照: state.md（config.toolstack, config.roles）
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

### post-loop/
```
.claude/skills/post-loop/
├── SKILL.md                    # Skill 定義
├── guards/
│   └── pending-guard.sh        # Edit/Write ブロック
│       ├─→ 検出: .claude/session-state/post-loop-pending
│       ├─→ 許可リスト: state.md, session-state/
│       └─→ BLOCK + post-loop 呼び出し強制
└── handlers/
    └── complete.sh             # pending ファイル削除
        └─→ Edit/Write ブロック解除
```

---

## 9. テンプレート・フレームワーク一覧

### plan/template/（playbook 作成時参照）

| ファイル | 用途 | 参照元 |
|----------|------|--------|
| playbook-format.md | playbook テンプレート（V17） | pm, subtask-guard |
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
| executor-fallback-policy.md | executor フォールバック手順（V17 新規） | executor-guard, playbook |

---

## 9.5. Commands 一覧（.claude/commands/）

> **スラッシュコマンドで呼び出し可能なユーザー向け機能**

| コマンド | ファイル | 用途 |
|----------|----------|------|
| `/playbook-init` | playbook-init.md | playbook 作成（pm SubAgent に委譲） |
| `/crit` | crit.md | done_criteria の CRITIQUE（critic SubAgent に委譲） |
| `/review` | review.md | playbook + コードレビュー自動ループ（V17 新規） |
| `/init` | init.md | セッション完全初期化（V17 新規） |
| `/lint` | lint.md | 静的解析実行 |
| `/test` | test.md | テスト実行 |
| `/rollback` | rollback.md | Git ロールバック |
| `/state-rollback` | state-rollback.md | state.md ロールバック |

---

## 9.6. Rules 一覧（.claude/rules/）

> **ナレッジ一元化ディレクトリ（V17 新規）**
>
> CLAUDE.md から分離した詳細ルール。/init で読み込まれる。

| ファイル | 内容 |
|----------|------|
| README.md | ディレクトリ説明、読み込み順序 |
| coding.md | コーディング規約、命名規則、TypeScript 設定 |
| testing.md | テスト規約、TDD フロー、カバレッジ基準 |
| operations.md | 運用規約、Git ワークフロー、デプロイ手順 |

### 読み込み順序

```yaml
order:
  1: CLAUDE.md（憲法）
  2: state.md（現在状態）
  3: .claude/rules/*.md（詳細ルール）
  4: playbook（タスク定義）
```

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
    ├─→ YES: archive-playbook.sh（自動実行）
    │       │
    │       ├─→ Step 1-3: コミット → Push → PR 作成
    │       ├─→ Step 4-7: アーカイブ → state.md 更新 → コミット → Push
    │       ├─→ Step 8-9: PR マージ → main 同期
    │       └─→ Step 10: pending ファイル作成
    │           │
    │           └─→ Edit/Write ブロック状態開始
    │
    └─→ NO: 次の Phase へ
    │
    ▼
[PreToolUse:Edit/Write]（次の操作試行時）
    │ pending-guard.sh
    │
    └─→ BLOCK: Skill(skill='post-loop') を呼べと案内
    │
    ▼
Skill(skill='post-loop')
    │
    ├─→ handlers/complete.sh: pending ファイル削除
    │       │
    │       └─→ Edit/Write ブロック解除
    │
    └─→ 次タスク導出（pm SubAgent 経由）
            │
            ├─→ 残タスクあり: ブランチ作成 → playbook 作成 → LOOP 継続
            └─→ 残タスクなし: 「全タスク完了。次の指示を待ちます。」
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
| 2026-01-01 | V17: Hook ログ機能追加、Commands/Rules セクション追加、executor-fallback-policy.md 追加 |
| 2025-12-25 | post-loop 自動発火: archive-playbook.sh 自動実行、pending-guard.sh 追加 |
| 2025-12-25 | 公式 Hook リファレンス追加（イベント一覧、入力 JSON、exit code） |
| 2025-12-25 | 全面改訂: ユーザー体験ベースの状態遷移マップに変更 |
| 2025-12-24 | docs 整理: 重複ファイル削除、統計値更新 |
| 2025-12-18 | 初版作成（cleanup/architecture-audit） |
