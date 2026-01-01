# playbook-facade-audit-v2.md

> **executor 強制メカニズムを修正し、Codex/CodeRabbit が実際に作業する監査を再実行**

---

## meta

```yaml
project: facade-audit-v2
branch: feat/facade-audit-v2
created: 2026-01-01
issue: null
reviewed: true  # reviewer SubAgent 承認済み (v2)
roles:
  orchestrator: claudecode
  worker: codex
  reviewer: coderabbit
toolstack: C  # Codex + CodeRabbit 併用
priority: critical
previous_playbook: plan/playbook-facade-audit.md
```

---

## context

### 前回の失敗分析

```yaml
violation:
  description: |
    playbook-facade-audit.md で executor: codex が指定されていたが、
    Claude Code が直接作業を実行していた。これは「見かけだけの実装」を
    検出するはずの監査が、自身が見かけだけの executor 運用になっていた。

  root_causes:
    - id: RC1
      description: "Codex MCP タイムアウト（-32001 AbortError）"
      impact: "Codex が応答しないため、Claude Code がフォールバック実行"
      evidence: "p1, p3, p4 で MCP error -32001 発生"

    - id: RC2
      description: "executor-guard が Edit/Write のみ監視"
      impact: "Task ツールや Bash は通過してしまう"
      evidence: "Claude Code が Bash で直接テストを実行"

    - id: RC3
      description: "フォールバックポリシー未定義"
      impact: "Codex 失敗時に Claude Code が無言で代行"
      evidence: "タイムアウト後に警告なく作業継続"

corrective_action: |
  1. Codex MCP 安定化を最優先で実施
  2. executor 強制ガードを拡張（Task/Bash も監視）
  3. フォールバック時の明示的なユーザー確認を導入
  4. その後、元の監査タスクを再実行
```

### 5W1H 分析

```yaml
What:
  - executor 強制メカニズムの強化
  - Codex MCP 安定化
  - 前回の監査タスク再実行

Why:
  - 前回 playbook で executor: codex が無視された
  - これは「見かけだけの実装」検出の失敗そのもの
  - 構造的に executor を強制しないと同じ問題が再発する

Who:
  - orchestrator: claudecode（設計・監督・ガード拡張のみ）
  - worker: codex（コード実装は全て Codex）
  - reviewer: coderabbit

Where:
  - .claude/skills/playbook-gate/guards/executor-guard.sh
  - .mcp.json（Codex 設定）
  - .claude/settings.json（フック設定）

When:
  - 即時実行（優先度: critical）

How:
  - p_init: Playbook テンプレート自体の見直し
  - p0-p2: 根本原因修正（claudecode が構造変更）
  - p3-p7: 修正後の Codex/CodeRabbit で監査再実行
```

---

## goal

```yaml
summary: executor 強制を構造的に保証し、Codex/CodeRabbit による監査を完遂する
done_when:
  - playbook テンプレートが「executor 強制」「証拠強制」を構造的に保証している
  - executor-guard が Task/Bash を含む全ツールを監視している
  - Codex MCP が 5 回連続で正常応答する（タイムアウトなし）
  - フォールバック時にユーザー確認プロンプトが発生する
  - p3-p7 の実装が全て Codex によって行われた証拠がある
  - CodeRabbit 最終レビューで critical: 0, major: 0 である
```

---

## phases

### p_init: Playbook テンプレート見直し

**goal**: playbook テンプレート自体の問題を特定・修正し、今後の playbook 品質を向上させる

#### subtasks

- [ ] **p_init.1**: 現行 playbook テンプレートの問題点を洗い出す
  - executor: claudecode
  - note: |
      検討項目:
      1. executor 指定が実際に強制されるか（構造的保証）
      2. validations の形式が「証拠」を強制するか
      3. subtask の粒度指針が明確か
      4. done_when と subtask.validations の整合性
      5. 前回失敗した root causes がテンプレートレベルで防げるか
  - validations:
    - technical: "問題点リストが 5 項目以上存在する"
    - consistency: "各問題点に改善案が添付されている"
    - completeness: "executor 強制の構造的保証が含まれている"

