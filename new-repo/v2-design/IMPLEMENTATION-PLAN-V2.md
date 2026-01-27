# new-repo 完璧実装計画 V2

> **文書の位置付け**: new-repo 再構築の実装計画
>
> **MECE 役割**: Phase 別実装手順・検証方法・成功基準の SSOT
>
> **作成日**: 2026-01-22

---

## 1. 設計原則（二の轍を踏まないために）

### 1.1 今のリポジトリの失敗要因

| 失敗 | 原因 | 対策 |
|------|------|------|
| Hook チェーンが複雑化 | Hook を第一層として自動強制を目指した | Hook は Phase 4 まで使わない |
| playbook が人間に読めない | JSON のみで設計 | JSON + Markdown 二層化 |
| 長期タスクで破綻 | セッション永続化なし | Phase 1 で永続化導入 |
| コンテキスト0で再現不能 | 暗黙の前提が多い | 全ての前提を明示化 |
| 検証が後回し | 作りっぱなし | 各 Phase にテストを含める |

### 1.2 新設計の原則

```yaml
principles:
  1_self_containment:
    rule: 各ドキュメントは単独で意味を持つ
    test: コンテキスト0で読んで理解できるか

  2_explicit_over_implicit:
    rule: 暗黙の前提を排除、全て明文化
    test: 「なぜ？」に対する答えがドキュメントにあるか

  3_testable_specification:
    rule: 全ての仕様に対応するテストが存在
    test: 仕様変更時にテストが失敗するか

  4_incremental_construction:
    rule: Phase N は Phase N-1 の上に構築
    test: Phase N-1 だけで動作するか

  5_human_readable:
    rule: 機械可読（JSON）と人間可読（Markdown）の両立
    test: 非技術者が Markdown を読んで理解できるか
```

---

## 2. リポジトリ構造

```
new-repo/
├── README.md                          # エントリーポイント（必読）
├── CLAUDE.md                          # Core Contract（必読）
│
├── docs/
│   ├── GLOSSARY.md                    # 用語定義（SSOT）
│   ├── ARCHITECTURE.md                # アーキテクチャ設計
│   ├── SPECIFICATION.md               # 仕様書（厳密な定義）
│   ├── IMPLEMENTATION-PLAN.md         # 実装計画（Phase別）
│   ├── REVIEW-PROTOCOL.md             # レビュー手順
│   ├── TEST-PROTOCOL.md               # テスト手順
│   └── FAILURE-CATALOG.md             # 失敗カタログ
│
├── contracts/
│   ├── schemas/
│   │   ├── state.schema.json          # state.md のスキーマ
│   │   ├── session.schema.json        # session.json のスキーマ
│   │   ├── playbook.schema.json       # playbook のスキーマ
│   │   └── safety.schema.json         # 安全設定のスキーマ
│   └── templates/
│       ├── PLAYBOOK.template.md       # playbook のテンプレート
│       └── REVIEW-REPORT.template.md  # レビューレポートのテンプレート
│
├── .claude/
│   ├── commands/                      # Phase 0
│   │   ├── plan.md
│   │   ├── work.md
│   │   └── review.md
│   ├── workflows/                     # Phase 0
│   │   └── golden-path.yaml
│   ├── skills/                        # Phase 2+
│   ├── state/                         # Phase 1
│   │   ├── session.json
│   │   └── session.events.jsonl
│   └── hooks/                         # Phase 4
│
├── play/
│   ├── template/
│   │   ├── plan.json
│   │   └── PLAYBOOK.md
│   └── archive/
│
├── tests/
│   ├── structure/                     # 構造検証
│   │   ├── test-file-exists.sh
│   │   ├── test-references.sh
│   │   └── test-schemas.sh
│   ├── scenarios/                     # シナリオテスト
│   │   ├── scenario-01-basic-task.md
│   │   ├── scenario-02-resume.md
│   │   └── scenario-03-review.md
│   └── run-all-tests.sh
│
└── state.md                           # 現在状態（SSOT）
```

---

## 3. ドキュメント依存関係

```
                    ┌─────────────┐
                    │  README.md  │  ← エントリーポイント
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        ┌──────────┐ ┌──────────┐ ┌──────────────┐
        │ CLAUDE.md│ │GLOSSARY.md│ │ARCHITECTURE.md│
        └────┬─────┘ └─────┬────┘ └───────┬──────┘
             │             │              │
             └─────────────┼──────────────┘
                           ▼
                  ┌─────────────────┐
                  │ SPECIFICATION.md │  ← 仕様の SSOT
                  └────────┬────────┘
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
┌──────────────────┐ ┌───────────────┐ ┌──────────────┐
│IMPLEMENTATION-   │ │REVIEW-        │ │TEST-         │
│PLAN.md           │ │PROTOCOL.md    │ │PROTOCOL.md   │
└──────────────────┘ └───────────────┘ └──────────────┘
```

**読み順序**: README → GLOSSARY → ARCHITECTURE → SPECIFICATION → 目的別（実装/レビュー/テスト）

---

## 4. 実装計画（Phase 別）

### Phase -1: 概念整理（全ての出発点）

> **重要**: Phase 0 に進む前に、エンジニアリング概念を整理する。これが全ての依頼の土台になる。

```yaml
phase_-1:
  name: 概念整理
  goal: 実装の前に「何を作るか」を決定する
  duration: 概念ごとに 1 依頼
  depends_on: なし

  why: |
    - Module を作る前に「何の Module を作るか」を決める必要がある
    - SubAgent を定義する前に「どの役割を SubAgent にするか」を決める必要がある
    - 概念整理なしに実装を始めると「作りながら考える」ことになり、責務の重複や欠落が生じる
    - 鉄則: 「モジュールにする前に、エンジニアリングの概念をリストアップする」

  概念整理の順序（依存関係）:
    1_役割:
      description: 判断者 / 実行者 / 監査者 / 強制者
      output: 各 SubAgent の責務が決まる
    2_保護・制御:
      description: Hook で強制できる範囲の確定
      output: Hook と Skill/SubAgent の境界が決まる
    3_計画:
      description: playbook の粒度と構造
      note: タスクは最小作業単位まで分解
      output: playbook/phase/subtask の設計が決まる
    4_テスト:
      description: 実行者の責務と実行タイミング
      flow: 観点抽出→設計→実装→実行→失敗分類→修正→再実行
      output: テスト戦略が決まる
    5_レビュー:
      description: 監査者の責務、playbook/code の分離
      note: チェックリスト化
      output: reviewer/critic の分離が決まる
    6_状態管理:
      description: ロングタームコンテキスト設計
      elements: 保存対象/表現形式/粒度/更新契機/復元手順/破綻パターン
      output: state.md/session.json の設計が決まる
    7_追加分解:
      description: 仕様（入力形式）、変更（PR）、運用
      output: 補助的な概念の整理

  最小作業単位テンプレ:
    - Step名
    - 入力
    - 作業内容
    - 完了条件
    - 出力
    - 失敗時の分岐

  deliverables:
    - 概念分解表（分解軸と分解結果、カバー範囲/非カバー範囲）
    - マッピング表（概念 → Skill/SubAgent/Module/Hook、Hook 強制可否）
    - コンポーネント仕様一覧（責務1行、入力/出力、依存先）
    - 機能依存関係図（Layer 0〜5 の分類と構築順序）

  done_criteria:
    - 作るべきコンポーネントの一覧が確定
    - 責務の重複がない（MECE）
    - 各コンポーネントの入力/出力が明確
```

**依頼例**:
- 「役割を分解して。判断者/実行者/監査者/強制者の4分類で整理し、各 SubAgent の責務を決めて」
- 「保護・制御という概念を整理して。Hook で強制できる範囲と、Skill/SubAgent に委ねる範囲を明確にして」
- 「計画という概念を分解して。playbook の粒度と reviewer/critic の関係を整理して」
- 「レビューという概念を分解して。playbook レビューとコードレビューを分離し、担当を割り当てて」

