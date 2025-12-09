# .claude/hooks/

> **Hooks - 構造的強制を実現するシェルスクリプト群**

---

## 役割

Hooks は Claude Code のイベントにフックして実行されるシェルスクリプトです。
LLM の行動に依存しない構造的強制を実現します。

---

## 三位一体アーキテクチャ

```
┌─────────────────────────────────────────────────────────┐
│  Hooks（構造的強制）+ SubAgents（検証）+ CLAUDE.md（思考制御）  │
│                                                          │
│  単独では機能しない。組み合わせて初めて強制力を持つ。          │
└─────────────────────────────────────────────────────────┘
```

---

## Hook のトリガー

| トリガー | 発火タイミング |
|----------|----------------|
| SessionStart | セッション開始時 |
| PreToolUse | ツール実行前（Edit/Write/Bash 等） |
| PostToolUse | ツール実行後 |
| Stop | セッション終了時 |

---

## 主要な Hooks

### セッション管理

| Hook | トリガー | 役割 |
|------|----------|------|
| session-start.sh | SessionStart | 初期化、pending/consent ファイル作成 |
| stop-summary.sh | Stop | セッション終了サマリー出力 |

### ガード系

| Hook | トリガー | 役割 |
|------|----------|------|
| init-guard.sh | PreToolUse | Read 必須チェック |
| playbook-guard.sh | PreToolUse:Edit/Write | playbook 存在チェック |
| consent-guard.sh | PreToolUse:Edit/Write | 合意ファイルチェック |
| check-protected-edit.sh | PreToolUse:Edit/Write | 保護ファイルチェック |

### 自動処理

| Hook | トリガー | 役割 |
|------|----------|------|
| archive-playbook.sh | PostToolUse | playbook 完了時のアーカイブ提案 |
| lint-check.sh | PreToolUse:Bash | 静的解析（ESLint/ShellCheck/Ruff） |

---

## 設定

Hooks は `.claude/settings.json` で登録されます：

```json
{
  "hooks": {
    "SessionStart": [{ "command": ".claude/hooks/session-start.sh" }],
    "PreToolUse": [{ "matcher": "Edit", "command": ".claude/hooks/playbook-guard.sh" }]
  }
}
```

---

## 連携

- **SubAgents** → Hook がトリガーとなり SubAgent を呼び出す
- **Skills** → Hook 内で参照される場合あり
- **state.md** → Hook が state.md を読み書き
