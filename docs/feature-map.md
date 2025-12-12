# Feature Map

> **Hooks / SubAgents / Skills の発火タイミング別一覧と依存関係マップ**

---

## 概要

このドキュメントは、thanks4claudecode リポジトリで実装されている全ての拡張機能（Hooks、SubAgents、Skills）を発火タイミング別に整理し、入出力と依存関係を明示したものです。

### アーキテクチャ概念図

```
┌─────────────────────────────────────────────────────────────────────┐
│                    三位一体アーキテクチャ                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   Hooks（構造的強制）     SubAgents（検証）      CLAUDE.md（思考制御）  │
│   ─────────────────     ───────────────       ────────────────────  │
│   exit 2 でブロック      PASS/FAIL 判定        行動ルール定義          │
│   stdin JSON 入力       Task ツール経由        @ 参照で連携            │
│   settings.json 登録    専門知識を持つ         Skill を呼び出し        │
│                                                                     │
│         ↓ 発火               ↓ 呼び出し             ↓ 参照           │
│                                                                     │
│                      ┌──────────────┐                              │
│                      │   Skills     │                              │
│                      │  専門知識    │                              │
│                      └──────────────┘                              │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 1. Hooks 一覧（発火タイミング別）

### 1.1 SessionStart（セッション開始時）

| Hook | ファイル | 入力（stdin） | 出力 | 役割 |
|------|----------|--------------|------|------|
| session-start.sh | `.claude/hooks/session-start.sh` | `{ "trigger": "startup\|resume\|clear\|compact" }` | stdout: 状態サマリー, exit 0 | セッション初期化、state.md の last_start 更新、CORE/必須Read 指示出力 |

### 1.2 UserPromptSubmit（ユーザープロンプト送信時）

| Hook | ファイル | 入力（stdin） | 出力 | 役割 |
|------|----------|--------------|------|------|
| prompt-guard.sh | `.claude/hooks/prompt-guard.sh` | `{ "prompt": "..." }` | JSON: `{ "systemMessage": "..." }`, exit 0/2 | State Injection（状態を systemMessage に注入）、スコープ外プロンプト検出、user-intent.md に保存 |

### 1.3 PreToolUse（ツール実行前）

#### 1.3.1 全ツール共通（matcher: "*"）

| Hook | ファイル | 入力（stdin） | 出力 | 役割 |
|------|----------|--------------|------|------|
| init-guard.sh | `.claude/hooks/init-guard.sh` | `{ "tool_name": "...", "tool_input": {...} }` | exit 0（通過）/2（ブロック） | 必須ファイル（state.md, mission.md, playbook）が Read されるまで他ツールをブロック |
| check-main-branch.sh | `.claude/hooks/check-main-branch.sh` | `{ "tool_name": "...", "tool_input": {...} }` | exit 0/2 | main ブランチでの作業をブロック（focus=workspace の場合のみ） |

#### 1.3.2 Edit 専用（matcher: "Edit"）

| Hook | ファイル | 入力（stdin） | 出力 | 役割 |
|------|----------|--------------|------|------|
| consent-guard.sh | `.claude/hooks/consent-guard.sh` | `{ "tool_name": "Edit", "tool_input": {...} }` | exit 0/2 | [理解確認] 完了まで Edit をブロック |
| check-protected-edit.sh | `.claude/hooks/check-protected-edit.sh` | `{ "tool_input": { "file_path": "..." } }` | exit 0/2 | 保護ファイル（HARD_BLOCK/BLOCK/WARN）の編集を制御 |
| playbook-guard.sh | `.claude/hooks/playbook-guard.sh` | `{ "tool_input": { "file_path": "..." } }` | exit 0/2 | playbook=null で Edit をブロック |
| depends-check.sh | `.claude/hooks/depends-check.sh` | `{ "tool_input": {...} }` | exit 0 + 警告 | Phase の depends_on を検証、依存 Phase が done でなければ警告 |
| check-file-dependencies.sh | `.claude/hooks/check-file-dependencies.sh` | `{ "tool_input": { "file_path": "..." } }` | exit 0 + 情報 | file-dependencies.yaml から依存先を表示 |
| critic-guard.sh | `.claude/hooks/critic-guard.sh` | `{ "tool_input": { "file_path": "...", "new_string": "..." } }` | exit 0/2 | state: done への変更に critic PASS（self_complete: true）を要求 |
| scope-guard.sh | `.claude/hooks/scope-guard.sh` | `{ "tool_input": { "old_string": "...", "new_string": "..." } }` | exit 0 + 警告 | done_when/done_criteria の無断変更を検出・警告 |
| executor-guard.sh | `.claude/hooks/executor-guard.sh` | `{ "tool_input": { "file_path": "..." } }` | exit 0/2 | executor: codex/coderabbit/user の Phase で Claude の直接編集をブロック |

#### 1.3.3 Write 専用（matcher: "Write"）

| Hook | ファイル | 入力（stdin） | 出力 | 役割 |
|------|----------|--------------|------|------|
| consent-guard.sh | 同上 | 同上 | 同上 | Edit と同様 |
| check-protected-edit.sh | 同上 | 同上 | 同上 | Edit と同様 |
| playbook-guard.sh | 同上 | 同上 | 同上 | Edit と同様 |
| check-file-dependencies.sh | 同上 | 同上 | 同上 | Edit と同様 |
| critic-guard.sh | 同上 | 同上 | 同上 | Edit と同様 |
| scope-guard.sh | 同上 | 同上 | 同上 | Edit と同様 |
| executor-guard.sh | 同上 | 同上 | 同上 | Edit と同様 |

#### 1.3.4 Bash 専用（matcher: "Bash"）

| Hook | ファイル | 入力（stdin） | 出力 | 役割 |
|------|----------|--------------|------|------|
| pre-bash-check.sh | `.claude/hooks/pre-bash-check.sh` | `{ "tool_input": { "command": "..." } }` | exit 0/1 | HARD_BLOCK ファイルへの書き込み検出、git commit 前の回帰テスト実行 |
| check-coherence.sh | `.claude/hooks/check-coherence.sh` | なし（git commit 時に実行） | exit 0/2 | state-playbook-branch の整合性チェック |
| lint-check.sh | `.claude/hooks/lint-check.sh` | `{ "tool_input": { "command": "..." } }` | exit 0 + 警告 | git commit 前に ESLint/ShellCheck/Ruff を実行 |

### 1.4 PostToolUse（ツール実行後）

| Hook | ファイル | 入力（stdin） | 出力 | 役割 |
|------|----------|--------------|------|------|
| log-subagent.sh | `.claude/hooks/log-subagent.sh` | `{ "tool_input": { "subagent_type": "..." }, "tool_response": "..." }` | exit 0 + ログ記録 | SubAgent 発動をログに記録、critic PASS/FAIL を検出・処理 |
| doc-freshness-check.sh | `.claude/hooks/doc-freshness-check.sh` | `{ "params": { "file_path": "..." } }` | JSON: `{ "systemMessage": "..." }` | 重要ドキュメントの鮮度をチェック、陳腐化警告 |
| archive-playbook.sh | `.claude/hooks/archive-playbook.sh` | `{ "tool_input": { "file_path": "..." } }` | exit 0 + アーカイブ提案 | playbook の全 Phase が done ならアーカイブを提案 |
| create-pr-hook.sh | `.claude/hooks/create-pr-hook.sh` | `{ "tool_input": {...} }` | exit 0 | PR 作成条件を検出（未実装） |
| update-tracker.sh | `.claude/hooks/update-tracker.sh` | `{ "params": { "file_path": "..." } }` | JSON: `{ "systemMessage": "..." }` | 変更を追跡し、current-implementation.md の自動更新を促す |

### 1.5 SessionEnd（セッション終了時）

| Hook | ファイル | 入力（stdin） | 出力 | 役割 |
|------|----------|--------------|------|------|
| session-end.sh | `.claude/hooks/session-end.sh` | なし | exit 0 + サマリー | state.md の last_end 更新、四つ組整合性チェック、セッションサマリー生成 |

### 1.6 Stop（エージェント停止時）

| Hook | ファイル | 入力（stdin） | 出力 | 役割 |
|------|----------|--------------|------|------|
| stop-summary.sh | `.claude/hooks/stop-summary.sh` | `{ "stop_hook_active": boolean }` | exit 0 + サマリー | Phase 状態サマリー出力、ユーザー意図との整合性チェック |

### 1.7 PreCompact（auto-compact / /compact 前）

| Hook | ファイル | 入力（stdin） | 出力 | 役割 |
|------|----------|--------------|------|------|
| pre-compact.sh | `.claude/hooks/pre-compact.sh` | `{ "trigger": "auto\|manual" }` | JSON: `{ "additionalContext": "..." }` | snapshot.json に状態保存、additionalContext で重要情報を伝達 |

### 1.8 ユーティリティ・未実装（直接は発火しない、または準備中）

| Hook | ファイル | 役割 | 状態 |
|------|----------|------|------|
| failure-logger.sh | `.claude/hooks/failure-logger.sh` | 失敗パターンを JSONL 形式で記録（他 Hook から呼び出し） | 稼働中 |
| generate-implementation-doc.sh | `.claude/hooks/generate-implementation-doc.sh` | current-implementation.md を自動生成 | 稼働中 |
| system-health-check.sh | `.claude/hooks/system-health-check.sh` | システム健全性チェック（session-start.sh から呼び出し） | 稼働中 |
| create-pr.sh | `.claude/hooks/create-pr.sh` | PR 作成スクリプト | 手動実行用 |
| merge-pr.sh | `.claude/hooks/merge-pr.sh` | PR マージスクリプト | 手動実行用 |
| test-hooks.sh | `.claude/hooks/test-hooks.sh` | Hook のテストスクリプト | 開発用 |
| lib/common.sh | `.claude/hooks/lib/common.sh` | 共通関数・変数の定義 | ライブラリ |

**合計: 29 個の Hook ファイル**（lib/common.sh を除外すると 28 個、含めると 29 個）

---

## 2. SubAgents 一覧

SubAgent は `Task(subagent_type='xxx')` で呼び出される専門エージェントです。

| SubAgent | 役割 | 主な使用タイミング | アクセス可能なツール |
|----------|------|-------------------|-------------------|
| **pm** | Playbook 管理、タスク標準化 | playbook=null で新規タスク開始時 | Read, Write, Edit, Grep, Glob, Bash |
| **critic** | done_criteria の証拠ベース検証、報酬詐欺防止 | Phase 完了判定前（必須） | Read, Grep, Bash |
| **plan-guard** | 3層計画の整合性チェック | セッション開始時、計画変更時 | Read, Grep, Glob |
| **reviewer** | コード/設計レビュー | コード実装後 | Read, Grep, Glob, Bash |
| **Explore** | コードベース探索、ファイル検索 | 調査・情報収集時 | All tools |
| **setup-guide** | セットアップ手順ガイド | focus=setup 時 | Read, Write, Edit, Bash, Grep, Glob |
| **health-checker** | システム状態の定期監視 | 定期チェック時 | Read, Grep, Glob, Bash |
| **claude-code-guide** | Claude Code/Agent SDK の使い方案内 | ユーザーが使い方を質問した時 | Glob, Grep, Read, WebFetch, WebSearch |

### SubAgent 呼び出しフロー

```
ユーザープロンプト
      ↓
  CLAUDE.md で判断
      ↓
  Task(subagent_type='xxx')
      ↓
  PostToolUse: log-subagent.sh
      ↓
  結果に応じて次のアクション
