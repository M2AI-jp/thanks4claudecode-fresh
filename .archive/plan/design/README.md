# plan/design/

> **設計ドキュメント - アーキテクチャと思想の詳細説明**

---

## 役割

このフォルダは、プロジェクトのアーキテクチャ設計や思想を詳細に説明するドキュメントを保存します。
project.md の vision を深堀りし、実装の根拠を提供します。

---

## ドキュメント一覧

| ファイル | 役割 | 参照タイミング |
|----------|------|----------------|
| mission.md | 最上位概念（存在意義） | セッション開始時、方向性の確認時 |
| self-healing-system.md | Self-Healing System 設計 | 自己修復機能の実装・改善時 |
| plan-chain-system.md | 計画連鎖システム設計 | playbook 作成、計画管理の改善時 |

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

### plan-chain-system.md

- **目的**: 計画連鎖システムの設計
- **内容**:
  - project.md → playbook の連鎖
  - derives_from による追跡
  - Phase 分割のルール
- **参照タイミング**: playbook 作成ルールの確認時

---

## 連携

```
project.md (vision)
    │
    └── plan/design/mission.md (vision の詳細)
            │
            ├── self-healing-system.md (自己修復の設計)
            └── plan-chain-system.md (計画管理の設計)
```

---

## 注意事項

- 設計ドキュメントは「なぜそうするか」を説明
- 実装の詳細は docs/current-implementation.md を参照
- 変更時は project.md の notes セクションとの整合性を確認

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-10 | 初版作成。設計ドキュメントの役割と参照タイミングを説明。 |
