# BUILD-FROM-SCRATCH.md

> **逆引き設計図**: Claude Code フレームワークをゼロから構築するためのガイド
>
> 執筆日: 2026-01-20
> 対象: Claude Code CLI（https://code.claude.com/docs/）

---

## 目次

1. [概要](#1-概要)
2. [Claude Code 公式仕様](#2-claude-code-公式仕様)
3. [構築フェーズ](#3-構築フェーズ)
4. [公式仕様 vs 独自設計](#4-公式仕様-vs-独自設計)
5. [検証チェックリスト](#5-検証チェックリスト)

---

## 1. 概要

このドキュメントは、Claude Code を活用した自律運用フレームワークを**ゼロから再構築**する場合の設計図です。

### 設計思想

```
Hook（いつ発火するか）→ Skill（何をするか）→ SubAgent（誰が検証するか）
```

- **Hook**: イベント駆動の入口（公式仕様）
- **Skill**: ユースケース単位のパッケージ（独自設計）
- **SubAgent**: 独立した検証者（報酬詐欺防止）

### 前提知識

- Claude Code CLI の基本操作
- Shell スクリプト（bash）
- JSON/YAML の読み書き

---

## 2. Claude Code 公式仕様

> 参照: https://code.claude.com/docs/ja/hooks

### 2.1 Hook イベント一覧（9種類）

Claude Code は以下の9つのイベントタイミングで Hook を発火できます。

| # | イベント名 | 発火タイミング | マッチャー | 用途 |
|---|-----------|--------------|----------|------|
| 1 | **SessionStart** | セッション開始/再開時 | `startup`, `resume`, `clear`, `compact` | 初期化、状態復元 |
| 2 | **UserPromptSubmit** | ユーザープロンプト送信時（処理前） | なし | 入力検証、コンテキスト注入 |
| 3 | **PreToolUse** | ツール実行前（パラメータ決定後） | `Edit`, `Write`, `Bash` 等 | 安全性チェック、ブロック |
| 4 | **PostToolUse** | ツール正常完了直後 | `Edit`, `Write` 等 | 後処理、自動化 |
| 5 | **SubagentStop** | サブエージェント応答完了時 | なし | SubAgent 結果の処理 |
| 6 | **PreCompact** | コンパクト操作実行前 | `manual`, `auto` | コンテキスト保全 |
| 7 | **Stop** | メインエージェント応答完了時 | なし | 完了チェック |
| 8 | **SessionEnd** | セッション終了時 | なし | クリーンアップ |
| 9 | **Notification** | 通知送信時 | なし | ログ記録 |

### 2.2 Hook の入力パラメータ（stdin JSON）

```json
// 共通フィールド（全イベント）
{
  "session_id": "abc123",
  "cwd": "/path/to/project",
  "hook_event_name": "PreToolUse",
  "transcript_path": "/Users/.../xxxxx.jsonl"
}

// PreToolUse 固有
{
  "tool_name": "Edit",
  "tool_input": { "file_path": "...", "old_string": "...", "new_string": "..." }
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

### 2.3 Exit Code の意味

| Exit Code | 動作 | 用途 |
|-----------|------|------|
| **0** | 成功・続行 | ツール実行を許可 |
| **2** | ブロック | ツール実行をブロック、stderr を Claude に表示 |
| **その他** | エラー（続行） | stderr をユーザーに表示、実行は続行 |

### 2.4 JSON 出力（高度な制御）

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

### 2.5 settings.json の構造

```json
{
  "permissions": {
    "defaultMode": "bypassPermissions",
    "allow": ["Edit", "Write", "Task(*)", "Bash(git:*)"]
  },
  "enableAllProjectMcpServers": true,
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/pre-tool.sh",
            "timeout": 10000
          }
        ]
      }
    ]
  }
}
```

**設定項目**:
- `permissions`: ツール実行の許可設定
- `enableAllProjectMcpServers`: MCP サーバーの有効化
- `hooks`: Hook イベントごとのコマンド定義

### 2.6 SubAgent（Task ツール）

> 参照: https://code.claude.com/docs/ja/sub-agents

```python
Task(
  subagent_type='pm',  # SubAgent の種類
  prompt='タスクの内容',
  description='短い説明'
)
```

**SubAgent の登録**:
- `.claude/agents/` ディレクトリに `*.md` ファイルを配置
- Task ツールの `subagent_type` で参照

**ツール制限**:
```yaml
# SubAgent 定義の例（.claude/agents/critic.md）
tools:
  - Read
  - Grep
  - Bash
