# レビュープロトコル

> **文書の位置付け**: レビュー手順の厳密な定義
>
> **MECE 役割**: レビューの定義・観点・手順・出力形式の SSOT
>
> **作成日**: 2026-01-22

---

## 1. レビューとは何か

### 1.1 定義

```yaml
review:
  definition: |
    成果物が仕様を満たしているかを、
    コンテキスト0（過去の議論を知らない状態）で検証する行為

  input:
    - 成果物（コード、ドキュメント、設定ファイル）
    - 仕様書（IMPLEMENTATION-PLAN-V2.md + 関連スキーマ）

  output:
    status: PASS | FAIL | CONDITIONAL_PASS
    issues:
      - id: R-001
        severity: critical | major | minor | suggestion
        location: ファイルパス:行番号
        description: 問題の説明
        spec_reference: 違反している仕様への参照

  constraint:
    - レビュアーは過去のチャット履歴を参照してはならない
    - 判断はドキュメントとコードのみから行う
    - 「意図」ではなく「実装」を評価する
```

### 1.2 なぜコンテキスト0でレビューするか

- **再現性**: 誰がレビューしても同じ結果になる
- **客観性**: 作成者の意図に引きずられない
- **自己完結性の検証**: ドキュメントだけで理解できるか確認

---

## 2. レビュー観点（5観点）

### 2.1 Spec Compliance（仕様準拠）

```yaml
question: 仕様書の要件を全て満たしているか？
method:
  - IMPLEMENTATION-PLAN-V2.md の各要件を抽出
  - 成果物が各要件を満たすか検証
  - 満たさない場合は FAIL + 要件番号を記録
evidence: 要件対応表（Traceability Matrix）

example_check:
  - [ ] 全ての必須フィールドが存在するか
  - [ ] 型定義がスキーマと一致するか
  - [ ] 命名規則に従っているか
```

### 2.2 Self-Containment（自己完結性）

```yaml
question: このドキュメント/コードは単独で理解可能か？
method:
  - 外部参照を全て列挙
  - 各参照が存在し、アクセス可能か確認
  - 未定義の用語がないか確認（GLOSSARY.md と照合）
evidence: 参照整合性レポート

example_check:
  - [ ] 全ての参照先ファイルが存在するか
  - [ ] 未定義の用語がないか
  - [ ] 前提知識なしで読めるか
```

### 2.3 Internal Consistency（内部整合性）

```yaml
question: 内部矛盾がないか？
method:
  - 同じ概念に対する記述を全て抽出
  - 矛盾する記述がないか確認
  - 型定義とスキーマの整合性確認
evidence: 矛盾検出レポート

example_check:
  - [ ] 同じ概念の説明が一貫しているか
  - [ ] 数値・日付が矛盾していないか
  - [ ] 状態遷移に矛盾がないか
```

### 2.4 Completeness（完全性）

```yaml
question: 必要な情報が全て揃っているか？
method:
  - テンプレートの必須項目と照合
  - TODO/FIXME/TBD が残っていないか確認
  - エラーケースの定義があるか確認
evidence: 完全性チェックリスト

example_check:
  - [ ] 必須セクションが全て存在するか
  - [ ] TODO/FIXME/TBD が残っていないか
  - [ ] エラーケースが定義されているか
  - [ ] エッジケースが考慮されているか
```

### 2.5 Testability（テスト可能性）

```yaml
question: この仕様/実装はテスト可能か？
method:
  - 各仕様に対応するテストケースが存在するか
  - テストケースが実行可能か
  - 合否判定基準が明確か
evidence: テスト対応表

example_check:
  - [ ] 各機能に対応するテストがあるか
  - [ ] 合否判定基準が明確か
  - [ ] 自動テストが可能か
```

---

## 3. レビュー手順

### Phase 1: 準備（10%）

```yaml
actions:
  - 新しい Claude Code セッションを開始（コンテキスト0）
  - README.md を読む
  - GLOSSARY.md を読む
  - IMPLEMENTATION-PLAN-V2.md を読む
  - レビュー対象の範囲を確認
```

### Phase 2: 体系的チェック（60%）

```yaml
actions:
  - 5観点それぞれについて順番に検証
  - 発見した問題を即座に記録
  - 判断に迷う場合は「要確認」として記録

order:
  1. Spec Compliance
  2. Self-Containment
  3. Internal Consistency
  4. Completeness
  5. Testability
```

### Phase 3: クロスチェック（20%）

```yaml
actions:
  - 発見した問題の重複を排除
  - 問題間の関連性を確認
  - 根本原因の特定
```

### Phase 4: レポート作成（10%）

```yaml
actions:
  - REVIEW-REPORT.template.md に従ってレポート作成
  - 総合判定（PASS/FAIL/CONDITIONAL_PASS）
  - 次のアクションを明記
```

---

## 4. レビューレポートテンプレート

```markdown
# Review Report

## メタ情報
- レビュー対象: {対象の範囲}
- レビュー日時: {YYYY-MM-DD HH:MM}
- レビュアー: Claude Code (Context-0)
- 参照仕様: IMPLEMENTATION-PLAN-V2.md v{version}

## 総合判定
**{PASS | FAIL | CONDITIONAL_PASS}**

## 観点別結果

| 観点 | 結果 | 問題数 |
|------|------|--------|
| Spec Compliance | {PASS/FAIL} | {N} |
| Self-Containment | {PASS/FAIL} | {N} |
| Internal Consistency | {PASS/FAIL} | {N} |
| Completeness | {PASS/FAIL} | {N} |
| Testability | {PASS/FAIL} | {N} |

## 検出された問題

### Critical（修正必須）
| ID | 場所 | 説明 | 仕様参照 |
|----|------|------|---------|
| R-001 | {path:line} | {description} | SPEC §{section} |

### Major（修正推奨）
...

### Minor（軽微）
...

## 次のアクション
1. {具体的なアクション}
2. {具体的なアクション}
```

