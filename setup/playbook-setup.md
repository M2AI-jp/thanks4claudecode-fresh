# playbook-setup.md

> **新規ユーザー向けセットアップ playbook（メインガイド）**
> **このファイルだけで setup が完結。詳細は CATALOG.md を参照。**

---

## Quickstart（5分で開始）

> **最速で始めたい方向け。詳細は後述の Phase を参照。**

```bash
# 1. このリポジトリをクローン
git clone https://github.com/your-username/thanks4claudecode.git my-project
cd my-project

# 2. Claude Code で開く
claude .

# 3. Claude に「setup を始めて」と伝える
# → Phase 0 から自動でガイドが始まります
```

**必要なもの:**
- Mac（Intel / Apple Silicon）
- Claude Pro 契約（$20/月）
- GitHub アカウント

**所要時間:**
- Tutorial Route: 10分
- Production Route: 30-60分

---

## このリポジトリの活用方法

> **このリポジトリ自体が「完成した実例」として参照可能です。**

```yaml
実例として参照できるもの:
  .claude/:
    hooks/: 22個の Hook 実装例（構造的強制）
    agents/: 10個の SubAgent 定義（検証・自動化）
    skills/: 9個の Skill 定義（自動発火）
    commands/: 7個のコマンド定義
    frameworks/: 評価フレームワーク

  CLAUDE.md: LLM 振る舞い制御の実例（三位一体の思考制御層）
  state.md: 統合状態管理の実例
  plan/: 計画管理の実例
  docs/: ドキュメント体系の実例

学習の流れ:
  1. まず setup を完了（Phase 0-8）
  2. plan/project.md を生成
  3. 実際にプロダクトを開発しながら仕組みを体験
  4. 必要に応じて .claude/ の中身を参照・カスタマイズ

参照ドキュメント:
  - docs/current-implementation.md: 現在実装の詳細仕様
  - docs/extension-system.md: Claude Code 公式リファレンス
  - docs/file-inventory.md: 全ファイルの存在理由
```

---

## meta

```yaml
project: dev-workspace-setup
branch: null  # setup は特定ブランチに紐づかない（main で実行可）
created: auto-generated
```

---

## goal

```yaml
summary: Mac 開発環境をセットアップし、product 開発を開始できる状態にする
done_when:
  - 開発ツール（Homebrew, Node.js, pnpm, Git）がインストール済み
  - GitHub CLI で認証済み
  - プロジェクトがローカルで動作する
  - Vercel にデプロイ済み
  - .claude/skills/ に Skills が存在する（事前配置済み）
  - plan/project.md が生成されている
  - focus.current が product に切り替わっている
```

---

## 最低要件

```yaml
必須サブスクリプション:
  - Claude Pro: $20/月
    用途: Claude Code の利用
    URL: https://claude.ai/

  - ChatGPT Plus: $20/月
    用途: Codex（大規模コード生成）
    URL: https://chat.openai.com/

推奨オプション:
  - CodeRabbit: Free / Lite ($12/月) / Pro ($24/月)
    用途: PR レビュー自動化
    URL: https://coderabbit.ai/

合計最低費用: $40/月（Claude Pro + ChatGPT Plus）
```

---

## レビューツール選択

```yaml
# Phase 4 でツールインストール後、ユーザーに選択させる

選択肢:
  coderabbit:
    説明: AI コードレビュー専用ツール
    プラン:
      - Free: 無料（1時間1レビュー制限）
      - Lite: $12/月（制限緩和）
      - Pro: $24/月（無制限）
    利点:
      - PR 作成時に自動レビュー（GitHub App）
      - 詳細なコード品質分析
      - セキュリティ脆弱性検出
    欠点:
      - 外部サービス依存
      - Free tier はレートリミットあり

  codex:
    説明: OpenAI のコード生成・分析ツール
    利用条件: ChatGPT Plus 契約必須
    利点:
      - プロンプトベースで柔軟なレビュー
      - 大規模コード生成も可能
      - MCP 経由で Claude Code から呼び出せる
    欠点:
      - 専用レビュー機能ではない
      - プロンプト作成が必要

  both:
    説明: 両方を使い分け
    推奨ケース:
      - CodeRabbit: PR 作成時の自動レビュー
      - Codex: 大規模コード生成、詳細分析

LLM の発言テンプレート（Phase 4 完了後）:
  ```
  開発ツールのインストールが完了しました。

  【レビューツールの選択】
  コードレビューをどのツールで行いますか？

  A: CodeRabbit（推奨）
     → PR 作成時に自動レビュー
     → Free: 無料（1時間1回制限）/ Lite: $12/月

  B: Codex
     → ChatGPT Plus 契約が必要
     → プロンプトベースで柔軟にレビュー

  C: 両方
     → CodeRabbit で自動レビュー + Codex で詳細分析

  D: なし（後で設定）

  どれにしますか？（A/B/C/D）
  ```

設定方法（A を選んだ場合）:
  1. https://coderabbit.ai/ でアカウント作成
  2. GitHub 連携を設定
  3. 対象リポジトリで GitHub App をインストール
  4. PR 作成時に自動でレビューが走る

設定方法（B を選んだ場合）:
  1. ChatGPT Plus に加入していることを確認
  2. Claude Code から mcp__codex__codex で呼び出し可能
  3. 「このコードをレビューして」とプロンプトで依頼
```

---

## 設計思想

> **三位一体アーキテクチャ**: Hooks（構造的強制）+ SubAgents（検証）+ CLAUDE.md（思考制御）
> 単独では機能しない。組み合わせて初めて強制力を持つ。

### 基本原則

```yaml
ターゲット: 初心者〜経験者（スキルレベルで分岐）
プラットフォーム: Mac
デフォルト技術スタック: TypeScript, Next.js, pnpm, Vercel

原則:
  - 初心者: デフォルト推奨、技術選択は聞かない
  - 経験者: 技術選択・非機能要件を確認
  - どちらの場合も決定を plan/project.md に永続化
  - LLM は plan/project.md の決定に従い続ける

LLM の性質を活用:
  - 最初に決めたことに引っ張られる → setup で全て決める
  - plan/project.md をセッション開始時に読む → 決定が維持される
  - 曖昧さを排除 → 後のセッションで迷わない
```

### 三位一体アーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│                    CLAUDE.md（思考制御）                     │
│    INIT / LOOP / POST_LOOP / CRITIQUE / CONSENT             │
│    → LLM の行動パターンを規定（自己拘束ルール）              │
└────────────────────────────┬────────────────────────────────┘
                             │ 参照・従う
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    Hooks（構造的強制）                        │
│    PreToolUse / PostToolUse / SessionStart / SessionEnd     │
│    → ツール実行時に bash スクリプトで強制ブロック            │
│    → LLM の意思とは無関係に発火                              │
└────────────────────────────┬────────────────────────────────┘
                             │ 呼び出す
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    SubAgents（検証）                         │
│    critic / pm / reviewer / health-checker                  │
│    → 外部視点からの検証（報酬詐欺防止）                      │
│    → done_criteria の達成を第三者判定                        │
└─────────────────────────────────────────────────────────────┘
```

### アクションベース Guards

```yaml
設計思想:
  - プロンプトの「意図」ではなく「アクション」を制御
  - Edit/Write 時のみ playbook チェック
  - Read/Grep/WebSearch 等は playbook なしでも常に許可

利点:
  - 「意図」の推測が不要
  - 調査・報告は自由に対応可能
  - 実際にコードを変更するときだけ計画を要求

実装:
  - playbook-guard.sh: Edit/Write 前に playbook 存在チェック
  - consent-guard.sh: 合意プロセス未完了時にブロック
```

### 報酬詐欺防止

```yaml
問題:
  - LLM は「完了しました」と自己申告する傾向がある
  - done_criteria を満たしていないのに done と報告

解決:
  - critic SubAgent による第三者検証
  - critic PASS なしで done 不可（critic-guard.sh でブロック）
  - 5層防御: CLAUDE.md → Hooks → critic → evidence → test

禁止パターン:
  - 「〇〇した」だけで証拠なし
  - 「〇〇のはず」「思う」という曖昧表現
  - シミュレーションのみで実際の動作確認なし
```

### 計画の連鎖（Plan Derivation）

```yaml
構造:
  Macro（project.md）→ Medium（playbook）→ Micro（Phase）

フロー:
  1. project.md の done_when を分析
  2. depends_on を解決し、着手可能なタスクを特定
  3. decomposition を参照して playbook を自動生成
  4. Phase ごとに done_criteria を検証
  5. playbook 完了 → project.md の done_when を achieved に
  6. 次の playbook を自動導出

必須経由点:
  - 全タスク開始は pm SubAgent 経由
  - derives_from なしの playbook は禁止
```

### コンテキスト外部化

```yaml
問題:
  - チャット履歴が長くなるとルールが効かなくなる
  - LLM が「何をやっているか」が不明確になる

解決:
  - state.md / project.md / playbook を唯一の真実源に
  - チャット履歴に依存しない
  - .claude/logs/context-log.md で処理経過を記録
  - 80% コンテキスト超過時は /clear を推奨
```

---

## phases

### Phase 0: ルート選択

```yaml
id: p0
name: ルート選択
goal: ユーザーの目的とスキルレベルを確認
executor: user
done_criteria:
  - ユーザーが目的（Tutorial / Production）を選択した
  - Production の場合、スキルレベル（初心者 / 経験者）を確認した
status: pending
```

**LLM の発言テンプレート:**

```
こんにちは！Mac の開発環境セットアップをお手伝いします。

最初に1つだけ教えてください：

【今日の目的は？】

A: まずプログラミングを体験してみたい（チュートリアル）
   → 費用ゼロ、10分で AI チャットが動きます

B: 実際に使うアプリやサービスを作りたい（本番開発）
   → 作りたいものに合わせた本格的な環境を構築します

どちらですか？（A または B）
```

**ルート判定:**
- A → Tutorial Route（後述）
- B → スキルレベル確認へ

**スキルレベル確認（B を選んだ場合）:**

```
ありがとうございます！

【プログラミング経験は？】

1: 初めて / ほぼ初心者
   → おすすめの構成で進めます（迷わない）

2: 経験あり / 自分で選びたい
   → 技術スタックや要件を一緒に決めます

どちらですか？（1 または 2）
```

**分岐:**
- 1（初心者）→ Phase 1 へ（デフォルト技術で進行）
- 2（経験者）→ Phase 1-A へ（技術選択ヒアリング）

---

### Phase 1: ヒアリング（Production のみ）

```yaml
id: p1
name: ヒアリング
goal: 何を作りたいかを確認し、カテゴリを分類
executor: user
depends_on: [p0]
skip_if: p0 で Tutorial を選択した場合
done_criteria:
  - ユーザーが作りたいものを回答した
  - カテゴリが決定した
status: pending
```

**LLM の発言テンプレート:**

```
では、本番開発を始めましょう！

【何を作りたいですか？】

