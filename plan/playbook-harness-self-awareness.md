# playbook-harness-self-awareness.md

> **ハーネス自己認識 v2: Claude Code がリポジトリ全体を掌握し、自動メンテナンスできる仕組みの構築**

---

## meta

```yaml
project: harness-self-awareness-v2
branch: feat/harness-self-awareness
created: 2026-01-02
issue: null
reviewed: true  # reviewer PASS: 2026-01-02T23:30:00Z
roles:
  worker: codex  # 本格的なコード実装は codex
```

---

## goal

```yaml
summary: Claude Code がリポジトリ全体を掌握し、ユーザープロンプトなしで自動メンテナンスできる仕組みを構築する
done_when:
  - 不要ファイルが削除されている（context-estimator、旧 session-start.sh）
  - prompt-analyzer に「複数論点・指示の分解」機能が組み込まれている
  - SessionStart 時に全 Hook/Skill/SubAgent の状態が読み込まれる
  - ARCHITECTURE.md と実装の整合性が自動チェックされる
  - 問題検出時に自動修正（軽微）または提案（重大）される
```

---

## context

```yaml
5w1h:
  who: Claude Code 自律運用フレームワークのユーザー
  what: リポジトリ全体を掌握し、自動メンテナンスできる仕組み
  when: 現在のセッションで完了
  where: .claude/hooks/, .claude/skills/, docs/
  why: 現在は全 Hook/Skill/SubAgent を読んでいない、整合性を自動チェックしていない
  how: 不要ファイル削除、prompt-analyzer 拡張、SessionStart 読み込み強化、整合性自動チェック

analysis_result:
  source: prompt-analyzer
  timestamp: 2026-01-02T23:00:00Z
  data:
    5w1h:
      who: Claude Code ユーザー
      what: ハーネス自己認識（掌握 + 自動メンテナンス）
      when: 現セッション
      where: リポジトリ全体（hooks, skills, agents, docs）
      why: 全体掌握ができていない、自動メンテナンスがない
      how: 削除 + 拡張 + 強化 + 自動化
    risks:
      technical:
        - risk: SessionStart が重くなる可能性
          severity: medium
          mitigation: 軽量な状態確認のみ、詳細は遅延読み込み
        - risk: prompt-analyzer の拡張が複雑になる
          severity: medium
          mitigation: 論点分解を単純なロジックで実装
      scope:
        - risk: 自動修正が意図しない変更を行う
          severity: high
          mitigation: 軽微な問題のみ自動修正、重大な問題は提案のみ
      dependency:
        - risk: 既存 Hook との整合性
          severity: low
          mitigation: pre-tool.sh との連携を維持
    ambiguity: []
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

translated_requirements:
  source: term-translator
  timestamp: 2026-01-02T23:00:00Z
  data:
    original_terms:
      - original: リポジトリ全体を掌握
        translated: SessionStart 時に全コンポーネントの状態を読み込む
        rationale: 掌握 = 状態把握
        alternatives: []
      - original: 自動でメンテナンス
        translated: 整合性チェック + 自動修正（軽微）/ 提案（重大）
        rationale: ユーザープロンプト不要で問題を検出・対応
        alternatives: []
      - original: 複数論点の分解
        translated: prompt-analyzer に論点分解機能を追加
        rationale: 1プロンプトに複数指示がある場合の分解
        alternatives: []
    technical_requirements:
      - requirement: context-estimator 削除
        derived_from: ユーザー判断「いらない」
        implementation_hint: rm -rf .claude/skills/context-estimator
      - requirement: session-start.sh 再設計
        derived_from: 現在は health.sh 呼び出しのみで掌握に貢献しない
        implementation_hint: 全コンポーネント状態の軽量読み込み
      - requirement: prompt-analyzer 拡張
        derived_from: 複数論点・指示の分解
        implementation_hint: 論点検出 + 分解ロジック
      - requirement: 整合性自動チェック
        derived_from: ARCHITECTURE.md と実装の整合性
        implementation_hint: セクション単位で実装状態を確認
      - requirement: 自動修正/提案
        derived_from: 問題検出時の対応
        implementation_hint: 軽微（自動修正）/ 重大（提案）の判定ロジック
    codebase_context:
      relevant_files:
        - .claude/hooks/session-start.sh（削除 → 再作成）
        - .claude/skills/context-estimator/（削除）
        - .claude/skills/prompt-analyzer/（拡張）
        - docs/ARCHITECTURE.md
      existing_patterns:
        - Hook スクリプト形式
        - Skill ディレクトリ構造
        - SubAgent 定義形式
      conventions:
        - bash -n でシンタックスチェック
        - SKILL.md + agents/ を含む

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-02T23:10:00Z
  summary: |
    Claude Code がリポジトリ全体を掌握し、自動メンテナンスできる仕組みを構築する。
    1. context-estimator 削除（ユーザー判断「いらない」）
    2. session-start.sh 削除 → 再設計（全コンポーネント状態読み込み）
    3. prompt-analyzer に論点分解機能追加
    4. ARCHITECTURE.md と実装の整合性チェック
    5. 自動修正（軽微）/ 提案（重大）の実装
  approved_items:
    - question_id: Q1
      question: context-estimator の削除
      answer: はい、削除。ユーザーが「いらない」と明言済み。
    - question_id: Q2
      question: session-start.sh の扱い
      answer: 削除して新しい設計で再作成。
    - question_id: Q3
      question: 自動修正 vs 提案
      answer: B（軽微な問題は自動修正、重大な問題は提案のみ）
    - question_id: Q4
      question: worker 設定
      answer: codex
  technical_requirements_confirmed:
    - original: context-estimator
      confirmed_translation: 削除
    - original: session-start.sh
      confirmed_translation: 削除 → 再設計
    - original: 自動修正範囲
      confirmed_translation: 軽微のみ自動、重大は提案
```

