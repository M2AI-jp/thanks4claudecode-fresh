# フォルダ管理ルール

> **全フォルダの役割、テンポラリ/永続区分、削除タイミングを定義**

---

## 概要

このドキュメントは、thanks4claudecode リポジトリ内のフォルダ構造と、
各フォルダに配置するファイルのルールを定義します。

### 基本原則

```yaml
原則:
  1. テンポラリファイルは tmp/ に統一
  2. 永続ファイルは適切なフォルダに配置
  3. playbook 完了時に自動クリーンアップ
  4. アーカイブは .archive/ に統一
```

---

## フォルダ一覧

### ルートディレクトリ

| フォルダ/ファイル | 区分 | 役割 | 削除タイミング |
|------------------|------|------|----------------|
| `.archive/` | 永続 | 過去のファイルのアーカイブ | 手動削除のみ |
| `.claude/` | 永続 | Claude Code 設定・拡張機能 | - |
| `docs/` | 永続 | ドキュメント（仕様書・運用ルール） | - |
| `plan/` | 永続 | プロジェクト計画・playbook | - |
| `setup/` | 永続 | セットアップガイド | - |
| `tmp/` | テンポラリ | 一時ファイル置き場 | playbook 完了時 |
| `CLAUDE.md` | 永続 | LLM の振る舞いルール | - |
| `state.md` | 永続 | 現在地を示す Single Source of Truth | - |
| `README.md` | 永続 | プロジェクト説明 | - |
| `AGENTS.md` | 永続 | SubAgent 一覧 | - |

### .claude/ 配下

| フォルダ | 区分 | 役割 | 削除タイミング |
|----------|------|------|----------------|
| `.claude/agents/` | 永続 | SubAgent 定義ファイル | - |
| `.claude/commands/` | 永続 | カスタムコマンド定義 | - |
| `.claude/hooks/` | 永続 | Hook スクリプト | - |
| `.claude/logs/` | 半永続 | ログファイル | 古いセッションログは定期削除 |
| `.claude/rules/` | 永続 | モジュラールール | - |
| `.claude/scripts/` | 永続 | ユーティリティスクリプト | - |
| `.claude/session-history/` | 半永続 | セッション履歴 | 古い履歴は定期削除 |
| `.claude/skills/` | 永続 | Skill 定義 | - |
| `.claude/templates/` | 永続 | テンプレートファイル | - |
| `.claude/tests/` | 永続 | Hook テスト | - |

### plan/ 配下

| フォルダ | 区分 | 役割 | 削除タイミング |
|----------|------|------|----------------|
| `plan/playbook-*.md` | 一時 | 進行中の playbook（直下に配置） | playbook 完了後に archive へ移動 |
| `plan/archive/` | 永続 | 完了した playbook のアーカイブ | - |
| `plan/template/` | 永続 | playbook テンプレート | - |
| `plan/project.md` | 永続 | プロジェクト計画 | - |

### docs/ 配下

| ファイル | 区分 | 役割 |
|----------|------|------|
| `repository-map.yaml` | 永続 | 全ファイルマッピング（★自動生成） |
| `extension-system.md` | 永続 | Claude Code 公式リファレンス |
| `criterion-validation-rules.md` | 永続 | done_criteria 検証ルール |
| `folder-management.md` | 永続 | フォルダ管理ルール（このファイル） |
| `archive-operation-rules.md` | 永続 | アーカイブ操作ルール |
| `artifact-management-rules.md` | 永続 | 成果物管理ルール |
| `git-operations.md` | 永続 | git 操作ガイド |

#### 全ファイル自動マッピング

```yaml
マスターマップ: docs/repository-map.yaml

自動更新タイミング:
  - playbook 完了時（cleanup-hook.sh 経由）

手動更新:
  bash .claude/hooks/generate-repository-map.sh

マッピング対象:
  - .claude/hooks/ - 全 Hook
  - .claude/agents/ - 全 SubAgent
  - .claude/skills/ - 全 Skill
  - .claude/commands/ - 全 Command
  - docs/ - 全ドキュメント
  - plan/ - active/archive/template
  - root - CLAUDE.md, state.md 等
```

### tmp/ 配下

| ファイル | 区分 | 役割 |
|----------|------|------|
| `README.md` | 永続 | 使い方説明（削除しない） |
| その他 | テンポラリ | 一時ファイル（playbook 完了時に自動削除） |

---

## テンポラリ vs 永続の判定基準

