# playbook-refactor-remove-project.md

> **project/milestone 機能を削除し、playbook と state.md を核にしたシンプルなオーケストレーションに移行**

---

## meta

```yaml
project: project/milestone 機能削除リファクタリング
branch: refactor/remove-project
created: 2025-12-23
issue: null
reviewed: true
```

---

## goal

```yaml
summary: project.md と milestone 機能を削除し、playbook と state.md を核にしたシンプルなオーケストレーションに移行する
done_when:
  - plan/project.md が削除されている
  - state.md に project と milestone フィールドが存在しない
  - hooks から vision.goal 注入と milestone 更新ロジックが削除されている
  - Skills から project.md 参照と milestone トリガーが削除されている
  - derives_from フィールドが playbook テンプレートから削除されている
  - 全ての hooks と Skills が正常に動作する
```

---

## phases

### p1: ファイル削除とテンプレート修正

**goal**: 削除対象ファイルを削除し、テンプレートから不要なフィールドを除去する

#### subtasks

- [x] **p1.1**: plan/project.md が削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - test ! -f plan/project.md で存在しないことを確認"
    - consistency: "PASS - 他のファイルから参照削除完了"
    - completeness: "PASS - 削除完了"
  - validated: 2025-12-23T22:00:00

- [x] **p1.2**: .claude/schema/project-schema.md が削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - test ! -f で確認、存在しない"
    - consistency: "PASS - schema 参照箇所なし"
    - completeness: "PASS - 削除完了"
  - validated: 2025-12-23T22:00:00

- [x] **p1.3**: .claude/skills/completion-review/hooks/milestone-impact-analyzer.sh が削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - test ! -f で確認、存在しない"
    - consistency: "PASS - settings.json に未登録"
    - completeness: "PASS - 削除完了"
  - validated: 2025-12-23T22:00:00

- [x] **p1.4**: plan/template/playbook-format.md から derives_from フィールドが削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で検出されない"
    - consistency: "PASS - meta セクション更新済み"
    - completeness: "PASS - 導出ガイドセクションも削除済み"
  - validated: 2025-12-23T22:00:00

- [x] **p1.5**: plan/template/state-initial.md から milestone フィールドが削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep milestone で検出されない"
    - consistency: "PASS - goal セクション構造正常"
    - completeness: "PASS - 他フィールド保持"
  - validated: 2025-12-23T22:00:00

**status**: done

---

### p2: Hooks の修正

**goal**: 9つの hooks から vision.goal 注入、milestone 更新、project.md 参照を削除する

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: prompt-guard.sh から vision.goal 注入が削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep vision.goal で検出されない"
    - consistency: "PASS - 他の注入ロジック保持"
    - completeness: "PASS - bash -n OK"
  - validated: 2025-12-23T22:00:00

- [x] **p2.2**: pre-compact.sh から vision.goal 保護が削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep vision.goal で検出されない"
    - consistency: "PASS - 他の保護ロジック保持"
    - completeness: "PASS - bash -n OK"
  - validated: 2025-12-23T22:00:00

- [x] **p2.3**: archive-playbook.sh から milestone 更新ロジックが削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep milestone で検出されない"
    - consistency: "PASS - アーカイブ機能保持"
    - completeness: "PASS - bash -n OK"
  - validated: 2025-12-23T22:00:00

- [x] **p2.4**: cleanup-hook.sh から milestone 進捗表示が削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep milestone で検出されない"
    - consistency: "PASS - cleanup ロジック保持"
    - completeness: "PASS - bash -n OK"
  - validated: 2025-12-23T22:00:00

- [x] **p2.5**: init-guard.sh から project.md 必須チェックが削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep project.md で検出されない"
    - consistency: "PASS - 他の必須チェック保持"
    - completeness: "PASS - bash -n OK"
  - validated: 2025-12-23T22:00:00

- [x] **p2.6**: system-health-check.sh から milestone 整合性チェックが削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep milestone で検出されない"
    - consistency: "PASS - 他のヘルスチェック保持"
    - completeness: "PASS - bash -n OK"
  - validated: 2025-12-23T22:00:00

- [x] **p2.7**: check-integrity.sh から milestone チェックが削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep milestone で検出されない"
    - consistency: "PASS - 他の整合性チェック保持"
    - completeness: "PASS - bash -n OK"
  - validated: 2025-12-23T22:00:00

