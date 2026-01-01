# playbook-auto-retry.md

> **FAIL 時自動リトライ機能の実装**

---

## meta

```yaml
project: auto-retry
branch: feat/auto-retry
created: 2026-01-01
issue: null
reviewed: true
```

---

## context

```yaml
背景:
  - max_iterations は playbook に定義されているが、FAIL 時に自動リトライするロジックが未実装
  - 現状: codex 実装 → critic FAIL → ここで止まる（手動介入待ち）
  - あるべき姿: codex 実装 → critic FAIL → エラーを codex にフィード → 再実装 → max_iterations まで自動ループ

解決策:
  - critic-guard.sh 拡張: FAIL 時にエラー内容を保存
  - executor-guard.sh 拡張: 保存されたエラーを次回プロンプトに注入
  - ループ制御: iteration_count を session-state に記録
  - ドキュメント更新: 動作仕様を明記

設計決定:
  - iteration_count 保存先: .claude/session-state/iteration-count
  - FAIL 理由保存先: .claude/session-state/last-fail-reason
  - max_iterations 到達時: AskUserQuestion で人間に確認
```

---

## goal

```yaml
summary: critic FAIL 時に自動リトライする機構を実装する（max_iterations まで）
done_when:
  - critic-guard.sh が FAIL 時に .claude/session-state/last-fail-reason にエラー内容を保存する
  - executor-guard.sh が保存されたエラーを読み込み、codex プロンプトに注入する仕組みが存在する
  - iteration_count が .claude/session-state/iteration-count に記録される
  - max_iterations 到達時に AskUserQuestion が呼ばれる仕組みが存在する
  - playbook-format.md に max_iterations の自動リトライ動作が明記されている
  - ARCHITECTURE.md に自動リトライフローが追記されている
```

---

## phases

### p1: FAIL 情報保存機構

**goal**: critic FAIL 時にエラー情報を保存する機構を実装

#### subtasks

- [ ] **p1.1**: .claude/session-state/ ディレクトリ構造が定義されている
  - executor: claudecode
  - validations:
    - technical: "test -d .claude/session-state で確認"
    - consistency: "他の session-state 利用箇所と整合性確認"
    - completeness: "README.md が存在し用途が説明されている"

- [ ] **p1.2**: critic-guard.sh に FAIL 時エラー保存ロジックが追加されている
  - executor: claudecode
  - validations:
    - technical: "bash -n でシンタックス確認、FAIL シナリオでファイル生成確認"
    - consistency: "既存の critic-guard.sh ロジックと整合性確認"
    - completeness: "FAIL 理由、タイムスタンプ、Phase ID が保存される"

**status**: pending
**max_iterations**: 5

---

### p2: エラー注入機構

**goal**: 保存されたエラーを次回実行時にプロンプトへ注入する機構を実装

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: executor-guard.sh にエラー読み込み・注入ロジックが追加されている
  - executor: claudecode
  - validations:
    - technical: "bash -n でシンタックス確認"
    - consistency: "既存の executor-guard.sh ロジックと整合性確認"
    - completeness: "last-fail-reason が存在する場合に hookSpecificOutput.systemMessage に含まれる"

- [ ] **p2.2**: エラー注入後に last-fail-reason がクリアされる
  - executor: claudecode
  - validations:
    - technical: "エラー注入後のファイル存在確認（削除または移動されている）"
    - consistency: "セッション状態管理ルールと整合性確認"
    - completeness: "クリア処理が executor-guard.sh に含まれている"

**status**: pending
**max_iterations**: 5

---

### p3: イテレーション制御

**goal**: iteration_count を追跡し、max_iterations 到達時に人間確認を強制

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: iteration_count が .claude/session-state/iteration-count に記録される
  - executor: claudecode
  - validations:
    - technical: "critic FAIL 後にファイル内容がインクリメントされることを確認"
    - consistency: "Phase 単位でカウントがリセットされることを確認"
    - completeness: "subtask_id, count, timestamp が記録される"

- [ ] **p3.2**: max_iterations 到達時に AskUserQuestion 呼び出し指示が出力される
  - executor: claudecode
  - validations:
    - technical: "max_iterations 到達時の出力に AskUserQuestion 指示が含まれる"
    - consistency: "既存の BLOCK メッセージ形式と整合性確認"
    - completeness: "選択肢（リトライ継続/中止/人間介入）が提示される"

**status**: pending
**max_iterations**: 5

---

### p4: ドキュメント更新

**goal**: playbook-format.md と ARCHITECTURE.md に自動リトライ機構を明記

**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: playbook-format.md の max_iterations セクションに自動リトライ動作が明記されている
  - executor: claudecode
  - validations:
    - technical: "grep で関連セクションの存在を確認"
    - consistency: "既存のフォーマット説明と整合性確認"
    - completeness: "FAIL 時の動作、iteration_count、上限到達時の動作が説明されている"

- [ ] **p4.2**: ARCHITECTURE.md に自動リトライフローが追記されている
  - executor: claudecode
  - validations:
    - technical: "grep で Auto-Retry セクションの存在を確認"
    - consistency: "既存のフロー図形式と整合性確認"
    - completeness: "critic FAIL → 保存 → 次回注入 → ループのフローが図示されている"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when の全項目が実際に満たされているか最終検証

**depends_on**: [p4]

#### subtasks

- [ ] **p_final.1**: critic-guard.sh が FAIL 時に .claude/session-state/last-fail-reason にエラー内容を保存することを確認
  - executor: claudecode
  - validations:
    - technical: "FAIL シナリオを模擬実行し、ファイル生成を確認"
    - consistency: "ファイル内容が期待するフォーマットであることを確認"
    - completeness: "FAIL 理由、Phase ID、タイムスタンプが全て含まれる"

- [ ] **p_final.2**: executor-guard.sh がエラーを読み込み、プロンプト注入する仕組みが動作することを確認
  - executor: claudecode
  - validations:
    - technical: "last-fail-reason 存在時の出力を確認"
    - consistency: "hookSpecificOutput 形式が正しいことを確認"
    - completeness: "注入後にファイルがクリアされることを確認"

- [ ] **p_final.3**: iteration_count が正しく記録・インクリメントされることを確認
  - executor: claudecode
  - validations:
    - technical: "複数回 FAIL 時にカウントが増加することを確認"
    - consistency: "Phase 切り替え時にリセットされることを確認"
    - completeness: "max_iterations 到達時のメッセージを確認"

- [ ] **p_final.4**: playbook-format.md に max_iterations の自動リトライ動作が明記されていることを確認
  - executor: claudecode
  - validations:
    - technical: "grep で関連セクションを検索"
    - consistency: "説明が実装と一致していることを確認"
    - completeness: "全ての動作パターンが説明されている"

- [ ] **p_final.5**: ARCHITECTURE.md に自動リトライフローが追記されていることを確認
  - executor: claudecode
  - validations:
    - technical: "grep で Auto-Retry セクションを検索"
    - consistency: "フロー図が実装と一致していることを確認"
    - completeness: "全ステップが図示されている"

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
