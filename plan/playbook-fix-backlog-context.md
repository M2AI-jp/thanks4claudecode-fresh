# playbook-fix-backlog-context.md

## meta

```yaml
project: fix-backlog-context
branch: docs/fix-backlog-context
created: 2026-01-03
issue: null
reviewed: true
```

---

## goal

```yaml
summary: docs/fix-backlog.md に文脈情報（Section 0）と使用方法セクション改訂を追加し、ドキュメントの目的・背景を明確化する
done_when:
  - docs/fix-backlog.md に「Section 0: 目的と文脈」が存在する
  - Section 0 に origin, purpose, principles, related_documents が含まれている
  - 使用方法セクションに playbook 生成フローと anti-fraud プロトコルが含まれている
  - 既存の Section 1-5 が維持されている
```

---

## context

```yaml
5w1h:
  who: pm SubAgent が playbook 生成時に参照し、done_criteria 設計に活用
  what: docs/fix-backlog.md に Section 0（目的と文脈）を追加し、使用方法セクションを改訂
  when: 今回のセッションで完了
  where: docs/fix-backlog.md（対象ファイル）
  why: 現状の fix-backlog.md は「目的のない作業指示書」になっている。skill-audit-v2 で発見された 39 件の問題の永続化のために作成されたが、その文脈が欠落。v1 監査の「全て keep」という報酬詐欺から学んだ教訓を反映する必要がある
  how: Section 0 追加（origin, purpose, principles, related_documents）+ 使用方法セクション改訂（playbook 生成フロー明確化、anti-fraud プロトコル追加）

analysis_result:
  source: prompt-analyzer
  timestamp: 2026-01-03T14:25:00Z
  data:
    5w1h:
      who: pm SubAgent
      what: docs/fix-backlog.md への文脈情報追加
      when: 今回のセッション
      where: docs/fix-backlog.md
      why: ドキュメントの目的・背景が欠落している
      how: Section 0 追加 + 使用方法改訂
    risks:
      technical: []
      scope: []
      dependency: []
    ambiguity: []
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

translated_requirements:
  source: term-translator
  timestamp: 2026-01-03T14:25:00Z
  data:
    original_terms: []
    technical_requirements: []
    codebase_context:
      relevant_files:
        - docs/fix-backlog.md
        - .claude/SKILL_INDEX_v2.md
        - .claude/frameworks/self-evaluation-defense.md
      existing_patterns: []
      conventions: []

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-03T14:26:00Z
  summary: "docs/fix-backlog.md に Section 0（目的と文脈）を追加し、使用方法セクションを改訂する"
  approved_items:
    - question_id: approval
      question: "この理解で playbook を作成してよろしいですか？"
      answer: "はい、進めてください"
  technical_requirements_confirmed: []
```

---

## phases

### p1: Section 0 追加

**goal**: docs/fix-backlog.md に「Section 0: 目的と文脈」を追加する

#### subtasks

- [x] **p1.1**: docs/fix-backlog.md に「## Section 0: 目的と文脈」セクションが存在する
  - executor: claudecode
  - validations:
    - technical: "PASS - grep '## Section 0' docs/fix-backlog.md で検出"
    - consistency: "PASS - Section 1-5 が維持されている（grep で 5 件検出）"
    - completeness: "PASS - Section 0 が使用方法セクションの前に配置"
  - validated: 2026-01-03T14:35:00+09:00

- [x] **p1.2**: Section 0 に origin（作成経緯）が含まれている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 'origin:' docs/fix-backlog.md で行 17 に検出"
    - consistency: "PASS - skill-audit-v2 への参照が含まれている"
    - completeness: "PASS - 39 件の問題発見という経緯が記載"
  - validated: 2026-01-03T14:35:00+09:00

- [x] **p1.3**: Section 0 に purpose（目的）が含まれている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 'purpose:' docs/fix-backlog.md で行 33 に検出"
    - consistency: "PASS - playbook 生成時の参照という目的が明記"
    - completeness: "PASS - done_criteria 設計への活用が記載"
  - validated: 2026-01-03T14:35:00+09:00

- [x] **p1.4**: Section 0 に principles（教訓・原則）が含まれている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 'principles:' docs/fix-backlog.md で行 47 に検出"
    - consistency: "PASS - 報酬詐欺への言及があり、self-evaluation-defense.md を参照"
    - completeness: "PASS - 4 原則（外部検証、反証モード、トレーサビリティ、正直さ）が記載"
  - validated: 2026-01-03T14:35:00+09:00

- [x] **p1.5**: Section 0 に related_documents（関連ドキュメント）が含まれている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 'related_documents:' docs/fix-backlog.md で行 61 に検出"
    - consistency: "PASS - SKILL_INDEX_v2.md, self-evaluation-defense.md への参照あり"
    - completeness: "PASS - 3 件の関連ドキュメント（パス + 役割）が記載"
  - validated: 2026-01-03T14:35:00+09:00

**status**: done
**max_iterations**: 5

---

### p2: 使用方法セクション改訂

**goal**: 使用方法セクションに playbook 生成フローと anti-fraud プロトコルを追加する
**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: 使用方法セクションに playbook 生成フローが追加されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 'playbook 生成フロー' docs/fix-backlog.md で行 74 に検出"
    - consistency: "PASS - pm SubAgent の参照フローが step_1 〜 step_4 で記載"
    - completeness: "PASS - PB-XX 特定 → Scope/Done when 取得 → 詳細分析 → playbook 反映の手順が記載"
  - validated: 2026-01-03T14:36:00+09:00

- [x] **p2.2**: 使用方法セクションに anti-fraud プロトコルが追加されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 'anti-fraud プロトコル' docs/fix-backlog.md で行 109 に検出"
    - consistency: "PASS - prohibited/required 構造が self-evaluation-defense.md と整合"
    - completeness: "PASS - evidence_format（technical/consistency/completeness）が記載"
  - validated: 2026-01-03T14:36:00+09:00

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証
**depends_on**: [p1, p2]

#### subtasks

- [x] **p_final.1**: docs/fix-backlog.md に「Section 0: 目的と文脈」が存在する
  - executor: claudecode
  - validations:
    - technical: "PASS - grep '## Section 0' docs/fix-backlog.md で検出"
    - consistency: "PASS - Section 0 が使用方法の前に配置"
    - completeness: "PASS - origin/purpose/principles/related_documents が全て存在"
  - validated: 2026-01-03T14:37:00+09:00

- [x] **p_final.2**: Section 0 に origin, purpose, principles, related_documents が含まれている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で 4 フィールド検出（行 17,33,47,61）"
    - consistency: "PASS - 各フィールドが skill-audit-v2/self-evaluation-defense.md を参照"
    - completeness: "PASS - 全 4 フィールドが存在し内容が充実"
  - validated: 2026-01-03T14:37:00+09:00

- [x] **p_final.3**: 使用方法セクションに playbook 生成フローと anti-fraud プロトコルが含まれている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で playbook 生成フロー（行 74）と anti-fraud（行 109）検出"
    - consistency: "PASS - pm SubAgent の動作と整合した step_1-4 フロー"
    - completeness: "PASS - 手順が具体的（PB-XX 特定 → done_criteria 反映まで）"
  - validated: 2026-01-03T14:37:00+09:00

- [x] **p_final.4**: 既存の Section 1-5 が維持されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で Section 1-5 全て検出（5 件）"
    - consistency: "PASS - 既存セクションの内容は変更なし"
    - completeness: "PASS - 全 5 セクションが維持されている"
  - validated: 2026-01-03T14:37:00+09:00

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: done

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done