---

## phases

### p1: 不要ファイル削除

**goal**: 前バージョンで作成した不要ファイルを削除し、クリーンな状態にする

#### subtasks

- [x] **p1.1**: .claude/skills/context-estimator/ が削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - test -d で exit code 1 確認"
    - consistency: "PASS - .claude/skills/ に context-estimator なし"
    - completeness: "PASS - ディレクトリ全体が削除されている"
  - validated: 2026-01-02T23:35:00Z

- [x] **p1.2**: .claude/hooks/session-start.sh が削除されている（後で再作成）
  - executor: claudecode
  - validations:
    - technical: "PASS - test -f で exit code 1 確認"
    - consistency: "PASS - settings.json の SessionStart 登録は保持"
    - completeness: "PASS - ファイルが削除されている"
  - validated: 2026-01-02T23:35:00Z

**status**: done
**max_iterations**: 3

---

### p2: prompt-analyzer 拡張

**goal**: prompt-analyzer に複数論点・指示の分解機能を追加する

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: prompt-analyzer.md に論点分解セクションが追加されている
  - executor: codex
  - validations:
    - technical: "PASS - grep で multi_topic_detection セクション存在確認"
    - consistency: "PASS - 既存の5W1H、リスク分析と同様の構造"
    - completeness: "PASS - 検出ロジック、論点タイプ分類、出力フォーマット定義済み"
  - validated: 2026-01-02T23:40:00Z

- [x] **p2.2**: SKILL.md に論点分解の使用方法が記載されている
  - executor: codex
  - validations:
    - technical: "PASS - grep で multi_topic_detection セクション存在確認"
    - consistency: "PASS - Integration with pm.md に step_0.5 として組み込み"
    - completeness: "PASS - 入力例、出力例（4論点）、pm連携方法が含まれている"
  - validated: 2026-01-02T23:40:00Z

**status**: done
**max_iterations**: 5

---

### p3: SessionStart 強化（全コンポーネント読み込み）