```

---

## 3. Skills 一覧

Skill は `Skill: "skill-name"` で呼び出される専門知識ファイルです。

| Skill | ファイル | 説明 | トリガー |
|-------|----------|------|----------|
| **state** | `.claude/skills/state/SKILL.md` | state.md 管理、playbook 運用、レイヤー構造 | state.md 更新時、focus 切り替え時 |
| **learning** | `.claude/skills/learning/SKILL.md` | 失敗パターンの記録・学習 | エラー発生時、critic FAIL 時 |
| **plan-management** | `.claude/skills/plan-management/SKILL.md` | 3層計画管理（project→playbook→phase） | playbook 作成時、phase 遷移時 |
| **context-management** | `.claude/skills/context-management/SKILL.md` | /compact 最適化、履歴要約 | コンテキスト管理時 |
| **execution-management** | `.claude/skills/execution-management/SKILL.md` | 並列実行制御、リソース配分 | タスク最適化時 |
| **consent-process** | `.claude/skills/consent-process/skill.md` | 合意プロセス（[理解確認]） | playbook=null で新規タスク開始時 |
| **context-externalization** | `.claude/skills/context-externalization/skill.md` | コンテキスト外部化 | Phase 完了時 |
| **post-loop** | `.claude/skills/post-loop/skill.md` | playbook 完了後の処理 | playbook の全 Phase が done |
| **beginner-advisor** | `.claude/skills/beginner-advisor/skill.md` | 初学者向け比喩説明 | learning_mode.expertise=beginner 時 |
| **frontend-design** | `.claude/skills/frontend-design/SKILL.md` | プロダクション品質の UI 設計 | フロントエンド開発時 |
| **lint-checker** | `.claude/skills/lint-checker/skill.md` | コード品質チェック（ESLint/型） | .ts/.tsx/.js/.jsx/.sh 変更時 |
| **test-runner** | `.claude/skills/test-runner/skill.md` | テスト実行・検証 | *.test.* / *.spec.* 変更時 |
| **deploy-checker** | `.claude/skills/deploy-checker/skill.md` | デプロイ準備・検証 | done_criteria に「デプロイ」含む時 |

---

## 4. コンポーネント間の連携フロー

### 4.1 セッション開始からタスク完了までの流れ

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. SessionStart                                                  │
│    └─→ session-start.sh                                         │
│         ├─ state.md last_start 更新                             │
│         ├─ system-health-check.sh 呼び出し                      │
│         ├─ failures.log から学習警告出力                        │
│         └─ 必須 Read 指示出力                                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. UserPromptSubmit                                              │
│    └─→ prompt-guard.sh                                          │
│         ├─ State Injection（systemMessage に状態注入）          │
│         ├─ user-intent.md に保存                                │
│         └─ スコープ外検出時はブロック（exit 2）                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. PreToolUse（Read 等）                                         │
│    └─→ init-guard.sh                                            │
│         └─ 必須ファイル Read 完了で pending 解除                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. playbook=null の場合                                          │
│    └─→ Task(subagent_type='pm')                                 │
│         ├─ project.md から milestone 特定                       │
│         ├─ playbook 作成                                        │
│         └─ state.md 更新                                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. LOOP（Phase 実行）                                            │
│    ├─→ PreToolUse（Edit/Write）                                 │
│    │    ├─ consent-guard.sh                                     │
│    │    ├─ check-protected-edit.sh                              │
│    │    ├─ playbook-guard.sh                                    │
│    │    ├─ executor-guard.sh                                    │
│    │    └─ scope-guard.sh                                       │
│    │                                                             │
│    └─→ PostToolUse（Edit/Write）                                │
│         ├─ update-tracker.sh                                    │
│         └─ archive-playbook.sh（全 done 検出）                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 6. CRITIQUE（Phase 完了前）                                      │
│    └─→ Task(subagent_type='critic')                             │
│         ├─ done_criteria を証拠ベースで検証                     │
│         ├─ PASS: self_complete: true 設定                       │
│         └─ FAIL: 修正して再実行                                 │
│                                                                  │
│    └─→ PostToolUse: log-subagent.sh                             │
│         └─ critic 結果をログに記録、次ステップを案内            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 7. Phase 完了 → 次 Phase or POST_LOOP                            │
│    ├─ state.md の phase を更新                                  │
│    ├─ 自動コミット                                              │
│    └─ 全 Phase done → POST_LOOP                                 │
│         ├─ playbook アーカイブ                                  │
│         ├─ project.milestone 更新                               │
│         ├─ /clear 推奨アナウンス                                │
│         └─ 次 milestone → 新 playbook 作成                      │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 8. SessionEnd / Stop                                             │
│    ├─→ session-end.sh                                           │
│    │    ├─ state.md last_end 更新                               │
│    │    ├─ 四つ組整合性チェック                                 │
│    │    └─ セッションサマリー生成                               │
│    │                                                             │
│    └─→ stop-summary.sh                                          │
│         └─ Phase 状態サマリー、ユーザー意図整合性チェック       │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 報酬詐欺防止の5層防御

```
┌─────────────────────────────────────────────────────────────────┐
│ Layer 1: CLAUDE.md LOOP/CRITIQUE（行動ルール）                   │
│          → critic PASS なしで done 禁止を明文化                 │
├─────────────────────────────────────────────────────────────────┤
│ Layer 2: critic SubAgent（証拠ベース判定）                       │
│          → done_criteria を客観的に検証                         │
├─────────────────────────────────────────────────────────────────┤
│ Layer 3: critic-guard.sh（state: done 更新前の警告）             │
│          → self_complete: true がなければブロック               │
├─────────────────────────────────────────────────────────────────┤
│ Layer 4: check-coherence.sh（state-playbook 整合性）             │
│          → git commit 前に整合性チェック                        │
├─────────────────────────────────────────────────────────────────┤
│ Layer 5: log-subagent.sh（critic 結果自動処理）                  │
│          → critic PASS/FAIL を検出してログ記録                  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.3 ファイル依存関係

