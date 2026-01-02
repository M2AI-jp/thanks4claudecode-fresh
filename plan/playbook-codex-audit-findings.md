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

- [x] **p1.1**: bash-check.sh:141 の check-coherence.sh パスが `.claude/skills/reward-guard/guards/coherence.sh` に修正されている
  - executor: codex
  - validations:
    - technical: "PASS - bash-check.sh:141 に正しいパス確認済み"
    - consistency: "PASS - coherence.sh ファイルが存在"
    - completeness: "PASS - 呼び出し箇所全て修正済み"
  - validated: 2026-01-02T18:00:00

- [x] **p1.2**: bash-check.sh:144 の check-state-update.sh 呼び出しが削除されている
  - executor: codex
  - validations:
    - technical: "PASS - grep 結果 0 件"
    - consistency: "PASS - 関連行も削除済み"
    - completeness: "PASS - 呼び出し箇所全て削除済み"
  - validated: 2026-01-02T18:00:00

- [x] **p1.3**: bash -n .claude/hooks/bash-check.sh がシンタックスエラーなしで終了する
  - executor: claudecode
  - validations:
    - technical: "PASS - bash -n exit 0"
    - consistency: "PASS - 整合性確認済み"
    - completeness: "PASS - 全関数正常定義"
  - validated: 2026-01-02T18:00:00

**status**: done
**max_iterations**: 5

---

### p2: ARCHITECTURE.md の修正

**goal**: ドキュメントの記述を実装と整合させる
**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: ARCHITECTURE.md Section 3 の `.claude/session-state/*` が `.claude/.session-init` に修正されている
  - executor: codex
  - validations:
    - technical: "PASS - Line 308 に .session-init 記述確認"
    - consistency: "PASS - init-guard.sh:17 INIT_DIR と一致"
    - completeness: "PASS - 関連記述全て修正済み"
  - validated: 2026-01-02T18:00:00

- [x] **p2.2**: ARCHITECTURE.md Section 1.5 の `session.sh -> handlers/compact.sh` が直接 `compact.sh` 呼び出しに修正されている
  - executor: codex
  - validations:
    - technical: "PASS - Line 121,169 に直接呼び出し記述確認"
    - consistency: "PASS - settings.json と一致"
    - completeness: "PASS - PreCompact セクション整合"
  - validated: 2026-01-02T18:00:00

- [x] **p2.3**: ARCHITECTURE.md Section 7 の `session.log` が `subagent.log` に修正され、`archive-playbook.sh` 呼び出しが追記されている
  - executor: codex
  - validations:
    - technical: "PASS - subagent.log 確認、session.log 検出なし"
    - consistency: "PASS - subagent-stop.sh 実装と一致"
    - completeness: "PASS - archive-playbook.sh 呼び出し追記済み"
  - validated: 2026-01-02T18:00:00

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証
**depends_on**: [p1, p2]

#### subtasks

- [x] **p_final.1**: bash-check.sh が存在しないスクリプトを呼び出していない
  - executor: claudecode
  - validations:
    - technical: "PASS - 旧パス grep 検出なし"
    - consistency: "PASS - coherence.sh 存在確認済み"
    - completeness: "PASS - bash -n exit 0"
  - validated: 2026-01-02T18:00:00

- [x] **p_final.2**: ARCHITECTURE.md の記述が実装と整合している
  - executor: claudecode
  - validations:
    - technical: "PASS - 3箇所全て grep 確認済み"
    - consistency: "PASS - 各実装ファイルと一致"
    - completeness: "PASS - 全修正対象更新済み"
  - validated: 2026-01-02T18:00:00

- [x] **p_final.3**: bash -n でシンタックスエラーがない
  - executor: claudecode
  - validations:
    - technical: "PASS - bash -n exit 0"
    - consistency: "PASS - 他スクリプトもエラーなし"
    - completeness: "PASS - 副作用なし"
  - validated: 2026-01-02T18:00:00

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
