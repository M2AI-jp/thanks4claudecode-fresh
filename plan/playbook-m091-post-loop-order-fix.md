# playbook-m091-post-loop-order-fix.md

> **POST_LOOP 処理順序修正 - milestone 更新を playbook アーカイブ前に移動**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/understanding-check-reimpl
created: 2025-12-23
issue: null
derives_from: M091
reviewed: false
```

---

## goal

```yaml
summary: POST_LOOP の処理順序を修正し、playbook-guard によるブロックを回避する
done_when:
  - post-loop/SKILL.md の step 3（project.milestone 更新）が step 0.5（アーカイブ）の前に移動している
  - ステップ番号が適切にリナンバリングされている
  - 変更理由がコメントとして記載されている
```

---

## phases

### p1: SKILL.md の処理順序修正

**goal**: post-loop/SKILL.md の行動セクションで処理順序を修正する

#### subtasks

- [ ] **p1.1**: step 3（project.milestone 更新）が step 0.5（アーカイブ）の前に移動している
  - executor: claudecode
  - validations:
    - technical: "grep -n 'project.milestone' と grep -n 'アーカイブ' の行番号を比較し、milestone が先にある"
    - consistency: "依存関係が正しい（milestone 更新は playbook.active が存在する間に実行）"
    - completeness: "step 3 の全内容が移動されている"

- [ ] **p1.2**: ステップ番号が 0, 1, 2, 3, 4, 5, 6 の連番にリナンバリングされている
  - executor: claudecode
  - validations:
    - technical: "grep でステップ番号を確認し、連番であることを確認"
    - consistency: "行動セクション内のステップ参照が更新されている"
    - completeness: "全ステップがリナンバリングされている"

- [ ] **p1.3**: 変更理由がコメント（YAML コメントまたは注記）として記載されている
  - executor: claudecode
  - validations:
    - technical: "grep で変更理由のコメントが存在することを確認"
    - consistency: "コメントが変更箇所の近くに配置されている"
    - completeness: "変更理由が明確に説明されている"

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: done_when が全て満たされているか最終検証

**depends_on**: [p1]

#### subtasks

- [ ] **p_final.1**: step 3（project.milestone 更新）が step 0.5（アーカイブ）の前に移動している
  - executor: claudecode
  - validations:
    - technical: "SKILL.md を読み、milestone 更新の記述がアーカイブの前にあることを確認"
    - consistency: "処理フローが論理的に正しい（playbook.active が有効な間に project.md を更新）"
    - completeness: "milestone 更新の全ステップが含まれている"

- [ ] **p_final.2**: ステップ番号が適切にリナンバリングされている
  - executor: claudecode
  - validations:
    - technical: "SKILL.md のステップ番号が連番（0, 1, 2, ...）であることを確認"
    - consistency: "ステップ間の依存関係が正しい"
    - completeness: "全ステップに番号が付与されている"

- [ ] **p_final.3**: 変更理由がコメントとして記載されている
  - executor: claudecode
  - validations:
    - technical: "SKILL.md に変更理由の記述があることを確認"
    - consistency: "コメントが適切な位置にある"
    - completeness: "理由が理解可能である"

**status**: done
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

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-23 | 初版作成 |
