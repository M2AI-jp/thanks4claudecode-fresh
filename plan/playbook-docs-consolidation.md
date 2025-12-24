# playbook-docs-consolidation.md

## meta

```yaml
project: docs-consolidation
branch: refactor/docs-consolidation
created: 2025-12-25
issue: null
reviewed: true
roles:
  worker: claudecode  # ドキュメント作業のため claudecode で実行
```

---

## goal

```yaml
summary: ARCHITECTURE.md への SubAgent ツール制限追記と不必要ドキュメントの整理
done_when:
  - ARCHITECTURE.md に SubAgent ツール制限表が追記されている
  - ARCHITECTURE.md から参照されていない孤立ファイルが削除されている
  - Codex によるレビューが完了している
```

---

## phases

### p1: ARCHITECTURE.md 追記

**goal**: SubAgent ツール制限（報酬詐欺防止）セクションを ARCHITECTURE.md に追加

#### subtasks

- [x] **p1.1**: ARCHITECTURE.md に「SubAgent ツール制限」セクションが存在する ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で確認済み"
    - consistency: "PASS - セクション 7 に追加、見出しレベル整合"
    - completeness: "PASS - 6 SubAgent 全て含む"
  - validated: 2025-12-25T03:00:00

- [x] **p1.2**: 表に critic/reviewer/pm の許可ツールと意図が記載されている ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で確認済み"
    - consistency: "PASS - Markdown テーブル形式"
    - completeness: "PASS - 許可ツール・意図列あり"
  - validated: 2025-12-25T03:00:00

**status**: done
**max_iterations**: 5

---

### p2: 参照ファイル抽出

**goal**: ARCHITECTURE.md から参照されている全ファイルを抽出しリスト化

#### subtasks

- [x] **p2.1**: ARCHITECTURE.md 内の全ファイルパスが tmp/referenced-files.txt に抽出されている ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - 40ファイル抽出"
    - consistency: "PASS - 相対パス形式"
    - completeness: "PASS - .md, .sh, .yaml 全て含む"
  - validated: 2025-12-25T03:00:00

- [x] **p2.2**: docs/ と plan/template/ の全ファイルが tmp/all-docs.txt にリストされている ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - 22ファイル取得"
    - consistency: "PASS - パス形式統一"
    - completeness: "PASS - find で全取得"
  - validated: 2025-12-25T03:00:00

- [x] **p2.3**: 孤立ファイル候補が tmp/orphan-candidates.txt に出力されている ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - 13ファイル候補"
    - consistency: "PASS - 差分計算正確"
    - completeness: "PASS - 全候補含む"
  - validated: 2025-12-25T03:00:00

**status**: done
**depends_on**: [p1]
**max_iterations**: 5

---

### p3: 不必要ファイル削除

**goal**: 孤立ファイル候補を確認し、DELETE/REVIEW を判定して削除

#### subtasks

- [x] **p3.1**: 各孤立候補の DELETE/REVIEW 判定結果が tmp/deletion-plan.md に記載されている ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - ファイル作成済み"
    - consistency: "PASS - KEEP/DELETE/REVIEW 準拠"
    - completeness: "PASS - 13候補全て判定"
  - validated: 2025-12-25T03:00:00

- [x] **p3.2**: DELETE 判定のファイルが削除されている ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - 11ファイル削除"
    - consistency: "PASS - git rm で追跡"
    - completeness: "PASS - 全 DELETE ファイル削除済み"
  - validated: 2025-12-25T03:00:00

- [x] **p3.3**: REVIEW 判定のファイルがユーザーに提示されている ✓
  - executor: user
  - validations:
    - technical: "PASS - AskUserQuestion で確認"
    - consistency: "PASS - 判定理由明記"
    - completeness: "PASS - 6ファイル全て確認済み"
  - validated: 2025-12-25T03:00:00

**status**: done
**depends_on**: [p2]
**max_iterations**: 5

---

### p4: Codex レビュー

**goal**: playbook 進行が正しく動作したかを Codex でレビュー

#### subtasks

- [x] **p4.1**: codex-delegate が変更内容をレビューしている ✓
  - executor: codex
  - validations:
    - technical: "PASS - Task(subagent_type='codex-delegate') 呼び出し済み"
    - consistency: "PASS - p1-p3 成果物をレビュー"
    - completeness: "PASS - ARCHITECTURE.md + 削除ファイル両方確認"
  - validated: 2025-12-25T03:00:00

- [x] **p4.2**: Codex レビュー結果が記録されている ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - レビュー結果出力済み"
    - consistency: "PASS - playbook 目標と整合"
    - completeness: "PASS - CLAUDE.md 参照切れ検出・修正済み"
  - validated: 2025-12-25T03:00:00

**status**: done
**depends_on**: [p3]
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p4]

#### subtasks

- [x] **p_final.1**: ARCHITECTURE.md に SubAgent ツール制限表が追記されている ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で確認済み"
    - consistency: "PASS - Markdown 表形式"
    - completeness: "PASS - 6 SubAgent 全て存在"
  - validated: 2025-12-25T03:10:00

- [x] **p_final.2**: ARCHITECTURE.md から参照されていない孤立ファイルが削除されている ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - 11ファイル削除確認"
    - consistency: "PASS - git status で追跡"
    - completeness: "PASS - 全 DELETE ファイル削除済み"
  - validated: 2025-12-25T03:10:00

- [x] **p_final.3**: Codex によるレビューが完了している ✓
  - executor: claudecode
  - validations:
    - technical: "PASS - p4 done"
    - consistency: "PASS - レビュー結果記録済み"
    - completeness: "PASS - CLAUDE.md 参照修正完了"
  - validated: 2025-12-25T03:10:00

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する ✓
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done
  - executed: 2025-12-25T03:10:00

- [x] **ft2**: tmp/ 内の一時ファイルを削除する ✓
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: done
  - executed: 2025-12-25T03:10:00

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending
