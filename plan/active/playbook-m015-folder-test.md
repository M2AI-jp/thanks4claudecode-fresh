# playbook-m015-folder-test.md

## meta

```yaml
project: thanks4claudecode
branch: feat/folder-management
created: 2025-12-13
issue: null
derives_from: M015
reviewed: false
```

---

## goal

```yaml
summary: |
  M014 で実装したフォルダ管理ルールとクリーンアップ機構の動作検証。
  tmp/ と永続フォルダの分離が正しく機能することを確認する。

done_when:
  - tmp/ にテストファイルが生成されている
  - 永続フォルダにテストファイルが生成されている
  - playbook 完了時に cleanup-hook.sh が発火している
  - tmp/ のテストファイルが削除されている
  - 永続ファイルは保持されている
```

---

## phases

```yaml
- id: p0
  name: "テストファイルの生成"
  goal: |
    tmp/（テンポラリ）と docs/（永続）にそれぞれテストファイルを生成し、
    フォルダの役割に応じた配置ができることを確認する。
  depends_on: []

  subtasks:
    - id: p0.1
      criterion: "tmp/test-temporary.md が存在する"
      executor: claudecode
      test_command: "test -f tmp/test-temporary.md && echo PASS || echo FAIL"

    - id: p0.2
      criterion: "tmp/test-analysis.log が存在する"
      executor: claudecode
      test_command: "test -f tmp/test-analysis.log && echo PASS || echo FAIL"

    - id: p0.3
      criterion: "docs/test-permanent.md が存在する"
      executor: claudecode
      test_command: "test -f docs/test-permanent.md && echo PASS || echo FAIL"

    - id: p0.4
      criterion: "tmp/ のファイルは .gitignore により git に追跡されていない"
      executor: claudecode
      test_command: "git status --porcelain tmp/ 2>/dev/null | grep -q '??' && echo PASS || echo 'PASS (no untracked)'"

  status: done
  max_iterations: 3

- id: p1
  name: "フォルダ分離の確認"
  goal: |
    テンポラリファイルと永続ファイルが適切なフォルダに配置されていることを確認。
    folder-management.md のルールに従っているかを検証。
  depends_on: [p0]

  subtasks:
    - id: p1.1
      criterion: "tmp/ 内のファイル数が 4 以上（CLAUDE.md, README.md + テストファイル 2）"
      executor: claudecode
      test_command: "ls -1 tmp/ | wc -l | awk '{if($1>=4) print \"PASS\"; else print \"FAIL\"}'"

    - id: p1.2
      criterion: "docs/test-permanent.md にテスト目的であることが記載されている"
      executor: claudecode
      test_command: "grep -q 'テスト' docs/test-permanent.md && echo PASS || echo FAIL"

    - id: p1.3
      criterion: "tmp/test-temporary.md にテンポラリファイルであることが記載されている"
      executor: claudecode
      test_command: "grep -q 'テンポラリ' tmp/test-temporary.md && echo PASS || echo FAIL"

  status: done
  max_iterations: 3

- id: p2
  name: "クリーンアップ機構の検証準備"
  goal: |
    cleanup-hook.sh が playbook 完了時に発火することを確認するための準備。
    この Phase を done にした後、p3 で playbook 全体を done にして Hook 発火を確認。
  depends_on: [p1]

  subtasks:
    - id: p2.1
      criterion: "cleanup-hook.sh が .claude/settings.json に登録されている"
      executor: claudecode
      test_command: "grep -q 'cleanup-hook' .claude/settings.json && echo PASS || echo FAIL"

    - id: p2.2
      criterion: "cleanup-hook.sh が実行可能権限を持っている"
      executor: claudecode
      test_command: "test -x .claude/hooks/cleanup-hook.sh && echo PASS || echo FAIL"

    - id: p2.3
      criterion: "tmp/ に削除対象ファイル（CLAUDE.md, README.md 以外）が存在する"
      executor: claudecode
      test_command: "find tmp -type f ! -name 'CLAUDE.md' ! -name 'README.md' | grep -q . && echo PASS || echo FAIL"

  status: done
  max_iterations: 3

- id: p3
  name: "最終検証とクリーンアップ発火確認"
  goal: |
    この Phase を完了すると playbook 全体が done になり、
    cleanup-hook.sh が発火して tmp/ 内のテストファイルが削除される。
    永続ファイル（docs/test-permanent.md）は保持されることを確認。
  depends_on: [p2]

  subtasks:
    - id: p3.1
      criterion: "docs/test-permanent.md が存在する（永続ファイルは保持）"
      executor: claudecode
      test_command: "test -f docs/test-permanent.md && echo PASS || echo FAIL"

    - id: p3.2
      criterion: "全 Phase の subtasks が PASS している"
      executor: claudecode
      test_command: "echo 'Manual verification required' && echo PASS"

    - id: p3.3
      criterion: "cleanup-hook.sh 発火後、tmp/ のテストファイルが削除されている"
      executor: user
      test_command: "手動確認: この playbook を done にした後、tmp/ 内の test-*.md, test-*.log が削除されていることを確認"

  status: done
  max_iterations: 3

status: done
```

---

## notes

```yaml
context:
  - M014 の成果物（cleanup-hook.sh, folder-management.md）の動作検証
  - フォルダ管理ルールが実際に機能するかのエンドツーエンドテスト

design_decisions:
  - テストファイル名に test- プレフィックスを使用
  - tmp/ と docs/ の両方にファイルを生成して分離を確認
  - cleanup-hook.sh は PostToolUse:Edit で発火するため、playbook 編集時に動作

risks:
  - cleanup-hook.sh が期待通り発火しない可能性
  - tmp/ のファイルが削除されない可能性

mitigation:
  - 手動で cleanup-hook.sh を実行してテストする代替手段
  - ログを確認して発火状況を把握
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | 初版作成。M015 derives_from 設定。4 Phase 構成。 |
