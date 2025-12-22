# playbook-m087-critique-process-verification.md

> **critique_process workflow の E2E 検証・修正**
>
> 「phase 完了申告」イベントは公式 Hook に存在しないため、
> critic-guard.sh が PreToolUse:Edit で検知して Claude にフィードバックする設計を検証・修正する。

---

## meta

```yaml
project: m087-critique-process-verification
branch: feat/m087-critique-process-verification
created: 2025-12-22
issue: null
derives_from: M083-critique-process
reviewed: true
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: critique_process workflow が設計通りに動作することを E2E で検証・修正する
done_when:
  - critic-guard.sh が PreToolUse:Edit で発火している（settings.json に登録済み）
  - playbook の `status: done` への変更を正しく検知する
  - critic 未実行時のブロックが機能する（exit 2 でブロック）
  - critic PASS 後の許可ロジックが動作する（self_complete: true で通過）
```

---

## phases

### p1: 現状分析・発火確認

**goal**: critic-guard.sh が PreToolUse:Edit で正しく発火しているか確認する

#### subtasks

- [ ] **p1.1**: settings.json の PreToolUse:Edit に critic-guard.sh が登録されている
  - executor: claudecode
  - validations:
    - technical: "grep で settings.json 内の critic-guard.sh 登録を確認"
    - consistency: "他の PreToolUse:Edit hooks との順序が適切か確認"
    - completeness: "Edit と Write 両方に登録されているか確認"

- [ ] **p1.2**: critic-guard.sh の構文が正しい（bash -n でエラーなし）
  - executor: claudecode
  - validations:
    - technical: "bash -n .claude/hooks/critic-guard.sh が exit 0"
    - consistency: "他の Hook と同じコーディングスタイルか確認"
    - completeness: "必要な変数・関数が全て定義されているか確認"

- [ ] **p1.3**: 現在の critic-guard.sh が state.md の `state: done` のみを検知対象としている
  - executor: claudecode
  - validations:
    - technical: "grep で検知パターンを確認"
    - consistency: "設計変更方針（playbook の status: done 検知）と整合性があるか確認"
    - completeness: "検知対象の網羅性を確認"

**status**: pending
**max_iterations**: 5

---

### p2: 検知ロジック修正

**goal**: playbook の `status: done` への変更を正しく検知するようにする

**depends_on**: [p1]

**notes**:
- ロールバック方針: `git checkout .claude/hooks/critic-guard.sh` で元に戻せる
- 設計方針: state.md の `self_complete: true` フラグを playbook 完了にも流用する

#### subtasks

- [ ] **p2.1**: critic-guard.sh が playbook ファイル（plan/playbook-*.md）を検知対象に含む
  - executor: claudecode
  - validations:
    - technical: "FILE_PATH のパターンマッチで playbook を検知できることを確認"
    - consistency: "state.md の検知ロジックと整合性があるか確認"
    - completeness: "plan/playbook-*.md のパターンが正確か確認"

- [ ] **p2.2**: `status: done` への変更パターンを正しく検知する
  - executor: claudecode
  - validations:
    - technical: "grep パターン `status:[[:space:]]*done` が動作することを確認"
    - consistency: "YAML 形式の status: done を正しく検知できるか確認"
    - completeness: "in_progress -> done の変更を検知できるか確認"

- [ ] **p2.3**: old_string に `status: pending` または `status: in_progress` が含まれる場合のみブロック
  - executor: claudecode
  - validations:
    - technical: "old_string のパターンマッチが動作することを確認"
    - consistency: "既に done のものを再度 done にする場合は許可する設計と整合"
    - completeness: "全ての状態遷移パターンを考慮"

**status**: pending
**max_iterations**: 5

---

### p3: ブロック・許可ロジック検証

**goal**: critic 未実行時のブロックと PASS 後の許可が正しく動作することを確認する

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: critic 未実行時に exit 2 でブロックされる
  - executor: claudecode
  - validations:
    - technical: "テストケース（critic 未実行）で exit code 2 を確認"
    - consistency: "エラーメッセージが CLAUDE.md の規約と整合しているか確認"
    - completeness: "ブロック時のユーザーガイダンスが含まれているか確認"

- [ ] **p3.2**: critic PASS 後（self_complete: true）に許可される
  - executor: claudecode
  - validations:
    - technical: "テストケース（self_complete: true）で exit code 0 を確認"
    - consistency: "state.md の self_complete フィールドと整合しているか確認"
    - completeness: "許可後の状態遷移が正しいか確認"

- [ ] **p3.3**: state.md の self_complete: true フラグを playbook 完了にも流用する設計が実装されている
  - executor: claudecode
  - validations:
    - technical: "critic-guard.sh が state.md の self_complete を参照していることを確認"
    - consistency: "state.md 用と playbook 用で同じ許可メカニズムを使用していることを確認"
    - completeness: "critic SubAgent が PASS 時に self_complete: true を設定する仕様が明記されているか確認"

**status**: pending
**max_iterations**: 5

---

### p4: E2E テスト実施

**goal**: 修正後の critique_process workflow が実際に動作することを E2E で確認する

**depends_on**: [p3]

**notes**:
- テスト用 playbook は tmp/ に配置（tmp/test-playbook.md）
- テスト完了後に削除（ft2 で自動削除）

#### subtasks

- [ ] **p4.1**: テストシナリオ1: playbook の status: done 変更を critic 未実行でブロック
  - executor: claudecode
  - validations:
    - technical: "tmp/test-playbook.md で status: done 変更を試み、exit 2 でブロックされることを確認"
    - consistency: "エラーメッセージが設計通りか確認"
    - completeness: "Edit と Write 両方でブロックされるか確認"

- [ ] **p4.2**: テストシナリオ2: critic 呼び出し後に status: done 変更が許可される
  - executor: claudecode
  - validations:
    - technical: "state.md に self_complete: true 設定後、status: done 変更が exit 0 で許可されることを確認"
    - consistency: "critic の出力形式が設計通りか確認"
    - completeness: "state.md の更新が正しく行われるか確認"

- [ ] **p4.3**: テストシナリオ3: phase 完了時の全フローが正常に動作する
  - executor: claudecode
  - validations:
    - technical: "subtask 完了 -> critic 呼び出し -> PASS -> status: done の全フローを確認"
    - consistency: "他の Hook（subtask-guard 等）との連携が正しいか確認"
    - completeness: "ログ出力が十分か確認"

- [ ] **p4.4**: docs/hook-responsibilities.md に critic-guard.sh の責務更新が反映されている
  - executor: claudecode
  - validations:
    - technical: "grep で playbook 検知の記述を確認"
    - consistency: "他の Hook 責務と整合しているか確認"
    - completeness: "state.md と playbook 両方の検知責務が記載されているか確認"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: goal.done_when が全て満たされているか最終検証する

**depends_on**: [p4]

#### subtasks

- [ ] **p_final.1**: critic-guard.sh が PreToolUse:Edit で発火している（settings.json に登録済み）
  - executor: claudecode
  - validations:
    - technical: "grep で settings.json を確認"
    - consistency: "他の Hook との順序が適切か確認"
    - completeness: "Edit と Write 両方に登録されているか確認"

- [ ] **p_final.2**: playbook の `status: done` への変更を正しく検知する
  - executor: claudecode
  - validations:
    - technical: "critic-guard.sh のパターンマッチを確認"
    - consistency: "設計変更方針と整合しているか確認"
    - completeness: "全ての状態遷移パターンを考慮"

- [ ] **p_final.3**: critic 未実行時のブロックが機能する（exit 2 でブロック）
  - executor: claudecode
  - validations:
    - technical: "E2E テストで exit 2 を確認"
    - consistency: "エラーメッセージが規約と整合しているか確認"
    - completeness: "ブロック時のガイダンスが含まれているか確認"

- [ ] **p_final.4**: critic PASS 後の許可ロジックが動作する（self_complete: true で通過）
  - executor: claudecode
  - validations:
    - technical: "E2E テストで exit 0 を確認"
    - consistency: "許可フラグの設計と整合しているか確認"
    - completeness: "許可後の状態遷移が正しいか確認"

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

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-22 | 初版作成。M083 検証結果に基づく critique_process workflow の E2E 検証・修正 playbook。 |
| 2025-12-22 | レビュー結果に基づき修正: p2 に notes 追加、p3.3 を具体化、p4 にテスト配置先と p4.4（ドキュメント更新）追加。 |
