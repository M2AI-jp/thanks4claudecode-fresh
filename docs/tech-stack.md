# Tech Stack

> **thanks4claudecode の技術スタックと設計思想**

---

## 概要

thanks4claudecode は、Claude Code の自律性と品質を**構造的に向上させる**ためのフレームワークです。

従来の「プロンプトエンジニアリングによる行動制御」ではなく、**Hooks による構造的強制**と**SubAgents による検証**を組み合わせることで、LLM の行動を確実に制御します。

---

## 三位一体アーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│                    三位一体アーキテクチャ                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Hooks           SubAgents         CLAUDE.md               │
│   （構造的強制）    （検証）           （思考制御）             │
│   ────────────    ──────────        ────────────            │
│   exit 2 で       PASS/FAIL で      行動ルールを             │
│   ブロック         判定              定義                     │
│                                                             │
│   単独では機能しない。組み合わせて初めて強制力を持つ。           │
└─────────────────────────────────────────────────────────────┘
```

**設計思想**: LLM は「良かれと思って」ルールを破ることがあります。そのため、CLAUDE.md での「お願い」だけでなく、Hook による「物理的なブロック」と SubAgent による「第三者検証」を組み合わせます。

---

## フレームワーク: Claude Code Hooks System

### 何ができるか

Claude Code のイベント（セッション開始、ツール実行前後など）にフックして、シェルスクリプトを自動実行します。

### なぜ使うか

- **構造的強制**: 「お願い」ではなく「物理的にブロック」
- **一貫性**: 人間の介入なしで同じルールを適用
- **透明性**: すべての制御がシェルスクリプトとして可読

### どう動くか

```
ユーザープロンプト
      ↓
UserPromptSubmit Hook（prompt-guard.sh）
      ↓  状態を systemMessage に注入
LLM が Read ツールを使用
      ↓
PreToolUse Hook（init-guard.sh）
      ↓  必須ファイル Read 完了を確認
LLM が Edit ツールを使用
      ↓
PreToolUse Hook（playbook-guard.sh）
      ↓  playbook 存在を確認（なければ exit 2 でブロック）
Edit 実行
      ↓
PostToolUse Hook（archive-playbook.sh）
      ↓  playbook 完了を検出 → アナウンス
```

---

## 言語: Bash/Shell

### なぜ Bash か

1. **Claude Code との親和性**: stdin JSON → 処理 → exit code/stdout JSON
2. **依存関係ゼロ**: Node.js や Python のインストール不要
3. **可読性**: 非エンジニアでも読める（比較的）
4. **デバッグ容易性**: `set -x` で実行トレースが可能

### 標準的な Hook 構造

```bash
#!/bin/bash
set -e

# stdin から JSON を読み込む
INPUT=$(cat)

# jq で必要な値を抽出
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# 条件チェック
if [ 条件 ]; then
    echo "エラーメッセージ"
    exit 2  # ブロック
fi

exit 0  # 通過
```

---

## デプロイ: ローカル（git-based）

### なぜローカルか

1. **即座に反映**: git commit で変更が即座に有効
2. **バージョン管理**: 変更履歴を追跡可能
3. **外部依存なし**: インターネット接続不要で動作
4. **カスタマイズ容易**: 各ユーザーが自由に拡張可能

### ディレクトリ構造

```
.claude/
├── hooks/           # シェルスクリプト群
│   ├── session-start.sh
│   ├── playbook-guard.sh
│   └── ...
├── settings.json    # Hook の登録
├── skills/          # 専門知識
└── .session-init/   # セッション状態
    ├── pending
    ├── consent
    └── user-intent.md

plan/
├── project.md       # プロジェクト計画
├── active/          # 進行中の playbook
└── template/        # テンプレート
```

---

## データストア: ファイルベース

### なぜファイルベースか

1. **シンプル**: データベース不要
2. **可読性**: Markdown で人間も読める
3. **バージョン管理**: git で変更履歴を追跡
4. **移植性**: ディレクトリをコピーするだけで移行可能

### 主要ファイル

| ファイル | 役割 | 更新頻度 |
|----------|------|----------|
| `state.md` | 現在地の Single Source of Truth | 高（セッション毎） |
| `plan/project.md` | プロジェクト全体の計画 | 低（milestone 完了時） |
| `plan/active/playbook-*.md` | タスク計画 | 中（phase 完了時） |
| `.claude/.session-init/user-intent.md` | ユーザー意図の記録 | 高（プロンプト毎） |

### state.md の構造

```yaml
focus:
  current: thanks4claudecode
  project: plan/project.md

playbook:
  active: plan/active/playbook-xxx.md
  branch: feat/xxx

goal:
  milestone: M008
  phase: p3
  done_criteria:
    - 条件1
    - 条件2
```

---

## 3層計画構造

```
project.md（永続）
├── vision: 最上位目標
├── milestones[]: 中間目標
│   ├── M001: achieved
│   ├── M002: achieved
│   └── M008: in_progress ← 現在
└── constraints: 制約条件

playbook（一時的）
├── meta.derives_from: M008
├── goal.done_when: milestone 達成条件
└── phases[]: 作業単位
    ├── p0: done
    ├── p1: done
    ├── p2: done
    ├── p3: in_progress ← 現在
    └── p4: pending

