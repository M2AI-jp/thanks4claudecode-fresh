# AI エージェントオーケストレーション

> **役割ベース executor 抽象化 - playbook の再利用性向上**

---

## 概要

AI エージェントオーケストレーションは、playbook の `executor` フィールドを
抽象的な役割名で指定できるようにする仕組みです。

**問題**: 現在の executor は具体的なツール名（claudecode, codex, coderabbit, user）を直接指定
**解決**: 抽象的な役割名（orchestrator, worker, reviewer, human）を使用し、実行時に解決

---

## 役割定義

| 役割 | 説明 | Toolstack A | Toolstack B | Toolstack C |
|------|------|-------------|-------------|-------------|
| orchestrator | 監督・調整・設計 | claudecode | claudecode | claudecode |
| worker | 本格的なコード実装 | claudecode | codex | codex |
| reviewer | コードレビュー | claudecode | claudecode | coderabbit |
| human | 人間の介入 | user | user | user |

---

## 解決優先順位

役割名から具体的な executor への解決は以下の優先順位で行われます：

```
1. playbook.meta.roles（playbook 固有の override）
2. state.md config.roles（プロジェクト全体のデフォルト）
3. ハードコードされたデフォルト（上記の表）
```

### 例：解決フロー

```
playbook.subtask.executor: "worker"
              ↓
    ┌─────────────────────┐
    │  role-resolver.sh   │
    └─────────┬───────────┘
              ↓
    1. playbook.meta.roles.worker を確認 → 未定義
    2. state.md config.roles.worker を確認 → 未定義
    3. デフォルト（toolstack B）→ "codex"
              ↓
    executor-guard.sh で toolstack チェック
              ↓
           実行
```

---

## 使用方法

### playbook での役割指定

```yaml
# subtask で役割名を使用
- [ ] **p1.1**: 機能を実装する
  - executor: worker  # 抽象的な役割名
  - validations:
    - technical: "npm test で動作確認"
    - consistency: "既存コードと整合性確認"
    - completeness: "全機能が実装されているか確認"
```

### playbook での役割 override

```yaml
# playbook meta で役割を override
meta:
  project: example
  roles:
    worker: claudecode  # この playbook では worker = claudecode
```

### state.md でのデフォルト設定

```yaml
# state.md config セクション
config:
  security: admin
  toolstack: B
  roles:
    orchestrator: claudecode
    worker: codex
    reviewer: claudecode
    human: user
```

---

## 互換性

既存の executor 名（claudecode, codex, coderabbit, user）はそのまま使用可能です。
役割名は追加オプションであり、既存の playbook を変更する必要はありません。

```yaml
# これまで通り直接指定も可能
- [ ] **p1.1**: 機能を実装する
  - executor: codex  # 具体的な executor 名（従来通り）
```

---

## Codex MCP 統合（M078）

> **TTY 制約を回避するため、Codex CLI から Codex MCP に移行**

### 背景

Codex CLI は対話型ターミナル（TTY）を必要とするため、Claude Code の SubAgent から
直接呼び出すことができませんでした（stdin がパイプになるため起動しない）。

### 解決策

Codex を MCP サーバーとして起動し、Claude Code から MCP ツールとして呼び出す。

```
Claude Code → mcp__codex__codex → Codex MCP Server → コード生成
```

### 設定方法

#### 1. .claude/mcp.json を作成

```json
{
  "mcpServers": {
    "codex": {
      "command": "codex",
      "args": ["mcp-server"],
      "env": {},
      "timeout": 600000
    }
  }
}
```

#### 2. Claude Code を再起動

MCP サーバー設定を読み込むため、Claude Code を再起動します。

#### 3. MCP ツールを使用

```yaml
# 新規セッション
mcp__codex__codex:
  prompt: "実装内容"
  model: "o3"  # オプション

# 継続会話
mcp__codex__codex-reply:
  prompt: "追加指示"
  conversationId: "前回のセッションID"
```

### 注意事項

- **タイムアウト**: Codex は処理に数分かかる場合があるため、timeout を 600000ms（10分）に設定
- **Codex CLI**: `npm install -g @openai/codex` でインストール済みであること
- **OPENAI_API_KEY**: 環境変数に設定済みであること

### 参考リンク

- [Codex MCP 公式ドキュメント](https://developers.openai.com/codex/mcp/)
- [Codex CLI GitHub](https://github.com/openai/codex)

---

## 実装詳細

### role-resolver.sh

役割名を具体的な executor に解決するユーティリティスクリプト。

```bash
# 使用例
echo 'worker' | bash .claude/hooks/role-resolver.sh
# 出力: codex（toolstack B の場合）

bash .claude/hooks/role-resolver.sh orchestrator
# 出力: claudecode
```

### executor-guard.sh との連携

executor-guard.sh は role-resolver.sh を呼び出し、解決後の executor を
toolstack に対してチェックします。

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-18 | Codex MCP 統合追加（M078） |
| 2025-12-17 | 初版作成（M073） |