# Edit/Write を含めないことで、書き込み権限を制限
```

### 2.7 SubAgent 一覧と役割

**SubAgent の登録ディレクトリ**:
- `.claude/agents/` に `*.md` ファイルを配置
- Task ツールの `subagent_type` で参照

**主要 SubAgents**:

| SubAgent | 役割 | ツール制限 | 呼び出しタイミング |
|----------|------|-----------|------------------|
| **pm** | playbook 作成の中核 | Read, Write, Edit, Grep, Glob, Bash | タスク開始時 |
| **reviewer** | playbook 品質検証 | Read, Grep, Glob, Bash | playbook 作成後 |
| **critic** | done_criteria 検証（敵対的） | Read, Grep, Bash | subtask/phase 完了時 |
| **prompt-analyzer** | 依頼の意図解析 | Read, Grep | タスク開始時 |
| **executor-resolver** | executor 判定 | Read, Grep | playbook 作成時 |
| **codex-delegate** | Codex MCP への委譲 | Bash, mcp__codex__* | 実装委譲時 |
| **coderabbit-delegate** | CodeRabbit CLI への委譲 | Bash | レビュー委譲時 |

**SubAgent 呼び出し例**:
```python
# pm SubAgent を呼び出し
Task(
  subagent_type='pm',
  prompt='新しい playbook を作成してください: ユーザー認証機能の追加',
  description='playbook 作成'
)

# critic SubAgent を呼び出し（検証）
Task(
  subagent_type='critic',
  prompt='play/auth-feature/progress.json の p1.1 を検証してください',
  description='subtask 検証'
)
```

**SubAgent のツール制限の設計意図**:
```yaml
設計原則:
  - 検証系（critic, reviewer）: 書き込み権限なし → 自己完了を防止
  - 作成系（pm）: 必要最小限の書き込み権限
  - 分析系（prompt-analyzer, executor-resolver）: 読み取りのみ
  - 外部連携（codex-delegate, coderabbit-delegate）: 専用ツールのみ

報酬詐欺防止:
  - critic は Edit/Write を持たない
  - critic が PASS を出さない限り done にできない
  - 自分の作業を自分で「完了」と判定しない
```

**SubAgent 定義ファイルの例（.claude/agents/critic.md）**:
```markdown
# Critic SubAgent

## Purpose
成果物が done_criteria を満たしているかを敵対的に検証する。

## Tools
- Read
- Grep
- Bash

## Process
1. done_criteria を読み込む
2. 各 criterion の検証コマンドを実行
3. 結果を PASS/FAIL で返す

