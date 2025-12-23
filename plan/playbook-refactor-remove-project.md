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

- [ ] **p1.1**: plan/project.md が削除されている
  - executor: claudecode
  - validations:
    - technical: "test ! -f plan/project.md で存在しないことを確認"
    - consistency: "他のファイルが project.md を参照していない"
    - completeness: "削除のみで他の修正は行わない"

- [ ] **p1.2**: .claude/schema/project-schema.md が削除されている
  - executor: claudecode
  - validations:
    - technical: "test ! -f .claude/schema/project-schema.md で存在しないことを確認"
    - consistency: "schema を参照している箇所がない"
    - completeness: "削除のみで他の修正は行わない"

- [ ] **p1.3**: .claude/skills/completion-review/hooks/milestone-impact-analyzer.sh が削除されている
  - executor: claudecode
  - validations:
    - technical: "test ! -f .claude/skills/completion-review/hooks/milestone-impact-analyzer.sh で存在しないことを確認"
    - consistency: "settings.json に登録されていない"
    - completeness: "削除のみで他の修正は行わない"

- [ ] **p1.4**: plan/template/playbook-format.md から derives_from フィールドが削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -q derives_from plan/template/playbook-format.md で検出されない"
    - consistency: "meta セクションの説明も更新されている"
    - completeness: "playbook 導出ガイドセクションも修正されている"

- [ ] **p1.5**: plan/template/state-initial.md から milestone フィールドが削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -q milestone plan/template/state-initial.md で検出されない"
    - consistency: "goal セクションの構造が正しい"
    - completeness: "他のフィールドは保持されている"

**status**: pending

---

### p2: Hooks の修正

**goal**: 9つの hooks から vision.goal 注入、milestone 更新、project.md 参照を削除する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: prompt-guard.sh から vision.goal 注入が削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -q 'vision.goal' .claude/hooks/prompt-guard.sh で検出されない"
    - consistency: "他の注入ロジックは保持されている"
    - completeness: "動作確認用の bash -n でシンタックスエラーがない"

- [ ] **p2.2**: pre-compact.sh から vision.goal 保護が削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -q 'vision.goal' .claude/hooks/pre-compact.sh で検出されない"
    - consistency: "他の保護ロジックは保持されている"
    - completeness: "bash -n でシンタックスエラーがない"

- [ ] **p2.3**: archive-playbook.sh から milestone 更新ロジックが削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -q milestone .claude/hooks/archive-playbook.sh で検出されない"
    - consistency: "アーカイブの主要機能は保持されている"
    - completeness: "bash -n でシンタックスエラーがない"

- [ ] **p2.4**: cleanup-hook.sh から milestone 進捗表示が削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -q milestone .claude/hooks/cleanup-hook.sh で検出されない"
    - consistency: "cleanup ロジックは保持されている"
    - completeness: "bash -n でシンタックスエラーがない"

- [ ] **p2.5**: init-guard.sh から project.md 必須チェックが削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -q project.md .claude/hooks/init-guard.sh で検出されない"
    - consistency: "他の必須ファイルチェックは保持されている"
    - completeness: "bash -n でシンタックスエラーがない"

- [ ] **p2.6**: system-health-check.sh から milestone 整合性チェックが削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -q milestone .claude/hooks/system-health-check.sh で検出されない"
    - consistency: "他のヘルスチェックは保持されている"
    - completeness: "bash -n でシンタックスエラーがない"

- [ ] **p2.7**: check-integrity.sh から milestone チェックが削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -q milestone .claude/hooks/check-integrity.sh で検出されない"
    - consistency: "他の整合性チェックは保持されている"
    - completeness: "bash -n でシンタックスエラーがない"

- [ ] **p2.8**: merge-pr.sh から milestone リセットが削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -q milestone .claude/hooks/merge-pr.sh で検出されない"
    - consistency: "マージの主要機能は保持されている"
    - completeness: "bash -n でシンタックスエラーがない"

- [ ] **p2.9**: scope-guard.sh から project.md 監視が削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -q project.md .claude/hooks/scope-guard.sh で検出されない"
    - consistency: "スコープガードの主要機能は保持されている"
    - completeness: "bash -n でシンタックスエラーがない"

