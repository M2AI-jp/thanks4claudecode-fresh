# Vision（最上位レイヤー）

> **このリポジトリの存在意義と最終到達点を定義する。**
> **全ての計画（meta-roadmap, roadmap, playbook）はこのビジョンに向かっている。**

---

## 1. 根幹質問

```yaml
誰のため:
  - 新規ユーザー（開発者）
  - Claude Code を使ってプロダクトを作りたい人
  - TDD/計画駆動開発を学びたい人

何のため:
  - フォークするだけで開発環境が整う
  - 対話的にセットアップが進む
  - TDD でプロダクトを開発できる
  - LLM が自律的に計画を立て、実行し、検証できる

なぜ必要:
  - Claude Code は強力だが、計画なしだと暴走する
  - LLM は「完了」と言いたがる（自己報酬詐欺）
  - コンテキストが揮発するため、外部ファイルに真実源が必要
  - 「仕組みを作る仕組み」がないと、属人化する
```

---

## 2. 完成形ビジョン（Ultimate Goal）

```
1. 新規ユーザーがフォーク
2. Claude Code 起動 → 「ChatGPTクローン作りたい」
3. setup 自動起動 → ヒアリング → 環境セットアップ
4. playbook 自動生成 → TDD で開発開始
5. 実装中も playbook が自動更新される
6. CodeRabbit が自動レビュー
7. アプリ完成 → デプロイ
```

### 成功指標（計測可能）

| 指標 | 目標値 | 計測方法 |
|-----|-------|---------|
| セットアップ時間 | 30分以内 | 新規ユーザーテスト |
| setup 完走率 | 100% | E2E テスト |
| 人間の介入回数 | 最小限 | ログ分析 |
| playbook 品質 | 自動生成で十分 | ユーザーフィードバック |

---

## 3. オーケストレーション設計

> **各タスクに「誰が実行するか」を明確にする。**

```yaml
executors:
  claude_code:
    role: オーケストレーター（指揮者）
    capabilities:
      - ユーザーとの対話
      - タスクの分解と割り当て
      - 進捗追跡
      - フィードバック統合
      - playbook 生成・更新
      - 意思決定（複数選択肢から最適解を選ぶ）
    delegates_to:
      codex: 長時間のコード実装
      coderabbit: 自動レビュー
      user: 外部サービス設定、手動承認

  codex:
    role: 実装担当（職人）
    receives:
      - playbook（HOW）
      - AGENTS.md（コーディングルール）
    capabilities:
      - コード実装
      - テスト実行
      - ドキュメント更新
    returns:
      - 実装結果
      - テスト結果
      - 判断が必要な課題
    does_not_see:
      - roadmap（中長期計画は不要）
      - CONTEXT.md（設計思想は Claude Code が判断）

  coderabbit:
    role: レビュー担当（監査役）
    triggers:
      - git push 時
      - PR 作成時
    capabilities:
      - コード品質チェック
      - セキュリティスキャン
      - ベストプラクティス提案
    returns:
      - レビューコメント
      - 修正提案
      - 承認/却下

  user:
    role: 意思決定者（オーナー）
    responsibilities:
      - 設計判断（複数選択肢がある場合）
      - 外部サービス設定（API キー、環境変数）
      - 手動承認（デプロイ、本番反映）
      - オフラインタスク（調査、学習、契約）
    offline_tasks:
      - Vercel/Stripe/Neon 等の外部サービス登録
      - DNS 設定
      - ドメイン購入
```

### タスクアサインの例

```yaml
task_example:
  id: T1
  description: "認証機能の実装"
  breakdown:
    - step: 設計判断
      assignee: claude_code
      action: "OAuth vs JWT vs Session を比較、最適解を提案"

    - step: ユーザー確認
      assignee: user
      action: "提案された設計を承認/修正"

    - step: 実装
      assignee: codex
      input: "playbook（認証機能の Phase）"
      output: "実装コード + テスト"

    - step: レビュー
      assignee: coderabbit
      trigger: "PR 作成時"
      output: "レビューコメント"

    - step: 修正・マージ
      assignee: claude_code
      action: "レビュー結果を反映、マージ"

    - step: 外部サービス設定
      assignee: user
      action: "OAuth プロバイダの設定（Google/GitHub 等）"
```

---

## 4. フィードバックループ

> **一方通行の計画ではなく、後工程から前工程への影響を設計する。**

```yaml
feedback_loop:
  every_milestone:
    trigger: マイルストーン完了時
    questions:
      - "想定通りに動いたか？"
      - "前工程の設計に問題はなかったか？"
      - "後工程に伝えるべき知見は？"
      - "roadmap の見積もりは適切だったか？"
    actions:
      - 問題発見 → 影響範囲分析
      - 前工程への修正伝播 → meta-roadmap に報告
      - 知見の外部化 → CONTEXT.md または playbook に追記

  debug_phase:
    frequency: 3 マイルストーンごと
    activities:
      - 過去のマイルストーン振り返り
      - 問題の根本原因分析（5 Whys）
      - 前工程への修正提案
      - roadmap 自体の改善案
      - テスト戦略の見直し
    output:
      - meta-roadmap への修正提案
      - CONTEXT.md への知見追加
      - テストケースの追加/修正
```

### 影響伝播の例

```
M5 で問題発見: "setup フローが focus=setup でも main ブランチをブロックしていた"
  ↓
影響分析: M3 の check-main-branch.sh 設計が原因
  ↓
前工程修正: M3 の設計を修正（focus=setup では許可）
  ↓
後工程影響: M6, M7 のテストケース更新が必要
  ↓
meta-roadmap 更新: "ブランチルールは focus 別に設計すべき" を追記
```

---

## 5. テスト戦略

> **現在の 27/27 PASS は何を確認しているか？**

```yaml
current_tests:
  what_it_tests:
    - Hook の動作確認（BLOCK/PASS）
    - 保護ファイルの守護
    - 状態遷移の正しさ
  what_it_does_not_test:
    - 新規ユーザーのエンドツーエンド体験
    - オーケストレーションの正常動作
    - 担当者間の引き継ぎ
    - フィードバックループの機能

required_tests:
  orchestration_test:
    description: "Claude Code → Codex → CodeRabbit → User の流れが機能するか"
    scenarios:
      - "新規機能リクエスト → playbook 生成 → 実装 → レビュー → マージ"
      - "問題発見 → 影響分析 → 前工程修正 → 後工程更新"

  e2e_user_test:
    description: "新規ユーザーの体験をシミュレート"
    scenarios:
      - "フォーク → Claude Code 起動 → setup 完走 → playbook 生成"
      - "playbook → 実装 → テスト → デプロイ"

  feedback_loop_test:
    description: "フィードバックループが機能するか"
    scenarios:
      - "マイルストーン完了 → 振り返り → 問題発見 → 前工程修正"
      - "デバッグフェーズ → roadmap 改善 → 反映"
```

---

## 6. レイヤー構造（6層）

```
┌─────────────────────────────────────────────────────────────┐
│ plan/vision.md                                             │
│   WHY-ultimate: このリポジトリの存在意義、最終到達点         │
│   オーケストレーション設計、フィードバックループ              │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ plan/meta-roadmap.md                                       │
│   HOW-to-improve: roadmap を完璧にするための計画             │
│   デバッグフェーズ、改善サイクル                             │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ CONTEXT.md                                                 │
│   WHY: 設計思想、問題と解決策、失敗パターン                  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ plan/roadmap.md                                            │
│   WHAT: 中長期計画、マイルストーン、担当者アサイン           │
│   フィードバックポイント、影響分析                           │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ plan/active/playbook-*.md                                  │
│   HOW: セッションタスク、done_criteria                      │
│   Codex への委譲単位                                        │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ task（実装）                                                │
│   DO: 具体的な実装、テスト、デプロイ                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. 成功の定義

```yaml
this_repository_succeeds_when:
  - 新規ユーザーが 30 分以内に開発を開始できる
  - setup フローが無人で完走する
  - playbook が自動生成され、品質が十分である
  - 問題発見時に前工程への影響が自動分析される
  - デバッグフェーズで roadmap 自体が改善される
  - 各担当者（Claude Code/Codex/CodeRabbit/User）の役割が明確
  - フィードバックループが機能し、知見が蓄積される

this_repository_fails_when:
  - 「終わりました」で会話が終わり、振り返りがない
  - テストは通るが、ユーザー体験が悪い
  - 担当者アサインが曖昧で、誰がやるかわからない
  - 問題発見しても前工程に伝播しない
  - roadmap が一方通行のチェックリストに終わる
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-04 | 初版作成。最上位レイヤーとして vision.md を新設。 |
