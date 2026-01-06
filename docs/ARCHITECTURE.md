# architecture.md

> **ユーザー体験ベースの状態遷移マップ**
>
> Hook Unit（イベント境界）→ Skill → SubAgent の動線と、参照関係・情報移動を表現。
> ユーザーフローの設計図と修正作業時のナビゲーションマップとして機能する。

---

## 概要

```
4QV+ 導火線モデル:
  Hook（トリガー）→ Skill（パッケージ）→ SubAgent（専門検証）

Single Source of Truth:
  state.md → playbook → 実行
```

> Hook Unit 目録: docs/core-feature-reclassification.md

---

## 理想ユーザーフロー（SSOT）

```
1) ユーザー依頼
   UserPromptSubmit Unit が意図を解析
   -> playbook-init -> pm -> reviewer で計画を確定
   -> state.md に反映

2) 実行
   PreToolUse(Edit/Write/Bash) Unit が playbook gate と安全性を強制
   -> executor（codex/coderabbit/user）に委譲
   -> validations を実行

3) 検証
   critic が done_criteria を証拠ベースで判定
   -> PASS でのみ完了へ進む

4) 完了
   PostToolUse(Edit/Write) Unit が整理・PRフロー・アーカイブを実施
   Stop/SessionEnd/Notification が状態を記録
```

このフローは Hook Unit 単位で保証される。詳細な依存マップは
`docs/core-feature-reclassification.md` が SSOT。

---

## Event Unit Architecture (SSOT)

Boundary is event timing, not function. Each Hook event owns a unit with its own
validator/context/guardrail/telemetry/retry/snapshot + chain.

Target layout (not yet implemented):

```
.claude/events/<event-unit>/
  validator.sh
  context-injector.sh
  guardrail.sh
  telemetry.sh
  retry.sh        # optional
  snapshot.sh     # optional
  chain.sh
```

Current implementation dispatches from hooks to event unit chain wrappers,
which still call existing skills. Component split is not yet implemented.
The canonical mapping (ideal -> current -> missing) lives in
`docs/core-feature-reclassification.md`.

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

### Event Unit Mapping (current -> target)

| Hook event | Unit ID | Dispatcher (current) | Target unit dir |
|-----------|---------|----------------------|-----------------|
| SessionStart | session-start | `.claude/hooks/session.sh` | `.claude/events/session-start/` |
| UserPromptSubmit | user-prompt-submit | `.claude/hooks/prompt.sh` | `.claude/events/user-prompt-submit/` |
| PreToolUse (Edit/Write) | pre-tool-edit | `.claude/hooks/pre-tool.sh` | `.claude/events/pre-tool-edit/` |
| PreToolUse (Bash) | pre-tool-bash | `.claude/hooks/pre-tool.sh` | `.claude/events/pre-tool-bash/` |
| PostToolUse (Edit/Write) | post-tool-edit | `.claude/hooks/post-tool.sh` | `.claude/events/post-tool-edit/` |
| SubagentStop | subagent-stop | `.claude/hooks/subagent-stop.sh` | `.claude/events/subagent-stop/` |
| PreCompact | pre-compact | `.claude/events/pre-compact/chain.sh` | `.claude/events/pre-compact/` |
| Stop | stop | `.claude/events/stop/chain.sh` | `.claude/events/stop/` |
| SessionEnd | session-end | `.claude/events/session-end/chain.sh` | `.claude/events/session-end/` |
| Notification | notification | `.claude/events/notification/chain.sh` | `.claude/events/notification/` |

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
    └─→ .claude/events/session-start/chain.sh
            └─→ .claude/skills/session-manager/handlers/start.sh
```

### 状態遷移

| Before | 処理 | After |
|--------|------|-------|
| post-loop-pending 残存 | stale pending を削除 | デッドロック回避 |
| 前セッションの状態不明 | state.md 読み込み | playbook 把握 |
| last_start 古い | タイムスタンプ更新 | last_start 現在時刻 |
| 状態不整合の可能性 | DRIFT チェック実行 | 整合性確認済み |

### 参照ファイル（読み取り）

| ファイル | 取得データ | 用途 |
|----------|-----------|------|
| state.md | playbook.active | 現在状態把握 |
| docs/repository-map.yaml | 構造カウント | 乖離検出 |
| .claude/.session-init/architecture-sync.yaml | drift フラグ | ARCHITECTURE 同期警告 |

### 書き込み

| ファイル | 書き込みデータ |
|----------|---------------|
| state.md | session.last_start |
| .claude/.session-init/pending | init-guard 用フラグ |
| .claude/.session-init/required_playbook | playbook.active の記録 |

### 関連 SubAgent

なし

---

## 1.5. PreCompact（コンテキスト圧縮前）

### 発火条件

**Hook イベント**: `PreCompact`

| matcher | 説明 |
|---------|------|
| `manual` | `/compact` コマンド実行時 |
| `auto` | auto-compact 発火時 |

### Hook
```
.claude/settings.json (PreCompact)
    └─→ .claude/events/pre-compact/chain.sh
            └─→ .claude/skills/session-manager/handlers/compact.sh