- [ ] **p_init.2**: テンプレート改善案を定義・適用する
  - executor: claudecode
  - note: |
      改善候補:
      1. executor フィールドに「構造的強制」フラグ追加
      2. validations に「証拠形式」フィールド追加（command/output/diff）
      3. subtask 完了時の自動検証フック定義
      4. Codex 実行証拠の自動記録機構

      注: テンプレート改善は次回以降の playbook に適用。
      この playbook 自体の再構成は行わない（循環依存回避）。
  - validations:
    - technical: "plan/template/playbook-format.md が更新されている"
    - consistency: "改善案が前回の root causes を解決する"
    - completeness: "executor 強制、証拠強制、自動検証の 3 項目が含まれている"

**status**: pending
**max_iterations**: 3
**depends_on**: []

---

### p0: 根本原因 #1 - Codex MCP 安定化

**goal**: Codex MCP が安定して動作し、タイムアウトしない

#### subtasks

- [ ] **p0.1**: タイムアウト原因を調査する
  - executor: claudecode
  - note: |
      調査項目:
      1. MCP サーバーのログを確認
      2. Codex CLI 単体でのレスポンス時間測定
      3. プロンプトサイズとタイムアウトの相関分析
  - validations:
    - technical: "タイムアウト発生条件が特定されている"
    - consistency: "再現手順が文書化されている"
    - completeness: "3 つの調査項目全てに結果がある"

- [ ] **p0.2**: タイムアウト対策を実装する
  - executor: claudecode
  - note: |
      対策候補:
      1. .mcp.json に timeout 設定追加
      2. プロンプト分割戦略の定義
      3. Codex CLI 直接呼び出しへの自動フォールバック
  - validations:
    - technical: ".mcp.json または settings.json に対策設定が追加されている"
    - consistency: "選択した対策の根拠が文書化されている"
    - completeness: "変更後に Codex MCP が応答する"

- [ ] **p0.3**: 安定性を検証する
  - executor: claudecode
  - validations:
    - technical: "mcp__codex__codex で 5 回連続で正常応答を得る"
    - consistency: "各応答時間が 30 秒以内である"
    - completeness: "エラー発生率 0% である"

- [ ] **p0.4**: MCP 安定化失敗時のフォールバック手順を定義する
  - executor: claudecode
  - note: |
      max_iterations (5) 到達後も安定しない場合の代替策:
      1. Codex CLI 直接実行モード（codex exec）を p3-p7 の主要手段とする
      2. executor-guard を CLI 実行も許可するよう調整
      3. ユーザーに状況を報告し、CLI モードでの継続を確認
  - validations:
    - technical: "docs/executor-fallback-policy.md にフォールバック手順が定義されている"
    - consistency: "CLI 直接実行が executor: codex として有効と明記されている"
    - completeness: "p3-p7 で使用可能な具体的コマンド例が含まれている"

**status**: pending
**max_iterations**: 5
**depends_on**: [p_init]

---

### p1: 根本原因 #2 - executor-guard 拡張

**goal**: executor-guard が全ツール（Edit/Write/Task/Bash）を監視する

#### subtasks

- [ ] **p1.1**: 現在の executor-guard の範囲を確認する
  - executor: claudecode
  - validations:
    - technical: "executor-guard.sh の監視対象ツールがリストアップされている"
    - consistency: "現状は Edit/Write のみ監視と確認"
    - completeness: "Task/Bash が監視対象外であることを確認"

- [ ] **p1.2**: Task ツール監視を追加する
  - executor: claudecode
  - note: |
      Task ツールで subagent_type を確認し、
      executor: codex の Phase で claudecode 以外の SubAgent 呼び出しをブロック
  - validations:
    - technical: "executor-guard.sh に Task ツール判定ロジックが追加されている"
    - consistency: "codex-delegate 以外の subagent がブロックされる"
    - completeness: "テストケースで BLOCK を確認"