例えば...
- 「ポートフォリオサイト」
- 「友達と使う割り勘アプリ」
- 「SaaS で課金できるサービス」
- 「ChatGPT みたいな AI チャット」
- 「iPhone アプリ」
- 「自動化スクリプト」

思いついたままに教えてください。
```

**カテゴリ分類（LLM が自動判定）:**

```yaml
static_site:
  キーワード: [ポートフォリオ, LP, ブログ, ホームページ, 作品集]
  構成: Next.js + Vercel（静的）
  必要アカウント: [GitHub, Vercel]

simple_tool:
  キーワード: [計算, 割り勘, 変換, 電卓, シンプル]
  構成: Next.js + Vercel（DB不要）
  必要アカウント: [GitHub, Vercel]

web_app:
  キーワード: [アプリ, サービス, ログイン, 保存, 履歴]
  構成: Next.js + Vercel + Neon
  必要アカウント: [GitHub, Vercel, Neon]

saas:
  キーワード: [SaaS, 課金, サブスク, 有料, ビジネス]
  構成: next-saas-stripe-starter
  必要アカウント: [GitHub, Vercel, Neon, Stripe, Resend]
  参照: CATALOG.md セクション 5

ai_chat:
  キーワード: [ChatGPT, AI, チャット, 会話, ボット, キャラクター]
  判定: 3段階から選択（追加質問OK）
  → ai_chat_tutorial / ai_chat_simple / ai_chat_production

automation:
  キーワード: [自動化, スクリプト, CLI, Bot, 定期実行]
  構成: Node.js or Python（フロントエンドなし）
  必要アカウント: [GitHub]

backend_only:
  キーワード: [API, サーバー, バックエンド, マイクロサービス, webhook]
  構成: Express / FastAPI / Hono（フロントエンドなし）
  必要アカウント: [GitHub, Railway or 自前サーバー]
```

**AI チャット分岐（ai_chat の場合のみ追加質問）:**

```
AI チャットを作りたいんですね！
どのレベルで作りたいですか？

A: まず動くものを見たい（10分、費用ゼロ）
B: 公開して使ってもらいたい（1時間、AI費用のみ）
C: 本格的なサービスを作りたい（3時間+、複数サービス費用）

迷ったら A から始めるのがおすすめです！
```

---

### Phase 1-A: 技術選択（経験者のみ）

```yaml
id: p1a
name: 技術選択
goal: 4層構成・認証・決済・費用を確定
executor: user
depends_on: [p0]
skip_if: スキルレベル=初心者 または Tutorial Route
done_criteria:
  - 4層（Frontend / Backend / Database / Hosting）が決定した
  - 認証・決済の要否が確認された
  - 月額費用の概算を提示した
  - 非機能要件が確認された
status: pending
```

**LLM の発言テンプレート（4層選択）:**

```
経験者向けの構成を決めていきます。
デフォルトのままでよい項目は「デフォルト」または「スキップ」と言ってください。

【1. フロントエンド】
デフォルト: Next.js + Tailwind CSS

選択肢:
- Next.js（推奨: SSR/SSG、API Routes 統合、Vercel 最適化）
- React（SPA 特化、柔軟性高い）
- Vue（学習コストが低い）
- なし（バックエンドのみ）

希望があれば教えてください。
```

```
【2. バックエンド】
デフォルト: Next.js API Routes（フロントと統合）

選択肢:
- Next.js API Routes（フロントと統合、サーバーレス）
- Express（Node.js、柔軟、歴史あり）
- FastAPI（Python、高速、型ヒント）
- Hono（軽量、Edge 対応）
- なし（静的サイトのみ）

希望があれば教えてください。
```

```
【3. データベース】
デフォルト: Neon（PostgreSQL、無料枠大きい）

選択肢:
- なし（データ保存不要）
- Neon（PostgreSQL、無料 0.5GB、$19/月〜）
- Supabase（BaaS、認証統合、無料 500MB）
- PlanetScale（MySQL、スケーラブル、無料 5GB）
- 自前（Docker PostgreSQL など）

希望があれば教えてください。
```

```
【4. ホスティング】
デフォルト: Vercel（Next.js 最適化）

選択肢:
- Vercel（Next.js 最適化、無料枠あり、$20/月〜）
- Cloudflare Pages（Edge、無料枠大きい）
- Railway（コンテナ対応、$5/月〜）
- 自前サーバー（VPS、EC2）

希望があれば教えてください。
```

**LLM の発言テンプレート（認証・決済）:**

```
【5. 認証（ログイン機能）】
デフォルト: なし

選択肢:
- なし（不要）
- NextAuth.js（無料、自前ホスティング）
- Clerk（マネージド、無料 10K MAU）
- Auth0（エンタープライズ、無料 7K MAU）
- Supabase Auth（Supabase 利用時）

ログイン機能は必要ですか？
```

```
【6. 決済（課金機能）】
デフォルト: なし

選択肢:
- なし（不要）
- Stripe（3.6% + $0.30/取引、業界標準）
- LemonSqueezy（5% + $0.50/取引、デジタル商品向け）

課金機能は必要ですか？
```

**LLM の発言テンプレート（費用概算）:**

```
【7. 月額費用の概算】
選択した構成の概算費用です：

■ ホスティング: {hosting_cost}
■ データベース: {database_cost}
■ 認証: {auth_cost}
■ AI API: {ai_cost}（使用量による）
■ その他: {other_cost}

【月額合計】{total_cost}

※ 無料枠を超えると課金が発生します
※ AI API は使用量に応じて変動します