```yaml
テンポラリ（tmp/ に配置）:
  条件:
    - playbook 完了後に不要になる
    - 他のファイルに統合される予定
    - デバッグや検証目的
    - セッション固有の作業ファイル
  例:
    - テストシナリオ・結果
    - 一時的な分析レポート
    - 中間成果物
    - ログ出力

永続（docs/ 等に配置）:
  条件:
    - 長期的に参照される
    - 複数の playbook で利用される
    - プロジェクト全体の仕様を定義
    - 運用ルールを定義
  例:
    - 仕様書
    - 運用ルール
    - API リファレンス
    - 設計ドキュメント
```

---

## クリーンアップのタイミング

### 自動クリーンアップ

```yaml
トリガー: playbook の全 Phase が done
実行者: .claude/hooks/cleanup-hook.sh
対象:
  - tmp/ 内のファイル（README.md を除く）
  - 空のサブディレクトリ
```

### 手動クリーンアップ

```yaml
タイミング:
  - 不要と判断した時点で随時
  - セッション終了時（推奨）
  - /clear 実行前

対象:
  - tmp/ 内の不要ファイル
  - .claude/logs/sessions/ の古いセッションログ
  - .archive/ の古いファイル（必要に応じて）
```

### playbook 完了時の流れ

```
1. 全 Phase が done
      ↓
2. archive-playbook.sh がアーカイブを提案
      ↓
3. cleanup-hook.sh が tmp/ をクリーンアップ
      ↓
4. POST_LOOP で playbook を plan/archive/ に移動
      ↓
5. /clear 推奨アナウンス
```

---

## ファイル配置ルール

### 新規ファイル作成時の判断フロー

```
                    ┌─────────────────┐
                    │ ファイル作成    │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ playbook 完了後  │
                    │ も必要？         │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │ NO           │ YES          │
              ▼              ▼              │
    ┌─────────────────┐  ┌─────────────────┐
    │ tmp/ に配置     │  │ 適切なフォルダ  │
    │                  │  │ に配置          │
    └─────────────────┘  └─────────────────┘
```

### 配置先の選択

| 種類 | 配置先 |
|------|--------|
| テスト結果・シナリオ | `tmp/` |
| 一時的な分析 | `tmp/` |
| デバッグ出力 | `tmp/` |
| 中間成果物 | `tmp/` |
| 仕様書・設計書 | `docs/` |
| 運用ルール | `docs/` |
| Hook スクリプト | `.claude/hooks/` |
| SubAgent 定義 | `.claude/agents/` |
| Skill 定義 | `.claude/skills/*/` |
| playbook | `plan/` |
| 完了した playbook | `plan/archive/` |
| アーカイブ（過去のファイル） | `.archive/` |

---

## .archive/ の構造

```
.archive/
├── docs/           # 古いドキュメント
├── plan/           # 古い playbook（plan/archive/ と併用）
├── plan-archive/   # 古い plan アーカイブ
├── test-m012/      # M012 のテスト成果物
├── logs/           # 古いログ
├── hooks/          # 古い Hook
└── .claude/        # 古い .claude 設定
```

---

## 禁止事項

```yaml
禁止:
  - ルート直下に一時ファイルを作成
  - docs/ に中間成果物を作成（後で削除が必要になる）
  - test/ フォルダの新規作成（tmp/ を使用）
  - 複数のアーカイブ先を作成（.archive/ に統一）
  - tmp/ に重要なファイルを配置

推奨:
  - 一時ファイルは必ず tmp/ に配置
  - 永続ファイルは最初から適切なフォルダに配置
  - アーカイブは .archive/ に統一
```

---

## 定期メンテナンス

### 推奨タイミング

```yaml
日次:
  - tmp/ の不要ファイル削除確認

週次:
  - .claude/logs/sessions/ の古いログ削除（1週間以上前）

月次:
  - .archive/ の整理（必要に応じて）
  - 未使用ドキュメントの確認
```

### メンテナンスコマンド例

```bash
# tmp/ の内容確認
ls -la tmp/

# 古いセッションログの削除（7日以上前）
find .claude/logs/sessions -mtime +7 -type f -delete

# .archive/ のサイズ確認
du -sh .archive/
```

---

## 連携ドキュメント

- `CLAUDE.md` - LLM の振る舞いルール
- `docs/archive-operation-rules.md` - アーカイブ操作ルール
- `.claude/hooks/cleanup-hook.sh` - クリーンアップ Hook
- `plan/template/playbook-format.md` - playbook テンプレート

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | docs/manifest.yaml 管理ルールを追加。docs/ ファイル管理セクション拡充。 |
| 2025-12-13 | 初版作成。M014 対応。 |