- [ ] **p1.3**: Bash ツール監視を追加する
  - executor: claudecode
  - note: |
      コード変更を伴う Bash コマンド（git add, npm, etc.）をブロック
      読み取り系（cat, ls, grep）は許可
  - validations:
    - technical: "executor-guard.sh に Bash コマンド判定ロジックが追加されている"
    - consistency: "変更系コマンドのみブロックされる"
    - completeness: "許可/ブロック各 5 パターンがテストされている"

- [ ] **p1.4**: 拡張後のガードをテストする
  - executor: claudecode
  - validations:
    - technical: "tests/guards/test-executor-guard.sh が存在し PASS"
    - consistency: "Edit/Write/Task/Bash 全パターンがテストされている"
    - completeness: "20 テストケース以上が PASS"

**status**: pending
**max_iterations**: 5
**depends_on**: [p0]

---

### p2: 根本原因 #3 - フォールバックポリシー定義

**goal**: executor 失敗時の明示的な対応方針が定義・実装されている

#### subtasks

- [ ] **p2.1**: フォールバックポリシーを文書化する
  - executor: claudecode
  - note: |
      定義項目:
      1. Codex MCP タイムアウト時: ユーザーに確認後 CLI フォールバック
      2. Codex CLI 失敗時: ユーザーに確認後 claudecode 代行（executor 変更必須）
      3. CodeRabbit 失敗時: ユーザーに確認後 reviewer SubAgent 代行
  - validations:
    - technical: "docs/executor-fallback-policy.md が存在する"
    - consistency: "3 パターンの対応方針が定義されている"
    - completeness: "各パターンにユーザー確認フローが含まれている"

- [ ] **p2.2**: フォールバック時のユーザー確認を実装する
  - executor: claudecode
  - note: |
      executor-guard.sh を拡張:
      - Codex 失敗検出時に AskUserQuestion を促すメッセージ
      - ユーザー承認なしでの代行禁止
  - validations:
    - technical: "executor-guard.sh にフォールバック検出ロジックが追加されている"
    - consistency: "BLOCK 時のメッセージにユーザー確認手順が含まれている"
    - completeness: "AskUserQuestion を使用した確認フローが文書化されている"

- [ ] **p2.3**: フォールバックフローをテストする
  - executor: claudecode
  - validations:
    - technical: "tests/guards/test-fallback-policy.sh が存在し PASS"
    - consistency: "3 パターン全てがテストされている"
    - completeness: "ユーザー確認なしの代行が BLOCK されることを確認"

**status**: pending
**max_iterations**: 5
**depends_on**: [p1]

---

### p3: 監査再実行 - ガードスクリプト検証（Codex 実行）

**goal**: 全ガードスクリプトが実際に機能することを Codex が検証する

#### subtasks

- [ ] **p3.1**: 12 ガードスクリプトの動作テストを実行する
  - executor: codex
  - executor_config:
    model: gpt-5.2-codex
    reasoning: medium
  - validations:
    - technical: "Codex 実行ログに 12 スクリプトのテスト結果が含まれている"
    - consistency: "各スクリプトの期待動作（BLOCK/ALLOW）がテストされている"
    - completeness: "12 スクリプト × 2 パターン = 24 テスト以上が実行されている"

- [ ] **p3.2**: exit 0 バイパスポイントを削減する
  - executor: codex
  - executor_config:
    model: gpt-5.2-codex
    reasoning: medium
  - validations:
    - technical: "grep -r 'exit 0' の結果が 30 以下である（59 → 30 以下）"
    - consistency: "削減された各 exit 0 に理由が記録されている"
    - completeness: "削減後も正常フローが動作する"

- [ ] **p3.3**: critic-guard の証拠検証を強化する
  - executor: codex
  - executor_config:
    model: gpt-5.2-codex
    reasoning: medium
  - validations:
    - technical: "critic-guard.sh に 'PASS - ' 形式チェックが含まれている"
    - consistency: "良い証拠/悪い証拠パターンが定義されている"
    - completeness: "10 パターン以上の証拠検証テストが PASS"