```

### 設計思想

```yaml
永続データ: playbook に集約（SSOT の延長）
復元橋: additionalContext（最小ポインタのみ）
snapshot.json: 廃止（.claude/ 配下は compact で削除されるため）
```

### additionalContext 出力（最小セット）

| フィールド | 必須 | 用途 |
|-----------|------|------|
| resume_instruction | ✓ | 1行で「何を読むか」（例: "Read state.md then open play/<id>/plan.json and progress.json"） |
| playbook | ✓ | 現在の playbook パス |
| phase | ✓ | 現在の phase ID |
| branch | - | 作業ブランチ（便利） |

### 状態遷移

| Before | 処理 | After |
|--------|------|-------|
| コンテキスト大 | compact.sh 実行 | additionalContext に最小ポインタ出力 |
| playbook 作業中 | 状態収集 | playbook/phase/branch を抽出 |

### 書き込み

なし（additionalContext への出力のみ）

---

## 2. UserPromptSubmit（ユーザープロンプト送信）

### 発火条件

**Hook イベント**: `UserPromptSubmit`

ユーザーがプロンプトを送信した時（Claude が処理する前）。
プロンプトの検証やコンテキスト追加が可能。

### Hook
```
.claude/hooks/prompt.sh
    └─→ .claude/events/user-prompt-submit/chain.sh
            └─→ instruction 検出時は playbook-init を自動指示（prompt-analyzer は playbook-init 内で自動実行可）
```

### 状態遷移

| Before | 処理 | After |
|--------|------|-------|
| プロンプト未処理 | State Injection | コンテキスト付加 |
| playbook=null | playbook-init 自動指示 | 自動フロー開始 |
| タスク依頼パターン検出 | auto_approve 判定 | understanding-check 自動承認 or 確認 |

### 参照ファイル（読み取り）

| ファイル | 取得データ | 用途 |
|----------|-----------|------|
| state.md | playbook.active | playbook 存在確認 |
| state.md | playbook.active | 現在 playbook |

### 書き込み
なし（systemMessage への出力のみ）

### タスク依頼パターン検出時のチェーン（設計）

Hook Unit の理想チェーンは `docs/core-feature-reclassification.md` に準拠。

```
playbook-init -> prompt-analyzer -> understanding-check (auto-approve 可) -> pm -> reviewer
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
    ├─→ .claude/skills/access-control/guards/main-branch.sh
    │       └─→ main ブランチでの作業ブロック
    │
    └─→ tool_name で分岐
            ├─→ .claude/events/pre-tool-edit/chain.sh (Edit|Write)
            └─→ .claude/events/pre-tool-bash/chain.sh (Bash)
```

### prompt-analyzer 強制

prompt-analyzer が未実行の状態では、以下のみ許可する。
ただし **playbook.active が null の場合のみ強制** し、active の場合は既存タスク継続として許可する:

- Read/Grep/Glob
- Skill(prompt-analyzer)
- Task(subagent_type='prompt-analyzer')
- Skill(playbook-init)（playbook-init 内で prompt-analyzer を実行するため）

### 状態遷移

| Before | 処理 | After |
|--------|------|-------|
| 必須ファイル未読 | init-guard チェック | Read 強制 or BLOCK |
| main ブランチ | main-branch チェック | 常にブロック |

### 参照ファイル（読み取り）

| ファイル | 取得データ | 用途 |
|----------|-----------|------|
| state.md | playbook.active | playbook 確認 |
| .claude/.session-init | 初期化済フラグ | init-guard 判定 |

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
    └─→ .claude/events/pre-tool-edit/chain.sh
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
            │       └─→ 参照: play/<id>/plan.json（depends_on）
            │
            ├─→ .claude/skills/playbook-gate/guards/executor-guard.sh
            │       │
            │       └─→ 参照: play/<id>/plan.json（executor）
            │
            ├─→ .claude/skills/reward-guard/guards/critic-guard.sh
            │       │
            │       └─→ done 変更前に critic 必須
            │
            ├─→ .claude/skills/reward-guard/guards/subtask-guard.sh
            │       │
            │       ├─→ - [ ] → - [x] 変更時に 3点検証確認
            │       └─→ 参照: play/template/plan.json（validation_plan）
            │
            ├─→ .claude/skills/reward-guard/guards/phase-status-guard.sh
            │       └─→ phase status 変更検出
            │
            └─→ .claude/skills/reward-guard/guards/scope-guard.sh
                    └─→ done_criteria 変更検出
```

