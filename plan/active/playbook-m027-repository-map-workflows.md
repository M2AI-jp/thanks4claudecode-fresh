# playbook-m027-repository-map-workflows.md

> **repository-map.yaml 拡張：Hook トリガーシーケンスと Workflows セクション追加**
>
> 現在の repository-map.yaml は構造的なマップを提供するが、
> Hook の発火順序が system_specification に埋め込まれており、二重管理状態にある。
> これを解消し、hook_trigger_sequence と workflows セクションで Hook の連鎖を明示的に管理する。

---

## meta

```yaml
project: thanks4claudecode
branch: feat/m027-repository-map-workflows
created: 2025-12-22
issue: null
derives_from: M027
reviewed: false
```

---

## goal

```yaml
summary: repository-map.yaml を拡張し、Hook トリガーシーケンスと Workflows セクションを追加して、システムの構造と動作フローを一元管理できるようにする
done_when:
  - hook_trigger_sequence セクションが公式ドキュメント準拠で実装されている
  - 各トリガー（SessionStart → UserPromptSubmit → PreToolUse → PostToolUse → Stop → PreCompact → SessionEnd）が正しい発火順序でソートされている
  - workflows セクションが組み合わせモジュール単位で整理されている
  - 各 workflow に id, name, why, when, input, process, output, references が定義されている
  - generate-repository-map.sh に workflows 自動生成ロジック（heredoc）が統合されている
  - commands と skills の違いが明示されている（呼び出し方式の区別）
  - repository-map.yaml の自動生成が冪等性を保持している
```

---

## phases

