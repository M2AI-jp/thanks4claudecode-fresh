# playbook-fix-pending-guard-fail-closed.md

> **PB-06: pending-guard.sh の jq 不在時 fail-closed 実装**

---

## meta

```yaml
project: fix-pending-guard-fail-closed
branch: fix/pending-guard-fail-closed
created: 2026-01-03
issue: PB-06
reviewed: true
derives_from: docs/fix-backlog.md Section 2 P0-04
```

---

## goal

```yaml
summary: pending-guard.sh の jq 不在時を fail-closed に変更し、セキュリティホールを修正
done_when:
  - jq 不在時に exit 2 でブロックする
  - エラーメッセージ "[FAIL-CLOSED] jq not found - blocking for security" が stderr に出力される
```

---

## context

```yaml
5w1h:
  who: Claude Code フレームワークを使用する開発者
  what: pending-guard.sh の jq 不在時の処理を fail-open から fail-closed に変更
  when: 即時対応（P0 Hook Robustness）
  where: .claude/skills/post-loop/guards/pending-guard.sh 行 31-34
  why: 現在の実装はセキュリティ違反。jq がない環境でセキュリティチェックがスキップされる
  how: exit 0 を exit 2 に変更し、stderr にエラーメッセージを出力

analysis_result:
  source: fix-backlog.md
  timestamp: 2026-01-03
  data:
    problem: |
      行 31-34 で jq 不在時に exit 0（fail-open）となっている。
      これはセキュリティ違反であり、jq がない環境でガードがスキップされる。
    current_code: |
      if ! command -v jq &> /dev/null; then
          exit 0  # Fail-open: セキュリティ違反
      fi
    fix_code: |
      if ! command -v jq &> /dev/null; then
          echo "[FAIL-CLOSED] jq not found - blocking for security" >&2
          exit 2
      fi
    risks:
      - risk: jq が通常インストールされている環境では影響なし
        severity: low
      - risk: fail-closed により正当な操作もブロック
        severity: medium
        mitigation: エラーメッセージで原因を明示

user_approved_understanding:
  source: user-provided
  approved_at: 2026-01-03
  summary: ユーザーがタスク詳細を docs/fix-backlog.md から提供。修正内容は明確に定義済み。
```

---

## phases

### p1: 修正実装

**goal**: pending-guard.sh の jq 不在時処理を fail-closed に変更

#### subtasks

- [x] **p1.1**: pending-guard.sh の行 31-34 が fail-closed 実装に変更されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で exit 2 (行34) と FAIL-CLOSED メッセージ (行33) を確認"
    - consistency: "PASS - 他の guard と同じ fail-closed パターン (echo >&2 + exit 2)"
    - completeness: "PASS - コメント (行31), stderr 出力 (行33), exit 2 (行34) の3要素全て含まれている"
  - validated: 2026-01-03T17:05:00+09:00

- [x] **p1.2**: bash -n pending-guard.sh がシンタックスエラーなしで通る
  - executor: claudecode
  - validations:
    - technical: "PASS - bash -n pending-guard.sh が exit 0 (出力なし)"
    - consistency: "PASS - 変更前と同じシェル構文ルールに従っている"
    - completeness: "PASS - ファイル全体が正しく解析される"
  - validated: 2026-01-03T17:05:00+09:00

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: done_when の全条件が実際に満たされていることを検証

**depends_on**: [p1]

#### subtasks

- [x] **p_final.1**: jq 不在時に exit 2 でブロックする
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 'exit 2' で行34に確認済み"
    - consistency: "PASS - exit 2 は Claude Code Hook 仕様（ブロック）と一致"
    - completeness: "PASS - jq 不在時の分岐 (行32-35) で exit 2 が呼ばれる"
  - validated: 2026-01-03T17:06:00+09:00

- [x] **p_final.2**: エラーメッセージが stderr に出力される
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 'FAIL-CLOSED' で行33に確認済み"
    - consistency: "PASS - メッセージ '[FAIL-CLOSED] jq not found - blocking for security' は docs/fix-backlog.md の仕様と一致"
    - completeness: "PASS - echo '[FAIL-CLOSED] jq not found - blocking for security' >&2 形式で stderr に出力される"
  - validated: 2026-01-03T17:06:00+09:00

**status**: done
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending
