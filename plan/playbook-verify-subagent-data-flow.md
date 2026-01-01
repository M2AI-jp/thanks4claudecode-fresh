# playbook-verify-subagent-data-flow.md

> **playbook-subagent-data-flow.md の修正内容を網羅的に検証する**

---

## meta

```yaml
project: verify-subagent-data-flow
branch: verify/subagent-data-flow
created: 2026-01-01
issue: null
reviewed: true
roles:
  worker: codex
```

---

## context

```yaml
5w1h:
  what: playbook-subagent-data-flow.md の修正内容を網羅的に検証する
  why: |
    修正が「実装された」と主張されているが、本当に正しく実装されているか
    実際にコマンドを実行して証拠を残す必要がある
  who: Claude Code フレームワークの品質保証
  when: 即時実行
  where: |
    - .claude/skills/term-translator/agents/term-translator.md
    - .claude/skills/understanding-check/SKILL.md
    - .claude/skills/golden-path/agents/pm.md
    - .claude/skills/prompt-analyzer/agents/prompt-analyzer.md
    - .claude/skills/context-management/SKILL.md
    - .claude/skills/quality-assurance/agents/reviewer.md
    - .claude/skills/reward-guard/agents/critic.md
    - plan/template/playbook-format.md
  how: grep/cat コマンドで実際にファイル内容を検証し、証拠を記録
```

---

## goal

```yaml
summary: playbook-subagent-data-flow.md の done_when 6項目が全て正しく実装されているか検証する

done_when:
  - term-translator に「テスト」「検証」の変換ルールが存在し、内容が適切である
  - understanding-check が translated_requirements を参照している
  - playbook-format.md と context-management に永続化フィールドが定義されている
  - prompt-analyzer に test_strategy, preconditions, success_criteria, reverse_dependencies が追加されている
  - validations に validation_type と証拠記録形式が定義されている
  - reviewer に 4QV+ の具体的判定基準と PASS/FAIL ログ形式が定義されている
```

---

## phases

### p1: term-translator 検証

**goal**: Issue 2 の修正を検証 - 「テスト」「検証」変換ルールの存在と内容確認

#### subtasks

- [x] **p1.1**: term-translator に「テスト」変換ルールが存在し、unit/integration/e2e の区別が明記されている
  - executor: codex
  - validations:
    - technical: PASS - grep で変換ルール全体を確認、unit/integration/e2e の区別あり
    - consistency: PASS - default, context, coverage_target, rationale が含まれている
    - completeness: PASS - 正常系/異常系/境界値の言及あり、anti_patterns も定義
  - validated: 2026-01-01T21:00:00Z

- [x] **p1.2**: term-translator に「検証」変換ルールが存在し、automated/manual/hybrid の区別が明記されている
  - executor: codex
  - validations:
    - technical: PASS - grep で変換ルール全体を確認、types セクションに詳細あり
    - consistency: PASS - types, validator, evidence_required, rationale が含まれている
    - completeness: PASS - automated/static_analysis/peer_review/manual の説明あり
  - validated: 2026-01-01T21:00:00Z

**status**: done
**max_iterations**: 3

---

### p2: understanding-check 検証

**goal**: Issue 3 の修正を検証 - translated_requirements 参照の実装確認

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: understanding-check に translated_requirements 参照セクションが存在する
  - executor: codex
  - validations:
    - technical: PASS - grep で「## translated_requirements（term-translator 連携）」セクション確認
    - consistency: PASS - term-translator の出力形式（original, translated, alternatives）と整合
    - completeness: PASS - 「技術用語でユーザーに確認する」指示あり
  - validated: 2026-01-01T21:01:00Z

- [x] **p2.2**: pm.md に prompt-analyzer → term-translator → understanding-check のデータフローが定義されている
  - executor: codex
  - validations:
    - technical: PASS - grep で「## SubAgent 間データフロー定義」セクション確認
    - consistency: PASS - 各 SubAgent の出力が次の入力として明示的に定義
    - completeness: PASS - フロー図と「データフロー断絶防止チェック」セクションあり
  - validated: 2026-01-01T21:01:00Z

**status**: done
**max_iterations**: 3

---

### p3: playbook context 永続化検証

