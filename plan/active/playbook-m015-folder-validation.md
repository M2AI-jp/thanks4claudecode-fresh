# playbook-m015-folder-validation.md

> **M015: フォルダ管理ルール検証テスト**
>
> M014 で実装したフォルダ管理ルールとクリーンアップ機構の動作を検証する playbook

---

## meta

```yaml
project: thanks4claudecode
branch: feat/m015-folder-validation
created: 2025-12-14
issue: null
derives_from: M015
reviewed: false
```

---

## goal

```yaml
summary: M014 の実装したフォルダ管理ルール（tmp/ / docs/ / cleanup-hook.sh）が正しく動作することを検証
done_when:
  - tmp/ ディレクトリが存在し .gitignore に登録されている
  - cleanup-hook.sh が実行可能で構文エラーがない
  - docs/folder-management.md が存在し重要セクションが含まれている
```

---

## phases

### p0: フォルダ構造の検証

**目標**: tmp/ フォルダが存在し、.gitignore に正しく登録されていることを確認

```yaml
id: p0
name: "フォルダ構造の検証"
goal: "tmp/ ディレクトリが存在し、.gitignore に登録されていることを確認"

subtasks:
  - id: p0.1
    criterion: "tmp/ ディレクトリが存在する"
    executor: claudecode
    test_command: "test -d tmp && echo PASS || echo FAIL"

  - id: p0.2
    criterion: ".gitignore に tmp/ が登録されている"
    executor: claudecode
    test_command: "grep -q '^tmp/$' .gitignore && echo PASS || echo FAIL"

  - id: p0.3
    criterion: "tmp/ 内に CLAUDE.md が存在する"
    executor: claudecode
    test_command: "test -f tmp/CLAUDE.md && echo PASS || echo FAIL"

  - id: p0.4
    criterion: "tmp/ 内に README.md が存在する"
    executor: claudecode
    test_command: "test -f tmp/README.md && echo PASS || echo FAIL"

status: pending
max_iterations: 5
```

---

### p1: クリーンアップスクリプトの検証

**目標**: cleanup-hook.sh が実行可能で、構文エラーがないことを確認

```yaml
id: p1
name: "クリーンアップスクリプトの検証"
goal: "cleanup-hook.sh が実行可能で、Bash 構文が正しいことを確認"
depends_on: [p0]

subtasks:
  - id: p1.1
    criterion: "cleanup-hook.sh ファイルが存在する"
    executor: claudecode
    test_command: "test -f .claude/hooks/cleanup-hook.sh && echo PASS || echo FAIL"

  - id: p1.2
    criterion: "cleanup-hook.sh が実行可能である"
    executor: claudecode
    test_command: "[ -x .claude/hooks/cleanup-hook.sh ] && echo PASS || echo FAIL"

  - id: p1.3
    criterion: "cleanup-hook.sh に Bash 構文エラーがない"
    executor: claudecode
    test_command: "bash -n .claude/hooks/cleanup-hook.sh && echo PASS || echo FAIL"

  - id: p1.4
    criterion: "cleanup-hook.sh に set -e が指定されている"
    executor: claudecode
    test_command: "head -20 .claude/hooks/cleanup-hook.sh | grep -q '^set -e$' && echo PASS || echo FAIL"

  - id: p1.5
    criterion: "cleanup-hook.sh に PlaybookComplete 検出ロジックが存在する"
    executor: claudecode
    test_command: "grep -q 'Phase status' .claude/hooks/cleanup-hook.sh && echo PASS || echo FAIL"

status: pending
max_iterations: 5
```

---

### p2: ドキュメント完全性の検証

**目標**: docs/folder-management.md が存在し、必要なセクションが含まれていることを確認

