# playbook-ops-improvement.md

> **Codex 考察に基づく運用改善: Hook 強化、フォールバック固定化、レビューループ、ナレッジ一元化**

---

## meta

```yaml
project: ops-improvement
branch: feat/ops-improvement
created: 2026-01-01
issue: null
reviewed: true
roles:
  worker: claudecode  # このplaybookはインフラ整備のため claudecode で実行
```

---

## context

```yaml
context:
  understanding_check:
  summary: "Codex考察に基づく4つの改善アクション（Hook強化、フォールバック、レビューループ、ナレッジ一元化）を実装"
  approved_by: user
  approved_at: 2026-01-01
  questions_answered:
    q1: "現在値を確認し、問題があれば調整"
    q2: "playbook + コードレビュー"
    q3: "完全初期化（state + rules + playbook + toolstack）"
```

---

## executor_enforcement

```yaml
executor_enforcement:
  enabled: true

  monitored_tools:
    - Edit
    - Write
    - Task
    - Bash

  fallback_policy:
    codex_timeout:
      threshold: 120s
      action: ask_user
      options: [retry, fallback_to_cli, abort]
    codex_error:
      action: ask_user
      options: [retry, fallback_to_claudecode, abort]
    coderabbit_error:
      action: ask_user
      options: [retry, fallback_to_reviewer_subagent, abort]

  execution_evidence:
    required: true
    fields:
      - executed_by: codex | claudecode | coderabbit | user
      - execution_log: ツール呼び出しログまたは CLI 出力
      - session_id: MCP セッション ID（codex の場合）
```

---

## goal

```yaml
summary: Codex 考察に基づく 4 つの改善アクション（Hook タイムアウト/ログ強化、Codex フォールバック固定化、レビュー自動ループ、ナレッジ一元化）を実装する
done_when:
  - settings.json に PreToolUse/UserPromptSubmit のタイムアウト設定が存在し、現状値から調整済みである
  - Hook 実行時間と BLOCK 理由がログ出力される仕組みが存在する
  - docs/executor-fallback-policy.md に Codex フォールバック手順が定義されている
  - .claude/commands/review.md が存在し、playbook + コードレビューループを実行できる
  - .claude/rules/ に仕様・テスト・運用規約が配置されている
  - .claude/commands/init.md が存在し、完全初期化（state + rules + playbook + toolstack）が実行できる
```

---

## phases

### p1: Hook タイムアウト調査と調整

**goal**: 現在の Hook タイムアウト設定を調査し、問題があれば調整する

#### subtasks

- [ ] **p1.1**: settings.json の全タイムアウト値が確認され、一覧化されている
  - executor: claudecode
  - validations:
    - technical: "settings.json から timeout 値を抽出し、一覧を出力"
    - consistency: "Hook 種別ごとのタイムアウト値が整理されている"
    - completeness: "全 Hook（PreToolUse/PostToolUse/SessionStart/UserPromptSubmit/SubagentStop/PreCompact）が含まれる"

- [ ] **p1.2**: タイムアウト調整が必要な場合、settings.json が更新されている
  - executor: claudecode
  - validations:
    - technical: "jq で settings.json を解析し、更新値を確認"
    - consistency: "変更前後の値が記録されている"
    - completeness: "調整理由がコメントまたはドキュメントに記載されている"

- [ ] **p1.3**: Hook 実行時間ログ機能が pre-tool.sh に追加されている
  - executor: claudecode
  - validations:
    - technical: "pre-tool.sh を実行し、時間ログが出力される"
    - consistency: "ログ形式が他のログと整合している"
    - completeness: "開始時刻・終了時刻・経過時間が記録される"

- [ ] **p1.4**: BLOCK 理由ログ機能が pre-tool.sh に追加されている
  - executor: claudecode
  - validations:
    - technical: "BLOCK 発生時に理由がログに出力される"
    - consistency: "既存の BLOCK メッセージと整合している"
    - completeness: "全ガードの BLOCK 理由がログに含まれる"

