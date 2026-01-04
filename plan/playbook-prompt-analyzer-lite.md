# playbook-prompt-analyzer-lite.md

## meta

```yaml
project: prompt-analyzer-lite
branch: refactor/prompt-analyzer-lite
created: 2026-01-04
issue: null
reviewed: false
```

---

## goal

```yaml
summary: prompt-analyzer を軽量化する（920行 → 200行以下）、全機能を保持
done_when:
  - prompt-analyzer.md が 200 行以下である
  - SKILL.md が 100 行以下である
  - 5W1H 分析機能が保持されている
  - リスク分析機能（technical/scope/dependency）が保持されている
  - 曖昧さ検出機能が保持されている
  - 論点分解機能（multi_topic_detection）が保持されている
  - 拡張分析項目（test_strategy/preconditions/success_criteria/reverse_dependencies）が保持されている
  - 出力フォーマット（YAML 形式）が保持されている
```

---

## context

```yaml
5w1h:
  who: LLM（Claude）
  what: prompt-analyzer の記述を軽量化
  when: 今回のセッション
  where: .claude/skills/prompt-analyzer/agents/prompt-analyzer.md, SKILL.md
  why: 現在 920 行で重すぎる → Hook 遅延 → Claude がスキップ → Hook 違反
  how: 冗長な記述を削減、機能は全て保持

analysis_result:
  source: prompt-analyzer（playbook-init 経由で受信済み）
  data:
    risks:
      technical:
        - risk: 削減しすぎて機能が欠落する
          severity: high
          mitigation: 機能チェックリストを作成し、削減後に検証
      scope:
        - risk: LLM が暗黙知として持っていない機能定義を削除してしまう
          severity: medium
          mitigation: 出力フォーマットと制約のみ残す方針
    ambiguity: []
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-04
  summary: |
    「機能は全て保持されなければならない」という制約のもと、
    冗長な説明・例示・ルール記述を簡略化する。
    LLM は十分な知識があるので、詳細なパターン定義は不要。
```

---

## phases

### p1: 機能目録作成

**goal**: 削減対象と保持すべき機能を明確化する

#### subtasks

- [ ] **p1.1**: 現在の機能一覧がリストアップされている
  - executor: claudecode
  - validations:
    - technical: "5W1H, リスク分析, 曖昧さ検出, 論点分解, 拡張分析項目が列挙されている"
    - consistency: "SKILL.md と agents/prompt-analyzer.md の機能が一致"
    - completeness: "全機能が網羅されている"

- [ ] **p1.2**: 削減対象セクションが特定されている
  - executor: claudecode
  - validations:
    - technical: "各セクションの行数と削減可能性が評価されている"
    - consistency: "機能定義ではなく説明・例示が削減対象"
    - completeness: "目標 200 行以下が達成可能な計画がある"

**status**: pending
**max_iterations**: 3

---

### p2: agents/prompt-analyzer.md 軽量化

**goal**: 920 行を 200 行以下に削減（機能保持）

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: agents/prompt-analyzer.md が 200 行以下である
  - executor: claudecode
  - validations:
    - technical: "wc -l で 200 行以下を確認"
    - consistency: "出力フォーマット（YAML）が保持されている"
    - completeness: "5W1H, リスク分析, 曖昧さ検出, 論点分解, 拡張分析項目の機能定義が保持されている"

**status**: pending
**max_iterations**: 5

---

### p3: SKILL.md 軽量化

**goal**: 243 行を 100 行以下に削減（機能保持）

**depends_on**: [p1]

#### subtasks

- [ ] **p3.1**: SKILL.md が 100 行以下である
  - executor: claudecode
  - validations:
    - technical: "wc -l で 100 行以下を確認"
    - consistency: "agents/prompt-analyzer.md との重複が解消されている"
    - completeness: "Skill の役割と呼び出し方法が記載されている"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: done_when の全項目が満たされていることを検証

**depends_on**: [p2, p3]

#### subtasks

- [ ] **p_final.1**: 行数が目標以下である
  - executor: claudecode
  - validations:
    - technical: "wc -l で agents/prompt-analyzer.md <= 200, SKILL.md <= 100 を確認"
    - consistency: "合計 300 行以下"
    - completeness: "両ファイルが確認されている"

- [ ] **p_final.2**: 5W1H 分析機能が保持されている
  - executor: claudecode
  - validations:
    - technical: "grep で 5w1h セクションの存在を確認"
    - consistency: "who/what/when/where/why/how/missing が定義されている"
    - completeness: "出力フォーマットに 5w1h が含まれている"

- [ ] **p_final.3**: リスク分析機能が保持されている
  - executor: claudecode
  - validations:
    - technical: "grep で risks セクションの存在を確認"
    - consistency: "technical/scope/dependency が定義されている"
    - completeness: "出力フォーマットに risks が含まれている"

- [ ] **p_final.4**: 曖昧さ検出機能が保持されている
  - executor: claudecode
  - validations:
    - technical: "grep で ambiguity セクションの存在を確認"
    - consistency: "term/clarification_needed が定義されている"
    - completeness: "出力フォーマットに ambiguity が含まれている"

- [ ] **p_final.5**: 論点分解機能が保持されている
  - executor: claudecode
  - validations:
    - technical: "grep で multi_topic_detection セクションの存在を確認"
    - consistency: "topics/decomposition_needed が定義されている"
    - completeness: "出力フォーマットに multi_topic_detection が含まれている"

- [ ] **p_final.6**: 拡張分析項目が保持されている
  - executor: claudecode
  - validations:
    - technical: "grep で test_strategy/preconditions/success_criteria/reverse_dependencies の存在を確認"
    - consistency: "各項目の構造が定義されている"
    - completeness: "出力フォーマットに拡張項目が含まれている"

- [ ] **p_final.7**: 出力フォーマット（YAML）が保持されている
  - executor: claudecode
  - validations:
    - technical: "出力フォーマットセクションが存在する"
    - consistency: "analysis: のルート構造が保持されている"
    - completeness: "必須アクションセクションが含まれている"

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
