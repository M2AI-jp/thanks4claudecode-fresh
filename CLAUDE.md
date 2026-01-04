# CLAUDE.md

```yaml
version: 2.1.0
status: FROZEN
updated: 2026-01-04
```

---

## 1. 目的と範囲

このリポジトリは、Claude Code のイベント駆動フローを **Hook Unit（イベント単位）** で分割し、
Hook -> Event Unit -> Skill -> SubAgent の連鎖で自律運用を行う。

- 目的: 検証可能な成果物のみを出力し、報酬詐欺・スコープ逸脱・文脈ノイズを抑制する
- 中心原理: 「いつ発火するか」を境界とし、機能は Hook Unit 内に閉じ込める

---

## 2. Event Unit Architecture（SSOT）

Hook の発火タイミングを 1 ユニットとする。ユニットの内部に以下を閉じる:

- Validator: 入力の検証と整形
- Context Injector: そのタイミングに必要な情報だけを注入
- Guardrail: 破壊的操作の遮断
- Telemetry: 成功/失敗/遅延の記録
- Recovery: 失敗時の復旧導線

```yaml
event_units:
  SessionStart: .claude/events/session-start
  UserPromptSubmit: .claude/events/user-prompt-submit
  PreToolUse_EditWrite: .claude/events/pre-tool-edit
  PreToolUse_Bash: .claude/events/pre-tool-bash
  PostToolUse_Edit: .claude/events/post-tool-edit
  SubagentStop: .claude/events/subagent-stop
  PreCompact: .claude/events/pre-compact
  Notification: .claude/events/notification
  Stop: .claude/events/stop
  SessionEnd: .claude/events/session-end
```

---

## 3. Core Contract（回避不可）

```yaml
golden_path:
  trigger: タスク依頼（作って/実装/修正/追加 など）
  required_chain:
    - Skill(skill='playbook-init')
    - playbook-init -> pm SubAgent
    - understanding-check の実行
    - reviewer による playbook 検証
  prohibited:
    - Task(subagent_type='pm') の直接呼び出し
    - Hook/Unit/Skill のスキップ

playbook_gate:
  condition: state.md の playbook.active == null
  action: Edit/Write/Bash(変更系) をブロック

reward_fraud_prevention:
  rule: done の判定は critic SubAgent の PASS が必須
  evidence: 検証結果・ログ・引用を添付

reviewer_gate:
  rule: playbook は reviewed: true でなければ確定しない

executor_orchestration:
  rule: playbook の executor を尊重し、codex/coderabbit/user へ委譲

file_protection:
  hard_block:
    - CLAUDE.md
    - .claude/protected-files.txt の対象
  soft_block:
    - state.md の直接編集（Skill 経由を推奨）
```

---

## 4. 状態モデル（SSOT）

```yaml
state_files:
  state.md:
    role: 現在状態の真実源
    contains: playbook.active, goal, config
  playbook:
    location: plan/playbook-*.md
    role: タスク定義と進捗
  repository_map:
    location: docs/repository-map.yaml
    role: 構造キャッシュ

trust_hierarchy:
  1: state.md
  2: playbook
  3: チャット履歴
```

---

## 5. LOOP

- state.md と playbook を読み、current phase と done_criteria を確認
- playbook に従って作業し、validations に沿って検証
- subtask/phase の完了前に critic を実行し、PASS を得る
- 変更内容と証拠を記録し、次 phase へ進む

---

## 6. POST_LOOP

- playbook の終了条件を満たしたら state.md を更新
- 必要なら git-workflow Skill に従って PR/マージ手順を実行
- アーカイブや記録更新は playbook の指示に従う

---

## 7. 禁止事項

❌ Hook -> Event Unit -> Skill -> SubAgent の連鎖をスキップする
❌ playbook なしで Edit/Write/Bash(変更系) を実行する
❌ critic の PASS なしに done を宣言する
❌ Task(subagent_type='pm'/'critic'/'reviewer') を直接呼び出す
❌ CLAUDE.md を PROMPT_CHANGELOG.md なしで変更する

---

## 8. 優先順位

```yaml
instruction_priority:
  1: Claude 組み込み安全性
  2: CLAUDE.md
  3: タスク固有指示（issue, ticket）
  4: その他 docs
```

---

## 9. 変更管理

```yaml
this_file:
  status: FROZEN
  change_requires:
    - governance/PROMPT_CHANGELOG.md に理由記録
    - version と updated の更新
```

---

## References

| ファイル | 役割 |
|---|---|
| state.md | 現在状態（SSOT） |
| docs/ARCHITECTURE.md | Event Unit の詳細 |
| docs/core-feature-reclassification.md | Hook Unit 依存マップ |
