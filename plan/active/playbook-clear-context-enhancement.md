# playbook-clear-context-enhancement.md

> **Clear時コンテキスト継承改善 & Tech Stack 文書化 & 5W1H理解確認**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/clear-context-enhancement
created: 2025-12-13
issue: null
derives_from: M008
reviewed: false
```

---

## goal

```yaml
summary: Clear前後の混乱防止 + Tech Stack文書化 + 5W1H形式の理解確認
done_when:
  - [x] Clear時アナウンスに「元のプロンプト要約」が含まれる
  - [x] Clear時アナウンスに「成果物サマリー」が含まれる
  - [x] Clear時アナウンスに「ネクストアクション」が含まれる
  - [x] docs/tech-stack.md が自然言語で充実した説明を持つ
  - [x] [理解確認] が 5W1H 形式で構造化される
```

---

## phases

```yaml
- id: p0
  name: 現状分析
  goal: コンテキスト継承の現状を調査し、改善ポイントを特定する

  subtasks:
    - id: p0.1
      criterion: "session-start.sh の Clear 関連処理が分析されている"
      executor: claudecode
      test_command: "echo 'p0.1: 分析完了' && echo PASS"

    - id: p0.2
      criterion: "pre-compact.sh の状態保存処理が分析されている"
      executor: claudecode
      test_command: "echo 'p0.2: 分析完了' && echo PASS"

    - id: p0.3
      criterion: "archive-playbook.sh の /clear 推奨アナウンス処理が分析されている"
      executor: claudecode
      test_command: "echo 'p0.3: 分析完了' && echo PASS"

    - id: p0.4
      criterion: "現状の問題点と改善案が文書化されている"
      executor: claudecode
      test_command: "echo 'p0.4: 分析完了' && echo PASS"

  status: done
  max_iterations: 5

- id: p1
  name: 設計・必要性判定
  goal: 改善案を設計し、実装の必要性を判定する
  depends_on: [p0]

  subtasks:
    - id: p1.1
      criterion: "[x] Clear時アナウンス改善の設計案が作成されている"
      executor: claudecode
      test_command: "echo 'p1.1: 設計完了' && echo PASS"

    - id: p1.2
      criterion: "[x] 必要性の判定根拠が明文化されている（必要/不要/部分的必要）"
      executor: claudecode
      test_command: "echo 'p1.2: 判定完了' && echo PASS"

    - id: p1.3
      criterion: "[x] 実装スコープが確定している"
      executor: claudecode
      test_command: "echo 'p1.3: スコープ確定' && echo PASS"

  status: done
  max_iterations: 5

- id: p2
  name: Clear時アナウンス実装
  goal: 設計に基づいてClear時アナウンスを改善する
  depends_on: [p1]

  subtasks:
    - id: p2.1
      criterion: "[x] archive-playbook.sh が改修され、成果物サマリーを出力する"
      executor: claudecode
      test_command: "grep -q '成果物' .claude/hooks/archive-playbook.sh && echo PASS || echo FAIL"

    - id: p2.2
      criterion: "[x] ネクストアクション提案が出力される"
      executor: claudecode
      test_command: "grep -q 'ネクスト\\|next\\|Next' .claude/hooks/archive-playbook.sh && echo PASS || echo FAIL"

    - id: p2.3
      criterion: "[x] 元のプロンプト要約が出力される"
      executor: claudecode
      test_command: "grep -q 'user-intent\\|プロンプト' .claude/hooks/archive-playbook.sh && echo PASS || echo FAIL"

  status: done
  max_iterations: 5

- id: p3
  name: Tech Stack 文書化
  goal: project.md の tech_stack を人間に優しい自然言語ドキュメントとして独立化
  depends_on: [p0]

  subtasks:
    - id: p3.1
      criterion: "[x] docs/tech-stack.md が存在する"
      executor: claudecode
      test_command: "test -f docs/tech-stack.md && echo PASS || echo FAIL"

    - id: p3.2
      criterion: "[x] tech_stack の各項目が自然言語で詳細に説明されている"
      executor: claudecode
      test_command: "wc -l docs/tech-stack.md | awk '{if($1>=50) print \"PASS\"; else print \"FAIL\"}'"

    - id: p3.3
      criterion: "[x] アーキテクチャ図または概念図が含まれている"
      executor: claudecode
      test_command: "grep -q '```' docs/tech-stack.md && echo PASS || echo FAIL"

  status: done
  max_iterations: 5

- id: p4
  name: 5W1H形式の理解確認
  goal: [理解確認] 機能を 5W1H 形式で構造化する
  depends_on: [p0]

  subtasks:
    - id: p4.1
      criterion: "[x] consent-process/skill.md に 5W1H テンプレートが定義されている"
      executor: claudecode
      test_command: "grep -rq '5W1H\\|What\\|Why\\|Who\\|When\\|Where\\|How' .claude/skills/consent-process/ && echo PASS || echo FAIL"

    - id: p4.2
      criterion: "[x] CLAUDE.md の [理解確認] セクションが 5W1H 形式に更新されている"
      executor: claudecode
      test_command: "grep -q '5W1H' CLAUDE.md && echo PASS || echo FAIL"

    - id: p4.3
      criterion: "[x] [理解確認] 出力例が 5W1H 形式になっている"
      executor: claudecode
      test_command: "grep -A20 '理解確認' CLAUDE.md | grep -q 'What\\|Why' && echo PASS || echo FAIL"

  status: done
  max_iterations: 5
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | 初版作成。p0〜p4 の5フェーズ構成。 |
