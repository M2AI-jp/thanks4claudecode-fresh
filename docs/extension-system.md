# Claude Code 拡張システム体系

> **公式リファレンスに基づく発火タイミング・トリガー・連携の完全ガイド**
>
> Sources:
> - https://code.claude.com/docs/ja/hooks
> - https://code.claude.com/docs/ja/plugins-reference

---

## 概要: 4つの拡張メカニズム

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Claude Code 拡張システム                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │    Hooks     │  │  SubAgents   │  │    Skills    │  │   Commands   │ │
│  │  イベント駆動  │  │   委譲型     │  │  自動発見型   │  │  明示呼出型   │ │
│  │              │  │              │  │              │  │              │ │
│  │ PreToolUse   │  │ Task ツール  │  │ 説明ベース   │  │ /command     │ │
│  │ PostToolUse  │  │ で委譲       │  │ 自動起動     │  │ で起動       │ │
│  │ SessionStart │  │              │  │              │  │              │ │
│  │ など         │  │              │  │              │  │              │ │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                                          │
│  発火: 自動         発火: 自動/手動    発火: 自動         発火: 手動      │
│  制御: ブロック可   制御: 独立実行     制御: コンテキスト  制御: プロンプト │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 1. Hooks（イベント駆動型）

### 1.1 利用可能な Hook イベント（10種類）

| イベント | 発火タイミング | matcher | 主な用途 |
|---------|--------------|---------|---------|
| **PreToolUse** | ツール実行前（パラメータ作成後） | ○ | 権限制御、パラメータ変更、ブロック |
| **PostToolUse** | ツール実行成功後 | ○ | 結果検証、追加コンテキスト注入 |
| **PermissionRequest** | 権限ダイアログ表示時 | ○ | 権限判定のカスタマイズ |
| **UserPromptSubmit** | ユーザープロンプト送信時 | - | 入力検証、コンテキスト追加 |
| **Stop** | メインエージェント停止試行時 | - | 継続判定、追加タスク指示 |
| **SubagentStop** | サブエージェント停止試行時 | - | サブタスク評価、継続判定 |
| **SessionStart** | セッション開始/再開時 | - | 環境初期化、変数設定 |
| **SessionEnd** | セッション終了時 | - | クリーンアップ、ログ記録 |
| **PreCompact** | コンテキスト圧縮前 | - | 重要情報の保持指示 |
| **Notification** | 通知送信時 | - | 通知カスタマイズ |

### 1.2 Hook タイプ（3種類）

```yaml
command:      # シェルコマンドまたはスクリプト実行（最も一般的）
validation:   # ファイルコンテンツまたはプロジェクト状態検証
notification: # アラート、ステータス更新送信
```

### 1.3 matcher の仕様

```yaml
対象: PreToolUse, PostToolUse, PermissionRequest のみ

パターン:
  完全一致: "Write"           # Write ツールのみ
  正規表現: "Edit|Write"      # Edit または Write
  ワイルドカード: "*" または "" # 全ツール
  MCP: "mcp__server__tool"    # MCP ツール指定
```

### 1.4 入力データ（stdin JSON）

```yaml
共通フィールド:
  session_id: セッション識別子
  transcript_path: 会話ログパス
  cwd: 現在の作業ディレクトリ
  permission_mode: default|plan|acceptEdits|bypassPermissions
  hook_event_name: イベント名

イベント固有:
  PreToolUse: tool_name, tool_input, tool_use_id
  PostToolUse: tool_name, tool_input, tool_response
  UserPromptSubmit: prompt
  Stop/SubagentStop: stop_hook_active (boolean)
  SessionStart: source (startup|resume|clear|compact)
```

### 1.5 環境変数

| 変数 | 説明 | 利用可能時 |
|-----|------|----------|
| `CLAUDE_PROJECT_DIR` | プロジェクトルート絶対パス | 全 Hook |
| `CLAUDE_CODE_REMOTE` | リモート環境フラグ（"true"） | 全 Hook |
| `CLAUDE_ENV_FILE` | 環境変数永続化ファイル | SessionStart のみ |
| `${CLAUDE_PLUGIN_ROOT}` | プラグインディレクトリ絶対パス | プラグイン内 Hook |

### 1.6 出力と効果

```yaml
終了コード:
  0: 成功（stdout がコンテキストに追加される場合あり）
  2: ブロック（stderr がエラーメッセージ）
  その他: 警告表示、実行継続

JSON 出力（終了コード 0 時のみ処理）:
  共通:
    continue: false で Claude 停止
    stopReason: 停止理由
    systemMessage: ユーザー向け警告

  PreToolUse 専用:
    hookSpecificOutput:
      permissionDecision: allow|deny|ask
      permissionDecisionReason: 説明
      updatedInput: { 修正フィールド }

  UserPromptSubmit/Stop 専用:
    decision: block
    reason: ブロック理由

  PostToolUse 専用:
    hookSpecificOutput:
      additionalContext: 追加情報
```

### 1.7 連携パターン

```
SessionStart → [環境初期化]
     ↓
UserPromptSubmit → [入力検証]
     ↓
PreToolUse → [権限/パラメータ制御]
     ↓
[ツール実行]
     ↓
PostToolUse → [結果検証/コンテキスト追加]
     ↓
Stop/SubagentStop → [継続判定]
     ↓
SessionEnd → [クリーンアップ]
```

---

## 2. SubAgents（委譲型）

### 2.1 定義形式

```yaml
# .claude/agents/agent-name.md

---
name: agent-identifier        # 必須: 小文字・ハイフン
description: 機能と使用時機    # 必須: 自動委譲のトリガー
tools: Read, Grep, Glob       # 任意: 省略で全ツール継承
model: sonnet                 # 任意: sonnet|opus|haiku|inherit
permissionMode: default       # 任意: default|acceptEdits|bypassPermissions|plan|ignore
skills: skill1, skill2        # 任意: 自動ロードするスキル
capabilities:                 # 任意: 得意なタスクのリスト（プラグイン用）
  - task1
  - task2
---

システムプロンプト（詳細な指示）
```

### 2.2 発火トリガー

```yaml
自動委譲:
  - description に「PROACTIVELY」「AUTOMATICALLY」を含める
  - Claude がタスク内容と description を照合して判断

手動呼び出し:
  - ユーザー: "Use the critic subagent to review this"
  - Task ツール: Task(subagent_type='critic', prompt='...')

CLI 定義:
  claude --agents '{"name": {...}}'
```

### 2.3 ビルトイン SubAgent

| 名前 | 用途 | モデル | ツール制限 |
|-----|------|-------|----------|
| general-purpose | 複雑な多段階タスク | Sonnet | 全ツール |
| Explore | 読み取り専用検索 | Haiku | Read, Grep, Glob |
| Plan | 計画モード | Sonnet | Read, Grep, Glob, Bash |

### 2.4 特徴

- 独立したコンテキストウィンドウ
- ツール/権限の制限可能
- 再開機能（agentId 指定）
- エージェントチェーン（複数 SubAgent の連携）

---

## 3. Skills（自動発見型）

### 3.1 定義形式

```yaml
# .claude/skills/skill-name/SKILL.md

---
name: skill-identifier        # 必須: 小文字・数字・ハイフン（最大64文字）
description: 機能と使用時機    # 必須: 自動発見のキー（最大1024文字）
---

スキルの詳細説明と指示
```

### 3.2 補足ファイル

```
.claude/skills/skill-name/
├── SKILL.md           # 必須
├── reference.md       # 任意: 参考資料
├── examples.md        # 任意: 使用例
├── scripts/           # 任意: 検証スクリプト
└── templates/         # 任意: テンプレート
```

### 3.3 発火トリガー

```yaml
トリガー: モデル呼び出し（Model-Invoked）

判断基準:
  - ユーザーリクエストの内容
  - Skill の description との照合
  - 現在のコンテキスト

効果的な description 例:
  "PDF ファイルのテキストと表を抽出、フォームを記入。
   PDF やフォーム、ドキュメント抽出について言及される場合に使用"

NG 例:
  "PDF を処理します"  # 曖昧すぎて発見されにくい
```

---

## 4. Slash Commands（明示呼出型）

### 4.1 定義形式

```yaml
# .claude/commands/command-name.md

---
description: コマンドの説明
allowed-tools: Bash(git:*), Read  # 任意: ツール制限
model: sonnet                     # 任意: モデル指定
argument-hint: <issue-number>     # 任意: 引数ヒント
---

プロンプトテンプレート
$ARGUMENTS を使用して引数を受け取る
$1, $2 で位置引数にアクセス
```

### 4.2 パラメータ

```yaml
$ARGUMENTS: 全引数（スペース区切り）
$1, $2, $N: 位置引数

例:
  /review-pr 123 high alice
  → $ARGUMENTS = "123 high alice"
  → $1 = "123", $2 = "high", $3 = "alice"
```

### 4.3 特殊構文

```yaml
ファイル参照: @path/to/file.js
コマンド実行: !`git status`
```

---

## 5. 連携マトリクス

### 5.1 Hook → SubAgent 連携

```yaml
パターン:
  1. Hook で条件検出 → SubAgent 呼び出し指示
  2. SubagentStop Hook でサブタスク評価

例:
  # PreToolUse で Edit 検出 → critic 呼び出しを additionalContext で指示
  # SubagentStop で critic 結果を評価 → 継続/ブロック判定
```

### 5.2 Hook → Skill 連携

```yaml
パターン:
  Hook の stdout/additionalContext でスキル使用を促す

例:
  # PostToolUse(Write) で TypeScript ファイル検出
  # → "lint-checker スキルを使用してください" を出力
```

### 5.3 SubAgent → Skill 連携

```yaml
パターン:
  SubAgent 定義に skills フィールドで自動ロード

例:
  ---
  name: code-reviewer
  skills: lint-checker, test-runner
  ---
```

---

## 6. 設計パターン

### 6.1 ガードパターン（PreToolUse）

```bash
# 条件チェック → ブロック or 許可
if [[ 条件 ]]; then
  echo "理由" >&2
  exit 2  # ブロック
fi
exit 0  # 許可
```

### 6.2 検証パターン（PostToolUse）

```bash
# 結果検証 → 追加コンテキスト注入
result=$(検証コマンド)
if [[ $result != "OK" ]]; then
  echo '{"hookSpecificOutput":{"additionalContext":"修正が必要"}}'
fi
exit 0
```

### 6.3 継続判定パターン（Stop）

```bash
# タスク完了判定 → 継続 or 停止
if [[ 未完了条件 ]]; then
  echo '{"decision":"block","reason":"追加タスクがあります"}'
fi
exit 0
```

### 6.4 環境初期化パターン（SessionStart）

```bash
# 環境変数設定 → CLAUDE_ENV_FILE に書き込み
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'export VAR=value' >> "$CLAUDE_ENV_FILE"
fi
# コンテキスト追加
echo "初期化情報をここに出力"
exit 0
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | 初版作成。公式リファレンスに基づく体系化。 |