この構成でよろしいですか？
```

**費用概算一覧:**

```yaml
hosting:
  Vercel Hobby: $0/月
  Vercel Pro: $20/月
  Cloudflare Pages: $0/月
  Railway: $5+/月

database:
  Neon Free: $0/月 (0.5GB)
  Neon Launch: $19/月
  Supabase Free: $0/月 (500MB)
  PlanetScale Hobby: $0/月 (5GB)

auth:
  NextAuth.js: $0（自前ホスティング）
  Clerk Free: $0/月 (10K MAU)
  Auth0 Free: $0/月 (7K MAU)

ai_api:
  OpenRouter Free: $0（制限あり）
  OpenAI gpt-3.5: ~$0.002/1K tokens
  Google AI: $0/月（無料枠）

payment:
  Stripe: 3.6% + $0.30/取引
  LemonSqueezy: 5% + $0.50/取引
```

### 無料→有料の警告【ストップ機構】

```yaml
警告が必要なケース:
  - 月額費用が $0 を超える構成を選択した
  - 無料枠の上限が小さいサービスを選択した（例: Vercel Hobby 100GB/月）
  - 従量課金が発生するサービス（AI API、Stripe 手数料）

LLM の行動:
  1. 費用が $0 を超える場合、必ず以下の警告を出す:
     ```
     ⚠️【費用確認】
     この構成では月額費用が発生する可能性があります。

     ■ 月額概算: ${total_cost}
     ■ 有料要素:
       - {有料サービス名}: ${cost}/月
       - ...

     【選択肢】
     A: この構成で進める（費用を了承）
     B: 無料構成に変更する（機能制限あり）

     どちらにしますか？
     ```

  2. ユーザーが B を選んだ場合:
     - 無料代替案を提示
     - 例: Vercel Pro → Cloudflare Pages
     - 例: Clerk → NextAuth.js

  3. 【重要】確認なしで有料構成を進めない

無料構成の強制オプション:
  - ユーザーが「無料だけで」「費用ゼロで」と言った場合
  - 全て無料サービスで構成する
  - 無料では実現できない機能は「できません」と伝える

⚠️ 無料→有料の壁は大きい:
  - 初心者ほど「いつの間にか課金」を避けたい
  - 有料選択には必ず明示的な同意を取る
```

**LLM の発言テンプレート（非機能要件）:**

```
【8. 非機能要件】
プロジェクトの規模感を教えてください。

■ 規模
- 想定ユーザー数: 自分だけ / 10人程度 / 100人以上 / 1000人以上
- データ量: 少ない / 中程度 / 多い

■ セキュリティ
- 個人情報を扱う: はい / いいえ

■ 予算・期間
- 月額予算: 無料 / $10以下 / $50以下 / 制限なし
- 目標リリース日: いつ頃？（任意）

わからない項目は「わからない」で OK です。
```

**技術選択のデフォルト値:**

```yaml
defaults:
  # 4層
  frontend: Next.js + Tailwind CSS
  backend: Next.js API Routes
  database: Neon
  hosting: Vercel

  # 認証・決済
  auth: なし
  payment: なし

  # ライブラリ
  language: TypeScript
  ui: Tailwind CSS
  state: React Context
  data_fetching: SWR
  form: React Hook Form
  validation: Zod
  ai: Vercel AI SDK

non_functional_defaults:
  users: 10
  data_volume: small
  requires_auth: false
  handles_pii: false
  handles_payment: false
  monthly_budget: free
  estimated_cost: $0/月
```

**初心者向け「おまかせ構成」:**

```yaml
# Phase 0 で「初心者」を選んだ場合、以下を自動適用
omakase_stack:
  frontend: Next.js + Tailwind CSS
  backend: Next.js API Routes
  database: Neon（データ保存が必要な場合）
  hosting: Vercel
  auth: なし（必要な場合 NextAuth.js）
  payment: なし（必要な場合 Stripe）
  estimated_cost: $0/月（無料枠内）

  # LLM の発言
  message: |
    おまかせ構成で進めます！

    【構成】
    - フロントエンド: Next.js + Tailwind CSS
    - バックエンド: Next.js API Routes（統合）
    - データベース: Neon（無料枠）
    - ホスティング: Vercel（無料枠）

    【費用】$0/月（無料枠内で収まります）

    この構成は後から変更も可能です。
    では、アカウント作成に進みましょう！
```

**LLM の行動:**
1. 経験者: 4層 → 認証・決済 → 費用概算 → 非機能要件 の順で質問
2. 初心者: 「おまかせ構成」を適用、質問しない
3. 「デフォルト」「スキップ」→ デフォルト値を使用
4. 全ての決定を内部で記録（Phase 8 で project.md に書き出し）
5. 費用概算は必ず提示する（初心者にも）

---

### Phase 2: 構成提案

```yaml
id: p2
name: 構成提案
goal: 技術スタックを決定し、ユーザーに提案
executor: llm
depends_on: [p1]
done_criteria:
  - 技術スタック（Next.js, Vercel, DB 等）が決定した
  - ユーザーに構成を説明した
status: pending
```

**LLM の発言テンプレート:**

```
わかりました！「{ユーザーの回答}」ですね。

【構成】
- フレームワーク: Next.js + TypeScript
- デプロイ: Vercel
- {追加要素: DB, AI API など}

この構成で進めます。
まず、いくつかアカウントを作成していただく必要があります。
```

---

### Phase 3: アカウント作成（オフライン）

```yaml
id: p3
name: アカウント作成
goal: 必要な外部サービスのアカウントを作成
executor: user
depends_on: [p2]
done_criteria:
  - GitHub アカウント作成済み
  - Vercel アカウント作成済み（GitHub 連携）
  - その他必要なサービス作成済み