**goal**: Issue 6 の修正を検証 - context セクションへの永続化フィールド追加確認

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: playbook-format.md に analysis_result, translated_requirements, user_approved_understanding フィールドが定義されている
  - executor: codex
  - validations:
    - technical: PASS - grep で 20 件マッチ（3つ以上存在確認）
    - consistency: PASS - context セクション内に定義されている
    - completeness: PASS - 各フィールドの説明、形式、source, timestamp が明記
  - validated: 2026-01-01T21:02:00Z

- [x] **p3.2**: context-management の must_keep に永続化フィールドが追加されている
  - executor: codex
  - validations:
    - technical: PASS - grep で must_keep セクションに3フィールド全て含まれている
    - consistency: PASS - 既存の must_keep 項目と同じ形式
    - completeness: PASS - analysis_result, translated_requirements, user_approved_understanding 全て追加済み
  - validated: 2026-01-01T21:02:00Z

**status**: done
**max_iterations**: 3

---

### p4: prompt-analyzer 検証

**goal**: Issue 1 の修正を検証 - 4つの新規分析項目の追加確認

**depends_on**: [p1]

#### subtasks

- [x] **p4.1**: prompt-analyzer に test_strategy 分析項目が存在し、内容が適切である
  - executor: codex
  - validations:
    - technical: PASS - grep で「### test_strategy（テスト戦略）」セクション確認
    - consistency: PASS - test_types, coverage_target, edge_cases が含まれている
    - completeness: PASS - unit/integration/e2e の説明、カバレッジ目標、エッジケース検出が明記
  - validated: 2026-01-01T21:03:00Z

- [x] **p4.2**: prompt-analyzer に preconditions 分析項目が存在し、内容が適切である
  - executor: codex
  - validations:
    - technical: PASS - grep で「### preconditions（前提条件）」セクション確認
    - consistency: PASS - existing_code, dependencies, constraints が含まれている
    - completeness: PASS - 「何が既に存在するか」を分析する指示あり
  - validated: 2026-01-01T21:03:00Z

- [x] **p4.3**: prompt-analyzer に success_criteria 分析項目が存在し、内容が適切である
  - executor: codex
  - validations:
    - technical: PASS - grep で「### success_criteria（成功基準）」セクション確認
    - consistency: PASS - functional, non_functional, breaking_changes が含まれている
    - completeness: PASS - 機能要件/非機能要件/破壊的変更の説明あり
  - validated: 2026-01-01T21:03:00Z

- [x] **p4.4**: prompt-analyzer に reverse_dependencies 分析項目が存在し、内容が適切である
  - executor: codex
  - validations:
    - technical: PASS - grep で「### reverse_dependencies（逆依存関係）」セクション確認
    - consistency: PASS - affected_components が含まれている
    - completeness: PASS - 「これに依存するもの」を分析する指示と調査コマンド例あり
  - validated: 2026-01-01T21:04:00Z

- [x] **p4.5**: prompt-analyzer の出力フォーマットに全ての新規項目が含まれている
  - executor: codex
  - validations:
    - technical: PASS - 出力フォーマットに test_strategy, preconditions, success_criteria, reverse_dependencies 全て含まれている
    - consistency: PASS - analysis セクション内に4項目全てが定義
    - completeness: PASS - 全4項目が出力フォーマットに定義されている
  - validated: 2026-01-01T21:04:00Z

**status**: done
**max_iterations**: 3

---

### p5: validations 実行フロー検証

**goal**: Issue 4 の修正を検証 - validation_type と証拠記録形式の追加確認

**depends_on**: [p3]

#### subtasks

- [x] **p5.1**: playbook-format.md に validation_type（automated/manual/hybrid）の定義がある
  - executor: codex
  - validations:
    - technical: PASS - grep で「## validation_types（M088: 検証タイプ分類）」セクション確認
    - consistency: PASS - 各タイプの説明が詳しく記載されている
    - completeness: PASS - 各タイプの判定ルールが明記、critic扱いも定義
  - validated: 2026-01-01T21:05:00Z

- [x] **p5.2**: playbook-format.md に evidence/command の記録形式が定義されている
  - executor: codex
  - validations:
    - technical: PASS - grep で 28 件マッチ（validation_type + evidence）
    - consistency: PASS - validations セクション内に定義されている
    - completeness: PASS - 記録形式の例が含まれている（具体例あり）
  - validated: 2026-01-01T21:05:00Z

- [x] **p5.3**: critic.md に validation_type 対応が追加されている
  - executor: codex
  - validations:
    - technical: PASS - grep で「## validation_type 対応（M089）」セクション確認
    - consistency: PASS - automated/manual/hybrid の扱いが定義されている
    - completeness: PASS - manual は PENDING (DEFERRED 扱い) になる指示がある
  - validated: 2026-01-01T21:05:00Z

**status**: done
**max_iterations**: 3

---

### p6: reviewer 判定基準検証

**goal**: Issue 5 の修正を検証 - 4QV+ 具体的判定基準と PASS/FAIL ログ形式の追加確認

**depends_on**: [p5]

#### subtasks

- [x] **p6.1**: reviewer.md に Q1-Q4 + Plus の具体的なチェック基準が定義されている
  - executor: codex
  - validations:
    - technical: PASS - grep で 30 件マッチ（Q1-Q4 + Plus 全項目）
    - consistency: PASS - Q1-Q4 全てに PASS 条件が明示されている
    - completeness: PASS - 各項目に検証コマンド/具体的な検証方法がある
  - validated: 2026-01-01T21:06:00Z

- [x] **p6.2**: reviewer.md の出力フォーマットに各 Q の PASS/FAIL ログが含まれている
  - executor: codex
  - validations:
    - technical: PASS - grep で「### 出力フォーマット」セクション確認
    - consistency: PASS - Q1-Q4 全ての判定結果が出力される
    - completeness: PASS - 各 Q の evidence（判定根拠）が含まれている
  - validated: 2026-01-01T21:06:00Z

**status**: done
**max_iterations**: 3

---

### p_final: 全体整合性検証（必須）

**goal**: done_when 6項目が全て満たされているか最終確認

**depends_on**: [p1, p2, p3, p4, p5, p6]

#### subtasks

- [x] **p_final.1**: term-translator の変換ルールが完全である
  - executor: codex
  - validations:
    - technical: PASS - grep で「テスト」1件、「検証」1件 - 両方存在
    - consistency: PASS - 変換ルール辞書の形式に従っている
    - completeness: PASS - テストと検証の両方が適切な内容で定義されている
  - validated: 2026-01-01T21:07:00Z

- [x] **p_final.2**: understanding-check のデータフロー連携が完全である
  - executor: codex
  - validations:
    - technical: PASS - grep 'translated_requirements' で3箇所存在確認
    - consistency: PASS - pm.md のフローと連携している
    - completeness: PASS - 技術用語でユーザー確認する仕組みがある
  - validated: 2026-01-01T21:07:00Z

- [x] **p_final.3**: playbook context 永続化が完全である
  - executor: codex
  - validations:
    - technical: PASS - grep で 20 件マッチ（3つのフィールド全て存在）
    - consistency: PASS - context-management の must_keep に含まれている
    - completeness: PASS - 3つ全てが定義されている
  - validated: 2026-01-01T21:07:00Z

- [x] **p_final.4**: prompt-analyzer の分析項目が完全である
  - executor: codex
  - validations:
    - technical: PASS - grep で 16 件マッチ（4つ以上存在確認）
    - consistency: PASS - 出力フォーマットに全項目が含まれている
    - completeness: PASS - 各項目に必要なサブフィールドがある
  - validated: 2026-01-01T21:08:00Z

- [x] **p_final.5**: validations 実行フローが完全である
  - executor: codex
  - validations:
    - technical: PASS - grep で 28 件マッチ（validation_type + evidence）
    - consistency: PASS - critic が validation_type を扱う
    - completeness: PASS - PASS/FAIL と証拠の記録方法がある
  - validated: 2026-01-01T21:08:00Z

- [x] **p_final.6**: reviewer の判定基準が完全である
  - executor: codex
  - validations:
    - technical: PASS - grep で 30 件マッチ（Q1-Q4 + Plus 全項目）
    - consistency: PASS - 4QV+ 全項目に具体的基準がある
    - completeness: PASS - 出力に各 Q の判定結果と証拠が含まれる
  - validated: 2026-01-01T21:08:00Z

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

- [ ] **ft2**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft3**: tmp/ ディレクトリをクリーンアップする
  - command: `rm -rf tmp/* 2>/dev/null || true`
  - status: pending
