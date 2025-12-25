# CLAUDE.md

```yaml
version: 2.0.1
status: FROZEN
updated: 2025-12-25
```

---

## 1. 設計思想

このリポジトリは **Claude Code 自律運用フレームワーク** である。

```yaml
purpose: |
  LLM の「自己承認バイアス」と「スコープクリープ」を構造的に防止し、
  検証可能な成果物のみを生産するシステム。

problem_statement:
  - LLM は自分の出力を「完了」と判断しがち（報酬詐欺）
  - ユーザープロンプトに引きずられてスコープが肥大する
  - コンテキストリセット後に状態を失う

solution:
  trinity:
    hooks: 構造的強制（Edit/Write 前にゲートチェック）
    subagents: 独立検証（critic が done_criteria を判定）
    claude_md: 思考制御（このファイル）

  enforcement: |
    「お願い」ではなく「ブロック」で制御する。
    Hook が BLOCK を返せば Claude は進めない。
```

---

## 2. 保護アーキテクチャ（4QV+）

```yaml
model: 導火線モデル（Fuse Model）

layers:
  L1_hooks:
    role: トリガー（導火線）
    files: .claude/hooks/{pre,post}-tool.sh
    behavior: |
      全ツール呼び出し前後に発火
      条件不成立 → BLOCK/WARN を返す

  L2_skills:
    role: ユースケースパッケージ
    files: .claude/skills/*/
    behavior: |
      Hook から呼び出される
      SubAgent を内包する場合あり

  L3_subagents:
    role: 専門検証者
    files: .claude/skills/*/agents/
    critical_agents:
      pm: タスク開始の必須エントリーポイント
      critic: done_criteria 検証（PASS/FAIL 判定）
      reviewer: playbook 検証

chain: |
  Hook → Skill → SubAgent
  この順序をスキップしてはならない

ssot: |
  state.md = Single Source of Truth
  playbook.active = 現在のタスク定義
  コンテキストリセット後は state.md を再読
```

---

## 3. コア契約（Core Contract）

以下は admin モードでも回避不可。

```yaml
golden_path:
  trigger: タスク依頼パターン（作って/実装して/修正して/追加して）
  required_chain: |
    1. Skill(skill='playbook-init') を呼ぶ
    2. playbook-init が pm SubAgent に委譲
    3. pm が understanding-check を実行
    4. reviewer が playbook を検証
  prohibited:
    - Task(subagent_type='pm') の直接呼び出し
    - Hook/Skill チェーンのスキップ
    - understanding-check の省略

playbook_gate:
  condition: state.md の playbook.active == null
  action: Edit/Write/Bash(変更系) をブロック
  bypass: なし

reward_fraud_prevention:
  rule: 自分の作業を自分で「完了」と判定しない
  required: critic SubAgent による独立検証
  evidence: PASS 判定には実行可能な証拠が必要

reviewer_gate:
  rule: playbook は reviewed: true でなければ確定しない
  enforced_by: playbook-guard.sh

file_protection:
  hard_block:
    - CLAUDE.md
    - .claude/protected-files.txt に記載のファイル
  soft_block:
    - state.md の直接編集（Skill 経由推奨）
```

---

## 4. 状態モデル

```yaml
state_files:
  state.md:
    role: 現在状態の真実源
    contains: playbook.active, goal, config
    rule: セッション開始時に必ず Read

  playbook:
    location: plan/playbook-*.md
    role: タスク定義と進捗
    contains: phases, done_criteria, validations

  repository_map:
    location: docs/repository-map.yaml
    role: ファイル構造のキャッシュ

trust_hierarchy:
  1: state.md（最優先）
  2: playbook
  3: チャット履歴（コンテキストリセットで消失）
```

---

## 5. 実行プロトコル

```yaml
task_execution:
  trivial: 直接実行（単一ファイル編集、質問回答）
  non_trivial:
    1: playbook 確認（なければ golden_path 発動）
    2: phase の done_criteria 確認
    3: 実行
    4: critic による検証
    5: 次 phase または完了

output_requirements:
  - 具体的成果物（diff, file, command）
  - 検証手順
  - 制限事項

prohibited:
  - 「後でやる」という約束
  - 時間見積もり
  - 検証なしの「完了」宣言
  - スコープ外の変更
  - 事実の捏造（知らなければ「知らない」と言う）

git:
  branch: main への直接コミット禁止
  naming: {type}/{description}
  commit: Co-Authored-By 必須
```

---

## 6. 優先順位

```yaml
instruction_priority:
  1: Claude 組み込み安全性
  2: CLAUDE.md（このファイル）
  3: タスク固有指示（issue, ticket）
  4: その他 docs（RUNBOOK.md 等）

conflict_resolution: |
  競合時は上位を優先。
  安全に実行できない場合のみ停止して確認。
```

---

## 7. 変更管理

```yaml
this_file:
  status: FROZEN
  change_requires:
    - governance/PROMPT_CHANGELOG.md に理由記録
    - バージョン番号更新（SemVer）
    - メンテナーレビュー

mutable_files:
  - RUNBOOK.md（手順書）
  - docs/*（ドキュメント）
  - .claude/skills/*（Skill 定義）
```

---

## References

| ファイル | 役割 |
|----------|------|
| state.md | 現在状態（SSOT） |
| RUNBOOK.md | 手順書（変更可能） |
| docs/ARCHITECTURE.md | 保護アーキテクチャ詳細・リポジトリ構造 |

---

## Version History

| Version | Date | Summary |
|---------|------|---------|
| 2.0.1 | 2025-12-25 | focus 機能削除: state.md から focus セクション削除、main ブランチブロック常時有効化 |
| 2.0.0 | 2025-12-24 | 総編集: 設計思想追加、保護アーキテクチャ追加、MECE 化、LLM 向け最適化 |
| 1.2.0 | 2025-12-24 | Golden Path: Hook→Skill→SubAgent チェーン経由を明記 |
| 1.1.0 | 2025-12-18 | Core Contract + Admin Mode Contract 追加 |
| 1.0.0 | 2025-12-18 | Initial frozen constitution |
