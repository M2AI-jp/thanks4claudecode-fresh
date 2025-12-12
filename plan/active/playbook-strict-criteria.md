# playbook-strict-criteria.md

> **厳密な done_criteria 定義システム**
>
> subtasks 構造を導入し、criterion + executor + test_command を1セットで定義する。
> 「テストをクリアするためのテスト」から「検証可能な仕様」への転換。

---

## meta

```yaml
project: thanks4claudecode
branch: feat/strict-criteria
created: 2025-12-13
issue: null
derives_from: M006  # project.milestone M006
reviewed: false
```

---

## goal

```yaml
summary: |
  done_criteria の定義精度を向上させるシステムを構築する。
  各 criterion に executor と test_command を1:1で紐付け、
  曖昧な表現を排除し、TDD の本質を実現する。

done_when:
  - subtasks 構造が playbook フォーマットに導入されている
  - 各 criterion に executor + test_command が紐付いている
  - 曖昧表現が自動検出・拒否される仕組みがある
  - pm/plan-reviewer が新構造で playbook を生成できる
```

---

## phases

### p0: subtasks 構造の設計と本 playbook への適用

```yaml
id: p0
name: subtasks 構造の設計と自己適用
goal: criterion + executor + test_command の1セット構造を設計し、本 playbook 全体（p0-p6）に適用する

subtasks:
  - id: p0.1
    criterion: "全 phase (p0-p6) が subtasks: キーを持つ（7個の phase に 7個の subtasks）"
    executor: claudecode
    test_command: |
      phases=$(grep -c '^### p[0-6]:' plan/active/playbook-strict-criteria.md)
      subtasks=$(grep -c '^subtasks:' plan/active/playbook-strict-criteria.md)
      [ "$phases" -eq 7 ] && [ "$subtasks" -eq 7 ] && echo "PASS" || echo "FAIL: phases=$phases, subtasks=$subtasks"

  - id: p0.2
    criterion: "全 subtask が id: p{N}.{M} 形式の識別子を持つ（27個以上）"
    executor: claudecode
    test_command: |
      count=$(grep -cE '^\s+- id: p[0-6]\.[0-9]+' plan/active/playbook-strict-criteria.md)
      [ "$count" -ge 27 ] && echo "PASS ($count subtasks)" || echo "FAIL ($count subtasks, need >=27)"

  - id: p0.3
    criterion: "executor 選択ガイドラインが playbook 末尾に存在する（claudecode/codex/coderabbit/user の4種）"
    executor: claudecode
    test_command: |
      grep -q 'executor 選択ガイドライン' plan/active/playbook-strict-criteria.md && \
      grep -q 'claudecode:' plan/active/playbook-strict-criteria.md && \
      grep -q 'codex:' plan/active/playbook-strict-criteria.md && \
      grep -q 'coderabbit:' plan/active/playbook-strict-criteria.md && \
      grep -q 'user:' plan/active/playbook-strict-criteria.md && \
      echo "PASS" || echo "FAIL"

status: done
max_iterations: 3
```

### p1: playbook-format.md テンプレート更新

```yaml
id: p1
name: playbook テンプレートの subtasks 構造対応
goal: plan/template/playbook-format.md を subtasks 構造に対応させる
depends_on: [p0]

subtasks:
  - id: p1.1
    criterion: "playbook-format.md に subtasks セクションが追加されている"
    executor: claudecode
    test_command: "grep -q 'subtasks:' plan/template/playbook-format.md && echo PASS"

  - id: p1.2
    criterion: "subtask の必須フィールド（criterion, executor, test_command）が定義されている"
    executor: claudecode
    test_command: |
      grep -A5 'subtask:' plan/template/playbook-format.md | grep -q 'criterion:' && \
      grep -A5 'subtask:' plan/template/playbook-format.md | grep -q 'executor:' && \
      grep -A5 'subtask:' plan/template/playbook-format.md | grep -q 'test_command:' && echo PASS

  - id: p1.3
    criterion: "executor の選択肢（claudecode, codex, coderabbit, user）が列挙されている"
    executor: claudecode
    test_command: |
      grep -q 'claudecode' plan/template/playbook-format.md && \
      grep -q 'codex' plan/template/playbook-format.md && \
      grep -q 'coderabbit' plan/template/playbook-format.md && \
      grep -q 'user' plan/template/playbook-format.md && echo PASS

  - id: p1.4
    criterion: "test_command のパターン例（ファイル存在、grep、コマンド実行）が記載されている"
    executor: claudecode
    test_command: "grep -c 'test -f\\|grep -q\\|exit' plan/template/playbook-format.md | awk '{if($1>=3) print \"PASS\"; else print \"FAIL\"}'"

status: pending
max_iterations: 5
```