> **重要**: モジュール化は"概念の名前"ではなく、**"人間の作業単位"と"合否判定"の境界**で行う。「入力」「処理」「出力」「検証（合否判定）」「失敗時の分岐」を持つ最小作業単位へ分解すると、並列化・リトライ・人間承認ポイント挿入・ログ追跡が可能になる。

#### 機能依存レイヤー（Layer 0-5）

構築は Layer 0 → Layer 5 の順序で進める。下位 Layer に依存するコンポーネントは、依存先が完成してから構築する。

```yaml
layer_0:
  description: 依存なし（独立コンポーネント）
  components:
    - state-updater       # 状態更新
    - file-protector      # ファイル保護
    - branch-protector    # ブランチ保護
    - prompt-analyzer     # プロンプト分析
    - test-runner         # テスト実行
    - lint-runner         # lint 実行
    - topic-classifier    # トピック分類
    - executor-resolver   # executor 判定
    - codex-invoker       # Codex 呼び出し
    - coderabbit-invoker  # CodeRabbit 呼び出し

layer_1:
  description: Layer 0 に依存
  components:
    - playbook-gate: [state-updater]
    - integrity-checker: [state-updater]
    - planner: [prompt-analyzer]
    - progress-tracker: [state-updater]

layer_2:
  description: Layer 1 に依存
  components:
    - playbook-creator: [planner]
    - code-reviewer: [test-runner, lint-runner]
    - review-aggregator: [code-reviewer, coderabbit-invoker]

layer_3:
  description: Layer 2 に依存
  components:
    - playbook-reviewer: [playbook-creator]
    - code-validator: [code-reviewer]

layer_4:
  description: Layer 3 に依存
  components:
    - critic: [playbook-reviewer, code-reviewer]

layer_5:
  description: Layer 4 に依存（最上位）
  components:
    - archive-manager: [critic]
    - orchestrator: [全て]
```

**構築の原則**:
- Layer N のコンポーネントは Layer N-1 以下が完成してから実装
- 各 Layer 内のコンポーネントは並列で構築可能
- 依存関係が明確なため、テストも Layer 順に実行

---

### Phase 0: 基盤（手動運用のみ）

```yaml
phase_0:
  name: 基盤構築
  goal: コマンド起点の手動運用が動作する
  duration: 1セッション

  deliverables:
    - README.md
    - CLAUDE.md
    - docs/GLOSSARY.md
    - docs/ARCHITECTURE.md
    - docs/SPECIFICATION.md（Phase 0 部分）
    - .claude/commands/plan.md
    - .claude/commands/work.md
    - .claude/commands/review.md
    - state.md（最小構成）

  validation:
    review:
      - SPECIFICATION.md §Phase0 の全要件を満たすか
      - ドキュメント間の参照が整合するか
    test:
      - Structure Test: 必須ファイルが存在するか
      - Reference Test: 参照が全て解決するか
      - Scenario Test: /plan → /work → /review が動作するか

  done_criteria:
    - コンテキスト0で README を読み、基本操作ができる
    - /plan でタスク計画を作成できる
    - /work でタスクを実行できる
    - /review でコードレビューができる
```

### Phase 1: 状態管理

```yaml
phase_1:
  name: 状態管理
  goal: セッション永続化と Resume/Fork が動作する
  duration: 1セッション
  depends_on: Phase 0

  deliverables:
    - contracts/schemas/state.schema.json
    - contracts/schemas/session.schema.json
    - .claude/state/session.json
    - .claude/state/session.events.jsonl
    - .claude/skills/session-control/SKILL.md
    - docs/SPECIFICATION.md（Phase 1 追記）

  validation:
    review:
      - session.json が session.schema.json に準拠するか
      - state.md との二層運用が明確か
    test:
      - Schema Test: session.json のスキーマ検証
      - Scenario Test: セッション中断 → Resume が動作するか
      - Scenario Test: Fork でブランチ分岐できるか

  done_criteria:
    - セッション中断後、別セッションで Resume できる
    - Fork で作業を分岐できる
    - session.events.jsonl から状態を復元できる
```