**status**: pending
**max_iterations**: 10
**depends_on**: [p2]

---

### p4: 監査再実行 - テスト基盤強化（Codex 実行）

**goal**: 既存テスト基盤が実用に耐える品質であることを Codex が検証・強化する

#### subtasks

- [ ] **p4.1**: tests/guards/ のテストを拡充する
  - executor: codex
  - executor_config:
    model: gpt-5.2-codex
    reasoning: medium
  - validations:
    - technical: "ls tests/guards/*.sh の結果が 6 ファイル以上である"
    - consistency: "各ガードに専用のテストファイルが存在する"
    - completeness: "grep -c 'test_' tests/guards/run-all.sh の結果が 40 以上である"

- [ ] **p4.2**: tests/critic/ のテストを 20 ケースに拡充する
  - executor: codex
  - executor_config:
    model: gpt-5.2-codex
    reasoning: medium
  - validations:
    - technical: "tests/critic/run-critic-tests.sh で 20 テスト以上が定義されている"
    - consistency: "良い証拠 10 ケース、悪い証拠 10 ケースが含まれている"
    - completeness: "全ケースが PASS"

- [ ] **p4.3**: E2E テストを完全なフローカバレッジにする
  - executor: codex
  - executor_config:
    model: gpt-5.2-codex
    reasoning: medium
  - validations:
    - technical: "tests/e2e/contract-test.sh で 30 アサーション以上が定義されている"
    - consistency: "INIT → LOOP → CRITIQUE → POST_LOOP の全パスがテストされている"
    - completeness: "全アサーションが PASS"

**status**: pending
**max_iterations**: 10
**depends_on**: [p3]

---

### p5: CodeRabbit 中間レビュー

**goal**: p0-p4 の変更が品質基準を満たしていることを CodeRabbit が確認する

#### subtasks

- [ ] **p5.1**: executor-guard 拡張をレビューする
  - executor: coderabbit
  - executor_config:
    type: uncommitted
    base: main
    focus: ".claude/skills/playbook-gate/guards/executor-guard.sh"
  - validations:
    - technical: "CodeRabbit 出力に executor-guard.sh のレビュー結果が含まれている"
    - consistency: "セキュリティ観点の評価が含まれている"
    - completeness: "critical/major 指摘がない、または対応済み"

- [ ] **p5.2**: テスト基盤をレビューする
  - executor: coderabbit
  - executor_config:
    focus: "tests/"
  - validations:
    - technical: "CodeRabbit 出力に tests/ のレビュー結果が含まれている"
    - consistency: "テストの網羅性が評価されている"
    - completeness: "critical 指摘がない"

**status**: pending
**max_iterations**: 3
**depends_on**: [p4]

---

### p6: 監査再実行 - 統合テスト（Codex 実行）

**goal**: 修正後のシステムが End-to-End で機能することを Codex が確認する

#### subtasks

- [ ] **p6.1**: TDD フロー playbook を作成・完了する
  - executor: codex
  - executor_config:
    model: gpt-5.2-codex
    reasoning: medium
  - validations:
    - technical: "plan/playbook-test-tdd-flow.md が作成されている"
    - consistency: "INIT → LOOP → CRITIQUE → POST_LOOP が全て完了している"
    - completeness: "playbook が archived/ に移動されている"

- [ ] **p6.2**: 全テストスイートを実行し 100% PASS する
  - executor: codex
  - executor_config:
    model: gpt-5.2-codex
    reasoning: medium
  - validations:
    - technical: "bash .claude/skills/test-runner/scripts/run-all.sh が exit 0"
    - consistency: "Guard/Critic/Typecheck/E2E 全カテゴリが PASS"
    - completeness: "テスト総数が 80 以上である"

**status**: pending
**max_iterations**: 5
**depends_on**: [p5]

---

### p7: CodeRabbit 最終レビュー

**goal**: 全変更が品質基準を満たし、critical/major 指摘がゼロである

#### subtasks