### p2: 禁止パターンと検証ルールの定義

```yaml
id: p2
name: 曖昧表現の禁止パターンと検証ルール定義
goal: 曖昧な criterion を検出・拒否するルールセットを作成
depends_on: [p0]

subtasks:
  - id: p2.1
    criterion: "docs/criterion-validation-rules.md が存在する"
    executor: claudecode
    test_command: "test -f docs/criterion-validation-rules.md && echo PASS"

  - id: p2.2
    criterion: "禁止パターンが15個以上列挙されている"
    executor: claudecode
    test_command: "grep -cE '^- 「|^- \\*\\*' docs/criterion-validation-rules.md | awk '{if($1>=15) print \"PASS\"; else print \"FAIL\"}'"

  - id: p2.3
    criterion: "各禁止パターンに「なぜダメか」と「修正例」が記載されている"
    executor: claudecode
    test_command: |
      grep -c '→' docs/criterion-validation-rules.md | awk '{if($1>=15) print \"PASS\"; else print \"FAIL\"}'

  - id: p2.4
    criterion: "Given/When/Then テンプレートが含まれている"
    executor: claudecode
    test_command: "grep -q 'Given:' docs/criterion-validation-rules.md && grep -q 'When:' docs/criterion-validation-rules.md && grep -q 'Then:' docs/criterion-validation-rules.md && echo PASS"

  - id: p2.5
    criterion: "検証ルールが実際の曖昧表現を検出できる（テスト実行）"
    executor: user
    test_command: "手動確認: サンプル criterion を入力し、禁止パターンが検出されるか確認"

status: pending
max_iterations: 5
```

### p3: pm SubAgent の playbook 生成ロジック更新

```yaml
id: p3
name: pm SubAgent の subtasks 構造対応
goal: pm が subtasks 構造で playbook を生成するようにロジックを更新
depends_on: [p1, p2]

subtasks:
  - id: p3.1
    criterion: ".claude/agents/pm.md に subtasks 生成ガイドラインが追加されている"
    executor: claudecode
    test_command: "grep -q 'subtasks' .claude/agents/pm.md && echo PASS"

  - id: p3.2
    criterion: "pm が criterion ごとに executor を選択するロジックが記載されている"
    executor: claudecode
    test_command: |
      grep -A10 'executor' .claude/agents/pm.md | grep -qE 'claudecode|codex|coderabbit|user' && echo PASS

  - id: p3.3
    criterion: "pm が criterion ごとに test_command を生成するガイドラインがある"
    executor: claudecode
    test_command: "grep -q 'test_command' .claude/agents/pm.md && echo PASS"

  - id: p3.4
    criterion: "pm が禁止パターンを参照して曖昧 criterion を拒否する"
    executor: claudecode
    test_command: "grep -q 'criterion-validation-rules' .claude/agents/pm.md && echo PASS"

  - id: p3.5
    criterion: "pm で新規 playbook を生成し、subtasks 構造が正しく出力される"
    executor: user
    test_command: "手動確認: pm を呼び出してテスト playbook を生成し、subtasks 構造を確認"

status: pending
max_iterations: 5
```

### p4: critic SubAgent の subtasks 検証対応

```yaml
id: p4
name: critic SubAgent の subtasks 検証対応
goal: critic が subtasks 単位で PASS/FAIL を判定するようにロジックを更新
depends_on: [p3]

subtasks:
  - id: p4.1
    criterion: ".claude/agents/critic.md に subtasks 検証ロジックが追加されている"
    executor: claudecode
    test_command: "grep -q 'subtask' .claude/agents/critic.md && echo PASS"

  - id: p4.2
    criterion: "critic が test_command を実行して PASS/FAIL を判定する"
    executor: claudecode
    test_command: "grep -q 'test_command' .claude/agents/critic.md && echo PASS"

  - id: p4.3
    criterion: "critic の出力形式に subtask 単位の結果が含まれる"
    executor: claudecode
    test_command: |
      grep -qE 'p[0-9]+\.[0-9]+|subtask.*PASS|subtask.*FAIL' .claude/agents/critic.md && echo PASS

  - id: p4.4
    criterion: "critic が1つでも FAIL の subtask があれば phase を FAIL にする"
    executor: claudecode
    test_command: "grep -qE '1つでも.*FAIL|any.*FAIL' .claude/agents/critic.md && echo PASS"

  - id: p4.5
    criterion: "critic による subtasks 検証が実際に動作する（テスト実行）"
    executor: user
    test_command: "手動確認: critic を呼び出して本 playbook の p0 を検証し、subtask 単位の結果を確認"

status: pending
max_iterations: 5
```

