# playbook-completion-definition.md

## meta

```yaml
project: completion-definition
branch: feat/completion-definition
created: 2025-12-24
issue: null
reviewed: true
roles:
  worker: claudecode  # ドキュメント作成主体のため claudecode
```

---

## goal

```yaml
summary: リポジトリの「完成の定義」を明確化し、アーキテクチャ図とセットで記録する
done_when:
  - plan/design/completion-definition.md が存在し、完成判定チェックリストが含まれている
  - アーキテクチャ図（ASCII）が含まれ、主要コンポーネントの関係が視覚化されている
  - mission.md の success_criteria との対応表が存在する
  - Self-Healing System の実装状況が Gap 分析されている
```

---

## phases

### p1: 現状分析

**goal**: mission.md と Self-Healing System の実装状況を把握する

**status**: done

#### subtasks

- [x] **p1.1**: mission.md の success_criteria の各項目が検証されている
  - executor: claudecode
  - validations:
    - technical: "mission.md の success_criteria 各項目について、実装証拠を確認"
    - consistency: "README.md や ARCHITECTURE.md の記載と整合性確認"
    - completeness: "5つのカテゴリ（自律性/信頼性/自己認識/自己修復/目的一貫性）全てを確認"

- [x] **p1.2**: Self-Healing System の 4 Phase の実装状況が整理されている
  - executor: claudecode
  - validations:
    - technical: "各 Phase（Context Continuity/Document Freshness/Feature Verification/Self-Improvement）の実装を確認"
    - consistency: "self-healing-system.md の設計と実際の Hook/機能が対応"
    - completeness: "Phase 1-4 全ての実装状況を網羅"

**max_iterations**: 5

---

### p2: Gap 分析

**goal**: 「完成」に必要な未実装項目を特定する

**depends_on**: [p1]
**status**: done

#### subtasks

- [x] **p2.1**: mission.md success_criteria の未達成項目リストが存在する
  - executor: claudecode
  - validations:
    - technical: "p1.1 の検証結果から未達成項目を抽出"
    - consistency: "mission.md の記載と整合性確認"
    - completeness: "全カテゴリの未達成項目を網羅"

- [x] **p2.2**: Self-Healing System の未実装 Phase/機能リストが存在する
  - executor: claudecode
  - validations:
    - technical: "p1.2 の分析結果から未実装項目を抽出"
    - consistency: "self-healing-system.md の設計と比較"
    - completeness: "Phase 1-4 の全成功基準をカバー"

**status**: pending
**max_iterations**: 5

---

### p3: 完成定義文書作成

**goal**: plan/design/completion-definition.md を作成する

**depends_on**: [p2]
**status**: done

#### subtasks

- [x] **p3.1**: 完成判定チェックリスト（3階層）が定義されている
  - executor: claudecode
  - validations:
    - technical: "L1（必須）/L2（推奨）/L3（オプション）の3階層構造で記述"
    - consistency: "mission.md success_criteria と Gap 分析結果と整合"
    - completeness: "全必須項目がチェックリストに含まれる"

- [x] **p3.2**: アーキテクチャ図（ASCII）が作成されている
  - executor: claudecode
  - validations:
    - technical: "主要コンポーネント（Hooks/SubAgents/Skills/Commands/State）の関係を表現"
    - consistency: "ARCHITECTURE.md と docs/repository-structure.md と整合"
    - completeness: "データフロー、制御フロー、依存関係を含む"

- [x] **p3.3**: mission.md success_criteria との対応表が存在する
  - executor: claudecode
  - validations:
    - technical: "success_criteria 各項目に対応する実装/検証方法を記載"
    - consistency: "mission.md の構造（5カテゴリ）と対応"
    - completeness: "全 success_criteria 項目をカバー"

- [x] **p3.4**: Self-Healing System 実装状況セクションが存在する
  - executor: claudecode
  - validations:
    - technical: "Phase 1-4 の実装状況（完了/部分実装/未実装）を記載"
    - consistency: "self-healing-system.md の成功基準と対応"
    - completeness: "Phase 1-4 の全成功基準について状況を記載"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: done_when が全て満たされているか最終検証

**depends_on**: [p3]
**status**: done

#### subtasks

- [x] **p_final.1**: plan/design/completion-definition.md が存在し、完成判定チェックリストが含まれている
  - executor: claudecode
  - validations:
    - technical: "test -f plan/design/completion-definition.md && grep -q 'チェックリスト' で確認"
    - consistency: "チェックリストが3階層（L1/L2/L3）構造になっている"
    - completeness: "L1（必須）に最低5項目以上含まれている"

- [x] **p_final.2**: アーキテクチャ図（ASCII）が含まれ、主要コンポーネントの関係が視覚化されている
  - executor: claudecode
  - validations:
    - technical: "ASCII 図が存在し、Hooks/SubAgents/Skills/Commands/State が含まれる"
    - consistency: "ARCHITECTURE.md の記載と矛盾がない"
    - completeness: "制御フロー、データフロー、依存関係の3観点を含む"

- [x] **p_final.3**: mission.md の success_criteria との対応表が存在する
  - executor: claudecode
  - validations:
    - technical: "表形式で success_criteria と実装/検証方法の対応が記載されている"
    - consistency: "mission.md の 5 カテゴリと対応"
    - completeness: "全 success_criteria 項目（15項目程度）をカバー"

- [x] **p_final.4**: Self-Healing System の実装状況が Gap 分析されている
  - executor: claudecode
  - validations:
    - technical: "Phase 1-4 の実装状況が明示されている"
    - consistency: "self-healing-system.md の成功基準と対応"
    - completeness: "未実装項目と対応方針が記載されている"

**status**: pending
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

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-24 | 初版作成。pm による playbook 生成。 |
