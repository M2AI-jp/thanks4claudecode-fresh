# playbook-context-continuity.md

> **Self-Healing Layer 1 完成: compact 後の作業継続を実現する**

---

## meta

```yaml
project: context-continuity
branch: feat/context-continuity
created: 2025-12-24
issue: null
reviewed: true
roles:
  worker: claudecode  # Shell スクリプト実装のみ
```

---

## goal

```yaml
summary: compact 後にも作業状態が継続されるよう、start.sh に復元処理を追加する
done_when:
  - start.sh が .claude/.session-init/snapshot.json の存在を検出し、復元モードで動作する
  - 復元時に「[COMPACT 復元]」ラベルと focus, playbook, phase, user_intents の4項目が表示される
  - 復元完了後に snapshot.json が削除（または archive に移動）される
```

---

## 既存実装の確認

```yaml
compact.sh（PreCompact）:
  status: 実装済み
  出力: .claude/.session-init/snapshot.json
  フィールド:
    - timestamp, trigger, focus, playbook, current_phase
    - phase_goal, done_criteria, self_complete
    - branch, uncommitted_count, git_status, user_intents
  評価: 十分なフィールドが保存されている。追加不要。

start.sh（SessionStart）:
  status: 復元処理なし
  問題: trigger=compact を受け取っても snapshot.json を読み取らない
  対応: snapshot.json の存在をトリガーとして復元処理を追加する

設計方針:
  - Claude Code の trigger 仕様に依存しない
  - snapshot.json の存在自体を復元のトリガーとする（より堅牢）
  - 復元後は snapshot.json を削除して二重復元を防止
```

---

## phases

### p1: start.sh に復元処理を追加

**goal**: snapshot.json の存在を検出し、復元メッセージを表示する

#### subtasks

- [ ] **p1.1**: start.sh に restore_from_snapshot 関数が存在する
  - executor: claudecode
  - validations:
    - technical: "grep -A30 'restore_from_snapshot' .claude/skills/session-manager/handlers/start.sh で関数を確認"
    - consistency: "snapshot.json のフィールド（focus, playbook, current_phase, user_intents）を読み取ることを確認"
    - completeness: "jq を使用して JSON をパースしていることを確認"

- [ ] **p1.2**: 関数が snapshot.json の存在をチェックし、存在時に復元処理を実行する
  - executor: claudecode
  - validations:
    - technical: "test -f .claude/.session-init/snapshot.json によるチェックがあることを確認"
    - consistency: "存在しない場合は通常の start 処理に進むことを確認"
    - completeness: "snapshot.json が壊れている場合のエラーハンドリングがあることを確認"

- [ ] **p1.3**: 復元メッセージに「[COMPACT 復元]」ラベルが含まれる
  - executor: claudecode
  - validations:
    - technical: "grep '\\[COMPACT' .claude/skills/session-manager/handlers/start.sh で確認"
    - consistency: "通常の SessionStart メッセージと区別できることを確認"
    - completeness: "focus, playbook, phase, user_intents の4項目が表示されることを確認"

**status**: pending
**max_iterations**: 3

---

### p2: 復元後のクリーンアップ

**goal**: 復元完了後に snapshot.json を削除して二重復元を防止する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: 復元処理の最後で snapshot.json が削除される
  - executor: claudecode
  - validations:
    - technical: "rm -f .claude/.session-init/snapshot.json がコードに含まれることを確認"
    - consistency: "復元メッセージ表示後に削除されることを確認（順序）"
    - completeness: "削除に失敗してもエラーにならないことを確認（|| true）"

- [ ] **p2.2**: 削除前に archive への保存オプションがある（任意）
  - executor: claudecode
  - validations:
    - technical: "SNAPSHOT_ARCHIVE_DIR 変数または同等の仕組みがあることを確認"
    - consistency: "削除のみでも動作することを確認"
    - completeness: "archive は任意機能として実装されていることを確認"

**status**: pending
**max_iterations**: 3

---

### p3: 初期化フローへの統合

**goal**: start.sh の冒頭で復元チェックを行い、適切なフローに分岐する

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: start.sh の初期化フロー冒頭で restore_from_snapshot が呼び出される
  - executor: claudecode
  - validations:
    - technical: "スクリプト冒頭（state.md 読み込み前後）で関数が呼び出されることを確認"
    - consistency: "既存の DRIFT チェック、前回未終了警告と共存することを確認"
    - completeness: "復元時も復元なしも正常に動作することを確認"

- [ ] **p3.2**: 後方互換性が維持されている
  - executor: claudecode
  - validations:
    - technical: "snapshot.json がない場合も start.sh が正常動作することを確認"
    - consistency: "既存の機能（前回未終了警告、DRIFT チェック）が維持されていることを確認"
    - completeness: "エラーで処理が中断しないことを確認"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: done_when の全項目が実際に満たされていることを検証する

**depends_on**: [p1, p2, p3]

#### subtasks

- [ ] **p_final.1**: start.sh が snapshot.json を検出し復元モードで動作する
  - executor: claudecode
  - validations:
    - technical: |
        テスト手順:
        1. テスト用 snapshot.json を作成: echo '{"focus":"test","playbook":"test.md","current_phase":"p1","user_intents":"test intent"}' > .claude/.session-init/snapshot.json
        2. bash .claude/skills/session-manager/handlers/start.sh を実行
        3. 出力に [COMPACT 復元] が含まれることを確認
    - consistency: "snapshot.json の内容と表示が一致することを確認"
    - completeness: "復元モードで動作したことが確認できること"

- [ ] **p_final.2**: 復元時に4項目が表示される
  - executor: claudecode
  - validations:
    - technical: "出力に focus, playbook, phase, user_intents の4項目が含まれることを grep で確認"
    - consistency: "snapshot.json の値と表示値が一致することを確認"
    - completeness: "4項目全てが表示されること"

- [ ] **p_final.3**: 復元完了後に snapshot.json が削除される
  - executor: claudecode
  - validations:
    - technical: "test ! -f .claude/.session-init/snapshot.json で削除を確認"
    - consistency: "再度 start.sh を実行しても復元モードにならないこと"
    - completeness: "通常モードで動作すること"

**status**: pending
**max_iterations**: 3

---

## risks

```yaml
リスク分析:
  - risk: jq がインストールされていない環境
    mitigation: compact.sh も jq 使用のため新規リスクではない。jq なしの場合は警告出力。

  - risk: snapshot.json が破損している場合
    mitigation: jq パースエラー時はスキップして通常起動。エラーログ出力。

  - risk: 既存機能への影響
    mitigation: 後方互換性テスト（p3.2）で確認。snapshot.json がない場合は既存動作維持。
```

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: E2E テストを実行する
  - command: |
      # 1. テスト用 snapshot.json 作成
      echo '{"focus":"e2e-test","playbook":"test.md","current_phase":"p1","user_intents":"test"}' > .claude/.session-init/snapshot.json
      # 2. start.sh 実行して復元確認
      bash .claude/skills/session-manager/handlers/start.sh | grep -E 'COMPACT|復元'
      # 3. snapshot.json が削除されたことを確認
      test ! -f .claude/.session-init/snapshot.json && echo "PASS: snapshot deleted"
  - status: pending

- [ ] **ft4**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending
