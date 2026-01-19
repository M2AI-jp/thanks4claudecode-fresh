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

### ⚠️ 構築順序の重要原則

**最終形は「Hook → Skills → モジュール化された機能」だが、構築順序は逆である。**

```
❌ 間違った順序（このリポジトリの失敗例）:
   Hook 基盤 → ガード → 機能
   → Hook が他機能の開発・デバッグを阻害する

✅ 正しい順序:
   1. 単機能として構成・テスト
   2. Skills 単位でモジュール化・手動テスト
   3. 最後に Hook で制御
```

**なぜこの順序か**:

| 順序 | やること | 理由 |
|------|----------|------|
| **1. 単機能** | ガードスクリプト、SubAgent を個別に作成・動作確認 | 各部品が正しく動くか確認してから組み合わせる |
| **2. Skills** | 機能をパッケージ化し、手動で呼び出してテスト | Hook なしで `/skill-name` や手動実行で検証 |
| **3. Hook** | すべて動作確認できてから Hook を接続 | Hook は「発火タイミング」のみ担当、機能は確立済み |

**失敗パターン**:
- Hook を先に入れると、playbook-guard が Edit をブロック → playbook 機能自体の開発ができない
- main-branch ガードを先に入れると、テスト中の修正も全部ブロックされる
- デバッグのために Hook を無効化する作業が発生し、本末転倒になる

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

> ⚠️ **重要**: Phase の順序は「単機能 → Skills → Hook」である。Hook を先に入れると開発を阻害する。

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

**⚠️ この Phase では Hook を設定しない**（settings.json の hooks は空のまま）

**作成ファイル**:
```
プロジェクト/
├── CLAUDE.md
├── state.md           # 現在状態の真実源（SSOT）
└── .claude/
    └── settings.json  # 権限設定のみ（hooks は空）
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

**settings.json（Hook なし）**:
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

# hooks が空であることを確認（この Phase では重要）
jq '.hooks | keys | length' .claude/settings.json
# 期待値: 0
```

**検証基準**:
- state.md が存在し、必須セクションがある
- settings.json が有効な JSON
- **hooks は空のまま**

---

### Phase 2: SubAgent 単体構築

**目標**: SubAgent を個別に作成し、手動で動作確認

**依存**: Phase 1

**⚠️ Hook 経由ではなく、手動で `Task()` を呼び出してテストする**

**作成ファイル**:
```
.claude/
└── agents/
    ├── pm.md          # Project Manager SubAgent
    ├── reviewer.md    # Reviewer SubAgent
    └── critic.md      # Critic SubAgent（検証専門）
```

**pm.md の例**:
```markdown
---
name: pm
description: playbook を作成・管理する Project Manager
tools: Read, Write, Edit, Grep, Glob, Bash
---

# PM SubAgent

## 役割
ユーザーの依頼を分析し、playbook（plan.json）を作成する。

## プロセス
1. 依頼内容を理解
2. done_when（完了条件）を定義
3. phases と subtasks に分解
4. plan.json を作成
```

**reviewer.md の例**:
```markdown
---
name: reviewer
description: playbook の品質を検証する Reviewer
tools: Read, Grep, Glob, Bash
---

# Reviewer SubAgent

## 役割
playbook が品質基準を満たしているかを検証する。

## 検証項目
- done_when が検証可能か
- phases の依存関係が正しいか
- scope が明確か
```

**critic.md の例**:
```markdown
---
name: critic
description: 成果物が done_criteria を満たしているかを敵対的に検証
tools: Read, Grep, Bash
---

# Critic SubAgent

## 役割
成果物が done_criteria を満たしているかを**敵対的に**検証する。

## ツール制限
- Edit/Write: **禁止**（自己完了を防止）

## 検証プロセス
1. done_criteria を読み込む
2. 各 criterion を検証コマンドで確認
3. 全て PASS なら PASS を返す
```

**検証方法（手動テスト）**:
```python
# Claude Code で手動実行

# pm SubAgent のテスト
Task(
  subagent_type='pm',
  prompt='テスト用の playbook を作成して: Hello World を出力する機能',
  description='pm テスト'
)

# reviewer SubAgent のテスト
Task(
  subagent_type='reviewer',
  prompt='play/test/plan.json を検証して',
  description='reviewer テスト'
)

# critic SubAgent のテスト
Task(
  subagent_type='critic',
  prompt='以下の criterion を検証して: "README.md が存在する"',
  description='critic テスト'
)
```

**検証基準**:
- 各 SubAgent が Task() で呼び出せる
- pm が playbook を作成できる
- reviewer が playbook を検証できる
- critic が criterion を検証できる（Edit/Write なしで）

---

### Phase 3: ガードスクリプト単体構築

**目標**: ガードスクリプトを個別に作成し、手動で動作確認

