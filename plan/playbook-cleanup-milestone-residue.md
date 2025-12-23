# playbook-cleanup-milestone-residue.md

> **project.md/milestone 機能削除後の残存コードをクリーンアップ**

---

## meta

```yaml
branch: refactor/cleanup-milestone-residue
created: 2025-12-23
reviewed: true
```

---

## goal

```yaml
summary: lib/common.sh の未使用 milestone 関数と generate-repository-map.sh のハードコード参照を削除
done_when:
  - lib/common.sh から get_current_milestone() と get_roadmap_milestone() が削除されている
  - generate-repository-map.sh から milestone/project.md へのハードコード参照が削除されている
  - bash -n で全対象ファイルの構文チェックが PASS
  - 既存の hook テストが PASS

rollback_plan:
  - git revert で変更を取り消し
  - 削除した関数は git show HEAD~1:path で復元可能
```

---

## phases

### p0: 使用状況の検証

**goal**: 削除対象の関数と参照が実際に未使用であることを確認する

#### subtasks

- [x] **p0.1**: get_current_milestone の呼び出し箇所が存在しないことを確認（定義のみ許容）
  - executor: claudecode
  - verification: `grep -r "get_current_milestone" .claude/hooks/ --include="*.sh" | grep -v "^.*:.*get_current_milestone()" | wc -l` が 0
  - validations:
    - technical: "PASS - 定義行のみ検出、呼び出し箇所なし"
    - consistency: "PASS - 他ファイルからの参照なし"
    - completeness: "PASS - 全 hooks 検索済み"
  - validated: 2025-12-23T22:40:00

- [x] **p0.2**: get_roadmap_milestone の呼び出し箇所が存在しないことを確認（定義のみ許容）
  - executor: claudecode
  - verification: `grep -r "get_roadmap_milestone" .claude/hooks/ --include="*.sh" | grep -v "^.*:.*get_roadmap_milestone()" | wc -l` が 0
  - validations:
    - technical: "PASS - 定義行のみ検出、呼び出し箇所なし"
    - consistency: "PASS - 他ファイルからの参照なし"
    - completeness: "PASS - 全 hooks 検索済み"
  - validated: 2025-12-23T22:40:00

- [x] **p0.3**: plan/project.md が存在しないことを確認
  - executor: claudecode
  - verification: `test ! -f plan/project.md`
  - validations:
    - technical: "PASS - ファイル存在しない"
    - consistency: "PASS - 前回 playbook で削除済み"
    - completeness: "PASS - 確認完了"
  - validated: 2025-12-23T22:40:00

**status**: done

---

### p1: lib/common.sh のクリーンアップ

**goal**: 未使用の milestone 関連関数を削除する

**depends_on**: [p0]

#### subtasks

- [x] **p1.1**: get_current_milestone() 関数が削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - 関数定義を削除"
    - consistency: "PASS - p0 で呼び出し箇所なしを確認済み"
    - completeness: "PASS - 関連コメントも削除"
  - validated: 2025-12-23T22:42:00

- [x] **p1.2**: get_roadmap_milestone() 関数が削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - 関数定義を削除"
    - consistency: "PASS - p0 で呼び出し箇所なしを確認済み"
    - completeness: "PASS - 関連コメントも削除"
  - validated: 2025-12-23T22:42:00

- [x] **p1.3**: bash -n .claude/hooks/lib/common.sh が PASS
  - executor: claudecode
  - validations:
    - technical: "PASS - bash -n 構文チェック OK"
    - consistency: "PASS - 他の関数に影響なし"
    - completeness: "PASS - 全構文検証済み"
  - validated: 2025-12-23T22:42:00

**status**: done

---

### p2: generate-repository-map.sh のクリーンアップ

**goal**: ハードコードされた milestone/project.md 参照を削除する（存在しないファイルへの参照のため）

**depends_on**: [p1]

**decision_rationale**: project.md は削除済みのため、参照は「更新」ではなく「削除」する

#### subtasks

- [x] **p2.1**: "project.md" へのハードコード参照が削除されている
  - executor: claudecode
  - scope: workflow/コンテキスト説明文から project.md への言及を削除
  - validations:
    - technical: "PASS - init_flow, post_loop, merge_flow から削除"
    - consistency: "PASS - playbook ベースの説明に統一"
    - completeness: "PASS - 全参照を更新"
  - validated: 2025-12-23T22:50:00

- [x] **p2.2**: "milestone" へのハードコード参照が削除されている
  - executor: claudecode
  - scope: workflow 説明文から milestone への言及を削除（playbook ベースの説明に置換）
  - validations:
    - technical: "PASS - PROJECT_COMPLETE を MERGE に置換"
    - consistency: "PASS - pdca_autonomy から milestone 削除"
    - completeness: "PASS - 全参照を更新"
  - validated: 2025-12-23T22:50:00

- [x] **p2.3**: bash -n .claude/hooks/generate-repository-map.sh が PASS
  - executor: claudecode
  - validations:
    - technical: "PASS - bash -n 構文チェック OK"
    - consistency: "PASS - YAML 生成ロジック正常"
    - completeness: "PASS - 全構文検証済み"
  - validated: 2025-12-23T22:50:00

- [x] **p2.4**: repository-map.yaml を再生成し、project.md/milestone への参照がないことを確認
  - executor: claudecode
  - verification: `grep -E "project\.md|milestone" docs/repository-map.yaml | wc -l` が 0
  - validations:
    - technical: "PASS - grep 結果 0 件"
    - consistency: "PASS - 309 ファイル正常生成"
    - completeness: "PASS - 全参照削除確認"
  - validated: 2025-12-23T22:50:00

**status**: done

---

### p_final: 検証

**goal**: 全ての変更が正しく完了し、既存機能に影響がないことを確認

**depends_on**: [p2]

#### subtasks

- [ ] **p_final.1**: regression-test.sh が PASS
  - executor: claudecode

- [ ] **p_final.2**: regression-test.sh PASS 後に変更がコミットされている
  - executor: claudecode
  - precondition: p_final.1 が PASS であること

**status**: pending

---

## changelog

| 日時 | 内容 |
|------|------|
| 2025-12-23 | 初版作成 |
| 2025-12-23 | レビュー指摘反映: p0 追加、rollback_plan 追加、スコープ明確化 |
