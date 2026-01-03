# playbook-pb28-archive-fix-backlog-auto-mark.md

> **archive-playbook.sh に fix-backlog.md の自動 FIXED マーク機能を追加**

---

## meta

```yaml
project: pb28-archive-fix-backlog-auto-mark
branch: feat/pb28-archive-fix-backlog-auto-mark
created: 2026-01-03
issue: null
reviewed: false
derives_from: docs/fix-backlog.md#PB-28
```

---

## goal

```yaml
summary: archive-playbook.sh に playbook 完了時の fix-backlog.md 自動 FIXED マーク機能を追加する
done_when:
  - archive-playbook.sh に Step 3.6（fix-backlog FIXED マーク）が追加されている
  - meta.derives_from が PB-XX 形式の playbook 完了時に、fix-backlog.md の該当行に FIXED マークが追加される
  - PR URL が取得できた場合は PR URL も追加される
  - 修正内容が playbook の goal.summary から抽出され追記される
  - derives_from がない playbook では警告のみでスキップされる
```

---

## context

```yaml
5w1h:
  who: archive-playbook.sh（自動実行）
  what: fix-backlog.md の対応 PB を自動 FIXED マークする機能を追加
  when: playbook 完了時（Step 3 PR 作成後、Step 4 アーカイブ前）
  where: .claude/skills/playbook-gate/workflow/archive-playbook.sh
  why: 現状は archive 後に playbook=null になり、fix-backlog.md 編集がブロックされる設計上の不具合がある
  how: playbook の meta.derives_from から PB-XX を抽出し、fix-backlog.md を更新

analysis_result:
  source: user-provided
  timestamp: 2026-01-03T00:00:00Z
  data:
    problem: |
      archive-playbook.sh の Step 7 で playbook.active = null になる。
      その後の fix-backlog.md 編集は playbook ガードによりブロックされる。
      結果として、PB-XX の FIXED マークを自動化できない。
    solution: |
      Step 3（PR 作成）後、Step 4（アーカイブ）前に fix-backlog.md を更新する。
      この時点では playbook.active がまだ有効なため、編集がブロックされない。
    risks:
      - playbook に derives_from がない場合の後方互換性
      - fix-backlog.md のフォーマット変更時の対応
      - PR URL 取得失敗時の処理

translated_requirements:
  source: user-provided
  timestamp: 2026-01-03T00:00:00Z
  data:
    original_terms:
      - original: "FIXED マーク"
        translated: "見出し行末に ✅ FIXED を追加"
        rationale: "fix-backlog.md の既存フォーマットに準拠"
      - original: "PR URL 追加"
        translated: "該当 PB セクションに - **PR**: {URL} 行を追加"
        rationale: "fix-backlog.md の既存フォーマット（PB-27 参照）に準拠"
      - original: "修正内容追加"
        translated: "該当 PB セクションに - **修正内容**: {goal.summary} 行を追加"
        rationale: "fix-backlog.md の既存フォーマット（PB-01 参照）に準拠"
```

---

## phases

### p1: fix-backlog 更新機能の実装

**goal**: archive-playbook.sh に fix-backlog.md 自動更新機能を追加する

#### subtasks

- [ ] **p1.1**: archive-playbook.sh に update_fix_backlog() 関数が存在する
  - executor: claudecode
  - validations:
    - technical: "grep -c 'update_fix_backlog' archive-playbook.sh で関数存在を確認"
    - consistency: "関数が Step 3.6 として適切な位置に配置されている"
    - completeness: "derives_from 抽出、FIXED マーク、PR URL 追加、修正内容追加の全機能が含まれる"

- [ ] **p1.2**: derives_from がない playbook で警告のみ出力される
  - executor: claudecode
  - validations:
    - technical: "derives_from なしの playbook でログに [WARN] または [INFO] が出力される"
    - consistency: "exit 0 で正常終了し、アーカイブ処理は継続される"
    - completeness: "スキップ理由が明確にログ出力される"

- [ ] **p1.3**: FIXED マークが正しいフォーマットで追加される
  - executor: claudecode
  - validations:
    - technical: "更新後の fix-backlog.md に ✅ FIXED が含まれる"
    - consistency: "既存の FIXED マーク（PB-01, PB-07 等）と同じフォーマット"
    - completeness: "見出し行（#### PB-XX:）の末尾に追加される"

- [ ] **p1.4**: PR URL が追加される
  - executor: claudecode
  - validations:
    - technical: "更新後の fix-backlog.md に - **PR**: https://... が含まれる"
    - consistency: "既存の PR URL 記載（PB-27 参照）と同じフォーマット"
    - completeness: "PR URL 取得失敗時は FIXED マークのみ追加される"

- [ ] **p1.5**: 修正内容が追加される
  - executor: claudecode
  - validations:
    - technical: "更新後の fix-backlog.md に - **修正内容**: ... が含まれる"
    - consistency: "playbook の goal.summary から抽出した内容が記載される"
    - completeness: "goal.summary が取得できない場合は省略される"

**status**: pending
**max_iterations**: 5

---

### p2: 動作検証

**goal**: 実装した機能が正しく動作することを検証する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: bash -n archive-playbook.sh が exit 0 で終了する
  - executor: claudecode
  - validations:
    - technical: "bash -n archive-playbook.sh && echo PASS"
    - consistency: "シンタックスエラーがない"
    - completeness: "全ての新規追加コードが構文的に正しい"

- [ ] **p2.2**: 既存の処理順序（Step 1-12）が維持されている
  - executor: claudecode
  - validations:
    - technical: "grep -E 'Step [0-9]+' archive-playbook.sh で順序確認"
    - consistency: "新規 Step 3.6 が Step 3 と Step 4 の間に配置"
    - completeness: "既存の Step 番号が変更されていない"

**status**: pending
**max_iterations**: 3

---

### p_self_update: 設計ドキュメント更新

**goal**: fix-backlog.md に PB-28 を追加し、設計を文書化する

**depends_on**: [p1]

#### subtasks

- [ ] **p_self_update.1**: fix-backlog.md に PB-28 が追加されている
  - executor: claudecode
  - validations:
    - technical: "grep -c 'PB-28' docs/fix-backlog.md で存在確認"
    - consistency: "既存の PB 形式（概要、Scope、Done when、Validation）に準拠"
    - completeness: "Section 1 と Section 3 の両方に追加"

- [ ] **p_self_update.2**: archive-playbook.sh のヘッダーコメントが更新されている
  - executor: claudecode
  - validations:
    - technical: "grep -c 'fix-backlog' archive-playbook.sh で確認"
    - consistency: "処理順序のコメントに Step 3.6 が追加"
    - completeness: "処理内容の説明が含まれる"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: done_when の全条件が満たされていることを検証する

**depends_on**: [p1, p2, p_self_update]

#### subtasks

- [ ] **p_final.1**: archive-playbook.sh に Step 3.6（fix-backlog FIXED マーク）が追加されている
  - executor: claudecode
  - validations:
    - technical: "grep -c 'Step 3.6' archive-playbook.sh で確認"
    - consistency: "update_fix_backlog() 関数が Step 3.6 で呼び出される"
    - completeness: "ヘッダーコメントにも Step 3.6 が記載"

- [ ] **p_final.2**: derives_from が PB-XX 形式の playbook 完了時に FIXED マークが追加される
  - executor: claudecode
  - validations:
    - technical: "update_fix_backlog() が PB-XX パターンを正しく抽出する"
    - consistency: "✅ FIXED フォーマットが既存と一致"
    - completeness: "見出し行と Status 行の両方が更新される"

- [ ] **p_final.3**: PR URL と修正内容が追加される
  - executor: claudecode
  - validations:
    - technical: "PR URL と修正内容の追加ロジックが存在する"
    - consistency: "既存の fix-backlog.md フォーマットに準拠"
    - completeness: "取得失敗時のフォールバック処理がある"

- [ ] **p_final.4**: derives_from がない playbook では警告のみでスキップされる
  - executor: claudecode
  - validations:
    - technical: "derives_from なしケースの条件分岐が存在する"
    - consistency: "後方互換性が維持される"
    - completeness: "スキップ時のログ出力がある"

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
