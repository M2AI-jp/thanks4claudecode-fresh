# state.md

> **統合状態管理ファイル（Single Source of Truth）**
>
> 4つのレイヤーを管理: plan-template → workspace → setup → product
> LLMはセッション開始時に必ずこのファイルを読み、`focus.current` を確認すること。

---

## focus

```yaml
current: setup               # plan-template | workspace | setup | product
session: discussion          # task | discussion (playbook作成中は一時的にdiscussion)
```

---

## security

```yaml
mode: trusted                # strict | trusted | developer | admin
```

---

## active_playbooks

```yaml
plan-template:    null
workspace:        null                       # 完了した playbook は .archive/plan/ に退避
setup:            setup/playbook-setup.md   # デフォルト playbook
product:          null                       # setup 完了後、product 開発用に作成
```

---

## context

```yaml
mode: normal                 # normal | interrupt
interrupt_reason: null
return_to: null
```

---

## plan_hierarchy

> **3層計画構造**: Macro → Medium → Micro

```yaml
# Macro: リポジトリ全体の最終目標（Phase 8 で生成）
macro:
  file: plan/project.md
  exists: false
  summary: null  # setup 完了後、ユーザーの目標に基づいて生成

# Archive: 公開時に新規ユーザーに不要なファイルを隔離
archive:
  folder: .archive/          # 一時退避フォルダ
  purpose: |
    開発時に使用したファイル（テスト履歴、ロードマップ、メタ改善記録など）を
    公開前に退避させ、新規ユーザーのコンテキスト負荷を軽減する。
    必要に応じて復元可能。
  restore_command: "git checkout .archive/ && mv .archive/* ."

# Medium: 単機能実装の中期計画（1ブランチ = 1playbook）
medium:
  file: null                 # 新タスク開始時
  exists: false
  goal: null

# Micro: セッション単位の作業（playbook の 1 Phase）
micro:
  phase: null
  name: null
  status: pending

# 上位計画参照（.archive/ に退避済み、必要時のみ復元）
upper_plans:
  vision: .archive/plan/vision.md           # WHY-ultimate
  meta_roadmap: .archive/plan/meta-roadmap.md  # HOW-to-improve
  roadmap: .archive/plan/roadmap.md         # WHAT
```

---

## project_context

> **Macro 計画の状態を管理。**

```yaml
generated: false             # Phase 8 で生成
project_plan: null           # setup 完了後に plan/project.md が生成される
```

---

## layer: plan-template

```yaml
state: done
sub: v3-complete
playbook: null
```

---

## layer: workspace

```yaml
state: done
sub: v8-3layer-plan-guard-archived
playbook: null
```

---

## layer: setup

```yaml
state: pending
sub: null
playbook: setup/playbook-setup.md
```

### 概要
> setup/playbook-setup.md に従って環境をセットアップする。
> Phase 0-8 を完了後、plan/project.md を生成し product レイヤーへ移行。
> CATALOG.md は必要な時だけ参照。

---

## layer: product

```yaml
state: pending               # setup 完了後に有効化
sub: null
playbook: null
```

### 概要
> ユーザーが実際にプロダクトを開発するためのレイヤー。
> setup 完了後、plan/project.md を参照して TDD で開発。

---

## goal

```yaml
phase: setup
milestone: Phase0
task: ルート選択
assignee: claude_code

done_criteria:
  - ユーザーが目的を選択した
```

### 次のステップ
```
Phase 0: ルート選択（チュートリアル or 本番開発）
Phase 1: プロジェクト設計（何を作るか）
```

---

## verification

```yaml
self_complete: false
user_verified: false
```

---

## states

```yaml
flow: pending → designing → implementing → [reviewing →] state_update → done
forbidden: [pending→implementing], [pending→done], [*→done without state_update]
```

---

## rules

```yaml
原則: focus.current のレイヤーのみ編集可能
例外: state.md の focus/context/verification は常に編集可能
保護: CLAUDE.md, CONTEXT.md は BLOCK（ユーザー許可必要）
```

---

## session_tracking

> **Hooks による自動更新。LLM の行動に依存しない。**

```yaml
last_start: 2025-12-08 00:42:19
last_end: null
uncommitted_warning: false
```

---

## 参照ファイル

| ファイル | 内容 |
|----------|------|
| CONTEXT.md | 唯一の真実源。設計思想、レイヤー構造、全コンテキスト |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| - | フォーク直後の初期状態 |