### Phase 2: 計画管理

```yaml
phase_2:
  name: 計画管理
  goal: playbook の二層化（JSON + Markdown）が動作する
  duration: 1セッション
  depends_on: Phase 1

  deliverables:
    - contracts/schemas/playbook.schema.json
    - contracts/templates/PLAYBOOK.template.md
    - play/template/plan.json
    - play/template/PLAYBOOK.md
    - .claude/skills/playbook-creator/SKILL.md
    - .claude/skills/playbook-sync/SKILL.md
    - docs/SPECIFICATION.md（Phase 2 追記）

  validation:
    review:
      - plan.json が playbook.schema.json に準拠するか
      - PLAYBOOK.md が人間可読か
      - 同期ロジックが明確か
    test:
      - Schema Test: plan.json のスキーマ検証
      - Scenario Test: playbook 作成 → 進捗更新 → 完了 が動作するか
      - Sync Test: JSON 変更 → MD 同期、MD 変更 → JSON 同期

  done_criteria:
    - /plan で playbook（JSON + MD）が作成される
    - 進捗更新が両方に反映される
    - コンテキスト0で PLAYBOOK.md を読んでタスクが理解できる
```

### Phase 3: 品質保証

```yaml
phase_3:
  name: 品質保証
  goal: レビュー・テストのスキルが動作する
  duration: 1セッション
  depends_on: Phase 2

  deliverables:
    - .claude/skills/review/SKILL.md
    - .claude/skills/test/SKILL.md
    - .claude/skills/quality-gate/SKILL.md
    - docs/REVIEW-PROTOCOL.md
    - docs/TEST-PROTOCOL.md
    - tests/structure/*
    - tests/scenarios/*
    - docs/SPECIFICATION.md（Phase 3 追記）

  validation:
    review:
      - レビュースキルが 5 観点を網羅しているか
      - テストスキルが 5 種別を網羅しているか
    test:
      - Scenario Test: /review が正しくレビューを実行するか
      - Scenario Test: テストスイートが正しく動作するか

  done_criteria:
    - /review でコンテキスト0レビューが実行できる
    - テストスイートが自動実行できる
    - 品質ゲートが PASS/FAIL を正しく判定する
```

### Phase 4: 自動化（Hook 統合）

```yaml
phase_4:
  name: 自動化
  goal: Hook による補助的な自動化が動作する
  duration: 1セッション
  depends_on: Phase 3

  deliverables:
    - .claude/hooks/session.sh
    - .claude/hooks/pre-tool.sh（最小限）
    - .claude/hooks/post-tool.sh（最小限）
    - contracts/schemas/safety.schema.json
    - docs/SPECIFICATION.md（Phase 4 追記）

  validation:
    review:
      - Hook が「検出・通知」に限定されているか
      - 「強制」は Workflow で行っているか
    test:
      - Scenario Test: SessionStart で状態が復元されるか
      - Scenario Test: PreToolUse でガードが発火するか

  done_criteria:
    - Hook がトリガーされる
    - Hook は通知のみ、強制は Workflow で行う
    - Phase 0-3 の機能が引き続き動作する（回帰テスト）
```

---

## 5. コンテキスト0検証プロトコル

### 5.1 検証の実行方法

