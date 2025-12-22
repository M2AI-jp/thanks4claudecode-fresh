# Repository Structure Guide

> repository-map.yaml を活用したリポジトリ構造の理解ガイド

---

## 概要

`docs/repository-map.yaml` はこのリポジトリの **Single Source of Truth** です。
自動生成スクリプト（`.claude/hooks/generate-repository-map.sh`）により、playbook 完了時に更新されます。

---

## セクション構成

### 1. hooks

```yaml
hooks:
  directory: .claude/hooks/
  count: 31
```

- **目的**: Claude Code の動作を制御する Hook スクリプト
- **発火タイミング**: SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, Stop, PreCompact, SessionEnd
- **詳細**: `hook_trigger_sequence` セクション参照

### 2. agents

```yaml
agents:
  directory: .claude/agents/
  count: 6
```

- **目的**: Task ツールで呼び出される SubAgent 定義
- **主要エージェント**: pm, critic, reviewer, setup-guide, health-checker, codex-delegate

### 3. skills

```yaml
skills:
  directory: .claude/skills/
  count: 8
```

- **目的**: Claude が文脈から自動検出して呼び出すスキル
- **発火方式**: プロンプトマッチによる自動発火（`auto_invoke: true`）

### 4. commands

```yaml
commands:
  directory: .claude/commands/
  count: 8
```

- **目的**: ユーザーが `/command` で明示的に呼び出す CLI 機能
- **例**: `/test`, `/lint`, `/crit`, `/rollback`

### 5. docs

```yaml
docs:
  directory: docs/
  count: 17
```

- **目的**: システム文書、運用ルール、契約文書
- **カテゴリ**: システム仕様、運用ルール、契約定義、参照文書

---

## workflows セクション

5 つのワークフローが定義されています：

| ID | 名前 | トリガー |
|----|------|----------|
| init_flow | INIT | SessionStart |
| work_loop | LOOP | playbook 存在時 |
| post_loop | POST_LOOP | playbook 完了時 |
| critique_process | CRITIQUE | phase 完了申告時 |
| project_complete | PROJECT_COMPLETE | 全 milestone 達成時 |

---

## integration_points セクション

Hook・SubAgent・Skill 間の依存関係を明示：

- `hook_to_subagent`: critic-guard.sh → critic, archive-playbook.sh → pm
- `hook_to_skill`: test-done-criteria.sh → test-runner
- `subagent_to_skill`: pm → post-loop
- `validation_chain`: subtask → critic → critic-guard → playbook

---

## 自動更新

```bash
# 手動実行
bash .claude/hooks/generate-repository-map.sh

# 自動実行タイミング
# - playbook 完了時（archive-playbook.sh から呼び出し）
```

### 冪等性

- タイムスタンプ（`meta.generated`, `changelog`）以外は冪等
- 2 回連続実行しても内容に差分なし

---

## 同期ワークフロー（[DRIFT] 検出）

### 仕組み

セッション開始時（`session-start.sh`）に repository-map.yaml と実際のファイル数を比較し、
乖離を自動検出します。

```
SessionStart
    │
    ▼
check_repository_map_drift()
    │
    ├─ 乖離なし → 正常継続
    │
    └─ 乖離あり → [DRIFT] メッセージ出力
                      │
                      ▼
                  Claude が自動で
                  generate-repository-map.sh を実行
```

### 検出対象

| カテゴリ | パターン | 比較対象 |
|---------|----------|----------|
| hooks | `.claude/hooks/*.sh` | `hooks.count` |
| agents | `.claude/agents/*.md` | `agents.count` |
| skills | `.claude/skills/*/` | `skills.count` |
| commands | `.claude/commands/*.md` | `commands.count` |

### [DRIFT] メッセージ例

```
[DRIFT] repository-map.yaml に乖離あり
  詳細: hooks: 31 → 32
  対応: bash .claude/hooks/generate-repository-map.sh を実行してください
```

### 対応手順

1. **自動対応**: Claude が [DRIFT] を検出すると、自動で `generate-repository-map.sh` を実行
2. **手動対応**: 必要に応じて以下を実行

```bash
# 更新実行
bash .claude/hooks/generate-repository-map.sh

# 差分確認
git diff docs/repository-map.yaml

# コミット
git add docs/repository-map.yaml
git commit -m "chore: update repository-map.yaml"
```

### 設計思想

- **軽量**: find コマンドによるファイル数カウントのみ（1 秒以内）
- **非侵入**: 乖離検出のみ、自動修正はしない（Claude の判断に委ねる）
- **fail-open**: チェック失敗時もセッション継続可能

---

## 参照

- [ARCHITECTURE.md](./ARCHITECTURE.md) - システム全体のアーキテクチャ
- [extension-system.md](./extension-system.md) - Hook/Skill/Command の発火タイミング
- [hook-responsibilities.md](./hook-responsibilities.md) - 各 Hook の責任