**依存**: Phase 2

**⚠️ Hook に接続せず、スクリプト単体でテストする**

**作成ファイル**:
```
.claude/
├── protected-files.txt        # 保護ファイルリスト
└── scripts/                   # 単体テスト用（後で skills/ に移動）
    ├── main-branch-guard.sh   # main ブランチ保護
    ├── protected-edit-guard.sh # 保護ファイル編集ブロック
    └── playbook-guard.sh      # playbook 必須チェック
```

**main-branch-guard.sh**:
```bash
#!/bin/bash
set -euo pipefail

BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  echo "BLOCK: main/master ブランチでの編集は禁止" >&2
  exit 2
fi

echo "ALLOW: ブランチ $BRANCH"
exit 0
```

**playbook-guard.sh**:
```bash
#!/bin/bash
set -euo pipefail

STATE_FILE="${1:-state.md}"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "BLOCK: state.md が存在しない" >&2
  exit 2
fi

PLAYBOOK_ACTIVE=$(grep -A1 "^## playbook" "$STATE_FILE" | grep "active:" | sed 's/.*active: //' || echo "null")

if [[ -z "$PLAYBOOK_ACTIVE" || "$PLAYBOOK_ACTIVE" == "null" ]]; then
  echo "BLOCK: playbook がありません" >&2
  exit 2
fi

echo "ALLOW: playbook=$PLAYBOOK_ACTIVE"
exit 0
```

**検証方法（スクリプト単体テスト）**:
```bash
# main-branch-guard のテスト
git checkout main
bash .claude/scripts/main-branch-guard.sh
# 期待: exit 2（BLOCK）

git checkout -b test-branch
bash .claude/scripts/main-branch-guard.sh
# 期待: exit 0（ALLOW）

# playbook-guard のテスト（playbook なし）
echo -e "## playbook\n- active: null" > /tmp/test-state.md
bash .claude/scripts/playbook-guard.sh /tmp/test-state.md
# 期待: exit 2（BLOCK）

# playbook-guard のテスト（playbook あり）
echo -e "## playbook\n- active: play/test/plan.json" > /tmp/test-state.md
bash .claude/scripts/playbook-guard.sh /tmp/test-state.md
# 期待: exit 0（ALLOW）
```

**検証基準**:
- 各スクリプトが単体で正しく動作する
- exit code が正しい（0=ALLOW, 2=BLOCK）
- **Hook なしで動作確認できている**

---

### Phase 4: playbook システム構築

**目標**: playbook テンプレートと SubAgent の連携をテスト

**依存**: Phase 2, Phase 3

**⚠️ まだ Hook は接続しない。手動で SubAgent を呼び出して連携テスト**

**作成ファイル**:
```
play/
├── template/
│   ├── plan.json      # playbook テンプレート
│   └── progress.json  # 進捗テンプレート
└── README.md
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

**検証方法（SubAgent 連携テスト）**:
```python
# 1. pm で playbook を作成
Task(
  subagent_type='pm',
  prompt='「README.md に Hello World を追加」という playbook を作成して',
  description='playbook 作成'
)

# 2. reviewer で playbook を検証
Task(
  subagent_type='reviewer',
  prompt='play/hello-world/plan.json を検証して',
  description='playbook 検証'
)

# 3. 実際に作業を実行（手動）
# README.md に Hello World を追加

# 4. critic で完了を検証
Task(
  subagent_type='critic',
  prompt='play/hello-world/plan.json の done_when を検証して',
  description='完了検証'
)
```

**検証基準**:
- pm → reviewer → 作業 → critic の流れが動作する
- 各 SubAgent が期待通りの出力を返す
- **まだ Hook による自動化はしない**

---

### Phase 5: Skills モジュール化

**目標**: 機能を Skills パッケージに整理し、手動呼び出しでテスト

**依存**: Phase 3, Phase 4

**⚠️ Skill ツールで手動呼び出し、または `/skill-name` でテスト**

**作成ファイル**:
```
.claude/skills/
├── access-control/
│   ├── SKILL.md
│   └── guards/
│       ├── main-branch.sh      # Phase 3 から移動
│       └── protected-edit.sh
├── playbook-gate/
│   ├── SKILL.md
│   └── guards/
│       └── playbook-guard.sh   # Phase 3 から移動
├── golden-path/
│   ├── SKILL.md
│   └── agents/
│       └── pm.md               # Phase 2 から移動
├── quality-assurance/
│   ├── SKILL.md
│   └── agents/
│       └── reviewer.md         # Phase 2 から移動
└── reward-guard/
    ├── SKILL.md
    └── agents/
        └── critic.md           # Phase 2 から移動
```

**SKILL.md の例（access-control）**:
```markdown
---
name: access-control
description: main ブランチ保護、保護ファイル編集ブロック
user-invocable: false
---

