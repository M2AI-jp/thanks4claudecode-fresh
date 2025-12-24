# 4QV+ アーキテクチャ設計書

> **Hook（導火線）→ Skill（ユースケース単位のパッケージ）→ 必要な機能の詰め合わせ**
>
> Skills は SubAgents をオーケストレートし、各 SubAgent は独自のコンテキストを持つ。
> これにより親セッションのコンテキストを節約できる。

---

## 1. 設計原則

### 1.1 Core Concept

```yaml
4QV+ Architecture:
  Hook: 導火線（トリガーのみ、ロジックを持たない）
  Skill: ユースケース単位のパッケージ（関連機能の詰め合わせ）
  SubAgent: Skill 内に配置、独自コンテキストで動作

Key Insight:
  - "機能別" ではなく "ユースケース/ワークフロー単位" で整理
  - 既に確立している「塊」をそのまま Skill にする
  - SubAgents は Skill 内の agents/ フォルダに配置可能（undocumented but works）
```

### 1.2 Core Contract との対応

このリポジトリの核心（CLAUDE.md Core Contract）：

| Core Contract | 対応 Skill | 役割 |
|---------------|------------|------|
| Golden Path | golden-path/ | タスク依頼 → pm → playbook 作成 |
| Playbook Gate | playbook-gate/ | playbook なしでの変更をブロック |
| Reward Fraud Prevention | reward-guard/ | critic PASS なしで done にできない |

---

## 2. ディレクトリ構造

### 2.1 全体構造

```
.claude/
├── hooks/                              ← 導火線のみ（4個）
│   ├── pre-tool.sh                     ← PreToolUse(*) 導火線
│   ├── post-tool.sh                    ← PostToolUse(*) 導火線
│   ├── session.sh                      ← SessionStart/End/PreCompact 導火線
│   └── prompt.sh                       ← UserPromptSubmit 導火線
│
├── skills/                             ← ユースケース単位のパッケージ（7個）
│   ├── golden-path/                    ★ Core Contract #1
│   ├── playbook-gate/                  ★ Core Contract #2
│   ├── reward-guard/                   ★ Core Contract #3
│   ├── access-control/                 ★ アクセス制御
│   ├── session-manager/                ★ セッション管理
│   ├── git-workflow/                   ★ Git/PR ワークフロー
│   └── quality-assurance/              ★ 品質保証
│
└── agents/                             ← 空（全て Skills に統合）
```

### 2.2 各 Skill の詳細構造

#### golden-path/ - Core Contract #1: Golden Path

```
golden-path/
│
│   「タスク依頼 → pm → playbook 作成」のワークフロー
│
├── SKILL.md                    ← Skill 定義・使用方法
├── workflow/
│   ├── task-start.sh           ← タスク開始フロー
│   └── playbook-init.sh        ← playbook 初期化
└── agents/
    └── pm.md                   ← pm SubAgent（playbook 作成）

発火条件:
  - ユーザーがタスクを依頼した時
  - playbook が null の状態で作業開始しようとした時

責務:
  - playbook の作成を強制
  - pm SubAgent をオーケストレート
  - タスク開始の標準フローを提供
```

#### playbook-gate/ - Core Contract #2: Playbook Gate

```
playbook-gate/
│
│   「playbook なしでの変更をブロック」のワークフロー
│
├── SKILL.md
├── guards/
│   ├── playbook-guard.sh       ← playbook 必須チェック
│   ├── executor-guard.sh       ← executor 強制（claudecode/codex/user）
│   ├── depends-check.sh        ← Phase 依存関係チェック
│   └── role-resolver.sh        ← executor 名解決
└── workflow/
    ├── archive.sh              ← playbook 完了時アーカイブ
    └── cleanup.sh              ← テンポラリクリーンアップ

発火条件:
  - Edit/Write ツール使用時（PreToolUse）
  - playbook 完了時（PostToolUse）

責務:
  - playbook なしでの Edit/Write をブロック
  - executor に応じた作業制御
  - 完了した playbook のアーカイブ
```

#### reward-guard/ - Core Contract #3: Reward Fraud Prevention

```
reward-guard/
│
│   「報酬詐欺防止」のワークフロー
│
├── SKILL.md
├── guards/
│   ├── critic-guard.sh         ← state: done 変更前チェック
│   ├── subtask-guard.sh        ← subtask 完了時 3検証強制
│   ├── scope-guard.sh          ← スコープ変更検出
│   └── coherence.sh            ← state-playbook 整合性チェック
└── agents/
    └── critic.md               ← critic SubAgent（done_when 検証）

発火条件:
  - state: done に変更しようとした時
  - subtask を完了にしようとした時
  - done_criteria/done_when を変更しようとした時

責務:
  - 証拠なしの done を防止
  - subtask 完了時の 3 検証（technical/consistency/completeness）
  - スコープクリープ検出
  - critic SubAgent による最終検証
```

#### access-control/ - アクセス制御

```
access-control/
│
│   「保護・ブランチ・契約」のワークフロー
│
├── SKILL.md
├── guards/
│   ├── protected-edit.sh       ← 保護ファイル編集ブロック
│   ├── main-branch.sh          ← main ブランチ作業禁止
│   └── bash-check.sh           ← Bash 契約チェック
└── lib/
    └── contract.sh             ← 契約判定ロジック

発火条件:
  - 全ての Edit/Write/Bash ツール使用時

責務:
  - HARD_BLOCK ファイルの保護（CLAUDE.md 等）
  - main ブランチでの直接作業禁止
  - 危険な Bash コマンドのブロック
```

#### session-manager/ - セッション管理

```
session-manager/
│
│   「セッション開始〜終了」のワークフロー
│
├── SKILL.md
└── handlers/
    ├── init-guard.sh           ← 必須ファイル Read 強制
    ├── start.sh                ← セッション開始処理
    ├── end.sh                  ← セッション終了処理
    └── compact.sh              ← compact 前スナップショット保存

発火条件:
  - SessionStart イベント
  - SessionEnd イベント
  - PreCompact イベント

責務:
  - 必須ファイル（state.md, playbook）の Read 強制
  - セッション状態の追跡
  - compact 前の状態保存・復元
```

#### git-workflow/ - Git/PR ワークフロー

```
git-workflow/
│
│   「PR 作成〜マージ」のワークフロー
│
├── SKILL.md
└── handlers/
    ├── create-pr.sh            ← PR 作成
    ├── merge-pr.sh             ← PR マージ
    └── post-merge.sh           ← マージ後処理（main checkout + pull）

発火条件:
  - playbook 完了後（PostToolUse:Edit）
  - ユーザーが PR 作成/マージを指示した時

責務:
  - PR の自動作成
  - PR のマージ
  - マージ後の main ブランチ同期
```

#### quality-assurance/ - 品質保証

```
quality-assurance/
│
│   「レビュー・チェック」のワークフロー
│
├── SKILL.md
├── checkers/
│   ├── lint.sh                 ← 静的解析チェック
│   ├── integrity.sh            ← 参照整合性チェック
│   └── health.sh               ← システムヘルスチェック
└── agents/
    ├── reviewer.md             ← reviewer SubAgent（コードレビュー）
    └── health-checker.md       ← health-checker SubAgent（システム監視）

発火条件:
  - git commit 前（PreToolUse:Bash）
  - ユーザーがレビューを依頼した時

責務:
  - コード品質チェック
  - 参照整合性の検証
  - システムヘルスの監視
```

---

## 3. 導火線 Hook 設計

### 3.1 pre-tool.sh

```bash
#!/bin/bash
# pre-tool.sh - PreToolUse(*) 導火線
# 適切な Skills を順次呼び出す

SKILLS_DIR=".claude/skills"
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Skill を呼び出す関数
invoke_skill() {
    local skill="$1"
    local script="$2"
    local path="$SKILLS_DIR/$skill/$script"
    [[ -x "$path" ]] && echo "$INPUT" | bash "$path"
}

# 1. session-manager: init-guard（全ツール共通）
invoke_skill "session-manager" "handlers/init-guard.sh" || exit $?

# 2. access-control: ブランチ・保護チェック
invoke_skill "access-control" "guards/main-branch.sh" || exit $?

case "$TOOL_NAME" in
    Edit|Write)
        invoke_skill "access-control" "guards/protected-edit.sh" || exit $?
        invoke_skill "playbook-gate" "guards/playbook-guard.sh" || exit $?
        invoke_skill "playbook-gate" "guards/depends-check.sh" || exit $?
        invoke_skill "playbook-gate" "guards/executor-guard.sh" || exit $?
        invoke_skill "reward-guard" "guards/critic-guard.sh" || exit $?
        invoke_skill "reward-guard" "guards/subtask-guard.sh" || exit $?
        invoke_skill "reward-guard" "guards/scope-guard.sh" || exit $?
        ;;
    Bash)
        invoke_skill "access-control" "guards/bash-check.sh" || exit $?
        invoke_skill "reward-guard" "guards/coherence.sh" || exit $?
        invoke_skill "quality-assurance" "checkers/lint.sh" || exit $?
        ;;
esac

exit 0
```

### 3.2 post-tool.sh