## Important
- 自分の作業を検証しない（独立性）
- 証拠なしに PASS を出さない
```

### 2.8 Skill ツール

> 参照: https://code.claude.com/docs/ja/skills（※公式仕様）

**Skill の概念**:
- **公式**: settings.json の `customSlashCommands` で `/command` を定義
- **独自拡張**: `.claude/skills/*/SKILL.md` で Skill パッケージを定義

```json
// settings.json での公式 Skill 定義
{
  "customSlashCommands": {
    "/commit": {
      "description": "コミットを作成",
      "command": "bash .claude/skills/git-workflow/handlers/commit.sh"
    }
  }
}
```

**このリポジトリの Skill 構造（独自設計）**:
```
.claude/skills/
├── access-control/     # 安全性ガード
│   ├── SKILL.md        # Skill 定義書
│   └── guards/         # ガードスクリプト
├── golden-path/        # タスク開始フロー
│   ├── SKILL.md
│   └── agents/         # SubAgent 定義
├── playbook-gate/      # playbook 必須チェック
│   ├── SKILL.md
│   ├── guards/
│   └── workflow/
├── reward-guard/       # 報酬詐欺防止
│   ├── SKILL.md
│   ├── agents/
│   └── guards/
└── session-manager/    # セッション管理
    ├── SKILL.md
    └── handlers/
```

**Skill パッケージの構成**:
| ディレクトリ | 役割 |
|------------|------|
| `SKILL.md` | Skill の定義・使用方法 |
| `agents/` | SubAgent 定義（*.md） |
| `guards/` | ガードスクリプト（*.sh） |
| `handlers/` | 処理スクリプト（*.sh） |
| `workflow/` | ワークフロースクリプト（*.sh） |

**主要 Skills 一覧**:
| Skill | 役割 | Hook との関係 |
|-------|------|--------------|
| session-manager | セッション初期化・終了 | SessionStart, SessionEnd |
| prompt-analyzer | 依頼の意図解析 | UserPromptSubmit |
| playbook-init | playbook 作成の入口 | UserPromptSubmit |
| golden-path | pm/reviewer の編成 | UserPromptSubmit |
| access-control | main ブランチ・保護ファイル | PreToolUse |
| playbook-gate | playbook 必須チェック | PreToolUse |
| reward-guard | critic 必須・報酬詐欺防止 | PreToolUse |
| quality-assurance | 品質検証 | SessionStart, PreToolUse |
| git-workflow | PR/マージ自動化 | PostToolUse |
| post-loop | 完了後の遷移ガード | PostToolUse |

### 2.8 CLAUDE.md の役割

- プロジェクトルートに配置
- Claude が自動的に読み込む
- プロジェクト固有の指示を記述

```markdown
# CLAUDE.md

## 目的
このプロジェクトは...

## 禁止事項
- 〜してはいけない

## 優先順位
1. Claude 組み込み安全性
2. CLAUDE.md
3. タスク固有指示
```

---

## 3. 構築フェーズ

### Phase 0: 最小動作環境

**目標**: Claude Code が動作する最小環境を構築

**作成ファイル**:
```
プロジェクト/
├── CLAUDE.md          # プロジェクト指示書
└── .gitignore
```

**CLAUDE.md の最小構成**:
```markdown
# CLAUDE.md

## 目的
[プロジェクトの目的を記述]

## 基本ルール
- 変更前に必ずファイルを読む
- テストを実行してから完了宣言する
```

**検証方法**:
```bash
# Claude Code を起動
claude

# 簡単な指示を実行
> CLAUDE.md を読んで内容を説明して
```

**検証基準**:
- Claude が CLAUDE.md を認識している
- 基本的なファイル操作ができる

---

### Phase 1: 状態管理の基盤

**目標**: セッション間で状態を保持する仕組みを構築

**依存**: Phase 0

**作成ファイル**:
```
プロジェクト/
├── CLAUDE.md
├── state.md           # 現在状態の真実源（SSOT）
└── .claude/
    └── settings.json  # Hook 設定
```

**state.md の構造**:
```markdown
# State

## playbook
- active: null
- branch: main

## session
- last_start: 2026-01-20T00:00:00+09:00
```

**settings.json の最小構成**:
```json
{
  "permissions": {
    "defaultMode": "bypassPermissions",
    "allow": ["Edit", "Write", "Bash(git:*)"]
  },
  "hooks": {}
}
```

**検証方法**:
```bash
# state.md が存在することを確認
test -f state.md && echo "exists"

# settings.json が有効な JSON であることを確認
jq '.' .claude/settings.json > /dev/null && echo "valid JSON"
```

**検証基準**:
- state.md が存在し、必須セクションがある
- settings.json が有効な JSON

---

### Phase 2: Hook 基盤

**目標**: Hook イベントに応じてスクリプトを実行する仕組みを構築

**依存**: Phase 1

**作成ファイル**:
```
.claude/
├── settings.json      # Hook 定義を追加
├── hooks/
│   ├── session.sh     # SessionStart dispatcher
│   ├── prompt.sh      # UserPromptSubmit dispatcher
│   ├── pre-tool.sh    # PreToolUse dispatcher
│   └── post-tool.sh   # PostToolUse dispatcher
└── events/
    ├── session-start/
    │   └── chain.sh   # SessionStart の処理チェーン
    ├── user-prompt-submit/
    │   └── chain.sh
    ├── pre-tool-edit/
    │   └── chain.sh
    └── post-tool-edit/
        └── chain.sh
```

**Hook dispatcher の基本形（pre-tool.sh）**:
```bash
#!/bin/bash
set -euo pipefail

# stdin から JSON を読み取り
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# ツール種別で分岐
case "$TOOL_NAME" in
  Edit|Write)
    bash .claude/events/pre-tool-edit/chain.sh <<< "$INPUT"
    ;;
  Bash)
    bash .claude/events/pre-tool-bash/chain.sh <<< "$INPUT"
    ;;
  *)
    exit 0  # その他は許可
    ;;
esac
```

**settings.json への Hook 追加**:
```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "bash .claude/hooks/session.sh",
        "timeout": 5000
      }]
    }],
    "PreToolUse": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "bash .claude/hooks/pre-tool.sh",
        "timeout": 10000
      }]
    }]
  }
}
```

**検証方法**:
```bash
# Hook スクリプトが存在することを確認
test -f .claude/hooks/pre-tool.sh && echo "exists"

# Hook スクリプトが実行可能であることを確認
bash -n .claude/hooks/pre-tool.sh && echo "syntax OK"

# settings.json に hooks が定義されていることを確認
jq '.hooks | keys | length' .claude/settings.json
# 期待値: >= 1
```

**検証基準**:
- 各 Hook スクリプトが構文エラーなし
- settings.json に hooks セクションがある
- SessionStart で state.md が読み込まれる

---

### Phase 3: 安全性ガード

**目標**: 破壊的操作をブロックする仕組みを構築

**依存**: Phase 2

**作成ファイル**:
```
.claude/
├── protected-files.txt        # 保護ファイルリスト
└── skills/
    └── access-control/
        └── guards/
            ├── main-branch.sh     # main ブランチ保護
            └── protected-edit.sh  # 保護ファイル編集ブロック
```

**main-branch.sh の例**:
```bash
#!/bin/bash
set -euo pipefail

BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  echo "main/master ブランチでの編集は禁止されています" >&2
  exit 2  # BLOCK
fi

exit 0  # ALLOW
```

**protected-files.txt の例**:
```
CLAUDE.md
.claude/protected-files.txt
```

**chain.sh への組み込み（pre-tool-edit/chain.sh）**:
```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# main ブランチチェック
bash .claude/skills/access-control/guards/main-branch.sh

# 保護ファイルチェック
if grep -qF "$FILE_PATH" .claude/protected-files.txt 2>/dev/null; then
  echo "保護ファイルは編集できません: $FILE_PATH" >&2
  exit 2
fi

exit 0
```

**検証方法**:
```bash
# main ブランチで Edit を試みてブロックされることを確認
git checkout main
# Claude で Edit を試行 → ブロックされる

# 保護ファイルの編集がブロックされることを確認
# Claude で CLAUDE.md の編集を試行 → ブロックされる
```

**検証基準**:
- main ブランチで Edit/Write がブロックされる
- protected-files.txt のファイルがブロックされる

---

### Phase 4: タスク管理（playbook）

**目標**: タスクの計画と進捗を管理する仕組みを構築

**依存**: Phase 3

**作成ファイル**:
```
play/
├── template/
│   ├── plan.json      # playbook テンプレート
│   └── progress.json  # 進捗テンプレート
└── README.md

.claude/
├── agents/
│   ├── pm.md          # Project Manager SubAgent
│   └── reviewer.md    # Reviewer SubAgent
└── skills/
    ├── golden-path/
    │   └── agents/
    │       └── pm.md
    ├── quality-assurance/
    │   └── agents/
    │       └── reviewer.md
    └── playbook-gate/
        └── guards/
            └── playbook-guard.sh  # playbook 必須チェック
```

**plan.json テンプレート**:
```json
{
  "format_version": "2.2",
  "meta": {
    "id": "example",
    "branch": "feat/example",
    "created": "YYYY-MM-DD",
    "status": "active",
    "reviewed": false,
    "reviewed_by": ""
  },
  "goal": {
    "summary": "タスクの概要",
    "done_when": [
      {
        "criterion": "完了条件（検証可能な文）",
        "command": "検証コマンド",
        "expected": "期待される出力"
      }
    ]
  },
  "phases": [
    {
      "id": "p1",
      "name": "Phase 1",
      "subtasks": [
        {
          "id": "p1.1",
          "criterion": "サブタスクの完了条件",
          "executor": "claudecode"
        }
      ]
    }
  ]
}
```

**playbook-guard.sh の例**:
```bash
#!/bin/bash
set -euo pipefail

PLAYBOOK_ACTIVE=$(grep -A1 "^## playbook" state.md | grep "active:" | sed 's/.*active: //')

if [[ -z "$PLAYBOOK_ACTIVE" || "$PLAYBOOK_ACTIVE" == "null" ]]; then
  echo "playbook がありません。先に playbook を作成してください。" >&2
  exit 2  # BLOCK
fi

exit 0
```

**検証方法**:
```bash
# playbook テンプレートが存在することを確認
test -f play/template/plan.json && echo "exists"

# テンプレートが有効な JSON であることを確認
jq '.' play/template/plan.json > /dev/null && echo "valid"

# SubAgent 定義が存在することを確認
test -f .claude/agents/pm.md && echo "pm exists"
test -f .claude/agents/reviewer.md && echo "reviewer exists"
```

**検証基準**:
- play/template/ にテンプレートがある
- SubAgent が Task(subagent_type='pm') で呼び出せる
- playbook なしで Edit がブロックされる

---

### Phase 5: 検証システム

**目標**: 自己承認バイアスを防ぐ独立検証の仕組みを構築

**依存**: Phase 4

**作成ファイル**:
```
.claude/
├── agents/
│   └── critic.md      # Critic SubAgent（検証専門）
├── skills/
│   └── reward-guard/
│       ├── agents/
│       │   └── critic.md
│       └── guards/
│           ├── critic-guard.sh    # done 変更前に critic 必須
│           └── subtask-guard.sh   # subtask 検証チェック
└── frameworks/
    └── done-criteria-validation.md  # 検証基準
```

**critic.md の例**:
```markdown
# Critic SubAgent

## 役割
成果物が done_criteria を満たしているかを**敵対的に**検証する。

## ツール制限
- Read: 許可
- Grep: 許可
- Bash: 許可（読み取り系コマンドのみ）
- Edit/Write: **禁止**（自己完了を防止）

## 検証プロセス
1. done_criteria を読み込む
2. 各 criterion を検証コマンドで確認
3. 全て PASS なら PASS を返す
4. 1つでも FAIL があれば FAIL を返す

## 出力形式
PASS または FAIL + 証拠
```

**critic-guard.sh の例**:
```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')

# "done" への変更を検出
if echo "$NEW_CONTENT" | grep -q '"status".*:.*"done"'; then
  echo "done への変更には critic の PASS が必要です" >&2
  echo '{"systemMessage": "Task(subagent_type=\"critic\") を先に実行してください"}'
  exit 0  # WARN（ブロックではなく警告）
fi

exit 0
```

**検証方法**:
```bash
# critic SubAgent が存在することを確認
test -f .claude/agents/critic.md && echo "exists"

# critic が Edit 権限を持っていないことを確認
grep -c "Edit" .claude/agents/critic.md
# 期待値: tools セクションに Edit がない

# done-criteria-validation.md が存在することを確認
test -f .claude/frameworks/done-criteria-validation.md && echo "exists"
```

**検証基準**:
- critic SubAgent が Edit/Write 権限を持たない
- done 変更時に critic が必要と通知される
- critic の PASS なしで完了宣言できない

---

### Phase 6: 自動化（Git ワークフロー）

**目標**: PR 作成・マージ・アーカイブを自動化

**依存**: Phase 5

**作成ファイル**:
```
.claude/
└── skills/
    ├── git-workflow/
    │   └── handlers/
    │       ├── create-pr.sh   # PR 作成
    │       └── merge-pr.sh    # PR マージ
    └── playbook-gate/
        └── workflow/
            └── archive-playbook.sh  # playbook アーカイブ
```

**archive-playbook.sh の例（簡略版）**:
```bash
#!/bin/bash
set -euo pipefail

PLAYBOOK_ID=$1
SOURCE="play/${PLAYBOOK_ID}"
DEST="play/archive/${PLAYBOOK_ID}"

# 1. アーカイブディレクトリへ移動
mkdir -p "$(dirname "$DEST")"
mv "$SOURCE" "$DEST"

# 2. state.md を更新
sed -i '' 's/active: .*/active: null/' state.md

