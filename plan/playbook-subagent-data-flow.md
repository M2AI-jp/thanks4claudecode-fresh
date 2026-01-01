# playbook-subagent-data-flow.md

> **SubAgent 間のデータフロー断絶を修正し、プログラミング言語実装に耐えうる設計に改善する**

---

## meta

```yaml
project: subagent-data-flow
branch: fix/subagent-data-flow
created: 2026-01-01
issue: null
reviewed: true
roles:
  worker: claudecode
```

---

## context

```yaml
5w1h:
  what: SubAgent 間のデータフロー断絶を修正する
  why: |
    現状の設計は「関数は定義したが引数を渡していない」状態。
    AI駆動開発の失敗の根本原因がここにある。
  who: Claude Code フレームワークの利用者（開発者）
  when: 次のセッションから開始
  where: |
    - .claude/skills/prompt-analyzer/agents/prompt-analyzer.md
    - .claude/skills/term-translator/agents/term-translator.md
    - .claude/skills/understanding-check/SKILL.md
    - .claude/skills/golden-path/agents/pm.md
    - .claude/skills/quality-assurance/agents/reviewer.md
    - .claude/skills/context-management/SKILL.md
    - plan/template/playbook-format.md
  how: 各 SubAgent の入出力仕様を明確化し、データフローを繋ぐ

diagnosis_date: 2026-01-01
diagnosed_by: claudecode (Opus 4.5)
```

---

## 診断結果（Critical Issues）

### Issue 1: prompt-analyzer に不足している本質的要素

```yaml
現状:
  - 5W1H 分析
  - リスク分析（technical/scope/dependency）
  - 曖昧さ検出

致命的不足:
  preconditions:
    問題: "何が既に存在するか" を分析していない
    必要: 既存コードの状態、依存ライブラリ、設定の現状

  success_criteria:
    問題: "ready_for_playbook: true/false" だけでは不十分
    必要: |
      - 機能要件の達成基準（何が動けば成功か）
      - 非機能要件（パフォーマンス、セキュリティ、可用性）
      - 破壊的変更の有無（既存機能への影響）

  test_strategy:
    問題: テストについての言及がゼロ
    必要: |
      - どの粒度でテストするか（unit/integration/e2e）
      - 何をテスト対象とするか（正常系/異常系/境界値）
      - カバレッジ目標

  reverse_dependencies:
    問題: "これが依存するもの" は分析するが "これに依存するもの" がない
    必要: 変更が波及する範囲の特定
```

### Issue 2: term-translator の「テスト」「検証」厳密判定の欠如

```yaml
現状の変換辞書（問題あり）:
  "うまく動く": "正常系・異常系テストが通る"  # ← 何のテスト？
  "正しく": "仕様通り + バリデーション済み"  # ← 仕様はどこ？

AI駆動開発の失敗パターン:
  1. "テストが通る" = 成功と判定してしまう
     → 実際には空のテストファイルでも "通る"
  2. "検証済み" の意味が曖昧
     → 自動テスト？手動確認？コードレビュー？目視？
  3. テストの網羅性が不明
     → 正常系1件だけ通って "テスト通過" と判定

根本問題:
  term-translator に「テスト」「検証」の変換ルールが存在しない
```

### Issue 3: understanding-check が変換結果を使っていない

```yaml
連携の断絶:
  prompt-analyzer → ambiguity: ["セキュアに", "認証機能"]
          ↓
  term-translator → translated: "AES-256暗号化 + アクセス制御"
          ↓
  understanding-check → ★ここで元の曖昧表現を使っている★
          ↓
  ユーザーに提示: "セキュアに認証機能を実装しますか？"
                     ^^^^^^ 変換結果が反映されていない！

結果:
  - ユーザーは曖昧な表現で承認してしまう
  - 技術要件が確定しないまま playbook が作成される
  - 後工程で「思っていたのと違う」が発生
```

### Issue 4: validations（3点検証）が機能していない

```yaml
問題1: 観点と検証方法の混在
  technical: "bash -n でシンタックスエラーがない" → 良い（実行可能）
  consistency: "他の関数と処理方式が整合している" → どうやって確認？主観？

問題2: subtask 完了判定のタイミングが不明
  - 誰が validations を実行するか定義されていない
  - critic SubAgent が実行？Claude が自己判定？
  - 自己判定なら報酬詐欺の温床

問題3: 検証結果のログがない
  - PASS/FAIL の記録がない
  - 証拠が残らない

現状: subtask を [x] にする → 誰が判定したか不明
```

