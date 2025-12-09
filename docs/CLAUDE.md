# docs/

> **ドキュメント - 仕様書・運用ルール・開発履歴**

---

## 役割

このフォルダは、プロジェクトの仕様書、運用ルール、開発履歴を保存します。
必要な時にのみ参照され、毎回読まれるわけではありません。

---

## ファイル分類

### コア仕様（必要時参照）

| ファイル | 役割 | 参照タイミング |
|----------|------|----------------|
| current-implementation.md | 現在実装の棚卸し（Single Source of Truth） | 構造変更時、復旧時 |
| extension-system.md | Claude Code 公式リファレンス | 拡張機能確認時 |

### 運用ルール（必要時参照）

| ファイル | 役割 | 参照タイミング |
|----------|------|----------------|
| git-operations.md | git 操作ガイド | git 操作時 |
| archive-operation-rules.md | アーカイブ操作ルール | アーカイブ時 |
| artifact-management-rules.md | 成果物管理ルール | 成果物操作時 |

### 開発履歴・分析（限定的参照）

| ファイル | 役割 | 参照タイミング |
|----------|------|----------------|
| file-inventory.md | ファイル棚卸し | 構造確認時 |
| task-initiation-flow.md | タスク開始フロー設計 | フロー確認時 |
| test-results.md | テスト結果記録 | テスト参照時 |
| coderabbit-evaluation.md | CodeRabbit 評価 | ツール評価時 |

### 設計・分析ドキュメント（アーカイブ候補）

| ファイル | 役割 |
|----------|------|
| phase-files-analysis.md | Phase ファイル分析 |
| playbook-archive-analysis.md | playbook アーカイブ分析 |
| archive-process-design.md | アーカイブプロセス設計 |
| artifact-health-verification.md | 成果物健全性検証 |
| file-creation-process-design.md | ファイル作成プロセス設計 |

---

## 設計原則

```yaml
原則:
  - 削減ではなく構造化
  - 全機能は担保される
  - 必要な時にのみ参照される

コア仕様:
  - current-implementation.md: 復旧可能な仕様書として維持
  - extension-system.md: 公式リファレンスとして維持

運用ルール:
  - 実際の操作時にのみ参照
  - CLAUDE.md から @参照で呼び出し可能

開発履歴:
  - 過去の分析・設計記録
  - 必要に応じてアーカイブ可能
```

---

## 連携

- **state.md** → 参照ファイル一覧で docs/ を指定
- **CLAUDE.md** → 必要に応じて @参照で呼び出し
- **playbook** → Phase 作業中に必要なドキュメントを参照