```bash
#!/bin/bash
# post-tool.sh - PostToolUse(*) 導火線

SKILLS_DIR=".claude/skills"
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

invoke_skill() {
    local skill="$1"
    local script="$2"
    local path="$SKILLS_DIR/$skill/$script"
    [[ -x "$path" ]] && echo "$INPUT" | bash "$path"
}

case "$TOOL_NAME" in
    Edit)
        invoke_skill "playbook-gate" "workflow/archive.sh" || true
        invoke_skill "playbook-gate" "workflow/cleanup.sh" || true
        invoke_skill "git-workflow" "handlers/create-pr.sh" || true
        ;;
    Task)
        # SubAgent ログ記録（必要に応じて）
        ;;
esac

exit 0
```

### 3.3 session.sh

```bash
#!/bin/bash
# session.sh - SessionStart/End/PreCompact 導火線

SKILLS_DIR=".claude/skills"
INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "startup"')

invoke_skill() {
    local skill="$1"
    local script="$2"
    local path="$SKILLS_DIR/$skill/$script"
    [[ -x "$path" ]] && echo "$INPUT" | bash "$path"
}

case "$TRIGGER" in
    startup|resume|clear)
        invoke_skill "session-manager" "handlers/start.sh"
        ;;
    end)
        invoke_skill "session-manager" "handlers/end.sh"
        ;;
    compact)
        invoke_skill "session-manager" "handlers/compact.sh"
        ;;
esac

exit 0
```

### 3.4 prompt.sh

```bash
#!/bin/bash
# prompt.sh - UserPromptSubmit 導火線
# State Injection を実行

# 現在の prompt-guard.sh のロジックをそのまま使用
# （State Injection は導火線に内蔵）
```

---

## 4. settings.json 設定

```json
{
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
    ],
    "PostToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/post-tool.sh",
            "timeout": 10000
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/session.sh",
            "timeout": 5000
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/prompt.sh",
            "timeout": 3000
          }
        ]
      }
    ]
  }
}
```

---

## 5. 発火フロー図

### 5.1 タスク開始フロー

```
┌─────────────────────────────────────────────────────────────────┐
│  ユーザー: 「〇〇を実装して」                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  prompt.sh (導火線)                                              │
│    └── State Injection                                          │
│        └── 「playbook=null → pm 必須」警告                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  golden-path/ Skill                                              │
│    │                                                             │
│    ├── workflow/task-start.sh                                    │
│    │     └── タスク開始フロー                                    │
│    │                                                             │
│    └── agents/pm.md (SubAgent)                                   │
│          └── playbook 作成                                       │
│          └── 独自コンテキストで動作（親のコンテキスト節約）       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  state.md 更新                                                   │
│    playbook.active: plan/playbook-xxx.md                        │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 コード編集フロー

```
┌─────────────────────────────────────────────────────────────────┐
│  Claude: Edit ツールを使用                                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  pre-tool.sh (導火線)                                            │
│    │                                                             │
│    ├──→ session-manager/handlers/init-guard.sh                   │
│    │      └── 必須ファイル Read 済み ✓                           │
│    │                                                             │
│    ├──→ access-control/guards/main-branch.sh                     │
│    │      └── feature ブランチ ✓                                 │
│    │                                                             │
│    ├──→ access-control/guards/protected-edit.sh                  │
│    │      └── 保護対象外 ✓                                       │
│    │                                                             │
│    ├──→ playbook-gate/guards/playbook-guard.sh                   │
│    │      └── playbook あり ✓                                    │
│    │                                                             │
│    ├──→ playbook-gate/guards/executor-guard.sh                   │
│    │      └── executor: claudecode ✓                             │
│    │                                                             │
│    ├──→ reward-guard/guards/critic-guard.sh                      │
│    │      └── state: done ではない ✓                             │
│    │                                                             │
│    └──→ reward-guard/guards/subtask-guard.sh                     │
│           └── validations あり ✓                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  [Edit 実行]                                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  post-tool.sh (導火線)                                           │
│    │                                                             │
│    ├──→ playbook-gate/workflow/archive.sh                        │
│    │      └── 全 Phase done なら「アーカイブ推奨」               │
│    │                                                             │
│    └──→ git-workflow/handlers/create-pr.sh                       │
│           └── playbook 完了なら PR 自動作成                      │
└─────────────────────────────────────────────────────────────────┘
```

### 5.3 Phase 完了フロー

```
┌─────────────────────────────────────────────────────────────────┐
│  Claude: Phase を done に変更しようとする                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  reward-guard/ Skill                                             │
│    │                                                             │
│    ├── guards/subtask-guard.sh                                   │
│    │     └── 全 subtask が [x] になっているか ✓                  │
│    │     └── validations が記入されているか ✓                    │
│    │                                                             │
│    └── agents/critic.md (SubAgent)                               │
│          └── done_when を検証                                    │
│          └── PASS → self_complete: true                          │
│          └── FAIL → done 変更をブロック                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Skill 内 SubAgent の動作原理