### Issue 5: reviewer の判定基準が曖昧

```yaml
曖昧な判定:
  Q2: "禁止パターンに該当しないか" → チェック方法が不明
  Q4: "漏れている Phase はないか" → 何をもって漏れとするか
  Plus: "報酬詐欺の可能性" → 具体的な検出方法がない

ログの欠如:
  - 各 Q の PASS/FAIL が記録されない
  - 最終的な "PASS/FAIL" のみが出力される
  - なぜ PASS したかの証拠がない
```

### Issue 6: コンテキスト破綻防止の設計欠陥

```yaml
保持されていないもの:
  - prompt-analyzer の分析結果（5W1H, リスク）
  - term-translator の変換結果（技術要件）
  - understanding-check でユーザーが承認した内容

compact 後に失われるもの:
  - "なぜこの要件になったか" の経緯
  - "ユーザーが何を承認したか" の証拠
  - "どの曖昧表現をどう変換したか"

結果:
  - compact 後に "ユーザーの意図" が失われる
  - playbook の context セクションにこれらが保存されていない
```

---

## 根本原因

```yaml
本質:
  「関数は定義したが、引数を渡していない」状態

具体的問題:
  1. 変数の受け渡しがない:
     - SubAgent 間のデータフローが定義されていない
     - prompt-analyzer の出力を term-translator が受け取る仕組みがない

  2. 状態の永続化がない:
     - 分析結果が playbook に保存されない
     - compact で消える情報がある

  3. 検証が主観的:
     - "正しく動作する" の定義がない
     - PASS/FAIL の判定基準が曖昧

  4. テスト概念の欠如:
     - テスト戦略が prompt-analyzer にない
     - テスト/検証の変換ルールが term-translator にない
```

---

## goal

```yaml
summary: SubAgent 間のデータフロー断絶を修正し、検証可能なシステムに改善する

done_when:
  - term-translator に「テスト」「検証」の変換ルールが追加されている
  - understanding-check が term-translator の出力を参照して技術用語でユーザーに確認している
  - playbook の context セクションに analysis_result, translated_requirements, user_approved_understanding が永続化される仕組みがある
  - prompt-analyzer にテスト戦略（test_strategy）の分析項目が追加されている
  - validations の実行フローが定義され、subtask 完了判定が自動化されている
  - reviewer の判定基準が具体化され、各 Q の PASS/FAIL がログに記録される
```

---

## phases

### p1: term-translator に「テスト」「検証」変換ルール追加

**goal**: AI駆動開発の失敗の根本原因を解消する

**priority**: 最高（ここが直らないと全てが曖昧なまま）

#### subtasks

- [ ] **p1.1**: term-translator に「テスト」の変換ルールが追加されている
  - executor: claudecode
  - validations:
    - technical: "grep -A20 'テスト:' .claude/skills/term-translator/agents/term-translator.md で変換ルール確認"
    - consistency: "unit/integration/e2e の区別が明記されている"
    - completeness: "正常系/異常系/境界値、カバレッジ目標が含まれている"

- [ ] **p1.2**: term-translator に「検証」の変換ルールが追加されている
  - executor: claudecode
  - validations:
    - technical: "grep -A20 '検証:' .claude/skills/term-translator/agents/term-translator.md で変換ルール確認"
    - consistency: "自動テスト/静的解析/レビュー/手動の区別が明記されている"
    - completeness: "検証者（self/peer/user）と検証基準が含まれている"

**status**: pending
**max_iterations**: 5

---

### p2: understanding-check の変換結果参照

**goal**: ユーザーに技術用語で確認し、曖昧さを排除する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: understanding-check が term-translator の出力を必須参照するよう修正されている
  - executor: claudecode
  - validations:
    - technical: "grep 'translated_requirements' .claude/skills/understanding-check/SKILL.md で参照確認"
    - consistency: "pm.md のフローと整合している"
    - completeness: "出力テンプレートに技術要件が含まれている"

- [ ] **p2.2**: pm.md のフローが understanding-check に変換結果を渡すよう修正されている
  - executor: claudecode
  - validations:
    - technical: "grep -A10 'understanding-check' .claude/skills/golden-path/agents/pm.md でフロー確認"
    - consistency: "prompt-analyzer → term-translator → understanding-check の順序が明示"
    - completeness: "各 SubAgent の出力が次の SubAgent の入力として定義されている"

**status**: pending
**max_iterations**: 5

---

### p3: playbook context セクションへの永続化

**goal**: compact 後もユーザー意図を復元可能にする

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: playbook-format.md の context セクションに analysis_result, translated_requirements, user_approved_understanding フィールドが追加されている
  - executor: claudecode
  - validations:
    - technical: "grep -E 'analysis_result|translated_requirements|user_approved_understanding' plan/template/playbook-format.md で存在確認"
    - consistency: "他の context フィールド（5w1h 等）と同じ形式"
    - completeness: "3つ全てのフィールドが定義されている"

- [ ] **p3.2**: pm.md が playbook 作成時にこれらのフィールドを書き込むよう修正されている
  - executor: claudecode
  - validations:
    - technical: "grep -A5 'context セクション' .claude/skills/golden-path/agents/pm.md で書き込み指示確認"
    - consistency: "playbook-format.md のテンプレートと整合"
    - completeness: "3つ全てのフィールドの書き込みが指示されている"

- [ ] **p3.3**: context-management の must_keep にこれらのフィールドが追加されている
  - executor: claudecode
  - validations:
    - technical: "grep -A10 'must_keep' .claude/skills/context-management/SKILL.md で保護対象確認"
    - consistency: "既存の must_keep 項目と同じ形式"
    - completeness: "analysis_result, translated_requirements, user_approved_understanding が含まれている"

**status**: pending
**max_iterations**: 5

---

### p4: prompt-analyzer の分析項目拡充

**goal**: Issue 1 で指摘した全ての致命的不足を解消する

**depends_on**: [p1]

#### subtasks

- [ ] **p4.1**: prompt-analyzer に test_strategy 分析項目が追加されている
  - executor: claudecode
  - validations:
    - technical: "grep -A20 'test_strategy' .claude/skills/prompt-analyzer/agents/prompt-analyzer.md で存在確認"
    - consistency: "既存の分析項目（5w1h, risks, ambiguity）と同じ形式"
    - completeness: "test_types, coverage_target, edge_cases が含まれている"

- [ ] **p4.2**: prompt-analyzer に preconditions 分析項目が追加されている
  - executor: claudecode
  - validations:
    - technical: "grep -A15 'preconditions' .claude/skills/prompt-analyzer/agents/prompt-analyzer.md で存在確認"
    - consistency: "既存の分析項目と同じ形式"
    - completeness: "existing_code, dependencies, constraints が含まれている"

- [ ] **p4.3**: prompt-analyzer に success_criteria 分析項目が追加されている
  - executor: claudecode
  - validations:
    - technical: "grep -A15 'success_criteria' .claude/skills/prompt-analyzer/agents/prompt-analyzer.md で存在確認"
    - consistency: "既存の分析項目と同じ形式"
    - completeness: "functional, non_functional, breaking_changes が含まれている"

- [ ] **p4.4**: prompt-analyzer に reverse_dependencies 分析項目が追加されている
  - executor: claudecode
  - validations:
    - technical: "grep -A10 'reverse_dependencies' .claude/skills/prompt-analyzer/agents/prompt-analyzer.md で存在確認"
    - consistency: "既存の分析項目と同じ形式"
    - completeness: "affected_components が含まれている"

- [ ] **p4.5**: prompt-analyzer の出力フォーマットに全ての新規項目が追加されている
  - executor: claudecode
  - validations:
    - technical: "grep -E 'test_strategy|preconditions|success_criteria|reverse_dependencies' .claude/skills/prompt-analyzer/agents/prompt-analyzer.md | wc -l >= 4"
    - consistency: "analysis セクション内に全項目がある"
    - completeness: "出力フォーマットに全項目が定義されている"

**status**: pending
**max_iterations**: 5

---

### p5: validations 実行フロー定義

**goal**: subtask 完了判定を自動化し、報酬詐欺を防止する

**depends_on**: [p3]

#### subtasks

- [ ] **p5.1**: playbook-format.md の validations 形式が実行可能な形式に強化されている
  - executor: claudecode
  - validations:
    - technical: "grep -A30 'validations' plan/template/playbook-format.md で形式確認"
    - consistency: "command + expected の形式が定義されている"
    - completeness: "technical, consistency, completeness 各項目に実行可能な検証が示されている"

- [ ] **p5.2**: subtask 完了判定フローが critic.md または新規ファイルに定義されている
  - executor: claudecode
  - validations:
    - technical: "grep -E 'subtask.*完了|validation.*実行' .claude/skills/reward-guard/agents/critic.md で存在確認"
    - consistency: "validations の 3 項目を順に実行するフローがある"
    - completeness: "PASS/FAIL の記録方法が定義されている"

**status**: pending
**max_iterations**: 5

---

### p6: reviewer 判定基準の具体化

**goal**: PASS/FAIL の判定を客観的にし、証拠を残す

**depends_on**: [p5]

#### subtasks

- [ ] **p6.1**: reviewer.md の 4QV+ 各項目に具体的なチェックコマンド/基準が追加されている
  - executor: claudecode
  - validations:
    - technical: "grep -A10 'Q1_形式検証' .claude/skills/quality-assurance/agents/reviewer.md で具体的基準確認"
    - consistency: "Q1-Q4 と Plus 全てに実行可能な基準がある"
    - completeness: "各項目の PASS 条件が明示されている"

- [ ] **p6.2**: reviewer の出力に各 Q の PASS/FAIL ログが含まれるよう修正されている
  - executor: claudecode
  - validations:
    - technical: "grep -A20 '出力フォーマット' .claude/skills/quality-assurance/agents/reviewer.md でログ形式確認"
    - consistency: "既存の出力形式を拡張する形"
    - completeness: "Q1-Q4 + Plus 全ての判定結果が出力される"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: 全ての done_when が満たされているか最終検証

**depends_on**: [p1, p2, p3, p4, p5, p6]

#### subtasks

- [ ] **p_final.1**: term-translator に「テスト」「検証」変換ルールが存在する
  - executor: claudecode
  - validations:
    - technical: "grep -c 'テスト:' .claude/skills/term-translator/agents/term-translator.md >= 1"
    - consistency: "変換ルール辞書の形式に従っている"
    - completeness: "テストと検証の両方が定義されている"

- [ ] **p_final.2**: understanding-check が変換結果を参照している
  - executor: claudecode
  - validations:
    - technical: "grep 'translated_requirements' .claude/skills/understanding-check/SKILL.md で存在確認"
    - consistency: "pm.md のフローと連携している"
    - completeness: "ユーザーへの確認時に技術用語が使われる"

- [ ] **p_final.3**: playbook context に永続化フィールドが追加されている
  - executor: claudecode
  - validations:
    - technical: "grep -c 'analysis_result\|translated_requirements\|user_approved_understanding' plan/template/playbook-format.md >= 3"
    - consistency: "context-management の must_keep に含まれている"
    - completeness: "3つ全てが定義されている"

- [ ] **p_final.4**: prompt-analyzer に test_strategy が追加されている
  - executor: claudecode
  - validations:
    - technical: "grep 'test_strategy' .claude/skills/prompt-analyzer/agents/prompt-analyzer.md で存在確認"
    - consistency: "出力フォーマットに含まれている"
    - completeness: "test_types, coverage_target, edge_cases がある"

- [ ] **p_final.5**: validations 実行フローが定義されている
  - executor: claudecode
  - validations:
    - technical: "grep 'command.*expected' plan/template/playbook-format.md で形式確認"
    - consistency: "critic.md で実行フローが参照されている"
    - completeness: "PASS/FAIL 記録方法がある"

- [ ] **p_final.6**: reviewer の判定基準が具体化されている
  - executor: claudecode
  - validations:
    - technical: "grep -c 'PASS.*条件' .claude/skills/quality-assurance/agents/reviewer.md >= 5"
    - consistency: "4QV+ 全項目に基準がある"
    - completeness: "出力に各 Q の判定結果が含まれる"

- [ ] **p_final.7**: SubAgent 間データフローの end-to-end 検証
  - executor: claudecode
  - validations:
    - technical: |
        シミュレーション実行:
        1. prompt-analyzer が test_strategy, preconditions, success_criteria, reverse_dependencies を出力
        2. term-translator が「テスト」「検証」を技術用語に変換
        3. understanding-check が translated_requirements を参照してユーザー確認
        4. pm が playbook 作成時に context セクションに永続化
        5. reviewer が各 Q の PASS/FAIL をログに記録
    - consistency: "各 SubAgent の出力が次の SubAgent の入力として正しく参照されている"
    - completeness: "全ての修正が連携して動作し、データフロー断絶が解消されている"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

- [ ] **ft2**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft3**: tmp/ ディレクトリをクリーンアップする
  - command: `rm -rf tmp/* 2>/dev/null || true`
  - status: pending
