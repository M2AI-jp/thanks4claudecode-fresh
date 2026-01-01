# Executor フォールバックポリシー

> **executor 失敗時の対応方針を定義する**

---

## 概要

playbook で指定された executor（codex/coderabbit/user）が失敗した場合の対応方針。
**重要**: フォールバック時は必ずユーザー確認が必要。無言での代行は禁止。

---

## Codex フォールバック

### 失敗パターンと対応

| 失敗パターン | 対応 | ユーザー確認 |
|-------------|------|-------------|
| MCP タイムアウト（-32001 AbortError） | CLI 直接実行に切り替え | 必須 |
| MCP 接続エラー | CLI 直接実行に切り替え | 必須 |
| Codex CLI エラー | 再試行 → 失敗時は claudecode 代行 | 必須 |
| 認証エラー | ユーザーに認証情報確認を依頼 | 必須 |

### Codex MCP 失敗時の手順

1. **再試行**: 同じプロンプトで最大 3 回再試行
2. **CLI フォールバック**: MCP が不安定な場合、CLI 直接実行に切り替え
   ```bash
   codex exec "{プロンプト}"
   ```
3. **ユーザー確認**: CLI も失敗する場合、以下の選択肢を提示
   - 再試行
   - claudecode で代行（playbook の executor を変更必須）
   - 中止

### CLI 直接実行の有効性

`codex exec` による CLI 直接実行は `executor: codex` として有効とみなす。
理由: 同じ Codex エンジン（GPT-5.2-Codex）を使用しており、MCP は通信レイヤーに過ぎない。

**executor-guard での扱い**:
- `mcp__codex__codex` 呼び出し → OK
- `codex exec` Bash 呼び出し → OK（codex-delegate SubAgent 経由を推奨）
- Claude Code が直接 Edit/Write → BLOCK

---

## p3-p7 で使用可能な Codex コマンド例

### MCP 経由（推奨）

```python
# Task ツールで codex-delegate SubAgent を使用
Task(
    subagent_type='codex-delegate',
    prompt='ファイル src/auth.ts を作成し、JWT 認証ロジックを実装する'
)
```

### CLI 直接実行（MCP 失敗時のフォールバック）

```bash
# ファイル作成
codex exec "Create file src/auth.ts with JWT authentication logic"

# テスト実行
codex exec "Run npm test and fix any failing tests"

# コード分析
codex exec "Analyze .claude/skills/playbook-gate/guards/*.sh for security issues"

# リファクタリング
codex exec "Refactor tests/guards/test-critic-guard.sh to add 10 more test cases"
```

### 複雑なタスクの分割

長いプロンプトがタイムアウトする場合、タスクを分割：

```bash
# NG: 長すぎるプロンプト
codex exec "Create comprehensive test suite with 40 test cases covering..."

# OK: 分割したプロンプト
codex exec "Create 10 test cases for happy path scenarios"
codex exec "Create 10 test cases for error handling"
codex exec "Create 10 test cases for edge cases"
codex exec "Create 10 test cases for security validation"
```

---

## CodeRabbit フォールバック

### 失敗パターンと対応

| 失敗パターン | 対応 | ユーザー確認 |
|-------------|------|-------------|
| API エラー | 再試行 → reviewer SubAgent に切り替え | 必須 |
| レート制限 | 待機後再試行 | 任意 |
| 認証エラー | ユーザーに認証情報確認を依頼 | 必須 |

### CodeRabbit 失敗時の手順

1. **再試行**: 最大 3 回再試行
2. **reviewer SubAgent 代行**: CodeRabbit が使用不可の場合
   ```python
   Task(subagent_type='reviewer', prompt='コードレビューを実行')
   ```
3. **ユーザー確認**: 手動レビュー依頼

---

## User フォールバック

executor: user の場合、Claude Code は代行不可。
ユーザーが作業を完了するまで待機する。

### 確認フロー

1. 作業内容を明確に説明
2. チェックリスト形式で確認項目を提示
3. AskUserQuestion でユーザー確認
4. 確認後に次の Phase へ

---

## フォールバック時の証跡記録

フォールバックが発生した場合、playbook に以下を記録：

```yaml
- [x] **p3.1**: タスク完了 ✓
  - executor: codex
  - validations:
    - technical: "PASS - ..."
  - validated: 2026-01-01T10:00:00
  - executed_by: codex  # 実際の実行者
  - execution_log: "MCP タイムアウト後 CLI フォールバック: codex exec 'prompt'"
  - fallback_reason: "MCP -32001 AbortError"  # フォールバック理由
```

---

## AskUserQuestion による確認フロー（V17）

フォールバック時は必ず AskUserQuestion でユーザー確認を行う。

### Codex 失敗時の確認例

```python
AskUserQuestion(
    questions=[{
        "question": "Codex MCP がタイムアウトしました。どのように進めますか？",
        "header": "Fallback",
        "options": [
            {"label": "CLI で再試行", "description": "codex exec コマンドで実行"},
            {"label": "claudecode で代行", "description": "executor を変更して Claude Code が実行"},
            {"label": "中止", "description": "このタスクを中止"}
        ],
        "multiSelect": false
    }]
)
```

### CodeRabbit 失敗時の確認例

```python
AskUserQuestion(
    questions=[{
        "question": "CodeRabbit が応答しません。どのように進めますか？",
        "header": "Review",
        "options": [
            {"label": "再試行", "description": "CodeRabbit に再度リクエスト"},
            {"label": "reviewer SubAgent", "description": "Claude Code の reviewer で代行"},
            {"label": "スキップ", "description": "レビューをスキップして進む"}
        ],
        "multiSelect": false
    }]
)
```

### User 作業確認の例

```python
AskUserQuestion(
    questions=[{
        "question": "手動作業は完了しましたか？",
        "header": "User Task",
        "options": [
            {"label": "完了", "description": "作業完了。次に進む"},
            {"label": "作業中", "description": "まだ完了していない"},
            {"label": "中止", "description": "この作業を中止"}
        ],
        "multiSelect": false
    }]
)
```

### 重要なルール

1. **無言での代行禁止**: フォールバック時は必ず AskUserQuestion で確認
2. **executor 変更の記録**: claudecode で代行する場合は playbook の executor を変更
3. **証跡の記録**: フォールバック理由と確認結果を playbook に記録

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-01 | V17: AskUserQuestion による確認フロー追加。ガードメッセージにフォールバック手順を追記。 |
| 2026-01-01 | 初版作成。Codex/CodeRabbit/User のフォールバックポリシー定義。 |
