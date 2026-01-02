# playbook-precompact-debug-log.md

> **PreCompact Hook のデバッグログ追加**

---

## meta

```yaml
project: precompact-debug-log
branch: fix/restore-demo-files
created: 2026-01-02
issue: null
reviewed: true
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: PreCompact Hook（compact.sh）に絶対パス版デバッグログ出力を追加し、Hook 動作を検証可能にする
done_when:
  - compact.sh の33行目（mkdir -p "$INIT_DIR"）直後にデバッグログコードが追加されている
  - evidence/precompact-debug.log にログが出力される仕組みが実装されている
```

---

## context

```yaml
5w1h:
  who: 開発者（デバッグ目的）
  what: compact.sh に絶対パス版デバッグログ出力を追加
  when: 今すぐ実施
  where: .claude/skills/session-manager/handlers/compact.sh
  why: PreCompact Hook が /compact 実行時に snapshot.json を作成しているか検証するため
  how: 指定されたデバッグログコードを挿入（33行目直後）

analysis_result:
  source: inline-analysis
  timestamp: 2026-01-02T10:00:00Z
  data:
    risks:
      technical: []
      scope: []
      dependency: []
    ambiguity: []
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-02T10:00:00Z
  summary: "compact.sh に指定されたデバッグログコードを追加する単純なタスク"
```

---

## phases

### p1: デバッグログコード追加

**goal**: compact.sh にデバッグログ出力コードを挿入する

#### subtasks

- [ ] **p1.1**: compact.sh の33行目（mkdir -p "$INIT_DIR"）直後にデバッグログコードが存在する
  - executor: claudecode
  - validations:
    - technical: "grep 'DEBUG_LOG=' compact.sh でコードが存在することを確認"
    - consistency: "既存のスクリプト構造と整合性があること"
    - completeness: "全てのデバッグ情報（date, pwd, REPO_ROOT, trigger, SNAPSHOT_FILE）が出力されること"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証（必須）

**goal**: done_when が全て満たされているか最終検証
**depends_on**: [p1]

#### subtasks

- [ ] **p_final.1**: compact.sh にデバッグログコードが追加されている
  - executor: claudecode
  - validations:
    - technical: "grep -A10 'デバッグログ' compact.sh で該当コードを確認"
    - consistency: "追加位置が33行目直後（mkdir -p の直後）であること"
    - completeness: "evidence/ ディレクトリ作成とログ出力ロジックが含まれること"

- [ ] **p_final.2**: スクリプトにシンタックスエラーがない
  - executor: claudecode
  - validations:
    - technical: "bash -n compact.sh で exit 0"
    - consistency: "他のシェルスクリプトと同様の構文であること"
    - completeness: "全行がパース可能であること"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: 変更をコミットする
  - command: `git add -A && git status`
  - status: pending
