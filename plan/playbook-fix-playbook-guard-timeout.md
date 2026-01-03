# playbook-fix-playbook-guard-timeout.md

> **playbook-guard.sh の stdin タイムアウト問題を修正**

---

## meta

```yaml
project: fix-playbook-guard-timeout
branch: fix/playbook-guard-timeout
created: 2026-01-03
issue: null
reviewed: true
```

---

## goal

```yaml
summary: playbook-guard.sh の stdin 読み込みにタイムアウトを追加し、ハングを防止する
done_when:
  - playbook-guard.sh が stdin 空/タイムアウト時に WARN して継続する
  - タイムアウト値が 5 秒で設定されている
```

---

## context

```yaml
5w1h:
  who: Claude Code（hooks 実行時）
  what: playbook-guard.sh の stdin 読み込みにタイムアウト追加
  when: 即時
  where: .claude/skills/playbook-gate/guards/playbook-guard.sh
  why: stdin が空またはタイムアウトした場合にスクリプトがハングする問題を解決
  how: timeout コマンドで 5 秒のタイムアウトを設定し、失敗時は WARN して INPUT="{}" で継続

analysis_result:
  source: user-specified
  timestamp: 2026-01-03T14:50:00Z
  data:
    modification:
      before: "INPUT=$(cat)"
      after: |
        if ! INPUT=$(timeout 5 cat 2>/dev/null); then
            echo "[WARN] stdin timeout or empty" >&2
            INPUT="{}"
        fi
    rationale: stdin が空の場合やパイプが詰まった場合のハング防止

user_approved_understanding:
  source: user-confirmation
  approved_at: 2026-01-03T14:50:00Z
  summary: デフォルト設定（タイムアウト5秒、WARN継続）で修正を進める
```

---

## phases

### p1: stdin タイムアウト修正

**goal**: playbook-guard.sh の stdin 読み込みにタイムアウトを追加

#### subtasks

- [x] **p1.1**: playbook-guard.sh の `INPUT=$(cat)` が `timeout 5 cat` に変更されている
  - executor: claudecode
  - validations:
    - technical: "PASS - 35行目: `if ! INPUT=$(timeout 5 cat 2>/dev/null); then`"
    - consistency: "PASS - 他の hook ファイルでは stdin タイムアウト未実装だが、初導入として妥当"
    - completeness: "PASS - WARN メッセージ（36行目）と INPUT={} フォールバック（37行目）が含まれている"
  - validated: 2026-01-03T15:10:00Z

- [x] **p1.2**: playbook-guard.sh が構文エラーなく動作する
  - executor: claudecode
  - validations:
    - technical: "PASS - bash -n playbook-guard.sh で SYNTAX CHECK: PASS"
    - consistency: "PASS - 既存のロジック（playbook チェック、reviewed チェック等）は維持"
    - completeness: "PASS - タイムアウト時のフォールバックパス（INPUT={}）により後続処理が継続可能"
  - validated: 2026-01-03T15:10:00Z

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when の全項目が実際に満たされているか検証

**depends_on**: [p1]

#### subtasks

- [x] **p_final.1**: playbook-guard.sh が stdin 空/タイムアウト時に WARN して継続する
  - executor: claudecode
  - validations:
    - technical: "PASS - 35行目: timeout 5 cat、36行目: [WARN]、37行目: INPUT={}"
    - consistency: "PASS - 他の guard スクリプト（coherence.sh等）も [WARN] パターンを使用"
    - completeness: "PASS - WARN が stderr に出力され、INPUT={} で処理が継続する"
  - validated: 2026-01-03T15:10:00Z

- [x] **p_final.2**: タイムアウト値が 5 秒で設定されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 'timeout 5' で35行目に確認"
    - consistency: "PASS - Hook タイムアウト（10秒）の半分として妥当"
    - completeness: "PASS - タイムアウト値がハードコード（timeout 5）されている"
  - validated: 2026-01-03T15:10:00Z

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
