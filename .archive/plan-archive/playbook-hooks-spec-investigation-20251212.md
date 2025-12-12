# playbook-hooks-spec-investigation.md

> **Claude Code Hooks 仕様の完全理解**

---

## meta

```yaml
project: hooks-100-percent-fire
branch: feat/hooks-100-percent-fire
created: 2025-12-12
issue: null
derives_from: M1
reviewed: false
```

---

## goal

```yaml
summary: Claude Code の公式ドキュメント・内部仕様を徹底調査し、Hooks 発火条件を完全に把握する
done_when:
  - 全 Hook イベントタイプの発火条件がドキュメント化されている
  - 発火しない可能性のあるパターンがリスト化されている
  - Claude Code の Hooks 仕様に関する知識が網羅的に整理されている
```

---

## phases

### p1: Claude Code 公式ドキュメント調査

```yaml
- id: p1
  name: Claude Code 公式ドキュメント調査
  goal: claude-code-guide SubAgent を使って Hooks 関連の公式ドキュメントを徹底収集
  tasks:
    - id: t1-1
      name: Hooks イベントタイプ調査
      subtasks:
        - step: "claude-code-guide で全 Hook イベントタイプを調査"
          executor: claudecode
          criteria: "全イベントタイプ（SessionStart, PreToolUse, PostToolUse, Stop, UserPromptSubmit, PreCompact, SubagentStop）の仕様がリスト化されている"
          status: "[x]"
        - step: "各イベントタイプの発火条件を詳細に記録"
          executor: claudecode
          criteria: "各イベントの発火タイミング、入力パラメータ、出力形式が記録されている"
          status: "[x]"
    - id: t1-2
      name: Matcher パターン調査
      subtasks:
        - step: "Matcher の種類と記法を調査"
          executor: claudecode
          criteria: "Matcher パターン（*、ツール名、glob等）の仕様が記録されている"
          status: "[x]"
    - id: t1-3
      name: additionalContext/systemMessage 調査
      subtasks:
        - step: "Hook 出力形式を調査"
          executor: claudecode
          criteria: "additionalContext、systemMessage、decision の使い方が記録されている"
          status: "[x]"
  status: done
  evidence: docs/hooks-specification.md に全情報を記録
```

### p2: 発火条件の網羅的整理

```yaml
- id: p2
  name: 発火条件の網羅的整理
  goal: 全 Hook イベントの発火条件を整理し、発火しないパターンを特定
  depends_on: [p1]
  tasks:
    - id: t2-1
      name: イベント発火マトリクス作成
      subtasks:
        - step: "全イベント × 全トリガー条件のマトリクスを作成"
          executor: claudecode
          criteria: "イベント発火マトリクスが docs/hooks-fire-matrix.md に存在する"
          status: "[x]"
    - id: t2-2
      name: 発火しないパターンの特定
      subtasks:
        - step: "発火しない可能性のあるパターンをリスト化"
          executor: claudecode
          criteria: "発火しないパターンが10種類以上リスト化されている"
          status: "[x]"
        - step: "各パターンの原因と対策を記録"
          executor: claudecode
          criteria: "各パターンに対する原因分析と対策案が記録されている"
          status: "[x]"
  status: done
  evidence: docs/hooks-fire-matrix.md に全情報を記録（15種類以上のパターンと対策）
```

### p3: エッジケース特定

```yaml
- id: p3
  name: エッジケース特定
  goal: 発火しない可能性のあるエッジケースを網羅的に特定
  depends_on: [p2]
  tasks:
    - id: t3-1
      name: プロンプトエッジケース
      subtasks:
        - step: "プロンプトのエッジケースを50種類以上リスト化"
          executor: claudecode
          criteria: "空文字、絵文字のみ、超長文、マルチバイト、特殊文字、制御文字等が含まれている"
          status: "[x]"
    - id: t3-2
      name: システムエッジケース
      subtasks:
        - step: "システム状態のエッジケースをリスト化"
          executor: claudecode
          criteria: "ファイル不在、権限不足、タイムアウト、並行実行等が含まれている"
          status: "[x]"
    - id: t3-3
      name: Claude Code 特有のケース
      subtasks:
        - step: "Claude Code 特有のエッジケースを調査"
          executor: claudecode
          criteria: "compact、resume、/commands、MCP 等のケースが含まれている"
          status: "[x]"
  status: done
  evidence: docs/hooks-edge-cases.md に 128 パターンを記録
```

### p4: 調査結果のドキュメント化

```yaml
- id: p4
  name: 調査結果のドキュメント化
  goal: 調査結果を docs/hooks-specification.md としてドキュメント化
  depends_on: [p3]
  tasks:
    - id: t4-1
      name: 仕様書作成
      subtasks:
        - step: "Hooks 仕様書を作成"
          executor: claudecode
          criteria: "docs/hooks-specification.md が存在し、全調査結果が含まれている"
          status: "[x]"
    - id: t4-2
      name: テストケース設計書作成
      subtasks:
        - step: "1000パターンのテストケース設計書を作成"
          executor: claudecode
          criteria: "docs/hooks-test-design.md が存在し、テストカテゴリと件数が記載されている"
          status: "[x]"
  status: done
  evidence: |
    - docs/hooks-specification.md: Hooks 完全仕様書
    - docs/hooks-test-design.md: 1000パターンテストケース設計書
```

### p5: 動作テスト

```yaml
- id: p5
  name: 動作テスト
  goal: p1-p4 の成果物が正しいことを検証
  depends_on: [p4]
  tasks:
    - id: t5-1
      name: ドキュメント検証
      subtasks:
        - step: "作成したドキュメントの整合性を検証"
          executor: claudecode
          criteria: "docs/hooks-specification.md と docs/hooks-test-design.md に矛盾がない"
          status: "[x]"
    - id: t5-2
      name: サンプルテスト実行
      subtasks:
        - step: "10パターンのサンプルテストを実行"
          executor: claudecode
          criteria: "サンプルテストが実行され、結果が記録されている"
          status: "[x]"
  status: done
  evidence: |
    - test-sample-prompts.sh: 10/10 PASS
    - ドキュメント間の整合性を確認済み
```

---

## notes

- この playbook は M1（Hooks 仕様の完全理解）に対応
- 次の playbook（テストフレームワーク構築）の基盤となる
- 徹底的な調査が必要（claude-code-guide SubAgent をフル活用）
