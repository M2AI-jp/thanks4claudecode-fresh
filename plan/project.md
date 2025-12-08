# project.md

> **Macro 計画: リポジトリ全体の最終目標**

---

## vision

```yaml
summary: 仕組みの完成 - LLM 自律制御システムの構築
goal: CLAUDE.md + Hooks + SubAgents + Skills が連動し、LLM が自律的に制御される仕組みを完成させる

why:
  問題: Claude Code は強力だが、計画なしで動くと暴走する
  解決: 構造的強制（Hooks/Guards）+ 計画駆動（playbook）+ 自己制御（CLAUDE.md）
  完成条件: 仕組みが機能し、LLM が自律的に動作する
```

---

## what_is_this

> **このリポジトリの正体**

```yaml
種別: GitHub テンプレートリポジトリ
用途: フォークして自分のプロジェクトに使う「開発環境の雛形」

含まれるもの:
  構造的制御:
    - Hooks: session-start, session-end, playbook-guard, init-guard 等
    - Guards: scope-guard, check-coherence, check-main-branch 等
    - 設計思想: アクションベース Guards（Edit/Write 時のみ計画を要求）

  計画駆動:
    - 3層計画: Macro(project.md) → Medium(playbook) → Micro(Phase)
    - playbook テンプレート: plan/template/playbook-format.md
    - setup ガイド: setup/playbook-setup.md

  自律支援:
    - SubAgents: critic, pm, coherence, state-mgr, reviewer, health-checker 等
    - Skills: state, plan-management, learning, context-management 等
    - Commands: /playbook-init, /crit, /focus, /lint, /test 等

  ドキュメント:
    - CLAUDE.md: LLM の振る舞いルール
    - state.md: 統合状態管理
    - spec.yaml: 機能仕様

含まれないもの:
  - 実際のアプリケーションコード
  - プロダクト固有のロジック
  - ユーザーが作りたいもの自体
```

---

## target_users

> **誰のためのテンプレートか**

```yaml
主要ターゲット:
  - Claude Code を使いたいが、LLM の暴走が怖い人
  - 計画駆動で開発したいが、毎回 playbook を書くのが面倒な人
  - LLM に「自律的に動いてほしいが、勝手に暴走はしてほしくない」人

前提スキル:
  - git の基本操作（clone, branch, commit, push）
  - Claude Code のインストールと基本操作
  - Markdown の読み書き

不要なスキル:
  - bash スクリプトの深い理解（Hooks はブラックボックスでOK）
  - LLM プロンプトエンジニアリング（CLAUDE.md がやってくれる）
```

---

## done_when

> **仕組みの完成条件**

```yaml
# ========================================
# 仕組みの完成（最終目標）
# ========================================
goal: |
  CLAUDE.md + Hooks + SubAgents + Skills が連動し、
  LLM が自律的に制御される仕組みが完成している。

done_criteria:
  1_structural_enforcement:
    definition: 構造的強制（Hooks）が機能している
    checklist:
      - init-guard.sh が INIT を強制する
      - playbook-guard.sh が playbook なしの Edit/Write をブロックする
      - check-protected-edit.sh が保護ファイルを守る
      - critic-guard.sh が done 更新前に警告する
    status: done

  2_guideline_enforcement:
    definition: CLAUDE.md のルールが LLM に内面化されている
    checklist:
      - 確認を求めない（BEFORE_ASK）
      - LOOP に従って自律的に作業を進める
      - critic を呼び出してから done 判定する
      - POST_LOOP で次タスクを自動導出する
    status: done  # p1 で検証完了（critic PASS）
    note: guideline enforcement は LLM 依存。完全な構造的強制ではない。

  3_integration:
    definition: 各コンポーネントが連動している
    checklist:
      - CLAUDE.md の INIT と init-guard.sh/session-start.sh が整合
      - CLAUDE.md の CRITIQUE と critic-guard.sh が整合
      - SubAgents が適切なタイミングで呼び出される
      - Skills が参照可能
    status: done  # p2 で検証完了（critic PASS）

  4_documentation:
    definition: 仕組みが文書化されている
    checklist:
      - current-implementation.md が Single Source of Truth
      - extension-system.md が公式リファレンスを反映
      - CLAUDE.md が最新の設計を反映
    status: done  # p3 で検証完了（critic PASS）

# ========================================
# 将来の拡張（仕組み完成後）
# ========================================
future:
  - id: DW-001
    name: フォーク即使用の検証
    priority: low
  - id: DW-002
    name: README.md 整備
    priority: low
  - id: DW-003
    name: サンプルプロジェクト
    priority: low
  - id: DW-004
    name: 公開準備
    priority: low
```

---

## current_state

> **今どこにいるか**

```yaml
phase: 仕組みの完成

completed:
  - 構造的強制（Hooks）: done（p0 で検証、critic PASS）
  - guideline enforcement: done（p1 で検証、critic PASS）
  - コンポーネント連動: done（p2 で検証、critic PASS）
  - ドキュメント整合性: done（p3 で検証、critic PASS）
  - メタツーリング（SubAgents/Skills/Commands）: done
  - アクションベース Guards: done
  - playbook-guard.sh HARD_BLOCK 追加: done
  - CLAUDE.md 冒頭改訂: done

in_progress: null  # 仕組みの完成
```

---

## next_steps

> **仕組み完成後の拡張タスク（低優先度）**

```yaml
immediate: null  # 仕組み完成済み

future:
  - DW-001: フォーク即使用の検証
  - DW-002: README.md 整備
  - DW-003: サンプルプロジェクト
  - DW-004: 公開準備

optional:
  - 未活用 Hook イベント（UserPromptSubmit, Stop）の活用設計
  - Skills frontmatter 問題の修正
  - 未登録 Hook の登録
```

---

## architecture_overview

> **システム構成の概要**

```
┌─────────────────────────────────────────────────────────┐
│                    Claude Code                          │
├─────────────────────────────────────────────────────────┤
│  CLAUDE.md (ルール)  ←→  state.md (状態)               │
│         ↓                      ↓                        │
│  ┌──────────────┐    ┌──────────────────┐              │
│  │   Hooks      │    │   計画層          │              │
│  │ ・init-guard │    │ ・project.md     │              │
│  │ ・playbook-  │    │ ・playbook       │              │
│  │   guard      │    │ ・Phase          │              │
│  │ ・session-*  │    └──────────────────┘              │
│  └──────────────┘              ↓                        │
│         ↓              ┌──────────────────┐            │
│  アクションベース      │   SubAgents      │            │
│  Guards               │ ・critic         │            │
│  (Edit/Write時のみ)   │ ・pm             │            │
│                       │ ・reviewer       │            │
│                       └──────────────────┘            │
└─────────────────────────────────────────────────────────┘
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | ディスカッション用に全面改訂。ユーザー視点の done_when を追加。 |
| 2025-12-08 | 全タスク完了。13件の機能実装を終了。 |
| 2025-12-08 | 初版作成。MECE 分析の残タスク 13件を登録。 |