phase（作業単位）
├── subtasks[]: 具体的なタスク
├── status: pending | in_progress | done
└── test_command: 検証コマンド
```

---

## Hooks 依存関係マトリクス

各 Hook が参照・依存するファイルの一覧です。

### Core Hooks（システム必須）

| Hook | 参照ファイル | 依存 Hook | 役割 |
|------|-------------|----------|------|
| **session-start.sh** | state.md, playbook, failures.log | system-health-check.sh | セッション初期化 |
| **prompt-guard.sh** | state.md, project.md, playbook, user-intent.md | - | State Injection |
| **init-guard.sh** | .session-init/pending, playbook | - | 必須 Read 強制 |
| **playbook-guard.sh** | state.md (playbook.active) | - | playbook 存在確認 |
| **consent-guard.sh** | .session-init/consent | - | [理解確認] 強制 |
| **critic-guard.sh** | state.md (self_complete) | - | critic PASS 強制 |
| **archive-playbook.sh** | playbook, user-intent.md, project.md | - | 完了検出・アナウンス |
| **log-subagent.sh** | subagent.log | failure-logger.sh | SubAgent ログ |

### Guard Hooks（保護・検証）

| Hook | 参照ファイル | 依存 Hook | 役割 |
|------|-------------|----------|------|
| **check-protected-edit.sh** | protected-files.txt, state.md (security) | - | ファイル保護 |
| **check-main-branch.sh** | state.md (focus) | - | main ブランチ禁止 |
| **check-coherence.sh** | state.md, playbook | - | 整合性チェック |
| **scope-guard.sh** | playbook (done_when/done_criteria) | - | スコープ変更検出 |
| **executor-guard.sh** | playbook (executor) | - | executor 制御 |
| **depends-check.sh** | playbook (depends_on) | - | 依存関係検証 |

### Utility Hooks（補助機能）

| Hook | 参照ファイル | 依存 Hook | 役割 |
|------|-------------|----------|------|
| **pre-compact.sh** | state.md, playbook, user-intent.md | - | 状態保存 |
| **session-end.sh** | state.md | - | セッション終了 |
| **stop-summary.sh** | state.md, playbook, user-intent.md | - | 停止サマリー |
| **lint-check.sh** | - | - | 静的解析 |
| **pre-bash-check.sh** | protected-files.txt | - | Bash 制御 |
| **update-tracker.sh** | changes.log | - | 変更追跡 |
| **doc-freshness-check.sh** | - | - | 鮮度チェック |
| **failure-logger.sh** | failures.log | - | 失敗記録 |
| **system-health-check.sh** | state.md, project.md, playbook | - | 健全性チェック |
| **generate-implementation-doc.sh** | changes.log | - | ドキュメント生成 |
| **check-file-dependencies.sh** | file-dependencies.yaml | - | ファイル依存表示 |

### 手動実行・開発用

| Hook | 参照ファイル | 役割 |
|------|-------------|------|
| create-pr.sh | - | PR 作成 |
| merge-pr.sh | - | PR マージ |
| test-hooks.sh | - | Hook テスト |
| lib/common.sh | - | 共通関数 |

---

## SubAgents 依存関係

SubAgent は Task ツールで呼び出される専門エージェントです。各 SubAgent は特定の役割を持ちます。

| SubAgent | 参照ファイル | 呼び出しタイミング |
|----------|-------------|-------------------|
| **pm** | project.md, playbook-format.md, state.md | playbook=null 時 |
| **critic** | playbook (done_criteria), 実装ファイル | Phase 完了判定前 |
| **plan-guard** | project.md, playbook, state.md | セッション開始時 |
| **reviewer** | 対象コードファイル | コード実装後 |
| **Explore** | コードベース全体 | 調査時 |
| **setup-guide** | setup/playbook-setup.md | focus=setup 時 |
| **health-checker** | state.md, project.md, playbook | 定期チェック時 |
| **claude-code-guide** | Claude Code ドキュメント | 使い方質問時 |

### SubAgent 詳細

- **pm SubAgent**: playbook 作成を担当。project.milestone を参照し derives_from を設定する。
- **critic SubAgent**: Phase 完了判定を担当。done_criteria の達成を検証し PASS/FAIL を返す。
- **plan-guard SubAgent**: セッション開始時に3層計画の整合性を検証する。
- **reviewer SubAgent**: コード品質レビューを担当。実装後のコードを評価する。
- **Explore SubAgent**: コードベース探索を担当。ファイル検索やキーワード検索を実行する。
- **setup-guide SubAgent**: 初期セットアップをガイドする。focus=setup 時に自動発火。
- **health-checker SubAgent**: システム健全性を監視する。state.md と playbook の整合性を確認。
- **claude-code-guide SubAgent**: Claude Code の使い方に関する質問に回答する。

---

## Skills 依存関係

Skill は特定の状況で参照される専門知識です。Skill ツールまたは SubAgent から呼び出されます。

| Skill | 参照ファイル | 呼び出しタイミング |
|-------|-------------|-------------------|
| **state** | state.md | state.md 更新時 |
| **learning** | failures.log | エラー発生時 |
| **plan-management** | project.md, playbook | playbook 作成時 |
| **context-management** | - | /compact 時 |
| **execution-management** | - | 並列実行時 |
| **consent-process** | - | [理解確認] 時 |
| **context-externalization** | - | Phase 完了時 |
| **post-loop** | project.md, playbook | playbook 完了時 |
| **beginner-advisor** | state.md (expertise) | beginner モード時 |
| **frontend-design** | - | フロントエンド開発時 |
| **lint-checker** | - | コード変更時 |
| **test-runner** | - | テスト実行時 |
| **deploy-checker** | - | デプロイ時 |

### Skill 詳細

**ワークフロー系 Skill**:
- **state Skill**: state.md の更新ルールと構造を定義する Skill。
- **plan-management Skill**: playbook と project の計画管理を担当する Skill。
- **consent-process Skill**: [理解確認] の 5W1H 形式出力を定義する Skill。
- **post-loop Skill**: playbook 完了後の自動処理フローを定義する Skill。
- **context-externalization Skill**: Phase 完了時のコンテキスト保存を定義する Skill。

**検証系 Skill**:
- **lint-checker Skill**: TypeScript/JavaScript の静的解析を実行する Skill。
- **test-runner Skill**: Unit/E2E テストを自動実行する Skill。
- **deploy-checker Skill**: デプロイ前の検証チェックを実行する Skill。

**ガイド系 Skill**:
- **context-management Skill**: /compact 最適化のガイドラインを提供する Skill。
- **execution-management Skill**: 並列実行制御のガイドラインを提供する Skill。
- **learning Skill**: 失敗パターンを記録・学習する Skill。
- **beginner-advisor Skill**: 初学者向けに専門用語を比喩で説明する Skill。
- **frontend-design Skill**: フロントエンド UI 設計のガイドラインを提供する Skill。

---

## Core 機能選定基準

システムの根幹を担う「Core」機能は以下の基準で選定されています。

### 選定基準

1. **必須性**: その機能がなければシステムが動作しない
2. **代替不可**: 他の機能で代替できない固有の役割を持つ
3. **連鎖起点**: 他の機能の前提条件となる（依存されている）

### Core Hooks（10個）

| Hook | 選定理由 |
|------|---------|
| session-start.sh | セッション初期化の唯一の起点。pending/consent 作成。 |
| prompt-guard.sh | State Injection の実装。systemMessage 注入の唯一手段。 |
| init-guard.sh | Read 必須チェック。INIT フェーズの強制。 |
| playbook-guard.sh | Edit/Write ブロック。計画駆動開発の強制。 |
| consent-guard.sh | [理解確認] 強制。報酬詐欺防止の入口。 |
| critic-guard.sh | critic PASS 強制。報酬詐欺防止の出口。 |
| check-coherence.sh | 5層報酬詐欺防御の中核。整合性検証。 |
| log-subagent.sh | SubAgent 追跡。監査証跡の記録。 |
| scope-guard.sh | スコープ変更検出。計画逸脱の防止。 |
| executor-guard.sh | executor 検証。実行権限の制御。 |

### Core SubAgents（3個）

| SubAgent | 選定理由 |
|----------|---------|
| pm | playbook 作成・milestone 管理。3層構造の運用者。 |
| critic | Phase 完了判定。報酬詐欺防止の判定者。 |
| plan-guard | 計画整合性チェック。3層構造の検証者。 |

### Core Skills（2個）

| Skill | 選定理由 |
|-------|---------|
| state/SKILL.md | state.md 管理。Single Source of Truth の運用知識。 |
| plan-management/SKILL.md | 3層構造運用。project→playbook→phase の管理知識。 |

**除外理由**:
- lint-checker, test-runner, deploy-checker: 検証系。プロジェクト依存で必須ではない。
- beginner-advisor, frontend-design: ガイド系。特定コンテキストでのみ有用。
- context-management, execution-management: 最適化。なくても動作する。
- learning, consent-process, context-externalization, post-loop: 補助機能。

---

## 関連ドキュメント

| ドキュメント | 内容 |
|-------------|------|
| [feature-map.md](./feature-map.md) | Hooks/SubAgents/Skills の詳細一覧と連携フロー |
| [CLAUDE.md](../CLAUDE.md) | LLM の行動ルール |
| [playbook-format.md](../plan/template/playbook-format.md) | playbook のテンプレート |

---

## 自動運用フロー

```yaml
phase_complete:
  trigger: critic PASS
  action:
    - phase.status = done
    - 次の phase へ（または playbook 完了へ）

playbook_complete:
  trigger: 全 phase が done
  action:
    - playbook をアーカイブ
    - project.milestone を自動更新
      - status = achieved
      - achieved_at = now()
      - playbooks[] に追記
    - /clear 推奨をアナウンス
    - 次の milestone を特定（depends_on 分析）
    - pm で新 playbook を自動作成

project_complete:
  trigger: 全 milestone が achieved
  action:
    - project.status = completed
    - 「次の方向性を教えてください」と人間に確認
```

---

## Hooks 詳細仕様

各 Hook の詳細な仕様を記載します。

### session-start.sh（Core Hook）

```yaml
ファイル: .claude/hooks/session-start.sh
トリガー: SessionStart (startup, resume, clear, compact)
機能: セッション初期化、状態復元、警告表示

入力:
  stdin: '{"trigger": "startup|resume|clear|compact"}'

出力:
  stdout: セッション情報（MISSION、警告、必須Read指示、[自認]テンプレート）
  exit_code: 0

参照ファイル:
  - state.md: last_start 更新、focus/phase/playbook 取得
  - plan/mission.md: MISSION statement 表示
  - playbook: 現在の Phase 情報
  - .claude/logs/failures.log: 繰り返し失敗パターン表示
  - .claude/.session-init/user-intent.md: ユーザー意図復元

生成ファイル:
  - .claude/.session-init/pending: 初期化未完了フラグ
  - .claude/.session-init/consent: 合意未完了フラグ
  - .claude/.session-init/required_playbook: playbook パス記録

依存 Hook:
  - system-health-check.sh: 健全性チェック呼び出し
  - generate-implementation-doc.sh: 変更蓄積時に自動実行
```

### prompt-guard.sh（Core Hook）

```yaml
ファイル: .claude/hooks/prompt-guard.sh
トリガー: UserPromptSubmit
機能: State Injection、プロンプト保存、スコープチェック

入力:
  stdin: '{"prompt": "ユーザー入力"}'

出力:
  stdout: '{"systemMessage": "..."}' (State Injection 情報)
  stderr: スコープ外エラー（exit 2 時）
  exit_code: 0 (通常) / 2 (スコープ外ブロック)

参照ファイル:
  - state.md: focus, milestone, phase, playbook, config
  - plan/project.md: vision.goal, milestones
  - plan/mission.md: 報酬詐欺パターン検出
  - .claude/logs/p*-test-results.md: last_critic 判定

生成ファイル:
  - .claude/.session-init/user-intent.md: プロンプト追記

systemMessage 内容:
  - focus, milestone, phase, playbook, branch
  - git status, remaining phases/milestones
  - project_summary, last_critic, done_criteria
```

### init-guard.sh（Core Hook）

```yaml
ファイル: .claude/hooks/init-guard.sh
トリガー: PreToolUse (*)
機能: 必須ファイル Read 完了まで他ツールをブロック

入力:
  stdin: '{"tool_name": "...", "tool_input": {...}}'

出力:
  stdout: "✅ 必須ファイルの Read が完了しました"
  stderr: ブロックメッセージ
  exit_code: 0 (許可) / 2 (ブロック)

参照ファイル:
  - state.md: security mode (admin でバイパス)
  - .claude/.session-init/pending: 初期化状態
  - .claude/.session-init/required_playbook: 必須 playbook
  - .claude/.session-init/read/*: Read 完了記録

必須ファイル:
  - plan/mission.md
  - state.md
  - playbook (存在する場合)

許可ツール（Read 未完了でも許可）:
  - Read, Grep, Glob
  - Bash: git status/branch/rev-parse/log/diff/checkout/switch/stash
```

### playbook-guard.sh（Core Hook）

```yaml
ファイル: .claude/hooks/playbook-guard.sh
トリガー: PreToolUse:Edit, PreToolUse:Write
機能: playbook=null なら Edit/Write をブロック

入力:
  stdin: '{"tool_name": "Edit|Write", "tool_input": {"file_path": "..."}}'

出力:
  stdout: '{"systemMessage": "playbook 未レビュー警告"}' (reviewed: false 時)
  stderr: ブロックメッセージ
  exit_code: 0 (許可) / 2 (ブロック)

参照ファイル:
  - state.md: playbook.active, config.security
  - playbook: reviewed フラグ

バイパス条件:
  - security: admin
  - 編集対象が state.md
  - 編集対象が playbook-*.md

依存 Hook:
  - failure-logger.sh: ブロック時に失敗記録
```

### consent-guard.sh（Core Hook）

```yaml
ファイル: .claude/hooks/consent-guard.sh
トリガー: PreToolUse:Edit, PreToolUse:Write
機能: [理解確認] 完了前の Edit/Write をブロック

入力:
  stdin: '{"tool_name": "Edit|Write", "tool_input": {...}}'

出力:
  stdout: ブロックメッセージ
  exit_code: 0 (許可) / 2 (ブロック)

参照ファイル:
  - .claude/.session-init/consent: 存在 = 未合意 → ブロック

フロー:
  1. session-start.sh: consent ファイル作成
  2. LLM: [理解確認] 出力
  3. ユーザー: OK
  4. LLM: rm .claude/.session-init/consent
  5. Edit/Write 許可
```

### critic-guard.sh（Core Hook）

```yaml
ファイル: .claude/hooks/critic-guard.sh
トリガー: PreToolUse:Edit
機能: critic PASS なしで state: done への変更をブロック

入力:
  stdin: '{"tool_name": "Edit", "tool_input": {"file_path": "...", "new_string": "..."}}'

出力:
  stderr: ブロックメッセージ
  exit_code: 0 (許可) / 2 (ブロック)

参照ファイル:
  - state.md: self_complete フラグ

チェック条件:
  - 編集対象が state.md
  - new_string に "state: done" を含む
  - self_complete: true がない → ブロック
```

### archive-playbook.sh（Core Hook）

```yaml
ファイル: .claude/hooks/archive-playbook.sh
トリガー: PostToolUse:Edit
機能: playbook 完了検出、アーカイブ提案、/clear 推奨アナウンス

入力:
  stdin: '{"tool_input": {"file_path": "..."}}'

出力:
  stdout: 完了アナウンス（元タスク、成果物、進捗、ネクストアクション）
  exit_code: 0

参照ファイル:
  - playbook: status 確認（全 done か）
  - .claude/.session-init/user-intent.md: 元のプロンプト
  - plan/project.md: 次の milestone

アナウンス内容:
  - 📝 元のタスク
  - ✅ 成果物
  - 📊 project 進捗
  - 🔜 ネクストアクション
  - ⚠️ /clear 推奨
```

### check-protected-edit.sh（Guard Hook）

```yaml
ファイル: .claude/hooks/check-protected-edit.sh
トリガー: PreToolUse:Edit, PreToolUse:Write
機能: 保護対象ファイルの編集をブロック

入力:
  stdin: '{"tool_input": {"file_path": "..."}}'

出力:
  stdout: 警告メッセージ (WARN レベル)
  stderr: ブロックメッセージ (BLOCK/HARD_BLOCK)
  exit_code: 0 (許可/警告) / 2 (ブロック)

参照ファイル:
  - .claude/protected-files.txt: 保護対象一覧
  - state.md: config.security (admin/trusted/strict)

保護レベル:
  - HARD_BLOCK: security に関係なく常にブロック（admin 除く）
  - BLOCK: strict でブロック、trusted で警告
  - WARN: 警告のみ（編集許可）
```

### check-main-branch.sh（Guard Hook）

```yaml
ファイル: .claude/hooks/check-main-branch.sh
トリガー: PreToolUse (*)
機能: main ブランチでの作業をブロック（workspace のみ）

入力:
  stdin: '{"tool_name": "...", "tool_input": {...}}'

出力:
  stderr: ブロックメッセージ
  exit_code: 0 (許可) / 2 (ブロック)

参照ファイル:
  - state.md: focus.current
  - git: current branch

ブロック条件:
  - focus = workspace
  - branch = main または master
  - ツール = Edit/Write/Bash（Read/Grep/Glob 除く）

許可条件:
  - focus = setup/product/plan-template
  - Bash: git checkout/switch/branch
  - 編集対象が state.md
```

### scope-guard.sh（Guard Hook）

```yaml
ファイル: .claude/hooks/scope-guard.sh
トリガー: PreToolUse:Edit, PreToolUse:Write
機能: done_when/done_criteria の無断変更を検出

入力:
  stdin: '{"tool_input": {"file_path": "...", "old_string": "...", "new_string": "..."}}'

出力:
  stdout: 警告メッセージ
  exit_code: 0 (警告のみ) / 2 (STRICT_MODE=true でブロック)

参照ファイル:
  - playbook または project.md の編集を検出

検出対象:
  - old_string に done_when/done_criteria を含む（既存定義の変更）
  - new_string に done_when/done_criteria を追加（新規追加）
```

### executor-guard.sh（Guard Hook）

```yaml
ファイル: .claude/hooks/executor-guard.sh
トリガー: PreToolUse:Edit, PreToolUse:Write
機能: executor が claudecode 以外の Phase でコード編集をブロック

入力:
  stdin: '{"tool_input": {"file_path": "..."}}'

出力:
  stderr: ブロックメッセージ（executor 別）
  exit_code: 0 (許可) / 2 (ブロック)

参照ファイル:
  - state.md: playbook パス
  - playbook: in_progress Phase の executor

executor 別対応:
  - codex: Codex MCP 使用を促す
  - coderabbit: CodeRabbit CLI 使用を促す
  - user: ユーザー作業であることを通知
```

### pre-compact.sh（Utility Hook）

```yaml
ファイル: .claude/hooks/pre-compact.sh
トリガー: PreCompact (auto-compact または /compact)
機能: compact 前の完全な状態スナップショット保存

入力:
  stdin: '{"trigger": "auto|manual", ...}'

出力:
  stdout: '{"additionalContext": "..."}' (状態サマリー)
  exit_code: 0

参照ファイル:
  - state.md: focus, playbook, self_complete
  - playbook: current_phase, phase_goal, done_criteria
  - .claude/.session-init/user-intent.md: ユーザー意図

生成ファイル:
  - .claude/.session-init/snapshot.json: 構造化状態データ
```

### log-subagent.sh（Utility Hook）

```yaml
ファイル: .claude/hooks/log-subagent.sh
トリガー: PostToolUse:Task
機能: SubAgent 発動ログ記録、critic 結果処理

入力:
  stdin: '{"tool_input": {"subagent_type": "...", "description": "..."}, "tool_response": "..."}'

出力:
  stdout: critic PASS/FAIL 検出時のアナウンス
  exit_code: 0

参照/生成ファイル:
  - .claude/logs/subagent-dispatch.log: 発動ログ
  - .claude/logs/critic-results.log: critic 結果ログ

critic 結果処理:
  - PASS 検出: self_complete 更新を促す
  - FAIL 検出: 修正・再実行を促す
```

### failure-logger.sh（Utility Hook）

```yaml
ファイル: .claude/hooks/failure-logger.sh
トリガー: 他の Hook から呼び出し
機能: 失敗パターン記録、学習ループ支援

入力:
  stdin: '{"hook": "...", "context": "...", "action": "..."}'
  または引数: hook_name context [user_action]

出力:
  stdout: "Logged failure: {hook}"
  exit_code: 0

生成ファイル:
  - .claude/logs/failures.log: JSONL 形式の失敗ログ（最大 100 件）

提供関数:
  - log_failure(): 失敗記録
  - count_similar_failures(): 同一パターンのカウント
  - get_failure_warnings(): 繰り返し失敗の警告生成
```

### system-health-check.sh（Utility Hook）

```yaml
ファイル: .claude/hooks/system-health-check.sh
トリガー: SessionStart (session-start.sh から呼び出し)
機能: システム健全性チェック

入力: なし（直接呼び出し）

出力:
  stdout: 問題検出時の警告メッセージ
  exit_code: 0

チェック項目:
  1. settings.json の存在・有効性
  2. Hook ファイルの存在・実行権限
  3. SubAgent 定義ファイル（critic, pm, reviewer, health-checker）
  4. Skills ディレクトリ構造
  5. state.md の必須セクション（focus, playbook, goal, config）
```

### check-coherence.sh（Guard Hook）

```yaml
ファイル: .claude/hooks/check-coherence.sh
トリガー: PreToolUse:Bash (git commit コマンド時)
機能: state.md と playbook の整合性チェック

入力: なし（直接呼び出し）

出力:
  stdout: 整合性チェック結果
  exit_code: 0 (通過) / 2 (ブロック)

チェック項目:
  1. state.md の存在
  2. focus.current の取得
  3. Active playbook の存在確認
  4. Branch coherence（playbook.branch vs git branch）
  5. Stray playbooks（plan/ 直下の playbook）の検出
  6. Critic enforcement（state: done 変更時の self_complete 確認）

参照ファイル:
  - state.md: focus, playbook パス
  - playbook: branch, status
  - git: current branch

依存 Hook:
  - pre-bash-check.sh から呼び出される
```

### depends-check.sh（Guard Hook）

```yaml
ファイル: .claude/hooks/depends-check.sh
トリガー: PreToolUse:Edit, PreToolUse:Write
機能: Phase の depends_on を検証

入力:
  stdin: '{"tool_input": {...}}'

出力:
  stdout: 依存チェック結果（警告のみ、ブロックしない）
  exit_code: 0

参照ファイル:
  - state.md: focus.current, playbook パス
  - playbook: 現在 Phase の depends_on, 依存 Phase の status

チェック内容:
  - depends_on で指定された Phase が done でなければ警告
  - 依存 Phase 未完了でも作業は続行可能（警告のみ）
```

### check-file-dependencies.sh（Utility Hook）

```yaml
ファイル: .claude/hooks/check-file-dependencies.sh
トリガー: PreToolUse:Edit, PreToolUse:Write
機能: ファイル依存関係の表示

入力:
  stdin: '{"tool_input": {"file_path": "..."}}'

出力:
  stdout: 依存先ファイル一覧（情報提供のみ）
  exit_code: 0（常に通過）

参照ファイル:
  - .claude/file-dependencies.yaml: affects, reason, check_level

表示内容:
  - 変更時に確認が必要なファイル一覧
  - 理由（reason）
  - 確認レベル（required/recommended/optional）

依存 Hook:
  - lib/common.sh: 共通関数
```

### session-end.sh（Utility Hook）

```yaml
ファイル: .claude/hooks/session-end.sh
トリガー: SessionEnd
機能: セッション終了時の整合性チェック・サマリー生成

入力: なし

出力:
  stdout: セッションサマリー
  exit_code: 0

自動更新:
  - state.md の last_end
  - state.md の uncommitted_warning

チェック項目:
  1. 未コミット変更
  2. 四つ組整合性（state-plan-git-branch）
  3. critic リマインド
  4. 未 push コミット

生成ファイル:
  - .claude/logs/sessions/{date}_session-{num}.md: セッションサマリー
```

### stop-summary.sh（Utility Hook）

```yaml
ファイル: .claude/hooks/stop-summary.sh
トリガー: Stop（エージェント停止試行時）
機能: Phase 状態サマリー出力

入力:
  stdin: '{"stop_hook_active": boolean}'

出力:
  stdout: Phase 状態サマリー + ユーザー意図との整合性
  exit_code: 0（ブロックしない）

参照ファイル:
  - state.md: focus, playbook パス, self_complete
  - playbook: current phase, goal, status, done_criteria
  - .claude/.session-init/user-intent.md: ユーザー意図

表示内容:
  - Focus, Playbook, Current Phase
  - Phases 状態カウント（done/in_progress/pending）
  - Criteria 達成状況
  - ユーザー意図との整合性チェック
```

### lint-check.sh（Utility Hook）

```yaml
ファイル: .claude/hooks/lint-check.sh
トリガー: PreToolUse:Bash (git commit/add コマンド時)
機能: コミット前の静的解析チェック

入力:
  stdin: '{"tool_name": "Bash", "tool_input": {"command": "..."}}'

出力:
  stderr: Linter 結果
  exit_code: 0（警告のみ、ブロックしない）

チェック対象:
  1. JavaScript/TypeScript: ESLint (pnpm lint)
  2. Shell スクリプト: ShellCheck (.claude/hooks/*.sh)
  3. Python: Ruff (pyproject.toml 存在時)

特徴:
  - 警告のみでブロックしない（開発者の判断に委ねる）
```

### pre-bash-check.sh（Guard Hook）

```yaml
ファイル: .claude/hooks/pre-bash-check.sh
トリガー: PreToolUse:Bash
機能: Bash コマンド実行前の保護チェック

入力:
  stdin: '{"tool_input": {"command": "..."}}'

出力:
  stderr: ブロックメッセージ
  exit_code: 0 (通過) / 1 (ブロック)

チェック内容:
  1. HARD_BLOCK ファイルへの書き込み（常時ブロック）
  2. BLOCK ファイルへの書き込み（strict モードでブロック）
  3. git commit 時の回帰テスト実行
  4. git commit 時の整合性チェック

参照ファイル:
  - state.md: security.mode
  - .claude/tests/regression-test.sh: 回帰テスト

依存 Hook:
  - check-coherence.sh: git commit 時に呼び出し
  - check-state-update.sh: git commit 時に呼び出し
```

### update-tracker.sh（Utility Hook）

```yaml
ファイル: .claude/hooks/update-tracker.sh
トリガー: PostToolUse:Edit, PostToolUse:Write
機能: 変更追跡と自動更新提案

入力:
  stdin: '{"params": {"file_path": "..."}}'

出力:
  stdout: '{"systemMessage": "..."}' (更新提案)
  exit_code: 0

参照ファイル:
  - .claude/logs/changes.log: 変更ログ

生成ファイル:
  - .claude/logs/changes.log: JSONL 形式の変更ログ（最大 100 件）

対象ファイル:
  - .claude/hooks/*
  - .claude/agents/*
  - .claude/skills/*
  - .claude/frameworks/*
  - .claude/settings.json
  - plan/template/*

提案内容:
  - 5 件以上の変更蓄積: 自動生成を強く推奨
  - 通常: ドキュメント更新推奨
```

### doc-freshness-check.sh（Utility Hook）

```yaml
ファイル: .claude/hooks/doc-freshness-check.sh
トリガー: PostToolUse:Read
機能: ドキュメント鮮度チェック

入力:
  stdin: '{"params": {"file_path": "..."}}'

出力:
  stdout: '{"systemMessage": "..."}' (警告)
  exit_code: 0

対象ドキュメント:
  - current-implementation.md: 関連 = .claude/hooks, .claude/agents, .claude/skills
  - CLAUDE.md: 関連 = state.md, plan/template/playbook-format.md
  - extension-system.md: 関連 = .claude/settings.json

チェック内容:
  - ドキュメント更新日 vs 関連ファイル更新日
  - 3 日以上の乖離で警告
  - current-implementation.md は自動修復提案
```

### generate-implementation-doc.sh（Utility Hook）

```yaml
ファイル: .claude/hooks/generate-implementation-doc.sh
トリガー: 手動実行
機能: current-implementation.md の自動生成

入力: なし

出力:
  stdout: 生成完了メッセージ
  exit_code: 0

生成ファイル:
  - docs/current-implementation.md

生成セクション:
  1. Hooks: settings.json から自動抽出
  2. SubAgents: .claude/agents/*.md から自動抽出
  3. Skills: .claude/skills/*/skill.md から自動抽出
  4. Frameworks: .claude/frameworks/*.md から自動抽出
  5. 設定ファイル情報
  6. 統計情報

参照ファイル:
  - .claude/settings.json
  - .claude/agents/*.md
  - .claude/skills/*/skill.md
  - .claude/frameworks/*.md
```

### create-pr.sh（手動実行 Hook）

```yaml
ファイル: .claude/hooks/create-pr.sh
トリガー: POST_LOOP（playbook 完了後）
機能: GitHub PR の自動作成

入力: なし（state.md と playbook から情報取得）

出力:
  stdout: PR URL
  exit_code: 0 (成功) / 1 (エラー) / 2 (スキップ)

前提条件:
  - gh CLI インストール済み
  - gh auth でログイン済み
  - 現在のブランチが main ではない
  - リモートへ push 済み

参照ファイル:
  - state.md: focus, playbook パス
  - playbook: goal.summary, done_when, phases

PR 本文内容:
  - Summary
  - Playbook 情報（Name, Phase, Path, Focus）
  - Done When（Playbook Goal）
  - Done Criteria（Current Phase）
  - Completed Phases
```

### lib/common.sh（ライブラリ）

```yaml
ファイル: .claude/hooks/lib/common.sh
トリガー: 他の Hook から source される
機能: 共通関数・変数の提供

提供内容:
  1. 色定義: RED, GREEN, YELLOW, BLUE, CYAN, NC
  2. パス定義: WORKSPACE_ROOT, STATE_MD, CLAUDE_MD 等
  3. state.md 取得関数:
     - get_focus(): focus.current を取得
     - get_security_mode(): security.mode を取得
     - get_playbook(): アクティブ playbook を取得
     - get_current_milestone(): 現在の milestone を取得
     - get_current_phase(): 現在の phase を取得
  4. Git 関数:
     - get_branch(): 現在のブランチ名
     - is_main_branch(): main ブランチ判定
     - has_uncommitted_changes(): 未コミット変更判定
     - has_unpushed_commits(): 未 push コミット判定
  5. ファイル依存関係関数:
     - get_file_dependencies(): 依存先を取得
  6. 出力関数:
     - log_error(), log_warn(), log_info(), log_success()
  7. SubAgent 関連関数:
     - log_subagent_dispatch(): ログ記録
     - check_recent_subagent(): 直近呼び出しチェック
  8. JSON パース関数:
     - json_get(): フィールド取得
     - get_tool_file_path(): file_path 取得
     - get_tool_command(): command 取得
```

### merge-pr.sh（手動実行 Hook）

```yaml
ファイル: .claude/hooks/merge-pr.sh
トリガー: POST_LOOP（playbook 完了後）/ 手動実行
機能: GitHub PR の自動マージ

入力:
  引数: PR番号（省略時は現在のブランチの PR を自動検索）
  stdin: なし

出力:
  stdout: PR 情報、マージ状態、同期結果
  exit_code:
    0: 成功（マージ完了 or 自動マージ設定済み）
    1: エラー（PR 未発見、コンフリクト、ブロック等）

前提条件:
  - gh CLI インストール済み
  - gh auth でログイン済み
  - Git リポジトリ内で実行
  - PR が存在し、Draft でない

処理フロー:
  1. PR 番号取得（引数または現在のブランチから検索）
  2. PR 情報取得（state, isDraft, mergeable, mergeStateStatus）
  3. ステータスチェック
     - CLOSED/MERGED → エラー or 終了
     - Draft → エラー（gh pr ready で解除を案内）
     - CONFLICTING → エラー（コンフリクト解決手順を案内）
     - BLOCKED → エラー（必須チェック未通過）
     - BEHIND → 警告（続行可能）
  4. マージ実行（gh pr merge --merge --auto --delete-branch）
  5. ローカルブランチ同期（fetch + checkout + pull）

参照ファイル:
  - state.md: playbook パス、goal summary（マージコミットメッセージ用）

生成するマージコミット本文:
  - Summary
  - PR Details（番号、ブランチ、Playbook）
  - Co-Authored-By ヘッダー

依存ツール:
  - gh CLI
  - jq
  - git
```

### test-hooks.sh（開発用 Hook）

```yaml
ファイル: .claude/hooks/test-hooks.sh
トリガー: 手動実行（開発・検証時）
機能: Hook 機能カタログスペック検証

入力:
  引数: --verbose（詳細出力モード、省略可）
  stdin: なし

出力:
  stdout: テスト結果サマリー
    ✅ PASS: 期待通り動作
    ❌ FAIL: 動作異常
    ⏭️ SKIP: ファイル未存在
  exit_code:
    0: 全テスト PASS
    1: 1件以上 FAIL

テスト対象 Hook:
  1. session-start.sh（startup/compact トリガー）
  2. pre-compact.sh（additionalContext 出力）
  3. playbook-guard.sh（状態依存）
  4. init-guard.sh（状態依存）
  5. system-health-check.sh（問題なし時は出力なし）
  6. doc-freshness-check.sh（鮮度問題なし時は出力なし）
  7. update-tracker.sh（更新提案 JSON）
  8. failure-logger.sh（失敗記録）
  9. generate-implementation-doc.sh（ドキュメント生成）

検証ロジック:
  1. ファイル存在チェック → 不在なら SKIP
  2. 実行権限チェック → 無ければ FAIL
  3. テスト入力を投入して実行
  4. 出力パターンマッチング
     - 期待パターンにマッチ → PASS
     - EMPTY: 出力なし = 正常 → PASS
     - EMPTY_OR_JSON: 出力なし or JSON → PASS
     - それ以外 → FAIL

参照ファイル:
  - なし（Hook ファイル自体をテスト）

修復コマンド例:
  chmod +x .claude/hooks/*.sh
```

---

## SubAgents 詳細仕様

### pm SubAgent

```yaml
subagent_type: pm
役割: playbook 作成・管理

呼び出しタイミング:
  - playbook=null で新規タスク開始時
  - milestone 完了後の次タスク導出時

入力:
  prompt: "playbook を作成してください" など

参照ファイル:
  - plan/project.md: milestones, depends_on, decomposition
  - plan/template/playbook-format.md: テンプレート
  - state.md: focus, 現在の playbook

出力:
  - plan/active/playbook-{name}.md 作成
  - state.md の playbook.active 更新
  - ブランチ作成（feat/{name}）

derives_from 設定:
  - playbook.meta.derives_from に milestone ID を設定
  - milestone 完了時の自動更新に使用
```

### critic SubAgent

```yaml
subagent_type: critic
役割: Phase 完了判定、報酬詐欺防止

呼び出しタイミング:
  - Phase 完了判定前（LOOP 内）
  - done_criteria の検証時

入力:
  prompt: 検証対象の done_criteria と証拠

参照ファイル:
  - playbook: done_criteria, test_command
  - 実装ファイル: 証拠となるコード・出力
  - .claude/rules/frameworks/done-criteria-validation.md

出力:
  - PASS: 全 done_criteria 満たす → state.md の self_complete: true
  - FAIL: 不足あり → 修正を促す

5層報酬詐欺防御:
  L1: CLAUDE.md LOOP/CRITIQUE
  L2: critic SubAgent（このエージェント）
  L3: critic-guard.sh
  L4: check-coherence.sh
  L5: log-subagent.sh
```

### Explore SubAgent

```yaml
subagent_type: Explore
役割: コードベース探索、ファイル検索

呼び出しタイミング:
  - オープンエンドな検索タスク
  - コードベース構造の把握
  - キーワード・パターン検索

入力:
  prompt: 探索内容の説明
  thoroughness: quick | medium | very thorough

参照ファイル:
  - コードベース全体

出力:
  - 検索結果サマリー
  - 該当ファイル一覧
  - パターン分析
```

### plan-guard SubAgent

```yaml
subagent_type: plan-guard
役割: 3層計画の整合性チェック

呼び出しタイミング:
  - セッション開始時
  - 計画変更時
  - playbook 作成前

入力:
  prompt: チェック対象の説明

参照ファイル:
  - plan/project.md: milestones, vision
  - playbook: phases, derives_from
  - state.md: focus, goal

出力:
  - 整合性チェック結果
  - 問題点の指摘
  - 修正提案
```

### reviewer SubAgent

```yaml
subagent_type: reviewer
役割: コード/設計レビュー

呼び出しタイミング:
  - コード実装完了後
  - 設計変更時
  - ユーザーが「レビューして」と言った場合

入力:
  prompt: レビュー対象の説明

参照ファイル:
  - 対象コードファイル
  - 関連テストファイル
  - 設計ドキュメント

出力:
  - コード品質評価
  - 改善提案
  - ベストプラクティスの提示

利用ツール:
  - Read, Grep, Glob, Bash
```

### setup-guide SubAgent

```yaml
subagent_type: setup-guide
役割: 初期セットアップガイド

呼び出しタイミング:
  - focus.current = setup 時
  - 新規環境セットアップ時

入力:
  prompt: セットアップ対象の説明

参照ファイル:
  - setup/playbook-setup.md
  - .env.example
  - package.json

出力:
  - セットアップ手順
  - 必要な環境変数
  - 検証コマンド

利用ツール:
  - Read, Write, Edit, Bash, Grep, Glob
```

### health-checker SubAgent

```yaml
subagent_type: health-checker
役割: システム状態の定期監視

呼び出しタイミング:
  - 定期チェック時
  - 問題発生時の診断

入力:
  prompt: チェック対象の説明

参照ファイル:
  - state.md
  - plan/project.md
  - playbook

出力:
  - システム健全性レポート
  - 問題点の検出
  - 修復提案

利用ツール:
  - Read, Grep, Glob, Bash
```

### claude-code-guide SubAgent

```yaml
subagent_type: claude-code-guide
役割: Claude Code / Agent SDK の使い方案内

呼び出しタイミング:
  - ユーザーが「Claude Code で...」と質問
  - Hook や Skill の使い方を聞かれた場合
  - Agent SDK の使い方を聞かれた場合

入力:
  prompt: 質問内容

参照ファイル:
  - Claude Code 公式ドキュメント
  - 既存の実装例

出力:
  - 使い方の説明
  - コード例
  - 参考リンク

利用ツール:
  - Glob, Grep, Read, WebFetch, WebSearch
```

---

## Skills 詳細仕様

### consent-process Skill

```yaml
ファイル: .claude/skills/consent-process/skill.md
役割: [理解確認] の 5W1H 形式出力定義

発火タイミング:
  - playbook=null で新規タスク開始時
  - Edit/Write 前の合意取得が必要な時

5W1H フォーマット:
  What（何を）: タスク要約
  Why（なぜ）: 目的・背景
  Who（誰が）: executor（claudecode/user/codex）
  When（いつまでに）: 期限
  Where（どこに）: 新規作成/更新/変更なしファイル
  How（どのように）: 手順

連携 Hook:
  - consent-guard.sh: consent ファイル有無チェック
  - session-start.sh: consent ファイル作成
```

### post-loop Skill

```yaml
ファイル: .claude/skills/post-loop/skill.md
役割: playbook 完了後の自動処理フロー定義

発火タイミング:
  - playbook の全 Phase が done になった時

行動フロー:
  0. 自動コミット（最終 Phase 分）
  0.5. playbook アーカイブ（.archive/plan/ へ移動）
  1. GitHub PR 作成（create-pr-hook.sh）
  2. GitHub PR マージ（merge-pr.sh）
  3. project.milestone 自動更新（status: achieved）
  4. /clear アナウンス
  5. 次タスク導出（pm 経由）
  6-7. 残タスクあり → 新 playbook / なし → 待機

参照ファイル:
  - playbook: derives_from
  - plan/project.md: milestones
  - .claude/.session-init/user-intent.md: 元のプロンプト
```

### context-externalization Skill

```yaml
ファイル: .claude/skills/context-externalization/skill.md
役割: コンテキスト外部化、作業記録

発火タイミング:
  - Phase 完了時（必須）
  - ユーザーから新しい指示を受けたとき
  - 重要な技術的発見時
  - セッション終了前

記録先: .claude/logs/context-log.md

記録フォーマット:
  - [HH:MM] Entry: {タスク名}
  - User Prompt, Intent, Actions, Result
  - Technical Notes, Files Changed, Playbook Phase
```

### test-runner Skill

```yaml
ファイル: .claude/skills/test-runner/skill.md
役割: テスト実行・検証

発火タイミング:
  - テストファイル作成・編集後
  - done_criteria 検証時
  - ユーザーが「テスト実行して」と言った場合

テスト種類:
  1. Unit Tests: pnpm test
  2. E2E Tests: pnpm test:e2e
  3. Type Checks: pnpm tsc --noEmit
  4. Build Test: pnpm build

出力形式:
  - 各テストの PASS/FAIL
  - 失敗詳細（ファイル:行）
  - Summary: Status, Passed, Failed, Build
```

### lint-checker Skill

```yaml
ファイル: .claude/skills/lint-checker/skill.md
役割: コード品質チェック

発火タイミング:
  - TypeScript/JavaScript ファイル作成・編集後
  - コミット前
  - ユーザーが「lint して」と言った場合

チェック項目:
  1. ESLint ルール違反
  2. TypeScript エラー
  3. コーディング規約
  4. ベストプラクティス

出力形式:
  - ESLint: errors/warnings
  - TypeScript: type errors
  - Recommendations: 修正方法
```

### state Skill

```yaml
ファイル: .claude/skills/state/SKILL.md
役割: state.md 管理、playbook 運用、レイヤー構造の専門知識

発火タイミング:
  - state.md の更新時
  - focus の切り替え時
  - done_criteria の判定時
  - CRITIQUE の実行時

内容:
  1. state.md の構造定義
     - focus: current, session
     - goal: phase, done_criteria
     - layer 定義（4つ）
  2. レイヤーの編集権限
  3. session の違い（task/discussion）
  4. CRITIQUE の実行方法
  5. state.md 更新のルール
  6. 状態遷移ルール
  7. playbook 必須ルール
  8. playbook 作成テンプレート

参照ファイル:
  - state.md
  - plan/template/playbook-format.md
```

### learning Skill

```yaml
ファイル: .claude/skills/learning/SKILL.md
役割: 失敗パターンの記録・学習

発火タイミング:
  - エラーが発生したとき
  - critic が FAIL を返したとき
  - 作業が行き詰まったとき
  - 同じ問題が繰り返されているとき

内容:
  1. 失敗パターンの記録
     - 記録先: .claude/logs/failures.log
     - 形式: JSONL（1行1レコード）
     - 保持: 最新 100 件
  2. 失敗パターンの分類
     - critic_fail, hook_block, error, timeout
  3. 学習の活用
     - セッション開始時の確認
     - 同種タスク実行時の参照
     - 定期的な振り返り
  4. 過去 playbook 参照機能
     - アーカイブ参照
     - 類似 Phase の検索
     - 過去の教訓の出力

参照ファイル:
  - .claude/logs/failures.log
  - .archive/plan/playbook-*.md
```

### plan-management Skill

```yaml
ファイル: .claude/skills/plan-management/SKILL.md
役割: Multi-layer planning and playbook management

発火タイミング:
  - playbook 作成時
  - phase 遷移時
  - "plan", "playbook", "phase", "roadmap", "milestone" キーワード検出時
  - session=task でのセッション開始時

内容:
  1. Plan Hierarchy Structure
     - roadmap → milestones → playbooks → phases
  2. Playbook Creation Flow
  3. Phase Transition Rules
     - 禁止遷移の定義
     - Phase 完了条件
  4. Four-Tuple Coherence
     - focus.current, layer.state, playbook, branch
  5. Session Start Checklist
  6. Integration with Hooks

参照ファイル:
  - plan/project.md: roadmap
  - playbook: phases
  - state.md: focus, plan_hierarchy
```

### context-management Skill

```yaml
ファイル: .claude/skills/context-management/SKILL.md
役割: /compact 最適化と履歴要約のガイドライン

発火タイミング:
  - /compact を実行する前
  - コンテキストが 80% を超えたとき
  - セッション終了時（履歴要約）

内容:
  1. /compact 最適化ガイドライン
     - 優先保持情報（高優先度）
     - 削除候補（低優先度）
     - 実行前チェックリスト
  2. 履歴要約ガイドライン
     - セッション終了時の要約フォーマット
     - 保存先: .claude/session-history/
  3. コンテキスト監視
     - thresholds: warning 70%, critical 80%, danger 90%
  4. コンテキスト外部化（context-log）
     - 記録先: .claude/logs/context-log.md
     - 記録フォーマット
     - 記録タイミング

参照ファイル:
  - state.md: goal.done_criteria
  - .claude/logs/context-log.md
  - .claude/session-history/
```

### execution-management Skill

```yaml
ファイル: .claude/skills/execution-management/SKILL.md
役割: 並列実行制御とリソース配分のガイドライン

発火タイミング:
  - 複数タスクを同時に実行するとき
  - コンテキストが逼迫しているとき
  - 効率的な実行順序を決めるとき

内容:
  1. 並列実行制御
     - parallel_safe: 並列実行可能なケース
     - sequential_required: 順次実行が必要なケース
     - 判断フロー
  2. リソース配分
     - コンテキストリソース管理
     - 時間リソース管理
     - 優先度ベースのリソース配分
  3. 効率化のベストプラクティス

参照ファイル:
  - なし（ガイドライン提供のみ）
```

### beginner-advisor Skill

```yaml
ファイル: .claude/skills/beginner-advisor/skill.md
役割: 初学者向けに専門用語を比喩で説明

発火タイミング:
  - state.md の learning_mode.expertise が beginner の場合
  - ユーザーが「説明して」「わからない」と言った場合
  - 専門用語を含む説明の後

内容:
  1. 責務
     - 専門用語の説明（比喩を使って 1-2 文）
     - 重要タイミングでの補足
  2. 用語辞書
     - Git 関連: リポジトリ、ブランチ、コミット等
     - 開発環境: Homebrew, Node.js, pnpm, VSCode
     - Web 開発: フレームワーク、API、デプロイ等
     - ファイル: .env.local, package.json, node_modules
  3. 説明タイミング
     - ブランチ作成時、コミット時、デプロイ時、マージ時
  4. 行動原則
     - 説明は短く、押し付けない

参照ファイル:
  - state.md: learning_mode.expertise
```

### frontend-design Skill

```yaml
ファイル: .claude/skills/frontend-design/SKILL.md
役割: プロダクション品質のフロントエンド UI 設計

発火タイミング:
  - フロントエンド UI を新規作成する
  - ページ / コンポーネントのデザインを改善する
  - 「もっとおしゃれに」「デザインを良くして」と言われた
  - ランディングページ / ポートフォリオを作成する

内容:
  1. デザイン思考
     - 目的を理解する
     - トーンを決める（9種類から選択）
     - 差別化を考える
  2. 美学ガイドライン
     - Typography（タイポグラフィ）
     - Color & Theme（色とテーマ）
     - Motion（モーション）
     - Spatial Composition（空間構成）
     - Visual Details（視覚的ディテール）
  3. 避けるべきパターン（AI 臭）
  4. 実装チェックリスト

参照ファイル:
  - なし（ガイドライン提供のみ）
```

### deploy-checker Skill

```yaml
ファイル: .claude/skills/deploy-checker/skill.md
役割: デプロイ準備・検証

発火タイミング:
  - git push 前の最終確認
  - ユーザーが「デプロイして」「公開して」と言った場合
  - done_criteria に「デプロイ」が含まれる場合

内容:
  1. チェック項目
     - 環境変数チェック
     - ビルドチェック
     - セキュリティチェック
     - デプロイ先チェック
  2. 実行手順（bash コマンド）
  3. 出力形式
  4. デプロイ手順
  5. トラブルシューティング
  6. 設定ファイル

参照ファイル:
  - .env.example
  - .gitignore
  - vercel.json
  - package.json
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | M009 対応。全 Hooks/SubAgents/Skills の詳細仕様を追加。 |
| 2025-12-13 | M008 対応。初版作成。 |