status: pending
```

**必要アカウント早見表:**

| カテゴリ | 必要なアカウント |
|---------|-----------------|
| static_site | GitHub, Vercel |
| simple_tool | GitHub, Vercel |
| web_app | GitHub, Vercel, Neon |
| saas | GitHub, Vercel, Neon, Stripe, Resend |
| ai_chat_tutorial | Google AI Studio |
| ai_chat_simple | GitHub, Vercel, OpenAI |
| ai_chat_production | GitHub, Vercel, Neon, Upstash, OpenAI |

**アカウント作成ガイド:**

```yaml
GitHub:
  URL: https://github.com/signup
  説明: プログラムの保存場所（クラウドのフォルダ）

Vercel:
  URL: https://vercel.com/signup
  説明: 無料でアプリを公開できる場所
  方法: 「Continue with GitHub」で登録

OpenAI:
  URL: https://platform.openai.com
  重要: 支払い設定必須（使った分だけ課金）
  参照: CATALOG.md セクション 2

Google AI Studio:
  URL: https://aistudio.google.com
  説明: 無料の AI API（チュートリアル用）
```

**LLM の発言:**
```
できたら教えてください！
（全部一度にやらなくても大丈夫です）
```

---

### Phase 4: 環境構築

```yaml
id: p4
name: 環境構築
goal: ローカル開発環境に必要なツールをインストール
executor: llm
depends_on: [p3]
done_criteria:
  - Homebrew がインストール済み（brew --version で確認）
  - Node.js がインストール済み（node --version で確認）
  - pnpm がインストール済み（pnpm --version で確認）
  - Git がインストール済み（git --version で確認）
  - GitHub CLI が認証済み（gh auth status で確認）
  - dotenvx がインストール済み（dotenvx --version で確認）
  - ShellCheck がインストール済み（shellcheck --version で確認）
  - pre-commit がインストール済み（pre-commit --version で確認）
status: pending
```

**LLM の行動:**

1. まず確認:
   ```bash
   brew --version && git --version && node --version && pnpm --version && dotenvx --version
   shellcheck --version && pre-commit --version
   ```

2. 不足があればインストール:
   ```bash
   # Homebrew
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

   # Node.js
   brew install node

   # pnpm
   npm install -g pnpm

   # GitHub CLI
   brew install gh && gh auth login

   # dotenvx（暗号化された環境変数管理）
   brew install dotenvx/brew/dotenvx

   # Linter/Formatter ツール（言語共通）
   brew install shellcheck shfmt  # Shell
   pip install pre-commit ruff    # pre-commit フック、Python Linter
   ```

3. dotenvx の説明（初心者向け）:
   ```
   dotenvx は API キーを安全に管理するツールです。
   - .env ファイルを暗号化してコミット可能に
   - チームでシークレットを安全に共有
   - 詳細: https://dotenvx.com/
   ```

4. Linter/Formatter の説明（初心者向け）:
   ```
   Linter はコードの問題を自動検出するツールです。
   Formatter はコードスタイルを統一するツールです。
   - ShellCheck: シェルスクリプトの問題検出
   - pre-commit: コミット前に自動チェック
   - 詳細: .claude/templates/linter-formatter-config.md
   ```

5. 参照: CATALOG.md セクション 1（トラブルシューティング）

---

### Phase 5: プロジェクト作成

```yaml
id: p5
name: プロジェクト作成
goal: カテゴリに応じたプロジェクトを作成
executor: llm
depends_on: [p4]
done_criteria:
  - projects/{name} ディレクトリが存在する
  - package.json が存在する
  - pnpm dev でローカルサーバーが起動する
status: pending
```

**カテゴリ別コマンド:**

```bash
# static_site / simple_tool / web_app / ai_chat（フロントエンドあり）
mkdir -p projects && cd projects
npx create-next-app@latest {name} --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --use-pnpm

# AI SDK 追加（ai_chat の場合）
cd {name} && pnpm add ai @ai-sdk/openai

# SaaS テンプレート
git clone https://github.com/mickasmt/next-saas-stripe-starter.git projects/{name}

# automation / backend_only（フロントエンドなし）
mkdir -p projects/{name} && cd projects/{name}
pnpm init
pnpm add typescript @types/node tsx -D

# Express バックエンド
pnpm add express && pnpm add @types/express -D

# FastAPI (Python) の場合
python -m venv .venv && source .venv/bin/activate
pip install fastapi uvicorn

# Hono（軽量 Edge）
pnpm add hono
```

**フロントエンドなしの判定:**
```yaml
フロントエンドなしを選ぶべきケース:
  - CLI ツール / スクリプト
  - API サーバーのみ（他のサービスから呼ばれる）
  - 定期実行バッチ / cron ジョブ
  - Discord Bot / Slack Bot
  - webhook 受信サーバー

⚠️ 初心者がこれを選んだ場合:
  - 「画面がないプロジェクトになりますが大丈夫ですか？」と確認
  - 迷っている場合は Next.js（フロントあり）を推奨
```

---

### Phase 5-A: Linter/Formatter 設定

```yaml
id: p5a
name: Linter/Formatter 設定
goal: プロジェクトに言語別 Linter/Formatter を設定
executor: llm
depends_on: [p5]
done_criteria:
  - 言語に応じた Linter 設定ファイルが存在する
  - 言語に応じた Formatter 設定ファイルが存在する
  - .pre-commit-config.yaml が設定されている
  - pre-commit install が実行済み
  - pnpm lint（または同等コマンド）が成功する