**status**: pending

---

### p3: Skills の修正とドキュメント更新

**goal**: 4つの Skills から project/milestone 機能を削除し、ドキュメントを更新する

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: plan-management Skill から project.md 参照と milestone トリガーが削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -rq 'project.md\\|milestone' .claude/skills/plan-management/ で検出されない"
    - consistency: "playbook 管理機能は保持されている"
    - completeness: "SKILL.md の説明も更新されている"

- [ ] **p3.2**: completion-review Skill から milestone 機能が削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -rq milestone .claude/skills/completion-review/ で検出されない"
    - consistency: "完了検証の主要機能は保持されている"
    - completeness: "frameworks/ 配下のドキュメントも更新されている"

- [ ] **p3.3**: post-loop Skill から milestone 更新が削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -rq milestone .claude/skills/post-loop/ で検出されない"
    - consistency: "post-loop の主要機能は保持されている"
    - completeness: "SKILL.md の説明も更新されている"

- [ ] **p3.4**: state Skill から milestone フィールド定義が削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -rq milestone .claude/skills/state/ で検出されない"
    - consistency: "state.md 管理の主要機能は保持されている"
    - completeness: "SKILL.md の説明も更新されている"

- [ ] **p3.5**: state.md から focus.project と goal.milestone フィールドが削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -q 'project:\\|milestone:' state.md で検出されない"
    - consistency: "他の state.md フィールドは保持されている"
    - completeness: "YAML 構造が正しい"

- [ ] **p3.6**: CLAUDE.md から project.md 参照が削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -q project.md CLAUDE.md で検出されない"
    - consistency: "他のルールは保持されている"
    - completeness: "参照テーブルが更新されている"

- [ ] **p3.7**: RUNBOOK.md から project.md の説明が削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -q project.md RUNBOOK.md で検出されない"
    - consistency: "他の手順は保持されている"
    - completeness: "目次が更新されている"

**status**: pending

---

### p_final: 完了検証

**goal**: 全ての削除と修正が正しく完了し、システムが正常に動作することを確認

**depends_on**: [p3]

#### subtasks

- [ ] **p_final.1**: plan/project.md が削除されている
  - executor: claudecode
  - validations:
    - technical: "test ! -f plan/project.md で存在しないことを確認"
    - consistency: "git status で削除が記録されている"
    - completeness: "他の削除対象ファイルも確認"

- [ ] **p_final.2**: state.md に project と milestone フィールドが存在しない
  - executor: claudecode
  - validations:
    - technical: "grep -q 'project:\\|milestone:' state.md で検出されない"
    - consistency: "state.md の YAML 構造が正しい"
    - completeness: "他の必須フィールドは全て存在する"

- [ ] **p_final.3**: hooks から vision.goal 注入と milestone 更新ロジックが削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -r 'vision.goal\\|milestone' .claude/hooks/ --include='*.sh' | grep -v 'Binary\\|archive/' で検出されない"
    - consistency: "hooks の主要機能が保持されている"
    - completeness: "全 9 つの hooks が修正されている"

- [ ] **p_final.4**: Skills から project.md 参照と milestone トリガーが削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -r 'project.md\\|milestone' .claude/skills/ --include='*.md' --include='*.sh' | grep -v archive で検出されない"
    - consistency: "Skills の主要機能が保持されている"
    - completeness: "全 4 つの Skills が修正されている"

- [ ] **p_final.5**: derives_from フィールドが playbook テンプレートから削除されている
  - executor: claudecode
  - validations:
    - technical: "grep -q derives_from plan/template/playbook-format.md で検出されない"
    - consistency: "テンプレートの構造が正しい"
    - completeness: "関連する説明も全て削除されている"

- [ ] **p_final.6**: 全ての hooks が正常に動作する
  - executor: claudecode
  - validations:
    - technical: "find .claude/hooks -name '*.sh' -exec bash -n {} \\; でシンタックスエラーがない"
    - consistency: "hooks の登録が settings.json と一致"
    - completeness: "主要な hooks を実際に実行して確認"

**status**: pending

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