### 状態遷移

| Before | 処理 | After |
|--------|------|-------|
| post-loop-pending 存在 | pending-guard | BLOCK + post-loop 必須案内 |
| 保護ファイル編集試行 | protected-edit | BLOCK |
| playbook=null | playbook-guard | BLOCK + 案内 |
| reviewed=false / context 欠落（v2: meta.reviewed/context） | playbook-guard | BLOCK + reviewer 必要 |
| 依存 Phase 未完了 | depends-check | BLOCK + 依存表示 |
| executor 不一致 | executor-guard | WARN |
| done 変更試行 | critic-guard | critic 必須通知 |
| subtask 未検証で [x] | subtask-guard | BLOCK |
| scope 変更試行 | scope-guard | WARN + 確認要求 |

### 参照ファイル（読み取り）

| ファイル | 取得データ | チェック内容 |
|----------|-----------|-------------|
| state.md | playbook.active | playbook 存在 |
| play/<id>/plan.json | reviewed, phases, validation_plan | 各種ガードチェック |
| play/<id>/progress.json | phases/subtasks/status/validations | reward-guard 判定 |
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
    └─→ .claude/events/pre-tool-bash/chain.sh
            ├─→ .claude/skills/access-control/guards/bash-check.sh
            │       └─→ 破壊的コマンドの検出・警告
            │
            ├─→ .claude/skills/reward-guard/guards/coherence.sh
            │       └─→ state.md と playbook の整合性チェック
            │
            └─→ .claude/skills/quality-assurance/checkers/lint.sh
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
| play/<id>/progress.json | phases.status | 状態一致確認 |

---

## 6. PostToolUse:Edit/Write（編集/書き込み後）

### 発火条件

**Hook イベント**: `PostToolUse`（マッチャー: `Edit|Write`）

ツール正常完了直後に発火。成功時のみ実行される。
`tool_response` でツール実行結果を取得可能。

```json
// stdin で受け取る JSON
{
  "tool_name": "Edit | Write",
  "tool_input": { "file_path": "...", ... },
  "tool_response": { "filePath": "...", "success": true }
}
```

### Hook チェーン
```
.claude/hooks/post-tool.sh
    └─→ .claude/events/post-tool-edit/chain.sh
            ├─→ .claude/skills/reward-guard/guards/progress-reminder.sh
            │       │
            │       ├─→ playbook.active 存在チェック
            │       ├─→ progress.json 以外のファイル編集を検出
            │       └─→ systemMessage でリマインダー注入:
            │           「progress.json を更新してください」
            │
            ├─→ .claude/skills/playbook-gate/workflow/archive-playbook.sh
            │       │
            │       ├─→ 全 Phase done 検出
            │       ├─→ 自動実行（10ステップ）:
            │       │   1. 未コミット変更を自動コミット
            │       │   2. Push（PR 作成前に必須）
            │       │   3. PR 作成（create-pr.sh）
            │       │   4. playbook アーカイブ（play/archive/<id>/ へ移動）
            │       │   5. state.md 更新（playbook.active = null）
            │       │   6. アーカイブ変更をコミット
            │       │   7. 追加コミットを Push
            │       │   8. PR マージ（merge-pr.sh）
            │       │   9. main 同期（checkout + pull）
            │       │   10. pending ファイル作成（post-loop 強制用）
            │       │
            │       └─→ 書き込み:
            │           ├─→ play/archive/<id>/
            │           ├─→ state.md（playbook.active = null）
            │           └─→ .claude/session-state/post-loop-pending
            │
            ├─→ .claude/skills/playbook-gate/workflow/cleanup.sh
            │       └─→ tmp/ クリーンアップ
            │
            └─→ .claude/skills/git-workflow/handlers/create-pr-hook.sh
                    └─→ PR 作成の案内/補助
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
| play/archive/<id>/ | アーカイブ済み playbook | 全 Phase done |
| state.md | playbook.active = null, last_archived | アーカイブ時 |
| .claude/session-state/post-loop-pending | status, playbook, timestamp | 自動処理完了時 |
| tmp/ | ファイル削除 | playbook 完了時 |

---

## 6.5. Stop（応答完了時）

### 発火条件

**Hook イベント**: `Stop`

メイン Claude エージェントの応答完了時に発火。
会話終了前の最終チェックポイントとして機能。

### Hook チェーン
```
.claude/events/stop/chain.sh
    └─→ .claude/skills/reward-guard/guards/completion-check.sh
            │
            ├─→ state.md から playbook.active を取得
            ├─→ progress.json の全 subtask の status をチェック
            ├─→ 未完了 subtask があれば exit 1 でブロック:
            │   「未完了の subtask があります - 応答をブロック」
            │
            └─→ 目的: subtask-guard バイパス対策（報酬詐欺防止）
                    Claude が progress.json を更新せずに
                    完了宣言することを強制的に防止