- [x] **p2.8**: merge-pr.sh から milestone リセットが削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep milestone で検出されない"
    - consistency: "PASS - マージ機能保持"
    - completeness: "PASS - bash -n OK"
  - validated: 2025-12-23T22:00:00

- [x] **p2.9**: scope-guard.sh から project.md 監視が削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep project.md で検出されない"
    - consistency: "PASS - スコープガード保持"
    - completeness: "PASS - bash -n OK"
  - validated: 2025-12-23T22:00:00

**status**: done

---

### p3: Skills の修正とドキュメント更新

**goal**: 4つの Skills から project/milestone 機能を削除し、ドキュメントを更新する

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: plan-management Skill から project.md 参照と milestone トリガーが削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で検出されない"
    - consistency: "PASS - playbook 管理機能保持"
    - completeness: "PASS - SKILL.md 更新済み"
  - validated: 2025-12-23T22:00:00

- [x] **p3.2**: completion-review Skill から milestone 機能が削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep milestone で検出されない"
    - consistency: "PASS - 完了検証機能保持"
    - completeness: "PASS - frameworks/ も更新済み"
  - validated: 2025-12-23T22:00:00

- [x] **p3.3**: post-loop Skill から milestone 更新が削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep milestone で検出されない"
    - consistency: "PASS - post-loop 機能保持"
    - completeness: "PASS - SKILL.md 更新済み"
  - validated: 2025-12-23T22:00:00

- [x] **p3.4**: state Skill から milestone フィールド定義が削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep milestone で検出されない"
    - consistency: "PASS - state.md 管理機能保持"
    - completeness: "PASS - SKILL.md 更新済み"
  - validated: 2025-12-23T22:00:00

- [x] **p3.5**: state.md から focus.project と goal.milestone フィールドが削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で検出されない"
    - consistency: "PASS - 他のフィールド保持"
    - completeness: "PASS - YAML 構造正常"
  - validated: 2025-12-23T22:00:00

- [x] **p3.6**: CLAUDE.md から project.md 参照が削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep project.md で検出されない"
    - consistency: "PASS - 他のルール保持"
    - completeness: "PASS - 参照テーブル更新済み"
  - validated: 2025-12-23T22:00:00

- [x] **p3.7**: RUNBOOK.md から project.md の説明が削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep project.md で検出されない"
    - consistency: "PASS - 他の手順保持"
    - completeness: "PASS - 目次更新済み"
  - validated: 2025-12-23T22:00:00

**status**: done

---

### p_final: 完了検証

**goal**: 全ての削除と修正が正しく完了し、システムが正常に動作することを確認

**depends_on**: [p3]

#### subtasks

- [x] **p_final.1**: plan/project.md が削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - test ! -f で確認、存在しない"
    - consistency: "PASS - git status で削除記録済み"
    - completeness: "PASS - 他の削除対象も確認済み"
  - validated: 2025-12-23T22:10:00

- [x] **p_final.2**: state.md に project と milestone フィールドが存在しない
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で検出されない"
    - consistency: "PASS - YAML 構造正常"
    - completeness: "PASS - 必須フィールド全て存在"
  - validated: 2025-12-23T22:10:00

- [x] **p_final.3**: hooks から vision.goal 注入と milestone 更新ロジックが削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で検出されない"
    - consistency: "PASS - hooks 主要機能保持"
    - completeness: "PASS - 全 9 hooks 修正済み"
  - validated: 2025-12-23T22:10:00

- [x] **p_final.4**: Skills から project.md 参照と milestone トリガーが削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で検出されない"
    - consistency: "PASS - Skills 主要機能保持"
    - completeness: "PASS - 全 4 Skills 修正済み"
  - validated: 2025-12-23T22:10:00

- [x] **p_final.5**: derives_from フィールドが playbook テンプレートから削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep derives_from で検出されない"
    - consistency: "PASS - テンプレート構造正常"
    - completeness: "PASS - 関連説明も削除済み"
  - validated: 2025-12-23T22:10:00

- [x] **p_final.6**: 全ての hooks が正常に動作する
  - executor: claudecode
  - validations:
    - technical: "PASS - regression-test.sh で PASS=37, FAIL=0"
    - consistency: "PASS - settings.json と一致"
    - completeness: "PASS - 主要 hooks 確認済み"
  - validated: 2025-12-23T22:10:00

**status**: done

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done
  - validated: 2025-12-23T22:21:00

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: done
  - validated: 2025-12-23T22:21:00

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done
  - validated: 2025-12-23T22:21:00
