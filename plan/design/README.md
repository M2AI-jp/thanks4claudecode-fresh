# plan/design/

> **設計ドキュメント - アーキテクチャと思想の詳細説明**

---

## 役割

このフォルダは、プロジェクトのアーキテクチャ設計や思想を詳細に説明するドキュメントを保存します。
ミッションや設計の根拠を提供します。

---

## ドキュメント一覧

| ファイル | 役割 | 参照タイミング |
|----------|------|----------------|
| mission.md | 最上位概念（存在意義） | セッション開始時、方向性の確認時 |
| self-healing-system.md | Self-Healing System 設計 | 自己修復機能の実装・改善時 |
| repository-health-master-plan.md | 健全性メンテの上位設計 | 大規模メンテ開始時 |

---

## 各ドキュメントの詳細

### mission.md

- **目的**: プロジェクトの存在意義を定義
- **内容**:
  - mission statement（使命宣言）
  - core_values（自律性、信頼性、自己認識、自己修復、目的一貫性）
  - anti-patterns（報酬詐欺の定義）
  - guardrails（mission を守る仕組み）
  - success_criteria（達成基準）
- **参照タイミング**: 方向性に迷った時、判断の根拠を確認する時

### self-healing-system.md

- **目的**: 自己修復システムの詳細設計
- **内容**:
  - Context Continuity（compact 後の状態復元）
  - Document Freshness（ドキュメント鮮度管理）
  - Feature Verification（機能検証）
  - Self-Improvement（失敗学習）
- **参照タイミング**: 自己修復機能の実装・改善時

### repository-health-master-plan.md

- **目的**: リポジトリ健全性メンテナンスの上位設計
- **内容**:
  - 判定基準（必須/壊れている/不要）
  - 依存抽出→分類→ドキュメント更新の手順
  - 証拠ルールとメンテ方針
- **参照タイミング**: 大規模メンテ開始時、更新計画立案時

---

## 連携

```
plan/design/mission.md (最上位概念)
        │
        └── self-healing-system.md (自己修復の設計)
                └── repository-health-master-plan.md (健全性メンテ設計)
```

---

## 注意事項

- 設計ドキュメントは「なぜそうするか」を説明
- 実装の詳細は docs/current-implementation.md を参照

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-10 | 初版作成。設計ドキュメントの役割と参照タイミングを説明。 |