---

## 5. 判定基準

### PASS

```yaml
condition:
  - Critical が 0 件
  - Major が 0 件
  - 5観点すべてが PASS
```

### CONDITIONAL_PASS

```yaml
condition:
  - Critical が 0 件
  - Major が 1-2 件（修正期限付きで承認）
  - 5観点のうち 4 以上が PASS
```

### FAIL

```yaml
condition:
  - Critical が 1 件以上
  - または Major が 3 件以上
  - または 5観点のうち 2 以上が FAIL
```

---

## 6. Evidence 3点検証（validations）

### 6.1 定義

Evidence（証拠）は以下の **3点** が全て揃って初めて有効とみなす。

```yaml
evidence_validation:
  three_points:
    1_technical:
      definition: 実行可能なコマンドで証明する
      example:
        - "test -f ./path/to/file.md → 存在確認"
        - "npm test → テスト PASS"
        - "grep 'pattern' file.md → 内容確認"
      fail_if: コマンドが存在しない、実行不能、期待と不一致

    2_consistency:
      definition: 関係ファイルと矛盾しないこと
      example:
        - "state.md の playbook.active と plan.json のパスが一致"
        - "GLOSSARY.md の用語定義と本文の用語が一致"
        - "参照先ファイルが全て存在"
      fail_if: 同一概念に矛盾する記述、壊れた参照

    3_completeness:
      definition: 欠落のない状態であること
      example:
        - "全ての done_criteria に対応する Evidence が存在"
        - "TODO/FIXME/TBD が残っていない"
        - "必須セクションが全て存在"
      fail_if: 未検証の criterion、欠損データ
```

### 6.2 検証の順序

```yaml
validation_order:
  1. technical: まず実行可能なコマンドで検証
  2. consistency: 次に他ファイル/基準との整合を確認
  3. completeness: 最後に漏れがないか確認

rationale: |
  technical が失敗すると consistency/completeness の検証が無意味になる。
  consistency が失敗すると completeness の判断が困難になる。
  この順序で検証することで、失敗の原因特定が容易になる。
```

### 6.3 3点検証の出力形式

```yaml
subtask_validation_example:
  p1.1:
    validations:
      technical:
        status: PASS | FAIL | PENDING
        command: "test -f ./docs/spec.md"
        evidence: ["ファイル存在確認: 2026-01-22"]
      consistency:
        status: PASS | FAIL | PENDING
        evidence: ["GLOSSARY.md との用語一致確認"]
      completeness:
        status: PASS | FAIL | PENDING
        evidence: ["全セクション存在確認"]
```

> **重要**: 3点検証が揃わない Evidence は「存在しない」とみなす。critic は 3点全てが PASS の subtask のみを完了として認定する。

---

## 7. 時間的達成可能性（Temporal Achievability）

### 7.1 定義

```yaml
temporal_achievability:
  definition: |
    criterion が「評価時点で達成可能」かどうかを検証する。
    将来の状態や外部完了を前提とする criterion は FAIL。

  rationale: |
    達成不可能な基準は、必ずデッドロックを生む。
    時間的達成可能性は、報酬詐欺と同じくらい重要である。
```

### 7.2 典型的な FAIL 例

```yaml
fail_examples:
  - name: "playbook なし状態の要求"
    criterion: "playbook.active が null であること"
    context: "作業中（playbook.active が設定されている状態）"
    reason: "評価時点で達成不可能"

  - name: "未来の完了を前提"
    criterion: "レビューが完了していること"
    context: "レビュー実行前の phase"
    reason: "まだ発生していない"

  - name: "全 subtask 完了を途中 phase に要求"
    criterion: "すべての subtask が完了していること"
    context: "Phase 1 の done_criteria"
    reason: "Phase 2 以降の subtask は未完了"
```

### 7.3 レビュー時の確認方法

```yaml
review_checklist:
  - question: "この criterion は評価時点で判定可能か？"
    pass: "Yes - 現在の状態で判定できる"
    fail: "No - 将来の状態を前提としている"

  - question: "外部依存はないか？"
    pass: "No - 自己完結している"
    fail: "Yes - 他の phase/subtask/外部システムに依存"

  - question: "時間順序を尊重しているか？"
    pass: "Yes - 前の phase で達成されるべきことを前提としていない"
    fail: "No - 後続 phase の成果を前提としている"
```

### 7.4 適用

- playbook の `done_criteria` は全て temporal achievability を通過しなければならない
- reviewer は plan.json のレビュー時に必ず時間的達成可能性を検証する
- 違反した criterion は即座に FAIL とし、修正を要求する

---

## 8. レビュー対象別ガイド

### コードレビュー

```yaml
additional_checks:
  - セキュリティ脆弱性（OWASP Top 10）
  - パフォーマンス問題（N+1, 無限ループ）
  - 型安全性
  - エラーハンドリング
```

### ドキュメントレビュー

```yaml
additional_checks:
  - 読みやすさ（構造、文体）
  - 最新性（日付、バージョン）
  - 正確性（技術的な正しさ）
```

### 設定ファイルレビュー

```yaml
additional_checks:
  - スキーマ準拠
  - セキュリティ設定
  - 環境依存の排除
```

---

## 参照

- TEST-PROTOCOL.md（テスト手順）
- GLOSSARY.md（用語定義）
- IMPLEMENTATION-PLAN-V2.md（実装計画）
- FAILURE-CATALOG.md（失敗カタログ）