```yaml
id: p2
name: "ドキュメント完全性の検証"
goal: "docs/folder-management.md が存在し、重要セクション（tmp/, cleanup, 永続フォルダ）が記載されていることを確認"
depends_on: [p1]

subtasks:
  - id: p2.1
    criterion: "docs/folder-management.md ファイルが存在する"
    executor: claudecode
    test_command: "test -f docs/folder-management.md && echo PASS || echo FAIL"

  - id: p2.2
    criterion: "docs/folder-management.md に『基本原則』セクションが存在する"
    executor: claudecode
    test_command: "grep -q '基本原則' docs/folder-management.md && echo PASS || echo FAIL"

  - id: p2.3
    criterion: "docs/folder-management.md に『tmp/』に関する説明が存在する"
    executor: claudecode
    test_command: "grep -q 'tmp/' docs/folder-management.md && echo PASS || echo FAIL"

  - id: p2.4
    criterion: "docs/folder-management.md に『クリーンアップ』セクションが存在する"
    executor: claudecode
    test_command: "grep -q 'クリーンアップ' docs/folder-management.md && echo PASS || echo FAIL"

  - id: p2.5
    criterion: "docs/folder-management.md に『playbook 完了時の流れ』が記載されている"
    executor: claudecode
    test_command: "grep -q 'playbook 完了時' docs/folder-management.md && echo PASS || echo FAIL"

  - id: p2.6
    criterion: "docs/folder-management.md に『テンポラリ vs 永続』セクションが存在する"
    executor: claudecode
    test_command: "grep -q 'テンポラリ vs 永続' docs/folder-management.md && echo PASS || echo FAIL"

  - id: p2.7
    criterion: "docs/folder-management.md の行数が50行以上である"
    executor: claudecode
    test_command: "wc -l docs/folder-management.md | awk '{if($1>=50) print \"PASS\"; else print \"FAIL\"}'"

status: pending
max_iterations: 5
```

---

### p3: 統合検証（cleanup-hook.sh の連携確認）

**目標**: cleanup-hook.sh と docs/folder-management.md が整合性を持ち、ドキュメントで説明されたロジックが実装されていることを確認

```yaml
id: p3
name: "統合検証：cleanup-hook.sh と ドキュメントの整合性確認"
goal: "cleanup-hook.sh がドキュメントで説明されたロジック通りに実装されていることを確認"
depends_on: [p2]

subtasks:
  - id: p3.1
    criterion: "cleanup-hook.sh と docs/folder-management.md の両方に CLAUDE.md と README.md を保持する旨が記載されている"
    executor: claudecode
    test_command: |
      bash -c '
      HOOK_MENTION=$(grep -c "CLAUDE.md\|README.md" .claude/hooks/cleanup-hook.sh || echo 0)
      DOC_MENTION=$(grep -c "CLAUDE.md\|README.md" docs/folder-management.md || echo 0)
      [ "$HOOK_MENTION" -gt 0 ] && [ "$DOC_MENTION" -gt 0 ] && echo PASS || echo FAIL
      '

  - id: p3.2
    criterion: "cleanup-hook.sh にエラー処理（set -e）が適切に設定されている"
    executor: claudecode
    test_command: "head -25 .claude/hooks/cleanup-hook.sh | grep -q 'set -e' && echo PASS || echo FAIL"

  - id: p3.3
    criterion: "cleanup-hook.sh に state.md の存在チェック処理が実装されている"
    executor: claudecode
    test_command: "grep -q 'state.md' .claude/hooks/cleanup-hook.sh && echo PASS || echo FAIL"

  - id: p3.4
    criterion: "docs/folder-management.md に cleanup-hook.sh への参照が存在する"
    executor: claudecode
    test_command: "grep -q 'cleanup-hook.sh' docs/folder-management.md && echo PASS || echo FAIL"

status: pending
max_iterations: 5
```

---

## 検証結果の出力

すべての subtask が PASS したら、以下の検証結果をまとめて出力します：

```
✅ M015 検証完了

フォルダ構造:
  - tmp/ ディレクトリ: OK
  - .gitignore 登録: OK
  - tmp/CLAUDE.md: OK
  - tmp/README.md: OK

クリーンアップスクリプト:
  - cleanup-hook.sh 存在: OK
  - 実行可能性: OK
  - Bash 構文: OK
  - set -e 設定: OK
  - 検出ロジック: OK

ドキュメント:
  - docs/folder-management.md 存在: OK
  - 基本原則セクション: OK
  - tmp/ 説明: OK
  - クリーンアップセクション: OK
  - playbook 完了時の流れ: OK
  - テンポラリ vs 永続: OK
  - 行数 (50行以上): OK

統合検証:
  - CLAUDE.md/README.md 保持ルール: OK
  - エラー処理: OK
  - state.md チェック: OK
  - cleanup-hook.sh 参照: OK
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-14 | playbook-m015-folder-validation.md 作成。4 Phase + 22 subtask の検証テスト。 |
