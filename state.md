# state.md

> **統合状態管理ファイル（Single Source of Truth）**
>
> **役割**: 「現在地」を示す。今どこにいて、何をしているか。
> **機能**: focus/goal/playbook/plan_hierarchy で現在の作業状態を管理。
> **分離**: 履歴は `.claude/context/history.md` に移動（参照用）。
>
> 4つのレイヤーを管理: plan-template → workspace → setup → product
> LLMはセッション開始時に必ずこのファイルを読み、`focus.current` を確認すること。

---

## focus

```yaml
current: product             # plan-template | workspace | setup | product
```

---

## security

```yaml
mode: admin                  # strict | trusted | developer | admin
```

---

## learning_mode

> **2軸の学習モード設定**

```yaml
operator: hybrid             # human | hybrid | llm
expertise: intermediate      # beginner | intermediate | expert
```

### 設定値の意味

```yaml
operator:
  human: 人間が主に操作（Claude は補助）
  hybrid: 人間と LLM が協働（デフォルト）
  llm: LLM が主に操作（人間は監視）

expertise:
  beginner: 初学者向け（専門用語を比喩で説明、beginner-advisor 自動発火）
  intermediate: 中級者向け（標準出力、必要時のみ補足）
  expert: 上級者向け（簡潔な出力、説明は省略）
```

### モード別出力調整

```yaml
beginner:
  - 専門用語は必ず比喩で説明
  - コマンド実行前に「何をするか」を説明
  - エラー時は原因と対処法を詳しく説明
  - beginner-advisor SubAgent を自動発火

intermediate:
  - 専門用語は必要に応じて説明
  - コマンドは実行後に結果を説明
  - エラー時は対処法を簡潔に説明

expert:
  - 専門用語の説明は省略
  - コマンドは結果のみ表示
  - エラー時は最小限の情報
```

---

## active_playbooks

```yaml
plan-template:    null
workspace:        null                       # 完了した playbook は .archive/plan/ に退避
setup:            null                       # テンプレートは常に pending（正常）
product:          plan/active/playbook-context-architecture.md
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
# Macro: リポジトリ全体の最終目標
macro:
  file: plan/project.md
  exists: true
  summary: 仕組みのための仕組みづくり - LLM 主導の開発環境テンプレート

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
  file: plan/active/playbook-context-architecture.md
  exists: true
  goal: コンテキストを機能として管理し、リポジトリの完成形を実現する

# Micro: セッション単位の作業（playbook の 1 Phase）
micro:
  phase: p1
  name: state.md 機能分離
  status: implementing

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
generated: true              # plan/project.md 生成済み
project_plan: plan/project.md
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
state: done
sub: v8-complete-meta-tooling
playbook: null  # テンプレートは pending のまま（正常）
```

### 概要
> setup/playbook-setup.md に従って環境をセットアップする。
> Phase 0-8 を完了後、plan/project.md を生成し product レイヤーへ移行。
> CATALOG.md は必要な時だけ参照。

---

## layer: product

```yaml
state: implementing
sub: context-architecture-p1
playbook: plan/active/playbook-context-architecture.md
```

### 概要
> ユーザーが実際にプロダクトを開発するためのレイヤー。
> setup 完了後、plan/project.md を参照して TDD で開発。
> playbook-context-architecture 進行中（p1: state.md 機能分離）。

---

## goal

```yaml
phase: p1
current_phase: state.md 機能分離
task: 履歴を .claude/context/history.md に分離
assignee: claudecode

done_criteria:
  - state.md が「現在地」機能に特化している
  - .claude/context/history.md に履歴が移動している
  - 両機能とも正常に動作している
  - state.md の役割が明確に定義されている
```

> **p1 実行中。** 履歴を .claude/context/history.md に分離中。

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
保護: CLAUDE.md は BLOCK（ユーザー許可必要）
```

---

## session_tracking

> **Hooks による自動更新。LLM の行動に依存しない。**

```yaml
last_start: 2025-12-10 00:24:52
last_end: 2025-12-09 21:22:42
uncommitted_warning: false
```

---

## 参照ファイル

| ファイル | 内容 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| plan/project.md | Macro 計画（最終目標） |
| docs/current-implementation.md | 現在実装の棚卸し（Single Source of Truth） |
| docs/extension-system.md | Claude Code 公式リファレンス |

---

## 変更履歴

> 詳細な履歴: `.claude/context/history.md`

| 日時 | 内容 |
|------|------|
| 2025-12-10 | **playbook-context-architecture p1**: state.md 機能分離。履歴を .claude/context/history.md に移動。 |