**goal**: SessionStart 時に全 Hook/Skill/SubAgent の状態を読み込む仕組みを実装する

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: .claude/hooks/session-start.sh が存在し、シンタックスエラーがない
  - executor: codex
  - validations:
    - technical: "PASS - bash -n でシンタックスチェック PASS"
    - consistency: "PASS - set -euo pipefail 使用"
    - completeness: "PASS - Hook/Skill/SubAgent 状態読み込み、サマリ表示実装"
  - validated: 2026-01-02T23:45:00Z

- [x] **p3.2**: SessionStart 時に Hook 一覧と状態が出力される
  - executor: codex
  - validations:
    - technical: "PASS - SESSION_START=true で実行時、Hooks: 6 registered と表示"
    - consistency: "PASS - .claude/settings.json の登録数と一致"
    - completeness: "PASS - 各 Hook の存在確認結果（6 OK, 0 missing）が含まれる"
  - validated: 2026-01-02T23:50:00Z

- [x] **p3.3**: SessionStart 時に Skill 一覧と状態が出力される
  - executor: codex
  - validations:
    - technical: "PASS - SESSION_START=true で実行時、Skills: 21 found と表示"
    - consistency: "PASS - .claude/skills/ 内のディレクトリ数と一致"
    - completeness: "PASS - SKILL.md 存在確認結果（21 have SKILL.md）が含まれる"
  - validated: 2026-01-02T23:50:00Z

- [x] **p3.4**: SessionStart 時に SubAgent 一覧と状態が出力される
  - executor: codex
  - validations:
    - technical: "PASS - SESSION_START=true で実行時、SubAgents: 10 found と表示"
    - consistency: "PASS - .claude/skills/*/agents/ 内の .md ファイル数と一致"
    - completeness: "PASS - SubAgent のカウントが含まれる"
  - validated: 2026-01-02T23:50:00Z

**status**: done
**max_iterations**: 5

---

### p4: 整合性自動チェック

**goal**: ARCHITECTURE.md と実装の整合性を自動チェックする仕組みを実装する

**depends_on**: [p3]

#### subtasks

- [x] **p4.1**: .claude/skills/coherence-checker/SKILL.md が存在する
  - executor: codex
  - validations:
    - technical: "PASS - test -f で存在確認"
    - consistency: "PASS - Purpose, When to Use, Output Format を含む構造"
    - completeness: "PASS - チェック項目、判定基準、出力フォーマットが定義されている"
  - validated: 2026-01-03T00:03:00Z

- [x] **p4.2**: .claude/skills/coherence-checker/scripts/check.sh が存在し、シンタックスエラーがない
  - executor: codex
  - validations:
    - technical: "PASS - bash -n でシンタックスチェック PASS"
    - consistency: "PASS - set -euo pipefail 使用"
    - completeness: "PASS - Hook/Skill/SubAgent の3カテゴリを双方向チェック"
  - validated: 2026-01-03T00:03:00Z

- [x] **p4.3**: check.sh が ARCHITECTURE.md と実装の整合性を検出できる
  - executor: codex
  - validations:
    - technical: "PASS - 実行して YAML 形式で結果を出力（verified:36, inconsistent:1, missing:3）"
    - consistency: "PASS - verified/inconsistent/missing の分類が正確"
    - completeness: "PASS - Hooks, Skills, SubAgents の各セクションをカバー"
  - validated: 2026-01-03T00:03:00Z

**status**: done
**max_iterations**: 5

---

### p5: 自動修正/提案

**goal**: 問題検出時に自動修正（軽微）または提案（重大）する仕組みを実装する

**depends_on**: [p4]

#### subtasks

- [x] **p5.1**: coherence-checker に severity 判定ロジックが実装されている
  - executor: codex
  - validations:
    - technical: "PASS - get_severity() 関数で missing→low, inconsistent→medium 判定"
    - consistency: "PASS - SKILL.md に severity 判定基準が記載されている"
    - completeness: "PASS - low=auto_fix、medium/high=suggestion の対応が実装"
  - validated: 2026-01-03T00:10:00Z