### 6.1 SubAgent の配置と呼び出し

```yaml
配置ルール:
  - SubAgent は関連する Skill の agents/ フォルダに配置
  - .claude/agents/ にはシンボリックリンクを作成（後方互換性）

配置例:
  .claude/skills/golden-path/agents/pm.md
  .claude/skills/reward-guard/agents/critic.md
  .claude/skills/quality-assurance/agents/reviewer.md

SubAgent の呼び出しルール:
  - Task(subagent_type='pm') は動作するが、直接呼び出しは禁止
  - 必ず Skill 経由で呼び出すこと（Hook→Skill→SubAgent チェーン）
  - 利用可能な predefined types: general-purpose, Explore, Plan, pm, reviewer, critic, etc.

呼び出し方法:
  - Skill() ツール経由で呼び出す（推奨）
  - または /skill-name コマンドで直接呼び出す
  - ❌ Task(subagent_type='pm') を直接呼ぶのは禁止（Core Contract 違反）
```

### 6.2 Entry Skill から SubAgent への委譲パターン（必須）

> **Entry Skill は SubAgent に処理を委譲する。自分で手順を実行してはならない。**

```yaml
パターン: Entry Skill → SubAgent 委譲

  # playbook 作成（/playbook-init）
  Entry Skill が呼ばれる
    ↓
  Skill 内で Task(subagent_type='pm') を呼び出す
    ↓
  pm SubAgent が理解確認・playbook 作成・reviewer 検証を実行

  # done_criteria 検証（/crit）
  Entry Skill が呼ばれる
    ↓
  Skill 内で Task(subagent_type='critic') を呼び出す
    ↓
  critic SubAgent が 3点検証・CRITIQUE を実行

禁止パターン:
  ❌ Entry Skill の手順を Claude が直接実行する
  ❌ SubAgent をスキップして処理を完了する
  ❌ Task(subagent_type='pm') を Skill 外から直接呼ぶ

Entry Skill と SubAgent のマッピング:
  | Entry Skill | 委譲先 SubAgent |
  |-------------|-----------------|
  | /playbook-init | pm → reviewer |
  | /crit | critic |
  | /test | (Bash 直接実行) |
  | /lint | (Bash 直接実行) |
```

### 6.3 委譲パターンの実装例

```yaml
# playbook-init.md の構造
---
description: pm SubAgent に委譲して playbook 作成を行う
allowed-tools: Read, Bash, Task
---

# Step 0: 前提チェック（Skill 内で実行）
# Step 1: pm SubAgent 呼び出し（必須）
Task:
  subagent_type: pm
  prompt: |
    ユーザーの要求: $ARGUMENTS
    ブランチ: {現在のブランチ名}

    以下を実行してください:
    1. understanding-check（5W1H 分析 + ユーザー承認）
    2. playbook 作成
    3. reviewer 検証
    4. state.md 更新

禁止事項:
  - pm SubAgent を呼ばずに自分で playbook を作成
```

---

## 7. 移行計画

### Phase 1: Skills ディレクトリ構造作成
- 7 Skills のディレクトリを作成
- SKILL.md を各 Skill に配置

### Phase 2: 既存 Hook のロジック移動
- 31 Hook のロジックを対応する Skill に移動
- ファイル名は維持（パスのみ変更）

### Phase 3: SubAgents の移動
- .claude/agents/*.md を対応する Skill に移動
- 6 SubAgents → 5 Skills に分散

### Phase 4: 導火線 Hook 作成
- pre-tool.sh, post-tool.sh, session.sh, prompt.sh を作成
- Skills を呼び出すディスパッチャーロジック

### Phase 5: settings.json 更新
- 31 Hook → 4 導火線に変更
- 旧 Hook への参照を削除

### Phase 6: 旧ファイル削除
- .claude/hooks/ から移行済み Hook を削除
- .claude/agents/ を空にする

### Phase 7: project.md 完全削除
- plan/project.md 削除
- plan/archive/* 削除
- 全参照の除去

---

## 8. 統計

| 項目 | AS-IS | TO-BE |
|------|-------|-------|
| Hook 数 | 31 | 4 |
| Skills 数 | 9 | 7（新規） + 3（既存） = 10 |
| SubAgents | 6（独立） | 5（Skills 内） |
| settings.json エントリ | 31+ | 4 |

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | Core Contract 定義 |
| state.md | 現在の状態 |
| docs/repository-map.yaml | 全ファイルマッピング |