```

### 設計意図

subtask-guard は受動的（progress.json 編集時のみ発火）なため、
Claude が progress.json を更新せずに作業を完了できてしまう脆弱性があった。

completion-check.sh は能動的に Stop 時点でチェックし、
未完了 subtask があれば exit 1 で応答をブロックする。
報酬詐欺防止のため「強制」が必要。

### 状態遷移

| Before | 処理 | After |
|--------|------|-------|
| 未完了 subtask あり | completion-check | exit 1（応答ブロック） |
| 全 subtask done | completion-check | 正常終了（出力なし） |

---

## 7. SubAgent 呼び出し（Task ツール）

> Task は `.claude/agents/*.md` をサブエージェント登録ディレクトリとして参照する。
> `.claude/skills/*/agents/` は正規定義（設計・参照元）なので、運用時は `.claude/agents/` に同期しておくこと。
> `bash .claude/hooks/generate-repository-map.sh` が registry 同期も行う。

### pm SubAgent

```
Task(subagent_type='pm')
    │
    ├─→ .claude/skills/golden-path/agents/pm.md
    │
    ├─→ 参照（読み取り）:
    │   ├─→ play/template/plan.json（テンプレート）
    │   ├─→ play/template/progress.json（テンプレート）
    │   └─→ .claude/skills/understanding-check/SKILL.md（理解確認）
    │
    ├─→ 書き込み:
    │   ├─→ play/{id}/plan.json（新規 playbook）
    │   ├─→ play/{id}/progress.json（進捗）
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
        └─→ play/<id>/plan.json（reviewed: true に更新）
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
    ├─→ validation_plan 判定:
    │   ├─→ automated: 自動で PASS/FAIL
    │   ├─→ manual: user 確認を強制
    │   └─→ hybrid: 自動検証 + user 確認
    │
    ├─→ 参照（読み取り）:
    │   ├─→ .claude/frameworks/done-criteria-validation.md（評価フレームワーク）
    │   ├─→ play/<id>/plan.json（subtasks, validation_plan）
    │   └─→ play/<id>/progress.json（validations, evidence）
    │
    ├─→ 呼び出し:
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
    ├─→ 自動委譲トリガー:
    │   └─→ executor-guard.sh が executor: codex/worker を検出
    │       → hookSpecificOutput JSON を出力
    │       → Claude が Task(subagent_type='codex-delegate') を呼び出し
    │
    └─→ 出力:
        └─→ コード実装結果（要約）
```

### coderabbit-delegate SubAgent

```
Task(subagent_type='coderabbit-delegate')
    │
    ├─→ .claude/skills/quality-assurance/agents/coderabbit-delegate.md
    │
    ├─→ CLI 呼び出し:
    │   └─→ coderabbit review --plain [options]
    │
    ├─→ 自動委譲トリガー:
    │   └─→ executor-guard.sh が executor: coderabbit/reviewer を検出
    │       → hookSpecificOutput JSON を出力
    │       → Claude が Task(subagent_type='coderabbit-delegate') を呼び出し
    │
    └─→ 出力:
        ├─→ summary: レビュー概要（5行以内）
        ├─→ findings: 指摘事項（severity, file, line, issue, suggestion）
        ├─→ recommendations: 推奨アクション
        └─→ status: approved/needs_changes/rejected
```

### prompt-analyzer Skill

```
Skill(skill='prompt-analyzer')
(Task(subagent_type='prompt-analyzer') が利用可能な環境では Task でも可)
    │
    ├─→ .claude/skills/prompt-analyzer/agents/prompt-analyzer.md
    │
    ├─→ 処理:
    │   ├─→ 5W1H 抽出（Who, What, When, Where, Why, How）
    │   ├─→ リスク分析
    │   └─→ 曖昧さ検出
    │
    └─→ 出力:
        └─→ 構造化データ（pm SubAgent へ）
