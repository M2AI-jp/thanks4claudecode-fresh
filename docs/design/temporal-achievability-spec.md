# Temporal Achievability Specification

> **時間的達成可能性 - 設計仕様書**
>
> このドキュメントは playbook-review-criteria.md に追加する「7. 時間的達成可能性」セクションの設計仕様を定義する。

---

## 1. 背景と問題定義

### 1.1 発生した問題

m1-post-maintenance playbook で以下の criterion 設計ミスが発生した:

```yaml
問題の criterion:
  id: p1.1
  criterion: "state.md の playbook.branch が main に設定されている"

問題点:
  - playbook 実行中、state.md の playbook.branch は作業ブランチを指す
  - main になるのは playbook 完了後（archive-playbook 実行後）
  - Phase 内で達成を求めるのは論理的に不可能

結果:
  - reviewer が PASS した
  - critic が FAIL を返した
  - criterion を修正して再検証が必要になった
```

### 1.2 根本原因

reviewer の検証基準（playbook-review-criteria.md）に以下のチェックが欠けていた:

- **「この criterion は評価時点で達成可能か？」**

既存の基準は「検証可能か」「論理的に正しいか」を確認するが、
「評価される時点のシステム状態で達成可能か」は確認していなかった。

---

## 2. 時間的達成可能性の定義

### 2.1 概念定義

```yaml
temporal_achievability:
  definition: |
    criterion が評価される時点で、システムの状態が
    その criterion を満たすことが論理的に可能であること。

  key_insight: |
    criterion は「ある時点で」評価される。
    その時点でシステムがどのような状態にあるかを考慮しなければ、
    論理的に達成不可能な criterion を設定してしまう。
```

### 2.2 時間軸の分類

```yaml
evaluation_timepoints:
  - id: "during_playbook"
    name: "playbook 実行中"
    state_characteristics:
      - playbook.active: "{current_playbook_path}"
      - playbook.branch: "{working_branch}"
      - goal.status: "in_progress"

  - id: "after_archive"
    name: "playbook アーカイブ後"
    state_characteristics:
      - playbook.active: "null"
      - playbook.branch: "null" または "main"
      - goal.status: "idle"

  - id: "during_phase"
    name: "Phase 実行中"
    state_characteristics:
      - 前の Phase の成果物は存在する
      - 現在の Phase の成果物はまだ存在しない（作成中）
```

---

## 3. チェックリスト設計

### 3.1 必須チェック項目

```yaml
checklist:
  - id: "prerequisite_availability"
    question: "この criterion を達成するための前提条件は、評価時点で全て揃っているか？"
    rationale: |
      前の Phase で生成されるファイルに依存する criterion は、
      その Phase が完了するまで達成不可能。

  - id: "state_consistency"
    question: "この criterion はシステムの状態遷移と矛盾しないか？"
    rationale: |
      playbook 実行中に「playbook.active が null」を要求するのは矛盾。
      状態遷移図を考慮する必要がある。

  - id: "timing_possibility"
    question: "この criterion は評価される Phase で達成可能か？（将来時点ではなく）"
    rationale: |
      「PR がマージされている」は p_final で評価されるが、
      マージは archive-playbook.sh（final_tasks 後）で実行される。

  - id: "no_self_reference"
    question: "この criterion は自己参照矛盾を含んでいないか？"
    rationale: |
      「この playbook が完了している」を criterion にすると、
      playbook 完了前に評価されるため達成不可能。
```

### 3.2 状態遷移マトリクス

```yaml
state_transition_matrix:
  # 主要フィールドの時間的変化

  playbook.active:
    during_playbook: "{playbook_path}"
    after_archive: "null"

  playbook.branch:
    during_playbook: "{working_branch}"
    after_archive: "null" または "main"

  goal.status:
    during_playbook: "in_progress"
    after_archive: "idle"

  git_branch:
    during_playbook: "{working_branch}"
    after_archive: "main"

  pr_status:
    during_playbook: "open" または "未作成"
    after_archive: "merged"
```

---

## 4. 失敗例と成功例

### 4.1 fail_examples（達成不可能な criterion）

