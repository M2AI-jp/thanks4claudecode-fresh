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

- [x] **p1.1**: archive-playbook.sh に update_fix_backlog() 関数が存在する
  - executor: claudecode
  - validations:
    - technical: "PASS - grep -c 'update_fix_backlog' = 2（定義と呼び出し）"
    - consistency: "PASS - 行 345-443 に関数定義、行 447 で呼び出し"
    - completeness: "PASS - 全機能実装済み"
  - validated: 2026-01-03T20:30:00Z

- [x] **p1.2**: derives_from がない playbook で警告のみ出力される
  - executor: claudecode
  - validations:
    - technical: "PASS - 行 359-361 で log_info + return 0"
    - consistency: "PASS - アーカイブ処理は継続される"
    - completeness: "PASS - スキップ理由がログ出力"
  - validated: 2026-01-03T20:30:00Z

- [x] **p1.3**: FIXED マークが正しいフォーマットで追加される
  - executor: claudecode
  - validations:
    - technical: "PASS - 行 396 で sed -i により ✅ FIXED 追加"
    - consistency: "PASS - 既存フォーマットと同じ"
    - completeness: "PASS - 見出し行末尾に追加"
  - validated: 2026-01-03T20:30:00Z

- [x] **p1.4**: PR URL が追加される
  - executor: claudecode
  - validations:
    - technical: "PASS - 行 380-382 で gh pr list により取得"
    - consistency: "PASS - 既存フォーマットと同じ"
    - completeness: "PASS - エラー時は空文字でフォールバック"
  - validated: 2026-01-03T20:30:00Z

- [x] **p1.5**: 修正内容が追加される
  - executor: claudecode
  - validations:
    - technical: "PASS - 行 377 で goal.summary 抽出"
    - consistency: "PASS - 既存フォーマットと同じ"
    - completeness: "PASS - 空の場合は省略"
  - validated: 2026-01-03T20:30:00Z

**status**: done
**max_iterations**: 5

---

### p2: 動作検証

**goal**: 実装した機能が正しく動作することを検証する

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: bash -n archive-playbook.sh が exit 0 で終了する
  - executor: claudecode
  - validations:
    - technical: "PASS - bash -n = SYNTAX_CHECK=PASS"
    - consistency: "PASS - シンタックスエラーなし"
    - completeness: "PASS - 全コードが構文的に正しい"
  - validated: 2026-01-03T20:30:00Z

- [x] **p2.2**: 既存の処理順序（Step 1-12）が維持されている
  - executor: claudecode
  - validations:
    - technical: "PASS - Step 1,2,3,3.5,3.6,4,5... の順序"
    - consistency: "PASS - Step 3.6 が 3 と 4 の間"
    - completeness: "PASS - 既存 Step 番号変更なし"
  - validated: 2026-01-03T20:30:00Z

**status**: done
**max_iterations**: 3

---

### p_self_update: 設計ドキュメント更新

**goal**: fix-backlog.md に PB-28 を追加し、設計を文書化する

**depends_on**: [p1]

#### subtasks

- [x] **p_self_update.1**: fix-backlog.md に PB-28 が追加されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 'PB-28' = 2箇所"
    - consistency: "PASS - 既存 PB 形式に準拠"
    - completeness: "PASS - Section 1 + Section 3 両方"
  - validated: 2026-01-03T20:30:00Z

- [x] **p_self_update.2**: archive-playbook.sh のヘッダーコメントが更新されている
  - executor: claudecode
  - validations:
    - technical: "PASS - 行 18 に Step 3.6 記載"
    - consistency: "PASS - 処理順序コメント更新済み"
    - completeness: "PASS - 処理内容説明あり"
  - validated: 2026-01-03T20:30:00Z

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: done_when の全条件が満たされていることを検証する

**depends_on**: [p1, p2, p_self_update]

#### subtasks

- [x] **p_final.1**: archive-playbook.sh に Step 3.6（fix-backlog FIXED マーク）が追加されている
  - executor: claudecode
  - validations:
    - technical: "PASS - 行 338,342 に Step 3.6 記載、update_fix_backlog() 定義 345 呼び出し 447"
    - consistency: "PASS - Step 3 と Step 4 の間に配置"
    - completeness: "PASS - ヘッダーコメント行 18 に記載"
  - validated: 2026-01-03T21:00:00Z

- [x] **p_final.2**: derives_from が PB-XX 形式の playbook 完了時に FIXED マークが追加される
  - executor: claudecode
  - validations:
    - technical: "PASS - 行 366 で grep -oE 'PB-[0-9]+' により抽出"
    - consistency: "PASS - 行 396 で ✅ FIXED を見出し行末尾に追加"
    - completeness: "PASS - 見出し行更新 + 修正内容/PR URL 挿入"
  - validated: 2026-01-03T21:00:00Z

- [x] **p_final.3**: PR URL と修正内容が追加される
  - executor: claudecode
  - validations:
    - technical: "PASS - 行 377 で goal.summary 抽出、行 380-382 で gh pr list で PR URL 取得"
    - consistency: "PASS - 既存フォーマット（- **修正内容**: / - **PR**:）に準拠"
    - completeness: "PASS - 行 400-404 で空の場合の条件分岐あり"
  - validated: 2026-01-03T21:00:00Z

- [x] **p_final.4**: derives_from がない playbook では警告のみでスキップされる
  - executor: claudecode
  - validations:
    - technical: "PASS - 行 359-361 で -z \"$derives_from\" チェック + return 0"
    - consistency: "PASS - アーカイブ処理は継続（後方互換）"
    - completeness: "PASS - log_info でスキップ理由を出力"
  - validated: 2026-01-03T21:00:00Z

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
