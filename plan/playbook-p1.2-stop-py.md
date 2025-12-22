# playbook-p1.2-stop-py.md

> **P1.2: stop.py 作成 - 報酬詐欺防止の要**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/p1.2-stop-py
created: 2025-12-23
issue: null
derives_from: P1.2
reviewed: true
roles:
  worker: codex
```

---

## goal

```yaml
summary: review_pending 時にセッション終了をブロックする stop.py を作成
done_when:
  - ".claude/hooks/stop.py が存在する"
  - "stdin から JSON を受け取れる"
  - "state.md の review_pending フラグを読み取れる"
  - "review_pending: true の場合、decision: block を返す"
  - "review_pending: false の場合、正常終了する"
  - "python3 -m py_compile でエラー 0"
```

---

## phases

### p1: スキーマ準備

**goal**: state.md に review_pending フラグを追加

#### subtasks

- [x] **p1.1**: state.md の playbook セクションに review_pending フィールドが存在する
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "grep 'review_pending:' state.md で存在を確認" → PASS (行 24)
    - consistency: "playbook セクション内の他フィールド（active, branch）と同じ階層" → PASS
    - completeness: "デフォルト値 false が設定されている" → PASS

- [x] **p1.2**: state.md スキーマドキュメント（.claude/skills/state/SKILL.md）が更新されている
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "grep 'review_pending' .claude/skills/state/SKILL.md で存在を確認" → PASS (行 21)
    - consistency: "他フィールドの説明形式と統一" → PASS
    - completeness: "用途と設定タイミングが説明されている" → PASS

**status**: done
**max_iterations**: 5

---

### p2: stop.py 実装

**goal**: session_start.py と同じ構造で stop.py を実装
**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: .claude/hooks/stop.py が存在し、python3 -m py_compile でエラー 0 である
  - executor: worker
  - coding: true
  - validations:
    - technical: "python3 -m py_compile .claude/hooks/stop.py && echo PASS" → PASS
    - consistency: "session_start.py と同じ構造（main, parse_state_md, 等）" → PASS
    - completeness: "shebang, docstring, import, main() が全て存在" → PASS

- [x] **p2.2**: stop.py が stdin から JSON を読み取る機能を持つ
  - executor: worker
  - coding: true
  - validations:
    - technical: "echo '{}' | python3 .claude/hooks/stop.py で exit 0" → PASS
    - consistency: "session_start.py と同じ JSON パース方式（json.loads(sys.stdin.read())）" → PASS
    - completeness: "空入力、不正 JSON でもクラッシュしない" → PASS

- [x] **p2.3**: stop.py が state.md から review_pending フラグを読み取れる
  - executor: worker
  - coding: true
  - validations:
    - technical: "parse_state_md() 関数が playbook.review_pending を返す" → PASS
    - consistency: "extract_yaml_from_section() を使用（session_start.py と共通）" → PASS
    - completeness: "review_pending 未定義時は false として扱う" → PASS

**status**: done
**max_iterations**: 10

---

### p3: ブロックロジック実装

**goal**: review_pending: true 時に decision: block を返す
**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: review_pending: true の場合、decision: block と stopReason を返す
  - executor: worker
  - coding: true
  - validations:
    - technical: "state.md に review_pending: true を設定し stop.py 実行、JSON に decision: block を確認" → PASS
    - consistency: "Claude Code Hook 仕様に準拠（{ continue: false, decision: 'block', stopReason: ... }）" → PASS
    - completeness: "stopReason にレビュー未完了であることを明示" → PASS

- [x] **p3.2**: review_pending: false または未定義の場合、正常終了する
  - executor: worker
  - coding: true
  - validations:
    - technical: "state.md に review_pending: false を設定し stop.py 実行、exit 0 を確認" → PASS
    - consistency: "ブロックしない場合は { continue: true } を返す" → PASS
    - completeness: "review_pending 未定義時も正常終了" → PASS

- [x] **p3.3**: 出力 JSON が Claude Code Hook 仕様に準拠している
  - executor: worker
  - coding: true
  - validations:
    - technical: "stop.py の出力を jq でパースできる" → PASS
    - consistency: "session_start.py と同じ出力形式（JSON 1行）" → PASS
    - completeness: "必須フィールド（continue, decision/stopReason）が全て含まれる" → PASS

**status**: done
**max_iterations**: 10

---

### p4: 統合テスト

**goal**: 全ケースをテストし動作確認
**depends_on**: [p3]

#### subtasks

- [x] **p4.1**: review_pending: true で decision: block が返る
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "一時的に state.md を編集し stop.py 実行、block 確認後に復元" → PASS
    - consistency: "他の Hook と同じテスト手順" → PASS
    - completeness: "stopReason の内容も確認" → PASS

- [x] **p4.2**: review_pending: false で正常終了する
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "review_pending: false で stop.py 実行、continue: true 確認" → PASS
    - consistency: "既存の stop-summary.sh と干渉しない" → PASS
    - completeness: "exit code 0 であること" → PASS

- [x] **p4.3**: review_pending 未定義で正常終了する
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "review_pending 行を削除した状態で stop.py 実行、continue: true 確認" → PASS
    - consistency: "デフォルト動作（ブロックしない）" → PASS
    - completeness: "エラーメッセージが出ない" → PASS

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when の全項目が満たされていることを検証
**depends_on**: [p4]

#### subtasks

- [x] **p_final.1**: .claude/hooks/stop.py が存在する
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "test -f .claude/hooks/stop.py && echo PASS" → PASS
    - consistency: "session_start.py と同じディレクトリ" → PASS
    - completeness: "ファイルが空でない" → PASS (118行)

- [x] **p_final.2**: stdin から JSON を受け取れる
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "echo '{\"trigger\": \"stop\"}' | python3 .claude/hooks/stop.py" → PASS
    - consistency: "session_start.py と同じ入力処理" → PASS
    - completeness: "有効な JSON を返す" → PASS

- [x] **p_final.3**: state.md の review_pending フラグを読み取れる
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "stop.py 内に review_pending を処理するロジックが存在（grep 確認）" → PASS
    - consistency: "parse_state_md() が review_pending を含む dict を返す" → PASS
    - completeness: "true/false/未定義の3パターンを処理" → PASS

- [x] **p_final.4**: review_pending: true の場合、decision: block を返す
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "テストスクリプトで block 出力を確認" → PASS
    - consistency: "Claude Code Hook 仕様準拠" → PASS
    - completeness: "stopReason が含まれる" → PASS

- [x] **p_final.5**: review_pending: false の場合、正常終了する
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "テストスクリプトで continue: true を確認" → PASS
    - consistency: "exit code 0" → PASS
    - completeness: "エラー出力がない" → PASS

- [x] **p_final.6**: python3 -m py_compile でエラー 0
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "python3 -m py_compile .claude/hooks/stop.py && echo PASS" → PASS
    - consistency: "session_start.py と同じ構文チェック方式" → PASS
    - completeness: "警告もない" → PASS

- [x] **p_final.7**: playbook_reviewer による独立検証が PASS
  - executor: playbook_reviewer
  - coding: false
  - validations:
    - technical: "done_when 6項目を独立検証（自分で実行）" → PASS
    - consistency: "edge case 4項目追加テスト" → PASS
    - completeness: "作成者の PASS を鵜呑みにせず独立検証" → PASS

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done (271 files, 31 hooks, 6 agents, 8 skills)

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: skipped (no temp files)
  - status: done

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git commit`
  - status: pending

---

## notes

### 設計方針

1. **session_start.py と同じ構造**:
   - `parse_state_md()` で state.md を解析
   - `main()` で stdin 読み込み + 出力

2. **Claude Code Hook 仕様**:
   - Stop イベントの出力形式は `{ continue: boolean, decision?: string, stopReason?: string }`
   - `decision: 'block'` でセッション終了をブロック

3. **報酬詐欺防止**:
   - レビュー完了前にセッション終了を防ぐ
   - review_pending: true → 終了不可
   - Phase 完了後、critic PASS → review_pending: false に設定

### 参考実装

- `.claude/hooks/session_start.py`: 同じ構造の Python Hook
- `.claude/hooks/stop-summary.sh`: 既存の Stop Hook（サマリー表示）

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-23 | 初版作成 |
