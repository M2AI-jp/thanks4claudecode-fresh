# playbook-e2e-verification-timestamp.md

---

## meta

```yaml
project: e2e-verification-timestamp
branch: test/e2e-verification
created: 2025-12-25
issue: null
reviewed: true
```

---

## goal

```yaml
summary: docs/BASELINE.md に E2E 検証完了タイムスタンプを追加する
done_when:
  - docs/BASELINE.md の検証済み状態セクション（セクション5）に E2E 検証完了タイムスタンプが追加されている
  - タイムスタンプは ISO 8601 形式（YYYY-MM-DD）である
```

---

## phases

### p1: E2E 検証タイムスタンプ追加

**goal**: docs/BASELINE.md に E2E 検証完了タイムスタンプを追記する

#### subtasks

- [x] **p1.1**: docs/BASELINE.md の検証済み状態セクションに E2E 検証タイムスタンプが存在する
  - executor: claudecode
  - validations:
    - technical: "grep で 'e2e_verification' または同等のタイムスタンプ行が存在することを確認"
    - consistency: "既存のセクション5（検証済み状態）の YAML 形式と整合性がある"
    - completeness: "タイムスタンプが ISO 8601 形式（YYYY-MM-DD）である"

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: done_when が全て満たされているか最終検証

**depends_on**: [p1]

#### subtasks

- [x] **p_final.1**: docs/BASELINE.md の検証済み状態セクション（セクション5）に E2E 検証完了タイムスタンプが追加されている
  - executor: claudecode
  - validations:
    - technical: "grep で e2e_verification または last_verified 等のタイムスタンプ行を確認"
    - consistency: "セクション5 の YAML 構造と整合性がある"
    - completeness: "E2E 検証の記録として十分な情報が含まれている"

- [x] **p_final.2**: タイムスタンプは ISO 8601 形式（YYYY-MM-DD）である
  - executor: claudecode
  - validations:
    - technical: "grep -E '[0-9]{4}-[0-9]{2}-[0-9]{2}' で形式を確認"
    - consistency: "既存のタイムスタンプ形式と一致している"
    - completeness: "日付が今日（2025-12-25）である"

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
