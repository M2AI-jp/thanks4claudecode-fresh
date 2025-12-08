# state.md

> **統合状態管理ファイル（Single Source of Truth）**
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

## active_playbooks

```yaml
plan-template:    null
workspace:        null                       # 完了した playbook は .archive/plan/ に退避
setup:            null                       # テンプレートは常に pending（正常）
product:          plan/active/playbook-plan-chain.md  # 計画の連鎖的導出システム
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
state: pending
sub: next-task-prep
playbook: null
```

### 概要
> ユーザーが実際にプロダクトを開発するためのレイヤー。
> setup 完了後、plan/project.md を参照して TDD で開発。
> **Issue #11: ロールバック機能 - p1 設計フェーズ**

---

## goal

```yaml
phase: done
current_phase: 全 Phase 完了（p0-p5）
task: 計画の連鎖的導出システム
assignee: claude

done_criteria:
  - project.done_when に decomposition（分解指針）が構造化されている
  - pm SubAgent が計画の導出を支援できる
  - /playbook-init が decomposition を参照して playbook を生成できる
  - CLAUDE.md に計画の連鎖ルールが明記されている
  - 実際に project.done_when から playbook を自動導出できることを検証
```

> **playbook-plan-chain: p0-p5 全完了、コミット準備中**

---

## verification

```yaml
self_complete: false     # playbook-e2e-validation 進行中
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
last_start: 2025-12-08 20:24:47
last_end: 2025-12-08 02:20:49
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

| 日時 | 内容 |
|------|------|
| 2025-12-08 | docs/ フォルダ新設。current-implementation.md を Single Source of Truth に。spec.yaml/architecture-*.md 廃止。 |
| 2025-12-08 | アクションベース Guards 完了: session 分類ロジック完全削除。Edit/Write 時のみ playbook チェック。 |
| 2025-12-08 | p8 完了（構造的強制）: Hook が session を TASK にリセット → NLU 判断 → 安全側フォール。 |
| 2025-12-08 | checkpoint: done_when 再定義 + アーキテクチャ図作成。main マージ。 |
| 2025-12-08 | playbook-e2e-validation 開始。done_when 達成に向けた検証。 |
| 2025-12-08 | spec.yaml YAML validation PASS。構文エラー修正完了。 |
| 2025-12-08 | playbook-validation 完了。spec.yaml v8.0.0、QUICKSTART 退避。 |
| 2025-12-08 | 全タスク完了。13件実装：SubAgents(reviewer, health-checker), Skills(context-mgmt, exec-mgmt, learning), playbook拡張。 |
| 2025-12-08 | Issue #11 完了。p1-p4 全 Phase critic PASS。test PASS=15。 |
| 2025-12-08 | Issue #11 開始。ロールバック機能 p1 設計フェーズ。 |
| 2025-12-08 | Issue #10 完了。playbook-auto-clear.md 全 Phase critic PASS。残り 11 タスク。 |
| 2025-12-08 | Issue #8 開始: 自律性強化。playbook-autonomy-enhancement.md 作成。p1 開始。 |
| 2025-12-08 | 全コアタスク完了（p1-p7）。Issue #6, #7 クローズ。メンテナンスフェーズへ移行。 |
| 2025-12-08 | POST_LOOP + Skills バリデーション機構追加。異常系テスト結果を反映。 |
| 2025-12-08 | Skills 4 件に YAML フロントマター追加（lint-checker, test-runner, deploy-checker, frontend-design）。自動発火可能に。 |
| 2025-12-08 | 自律発火テスト 全 4 項目 PASS。Hooks による構造的制御を検証。 |
| 2025-12-08 | playbook-done-criteria-schema 全 Phase 完了（p1-p5 done）。V9 スキーマ定義。 |
| 2025-12-08 | 新 playbook 作成: playbook-done-criteria-schema.md。Issue #8 開始。 |
| 2025-12-08 | playbook-claude-redesign 全 Phase 完了（p0-p4 critic PASS）。CLAUDE.md V4.0。Issue #7。 |
| 2025-12-08 | spec.yaml v8.0.0 更新（Hooks/SubAgents/Skills 正確に反映）。critic PASS。 |
| 2025-12-08 | p6 evidence にコミットハッシュ 6ca9529 を追加。 |
| 2025-12-08 | playbook-context-optimization 全 Phase 完了（p3,p4,p6 critic PASS）。Issue #6 完了報告済み。 |
| 2025-12-08 | 新 playbook 作成: playbook-context-optimization.md。Issue #6。 |
| 2025-12-08 | playbook-meta-tooling 全 Phase 完了（p1-p4 全て critic PASS）。 |
| 2025-12-08 | p4: evidence 追加。critic 待ち。 |
| 2025-12-08 | p3 完了（critic PASS）。p4 開始。 |
| 2025-12-08 | p3: critic 再対応。実引用証拠追加、Skills 定義明確化。 |
| 2025-12-08 | p3: done_criteria 明確化（構造・ファイル存在確認をスコープに）。critic FAIL 対応。 |
| 2025-12-08 | p3: setup playbook 検証完了（構造・手順が明確）。critic 待ち。 |
| 2025-12-08 | p2 完了（critic PASS）。p3 開始。 |
| 2025-12-08 | p2: done_criteria 明確化（手動操作可能をスコープに）。critic FAIL 対応。 |
| 2025-12-08 | p1 完了（critic PASS）。p2 開始。 |
| 2025-12-08 | p1: current_phase 追加、evidence 詳細化。critic FAIL 対応。 |
| 2025-12-08 | setup done, product implementing へ移行。playbook-meta-tooling.md 作成。 |
| - | フォーク直後の初期状態 |