status: pending
```

**LLM の行動:**

1. プロジェクトの言語を判定:
   ```yaml
   判定基準:
     - package.json 存在 → JavaScript/TypeScript
     - pyproject.toml 存在 → Python
     - go.mod 存在 → Go
     - Cargo.toml 存在 → Rust
     - .sh ファイル存在 → Shell
   ```

2. 言語別設定ファイルを作成:
   ```bash
   # テンプレート参照
   cat .claude/templates/linter-formatter-config.md
   ```

3. JavaScript/TypeScript の場合:
   ```bash
   cd projects/{name}

   # Prettier 追加（ESLint は create-next-app で含まれる）
   pnpm add -D prettier eslint-config-prettier

   # .prettierrc 作成
   cat > .prettierrc << 'EOF'
   {
     "semi": true,
     "singleQuote": true,
     "tabWidth": 2,
     "trailingComma": "es5",
     "printWidth": 100
   }
   EOF

   # package.json に lint スクリプト追加
   # "lint": "eslint . --fix",
   # "format": "prettier --write ."
   ```

4. pre-commit 設定:
   ```bash
   cd projects/{name}

   # .pre-commit-config.yaml 作成
   cat > .pre-commit-config.yaml << 'EOF'
   repos:
     - repo: local
       hooks:
         - id: eslint
           name: ESLint
           entry: pnpm eslint --fix
           language: system
           files: \.(js|jsx|ts|tsx)$
           pass_filenames: false

         - id: prettier
           name: Prettier
           entry: pnpm prettier --write
           language: system
           files: \.(js|jsx|ts|tsx|json|md|css)$
   EOF

   # pre-commit インストール
   pre-commit install
   ```

5. 動作確認:
   ```bash
   pnpm lint
   pre-commit run --all-files
   ```

**初心者向け説明:**
```
Linter と Formatter を設定しました。

【Linter（ESLint）】
- コードの問題（バグの可能性、未使用変数）を検出
- pnpm lint で実行

【Formatter（Prettier）】
- コードスタイルを自動整形
- 保存時に自動実行（VSCode 設定済みなら）

【pre-commit】
- コミット前に自動チェック
- 問題があるとコミットが止まる（安全装置）

これで「きれいなコード」を書く習慣が身につきます。
```

---

### Phase 6: API キー設定とデプロイ

```yaml
id: p6
name: API キー設定とデプロイ
goal: dotenvx で環境変数を設定し、Vercel にデプロイ
executor: user + llm
depends_on: [p5]
done_criteria:
  - dotenvx で .env が暗号化されている
  - .env.keys が .gitignore に含まれている
  - GitHub リポジトリにプッシュ済み
  - Vercel でインポート完了
  - 環境変数が設定済み
  - デプロイ URL にアクセスして動作確認済み
status: pending
```

#### dotenvx による環境変数設定（推奨）

**重要: API キーはチャットに入力しないでください**

```
【dotenvx での設定方法】

1. プロジェクトフォルダに移動:
   cd projects/{name}

2. dotenvx で API キーを設定（暗号化）:
   dotenvx set OPENAI_API_KEY "sk-ここにAPIキーを貼り付け"

3. 結果:
   - .env に暗号化されたキーが保存される（コミット可能）
   - .env.keys に秘密鍵が保存される（コミット禁止）

4. ローカル実行:
   dotenvx run -- pnpm dev
```

**dotenvx の利点:**
- 暗号化された .env をコミットできる（チーム共有が安全）
- 秘密鍵（.env.keys）だけを別管理
- Vercel には DOTENV_PRIVATE_KEY を設定するだけ

**LLM の行動:**

1. `.gitignore` に .env.keys を追加:
   ```bash
   echo ".env.keys" >> projects/{name}/.gitignore
   ```

2. `.env.example` を作成:
   ```bash
   cat > projects/{name}/.env.example << 'EOF'
   # dotenvx で設定してください: https://dotenvx.com/
   # dotenvx set OPENAI_API_KEY "sk-your-key"
   OPENAI_API_KEY=
   EOF
   ```

3. ユーザーに dotenvx での設定を案内:
   ```
   API キーを設定しましょう。

   1. ターミナルで以下を実行:
      cd projects/{name}
      dotenvx set OPENAI_API_KEY "sk-あなたのAPIキー"

   2. 暗号化された .env が作成されます
   3. .env.keys は絶対にコミットしないでください
   ```

4. GitHub にプッシュ:
   ```bash
   cd projects/{name}
   git init && git add . && git commit -m "Initial commit"
   gh repo create {name} --public --source=. --push
   ```

5. ユーザーに Vercel でのインポートを案内:
   ```
   1. https://vercel.com/new を開く
   2. 「Import Git Repository」で {name} を選択
   3. 「Environment Variables」に以下を設定:
      - DOTENV_PRIVATE_KEY: .env.keys 内の値をコピー
   4. 「Deploy」をクリック
   ```

#### 従来の方法（dotenvx を使わない場合）

```
【.env.local の手動作成】

1. VSCode で projects/{name} フォルダを開く
2. 新しいファイル .env.local を作成
3. OPENAI_API_KEY=sk-あなたのAPIキー を記入
4. 保存（Cmd + S）

※ この方法では .env.local はコミットできません
```

---

### Phase 7: 完了確認

```yaml
id: p7
name: 完了確認
goal: セットアップの完了を確認
executor: llm
depends_on: [p6]
done_criteria:
  - ローカルで動作する（pnpm dev）
  - GitHub にコードがある
  - Vercel で公開されている
  - 主要機能が動作する
