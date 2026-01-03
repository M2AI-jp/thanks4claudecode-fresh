# playbook-pb11-critic-guard.md

> **PB-11: critic-guard.sh の問題を修正し、critic 未実行の done 変更を確実にブロックする**

---

## meta

```yaml
project: PB-11 critic-guard 修正
branch: fix/pb11-critic-guard
created: 2026-01-03
issue: null
reviewed: true
derives_from: docs/fix-backlog.md#PB-11
```

---

## context

```yaml
5w1h:
  who: Claude Code（自動実行）/ LLM の報酬詐欺をブロック
  what: critic-guard.sh の 3 つの問題を修正
  when: 今回のセッションで完了
  where: .claude/skills/reward-guard/guards/critic-guard.sh
  why: critic 未実行で goal.status を done に変更することを確実にブロックし、自己報酬詐欺を防止
  how: パターン修正 + 無意味コード削除 + 検証テスト

analysis_result:
  source: manual-analysis
  timestamp: 2026-01-03T19:40:00Z
  data:
    problems:
      - id: 1
        description: "パターン不一致 - state: done vs status: done"
        severity: critical
        location: "行 51, 62"
        evidence: |
          critic-guard.sh: grep -qE "state:[[:space:]]*done"
          coherence.sh (正): grep -E "^\+.*status: done"
          state.md 構造: goal.status: done
      - id: 2
        description: "無意味なコードブロック"
        severity: low
        location: "行 62-67"
        evidence: |
          if ! echo "$NEW_STRING" | grep -qE "^state:[[:space:]]*done"; then
              :  # 何もしない
          fi
      - id: 3
        description: "self_complete フィールドの整合性"
        severity: medium
        location: "行 71"
        evidence: |
          state.md には self_complete フィールドが存在しない
          critic PASS 時に追加される設計

user_approved_understanding:
  source: user-instruction
  approved_at: 2026-01-03T19:40:00Z
  summary: "ユーザーが明示的に playbook 作成を指示"
```

---

## goal

```yaml
summary: critic-guard.sh のパターン不一致を修正し、critic 未実行の status: done 変更を確実にブロック
done_when:
  - critic-guard.sh の "state: done" パターンが "status: done" に修正されている
  - 無意味なコードブロック（行 62-67）が削除されている
  - critic 未実行で status: done への変更を試みると BLOCK される
```

---

## phases

### p1: パターン修正

**goal**: critic-guard.sh のパターン不一致を修正

#### subtasks

- [x] **p1.1**: 行 51 の `state:[[:space:]]*done` が `status:[[:space:]]*done` に修正されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep -c 'state:.*done' = 0, grep -c 'status:.*done' = 10"
    - consistency: "PASS - coherence.sh と同じ status: done パターン"
    - completeness: "PASS - 全パターン修正済み"
  - validated: 2026-01-03T20:00:00Z

- [x] **p1.2**: 行 62 の `^state:[[:space:]]*done` が `status:[[:space:]]*done` に修正されている
  - executor: claudecode
  - validations:
    - technical: "PASS - 該当行は削除済み（無意味コードブロック）"
    - consistency: "PASS - 行 52 のパターンと整合"
    - completeness: "PASS - コメントも status: done に更新"
  - validated: 2026-01-03T20:00:00Z

- [x] **p1.3**: 無意味なコードブロック（旧 行 62-67 の `: # 何もしない` 部分）が削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep ': # 何もしない' = 0 件"
    - consistency: "PASS - ロジックフローが明確"
    - completeness: "PASS - デッドコードなし、131行（元141行）"
  - validated: 2026-01-03T20:00:00Z

**status**: done
**max_iterations**: 3

---

### p2: 動作検証

**goal**: 修正後の guard が正しく動作することを検証

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: bash -n critic-guard.sh が成功する
  - executor: claudecode
  - validations:
    - technical: "PASS - bash -n で SYNTAX_CHECK=PASS"
    - consistency: "PASS - 他の guard と同じ品質基準"
    - completeness: "PASS - 全構文正しい"
  - validated: 2026-01-03T20:00:00Z

- [x] **p2.2**: critic 未実行時に status: done への変更が BLOCK される
  - executor: claudecode
  - validations:
    - technical: "PASS - EXIT_CODE=2 を確認"
    - consistency: "PASS - エラーメッセージに /crit ガイダンス"
    - completeness: "PASS - BLOCK 理由が明示"
  - validated: 2026-01-03T20:00:00Z

- [x] **p2.3**: self_complete: true が存在する場合は PASS する
  - executor: claudecode
  - validations:
    - technical: "PASS - EXIT_CODE=0 を確認（self_complete設定時）"
    - consistency: "PASS - 正当な完了フローは妨げられない"
    - completeness: "PASS - 両ケースをテスト"
  - validated: 2026-01-03T20:00:00Z

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: done_when が全て満たされていることを最終検証

**depends_on**: [p1, p2]

#### subtasks

- [x] **p_final.1**: critic-guard.sh の "state: done" パターンが "status: done" に修正されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep -c 'state:.*done' = 0"
    - consistency: "PASS - grep -c 'status:.*done' = 10"
    - completeness: "PASS - 全パターン修正済み"
  - validated: 2026-01-03T20:00:00Z

- [x] **p_final.2**: 無意味なコードブロック（行 62-67）が削除されている
  - executor: claudecode
  - validations:
    - technical: "PASS - 131行 < 141行"
    - consistency: "PASS - grep ': # 何もしない' = 0"
    - completeness: "PASS - デッドコードなし"
  - validated: 2026-01-03T20:00:00Z

- [x] **p_final.3**: critic 未実行で status: done への変更を試みると BLOCK される
  - executor: claudecode
  - validations:
    - technical: "PASS - EXIT_CODE=2 を確認"
    - consistency: "PASS - /crit ガイダンスが表示"
    - completeness: "PASS - 報酬詐欺がブロック"
  - validated: 2026-01-03T20:00:00Z

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

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-03 | 初版作成 |
