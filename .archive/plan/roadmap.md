# Roadmap（中長期計画）

> **vision.md の目標を達成するための中長期計画。**
> **各マイルストーンには担当者アサイン、影響分析、フィードバックポイントを含む。**

---

## meta

```yaml
project: dev-workspace
version: 2.0.0
created: 2025-12-02
updated: 2025-12-04
references:
  - plan/vision.md        # 最上位レイヤー（存在意義、オーケストレーション）
  - plan/meta-roadmap.md  # 改善サイクル
```

---

## current_focus

```yaml
phase: PHASE_3
milestone: M9
task: 公開準備完了
priority: high
branch: fix/simplify-structure

next_actions:
  - M9-T1: state.md を初期状態にリセット
  - M9-T2: 不要ファイルの削除
  - M9-T3: 最終 E2E テスト
```

---

## phases

```yaml
- id: PHASE_0
  name: Meta（roadmap 自体の改善）
  status: done
  goal: |
    roadmap を「生きたプロジェクトマネジメント」にする。
    担当者アサイン、フィードバックループ、デバッグフェーズを導入。
  milestones: [M0]

- id: PHASE_1
  name: Foundation（基盤構築）
  status: done
  goal: |
    ワークスペースの根幹機能を構築。
    Hooks、保護ファイル、状態管理の基盤を作る。
  milestones: [M1, M2, M3, M4]

- id: PHASE_2
  name: Verification（検証）
  status: done
  completed: 2025-12-04
  goal: |
    ユーザー視点での検証を行う。
    オーケストレーション、E2E、フィードバックループのテスト。
  milestones: [M5, M6, M7]
  debug_phase_after: true  # M7 完了後にデバッグフェーズ（実施済み）

- id: PHASE_3
  name: Release（公開）
  status: in_progress
  goal: |
    新規ユーザーが使える状態で公開。
    ドキュメント整備、テンプレートリセット。
  milestones: [M8, M9]

- id: PHASE_4
  name: Iteration（改善）
  status: pending
  goal: |
    ユーザーフィードバックを元に継続改善。
  milestones: [M10+]
```

---

## milestones

### PHASE_0: Meta

```yaml
- id: M0
  name: roadmap 自体の設計改善
  status: done
  completed: 2025-12-04
  priority: critical

  tasks:
    - id: M0-T1
      description: "vision.md を作成"
      assignee: claude_code
      status: done
      output: plan/vision.md
      affects: [M0-T2, M0-T3]

    - id: M0-T2
      description: "meta-roadmap.md を作成"
      assignee: claude_code
      status: done
      output: plan/meta-roadmap.md
      depends_on: [M0-T1]
      affects: [M0-T3]

    - id: M0-T3
      description: "roadmap.md を完全再設計"
      assignee: claude_code
      status: done
      depends_on: [M0-T1, M0-T2]
      output: plan/roadmap.md（このファイル）
      affects: [M0-T4, M0-T5]

    - id: M0-T4
      description: "オーケストレーションテスト作成"
      assignee: codex
      status: done
      completed: 2025-12-04
      depends_on: [M0-T3]
      output: .claude/hooks/test-orchestration.sh

    - id: M0-T5
      description: "E2E ユーザーシナリオテスト作成"
      assignee: codex
      status: done
      completed: 2025-12-04
      depends_on: [M0-T3]
      output: .claude/hooks/test-e2e-user.sh

  done_when:
    - "vision.md が存在し、オーケストレーション設計を含む"
    - "meta-roadmap.md が存在し、デバッグフェーズを定義"
    - "roadmap.md が担当者アサイン、影響分析、フィードバックポイントを含む"
    - "オーケストレーションテストが PASS"
    - "E2E ユーザーシナリオテストが PASS"

  feedback_checkpoint:
    trigger: 全タスク完了後
    questions:
      - "新しい roadmap 構造は使いやすいか？"
      - "担当者アサインは明確か？"
      - "フィードバックループは機能しそうか？"
    action: meta-roadmap.md に振り返りを記録
```