# 3. コミット
git add -A
git commit -m "archive: ${PLAYBOOK_ID}"

echo "Archived: ${PLAYBOOK_ID}"
```

**検証方法**:
```bash
# git-workflow スクリプトが存在することを確認
test -f .claude/skills/git-workflow/handlers/create-pr.sh && echo "exists"

# archive-playbook.sh が存在することを確認
test -f .claude/skills/playbook-gate/workflow/archive-playbook.sh && echo "exists"

# スクリプトの構文チェック
bash -n .claude/skills/playbook-gate/workflow/archive-playbook.sh && echo "syntax OK"
```

**検証基準**:
- playbook 完了時に自動アーカイブされる
- PR が自動作成される
- state.md が自動更新される

---

## 4. 公式仕様 vs 独自設計

### 公式仕様（Claude Code が提供）

| 機能 | 説明 | 参照 |
|-----|------|-----|
| Hook イベント | 9種類のイベントタイミング | https://code.claude.com/docs/ja/hooks |
| settings.json | Hook 定義、権限設定 | https://code.claude.com/docs/ja/settings |
| SubAgent | Task ツールで専門エージェントを呼び出し | https://code.claude.com/docs/ja/sub-agents |
| CLAUDE.md | プロジェクト指示書 | https://code.claude.com/docs/ja/claude-md |

### 独自設計（このリポジトリ固有）

| 機能 | 説明 | 目的 |
|-----|------|-----|
| Event Unit | Hook → chain → Skill の階層構造 | 疎結合の維持 |
| playbook | plan.json + progress.json によるタスク管理 | 状態の永続化 |
| state.md | 現在状態の Single Source of Truth | セッション間の状態保持 |
| Golden Path | playbook-init → pm → reviewer の必須チェーン | 品質保証 |
| Reward Guard | critic による独立検証 | 報酬詐欺防止 |
| Playbook Gate | playbook なしで Edit をブロック | 計画なき実装の防止 |

---

## 5. 検証チェックリスト

### Phase 0 の検証
```bash
# CLAUDE.md が存在する
test -f CLAUDE.md && echo "PASS" || echo "FAIL"
```

### Phase 1 の検証
```bash
# state.md が存在する
test -f state.md && echo "PASS" || echo "FAIL"

