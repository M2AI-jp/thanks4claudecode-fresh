# playbook-codex-audit-findings.md

> **Codex 監査で発見された問題の修正**

---

## meta

```yaml
project: codex-audit-findings
branch: fix/codex-audit-findings
created: 2026-01-02
issue: null
reviewed: true
roles:
  worker: codex
  reviewer: coderabbit
```

---

## goal

```yaml
summary: Codex 監査で発見された bash-check.sh の欠損スクリプト呼び出しと ARCHITECTURE.md のドキュメント不整合を修正する
done_when:
  - bash-check.sh が存在しないスクリプトを呼び出していない
  - ARCHITECTURE.md の記述が実装と整合している
  - bash -n でシンタックスエラーがない
```

---

## context

```yaml
5w1h:
  who: 開発者（Claude/Codex が実行）
  what: Codex 監査で発見された 4 件の問題を修正
  when: 今回のセッションで完了
  where: bash-check.sh、ARCHITECTURE.md
  why: コードベースの品質・整合性を維持するため
  how: 欠損スクリプト呼び出し削除、ドキュメント修正

analysis_result:
  source: user-provided
  timestamp: 2026-01-02T17:55:00Z
  data:
    findings:
      - id: 1
        severity: critical
        location: bash-check.sh:141
        issue: check-coherence.sh を呼び出しているが存在しない
        actual_path: .claude/skills/reward-guard/guards/coherence.sh
      - id: 2
        severity: critical
        location: bash-check.sh:144
        issue: check-state-update.sh を呼び出しているが存在しない
        action: 削除（スキーマ廃止のため）
      - id: 3
        severity: high
        location: ARCHITECTURE.md:312
        issue: .claude/session-state/* と記載だが実装は .claude/.session-init
      - id: 4
        severity: high
        location: ARCHITECTURE.md:170
        issue: session.sh -> handlers/compact.sh と記載だが直接 compact.sh 呼び出し
      - id: 5
        severity: medium
        location: ARCHITECTURE.md:771
        issue: session.log と記載だが実装は subagent.log + archive-playbook.sh

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-02T17:55:00Z
  summary: ユーザーが修正方針を承認済み
  approved_items:
    - question_id: q1
      question: check-state-update.sh は削除してよいか
      answer: はい、スキーマ廃止のため削除
    - question_id: q2
      question: check-coherence.sh のパス修正方法
      answer: 正しいパス .claude/skills/reward-guard/guards/coherence.sh に修正
```

---

## phases

### p1: bash-check.sh の修正

**goal**: 欠損スクリプトの呼び出しを修正し、シンタックスエラーがない状態にする

#### subtasks

- [ ] **p1.1**: bash-check.sh:141 の check-coherence.sh パスが `.claude/skills/reward-guard/guards/coherence.sh` に修正されている
  - executor: codex
  - validations:
    - technical: "grep で修正後のパスが存在することを確認"
    - consistency: "coherence.sh の実際のパスと一致"
    - completeness: "呼び出し箇所が全て修正されている"

- [ ] **p1.2**: bash-check.sh:144 の check-state-update.sh 呼び出しが削除されている
  - executor: codex
  - validations:
    - technical: "grep -c 'check-state-update' が 0 を返す"
    - consistency: "関連する変数や条件分岐も削除されている"
    - completeness: "呼び出し箇所が全て削除されている"

- [ ] **p1.3**: bash -n .claude/hooks/bash-check.sh がシンタックスエラーなしで終了する
  - executor: claudecode
  - validations:
    - technical: "bash -n が exit 0 で終了"
    - consistency: "他のスクリプトとの整合性確認"
    - completeness: "全ての関数が正しく定義されている"

**status**: pending
**max_iterations**: 5

---

### p2: ARCHITECTURE.md の修正

**goal**: ドキュメントの記述を実装と整合させる
**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: ARCHITECTURE.md Section 3 の `.claude/session-state/*` が `.claude/.session-init` に修正されている
  - executor: codex
  - validations:
    - technical: "grep で .claude/.session-init が存在することを確認"
    - consistency: "init-guard.sh の INIT_DIR と一致"
    - completeness: "関連する全ての記述が修正されている"

- [ ] **p2.2**: ARCHITECTURE.md Section 1.5 の `session.sh -> handlers/compact.sh` が直接 `compact.sh` 呼び出しに修正されている
  - executor: codex
  - validations:
    - technical: "grep で修正後の記述が存在することを確認"
    - consistency: "settings.json の hooks 定義と一致"
    - completeness: "PreCompact セクション全体が整合している"

- [ ] **p2.3**: ARCHITECTURE.md Section 7 の `session.log` が `subagent.log` に修正され、`archive-playbook.sh` 呼び出しが追記されている
  - executor: codex
  - validations:
    - technical: "grep で subagent.log と archive-playbook.sh が存在することを確認"
    - consistency: "subagent-stop.sh の実装と一致"
    - completeness: "SubagentStop セクション全体が整合している"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証
**depends_on**: [p1, p2]

#### subtasks

- [ ] **p_final.1**: bash-check.sh が存在しないスクリプトを呼び出していない
  - executor: claudecode
  - validations:
    - technical: "grep で check-coherence.sh と check-state-update.sh の古いパス/呼び出しがないことを確認"
    - consistency: "呼び出されるスクリプトが全て存在する"
    - completeness: "bash -n でエラーがない"

- [ ] **p_final.2**: ARCHITECTURE.md の記述が実装と整合している
  - executor: claudecode
  - validations:
    - technical: "修正された 3 箇所を grep で確認"
    - consistency: "各記述が対応する実装ファイルと一致"
    - completeness: "全ての修正対象箇所が更新されている"

- [ ] **p_final.3**: bash -n でシンタックスエラーがない
  - executor: claudecode
  - validations:
    - technical: "bash -n .claude/hooks/bash-check.sh が exit 0"
    - consistency: "他のシェルスクリプトも同様にエラーがない"
    - completeness: "修正による副作用がない"

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
