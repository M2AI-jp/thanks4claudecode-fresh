# playbook-fizzbuzz-dogfooding.md

> **FizzBuzz ドッグフーディング: フレームワーク全工程の検証**

---

## meta

```yaml
project: fizzbuzz-dogfooding
branch: feat/fizzbuzz-dogfooding
created: 2026-01-04
issue: null
reviewed: true
roles:
  worker: codex
  reviewer: coderabbit
```

---

## goal

```yaml
summary: |
  【表面上のタスク】
  tmp/ に Python で FizzBuzz を作成し、テスト・レビュー・マージする。

  【本当の目的（メタ目的）】
  プログラミング自体ではなく、playbook 開始から main へのマージまでの
  一連の作業を通じて、フレームワークの必要機能と欠陥を発見する。

  このタスクは「ドッグフーディング」であり、以下を検証する:
  - Hook チェーンの動作
  - executor (codex/coderabbit) の連携
  - critic 検証の有効性
  - マージまでのワークフロー

done_when:
  - tmp/fizzbuzz.py が存在し、FizzBuzz ロジックが実装されている
  - Codex で実装コミットが作成されている
  - CodeRabbit でレビューが完了している
  - PR が作成され、main にマージされている
  - 発見事項が docs/dogfooding-findings.md に記録されている
```

---

## context

```yaml
5w1h:
  who: "Claude Code（実行者）、ユーザー（結果確認者）"
  what: "tmp/ に Python FizzBuzz を作成し、フレームワーク全工程を実行"
  when: "今回のセッションで即時実行"
  where: "tmp/ ディレクトリ"
  why: "playbook → codex → coderabbit → マージ の全工程を通じて必要機能と欠陥を発見"
  how: "playbook 作成 → Codex 実装 → CodeRabbit レビュー → マージ"

analysis_result:
  source: prompt-analyzer
  timestamp: 2026-01-04
  data:
    5w1h:
      who: "Claude Code（実行者）、ユーザー（結果確認者）"
      what: "tmp/ に Python FizzBuzz を作成し、フレームワーク全工程を実行"
      when: "今回のセッションで即時実行"
      where: "tmp/ ディレクトリ"
      why: "playbook → codex → coderabbit → マージ の全工程を通じて必要機能と欠陥を発見"
      how: "playbook 作成 → Codex 実装 → CodeRabbit レビュー → マージ"
      missing: []
    risks:
      technical:
        - risk: "Codex/CodeRabbit 連携の確認"
          severity: medium
          mitigation: "実行時に確認"
      scope: []
      dependency: []
    ambiguity: []
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

translated_requirements:
  source: term-translator
  timestamp: 2026-01-04
  data:
    original_terms: []
    technical_requirements:
      - requirement: "Python FizzBuzz 実装"
        derived_from: "FizzBuzz を作成"
        implementation_hint: "1-100 の数値に対して FizzBuzz を出力"
    codebase_context:
      relevant_files:
        - "tmp/"
      existing_patterns: []
      conventions: []

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-04
  summary: "tmp/ に Python FizzBuzz を作成し、フレームワーク全工程を検証する"
  approved_items:
    - question_id: "meta_purpose"
      question: "メタ目的を playbook に含めるか？"
      answer: "はい、含める"
  technical_requirements_confirmed: []
```

---

## phases

### p1: FizzBuzz 実装

**goal**: Codex で tmp/fizzbuzz.py を実装する

#### subtasks

- [ ] **p1.1**: tmp/fizzbuzz.py が存在し、FizzBuzz ロジックが実装されている
  - executor: codex
  - validations:
    - technical: "python tmp/fizzbuzz.py を実行し、1-15 の出力が正しいか確認"
    - consistency: "Python の一般的なコーディング規約に従っているか確認"
    - completeness: "1-100 の範囲で FizzBuzz が正しく動作するか確認"

**status**: pending
**max_iterations**: 5

---

### p2: コードレビュー