**status**: pending
**max_iterations**: 5

---

### p2: Codex フォールバック運用固定化

**goal**: docs/executor-fallback-policy.md を確認・更新し、運用手順を明確化する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: docs/executor-fallback-policy.md が存在し、フォールバック手順が定義されている
  - executor: claudecode
  - validations:
    - technical: "test -f docs/executor-fallback-policy.md で存在確認"
    - consistency: "V17 playbook-format.md の fallback_policy と整合している"
    - completeness: "codex_timeout / codex_error / coderabbit_error の全パターンが含まれる"

- [ ] **p2.2**: フォールバック手順にユーザー確認フローが含まれている
  - executor: claudecode
  - validations:
    - technical: "grep で AskUserQuestion 関連の記述を確認"
    - consistency: "executor-guard.sh のフォールバック動作と整合している"
    - completeness: "retry/fallback/abort の全選択肢が説明されている"

- [ ] **p2.3**: フォールバックポリシーが settings.json または playbook-format.md から参照されている
  - executor: claudecode
  - validations:
    - technical: "grep で executor-fallback-policy.md への参照を確認"
    - consistency: "参照元ドキュメントと整合している"
    - completeness: "必要な参照が全て追加されている"

**status**: pending
**max_iterations**: 3

---

### p3: レビュー自動ループ整備

**goal**: playbook + コードレビューを自動ループで実行するコマンドを作成する

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: .claude/commands/review.md が存在する
  - executor: claudecode
  - validations:
    - technical: "test -f .claude/commands/review.md で存在確認"
    - consistency: "他のコマンドファイル（*.md）と同じ形式である"
    - completeness: "コマンド説明・使用方法・例が含まれている"

- [ ] **p3.2**: /review コマンドが playbook レビュー（reviewer SubAgent）を呼び出せる
  - executor: claudecode
  - validations:
    - technical: "コマンド内に reviewer 呼び出しの記述がある"
    - consistency: ".claude/agents/reviewer.md の仕様と整合している"
    - completeness: "レビュー結果の PASS/FAIL 処理が含まれている"

- [ ] **p3.3**: /review コマンドがコードレビュー（critic + coderabbit）を呼び出せる
  - executor: claudecode
  - validations:
    - technical: "コマンド内に critic/coderabbit 呼び出しの記述がある"
    - consistency: ".claude/agents/critic.md の仕様と整合している"
    - completeness: "レビューループ（最大3回）の制御が含まれている"

- [ ] **p3.4**: /review コマンドにレビューループ制御（max_iterations: 3）が実装されている
  - executor: claudecode
  - validations:
    - technical: "コマンド内に max_iterations または retry 制御の記述がある"
    - consistency: "playbook-format.md の max_iterations 仕様と整合している"
    - completeness: "3回 FAIL 時のユーザー確認フローが含まれている"

**status**: pending
**max_iterations**: 5

---

### p4: ナレッジ一元化（rules + init コマンド）

**goal**: .claude/rules/ にルールを配置し、/init コマンドで完全初期化を実行できるようにする

**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: .claude/rules/ ディレクトリが存在する
  - executor: claudecode
  - validations:
    - technical: "test -d .claude/rules/ で存在確認"
    - consistency: ".claude/ 配下の他ディレクトリと整合している"
    - completeness: "README.md が含まれている"

- [ ] **p4.2**: .claude/rules/ に仕様・テスト・運用規約が配置されている
  - executor: claudecode
  - validations:
    - technical: "ls .claude/rules/ で規約ファイルを確認"
    - consistency: "既存のドキュメント（CLAUDE.md, RUNBOOK.md）と整合している"
    - completeness: "coding.md, testing.md, operations.md が存在する"

- [ ] **p4.3**: .claude/commands/init.md が存在する
  - executor: claudecode
  - validations:
    - technical: "test -f .claude/commands/init.md で存在確認"
    - consistency: "他のコマンドファイルと同じ形式である"
    - completeness: "コマンド説明・使用方法・例が含まれている"