- [ ] **p7.1**: 全変更ファイルをレビューする
  - executor: coderabbit
  - executor_config:
    type: uncommitted
    base: main
  - validations:
    - technical: "CodeRabbit 出力に全変更ファイルのレビュー結果が含まれている"
    - consistency: "セキュリティ・品質観点の評価が完了している"
    - completeness: "critical: 0, major: 0 である"

- [ ] **p7.2**: 指摘事項があれば対応する
  - executor: codex
  - executor_config:
    model: gpt-5.2-codex
    reasoning: medium
  - note: critical/major 指摘がなければスキップ
  - validations:
    - technical: "critical/major 指摘が全て対応済みである"
    - consistency: "対応内容が CodeRabbit 指摘と整合している"
    - completeness: "再レビューで critical: 0, major: 0 を確認"

**status**: pending
**max_iterations**: 5
**depends_on**: [p6]

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p7]

#### subtasks

- [ ] **p_final.1**: executor-guard が全ツールを監視していることを確認する
  - executor: claudecode
  - validations:
    - technical: "executor-guard.sh に Edit/Write/Task/Bash の判定がある"
    - consistency: "テストで全パターンが PASS"
    - completeness: "20 テストケース以上が実行されている"

- [ ] **p_final.2**: Codex MCP の安定性を最終確認する
  - executor: claudecode
  - validations:
    - technical: "mcp__codex__codex で 5 回連続正常応答"
    - consistency: "各応答時間が 30 秒以内"
    - completeness: "p3-p6 で Codex MCP タイムアウトが 0 回"

- [ ] **p_final.3**: p3-p6 の Codex 実行証拠を確認する
  - executor: claudecode
  - validations:
    - technical: "各 Phase の実行ログに 'mcp__codex__codex' または 'codex exec' が含まれている"
    - consistency: "Edit/Write が executor: codex Phase で直接使用されていない"
    - completeness: "全 subtask に Codex 実行証拠がある"

- [ ] **p_final.4**: CodeRabbit 最終レビュー結果を確認する
  - executor: claudecode
  - validations:
    - technical: "p7 の結果が critical: 0, major: 0 である"
    - consistency: "全指摘が対応済み"
    - completeness: "全変更ファイルがレビュー済み"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## risk_assessment

```yaml
risks:
  - id: R1
    description: "Codex MCP タイムアウトが解決しない"
    mitigation: "Codex CLI 直接呼び出しへの安定フォールバック、ユーザー確認フロー"
    probability: medium
    impact: high

  - id: R2
    description: "executor-guard 拡張が正常フローをブロック"
    mitigation: "段階的に監視対象を追加、各段階でテスト実行"
    probability: medium
    impact: medium

  - id: R3
    description: "Codex が複雑なタスクを正しく実行できない"
    mitigation: "タスク分割、明確なプロンプト設計"
    probability: low
    impact: medium

rollback_plan:
  p0_failure:
    trigger: "p0 max_iterations (5) 到達後も Codex MCP が不安定"
    action: "Codex CLI 直接実行モードに切り替え、p0.4 のフォールバック手順を適用"
  general:
    trigger: "p2 完了後に Codex 実行が 3 回連続失敗"
    action: "ユーザー確認を経て executor を claudecode に変更"
```

---

## success_metrics

```yaml
quantitative:
  - executor_enforcement: 100% (4 ツールタイプ全監視)
  - codex_stability: 95% (タイムアウト率 5% 以下)
  - codex_usage: 100% (p3-p6 で Codex 使用証拠あり)
  - guard_test_coverage: 100%
  - coderabbit_critical: 0
  - coderabbit_major: 0

qualitative:
  - executor 指定が構造的に強制される
  - Codex 失敗時はユーザー確認が必須
  - 「見かけだけの executor 運用」が不可能
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-01 | v2: reviewer 指摘対応。p_init.3 削除（循環依存）、テンプレートパス修正、p0.4 フォールバック追加、rollback_plan 拡充。 |
| 2026-01-01 | v1: 初版作成。前回の executor 違反を分析し、根本原因修正を p0-p2 に配置。 |