# Access Control Skill

## 機能
- main/master ブランチでの編集をブロック
- protected-files.txt に記載されたファイルの編集をブロック

## 使用方法
このスキルは Hook 経由で自動実行される。
手動テストは以下:

\`\`\`bash
bash .claude/skills/access-control/guards/main-branch.sh
bash .claude/skills/access-control/guards/protected-edit.sh "path/to/file"
\`\`\`
```

**検証方法**:
```bash
# Skill 構造の確認
find .claude/skills -name "SKILL.md" | wc -l
# 期待: 5 以上

# 各 Skill のガードスクリプトが動作することを確認
bash .claude/skills/access-control/guards/main-branch.sh
bash .claude/skills/playbook-gate/guards/playbook-guard.sh state.md

# SubAgent が Skill ディレクトリから呼び出せることを確認
Task(subagent_type='pm', prompt='テスト', description='Skill 配置確認')
```

**検証基準**:
- 各 Skill に SKILL.md がある
- ガードスクリプトが Skill ディレクトリ内で動作する
- SubAgent が Skill 内の agents/ から参照できる
- **まだ Hook は接続しない**

---

### Phase 6: Hook 統合（最終段階）

**目標**: すべての機能が動作確認できてから、Hook を接続

**依存**: Phase 5（すべての機能が手動で動作確認済み）

**⚠️ この Phase が最後。ここまで来てから初めて Hook を有効化する**

**作成ファイル**:
```
.claude/
├── hooks/
│   ├── session.sh     # SessionStart dispatcher
│   ├── prompt.sh      # UserPromptSubmit dispatcher
│   ├── pre-tool.sh    # PreToolUse dispatcher
│   └── post-tool.sh   # PostToolUse dispatcher
└── events/
    ├── session-start/
    │   └── chain.sh
    ├── user-prompt-submit/
    │   └── chain.sh
    ├── pre-tool-edit/
    │   └── chain.sh
    └── post-tool-edit/
        └── chain.sh
```

**settings.json への Hook 追加（この Phase で初めて）**:
```json
{
  "permissions": {
    "defaultMode": "bypassPermissions",
    "allow": ["Edit", "Write", "Task(*)", "Bash(git:*)"]
  },
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

**pre-tool.sh（dispatcher）**:
```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

case "$TOOL_NAME" in
  Edit|Write)
    # Phase 5 で動作確認済みのガードを呼び出し
    bash .claude/skills/access-control/guards/main-branch.sh
    bash .claude/skills/playbook-gate/guards/playbook-guard.sh state.md
    ;;
  *)
    exit 0
    ;;
esac
```

**検証方法**:
```bash
# 1. Hook が正しく発火することを確認
# Claude Code を起動して Edit を試みる

# 2. main ブランチで Edit がブロックされることを確認
git checkout main
# Edit を試行 → ブロックされる

# 3. playbook なしで Edit がブロックされることを確認
# state.md の playbook.active を null にして Edit → ブロック

# 4. 正常系：playbook あり + feature ブランチで Edit が成功
git checkout -b feat/test
# state.md の playbook.active を設定
# Edit → 成功
```

**検証基準**:
- Hook が正しく発火する
- Phase 5 までに作成した機能が Hook 経由で動作する
- **Hook を有効化しても、機能自体のロジックは変わらない**（発火タイミングが変わるだけ）

---

### Phase 7: 自動化（Git ワークフロー）

**目標**: PR 作成・マージ・アーカイブを自動化

**依存**: Phase 6

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

**archive-playbook.sh の例**:
```bash
#!/bin/bash
set -euo pipefail

PLAYBOOK_ID=$1
SOURCE="play/${PLAYBOOK_ID}"
DEST="play/archive/${PLAYBOOK_ID}"

mkdir -p "$(dirname "$DEST")"
mv "$SOURCE" "$DEST"
sed -i '' 's/active: .*/active: null/' state.md
git add -A
git commit -m "archive: ${PLAYBOOK_ID}"

echo "Archived: ${PLAYBOOK_ID}"
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

> ⚠️ **重要**: 各 Phase の検証は **Hook なしで** 行う（Phase 6 まで）

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

# ⚠️ hooks が空であることを確認（この Phase では重要）
[[ $(jq '.hooks | keys | length' .claude/settings.json) -eq 0 ]] && echo "PASS: hooks empty" || echo "WARN: hooks should be empty"
```

### Phase 2 の検証（SubAgent 単体）
```bash
# SubAgent 定義が存在する
test -f .claude/agents/pm.md && echo "PASS: pm" || echo "FAIL"
test -f .claude/agents/reviewer.md && echo "PASS: reviewer" || echo "FAIL"
test -f .claude/agents/critic.md && echo "PASS: critic" || echo "FAIL"

# critic が Edit 権限を持たない
! grep -q "Edit" .claude/agents/critic.md && echo "PASS: critic no Edit" || echo "FAIL"
```

### Phase 3 の検証（ガードスクリプト単体）
```bash
# スクリプトが存在する
test -f .claude/scripts/main-branch-guard.sh && echo "PASS" || echo "FAIL"
test -f .claude/scripts/playbook-guard.sh && echo "PASS" || echo "FAIL"

# main-branch-guard の単体テスト
git checkout main
bash .claude/scripts/main-branch-guard.sh 2>/dev/null
[[ $? -eq 2 ]] && echo "PASS: main branch blocked" || echo "FAIL"

# ⚠️ Hook なしで動作確認できていることが重要
```

### Phase 4 の検証（playbook システム）
```bash
# playbook テンプレートが存在する
test -f play/template/plan.json && echo "PASS" || echo "FAIL"

# テンプレートが有効な JSON
jq '.' play/template/plan.json > /dev/null 2>&1 && echo "PASS" || echo "FAIL"

# ⚠️ SubAgent 連携を手動でテスト（Hook なし）
# Task(subagent_type='pm', prompt='テスト playbook 作成')
# Task(subagent_type='reviewer', prompt='検証')
# Task(subagent_type='critic', prompt='完了検証')
```

### Phase 5 の検証（Skills モジュール）
```bash
# Skill 構造が正しい
test -f .claude/skills/access-control/SKILL.md && echo "PASS" || echo "FAIL"
test -f .claude/skills/playbook-gate/SKILL.md && echo "PASS" || echo "FAIL"
test -f .claude/skills/golden-path/SKILL.md && echo "PASS" || echo "FAIL"

# ガードスクリプトが Skill ディレクトリに移動されている
test -f .claude/skills/access-control/guards/main-branch.sh && echo "PASS" || echo "FAIL"
test -f .claude/skills/playbook-gate/guards/playbook-guard.sh && echo "PASS" || echo "FAIL"

# ⚠️ まだ Hook は接続しない
```

### Phase 6 の検証（Hook 統合）
```bash
# ⚠️ この Phase で初めて Hook を有効化

# Hook スクリプトが存在する
test -f .claude/hooks/pre-tool.sh && echo "PASS" || echo "FAIL"
test -f .claude/hooks/session.sh && echo "PASS" || echo "FAIL"

# settings.json に hooks が定義されている
jq -e '.hooks.PreToolUse' .claude/settings.json > /dev/null 2>&1 && echo "PASS" || echo "FAIL"

# Hook 経由で既存機能が動作することを確認
# main ブランチで Edit → ブロック
# playbook なしで Edit → ブロック
```

### Phase 7 の検証（自動化）
```bash
# archive-playbook.sh が存在する
test -f .claude/skills/playbook-gate/workflow/archive-playbook.sh && echo "PASS" || echo "FAIL"

# git-workflow が存在する
test -f .claude/skills/git-workflow/handlers/create-pr.sh && echo "PASS" || echo "FAIL"
```

### 統合検証（Phase 6 完了後のみ）
```bash
# 全 Hook イベントが settings.json に定義されているか確認
HOOKS=$(jq -r '.hooks | keys[]' .claude/settings.json 2>/dev/null | sort | tr '\n' ' ')
echo "定義済み Hook: $HOOKS"
```

---

## 付録: 依存関係図

```
Phase 0: 最小環境
    │   └─ CLAUDE.md
    ▼
Phase 1: 状態管理（Hook なし）
    │   └─ state.md, settings.json（hooks: {}）
    ▼
Phase 2: SubAgent 単体（手動テスト）
    │   └─ pm.md, reviewer.md, critic.md
    │   └─ Task() で手動呼び出し
    ▼
Phase 3: ガードスクリプト単体（手動テスト）
    │   └─ main-branch-guard.sh, playbook-guard.sh
    │   └─ bash で直接実行
    ▼
Phase 4: playbook システム（手動テスト）
    │   └─ plan.json テンプレート
    │   └─ pm → reviewer → critic 連携
    ▼
Phase 5: Skills モジュール化（手動テスト）
    │   └─ .claude/skills/ に整理
    │   └─ SKILL.md 定義
    ▼
Phase 6: Hook 統合 ← ここで初めて Hook を有効化
    │   └─ hooks/, events/
    │   └─ settings.json に hooks 追加
    ▼
Phase 7: 自動化
        └─ git-workflow, archive
```

**重要**: Phase 1-5 は **Hook なし** で動作確認する。
Hook を先に入れると、機能開発・デバッグが阻害される。

---

## 変更履歴

| 日付 | 内容 |
|------|------|
| 2026-01-20 | **Phase 構成を根本修正**: 「単機能 → Skills → Hook」の順序に変更 |
| 2026-01-20 | 初版作成 |