**goal**: CodeRabbit で実装コードをレビューする

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: CodeRabbit によるコードレビューが完了している
  - executor: coderabbit
  - validations:
    - technical: "coderabbit コマンドが正常終了し、レビュー結果が出力されている"
    - consistency: "レビュー指摘事項が妥当であるか確認"
    - completeness: "重大な問題がないことを確認"

**status**: pending
**max_iterations**: 3

---

### p3: テスト実行

**goal**: FizzBuzz の動作を確認する

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: python tmp/fizzbuzz.py が期待通りの出力を返す
  - executor: claudecode
  - validations:
    - technical: "python tmp/fizzbuzz.py を実行し出力を確認"
    - consistency: "FizzBuzz のルール（3の倍数=Fizz、5の倍数=Buzz、15の倍数=FizzBuzz）に従っている"
    - completeness: "1-100 の全ての数値が正しく処理されている"

**status**: pending
**max_iterations**: 3

---

### p4: PR 作成・マージ

**goal**: 変更を main にマージする

**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: 全ての変更がコミットされている
  - executor: claudecode
  - validations:
    - technical: "git status で未コミットの変更がないことを確認"
    - consistency: "コミットメッセージが規約に従っている"
    - completeness: "playbook 関連ファイルも含めて全てコミットされている"

- [ ] **p4.2**: PR が作成されている
  - executor: claudecode
  - validations:
    - technical: "gh pr view で PR の存在を確認"
    - consistency: "PR のタイトルと説明が適切である"
    - completeness: "変更内容が PR に正しく含まれている"

- [ ] **p4.3**: main にマージされている
  - executor: claudecode
  - validations:
    - technical: "gh pr merge で PR がマージされている"
    - consistency: "マージコンフリクトがない"
    - completeness: "マージ後に main ブランチに変更が反映されている"

**status**: pending
**max_iterations**: 3

---

### p5: 発見事項の記録

**goal**: ドッグフーディングで発見した問題点・改善点を記録する

**depends_on**: [p4]

#### subtasks

- [ ] **p5.1**: docs/dogfooding-findings.md が存在し、発見事項が記録されている
  - executor: claudecode
  - validations:
    - technical: "test -f docs/dogfooding-findings.md でファイル存在を確認"
    - consistency: "発見事項が実際の作業内容と一致している"
    - completeness: "Hook/executor/critic/マージの各工程について記録がある"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p5]

#### subtasks

- [ ] **p_final.1**: tmp/fizzbuzz.py が存在し、FizzBuzz ロジックが実装されている
  - executor: claudecode
  - validations:
    - technical: "test -f tmp/fizzbuzz.py && python tmp/fizzbuzz.py で動作確認"
    - consistency: "FizzBuzz のルールに従った出力であることを確認"
    - completeness: "1-100 の範囲で正しく動作することを確認"

- [ ] **p_final.2**: Codex で実装コミットが作成されている
  - executor: claudecode
  - validations:
    - technical: "git log で Codex による実装コミットを確認"
    - consistency: "コミットメッセージが規約に従っている"
    - completeness: "fizzbuzz.py の実装が含まれている"

- [ ] **p_final.3**: CodeRabbit でレビューが完了している
  - executor: claudecode
  - validations:
    - technical: "CodeRabbit レビュー実行の証跡を確認"
    - consistency: "レビュー結果が記録されている"
    - completeness: "重大な問題が解決されている"

- [ ] **p_final.4**: PR が作成され、main にマージされている
  - executor: claudecode
  - validations:
    - technical: "git branch -a で main に変更が反映されていることを確認"
    - consistency: "マージが正常に完了している"
    - completeness: "全ての変更が main に含まれている"

- [ ] **p_final.5**: 発見事項が docs/dogfooding-findings.md に記録されている
  - executor: claudecode
  - validations:
    - technical: "test -f docs/dogfooding-findings.md でファイル存在を確認"
    - consistency: "記録内容が実際の作業と一致している"
    - completeness: "必要な情報が全て記録されている"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する（fizzbuzz.py は保持）
  - command: `find tmp/ -type f ! -name 'README.md' ! -name 'fizzbuzz.py' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending
