# project.md

> **Macro 計画: リポジトリ全体の最終目標**

---

## vision

```yaml
summary: 仕組みのための仕組みづくり - LLM 主導の開発環境テンプレート
goal: LLM が完全自律で PDCA を回せる開発環境を提供する

why:
  問題: Claude Code は強力だが、計画なしで動くと暴走する
  解決: 構造的強制（Hooks/Guards）+ 計画駆動（playbook）で自律性と安全性を両立
  対象: Claude Code を使いたいが、LLM の暴走が怖い開発者
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

> **このテンプレートの完成条件**

```yaml
# ========================================
# 達成済み（開発者視点）
# ========================================
achieved:
  自律動作:
    definition: LLM がルールに従い、人間の介入なしで作業を進める
    evidence:
      - Hooks (init-guard, playbook-guard) が INIT を強制
      - CLAUDE.md の LOOP ルールに従って作業継続
      - アクションベース Guards で Edit/Write 時のみ計画要求
    status: done

  自己報酬詐欺防止:
    definition: done 判定前に critic が証拠ベースで検証
    evidence:
      - critic Agent 必須化（CRITIQUE ルール）
      - Hooks による構造的強制（commit 前チェック）
    status: done

  メタツーリング完備:
    definition: Hooks/SubAgents/Skills/Commands が揃っている
    evidence:
      - spec.yaml v8.0.0 で全機能を文書化
      - 13件の機能タスク完了
    status: done

# ========================================
# 未達成（ユーザー視点）
# ========================================
not_achieved:
  自動化基盤強化:
    id: DW-000
    definition: 公式リファレンスに基づく Hooks/SubAgents の最適化と未活用イベントの設計
    priority: critical
    status: in_progress

    decomposition:
      playbook_summary: Claude Code 公式リファレンスに基づき、拡張システムを最適化する

      phase_hints:
        - name: 公式リファレンス深読
          what: hooks, sub-agents, skills, slash-commands, plugins-reference を徹底読み込み
          why: 現在の実装が公式仕様のどこまで活用しているかを把握するため
        - name: 体系化ドキュメント作成
          what: 発火タイミング・トリガー・連携の完全ガイドを作成
          why: LLM が参照できる形で整理するため
        - name: 現状棚卸し・ギャップ分析
          what: 現在実装の全機能を整理し、未活用の Hook イベント等を特定
        - name: 最適化設計
          what: UserPromptSubmit, Stop, SubagentStop 等の活用設計
        - name: 実装
          what: 設計に基づき Hooks/SubAgents を拡張

      success_indicators:
        - docs/extension-system.md が公式リファレンスを反映している
        - docs/current-implementation.md が全機能を発火タイミング・トリガーで整理
        - 未活用 Hook イベント（UserPromptSubmit, Stop, SubagentStop 等）の活用設計がある
        - spec.yaml との整合性が取れている

      depends_on: []  # 他の全てに先行
      estimated_effort: "2-3 sessions"

  フォーク即使用:
    id: DW-001
    definition: 新規ユーザーがフォーク後、30分以内に最初の playbook を作成できる
    priority: high
    status: untested

    decomposition:
      playbook_summary: setup フローの検証と改善

      phase_hints:
        - name: 現状分析
          what: setup/playbook-setup.md を読み、構造と依存関係を理解
        - name: 環境準備
          what: 新規ユーザーと同じ初期状態を作る（git clone 直後を再現）
          why: 実際のユーザー体験を再現するため
        - name: 実走テスト
          what: setup を Phase 0 から実行し、問題を記録
        - name: 問題修正
          what: 発見した問題を修正
        - name: 再検証
          what: 修正後に再度実走し、完了を確認

      success_indicators:
        - setup が Phase 8 まで完了する
        - 30分以内に完了する
        - 致命的なエラーがない
        - 最初の playbook が作成できる

      depends_on: []
      estimated_effort: "2-3 sessions"

  ドキュメント整備:
    id: DW-002
    definition: README.md が新規ユーザー向けに書かれている
    priority: high
    status: not_started

    decomposition:
      playbook_summary: README.md と使い方ガイドの作成

      phase_hints:
        - name: 構成設計
          what: README.md のセクション構成を決定
          why: 「これは何か」「どう使うか」を3分で理解させるため
        - name: コンテンツ作成
          what: 各セクションを執筆（What/Why/How/QuickStart）
        - name: 図表追加
          what: アーキテクチャ図、フロー図を追加
        - name: レビュー
          what: 新規ユーザー視点で読み直し、わかりにくい箇所を修正

      success_indicators:
        - README.md が存在する
        - 「これは何か」が30秒で理解できる
        - 「どう始めるか」が3分で理解できる
        - QuickStart セクションがある

      depends_on: [DW-001]  # setup が動くことを確認してから書く
      estimated_effort: "1-2 sessions"

  サンプルプロジェクト:
    id: DW-003
    definition: このテンプレートを使った実例がある
    priority: medium
    status: not_started

    decomposition:
      playbook_summary: テンプレートを使った実例アプリの作成

      phase_hints:
        - name: アプリ選定
          what: 作成するサンプルアプリを決定（TODO/チャット等）
          why: シンプルで理解しやすいものを選ぶ
        - name: setup 実行
          what: テンプレートの setup を実行
        - name: アプリ開発
          what: playbook を使ってアプリを開発
        - name: 問題記録
          what: 開発中に発見したテンプレートの問題を記録
        - name: テンプレート改善
          what: 発見した問題をテンプレートに反映

      success_indicators:
        - サンプルアプリが動作する
        - 開発過程がドキュメント化されている
        - 発見した問題が修正されている

      depends_on: [DW-001, DW-002]  # setup と README が整ってから
      estimated_effort: "3-5 sessions"

  公開準備:
    id: DW-004
    definition: GitHub で公開できる状態
    priority: medium
    status: not_started

    decomposition:
      playbook_summary: GitHub 公開に向けた整理と準備

      phase_hints:
        - name: 履歴整理
          what: 開発履歴を .archive/ に退避
        - name: LICENSE 追加
          what: 適切なライセンスを選定し追加
        - name: 不要ファイル削除
          what: テスト用ファイル、一時ファイルを削除
        - name: 最終確認
          what: 公開前の最終チェックリストを実行

      success_indicators:
        - LICENSE ファイルがある
        - .archive/ に開発履歴が退避されている
        - 不要ファイルがない
        - README.md がトップレベルにある

      depends_on: [DW-001, DW-002]  # ドキュメントが整ってから
      estimated_effort: "1 session"
```

---

## current_state

> **今どこにいるか**

```yaml
phase: メタツーリング完了 → ユーザー視点検証前

completed_milestones:
  - 基盤構築: Hooks/Guards システム
  - 計画駆動: 3層計画 + playbook テンプレート
  - 自律支援: SubAgents/Skills/Commands
  - 設計改善: session 分類 → アクションベース Guards
  - 13件の機能タスク完了

current_gap:
  問題: 開発者（私たち）視点では完成しているが、ユーザー視点でのテストがない
  リスク:
    - setup が実際に動くかわからない
    - README がないので何のリポジトリかわからない
    - 「フォークして使う」体験が未検証
```

---

## next_steps

> **ディスカッションポイント: 何を優先すべきか**

```yaml
option_A:
  name: ユーザー視点検証（推奨）
  tasks:
    - 新規ユーザーとして setup を実走
    - README.md を書く
    - 問題を発見したら修正
  merit: 実際に使えるテンプレートになる
  risk: 地味な作業が多い

option_B:
  name: サンプルプロジェクト作成
  tasks:
    - このテンプレートを使って何かアプリを作る
    - 作る過程でテンプレートの問題を発見
  merit: 「これを使うとこうなる」という実例ができる
  risk: アプリ開発に時間がかかる

option_C:
  name: 公開準備
  tasks:
    - .archive/ に履歴退避
    - LICENSE 追加
    - README.md 最低限
  merit: 早く公開できる
  risk: 品質が不明なまま公開

option_D:
  name: その他
  description: ユーザーの要望次第
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
