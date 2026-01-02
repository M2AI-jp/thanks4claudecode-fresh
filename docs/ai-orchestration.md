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
  model: "opus"  # オプション

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

## playbook_reviewer 仕様

> **報酬詐欺防止のための独立検証エージェント**
> criteria がクリアされるまで LOOP する仕組みの核心部分

### 役割

- playbook の done_when が「本当に」達成されているか独立検証
- 作成者の PASS 判定を鵜呑みにしない
- 自分でコードを実行して証拠を収集
- **FAIL の場合、該当 subtask を特定して返す（親 Claude が再実行）**

### LOOP メカニズム

```
実装フェーズ (p1 → p2 → p3 → p4)
              ↓
p_final: playbook_reviewer による独立検証
              ↓
         ┌─────────┐
         │  PASS?  │
         └────┬────┘
         YES  │  NO
    ┌────────┴────────┐
    ↓                 ↓
reviewed: true    FAIL した subtask を特定
→ アーカイブ      親 Claude が再実行
                  → 再度 playbook_reviewer
                        ↑        │
                        └────────┘
                          LOOP
```

**重要**: FAIL 時は「レポート」ではなく、「再実行すべき subtask」を返す。
親 Claude (orchestrator) がその subtask を再実行し、再度 playbook_reviewer を呼ぶ。

### 検証タイプ

| タイプ | 判定条件 | 検証内容 |
|--------|----------|----------|
| コードタスク | `coding: true` | 構文チェック + 実行テスト + edge case |
| 非コードタスク | `coding: false` | 存在確認 + 内容確認 |

### 独立性の担保

```yaml
禁止:
  - 作成者が書いた「PASS」を見る
  - playbook の [x] チェックボックスを信じる
  - validations の結果文字列を鵜呑みにする

必須:
  - 自分で検証コマンドを実行
  - edge case を自分で考えて追加テスト
  - 疑わしきは FAIL
```

### 出力形式

```yaml
# PASS の場合
result: PASS
action: reviewed: true に設定し、アーカイブ可能

# FAIL の場合
result: FAIL
failed_items:
  - item: "done_when 項目"
    related_subtask: p2.3  # ← 親 Claude はこれを再実行
    fix_hint: "修正のヒント"
action: 親 Claude は related_subtask を再実行
```

### 制約

- **配置**: p_final の最後の subtask として必須
- **条件**: reviewed: true でなければアーカイブ不可
- **原則**: 疑わしきは FAIL

### 詳細仕様

→ `.claude/frameworks/playbook-reviewer-spec.md` を参照

---

## オーケストレーション自動化（M085）

> **pm が playbook 作成時に executor を自動判定・自動割り当て**

### 概要

タスク内容から自動的に適切な executor を判定し、playbook に割り当てる仕組み。
これにより、ユーザーが executor を明示的に指定しなくても、適切な役割分担が行われる。

### タスク分類パターン

| パターン | キーワード例 | 自動割り当て | 解決後 (Toolstack B) |
|----------|-------------|-------------|---------------------|
| coding_task | 実装, コーディング, ロジック, リファクタリング, 修正 | worker | codex |
| review_task | レビュー, 検証, チェック, 監査 | reviewer | claudecode |
| human_task | アカウント, 登録, 支払い, 手動, 確認 | human | user |
| default | 上記以外 | orchestrator | claudecode |

### 自動化フロー

```
ユーザー: "認証機能を実装して"
              ↓
    ┌─────────────────────┐
    │      pm.md          │ タスク分類ロジック
    └─────────┬───────────┘
              ↓ "実装" キーワード → coding_task
    ┌─────────────────────┐
    │   playbook 作成     │ executor: worker
    └─────────┬───────────┘
              ↓
    ┌─────────────────────┐
    │  role-resolver.sh   │ worker → codex (Toolstack B)
    └─────────┬───────────┘
              ↓
    ┌─────────────────────┐
    │  executor-guard.sh  │ ブロック + SubAgent 案内
    └─────────┬───────────┘
              ↓
    ┌─────────────────────┐
    │  SubAgent 呼び出し  │ Task(subagent_type='codex-delegate')
    └─────────────────────┘
```

### executor-guard.sh の案内

executor-guard.sh は、ブロック時に適切な SubAgent の呼び出し方を案内する：

```
# codex ブロック時の案内
正しい手順（M085: SubAgent 呼び出し）:
  Task(subagent_type='codex-delegate', prompt='実装内容を説明')

代替手順（Codex MCP 直接実行）:
  mcp__codex__codex(prompt='実装内容を説明')

# coderabbit ブロック時の案内
正しい手順（M085: SubAgent 呼び出し）:
  Task(subagent_type='reviewer', prompt='レビュー対象を説明')
```

### Hook → Skill → SubAgent 構造

```yaml
構造設計:
  Hook: 導火線（トリガー）
  Skill: 親（エントリーポイント）
  SubAgent: パッケージ（動作保証された実行単位）

利点:
  - 動線が分離しない（安定性）
  - 新規機能追加が最小限
  - 各レイヤーの責任が明確
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-23 | オーケストレーション自動化追加（M085: タスク分類、SubAgent 案内） |
| 2025-12-23 | playbook_reviewer 仕様追加（LOOP メカニズム、独立検証） |
| 2025-12-18 | Codex MCP 統合追加（M078） |
| 2025-12-17 | 初版作成（M073） |