- [ ] **p4.4**: /init コマンドが state.md を読み込む
  - executor: claudecode
  - validations:
    - technical: "コマンド内に state.md 読み込みの記述がある"
    - consistency: "既存の session-start フローと整合している"
    - completeness: "playbook.active の確認が含まれている"

- [ ] **p4.5**: /init コマンドが .claude/rules/ を読み込む
  - executor: claudecode
  - validations:
    - technical: "コマンド内に rules/ 読み込みの記述がある"
    - consistency: "rules/ 内の全ファイルが対象である"
    - completeness: "読み込み順序が明示されている"

- [ ] **p4.6**: /init コマンドが最新 playbook を読み込む
  - executor: claudecode
  - validations:
    - technical: "コマンド内に playbook 読み込みの記述がある"
    - consistency: "state.md の playbook.active と連動している"
    - completeness: "playbook が null の場合の処理が含まれている"

- [ ] **p4.7**: /init コマンドが toolstack を確認する
  - executor: claudecode
  - validations:
    - technical: "コマンド内に toolstack 確認の記述がある"
    - consistency: "state.md の config.toolstack と連動している"
    - completeness: "toolstack に応じた役割解決が含まれている"

**status**: pending
**max_iterations**: 5

---

### p_self_update: 自己改善

**goal**: playbook 自身の改善と学習事項を記録する

**depends_on**: [p4]

#### subtasks

- [ ] **p_self_update.1**: 実装中に発見した改善点が playbook または関連ドキュメントに反映されている
  - executor: claudecode
  - validations:
    - technical: "git diff でドキュメント変更を確認"
    - consistency: "改善点が実装内容と整合している"
    - completeness: "発見した全改善点が記録されている"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p_self_update]

#### subtasks

- [ ] **p_final.1**: settings.json に PreToolUse/UserPromptSubmit のタイムアウト設定が存在し、現状値から調整済みである
  - executor: claudecode
  - validations:
    - technical: "jq で settings.json のタイムアウト値を確認"
    - consistency: "p1 で記録した調整内容と一致している"
    - completeness: "全 Hook のタイムアウトが確認されている"

- [ ] **p_final.2**: Hook 実行時間と BLOCK 理由がログ出力される仕組みが存在する
  - executor: claudecode
  - validations:
    - technical: "pre-tool.sh を確認し、ログ出力コードが存在する"
    - consistency: "p1.3, p1.4 の実装と一致している"
    - completeness: "時間ログと BLOCK 理由ログの両方が確認されている"

- [ ] **p_final.3**: docs/executor-fallback-policy.md に Codex フォールバック手順が定義されている
  - executor: claudecode
  - validations:
    - technical: "test -f と grep で内容を確認"
    - consistency: "p2 の実装と一致している"
    - completeness: "全フォールバックパターンが含まれている"

- [ ] **p_final.4**: .claude/commands/review.md が存在し、playbook + コードレビューループを実行できる
  - executor: claudecode
  - validations:
    - technical: "test -f と内容確認"
    - consistency: "p3 の実装と一致している"
    - completeness: "playbook レビューとコードレビューの両方が含まれている"

- [ ] **p_final.5**: .claude/rules/ に仕様・テスト・運用規約が配置されている
  - executor: claudecode
  - validations:
    - technical: "ls .claude/rules/ で確認"
    - consistency: "p4.2 の実装と一致している"
    - completeness: "coding.md, testing.md, operations.md が存在する"

- [ ] **p_final.6**: .claude/commands/init.md が存在し、完全初期化が実行できる
  - executor: claudecode
  - validations:
    - technical: "test -f と内容確認"
    - consistency: "p4.3-p4.7 の実装と一致している"
    - completeness: "state + rules + playbook + toolstack の全要素が含まれている"

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

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-01 | 初版作成。Codex 考察に基づく 4 つの改善アクションを playbook 化。 |