### PHASE_1: Foundation（完了済み）

```yaml
- id: M1
  name: 根幹機能の完成
  status: done
  completed: 2025-12-01

  tasks:
    - id: M1-T1
      description: "SessionStart Hook 実装"
      assignee: claude_code
      status: done

    - id: M1-T2
      description: "保護ファイル機構実装"
      assignee: claude_code
      status: done

    - id: M1-T3
      description: "state.md 更新強制実装"
      assignee: claude_code
      status: done

    - id: M1-T4
      description: "critic/coherence エージェント実装"
      assignee: claude_code
      status: done

  retrospective:
    learned: |
      - LLM は「完了」と言いたがる（自己報酬詐欺）
      - 構造的強制がないとルールは守られない
    affects_future: |
      - M5 以降で critic PASS 必須化
      - Hook による構造的ブロックを多用

- id: M2
  name: コンテキスト管理機能
  status: done
  completed: 2025-12-01

  retrospective:
    learned: |
      - CLAUDE.md が肥大化するとルールが効かなくなる
      - 外部ファイルを真実源にすべき
    affects_future: |
      - CONTEXT.md を唯一の真実源に
      - @import による二層構造化

- id: M3
  name: 複数階層 plan 運用
  status: done
  completed: 2025-12-02

  retrospective:
    learned: |
      - roadmap と playbook の役割分担が不明確だった
      - focus 別の挙動を考慮していなかった
    affects_future: |
      - M0 で roadmap 再設計
      - check-main-branch.sh を focus 別に修正

- id: M4
  name: setup/plan 基盤完成
  status: done
  completed: 2025-12-02

  retrospective:
    learned: |
      - setup フローは新規ユーザー視点で設計すべき
      - テストは「存在確認」ではなく「動作確認」が必要
```

### PHASE_2: Verification（検証）

```yaml
- id: M5
  name: オーケストレーション検証
  status: done
  completed: 2025-12-04
  depends_on: [M0]

  tasks:
    - id: M5-T1
      description: "Claude Code → Codex 委譲テスト"
      assignee: claude_code
      status: pending
      test_scenario: |
        1. ユーザー: "認証機能を追加して"
        2. Claude Code: playbook 生成
        3. Claude Code: Codex に委譲
        4. Codex: 実装
        5. Claude Code: 結果検証

    - id: M5-T2
      description: "CodeRabbit 連携テスト"
      assignee: claude_code
      status: pending
      test_scenario: |
        1. git push
        2. CodeRabbit がレビュー
        3. レビュー結果を確認
        4. 修正対応

    - id: M5-T3
      description: "User オフラインタスク連携テスト"
      assignee: user
      status: pending
      test_scenario: |
        1. Claude Code: "外部サービス設定が必要です"
        2. User: オフラインで設定
        3. User: 設定完了を報告
        4. Claude Code: 続行

  done_when:
    - "Claude Code → Codex 委譲が正常動作（証拠: ログ）"
    - "CodeRabbit レビューが自動実行（証拠: PR コメント）"
    - "オフラインタスクの引き継ぎが明確（証拠: 指示ログ）"

- id: M6
  name: E2E ユーザーシナリオ検証
  status: done
  completed: 2025-12-04
  depends_on: [M5]

  tasks:
    - id: M6-T1
      description: "E2E シミュレーションテスト基盤構築"
      assignee: claude_code
      status: done
      completed: 2025-12-04
      output: test/E2E/run-e2e-test.sh

    - id: M6-T2
      description: "setup フローシミュレーション実行"
      assignee: claude_code
      status: done
      completed: 2025-12-04
      output: test/E2E/results/e2e_*.json

  done_when:
    - "E2E テスト基盤が構築されている（証拠: test/E2E/run-e2e-test.sh）"
    - "シミュレーションで全 Phase PASS（証拠: JSON 結果）"
    - "playbook テンプレート生成が機能（証拠: sandbox/playbook-*.md）"

  note: |
    実際のユーザーによる E2E 検証は M9（最終 E2E テスト）で実施。
    M6 はシミュレーションベースのテスト基盤構築に焦点を当てる。

- id: M7
  name: フィードバックループ検証
  status: done
  completed: 2025-12-04
  depends_on: [M6]

  tasks:
    - id: M7-T1
      description: "マイルストーン完了時の振り返り"
      assignee: claude_code
      status: pending

    - id: M7-T2
      description: "問題発見 → 前工程修正の流れ"
      assignee: claude_code
      status: pending

    - id: M7-T3
      description: "デバッグフェーズ実施"
      assignee: claude_code
      status: pending

  done_when:
    - "振り返りが自動で促される（証拠: Hook 出力）"
    - "影響分析テンプレートが使える（証拠: 記入例）"
    - "デバッグフェーズで改善案が出る（証拠: meta-roadmap 更新）"

  # M7 完了後にデバッグフェーズ実施
  debug_phase:
    enabled: true
    target: [M5, M6, M7]
```

### PHASE_3: Release

```yaml
- id: M8
  name: ドキュメント整備
  status: done
  completed: 2025-12-04
  depends_on: [M7]

  tasks:
    - id: M8-T1
      description: "README.md を新規ユーザー向けに更新"
      assignee: claude_code

    - id: M8-T2
      description: "QUICKSTART.md 作成"
      assignee: claude_code

    - id: M8-T3
      description: "CONTRIBUTING.md 作成"
      assignee: claude_code

- id: M9
  name: 公開準備完了
  status: in_progress
  depends_on: [M8]

  tasks:
    - id: M9-T1
      description: "state.md を初期状態にリセット"
      assignee: claude_code

    - id: M9-T2
      description: "不要ファイルの削除"
      assignee: claude_code

    - id: M9-T3
      description: "最終 E2E テスト"
      assignee: codex

  done_when:
    - "state.md が focus=setup, project_context.generated=false"
    - "git status がクリーン"
    - "E2E テストが PASS"
    - "README.md がユーザーフレンドリー"
```

---

## feedback_checkpoints

> **各マイルストーン完了時に実施する振り返り。**

```yaml
template:
  questions:
    - "想定通りに動いたか？"
    - "前工程の設計に問題はなかったか？"
    - "後工程に伝えるべき知見は？"
    - "roadmap の見積もりは適切だったか？"
    - "担当者アサインは適切だったか？"
  actions:
    - 問題発見 → 影響分析テンプレート記入
    - 前工程修正 → playbook 作成
    - 知見追加 → CONTEXT.md または meta-roadmap.md
```

---

## debug_phases

> **3 マイルストーンごとに実施する定期的な振り返り。**

| フェーズ | 対象 | 実施タイミング | ステータス |
|---------|------|---------------|-----------|
| Debug-0 | M0 | M0 完了後 | pending |
| Debug-1 | M5, M6, M7 | M7 完了後 | pending |
| Debug-2 | M8, M9, M10 | M10 完了後 | pending |

---

## assignee_summary

> **担当者別のタスク一覧。**

```yaml
claude_code:
  role: オーケストレーター
  current_tasks:
    - M0-T3: roadmap.md を完全再設計
  pending_tasks:
    - M5-T1, M5-T2, M6-T1, M7-T1, M7-T2, M7-T3
    - M8-T1, M8-T2, M8-T3, M9-T1, M9-T2

codex:
  role: 実装担当
  current_tasks: []
  pending_tasks:
    - M0-T4: オーケストレーションテスト作成
    - M0-T5: E2E ユーザーシナリオテスト作成
    - M6-T2, M9-T3

coderabbit:
  role: レビュー担当
  trigger: git push / PR 作成時
  tasks: 自動実行

user:
  role: 意思決定者
  current_tasks: []
  pending_tasks:
    - M5-T3: User オフラインタスク連携テスト
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-04 | V2.0: 完全再設計。担当者アサイン、影響分析、フィードバックポイント追加。 |
| 2025-12-02 | V1.0: 初版作成。 |