```
state.md ←──────────────────────────────────────────┐
    ↓                                                │
    ├─→ playbook（plan/active/playbook-*.md）        │
    │       ↓                                        │
    │       └─→ phases[].done_criteria              │
    │                                                │
    ├─→ project.md（plan/project.md）               │
    │       ↓                                        │
    │       └─→ milestones[].done_when              │
    │                                                │
    └─→ git branch                                   │
            ↓                                        │
            └─→ 1 playbook = 1 branch ルール ───────┘

.claude/settings.json
    ↓
    └─→ hooks 登録（発火タイミング + matcher）
            ↓
            └─→ .claude/hooks/*.sh

CLAUDE.md
    ↓
    ├─→ @.claude/skills/*/skill.md（参照）
    ├─→ SubAgent 呼び出しルール
    └─→ LOOP / CRITIQUE 行動定義
```

---

## 5. 設定ファイル

### 5.1 .claude/settings.json

Hooks の登録と発火タイミングを定義：

```json
{
  "hooks": {
    "SessionStart": [...],
    "UserPromptSubmit": [...],
    "PreToolUse": [
      { "matcher": "*", "hooks": [...] },
      { "matcher": "Edit", "hooks": [...] },
      { "matcher": "Write", "hooks": [...] },
      { "matcher": "Bash", "hooks": [...] }
    ],
    "PostToolUse": [...],
    "SessionEnd": [...],
    "Stop": [...],
    "PreCompact": [...]
  }
}
```

### 5.2 .claude/protected-files.txt

ファイル保護レベルを定義：

- `HARD_BLOCK:` - admin モード以外では常にブロック
- `BLOCK:` - strict モードでブロック、trusted で警告
- `WARN:` - 警告のみ

### 5.3 .claude/file-dependencies.yaml

ファイル間の依存関係を定義（check-file-dependencies.sh が参照）

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | 初版作成。M007 対応。 |