```

### executor-resolver SubAgent

```
Task(subagent_type='executor-resolver')
    │
    ├─→ .claude/skills/executor-resolver/agents/executor-resolver.md
    │
    ├─→ 処理:
    │   └─→ タスク性質を LLM ベースで分析 → executor 判定
    │
    └─→ 出力:
        └─→ executor: claudecode | codex | coderabbit | user
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
| **codex-delegate** | Bash, mcp__codex__codex, mcp__codex__codex-reply | Codex MCP 専用 |
| **coderabbit-delegate** | Bash | CodeRabbit CLI 専用（レビューのみ） |
| **prompt-analyzer** | Read, Grep | 分析専念（読み取りのみ） |
| **executor-resolver** | Read, Grep | 判定専念（読み取りのみ） |

```yaml
設計原則:
  - 検証系（critic, reviewer）は書き込み権限を与えない
  - 作成系（pm）は必要最小限の書き込み権限
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
    └─→ .claude/events/subagent-stop/chain.sh
            ├─→ playbook 完了判定
            └─→ archive-playbook.sh 呼び出し（全 Phase done の場合）
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
└── handlers/
    ├── init-guard.sh           # 必須ファイル Read 強制
    ├── start.sh                # セッション開始処理
    ├── end.sh                  # セッション終了処理
    └── compact.sh              # PreCompact: 最小ポインタで復元橋を架ける
        └─→ additionalContext に playbook/phase/branch のみ出力
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
│   │   └─→ 参照: state.md, play/<id>/plan.json
│   ├── depends-check.sh        # Phase 依存チェック
│   │   └─→ 参照: play/<id>/plan.json（depends_on）
│   ├── executor-guard.sh       # executor 制御
│   │   └─→ 参照: play/<id>/plan.json（executor）
│   └── role-resolver.sh        # executor 役割解決
└── workflow/
    ├── archive-playbook.sh     # playbook アーカイブ
    │   └─→ 書き込み: play/archive/<id>/, state.md
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
    │   └─→ 参照: play/<id>/progress.json（validations）
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
│   └── coderabbit-delegate.md  # coderabbit-delegate SubAgent（外部レビュー）
│       └─→ CLI: coderabbit review --plain
└── checkers/
    ├── lint.sh                 # 静的解析
    ├── integrity.sh            # 整合性チェック（playbook v2 の reviewed_by/evidence も検査）
    └── health.sh               # 健全性チェック
```

### golden-path/
```
.claude/skills/golden-path/
├── SKILL.md                    # Skill 定義
└── agents/
    ├── pm.md                   # pm SubAgent（エントリーポイント）
    │   ├─→ 参照: play/template/plan.json, play/template/progress.json
    │   └─→ 呼び出し: understanding-check, reviewer
    └── codex-delegate.md       # codex-delegate SubAgent
```

### git-workflow/
```
.claude/skills/git-workflow/
├── SKILL.md                    # Skill 定義
└── handlers/
    ├── create-pr-hook.sh       # PR 作成提案（Hook から呼び出し）
    ├── create-pr.sh            # PR 作成実行
    └── merge-pr.sh             # PR マージ実行
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

### executor-resolver/
```
.claude/skills/executor-resolver/
├── SKILL.md                    # Skill 定義
└── agents/
    └── executor-resolver.md    # タスク性質分析 → executor 判定
```

### playbook-init/
```
.claude/skills/playbook-init/
└── SKILL.md                    # タスク開始フロー → pm SubAgent 委譲
    └─→ Hook → Skill → SubAgent チェーン強制
```

### prompt-analyzer/
```
.claude/skills/prompt-analyzer/
├── SKILL.md                    # Skill 定義
└── agents/
    └── prompt-analyzer.md      # 5W1H 抽出・リスク分析・曖昧さ検出
```

### state/
```
.claude/skills/state/
└── SKILL.md                    # state.md 管理・playbook 運用の専門知識
```

### understanding-check/
```
.claude/skills/understanding-check/
└── SKILL.md                    # タスク依頼時の理解確認（5W1H）
    └─→ pm SubAgent から呼び出し