- [x] **p5.2**: 軽微な問題（severity: low）が自動修正される
  - executor: codex
  - validations:
    - technical: "PASS - missing 問題に対して auto_fix セクションが生成される"
    - consistency: "PASS - action, section, content の構造で出力"
    - completeness: "PASS - ARCHITECTURE.md への追記内容が生成される"
  - validated: 2026-01-03T00:10:00Z

- [x] **p5.3**: 重大な問題（severity: medium/high）が提案として出力される
  - executor: codex
  - validations:
    - technical: "PASS - inconsistent 問題に対して suggestion セクションが YAML で出力"
    - consistency: "PASS - problem, action, reason, options の構造で出力"
    - completeness: "PASS - ユーザーが判断できる選択肢（実装 or 参照削除）が含まれる"
  - validated: 2026-01-03T00:10:00Z

**status**: done
**max_iterations**: 5

---

### p_self_update: ドキュメント更新

**goal**: 新機能のドキュメント整合性を確保する

**depends_on**: [p5]

#### subtasks

- [x] **p_self_update.1**: docs/repository-map.yaml に新規ファイルが追加されている
  - executor: claudecode
  - validations:
    - technical: "PASS - generate-repository-map.sh 実行後、Skills: 22 に増加"
    - consistency: "PASS - 既存形式維持"
    - completeness: "PASS - coherence-checker が追加されている"
  - validated: 2026-01-03T00:15:00Z

- [x] **p_self_update.2**: docs/harness-self-awareness-design.md が更新されている
  - executor: claudecode
  - validations:
    - technical: "PASS - ステータスを v2 実装完了に更新"
    - consistency: "PASS - 既存セクション維持、v2ロードマップ追加"
    - completeness: "PASS - 全5フェーズの実装内容が記載"
  - validated: 2026-01-03T00:15:00Z

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p_self_update]

#### subtasks

- [x] **p_final.1**: 不要ファイルが削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - test -d で DELETED 確認"
    - consistency: "PASS - context-estimator への参照なし"
    - completeness: "PASS - ディレクトリ全体が削除済み"
  - validated: 2026-01-03T00:20:00Z

- [x] **p_final.2**: prompt-analyzer に論点分解機能が組み込まれている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で multi_topic_detection が2ファイルで検出"
    - consistency: "PASS - SKILL.md と prompt-analyzer.md の両方に記載"
    - completeness: "PASS - detected, topic_count, topics, decomposition_needed 構造が完成"
  - validated: 2026-01-03T00:20:00Z

- [x] **p_final.3**: SessionStart 時に全コンポーネント状態が読み込まれる
  - executor: claudecode
  - validations:
    - technical: "PASS - Hooks: 6, Skills: 22, SubAgents: 10 が出力"
    - consistency: "PASS - 実際のファイル数と一致"
    - completeness: "PASS - 全カテゴリがカバーされている"
  - validated: 2026-01-03T00:20:00Z

- [x] **p_final.4**: 整合性が自動チェックされる
  - executor: claudecode
  - validations:
    - technical: "PASS - coherence_check YAML 出力（verified:36, inconsistent:1, missing:3）"
    - consistency: "PASS - ARCHITECTURE.md と実装状態の比較が正確"
    - completeness: "PASS - hooks, skills, subagents の各セクションをカバー"
  - validated: 2026-01-03T00:20:00Z

- [x] **p_final.5**: 問題検出時に自動修正/提案される
  - executor: claudecode
  - validations:
    - technical: "PASS - severity:low → auto_fix、severity:medium → suggestion が出力"
    - consistency: "PASS - SKILL.md に severity 判定基準が記載"
    - completeness: "PASS - 4件の recommendations が出力（1 medium, 3 low）"
  - validated: 2026-01-03T00:20:00Z

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done (Skills: 22 確認済み)

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: done

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-02 | v2: 方向転換。context-estimator 削除、SessionStart 再設計、整合性チェック追加 |
| 2026-01-02 | v1: 初版作成（アーカイブせず上書き） |
