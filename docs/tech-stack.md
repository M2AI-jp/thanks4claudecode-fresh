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

## 関連ドキュメント

| ドキュメント | 内容 |
|-------------|------|
| [feature-map.md](./feature-map.md) | Hooks/SubAgents/Skills の一覧と連携フロー |
| [CLAUDE.md](../CLAUDE.md) | LLM の行動ルール |
| [playbook-format.md](../plan/template/playbook-format.md) | playbook のテンプレート |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | M008 対応。初版作成。 |