```

---

## 9. テンプレート・フレームワーク一覧

### play/template/（playbook 作成時参照）

| ファイル | 用途 | 参照元 |
|----------|------|--------|
| plan.json | playbook plan テンプレート | pm |
| progress.json | playbook progress テンプレート | pm |

### .claude/frameworks/（検証時参照）

| ファイル | 用途 | 参照元 |
|----------|------|--------|
| done-criteria-validation.md | done_criteria 評価基準 | critic（必須） |
| playbook-review-criteria.md | playbook レビュー基準 | reviewer |
| playbook-reviewer-spec.md | reviewer LOOP 仕様 | reviewer |

### docs/（全般参照）

| ファイル | 用途 | 参照元 |
|----------|------|--------|
| core-feature-reclassification.md | Hook Unit SSOT | 全体 |
| repository-map.yaml | リポジトリ構造マップ | session-manager |

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
    ├─→ Read: play/template/plan.json
    ├─→ Read: play/template/progress.json
    ├─→ Read: .claude/skills/understanding-check/SKILL.md
    │       │
    │       └─→ 5W1H 分析 → AskUserQuestion
    │
    ├─→ Write: play/{id}/plan.json
    ├─→ Write: play/{id}/progress.json
    │
    └─→ Task(subagent_type='reviewer')
            │
            ├─→ Read: .claude/frameworks/playbook-review-criteria.md
            │
            ├─→ PASS → Edit: plan.json reviewed = true
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
            │         iteration-count リセット
            │         last-fail-reason 削除
            │
            └─→ FAIL → 【自動リトライ機構（M086）】
                      │
                      ├─→ last-fail-reason に保存
                      ├─→ iteration-count++
                      │
                      └─→ count < max_iterations?
                              │
                              ├─→ YES: codex に再委譲（エラー注入）
                              │         executor-guard.sh が
                              │         last-fail-reason を読み込み
                              │         プロンプトに注入
                              │
                              └─→ NO: AskUserQuestion
                                       選択肢:
                                       - リトライ継続
                                       - 中止
                                       - 手動対応
    │
    ▼
[PostToolUse:Edit/Write]
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
2. playbook（play/<id>/plan.json + progress.json）← タスク定義・進捗
3. チャット履歴      ← コンテキストリセットで消失
```

### state.md 構造

```yaml
playbook:
  active: {path}          # 現在の playbook（plan.json, null = なし）
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

## 11.5 progress.json 更新フロー（責務定義）

> **問題**: progress.json の更新責務が Claude/SubAgent/Hook のどれに属するか不明確だった
>
> **解決**: 以下のフローで責務を明確化

### 更新責務

```yaml
progress.json の更新責務:
  orchestrator: Claude 本体（claudecode）
  timing: SubAgent 完了後、次の操作前

禁止:
  - SubAgent が progress.json を直接更新する
  - Hook が progress.json を自動更新する（読み取りのみ）

理由:
  - SubAgent はツール制限で Edit 権限がない場合がある
  - Hook は情報を提供するが、状態変更は Claude の責務
  - Claude が orchestrator として状態管理を担当
```

### 更新タイミング

```yaml
1. subtask 作業開始時:
   Claude が subtasks[id].status を "in_progress" に更新

2. subtask 作業完了時:
   a. Claude が validations (technical/consistency/completeness) を記録
   b. Claude が critic SubAgent を呼び出し
   c. critic が PASS → Claude が validated_by: "critic" を設定
   d. Claude が subtasks[id].status を "done" に更新
   e. subtask-guard.sh が validated_by をチェック（ブロック機構）

3. phase 完了時:
   a. 全 subtask が done になったことを確認
   b. Claude が phases[id].status を "done" に更新
   c. 次 phase に進む or 全 phase done なら Post-Loop へ

4. playbook 完了時:
   a. SubagentStop または PostToolUse で検出
   b. archive-playbook.sh が自動実行（Post-Loop）
```

### 更新内容の詳細

```yaml
subtasks[id]:
  status: "pending" | "in_progress" | "done"
  validated_at: "{ISO8601 timestamp}"  # critic PASS 時に設定
  validated_by: "critic"               # critic PASS 時に設定
  validations:
    technical:
      status: "PASS" | "FAIL" | "PENDING"
      evidence: ["検証コマンドの出力", "..."]
    consistency:
      status: "PASS" | "FAIL" | "PENDING"
      evidence: ["整合性確認の結果", "..."]
    completeness:
      status: "PASS" | "FAIL" | "PENDING"
      evidence: ["完全性確認の結果", "..."]
  notes: "作業メモ"

phases[id]:
  status: "pending" | "in_progress" | "done"
  updated_at: "{ISO8601 timestamp}"
```

### SubagentStop 後のリマインダー

```yaml
SubagentStop Hook の役割:
  - SubAgent 完了を検出
  - Claude に progress.json 更新をリマインド（systemMessage）
  - 全 Phase done なら archive-playbook.sh を呼び出し

リマインダー内容:
  "SubAgent が完了しました。progress.json を更新してください:
   - subtasks[{id}].validations に結果を記録
   - critic PASS なら validated_by: 'critic' を設定
   - status を更新"
```

---

## 11.6 reviewer 検証記録フロー（playbook 確定）

> **設計思想**: reviewer SubAgent は playbook の品質を保証し、検証結果を plan.json に記録する。
> critic が subtask 完了を検証するのに対し、reviewer は playbook 全体の品質を検証する。

### reviewer の役割

```yaml
対象: playbook (plan.json)
タイミング: playbook 作成直後（pm が呼び出し）
検証内容:
  - 4QV+ 検証（形式・内容・整合性・完全性・批判的思考）
  - criterion の検証可能性
  - validation_plan の具体性
  - 報酬詐欺の可能性