status: pending
```

**チェックリスト:**
- [ ] `pnpm dev` で localhost:3000 が開く
- [ ] GitHub リポジトリに最新コードがある
- [ ] Vercel の公開 URL にアクセスできる
- [ ] 機能が正常に動作する

---

### Phase 8: 開発移行

```yaml
id: p8
name: 開発移行
goal: Skills を確認し、plan/project.md を生成し、product レイヤーへ移行
executor: llm
depends_on: [p7]
done_criteria:
  - .claude/skills/lint-checker/ が存在する（事前配置済み）
  - .claude/skills/test-runner/ が存在する（事前配置済み）
  - .claude/skills/deploy-checker/ が存在する（事前配置済み）
  - plan/template/project-format.md を読んだ
  - plan/project.md が生成されている（tech_decisions, non_functional_requirements 含む）
  - state.md の project_context.generated が true
  - state.md の focus.current が product
  - layer.setup.state が done
status: pending
```

**LLM の行動:**

1. **Skills を確認**（事前配置済み）:
   ```
   .claude/skills/
   ├── lint-checker/
   │   └── SKILL.md    # ESLint/Biome 実行、エラー修正
   ├── test-runner/
   │   └── SKILL.md    # Jest/Vitest 実行、カバレッジ確認
   └── deploy-checker/
       └── SKILL.md    # build 確認、env 確認、Vercel 状態
   ```
   ※ Skills は .claude/skills/ に事前配置されている。新規生成は不要。

2. `plan/template/project-format.md` を読む
3. `plan/project.md` を生成:
   - **meta**: プロジェクト名、作成日、タイプ、場所
   - **vision**: ユーザーの意図、成功の定義
   - **tech_decisions**: 開発言語、フレームワーク、ライブラリ、デプロイ先（Phase 1-A で決定 or デフォルト）
   - **non_functional_requirements**: 規模、パフォーマンス、セキュリティ、可用性、予算、期間
   - **stack**: tech_decisions から導出した最終構成
   - **constraints**: 制約条件
   - **milestones**: マイルストーン

3. **重要**: tech_decisions と non_functional_requirements は必ず記載
   - 初心者ルート → デフォルト値を記載（理由: 「デフォルト推奨に従った」）
   - 経験者ルート → Phase 1-A の回答を記載

4. `state.md` を更新:
   - `project_context.generated: true`
   - `project_context.project_plan: plan/project.md`
   - `layer.setup.state: done`
   - `focus.current: product`

5. 完了メッセージ:
   ```
   おめでとうございます！
   開発環境のセットアップが完了しました。

   【プロジェクト概要】
   - 名前: {name}
   - 場所: projects/{name}/
   - 公開 URL: {vercel_url}

   【技術スタック】
   - 言語: {language}
   - フレームワーク: {framework}
   - デプロイ: {deploy}

   技術選択と非機能要件は plan/project.md に記録しました。
   今後の開発はこの設定に基づいて進めます。

   追加したい機能があれば教えてください。
   開発計画（playbook）を作成します。
   ```

**tech_decisions 永続化の意図:**
- LLM は次セッション以降も plan/project.md を読む
- 最初に決めた技術選択に引っ張られ続ける
- 一貫性のある開発が可能になる

---

## Tutorial Route（Phase 0 で A を選択した場合）

Phase 1-6 をスキップし、簡易フローを実行。

```yaml
- id: t1
  name: Google AI Studio セットアップ
  goal: 10 分で AI チャットを動かす
  executor: user + llm
  done_criteria:
    - Google AI Studio でアカウント作成済み
    - API キー取得済み（.env.local に設定）
    - AI チャットがローカルで動作する
  status: pending

- id: t2
  name: 本番開発への移行（オプション）
  goal: ユーザーが「本番開発したい」と言ったら Production Route へ
  executor: user
  done_criteria:
    - ユーザーが本番開発を希望した場合、p1 から開始
  status: pending
```

**参照:** CATALOG.md セクション 9（チュートリアル詳細）

---

## LLM 行動指針

### 質問ルール

```yaml
質問してよい:
  - Phase 0 のルート選択（Tutorial / Production）
  - Phase 0 のスキルレベル確認（初心者 / 経験者）
  - Phase 1 の「何を作りたいか」
  - Phase 1-A の4層選択（経験者のみ）
  - Phase 1-A の認証・決済確認（経験者のみ）
  - ai_chat の3段階選択
  - 判断に迷った時の確認

質問してはいけない:
  - 初心者ルートでの技術選択（デフォルトを使う）
  - 「これでよいですか？」（確認求め）
  - 「次に何をしますか？」
  - 「〇〇しますか？」（するに決まっている）
```

### API キー取り扱い（厳守）【構造的ブロック】

```yaml
絶対禁止:
  - ユーザーに API キーをチャットに入力させる
  - API キーを echo/cat でファイルに書き込む
  - 「API キーを教えてください」と聞く
  - .env* ファイルに直接書き込む（Edit/Write）

正しい対応:
  - .env.example を作成してプレースホルダーを表示
  - ファイル形式とキー名だけを教える
  - ユーザー自身で .env.local を作成させる
  - 確認は「設定完了」の報告のみ

キーを受け取ってしまった場合【重要】:
  1. 即座に警告を出す
     「⚠️ チャットに API キーを入力しないでください！」
  2. そのキーは絶対に使用しない
     - Edit/Write で .env* に書き込まない
     - Bash でも echo しない
  3. ユーザーにキーの再生成を推奨
     「セキュリティのため、キーを再生成してください」
  4. 正しい設定方法を再案内
     「.env.local ファイルをご自身で作成してください」

