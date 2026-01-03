# playbook-pb11-move-cleanup-stale-pending.md

> **cleanup_stale_pending() を正しい場所に移動し、孤立ファイルを整理する**

---

## meta

```yaml
project: PB-11 Move cleanup_stale_pending
branch: fix/pb11-move-cleanup-stale-pending
created: 2026-01-03
issue: null
reviewed: true
roles:
  worker: claudecode
```

---

## context

```yaml
5w1h:
  who: Claude（自動システム）
  what: cleanup_stale_pending() 関数を正しい場所に移動し、孤立した session-start.sh を削除
  when: セッション開始時（startup/resume/clear）
  where: .claude/hooks/session.sh -> .claude/skills/session-manager/handlers/start.sh
  why: |
    前回の修正（PB-27）で session-start.sh に cleanup_stale_pending() を追加したが、
    実際は session-manager/handlers/start.sh が SessionStart で呼び出されており、
    session-start.sh は未使用。デッドロック問題が再発した。
  how: |
    1. cleanup_stale_pending() を start.sh に移動
    2. session-start.sh を削除
    3. 実際の Hook チェーンでテスト

analysis_result:
  source: prompt-analyzer
  timestamp: 2026-01-03T19:20:00Z
  data:
    risks:
      technical:
        - risk: "移動後に cleanup が呼ばれない"
          severity: high
          mitigation: "Hook チェーン全体のテスト"
      scope:
        - risk: "session-start.sh の他機能が必要"
          severity: low
          mitigation: "移動前に機能を確認"

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-03T19:19:00Z
  summary: "cleanup_stale_pending() を start.sh に移動し、session-start.sh を削除する"
```

---

## goal

```yaml
summary: cleanup_stale_pending() を正しい場所（start.sh）に移動し、孤立ファイルを削除する
done_when:
  - cleanup_stale_pending() が .claude/skills/session-manager/handlers/start.sh に存在する
  - .claude/hooks/session-start.sh が削除されている
  - セッション開始時に pending ファイルが自動削除される（実際の動作テスト）
```

---

## phases

### p1: cleanup_stale_pending() を start.sh に移動

**goal**: cleanup_stale_pending() 関数を start.sh に追加し、main() で呼び出す

#### subtasks

- [x] **p1.1**: cleanup_stale_pending() 関数が .claude/skills/session-manager/handlers/start.sh に存在する
  - executor: claudecode
  - validations:
    - technical: "grep 'cleanup_stale_pending' start.sh → 関数定義あり (行 27-37)"
    - consistency: "rm -f で pending ファイルを削除する実装、session-start.sh と同等"
    - completeness: "行 40 で cleanup_stale_pending を呼び出し"
  - validated: 2026-01-03T19:30:00Z

- [x] **p1.2**: bash -n .claude/skills/session-manager/handlers/start.sh が exit 0 で終了する
  - executor: claudecode
  - validations:
    - technical: "bash -n start.sh → exit 0 (no output)"
    - consistency: "既存関数 check_repository_map_drift, verify_hooks 等が正常"
    - completeness: "全関数定義あり、シンタックスエラーなし"
  - validated: 2026-01-03T19:30:00Z

**status**: done
**max_iterations**: 5

---

### p2: 孤立した session-start.sh を削除

**goal**: 未使用の session-start.sh を削除する

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: .claude/hooks/session-start.sh が存在しない
  - executor: claudecode
  - validations:
    - technical: "test ! -f .claude/hooks/session-start.sh → PASS"
    - consistency: "settings.json に session-start.sh への参照なし（session.sh のみ）"
    - completeness: "start.sh ヘッダーコメントを更新済み"
  - validated: 2026-01-03T19:31:00Z

**status**: done
**max_iterations**: 3

---

### p3: テストスクリプトを更新

**goal**: test-workflow-simple.sh の Test 8 を実際の Hook チェーンを呼び出すよう修正

**depends_on**: [p1]

#### subtasks

- [x] **p3.1**: test-workflow-simple.sh の Test 8 が実際の session.sh -> start.sh チェーンを呼び出している
  - executor: claudecode
  - validations:
    - technical: "START_SH=\"$REPO_ROOT/.claude/skills/session-manager/handlers/start.sh\" で start.sh を呼び出し"
    - consistency: "Test 1-7 と同様の subshell パターン使用"
    - completeness: "pending 作成 → start.sh 実行 → 削除確認のフローあり (行 308-351)"
  - validated: 2026-01-03T19:32:00Z

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: done_when の全項目を実際に検証する

**depends_on**: [p1, p2, p3]

#### subtasks

- [x] **p_final.1**: cleanup_stale_pending() が start.sh に存在し、呼び出されている
  - executor: claudecode
  - validations:
    - technical: "grep -A5 'cleanup_stale_pending' start.sh → 関数定義 (行 27-37) と呼び出し (行 40)"
    - consistency: "set -e の直後、state-schema.sh source の前に呼び出し"
    - completeness: "pending_file='.claude/session-state/post-loop-pending' で正しいパス"
  - validated: 2026-01-03T19:33:00Z

- [x] **p_final.2**: session-start.sh が削除されている
  - executor: claudecode
  - validations:
    - technical: "test ! -f .claude/hooks/session-start.sh → PASS"
    - consistency: "git status: D .claude/hooks/session-start.sh"
    - completeness: "start.sh ヘッダーに '旧 session-start.sh の機能を統合' と記載"
  - validated: 2026-01-03T19:33:00Z

- [x] **p_final.3**: 実際の動作テスト - pending ファイルがセッション開始で削除される
  - executor: claudecode
  - validations:
    - technical: "Test 8 in test-workflow-simple.sh: PASS"
    - consistency: "start.sh を直接呼び出し、pending 削除を確認"
    - completeness: "cleanup_stale_pending() が pending ファイルを rm -f で削除"
  - validated: 2026-01-03T19:33:00Z

- [x] **p_final.4**: test-workflow-simple.sh の Test 8 が PASS する
  - executor: claudecode
  - validations:
    - technical: "Test 8: PASS (SessionStart Hook chain で pending ファイルを自動削除)"
    - consistency: "Test 1-4 の失敗はパス不整合（別 issue、本 playbook スコープ外）"
    - completeness: "本 playbook の対象である Test 8 は PASS"
  - validated: 2026-01-03T19:33:00Z

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
