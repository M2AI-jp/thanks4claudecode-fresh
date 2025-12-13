# docs/

> **ドキュメント - 仕様書・運用ルール**
>
> 全ファイルマッピングは `docs/repository-map.yaml`（自動生成）

---

## 役割

このフォルダは、プロジェクトの仕様書、運用ルールを保存します。
必要な時にのみ参照され、毎回読まれるわけではありません。

---

## ファイル一覧

### マスターマップ（自動生成）

| ファイル | 役割 | 更新タイミング |
|----------|------|----------------|
| repository-map.yaml | 全ファイルマッピング | playbook 完了時（自動） |

### 仕様書

| ファイル | 役割 | 参照タイミング |
|----------|------|----------------|
| extension-system.md | Claude Code 公式リファレンス | 拡張機能確認時 |
| folder-management.md | フォルダ管理ルール | ファイル配置時 |

### 運用ルール

| ファイル | 役割 | 参照タイミング |
|----------|------|----------------|
| git-operations.md | git 操作ガイド | git 操作時 |
| archive-operation-rules.md | アーカイブ操作ルール | アーカイブ時 |
| artifact-management-rules.md | 成果物管理ルール | 成果物操作時 |
| criterion-validation-rules.md | done_criteria 検証ルール | playbook 作成時 |

---

## 自動マッピングシステム

```yaml
マスターマップ: docs/repository-map.yaml

自動更新:
  トリガー: playbook 完了時
  実行: .claude/hooks/cleanup-hook.sh
         → .claude/hooks/generate-repository-map.sh

手動更新:
  bash .claude/hooks/generate-repository-map.sh

マッピング内容:
  - Hooks（トリガー、説明）
  - SubAgents（説明）
  - Skills（説明）
  - Commands（説明）
  - Docs（説明）
  - Plan（active/archive/template）
  - Root files
```

---

## 設計原則

```yaml
原則:
  - repository-map.yaml で全ファイルを一元管理
  - playbook 完了時に自動更新
  - 手動編集は上書きされる

禁止:
  - テスト目的のファイル配置（tmp/ を使用）
  - 中間成果物の配置（tmp/ を使用）
```

---

## 連携

- **state.md** → 参照ファイル一覧で docs/ を指定
- **CLAUDE.md** → 必要に応じて @参照で呼び出し
- **playbook** → Phase 作業中に必要なドキュメントを参照
- **repository-map.yaml** → 全ファイルの自動マッピング
