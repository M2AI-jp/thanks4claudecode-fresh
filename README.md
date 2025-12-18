# thanks4claudecode

> **Claude Code の自律性と品質を向上させるフレームワーク**
>
> 報酬詐欺防止、計画駆動開発、構造的強制を実装。52 の E2E テストで動作を保証。

**GitHub**: https://github.com/M2AI-jp/thanks4claudecode-fresh

---

## クイックスタート

```bash
# リポジトリをクローン
git clone https://github.com/M2AI-jp/thanks4claudecode-fresh.git
cd thanks4claudecode-fresh

# Claude Code で開く
claude

# 動作確認（E2E テスト）
bash scripts/e2e-contract-test.sh
# 結果: 52/52 PASS
```

### 基本的な使い方

1. **タスクを依頼する** → pm SubAgent が自動で playbook（計画書）を作成
2. **playbook に従って作業** → Hook が構造的に制御
3. **完了時に critic が検証** → 報酬詐欺を防止

---

## 主要機能

| 機能 | 説明 | 実装状況 |
|------|------|----------|
| 報酬詐欺防止 | critic SubAgent が done_when の達成を検証 | 動作 |
| 計画駆動開発 | playbook なしでの Edit/Write をブロック | 動作（52 E2E PASS） |
| 構造的強制 | Hook で LLM の意思に依存しない制御 | 動作 |
| 3層自動運用 | project → playbook → phase の自動進行 | 動作（pm SubAgent） |
| コンテキスト外部化 | state.md で状態を永続化 | 動作 |
| 整合性チェック | check-integrity.sh で参照・アーカイブ漏れを検出 | 動作 |

---

## アーキテクチャ

```
CLAUDE.md（262行）
  ↓ 思考制御
Hook（32個）
  ↓ 構造的強制
SubAgent（6個）+ Skill（9個）+ Command（8個）
  ↓ 検証・専門知識
state.md ← Single Source of Truth
```

### Contract System

全ての契約判定を `scripts/contract.sh` に集約:

```bash
contract_check_edit()   # Edit/Write の判定
contract_check_bash()   # Bash コマンドの判定
is_hard_block()         # 絶対保護ファイル判定
is_compound_command()   # 複合コマンド検出
```

### Core Contract（admin でも回避不可）

- **Golden Path**: タスク依頼 → pm 必須
- **Playbook Gate**: playbook=null で Edit/Write/Bash 変更系をブロック
- **HARD_BLOCK**: CLAUDE.md 等の保護ファイルは編集不可

---

## ファイル構造

```
.
├── CLAUDE.md               # ルールブック（262行）
├── RUNBOOK.md              # 運用手順
├── state.md                # 現在の状態
├── plan/
│   ├── project.md          # プロジェクト計画（82 milestone）
│   ├── archive/            # 完了した playbook
│   └── template/           # playbook テンプレート
├── scripts/
│   ├── contract.sh         # 契約判定中核
│   └── e2e-contract-test.sh # E2E テスト（52件）
├── .claude/
│   ├── hooks/              # Hook（32個）
│   ├── agents/             # SubAgent（6個）
│   ├── skills/             # Skill（9個）
│   ├── commands/           # Command（8個）
│   └── settings.json       # Hook 登録
└── docs/
    ├── core-contract.md    # コア契約仕様
    └── admin-contract.md   # Admin 権限仕様
```

---

## E2E テスト

```bash
# 全テスト実行
bash scripts/e2e-contract-test.sh all
# 結果: PASS 52, FAIL 0

# シナリオ別実行
bash scripts/e2e-contract-test.sh scenario_a  # playbook=null & non-admin
bash scripts/e2e-contract-test.sh scenario_b  # playbook=null & admin
bash scripts/e2e-contract-test.sh scenario_c  # playbook=active
```

### 整合性チェック

```bash
bash .claude/hooks/check-integrity.sh
# [1/5] commands → hooks 参照チェック
# [2/5] state.md 参照チェック
# [3/5] agents → framework 参照チェック
# [4/5] settings.json → hooks 参照チェック
# [5/5] achieved milestone のアーカイブ漏れチェック
```

---

## SubAgent 一覧

| SubAgent | 役割 |
|----------|------|
| pm | playbook 作成・進捗管理 |
| critic | done_when 達成検証（報酬詐欺防止） |
| reviewer | playbook レビュー |
| codex-delegate | Codex MCP 呼び出し |
| health-checker | システム状態監視 |
| setup-guide | セットアップガイド |

---

## 開発履歴

- **82 milestone** を達成（M001〜M082）
- **52 E2E テスト** で契約システムを保証
- **CLAUDE.md** を 648行 → 262行に最適化

---

## 連絡先

[M2AI-jp](https://github.com/M2AI-jp) が管理。Issue/PR 歓迎。