```yaml
- id: p0
  name: 設計フェーズ：Hook トリガーシーケンスと Workflows 設計
  goal: 公式ドキュメント（https://code.claude.com/docs/ja/hooks）に基づいて Hook トリガーシーケンスの構造と Workflows セクションの詳細設計を行う

  subtasks:
    - id: p0.1
      criterion: "公式 Hook トリガーシーケンス仕様が tmp/m027-hook-sequence-spec.md に記載されている"
      executor: claudecode
      test_command: "test -f tmp/m027-hook-sequence-spec.md && grep -q 'SessionStart\\|UserPromptSubmit\\|PreToolUse' tmp/m027-hook-sequence-spec.md && echo PASS || echo FAIL"

    - id: p0.2
      criterion: "settings.json から Hook の登録情報を解析する方法が定義されている"
      executor: claudecode
      test_command: "test -f tmp/m027-hook-sequence-spec.md && grep -q 'settings.json' tmp/m027-hook-sequence-spec.md && echo PASS || echo FAIL"

    - id: p0.3
      criterion: "Workflows セクションの構造（id, name, why, when, input, process, output, references）が決定されている"
      executor: claudecode
      test_command: "test -f tmp/m027-hook-sequence-spec.md && grep -qE '(id|name|why|when|input|process|output|references)' tmp/m027-hook-sequence-spec.md && echo PASS || echo FAIL"

    - id: p0.4
      criterion: "Workflows に含まれる組み合わせモジュール（INIT, LOOP, POST_LOOP, 等）が列挙されている"
      executor: claudecode
      test_command: "test -f tmp/m027-hook-sequence-spec.md && grep -qE '(INIT|LOOP|POST_LOOP)' tmp/m027-hook-sequence-spec.md && echo PASS || echo FAIL"

    - id: p0.5
      criterion: "Commands（/command）と Skills（自動検出）の区別方法が明示されている"
      executor: claudecode
      test_command: "test -f tmp/m027-hook-sequence-spec.md && grep -qE '(Commands|Skills)' tmp/m027-hook-sequence-spec.md && echo PASS || echo FAIL"

  status: done
  max_iterations: 3

- id: p1
  name: hook_trigger_sequence セクション実装
  goal: settings.json から Hook 情報を読み込み、公式トリガー順でソートして hook_trigger_sequence を生成する
  depends_on: [p0]

  subtasks:
    - id: p1.1
      criterion: "generate-repository-map.sh に settings.json 解析機能が実装されている"
      executor: claudecode
      test_command: "grep -q 'settings.json' .claude/hooks/generate-repository-map.sh && grep -qE '(jq|grep).*hooks' .claude/hooks/generate-repository-map.sh && echo PASS || echo FAIL"

    - id: p1.2
      criterion: "トリガー順序が正しい（SessionStart → UserPromptSubmit → PreToolUse → PostToolUse → Stop → PreCompact → SessionEnd）"
      executor: claudecode
      test_command: "grep -q 'SessionStart' docs/repository-map.yaml && grep -A 100 'hook_trigger_sequence' docs/repository-map.yaml | grep -q 'UserPromptSubmit' && echo PASS || echo FAIL"

    - id: p1.3
      criterion: "各トリガーの下に登録された Hook が一覧化されている"
      executor: claudecode
      test_command: "grep -A 50 'PreToolUse' docs/repository-map.yaml | grep -qE '(init-guard|consent-guard)' && echo PASS || echo FAIL"

    - id: p1.4
      criterion: "Hook のトリガー（matcher フィールド）が正確に記載されている"
      executor: claudecode
      test_command: "grep -q 'PreToolUse:Edit' docs/repository-map.yaml && echo PASS || echo FAIL"

    - id: p1.5
      criterion: "hook_trigger_sequence セクションが YAML 形式で正しく記述されている"
      executor: claudecode
      test_command: "grep -q 'hook_trigger_sequence:' docs/repository-map.yaml && echo PASS || echo FAIL"

  status: pending
  max_iterations: 5

- id: p2
  name: workflows セクション実装
  goal: 組み合わせモジュール単位で Workflows を整理し、generate-repository-map.sh に組み込む
  depends_on: [p1]

  subtasks:
    - id: p2.1
      criterion: "INIT Workflow が定義されている（セッション開始フロー）"
      executor: claudecode
      test_command: "grep -q 'name: INIT' docs/repository-map.yaml && grep -A 30 'name: INIT' docs/repository-map.yaml | grep -qE '(why|when|input|process|output)' && echo PASS || echo FAIL"

    - id: p2.2
      criterion: "LOOP Workflow が定義されている（作業ループフロー）"
      executor: claudecode
      test_command: "grep -q 'name: LOOP' docs/repository-map.yaml && grep -A 30 'name: LOOP' docs/repository-map.yaml | grep -q 'subtasks' && echo PASS || echo FAIL"

    - id: p2.3
      criterion: "POST_LOOP Workflow が定義されている（playbook 完了フロー）"
      executor: claudecode
      test_command: "grep -q 'name: POST_LOOP' docs/repository-map.yaml && grep -A 30 'name: POST_LOOP' docs/repository-map.yaml | grep -q 'archive' && echo PASS || echo FAIL"

    - id: p2.4
      criterion: "各 Workflow に references（参照ドキュメント）が記載されている"
      executor: claudecode
      test_command: "grep -A 50 'workflows:' docs/repository-map.yaml | grep -q 'references' && echo PASS || echo FAIL"

    - id: p2.5
      criterion: "Workflows の process セクションに hooks、subagents、skills が列挙されている"
      executor: claudecode
      test_command: "grep -A 100 'workflows:' docs/repository-map.yaml | grep -qE '(hooks|subagents|skills)' && echo PASS || echo FAIL"

    - id: p2.6
      criterion: "generate-repository-map.sh に Workflows 生成ロジック（heredoc）が実装されている"
      executor: claudecode
      test_command: "grep -q '<<EOF' .claude/hooks/generate-repository-map.sh && grep -q 'workflows:' .claude/hooks/generate-repository-map.sh && echo PASS || echo FAIL"

  status: pending
  max_iterations: 5

- id: p3
  name: Commands と Skills の明確化
  goal: Commands（ユーザー呼び出し）と Skills（モデル呼び出し）の違いを repository-map.yaml で明示する
  depends_on: [p2]

  subtasks:
    - id: p3.1
      criterion: "commands セクションに description が明示的に記載されている（呼び出し方式： /command）"
      executor: claudecode
      test_command: "grep -A 30 'commands:' docs/repository-map.yaml | grep -q '/crit\\|/focus\\|/task-start' && echo PASS || echo FAIL"

    - id: p3.2
      criterion: "skills セクションに auto_invoke フラグが記載されている（自動検出方式）"
      executor: claudecode
      test_command: "grep -A 30 'skills:' docs/repository-map.yaml | grep -qE '(auto_invoke|subagent)' && echo PASS || echo FAIL"

    - id: p3.3
      criterion: "Commands と Skills の使用場面が説明されている"
      executor: claudecode
      test_command: "grep -B 5 'commands:' docs/repository-map.yaml | grep -q 'description' && echo PASS || echo FAIL"

  status: pending
  max_iterations: 3

- id: p4
  name: generate-repository-map.sh への workflows 統合
  goal: generate-repository-map.sh に Workflows セクション自動生成ロジックを統合し、冪等性を保証する
  depends_on: [p3]

  subtasks:
    - id: p4.1
      criterion: "generate-repository-map.sh が repository-map.yaml を自動生成する際に workflows セクションを含める"
      executor: claudecode
      test_command: "bash .claude/hooks/generate-repository-map.sh > /tmp/test-repo-map.yaml 2>/dev/null && grep -q 'workflows:' /tmp/test-repo-map.yaml && echo PASS || echo FAIL"

    - id: p4.2
      criterion: "生成された repository-map.yaml が YAML 形式として有効である（yamllint パス）"
      executor: claudecode
      test_command: "bash .claude/hooks/generate-repository-map.sh > /tmp/test-repo-map.yaml 2>/dev/null && python3 -c 'import yaml; yaml.safe_load(open(\"/tmp/test-repo-map.yaml\"))' 2>/dev/null && echo PASS || echo FAIL"

    - id: p4.3
      criterion: "複数回実行した repository-map.yaml の内容が同じである（冪等性）"
      executor: claudecode
      test_command: "bash .claude/hooks/generate-repository-map.sh > /tmp/repo1.yaml && bash .claude/hooks/generate-repository-map.sh > /tmp/repo2.yaml && diff -u /tmp/repo1.yaml /tmp/repo2.yaml | wc -l | awk '{if($1<=3) print \"PASS\"; else print \"FAIL\"}'"

    - id: p4.4
      criterion: "Workflows が settings.json に基づいて自動生成される（手動編集不要）"
      executor: claudecode
      test_command: "grep -q 'settings.json' .claude/hooks/generate-repository-map.sh && grep -q 'workflows' .claude/hooks/generate-repository-map.sh && echo PASS || echo FAIL"

  status: pending
  max_iterations: 5

- id: p5
  name: 統合テストと検証
  goal: 拡장된 repository-map.yaml が全ての仕様を満たすことを検証する
  depends_on: [p4]

  subtasks:
    - id: p5.1
      criterion: "repository-map.yaml に hook_trigger_sequence, workflows セクションが存在する"
      executor: claudecode
      test_command: "grep -q 'hook_trigger_sequence:' docs/repository-map.yaml && grep -q 'workflows:' docs/repository-map.yaml && echo PASS || echo FAIL"

    - id: p5.2
      criterion: "全てのトリガータイプ（SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, Stop, PreCompact, SessionEnd）が含まれている"
      executor: claudecode
      test_command: "grep -c -E '(SessionStart|UserPromptSubmit|PreToolUse|PostToolUse|Stop|PreCompact|SessionEnd)' docs/repository-map.yaml | awk '{if($1>=7) print \"PASS\"; else print \"FAIL\"}'"

    - id: p5.3
      criterion: "PreToolUse トリガーに Edit と Write の両マッチャーが含まれている"
      executor: claudecode
      test_command: "grep -A 50 'PreToolUse' docs/repository-map.yaml | grep -qE '(matcher.*Edit|matcher.*Write)' && echo PASS || echo FAIL"

    - id: p5.4
      criterion: "Workflows セクションに最少 3 個の Workflow（INIT, LOOP, POST_LOOP）が定義されている"
      executor: claudecode
      test_command: "grep -c 'name:' docs/repository-map.yaml | awk '{if($1>=3) print \"PASS\"; else print \"FAIL\"}'"

    - id: p5.5
      criterion: "repository-map.yaml の生成がセッション開始時に自動実行される（hook から呼び出される）"
      executor: claudecode
      test_command: "grep -r 'generate-repository-map' .claude/hooks/ | wc -l | awk '{if($1>0) print \"PASS\"; else print \"FAIL\"}'"

  status: pending
  max_iterations: 3

- id: p6
  name: ドキュメント更新と最終検証
  goal: repository-map.yaml 拡張に関連するドキュメント（docs/ や CLAUDE.md）を更新し、最終検証を行う
  depends_on: [p5]

  subtasks:
    - id: p6.1
      criterion: "docs/extension-system.md が更新され、hook_trigger_sequence セクションへのリンクが追加されている"
      executor: claudecode
      test_command: "grep -q 'hook_trigger_sequence' docs/extension-system.md && echo PASS || echo FAIL"

    - id: p6.2
      criterion: "CLAUDE.md の INIT セクションに repository-map.yaml.hook_trigger_sequence への参照が追加されている"
      executor: claudecode
      test_command: "grep -q 'hook_trigger_sequence\\|workflows' CLAUDE.md && echo PASS || echo FAIL"

    - id: p6.3
      criterion: "repository-map.yaml が自動生成されており、手動編集による矛盾が存在しない"
      executor: claudecode
      test_command: "head -10 docs/repository-map.yaml | grep -q '自動生成' && echo PASS || echo FAIL"

    - id: p6.4
      criterion: "tmp/ 内の m027 設計ファイルが削除されている"
      executor: claudecode
      test_command: "! ls tmp/m027-*.md 2>/dev/null | wc -l | grep -qv '^0$' && echo PASS || echo FAIL"

    - id: p6.5
      criterion: "全変更がコミットされている（git status がクリーン）"
      executor: claudecode
      test_command: "git status --porcelain | wc -l | awk '{if($1==0) print \"PASS\"; else print \"FAIL\"}'"

  status: pending
  max_iterations: 3

- id: p7
  name: 最終検証と完了
  goal: 拡張された repository-map.yaml が全ての要件を満たし、システムが正常に動作することを最終検証する
  depends_on: [p6]

  subtasks:
    - id: p7.1
      criterion: "repository-map.yaml の structure が YAML 形式として有効である"
      executor: claudecode
      test_command: "python3 -c 'import yaml; yaml.safe_load(open(\"docs/repository-map.yaml\"))' 2>/dev/null && echo PASS || echo FAIL"

    - id: p7.2
      criterion: "hook_trigger_sequence セクションが全 Hook を漏れなくカバーしている"
      executor: claudecode
      test_command: "HOOK_COUNT=$(ls -1 .claude/hooks/*.sh | wc -l); SEQ_COUNT=$(grep -c 'name:' docs/repository-map.yaml); test $SEQ_COUNT -ge $((HOOK_COUNT * 80 / 100)) && echo PASS || echo FAIL"

    - id: p7.3
      criterion: "Workflows セクションが明確な process フロー（hooks/subagents/skills の連携）を示している"
      executor: claudecode
      test_command: "grep -A 200 'workflows:' docs/repository-map.yaml | grep -qE '(hooks|subagents|skills)' && echo PASS || echo FAIL"

    - id: p7.4
      criterion: "M027 done_when が全て達成されている"
      executor: claudecode
      test_command: "grep -A 10 'id: M027' plan/project.md | grep -q 'status: achieved' || echo PASS"

  status: pending
  max_iterations: 3
```

---

## final_tasks

```yaml
- id: ft1
  task: "repository-map.yaml を最終更新する"
  command: "bash .claude/hooks/generate-repository-map.sh"
  status: pending

- id: ft2
  task: "tmp/ 内の一時ファイル（m027-*.md）を削除する"
  command: "find tmp/ -type f -name 'm027-*' -delete 2>/dev/null"
  status: pending

- id: ft3
  task: "変更を全てコミットする"
  command: "git add -A && git status"
  status: pending
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-22 | 初版作成。M027 playbook 設計。7 Phase 構成で repository-map.yaml 拡張を計画。 |
