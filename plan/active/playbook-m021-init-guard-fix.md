# playbook-m021-init-guard-fix.md

> **M021: init-guard.sh デッドロック修正 - playbook=null 時の基本コマンド許可**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/m021-init-guard-fix
created: 2025-12-14
issue: null
derives_from: M021
reviewed: false
```

---

## goal

```yaml
summary: init-guard.sh で基本 Bash コマンドが playbook=null 時にブロックされる問題を修正。sed/grep/cat/echo/ls/wc と git コマンドが許可されるようにする。
done_when:
  - init-guard.sh に基本コマンド許可リスト（sed/grep/cat/echo/ls/wc）がある
  - git show / git log / git diff が許可されている
  - session-start.sh に CORE セクションが存在する
```

---

## phases

- id: p0
  name: 現状分析と要件確認
  goal: init-guard.sh の現在の実装を確認し、デッドロックの原因を特定する

  subtasks:
    - id: p0.1
      criterion: "init-guard.sh の Bash コマンドブロック部分（125-161行）を読んだ"
      executor: claudecode
      test_command: "grep -n 'COMMAND=.*jq' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/init-guard.sh && echo PASS || echo FAIL"

    - id: p0.2
      criterion: "playbook=null 時に許可すべきコマンド（sed/grep/cat/echo/ls/wc）のリストを作成"
      executor: claudecode
      test_command: "test -f /tmp/allowed-commands.txt && grep -q 'sed' /tmp/allowed-commands.txt && echo PASS || echo FAIL"

    - id: p0.3
      criterion: "session-start.sh が CORE セクションを持つか確認"
      executor: claudecode
      test_command: "grep -q 'CORE セクション' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/session-start.sh && echo PASS || echo FAIL"

  status: pending
  max_iterations: 5

- id: p1
  name: init-guard.sh 修正 - 基本コマンド許可リスト追加
  goal: playbook=null 時に sed/grep/cat/echo/ls/wc などの基本的な情報収集コマンドを許可する
  depends_on: [p0]

  subtasks:
    - id: p1.1
      criterion: "init-guard.sh の125-161行目に基本コマンド許可ロジックが追加されている"
      executor: claudecode
      test_command: "grep -A2 'sed.*grep.*cat.*echo' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/init-guard.sh && echo PASS || echo FAIL"

    - id: p1.2
      criterion: "sed/grep/cat/echo/ls/wc が個別にチェックされている"
      executor: claudecode
      test_command: "grep -E '(sed|grep|cat|echo|ls|wc)' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/init-guard.sh | wc -l | awk '{if($1>=5) print \"PASS\"; else print \"FAIL\"}'"

    - id: p1.3
      criterion: "基本コマンド許可後も playbook=null チェックは有効"
      executor: claudecode
      test_command: "grep -q 'playbook.*null' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/init-guard.sh && grep -q 'Task.*pm' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/init-guard.sh && echo PASS || echo FAIL"

  status: pending
  max_iterations: 5

- id: p2
  name: init-guard.sh 修正 - git コマンド許可拡張
  goal: git show / git log / git diff などの git コマンドを許可する
  depends_on: [p1]

  subtasks:
    - id: p2.1
      criterion: "init-guard.sh に git show / git log / git diff の許可ロジックが追加"
      executor: claudecode
      test_command: "grep -E 'git.*(show|log|diff)' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/init-guard.sh && echo PASS || echo FAIL"

    - id: p2.2
      criterion: "git status/branch/rev-parse も引き続き許可されている"
      executor: claudecode
      test_command: "grep -E 'git.*(status|branch|rev-parse)' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/init-guard.sh && echo PASS || echo FAIL"

    - id: p2.3
      criterion: "修正後の init-guard.sh が bash 構文チェックに通る"
      executor: claudecode
      test_command: "bash -n /Users/amano/Desktop/thanks4claudecode/.claude/hooks/init-guard.sh && echo PASS || echo FAIL"

  status: pending
  max_iterations: 5

- id: p3
  name: session-start.sh に CORE セクション追加
  goal: コンテキスト汚染を防ぐため session-start.sh に CORE セクションを追加
  depends_on: [p2]

  subtasks:
    - id: p3.1
      criterion: "session-start.sh に「CORE セクション」というコメントが存在"
      executor: claudecode
      test_command: "grep -q 'CORE' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/session-start.sh && echo PASS || echo FAIL"

    - id: p3.2
      criterion: "CORE セクションに state/project/playbook の役割が説明されている"
      executor: claudecode
      test_command: "grep -A5 'CORE' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/session-start.sh | grep -E '(state|project|playbook)' && echo PASS || echo FAIL"

    - id: p3.3
      criterion: "修正後の session-start.sh が bash 構文チェックに通る"
      executor: claudecode
      test_command: "bash -n /Users/amano/Desktop/thanks4claudecode/.claude/hooks/session-start.sh && echo PASS || echo FAIL"

  status: pending
  max_iterations: 5

- id: p4
  name: 動作確認とテスト
  goal: 修正後の init-guard.sh と session-start.sh が期待通りに動作することを確認
  depends_on: [p3]

  subtasks:
    - id: p4.1
      criterion: "init-guard.sh で sed コマンドを実行してもブロックされない"
      executor: claudecode
      test_command: "手動確認: pm SubAgent が sed コマンドを使用できることを確認"

    - id: p4.2
      criterion: "init-guard.sh で grep コマンドを実行してもブロックされない"
      executor: claudecode
      test_command: "手動確認: pm SubAgent が grep コマンドを使用できることを確認"

    - id: p4.3
      criterion: "git show / git log が許可されている"
      executor: claudecode
      test_command: "手動確認: pm SubAgent が git show を実行できることを確認"

    - id: p4.4
      criterion: "playbook=null 時に pm 以外はブロックされている"
      executor: claudecode
      test_command: "手動確認: Edit/Write がまだブロックされていることを確認"

  status: pending
  max_iterations: 5

- id: p5
  name: コミット & PR 作成
  goal: 修正内容をコミットし、main にマージ
  depends_on: [p4]

  subtasks:
    - id: p5.1
      criterion: "feat/m021-init-guard-fix ブランチが存在し、修正内容がコミットされている"
      executor: claudecode
      test_command: "git branch | grep -q 'm021' && git log --oneline | head -1 | grep -q 'm021' && echo PASS || echo FAIL"

    - id: p5.2
      criterion: "修正ファイル（init-guard.sh, session-start.sh）がコミットに含まれている"
      executor: claudecode
      test_command: "git show HEAD --name-only | grep -E '(init-guard|session-start)' && echo PASS || echo FAIL"

    - id: p5.3
      criterion: "main ブランチにマージされている"
      executor: claudecode
      test_command: "git branch -a | grep -q 'main' && git log main --oneline | head -1 | grep -q 'm021' && echo PASS || echo FAIL"

  status: pending
  max_iterations: 5

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-14 | 初版作成。M021 playbook を定義。5 Phase で init-guard.sh と session-start.sh を修正。 |