```yaml
fail_examples:
  - criterion: "state.md の playbook.branch が main に設定されている"
    evaluation_point: "Phase p1 (playbook 実行中)"
    problem: "playbook 実行中は branch = 作業ブランチ。main は archive 後。"
    category: "state_consistency"

  - criterion: "playbook.active が null である"
    evaluation_point: "任意の Phase (playbook 実行中)"
    problem: "playbook 実行中は active = current playbook。null は完了後。"
    category: "state_consistency"

  - criterion: "PR がマージされている"
    evaluation_point: "p1 Phase"
    problem: "PR マージは archive-playbook.sh で実行される。Phase 中は未マージ。"
    category: "timing_possibility"

  - criterion: "全ての Phase が完了している"
    evaluation_point: "任意の Phase"
    problem: "現在実行中の Phase は未完了。自己参照矛盾。"
    category: "no_self_reference"

  - criterion: "commit {hash} が main に存在する"
    evaluation_point: "Phase 中"
    problem: "作業ブランチのコミットは archive 後に main にマージされる。"
    category: "timing_possibility"
```

### 4.2 pass_examples（達成可能な criterion）

```yaml
pass_examples:
  - criterion: "state.md に playbook.branch フィールドが存在する"
    evaluation_point: "任意の Phase"
    reason: "state.md の構造は playbook 実行中も変わらない。"
    category: "prerequisite_availability"

  - criterion: "作業ブランチ名が feat/xxx 形式である"
    evaluation_point: "任意の Phase"
    reason: "ブランチは playbook 開始時に作成済み。"
    category: "prerequisite_availability"

  - criterion: "repository-map.yaml が再生成されている"
    evaluation_point: "その Phase で実行した後"
    reason: "Phase 内のアクションで達成可能。"
    category: "timing_possibility"

  - criterion: "docs/design/spec.md が存在する"
    evaluation_point: "その Phase で作成した後"
    reason: "Phase 内のアクションで達成可能。"
    category: "prerequisite_availability"

  - criterion: "ESLint エラーが 0 件である"
    evaluation_point: "修正 Phase 後"
    reason: "Phase 内のアクションで達成可能。外部状態に依存しない。"
    category: "timing_possibility"
```

---

## 5. playbook-review-criteria.md への統合設計

### 5.1 新セクション構造

既存の「普遍的レビュー基準（Universal Criteria）」の 1-6 に続く形で追加:

```markdown
### 7. 時間的達成可能性（Temporal Achievability）

```yaml
question: "この criterion は評価される時点で達成可能か？"

checklist:
  - [ ] 前提条件が評価時点で揃っている
  - [ ] システムの状態遷移と矛盾しない
  - [ ] 評価される Phase で達成可能（将来時点ではない）
  - [ ] 自己参照矛盾を含んでいない

fail_examples:
  - "state.md の playbook.branch が main" → playbook 実行中は達成不可能
  - "playbook.active が null" → playbook 実行中は達成不可能
  - "PR がマージされている" → archive 前は達成不可能

pass_examples:
  - "ファイル X が存在する" → Phase 内で作成可能
  - "ESLint エラーが 0 件" → Phase 内で修正可能
  - "ブランチ名が feat/xxx 形式" → 開始時に確定済み
```
```

### 5.2 判定基準への統合

```yaml
# 変更箇所: 判定基準セクション

PASS_conditions:
  追加:
    - temporal_achievability: PASS

FAIL_conditions:
  追加:
    - "criterion が評価時点で達成不可能（論理的矛盾）"
```

### 5.3 シミュレーション実行プロトコルへの統合

```yaml
# 変更箇所: シミュレーション実行プロトコル

追加する質問:
  - "この Phase の criterion を評価するとき、システムはどのような状態か？"
  - "その状態で、この criterion は達成可能か？"
  - "達成に必要な条件は、評価時点で全て揃っているか？"
```

---

## 6. 検証方法

### 6.1 設計の妥当性確認

```yaml
validation_criteria:
  - 既存の 6 基準と同じフォーマットを維持している
  - question, checklist, fail_examples, pass_examples が全て定義されている
  - m1-post-maintenance の問題を検出できる（fail_examples に含まれる）
  - 誤検出（false positive）を最小限に抑えている
```

### 6.2 遡及検証（オプション）

```yaml
retrospective_check:
  description: |
    過去の playbook で時間的達成可能性違反がないか確認。
    今回のスコープ外だが、将来のタスク候補。
```

---

## 7. 参照

| ファイル | 役割 |
|----------|------|
| .claude/frameworks/playbook-review-criteria.md | 実装先 |
| .claude/frameworks/done-criteria-validation.md | 関連する done_criteria 検証基準 |
| play/archive/m1-post-maintenance/ | 問題の発生元 |