```yaml
context_0_verification:
  preparation:
    - 新しい Claude Code セッションを開始
    - 「私は新しいセッションです。このリポジトリを理解して、{タスク}を実行してください」と入力

  verification_points:
    1_can_understand:
      question: README を読んで目的を理解できるか
      method: Claude に「このリポジトリの目的を説明して」と聞く
      pass_criteria: IMPLEMENTATION-PLAN-V2.md の目的と一致する回答

    2_can_navigate:
      question: 必要なドキュメントを見つけられるか
      method: 「Phase 2 を実装するにはどのファイルを読むべきか」と聞く
      pass_criteria: IMPLEMENTATION-PLAN.md の Phase 2 を参照する回答

    3_can_execute:
      question: 指示に従って実行できるか
      method: 「Phase 2 を実装して」と依頼する
      pass_criteria: IMPLEMENTATION-PLAN.md の通りに実装が進む

    4_can_review:
      question: レビューを正しく実行できるか
      method: 「Phase 2 をレビューして」と依頼する
      pass_criteria: REVIEW-PROTOCOL.md の通りにレビューが進む

    5_can_test:
      question: テストを正しく実行できるか
      method: 「Phase 2 をテストして」と依頼する
      pass_criteria: TEST-PROTOCOL.md の通りにテストが進む
```

---

## 6. 実装スケジュール

```
Week 1: Phase 0（基盤）
  Day 1-2: ドキュメント作成
  Day 3: コマンド定義
  Day 4: コンテキスト0レビュー
  Day 5: コンテキスト0テスト + 修正

Week 2: Phase 1（状態管理）
  Day 1-2: スキーマ + スキル実装
  Day 3: セッション永続化実装
  Day 4: コンテキスト0レビュー
  Day 5: コンテキスト0テスト + 修正

Week 3: Phase 2（計画管理）
  Day 1-2: playbook 二層化実装
  Day 3: 同期スクリプト実装
  Day 4: コンテキスト0レビュー
  Day 5: コンテキスト0テスト + 修正

Week 4: Phase 3（品質保証）
  Day 1-2: レビュー/テストスキル実装
  Day 3: テストスイート作成
  Day 4: コンテキスト0レビュー
  Day 5: コンテキスト0テスト + 修正

Week 5: Phase 4（自動化）+ 総合検証
  Day 1-2: Hook 最小実装
  Day 3: 回帰テスト
  Day 4: 総合コンテキスト0レビュー
  Day 5: 総合コンテキスト0テスト + 最終修正
```

---

## 7. 成功基準

```yaml
success_criteria:
  overall:
    - コンテキスト0で README を読み、全 Phase を実装できる
    - コンテキスト0でレビューを実行し、問題を検出できる
    - コンテキスト0でテストを実行し、PASS/FAIL を判定できる
    - Phase 4 完了後、回帰テストが全て PASS

  per_phase:
    phase_0:
      - 手動コマンドで /plan /work /review が動作
    phase_1:
      - Resume/Fork が動作
    phase_2:
      - playbook 二層化が動作、同期が正しい
    phase_3:
      - レビュー/テストスキルが動作
    phase_4:
      - Hook が発火、回帰テスト PASS
```

---

## 8. Codex 統合分析（追加）

Codex の分析結果を統合した改善案:

### 8.1 Core Control Plane

```yaml
追加ディレクトリ:
  - .claude/commands/     # コマンド定義
  - .claude/workflows/    # ワークフロー定義
  - profiles/             # プロファイル設定

設計原則:
  - /plan /work /review を手動で確実に回すレイヤーを新設
  - Hook は補助に限定
```

### 8.2 Workflow 集約

```yaml
原則:
  - Hook の処理は Workflow の再利用に寄せる
  - Event Unit は ガード/テレメトリ/復旧補助 へスコープ縮小
  - ロジック重複を禁止
```

### 8.3 段階導入

```yaml
phase_0: 手動のみ
phase_1: セッション/ログ
phase_2: 計画管理
phase_3: 品質保証
phase_4: 自動化

原則: Hook 自動化は Phase 4（最後）
```

---

## 参照

- HARNESS-ANALYSIS.md（harness 分析結果）
- REVIEW-PROTOCOL.md（レビュー手順）
- TEST-PROTOCOL.md（テスト手順）
- FAILURE-CATALOG.md（失敗カタログ）
- GLOSSARY.md（用語定義）
