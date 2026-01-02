# playbook-harness-self-awareness-v3.md

> **v3: SessionStart 連携と auto_fix 適用機能の実装**

---

## meta

```yaml
project: harness-self-awareness-v3
branch: feat/harness-self-awareness
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
  who: "Claude Code（LLM）がセッション開始時に自動実行"
  what: "session-start.sh に coherence-checker 連携を追加し、問題検出時に詳細警告表示 + auto_fix をユーザー承認後に適用"
  when: "各セッション開始時（SessionStart フック発火時）"
  where: ".claude/hooks/session-start.sh、.claude/skills/coherence-checker/"
  why: "v2 で実現した整合性チェック・自動修正提案を、セッション開始時に自動的にフィードバックループとして完成させるため"
  how: "1. session-start.sh から check.sh を呼び出し、2. 問題があれば詳細表示（ファイル一覧含む）、3. severity: low の auto_fix はユーザー承認後に適用"

analysis_result:
  source: prompt-analyzer
  timestamp: 2026-01-03T00:30:00Z
  data:
    risks:
      technical:
        - risk: "SessionStart の遅延"
          severity: medium
          mitigation: "coherence-checker の実行を軽量に保つ（既に軽量）"
      scope:
        - risk: "auto_fix の誤適用"
          severity: low
          mitigation: "ユーザー承認を必須にする"
      dependency:
        - risk: "ARCHITECTURE.md の破損"
          severity: low
          mitigation: "バックアップを取ってから適用"
    ambiguity: []
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-03T00:35:00Z
  summary: "SessionStart 時に coherence-checker を自動実行し、問題検出→詳細表示→auto_fix 適用（ユーザー承認後）のフィードバックループを完成させる"
  approved_items:
    - question_id: q1
      question: "auto_fix の適用方法"
      answer: "ユーザー確認後に適用"
    - question_id: q2
      question: "SessionStart での表示レベル"
      answer: "詳細表示（問題のあるファイル一覧も表示）"
```

---

## goal

```yaml
summary: SessionStart 時に coherence-checker を自動実行し、問題検出→詳細警告→auto_fix 適用（ユーザー承認後）のフィードバックループを完成させる
done_when:
  - session-start.sh が coherence-checker を呼び出し、問題があれば詳細（ファイル一覧含む）を表示する
  - severity: low の auto_fix を適用するスクリプト（apply-fixes.sh）が存在する
  - docs/harness-self-awareness-design.md が v3 の内容で更新されている
```

---

## phases

### p1: session-start.sh 拡張

**goal**: session-start.sh に coherence-checker 連携を追加し、問題があれば詳細警告（ファイル一覧含む）を表示する

#### subtasks

- [x] **p1.1**: session-start.sh が coherence-checker/scripts/check.sh を呼び出している
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 'coherence-checker' session-start.sh で呼び出し確認"
    - consistency: "PASS - check.sh のパスが正しい"
    - completeness: "PASS - エラーハンドリングが含まれている"
  - validated: 2026-01-03T01:00:00Z

- [x] **p1.2**: 問題がある場合に詳細警告（verified/inconsistent/missing の数 + ファイル一覧）が表示される
  - executor: claudecode
  - validations:
    - technical: "PASS - session-start.sh 実行で詳細が表示される"
    - consistency: "PASS - coherence-checker の出力形式と整合"
    - completeness: "PASS - verified/inconsistent/missing + ファイル一覧が表示"
  - validated: 2026-01-03T01:00:00Z

**status**: done
**max_iterations**: 5

---

### p2: auto_fix 適用スクリプト作成

**goal**: severity: low の auto_fix を ARCHITECTURE.md に適用するスクリプトを作成する

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: .claude/skills/coherence-checker/scripts/apply-fixes.sh が存在する
  - executor: claudecode
  - validations:
    - technical: "PASS - test -f で存在確認"
    - consistency: "PASS - check.sh の出力形式に対応"
    - completeness: "PASS - auto_fix の content を ARCHITECTURE.md に追記するロジックあり"
  - validated: 2026-01-03T01:00:00Z

- [x] **p2.2**: apply-fixes.sh はユーザー承認を必須とする
  - executor: claudecode
  - validations:
    - technical: "PASS - スクリプトがインタラクティブに確認を求める"
    - consistency: "PASS - Claude からの呼び出しパターン（非インタラクティブ）に対応"
    - completeness: "PASS - 承認なしには ARCHITECTURE.md を変更しない"
  - validated: 2026-01-03T01:00:00Z

- [x] **p2.3**: apply-fixes.sh が ARCHITECTURE.md のバックアップを作成する
  - executor: claudecode
  - validations:
    - technical: "PASS - バックアップファイル作成ロジック確認"
    - consistency: "PASS - バックアップファイル名が一貫（ARCHITECTURE.md.backup.TIMESTAMP）"
    - completeness: "PASS - 適用前にバックアップが作成される"
  - validated: 2026-01-03T01:00:00Z

**status**: done
**max_iterations**: 5

---

### p3: 設計ドキュメント更新

**goal**: docs/harness-self-awareness-design.md を v3 の内容で更新する

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: docs/harness-self-awareness-design.md に v3 セクションが追加されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 'v3' で存在確認"
    - consistency: "PASS - 既存の v1/v2 セクションとの整合性OK"
    - completeness: "PASS - SessionStart 連携と auto_fix 適用フローが記載"
  - validated: 2026-01-03T01:00:00Z

- [x] **p3.2**: 変更履歴が更新されている
  - executor: claudecode
  - validations:
    - technical: "PASS - 変更履歴セクションに 2026-01-03 の記録あり"
    - consistency: "PASS - 既存の変更履歴フォーマットとの整合性OK"
    - completeness: "PASS - v3 の主要変更点（SessionStart 連携、apply-fixes.sh）が記載"
  - validated: 2026-01-03T01:00:00Z

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p3]

#### subtasks

- [x] **p_final.1**: session-start.sh が coherence-checker を呼び出し、問題があれば詳細（ファイル一覧含む）を表示する
  - executor: claudecode
  - validations:
    - technical: "PASS - session-start.sh 実行で出力確認"
    - consistency: "PASS - coherence-checker の出力と整合性OK"
    - completeness: "PASS - verified/inconsistent/missing + ファイル一覧が表示"
  - validated: 2026-01-03T01:00:00Z

- [x] **p_final.2**: severity: low の auto_fix を適用するスクリプト（apply-fixes.sh）が存在する
  - executor: claudecode
  - validations:
    - technical: "PASS - test -f で存在確認"
    - consistency: "PASS - check.sh の出力形式に対応"
    - completeness: "PASS - ユーザー承認 + バックアップ + 適用のフローが実装"
  - validated: 2026-01-03T01:00:00Z

- [x] **p_final.3**: docs/harness-self-awareness-design.md が v3 の内容で更新されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 'v3' で存在確認"
    - consistency: "PASS - v1/v2 との整合性OK"
    - completeness: "PASS - SessionStart 連携と auto_fix 適用フローが記載"
  - validated: 2026-01-03T01:00:00Z

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

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-03 | 初版作成（v3: SessionStart 連携と auto_fix 適用機能） |