```

### 検証記録フロー

```
1. pm が playbook 作成後、reviewer を呼び出し:
   Task(subagent_type='reviewer', prompt='play/<id>/plan.json を検証')

2. reviewer が 4QV+ 検証を実行:
   ├─→ Q1: 形式検証（JSON 構造、必須フィールド）
   ├─→ Q2: 内容検証（criterion が検証可能か）
   ├─→ Q3: 整合性検証（state.md との整合）
   ├─→ Q4: 完全性検証（done_when に漏れがないか）
   └─→ +: 批判的思考（報酬詐欺の可能性）

3. reviewer が PASS 判定した場合:
   a. plan.json の meta.reviewed を true に更新
   b. plan.json の meta.reviewed_by を "reviewer" に更新
   c. PASS 結果を返却

4. reviewer が FAIL 判定した場合:
   a. 問題点と修正案を Claude に返却
   b. Claude が修正後、再度 reviewer を呼び出し
   c. PASS するまでループ
```

### plan.json への記録

```yaml
meta:
  id: "example"
  branch: "feat/example"
  created: "YYYY-MM-DD"
  status: "active"           # draft -> active（reviewer PASS 後）
  review_profile: "standard"
  reviewed: true             # reviewer PASS 後に true
  reviewed_by: "reviewer"    # reviewer PASS 後に設定
  roles:
    orchestrator: "claudecode"
    worker: "codex"
    reviewer: "coderabbit"
    human: "user"
```

### reviewer Gate（enforcement）

```yaml
playbook-gate:
  condition: meta.reviewed == false
  action:
    - playbook に基づく作業をブロック
    - reviewer 検証を強制
  メカニズム:
    - pm が reviewer を呼び出すまで playbook は draft
    - reviewed: true でなければ playbook は確定しない
```

### critic との違い

| 項目 | reviewer | critic |
|------|----------|--------|
| 対象 | playbook (plan.json) | subtask 完了 (progress.json) |
| タイミング | playbook 作成直後 | subtask 完了時 |
| 記録先 | plan.json meta | progress.json subtasks |
| フィールド | reviewed, reviewed_by | validated_at, validated_by |
| 目的 | playbook 品質保証 | 成果物品質保証 |

---

## 11.7 Post-Loop 自動発火（playbook 完了時）

> **設計思想**: playbook の全 Phase が done になったら、自動的に archive → PR → merge → 次タスク導出を実行する。
> 手動介入なしで playbook サイクルを完結させる。

### 発火条件

```yaml
トリガー: PostToolUse:Edit (progress.json 更新時)
発火条件:
  - progress.json の全 phases[].status が "done"
  - progress.json の全 subtasks[].status が "done"
  - critic.status が "PASS"
  - final_tasks が存在する場合は全て done または skipped

ブロック条件（exit 2）:
  - 未完了の subtask がある場合
  - critic.status が PASS でない場合
```

### 処理順序（archive-playbook.sh）

```
1. 自動コミット（未コミット変更がある場合）
2. Push（PR 作成前に必要）
3. PR 作成（create-pr.sh）
3.5. バックグラウンドタスク クリーンアップ
4. Playbook アーカイブ（play/archive/ へ移動）
5. アーカイブのコミット
6. Push（アーカイブ分）
7. state.md 更新（playbook.active = null, goal セクションリセット）
8. state.md 更新のコミット
9. Push（state.md 分）
10. PR マージ（merge-pr.sh）
11. main 同期（checkout main && pull）
12. pending ファイル作成（post-loop-pending）
```

### pending ファイルの役割

```yaml
ファイル: .claude/session-state/post-loop-pending
目的: post-loop Skill の呼び出しを強制

内容:
  {
    "playbook": "example-v1",
    "archived_at": "2026-01-07T12:00:00+09:00",
    "status": "success",
    "branch": "feat/example-v1"
  }

使用フロー:
  1. archive-playbook.sh が pending ファイルを作成
  2. systemMessage で Claude に post-loop 呼び出しを指示
  3. Claude が Skill(skill='post-loop') を実行
  4. post-loop が pending ファイルを削除
  5. post-loop が次タスクを導出
```

### systemMessage による自動呼び出し

```yaml
archive-playbook.sh の出力:
  {
    "status": "success",
    "message": "自動処理完了",
    "systemMessage": "今すぐ Skill(skill='post-loop') を呼び出すこと"
  }

Claude の動作:
  - systemMessage を受け取り、post-loop Skill を自動実行
  - ユーザーに確認を求めない（自動実行）
```

### post-loop Skill の責務

```yaml
入力: pending ファイル
出力:
  - pending ファイル削除
  - 次タスクの導出（以下のいずれか）:
    - 新しいタスクの提案
    - 完了報告
    - 待機状態への遷移
```

### ファイルパス

| ファイル | 役割 |
|----------|------|
| .claude/skills/playbook-gate/workflow/archive-playbook.sh | Post-Loop 自動発火 |
| .claude/skills/post-loop/SKILL.md | post-loop Skill |
| .claude/session-state/post-loop-pending | pending ファイル |

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


## 13. 補助モジュール（MECE 補完）

### utility 層（共通関数）

```

scripts/
└── contract.sh        # 契約チェック関数（ALLOW/WARN/BLOCK）
```

### config 層

```
.claude/
├── agents/            # Task が参照する SubAgent 登録ディレクトリ
├── settings.json      # Claude Code 設定（Hooks 定義）
├── protected-files.txt # HARD_BLOCK 対象ファイルリスト
└── .session-init/     # セッション初期化状態

.mcp.json              # MCP サーバー設定（Codex 等）
```

---

## 14. 既知の課題と未実装

> **監査日**: 2026-01-02

### 14.1 存在しないファイルへの参照

| 参照元 | 参照先 | 状態 | 影響度 |
|--------|--------|------|--------|
| playbook-guard.sh (行 107, 138, 171) | .claude/hooks/failure-logger.sh | ❌ 不存在 | 低（存在チェックあり） |
| cleanup.sh (行 85) | .claude/skills/playbook-gate/workflow/generate-repository-map.sh | ❌ 不存在 | 中（自動更新が無効） |
| access-control/SKILL.md | .claude/skills/access-control/lib/contract.sh | ❌ 不存在 | 低（文書不整合） |

**備考**: failure-logger.sh は存在チェック `[[ -f ... ]]` でガードされているため、不存在でも機能に影響なし。

### 14.2 設計されたが未実装の機能

| 機能 | 設計箇所 | 状態 | 推奨対応 |
|------|---------|------|---------|
| failure-logger.sh | playbook-guard.sh から参照 | 未実装 | 実装または参照削除 |
| doc-freshness-check.sh | 設計構想 | 未実装 | 要件定義後に検討 |
| update-tracker.sh | 設計構想 | 未実装 | git diff で代替可能 |

### 14.3 Hook イベント（no-op chain）

| Hook | 状態 | 理由 |
|------|------|------|
| Stop | ✅ 実装済み | completion-check.sh で未完了 subtask 検出 |
| SessionEnd | 登録済み | 連携先が未実装のため no-op |
| Notification | 登録済み | 連携先が未実装のため no-op |

### 14.4 設計と実装の乖離

| セクション | 設計 | 実装状態 |
|-----------|------|---------|
| Section 1 (SessionStart) | health.sh を SessionStart から自動呼び出し | ✅ 実装済み（session-manager/handlers/start.sh） |
| Playbook v2 (golden-path) | play/<id>/plan.json + progress.json を使用 | ✅ pm が play/<id>/plan.json + progress.json を生成 |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-06 | prompt-analyzer 強制条件の明文化・playbook v2/legacy 乖離を追記 |
| 2026-01-06 | playbook v2(JSON) の guards/workflow/agents を更新 |
| 2026-01-06 | SessionStart で health/integrity を自動実行 |
| 2026-01-04 | repository-map 更新 |
| 2026-01-02 | Section 14「既知の課題と未実装」追加（リポジトリ監査結果） |
| 2026-01-02 | Skills 全面追記: core skills 追加 |
| 2026-01-02 | SubAgents 追記: prompt-analyzer, executor-resolver |
| 2026-01-02 | 既存 Skills 補完: role-resolver.sh, merge-pr.sh, integrity.sh 等 |
| 2026-01-02 | PreCompact 設計更新: snapshot.json 廃止、最小ポインタ（additionalContext のみ）に変更 |
| 2026-01-02 | session-manager/handlers に end.sh, compact.sh 追記 |
| 2025-12-25 | post-loop 自動発火: archive-playbook.sh 自動実行、pending-guard.sh 追加 |
| 2025-12-25 | 公式 Hook リファレンス追加（イベント一覧、入力 JSON、exit code） |
| 2025-12-25 | 全面改訂: ユーザー体験ベースの状態遷移マップに変更 |
| 2025-12-24 | docs 整理: 重複ファイル削除、統計値更新 |
| 2025-12-18 | 初版作成（cleanup/architecture-audit） |