検出パターン（自己チェック）:
  - sk-* (OpenAI)
  - pk_* / sk_* (Stripe)
  - AKIA* (AWS)
  - AIza* (Google)
  - これらのパターンを含むテキストを受け取ったら警告
```

### Codex 委譲基準【重要】

```yaml
Codex に委譲すべきタスク:
  - 新規コード 50 行以上の作成
  - 複雑なロジック実装（将棋ルール、認証フローなど）
  - 既存コードの大規模リファクタリング
  - テストコードの作成

Claude Code が直接実行すべきタスク:
  - 設定ファイル（.env.example, package.json）
  - 簡易な UI 変更（スタイル調整）
  - git 操作、デプロイ
  - playbook / state.md の管理

委譲方法:
  mcp__codex__codex ツールを使用
  渡す情報: 目標、done_criteria、コーディングルール
  渡さない情報: state.md 全体、playbook 全体

⚠️ E2E テストでの教訓:
  - 将棋ロジック 282 行を Claude Code が直接書いた → Codex に任せるべきだった
  - コンテキストが肥大し、ルール遵守率が低下した
```

### Phase 完了時の必須行動

```yaml
Phase 完了チェックリスト:
  1. done_criteria の全項目に「証拠」を示す
     - コマンド実行結果
     - ファイル存在確認（ls）
     - 該当箇所の引用
  2. playbook 内の当該 Phase の status を done に更新
  3. Phase 5, 7, 8 では critic を呼び出す
     - /crit または Task(subagent_type="critic")

禁止事項:
  - 証拠なしで「完了しました」
  - status を pending のまま放置
  - critic なしで Phase 7, 8 を完了

⚠️ E2E テストでの教訓:
  - 全 Phase が pending のまま完了報告 → status 更新を忘れた
  - critic を Phase 8 でのみ呼び出し → 遅すぎた
```

### critic 発動タイミング

```yaml
必須発動:
  - Phase 5 完了時（プロジェクト作成後）
  - Phase 7 完了時（デプロイ後）
  - Phase 8 完了時（開発移行前）

推奨発動:
  - 大きなコード変更後
  - done_criteria に自信がない時

呼び出し方:
  - /crit
  - Task(subagent_type="critic")

critic が FAIL を返したら:
  1. 指摘された問題を修正
  2. 再度 critic を呼び出す
  3. PASS するまで繰り返す
```

### CATALOG.md 参照タイミング

```yaml
# 必要な時だけ、該当セクションのみ読む

セクション 1: ツールインストールでエラーが出た時
セクション 2: API キー関連のトラブル
セクション 5: SaaS テンプレート使用時
セクション 9: チュートリアル詳細が必要な時
```

---

## 補足

```yaml
プロジェクト配置:
  dev-workspace のルートに projects/ ディレクトリを作成
  例: projects/my-ai-chat/

開発計画:
  dev-workspace のルートに plan/project.md を生成
  プロジェクトコードとは別の場所

Skills:
  .claude/skills/ に自動生成
  lint-checker, test-runner, deploy-checker
```

---

## 現在のシステム構成（2025-12-09 時点）

> **setup 完了後に利用可能になる機能の一覧**

### コンポーネント数

| カテゴリ | 数 | 説明 |
|---------|---|------|
| Hooks | 22 | 構造的強制（settings.json に 16 個登録） |
| SubAgents | 10 | 検証・自動化エージェント |
| Skills | 9 | 自動発火スキル（4 個はテンプレート） |
| Commands | 7 | スラッシュコマンド |
| Frameworks | 1 | 評価フレームワーク |

### 主要機能

```yaml
タスク管理:
  - pm SubAgent: タスク開始の必須経由点
  - /task-start: 標準タスク開始コマンド
  - playbook-guard: playbook なしの Edit/Write をブロック

品質保証:
  - critic SubAgent: done_criteria の第三者検証
  - critic-guard: critic PASS なしの done をブロック
  - reviewer SubAgent: コードレビュー

git 自動化:
  - Phase 完了時: 自動コミット
  - playbook 完了時: 自動マージ
  - 新タスク時: 自動ブランチ作成

状態管理:
  - state.md: 統合状態管理（Single Source of Truth）
  - state-mgr SubAgent: 状態遷移管理
  - state-rollback: 状態巻き戻し

セキュリティ:
  - protected-files.txt: 保護ファイル定義
  - check-protected-edit: 保護ファイル編集チェック
  - check-main-branch: main ブランチ保護

コンテキスト:
  - session-start/end: セッション管理
  - context-log.md: コンテキスト外部化
  - stop-summary: セッション終了サマリー
```

### 参照ドキュメント

| ファイル | 内容 |
|---------|------|
| docs/current-implementation.md | 現在実装の詳細仕様（復旧手順含む） |
| docs/extension-system.md | Claude Code 公式リファレンス |
| docs/file-inventory.md | 全ファイルの存在理由 |
| docs/task-initiation-flow.md | タスク開始フロー図 |
| CLAUDE.md | LLM 振る舞いルール |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | V2.0: 設計思想強化、クイックスタート追加、実例参照セクション追加、現在のシステム構成追加 |
| 2025-12-08 | V1.1: レビューツール選択（CodeRabbit/Codex）追加、Linter/Formatter Phase 追加 |
| 2025-12-01 | V1.0: 初版作成 |
