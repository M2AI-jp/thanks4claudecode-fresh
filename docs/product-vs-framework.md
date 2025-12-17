# Product vs Framework 分離方針

> このリポジトリで「何を開発するのか」の整理

---

## 問題

このリポジトリには2つの異なる目的が混在していた：

1. **フレームワーク開発**: Hooks/SubAgents/Skills などの AI エージェント基盤
2. **プロダクト開発**: 実際のアプリケーション/SaaS の開発

これらが同じ `project.md` の milestones に混在することで、
「世界のすべて」を表そうとして破綻していた。

---

## 分離方針

### レイヤー定義

```yaml
framework:
  description: "AI エージェント基盤（Hooks/SubAgents/Skills/Commands）"
  scope:
    - .claude/ 配下のすべて
    - CLAUDE.md
    - state.md の構造定義
    - docs/ の設計ドキュメント
  focus_value: "framework"
  branch_prefix: "framework/"
  
workspace:
  description: "実際のプロダクト/アプリケーション開発"
  scope:
    - src/ や app/ などのアプリケーションコード
    - プロダクト固有の設定
    - ユーザー向け機能
  focus_value: "product"
  branch_prefix: "feature/"

setup:
  description: "新規ユーザーの初期セットアップ"
  scope:
    - 環境構築
    - 依存関係インストール
  focus_value: "setup"
  special: "main ブランチで許可される唯一の作業モード"
```

---

## state.md の focus.current 候補値

```yaml
# フレームワーク開発用
framework:
  - thanks4claudecode-recovery  # 現在の回復プロジェクト
  - framework-maintenance       # フレームワークの定期メンテナンス

# プロダクト開発用（例）
product:
  - my-saas-app                 # 実際のプロダクト開発
  - my-cli-tool                 # CLI ツール開発

# 特殊
special:
  - setup                       # 新規セットアップ（main で許可）
  - plan-template               # テンプレート編集（main で許可）
```

---

## ブランチ戦略

```yaml
main:
  allowed_focus:
    - setup
    - plan-template
  purpose: "安定版、新規ユーザーのクローン元"

framework/*:
  allowed_focus:
    - framework-*
    - thanks4claudecode-recovery
  purpose: "フレームワーク自体の開発"
  example: "framework/m101-recovery"

feature/*:
  allowed_focus:
    - product-*
  purpose: "プロダクト機能の開発"
  example: "feature/user-auth"
```

---

## このリポジトリの現状

```yaml
current_status:
  type: "framework"
  purpose: "AI エージェント基盤の実験・回復"
  product_code: "なし（フレームワークのみ）"
  
recommendation:
  short_term: |
    回復プロジェクト完了まで framework として運用。
    focus.current は thanks4claudecode-recovery を維持。
  
  long_term: |
    M120 で最終方針を決定：
    - テンプレート化: 別リポジトリで product 開発を想定
    - 博物館化: このリポジトリは read-only にして実験記録として保存
    - 凍結: 概念だけ抽出して、このリポジトリはアーカイブ
```

---

## plan/template/state-initial.md への反映

state-initial.md は以下の構造に更新されるべき：

```yaml
focus:
  current: setup  # 初期値は setup
  project: plan/project.md

# focus.current の候補値:
# - setup: 新規セットアップ
# - plan-template: テンプレート編集
# - framework-*: フレームワーク開発
# - product-*: プロダクト開発
```

---

## 実装状態

| 項目 | 状態 |
|------|------|
| 方針定義（このドキュメント） | ✓ 完了 |
| state.md の focus 構造 | 部分的に実装（current フィールドあり） |
| plan/template/state-initial.md | 更新が必要 |
| check-main-branch.sh | 更新が必要（新しい focus 値に対応） |