# settings.json が有効
jq '.' .claude/settings.json > /dev/null 2>&1 && echo "PASS" || echo "FAIL"
```

### Phase 2 の検証
```bash
# Hook スクリプトが存在する
test -f .claude/hooks/pre-tool.sh && echo "PASS" || echo "FAIL"

# settings.json に hooks が定義されている
jq -e '.hooks' .claude/settings.json > /dev/null 2>&1 && echo "PASS" || echo "FAIL"
```

### Phase 3 の検証
```bash
# main-branch.sh が存在する
test -f .claude/skills/access-control/guards/main-branch.sh && echo "PASS" || echo "FAIL"

# protected-files.txt が存在する
test -f .claude/protected-files.txt && echo "PASS" || echo "FAIL"
```

### Phase 4 の検証
```bash
# playbook テンプレートが存在する
test -f play/template/plan.json && echo "PASS" || echo "FAIL"

# pm SubAgent が存在する
test -f .claude/agents/pm.md && echo "PASS" || echo "FAIL"
```

### Phase 5 の検証
```bash
# critic SubAgent が存在する
test -f .claude/agents/critic.md && echo "PASS" || echo "FAIL"

# critic が Edit 権限を持たない
! grep -q "Edit" .claude/agents/critic.md && echo "PASS" || echo "FAIL"
```

### Phase 6 の検証
```bash
# archive-playbook.sh が存在する
test -f .claude/skills/playbook-gate/workflow/archive-playbook.sh && echo "PASS" || echo "FAIL"
```

### 統合検証
```bash
# 全 Hook イベントが settings.json に定義されているか確認
HOOKS=$(jq -r '.hooks | keys[]' .claude/settings.json 2>/dev/null | sort | tr '\n' ' ')
echo "定義済み Hook: $HOOKS"
# 期待: SessionStart UserPromptSubmit PreToolUse PostToolUse SubagentStop PreCompact Stop SessionEnd Notification
```

---

## 付録: 依存関係図

```
Phase 0: 最小環境
    │
    ▼
Phase 1: 状態管理
    │   └─ state.md, settings.json
    ▼
Phase 2: Hook 基盤
    │   └─ Hook dispatcher, Event chain
    ▼
Phase 3: 安全性ガード
    │   └─ access-control, playbook-gate
    ▼
Phase 4: タスク管理
    │   └─ playbook, pm, reviewer
    ▼
Phase 5: 検証システム
    │   └─ critic, reward-guard
    ▼
Phase 6: 自動化
        └─ git-workflow, archive
```

---

## 変更履歴

| 日付 | 内容 |
|------|------|
| 2026-01-20 | 初版作成 |