### p5: CLAUDE.md と統合テスト

```yaml
id: p5
name: CLAUDE.md 更新と統合テスト
goal: CLAUDE.md に subtasks 構造を反映し、全体フローが機能することを確認
depends_on: [p3, p4]

subtasks:
  - id: p5.1
    criterion: "CLAUDE.md の LOOP セクションに subtasks 検証が追加されている"
    executor: claudecode
    test_command: "grep -q 'subtask' CLAUDE.md && echo PASS"

  - id: p5.2
    criterion: "CLAUDE.md に executor 選択ガイドラインが記載されている"
    executor: claudecode
    test_command: |
      grep -qE 'claudecode.*設計|codex.*実装|coderabbit.*レビュー|user.*確認' CLAUDE.md && echo PASS

  - id: p5.3
    criterion: "pm → playbook → critic の全フローが subtasks 構造で動作する"
    executor: user
    test_command: |
      手動確認:
      1. pm で新規 playbook を作成（subtasks 構造）
      2. phase を実行
      3. critic が subtask 単位で検証
      4. 全 subtask PASS で phase 完了

  - id: p5.4
    criterion: "既存 playbook との互換性が確認されている（または移行ガイドがある）"
    executor: claudecode
    test_command: "test -f docs/subtasks-migration-guide.md || grep -q '互換性' CLAUDE.md && echo PASS"

status: pending
max_iterations: 5
```

### p6: ドキュメント整備とクリーンアップ

```yaml
id: p6
name: ドキュメント整備とクリーンアップ
goal: 全ドキュメントを統合し、M006 完了状態にする
depends_on: [p5]

subtasks:
  - id: p6.1
    criterion: "docs/criterion-validation-rules.md が完成版として存在する"
    executor: claudecode
    test_command: "test -f docs/criterion-validation-rules.md && wc -l docs/criterion-validation-rules.md | awk '{if($1>=50) print \"PASS\"; else print \"FAIL\"}'"

  - id: p6.2
    criterion: "plan/template/playbook-format.md が subtasks 構造を含む最新版である"
    executor: claudecode
    test_command: "grep -q 'subtasks:' plan/template/playbook-format.md && echo PASS"

  - id: p6.3
    criterion: ".claude/agents/pm.md と critic.md が更新されている"
    executor: claudecode
    test_command: |
      grep -q 'subtask' .claude/agents/pm.md && \
      grep -q 'subtask' .claude/agents/critic.md && echo PASS

  - id: p6.4
    criterion: "不要な中間ファイルが削除されている"
    executor: claudecode
    test_command: "! ls plan/active/draft-*.md 2>/dev/null && ! ls plan/active/temp-*.md 2>/dev/null && echo PASS"

  - id: p6.5
    criterion: "project.md の M006 が achieved に更新可能な状態である"
    executor: claudecode
    test_command: |
      grep -A5 'M006' plan/project.md | grep -q 'not_started\|in_progress' && echo "READY_TO_ACHIEVE"

status: pending
max_iterations: 3
```

---

## executor 選択ガイドライン

```yaml
claudecode:
  用途: ファイル作成、設計ドキュメント、設定変更、軽量なスクリプト
  test_command例:
    - "test -f {path}"
    - "grep -q '{pattern}' {file}"
    - "wc -l {file} | awk '{if($1>=N) print \"PASS\"}'"

codex:
  用途: 本格的なコード実装、複雑なロジック、大規模リファクタリング
  test_command例:
    - "npm test"
    - "pytest {path}"
    - "go test ./..."

coderabbit:
  用途: コードレビュー、セキュリティチェック、品質チェック
  test_command例:
    - "coderabbit review --check"
    - "cr lint {path}"

user:
  用途: 目視確認、外部ソースからのコピペ、Claude がアクセスできない操作
  test_command例:
    - "手動確認: {具体的な確認手順}"
    - "ユーザー入力待ち: {必要な情報}"
```

---

## リスク

| リスク | 対応 |
|--------|------|
| subtasks 構造への移行で既存 playbook が壊れる | 互換性レイヤーまたは移行ガイドを用意 |
| test_command が複雑すぎて失敗する | シンプルなパターンに絞る、失敗時のデバッグ手順を用意 |
| executor 選択が曖昧 | ガイドラインを明確化、迷ったら claudecode |

---

## 参照

- plan/project.md（M006 定義）
- plan/template/playbook-format.md（更新対象）
- docs/criterion-validation-rules.md（新規作成）
- .claude/agents/pm.md（更新対象）
- .claude/agents/critic.md（更新対象）
- CLAUDE.md（更新対象）
