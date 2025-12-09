# CATALOG.md - ツール・サービスカタログ

> **このファイルは「何が使えるか」を定義する知識ベース。**
> **「どう使うか」は playbook-setup.md を参照。**

---

## 1. 基盤ツール（必須）

### 1.1 Homebrew

```yaml
種類: パッケージ管理
必須度: 必須
料金: 無料

インストール:
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

確認:
  brew --version

公式: https://brew.sh/
```

### 1.2 Git

```yaml
種類: バージョン管理
必須度: 必須
料金: 無料

インストール:
  brew install git

確認:
  git --version

公式: https://git-scm.com/
```

### 1.3 Node.js

```yaml
種類: JavaScript 実行環境
必須度: 必須
料金: 無料

インストール:
  brew install node

確認:
  node --version
  npm --version

公式: https://nodejs.org/
```

### 1.4 pnpm

```yaml
種類: パッケージマネージャ
必須度: 推奨（npm より高速）
料金: 無料

インストール:
  npm install -g pnpm

確認:
  pnpm --version

公式: https://pnpm.io/
```

### 1.5 VS Code（エディタ）

```yaml
種類: コードエディタ
必須度: 推奨
料金: 無料

概要:
  Microsoft 製の無料コードエディタ。
  拡張機能が豊富で、TypeScript/Next.js 開発に最適。

インストール:
  方法1（Homebrew）:
    brew install --cask visual-studio-code

  方法2（手動）:
    1. https://code.visualstudio.com/ にアクセス
    2. 「Download for Mac」をクリック
    3. ダウンロードした .zip を展開
    4. Visual Studio Code.app を Applications に移動

確認:
  code --version

起動:
  方法1: Spotlight（⌘ + Space）で「Visual Studio Code」と入力
  方法2: ターミナルで code .（現在のフォルダを開く）

推奨拡張機能:
  - ESLint: JavaScript/TypeScript の構文チェック
  - Prettier: コード自動整形
  - Tailwind CSS IntelliSense: Tailwind の補完
  - GitLens: Git 履歴の可視化

公式: https://code.visualstudio.com/
```

### 1.6 ターミナル基礎

```yaml
種類: コマンドライン操作
必須度: 必須（Mac 標準）

開き方:
  方法1: Spotlight（⌘ + Space）で「ターミナル」と入力して Enter
  方法2: Finder → アプリケーション → ユーティリティ → ターミナル
  方法3: Launchpad で「ターミナル」を検索

基本操作:
  コマンド実行: コマンドを入力して Enter キーを押す
  コピー: ⌘ + C
  ペースト: ⌘ + V
  中断: Ctrl + C（実行中のコマンドを止める）
  クリア: ⌘ + K（画面をきれいにする）

よく使うコマンド:
  ls: ファイル一覧を表示
  cd フォルダ名: フォルダに移動
  cd ..: 1つ上のフォルダに移動
  pwd: 現在のフォルダを表示
  mkdir フォルダ名: フォルダを作成

ドットファイル（.で始まるファイル）の表示:
  Finder で表示: ⌘ + Shift + .（ピリオド）
  ターミナルで表示: ls -la

注意:
  - ⌘ はキーボード左下の「コマンドキー」
  - Ctrl は ⌘ の隣にある「コントロールキー」
  - 大文字/小文字を区別する
```

### 1.7 概念マッピング表（他言語経験者向け）

```yaml
概要:
  他の言語/環境の経験がある人向けの対応表。
  「あぁ、Python で言うところの○○か」と理解できる。

パッケージ管理:
  Python:
    pip → npm/pnpm
    requirements.txt → package.json
    virtualenv → nvm（Node バージョン管理）
    PyPI → npm registry

  Java:
    Maven/Gradle → pnpm
    pom.xml / build.gradle → package.json
    JDK → Node.js
    Maven Central → npm registry

  Ruby:
    gem → npm/pnpm
    Gemfile → package.json
    bundler → pnpm
    RubyGems → npm registry

  Go:
    go mod → pnpm
    go.mod → package.json
    $GOPATH → node_modules

フレームワーク:
  Python:
    Django/Flask → Next.js
    Jinja2 → React/JSX
    Django ORM → Prisma

  Java:
    Spring Boot → Next.js
    JSP/Thymeleaf → React/JSX
    JPA/Hibernate → Prisma

  PHP:
    Laravel → Next.js
    Blade → React/JSX
    Eloquent → Prisma

デプロイ:
  Python: Heroku, Railway → Vercel
  Java: AWS EC2, Tomcat → Vercel
  PHP: Apache, Nginx → Vercel

型システム:
  TypeScript は以下に近い:
    - Java の型システム（厳格な型チェック）
    - Python の type hints（オプショナル型）
    - 静的型付け + 型推論
```

---

## 2. AI 開発ツール

### 2.1 ChatGPT Codex（コーディングエージェント）

```yaml
種類: クラウドコーディングエージェント
必須度: オプション
料金: ChatGPT Plus（$20/月）以上

概要:
  OpenAI の AI コーディングエージェント。
  リポジトリを読み込み、機能追加・バグ修正・PR作成を自動化。

セットアップ方法:
  Web版:
    1. chatgpt.com/codex にアクセス
    2. GitHub アカウントを連携
    3. リポジトリを選択してタスクを依頼

  CLI版:
    npm install -g @openai/codex
    codex  # 初回は ChatGPT でサインイン

  IDE拡張:
    VSCode / Cursor / Windsurf で利用可能

公式: https://openai.com/codex/
ドキュメント: https://developers.openai.com/codex/quickstart/
```

### 2.2 Claude Code（コーディングエージェント）

```yaml
種類: ターミナルコーディングエージェント
必須度: オプション
料金: Claude Pro（$20/月）以上

概要:
  Anthropic の AI コーディングエージェント。
  ターミナルで動作し、ファイル編集・コマンド実行・MCP連携が可能。

セットアップ方法:
  npm install -g @anthropic-ai/claude-code
  claude  # 初回は認証

公式: https://claude.ai/
```

### 2.3 Context7（MCP ドキュメントサーバー）

```yaml
種類: LLM 向けドキュメント提供 MCP
必須度: オプション（推奨）
料金: 無料（高レート制限は有料）

概要:
  最新のライブラリドキュメントを LLM に提供。
  Claude Code や Cursor と連携して使用。

セットアップ方法:
  Claude Code（リモート接続）:
    claude mcp add --transport http context7 https://mcp.context7.com/mcp

  Claude Code（ローカル接続）:
    claude mcp add context7 -- npx -y @upstash/context7-mcp

  使い方:
    プロンプトに「use context7」を追加

公式: https://context7.com/
GitHub: https://github.com/upstash/context7
```

### 2.4 OpenRouter（統一 AI API）

```yaml
種類: AI モデルアグリゲーター
必須度: オプション
料金: 従量課金（モデルにより異なる）

概要:
  60+ プロバイダー、300+ モデルへの統一 API。
  OpenAI SDK 互換なので既存コードをそのまま使える。

対応モデル:
  - OpenAI (GPT-4, GPT-5)
  - Anthropic (Claude)
  - Google (Gemini)
  - Meta (Llama)
  - DeepSeek
  - Mistral

セットアップ方法:
  1. https://openrouter.ai/ でアカウント作成
  2. クレジット購入
  3. API キー取得
  4. base_url を openrouter.ai に向ける

公式: https://openrouter.ai/
```

### 2.5 Google AI Studio（無料 AI API）

```yaml
種類: AI API
必須度: オプション
料金: 無料（制限あり）

概要:
  Google の Gemini API を無料で利用可能。
  入出力トークンが無料枠内で利用できる。

無料枠の制限:
  - 一部モデルへのアクセス制限
  - Context caching 不可
  - Batch API 不可
  - コンテンツは製品改善に使用される

セットアップ方法:
  1. https://aistudio.google.com/ にアクセス
  2. Google アカウントでログイン
  3. API キーを取得
  4. アプリケーションに組み込み

公式: https://aistudio.google.com/
ドキュメント: https://ai.google.dev/
料金: https://ai.google.dev/pricing
```

### 2.6 CodeRabbit CLI（AI コードレビュー）

```yaml
種類: AI コードレビューツール
必須度: オプション
料金: 無料（レート制限あり）

概要:
  AI によるコードレビューをターミナルで実行。
  コミット前にバグ・セキュリティ問題・コード品質を検出。
  Claude Code や Codex と連携して自動修正も可能。

インストール:
  curl -fsSL https://cli.coderabbit.ai/install.sh | sh
  source ~/.zshrc

認証:
  coderabbit auth login

主なコマンド:
  coderabbit                    # インタラクティブレビュー
  coderabbit --prompt-only      # AI 向け出力（Claude Code 連携用）
  coderabbit --type uncommitted # 未コミット変更のみレビュー

オプション:
  -t, --type <type>    # all | committed | uncommitted
  --base <branch>      # 比較ベースブランチ
  -c, --config <file>  # 追加設定ファイル

注意:
  - レビュー実行に 7-30 分かかる場合あり
  - バックグラウンド実行推奨
  - 全コミットに必須ではない（PR 前の最終チェック向け）

公式: https://www.coderabbit.ai/cli
ドキュメント: https://docs.coderabbit.ai/cli/overview
```

---

## 3. デプロイ先

### 3.1 Vercel（推奨: フロントエンド）

```yaml
種類: フロントエンドホスティング
必須度: オプション
料金: 無料枠あり（Hobby プラン）

概要:
  Next.js 最適化のホスティングサービス。
  Git push でデプロイ、プレビュー URL 自動発行。

無料枠:
  - 月 100GB 帯域
  - 無制限のサイト数
  - 自動 HTTPS

セットアップ方法:
  npm i -g vercel
  vercel login
  vercel --prod

推奨フレームワーク: Next.js

公式: https://vercel.com/
ドキュメント: https://vercel.com/docs
```

### 3.2 Cloudflare Pages（無料枠大）

```yaml
種類: 静的サイト / フルスタックホスティング
必須度: オプション
料金: 無料枠あり（非常に大きい）

概要:
  Cloudflare のグローバルネットワークにデプロイ。
  Pages Functions でサーバーサイド処理も可能。

無料枠:
  - 月 500 デプロイ
  - 無制限の帯域
  - 無制限のサイト数
  - 自動 HTTPS

セットアップ方法:
  1. https://dash.cloudflare.com/ でアカウント作成
  2. Pages を選択
  3. Git リポジトリを連携（または Direct Upload）
  4. ビルド設定を入力してデプロイ

推奨フレームワーク: Next.js, Astro, SvelteKit

公式: https://pages.cloudflare.com/
ドキュメント: https://developers.cloudflare.com/pages/
```

### 3.3 Cloudflare Workers（サーバーレス）

```yaml
種類: サーバーレス関数
必須度: オプション
料金: 無料枠あり

概要:
  エッジで動作するサーバーレス関数。
  API サーバー、Webhook 処理などに最適。

無料枠（日次リセット）:
  Workers:
    - 100,000 リクエスト/日
    - 10ms CPU 時間/リクエスト

  Workers KV:
    - 100,000 読み取り/日
    - 1,000 書き込み/日
    - 1GB ストレージ

  D1（データベース）:
    - 500万行読み取り/日
    - 10万行書き込み/日
    - 5GB ストレージ

セットアップ方法:
  npm install -g wrangler
  wrangler login
  wrangler init my-worker
  wrangler deploy

公式: https://workers.cloudflare.com/
ドキュメント: https://developers.cloudflare.com/workers/
料金: https://developers.cloudflare.com/workers/platform/pricing/
```

### 3.4 GCP（Cloud Run）

```yaml
種類: コンテナホスティング
必須度: オプション
料金: 無料枠あり

概要:
  Docker コンテナをデプロイ。
  自動スケーリング、従量課金。

追加ツール:
  - gcloud CLI
  - Docker

セットアップ方法:
  1. GCP コンソールでプロジェクト作成
  2. gcloud CLI インストール
  3. Dockerfile 作成
  4. gcloud builds submit
  5. gcloud run deploy

公式: https://cloud.google.com/run
```

### 3.5 AWS（Amplify）

```yaml
種類: フルスタックホスティング
必須度: オプション
料金: 無料枠あり

追加ツール:
  - aws CLI
  - amplify CLI

セットアップ方法:
  npm install -g @aws-amplify/cli
  amplify configure
  amplify init

公式: https://aws.amazon.com/amplify/
```

---

## 4. 開発補助ツール

### 4.1 ngrok（ローカルサーバー公開）

```yaml
種類: トンネリングサービス
必須度: オプション（Webhook 開発時に便利）
料金: 無料枠あり

概要:
  ローカルで動作するサーバーに公開 URL を発行。
  Webhook 開発、リモートデモ、外部連携テストに最適。

セットアップ方法:
  brew install ngrok
  ngrok config add-authtoken $YOUR_TOKEN

使い方:
  ngrok http 3000
  # → https://xxxxx.ngrok.io でアクセス可能

公式: https://ngrok.com/
ドキュメント: https://ngrok.com/docs/getting-started/
```

### 4.2 GitHub CLI

```yaml
種類: GitHub 操作 CLI
必須度: 必須（Claude Code 連携に必要）
料金: 無料

インストール:
  brew install gh
  gh auth login

使い方:
  gh repo create
  gh pr create
  gh issue list

公式: https://cli.github.com/
```

### 4.3 GitHub と Claude Code の連携（必須）

> **重要**: Claude Code が git push / git commit を実行するには事前認証が必須。
> Claude Code のターミナルはインタラクティブなパスワード入力に対応していない。

#### 4.3.1 推奨構成

```yaml
最も推奨: GitHub CLI + SSH キー（パスフレーズなし）

理由:
  - セキュリティと利便性のバランスが最良
  - gh コマンドで PR 作成、Issue 管理も可能
  - パスフレーズ入力が不要
```

#### 4.3.2 セットアップ手順

```bash
# Step 1: GitHub CLI のインストールと認証
brew install gh
gh auth login

# 対話的な質問に答える:
# - GitHub.com を選択
# - HTTPS を選択（推奨）
# - 認証方法: Login with a web browser
# - ブラウザでワンタイムコードを入力

# Step 2: 認証の確認
gh auth status
# 出力例:
# ✓ Logged in to github.com as username

# Step 3: SSH キーの生成（オプション、推奨）
ssh-keygen -t ed25519 -C "your_email@example.com"
# ⚠️ パスフレーズは空のまま Enter（Claude Code 対応のため）

# Step 4: SSH キーを GitHub に登録
gh ssh-key add ~/.ssh/id_ed25519.pub --title "Mac Dev"

# Step 5: SSH 接続テスト
ssh -T git@github.com
# 出力例:
# Hi username! You've successfully authenticated...
```

#### 4.3.3 認証方式の比較

| 方式 | セキュリティ | 使いやすさ | Claude Code 対応 |
|------|-------------|-----------|-----------------|
| **GitHub CLI** | ★★★★ | ★★★★★ | ✅ 完全対応 |
| **SSH（パスフレーズなし）** | ★★★ | ★★★★ | ✅ 完全対応 |
| **SSH（パスフレーズあり）** | ★★★★★ | ★★ | ❌ 非対応 |
| **HTTPS + PAT** | ★★★ | ★★★ | ✅ 対応 |

#### 4.3.4 トラブルシューティング

```yaml
問題: git push で認証エラー
解決:
  1. gh auth status で認証状態を確認
  2. gh auth login で再認証
  3. git remote -v でリモート URL を確認

問題: SSH 認証に失敗
解決:
  1. ssh -T git@github.com で接続テスト
  2. パスフレーズが設定されていないか確認
  3. ssh-add ~/.ssh/id_ed25519 で鍵を追加

問題: Claude Code で gh コマンドが使えない
解決:
  1. /permissions で権限を確認
  2. Bash(gh:*) を許可リストに追加

問題: 「Please complete authentication in your browser」が出る
解決:
  - Claude Code ターミナルではブラウザ認証できない
  - 先に通常のターミナルで gh auth login を完了させる
```

#### 4.3.5 Claude Code 権限設定

```json
// .claude/settings.json に追加
{
  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(gh:*)"
    ]
  }
}
```

#### 4.3.6 参考リンク

```yaml
公式:
  - GitHub CLI: https://cli.github.com/
  - GitHub SSH: https://docs.github.com/authentication/connecting-to-github-with-ssh

Claude Code 関連:
  - 認証問題: https://github.com/anthropics/claude-code/issues/2911
  - GitHub Actions 連携: https://docs.anthropic.com/en/docs/claude-code/github-actions
```

---

## 5. Vercel 最適化 SaaS テンプレート（推奨）

> **Vercel デプロイに完全最適化された本番対応テンプレート。**
> **setup は、このテンプレートを最もスムーズに動作させることを目指す。**

### 5.1 next-saas-stripe-starter 概要

```yaml
種類: Next.js 14 SaaS スターター（本番対応）
必須度: SaaS 開発時は強く推奨
料金: 無料（MIT ライセンス）
GitHub: https://github.com/mickasmt/next-saas-stripe-starter

特徴:
  - Vercel ワンクリックデプロイ対応
  - 認証・決済・管理画面が統合済み
  - TypeScript + 型安全な実装
  - shadcn/ui による洗練された UI
  - Server Actions 活用（Next.js 14 最新機能）
```

### 5.2 完全技術スタック

```yaml
# フレームワーク
Next.js: 14.2.5          # App Router、Server Actions
React: 18.3.1            # 最新 React
TypeScript: 5.x          # 型安全性

# 認証
Auth.js: v5              # 旧 NextAuth.js
  - JWT 戦略
  - Prisma Adapter
  - Google / GitHub OAuth
  - マジックリンク認証

# データベース
Prisma: ORM              # 型安全なDB操作
Neon: PostgreSQL         # サーバーレス DB

# 決済
Stripe:
  - サブスクリプション管理
  - Customer Portal
  - Webhook 統合

# メール
Resend: メール配信
React Email: テンプレート

# UI / スタイリング
Tailwind CSS: 3.4.x      # ユーティリティ CSS
shadcn/ui: コンポーネント  # Radix UI ベース
Framer Motion: アニメーション
Lucide: アイコン
Recharts: グラフ

# フォーム
React Hook Form: フォーム管理
Zod: バリデーション

# コンテンツ
Contentlayer: MDX 管理   # ブログ・ドキュメント

# 開発ツール
ESLint: コード品質
Prettier: フォーマット
Husky: Git hooks
```

### 5.3 ディレクトリ構造（詳細）

```
next-saas-stripe-starter/
│
├── app/                          # Next.js App Router
│   ├── (auth)/                   # 認証ページグループ
│   │   ├── login/                #   ログイン
│   │   └── register/             #   新規登録
│   │
│   ├── (marketing)/              # マーケティングページグループ
│   │   ├── page.tsx              #   ホーム（ランディング）
│   │   ├── blog/                 #   ブログ一覧
│   │   ├── [slug]/               #   動的ページ
│   │   └── pricing/              #   料金ページ
│   │
│   ├── (protected)/              # 認証必須ページグループ
│   │   ├── layout.tsx            #   認証チェック
│   │   ├── dashboard/            #   ダッシュボード
│   │   │   ├── page.tsx          #     メイン
│   │   │   ├── billing/          #     請求管理
│   │   │   ├── charts/           #     分析チャート
│   │   │   └── settings/         #     設定
│   │   └── admin/                #   管理者パネル
│   │       ├── page.tsx          #     管理者ダッシュボード
│   │       └── orders/           #     注文管理
│   │
│   ├── (docs)/                   # ドキュメントページグループ
│   │
│   └── api/                      # API ルート
│       ├── auth/[...nextauth]/   #   Auth.js エンドポイント
│       ├── og/                   #   OGP 画像生成
│       ├── user/                 #   ユーザー API
│       └── webhooks/stripe/      #   Stripe Webhook
│
├── actions/                      # Server Actions
│   ├── generate-user-stripe.ts   #   Stripe 顧客作成
│   ├── open-customer-portal.ts   #   顧客ポータル開く
│   ├── update-user-name.ts       #   ユーザー名更新
│   └── update-user-role.ts       #   ロール更新
│
├── components/                   # React コンポーネント
│   ├── ui/                       #   shadcn/ui 基本要素
│   ├── forms/                    #   フォーム
│   ├── layout/                   #   レイアウト（Header, Footer）
│   ├── dashboard/                #   ダッシュボード専用
│   ├── pricing/                  #   料金表示
│   ├── modals/                   #   モーダル
│   ├── charts/                   #   グラフ
│   └── shared/                   #   共通コンポーネント
│
├── config/                       # 設定ファイル
│   ├── site.ts                   #   サイト基本情報
│   ├── subscriptions.ts          #   サブスクプラン定義
│   ├── dashboard.ts              #   ダッシュボードナビ
│   ├── marketing.ts              #   マーケティングナビ
│   ├── landing.ts                #   LP 設定
│   ├── blog.ts                   #   ブログ設定
│   └── docs.ts                   #   ドキュメント設定
│
├── lib/                          # ユーティリティ
│   ├── db.ts                     #   Prisma クライアント
│   ├── stripe.ts                 #   Stripe クライアント
│   ├── subscription.ts           #   サブスク状態取得
│   ├── session.ts                #   セッション管理
│   ├── user.ts                   #   ユーザー操作
│   ├── email.ts                  #   メール送信
│   ├── utils.ts                  #   汎用ユーティリティ
│   └── validations/              #   Zod スキーマ
│
├── hooks/                        # カスタム React フック
│   ├── use-intersection-observer.ts
│   ├── use-local-storage.ts
│   ├── use-lock-body.ts
│   ├── use-media-query.ts
│   ├── use-mounted.ts
│   └── use-scroll.ts
│
├── emails/                       # React Email テンプレート
│   └── magic-link-email.tsx      #   マジックリンク
│
├── prisma/                       # データベース
│   └── schema.prisma             #   スキーマ定義
│
├── content/                      # Contentlayer コンテンツ
│   ├── blog/                     #   ブログ記事（MDX）
│   └── docs/                     #   ドキュメント（MDX）
│
├── public/                       # 静的ファイル
├── styles/                       # グローバル CSS
│
├── auth.ts                       # Auth.js 設定
├── middleware.ts                 # 認証ミドルウェア
├── env.mjs                       # 環境変数バリデーション
└── next.config.mjs               # Next.js 設定
```

### 5.4 データベーススキーマ（Prisma）

```prisma
// prisma/schema.prisma

enum UserRole {
  ADMIN
  USER
}

model User {
  id            String    @id @default(cuid())
  name          String?
  email         String?   @unique
  emailVerified DateTime?
  image         String?
  role          UserRole  @default(USER)

  // Stripe 統合
  stripeCustomerId       String?   @unique
  stripeSubscriptionId   String?   @unique
  stripePriceId          String?
  stripeCurrentPeriodEnd DateTime?

  // リレーション
  accounts Account[]
  sessions Session[]

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model Account {
  // OAuth プロバイダー接続情報
  userId            String
  type              String
  provider          String
  providerAccountId String
  refresh_token     String?
  access_token      String?
  expires_at        Int?
  token_type        String?
  scope             String?
  id_token          String?

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@id([provider, providerAccountId])
}

model Session {
  sessionToken String   @unique
  userId       String
  expires      DateTime
  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)
}

model VerificationToken {
  identifier String
  token      String   @unique
  expires    DateTime

  @@unique([identifier, token])
}
```

### 5.5 環境変数一覧（16個）

```bash
# .env.local

# ========================================
# アプリケーション設定
# ========================================
NEXT_PUBLIC_APP_URL="http://localhost:3000"  # 本番では https://yourdomain.com

# ========================================
# 認証（Auth.js v5）
# ========================================
AUTH_SECRET="your-auth-secret-here"          # openssl rand -base64 32 で生成

# Google OAuth
GOOGLE_CLIENT_ID="your-google-client-id"
GOOGLE_CLIENT_SECRET="your-google-client-secret"

# GitHub OAuth
GITHUB_OAUTH_TOKEN="your-github-oauth-token"

# ========================================
# データベース（Neon PostgreSQL）
# ========================================
DATABASE_URL="postgresql://user:password@host/database?sslmode=require"

# ========================================
# メール（Resend）
# ========================================
RESEND_API_KEY="re_xxxxxxxxxx"
EMAIL_FROM="SaaS Starter <onboarding@yourdomain.com>"

# ========================================
# 決済（Stripe）
# ========================================
STRIPE_API_KEY="sk_test_xxxxxxxxxx"          # 本番では sk_live_
STRIPE_WEBHOOK_SECRET="whsec_xxxxxxxxxx"

# Stripe 料金プラン ID（Stripe ダッシュボードで作成）
NEXT_PUBLIC_STRIPE_PRO_MONTHLY_PLAN_ID="price_xxxxxxxxxx"
NEXT_PUBLIC_STRIPE_PRO_YEARLY_PLAN_ID="price_xxxxxxxxxx"
NEXT_PUBLIC_STRIPE_BUSINESS_MONTHLY_PLAN_ID="price_xxxxxxxxxx"
NEXT_PUBLIC_STRIPE_BUSINESS_YEARLY_PLAN_ID="price_xxxxxxxxxx"
```

### 5.6 サブスクリプションプラン設定

```typescript
// config/subscriptions.ts

export const pricingPlans = [
  {
    title: "Starter",
    price: { monthly: 0, yearly: 0 },
    description: "無料で始められるプラン",
    features: [
      "月100投稿まで",
      "基本分析",
      "標準テンプレート",
    ],
    limitations: [
      "優先サポートなし",
      "カスタムブランディング不可",
    ],
  },
  {
    title: "Pro",
    price: { monthly: 15, yearly: 144 },  // 年額は20%オフ
    description: "成長中のビジネス向け",
    features: [
      "月500投稿まで",
      "高度な分析",
      "優先サポート",
      "ウェビナーアクセス",
    ],
    stripeIds: {
      monthly: process.env.NEXT_PUBLIC_STRIPE_PRO_MONTHLY_PLAN_ID,
      yearly: process.env.NEXT_PUBLIC_STRIPE_PRO_YEARLY_PLAN_ID,
    },
  },
  {
    title: "Business",
    price: { monthly: 30, yearly: 300 },
    description: "大規模チーム向け",
    features: [
      "無制限投稿",
      "リアルタイム分析",
      "24/7サポート",
      "完全なテンプレートアクセス",
      "カスタムブランディング",
    ],
    stripeIds: {
      monthly: process.env.NEXT_PUBLIC_STRIPE_BUSINESS_MONTHLY_PLAN_ID,
      yearly: process.env.NEXT_PUBLIC_STRIPE_BUSINESS_YEARLY_PLAN_ID,
    },
  },
];
```

### 5.7 Stripe Webhook 処理（実装例）

```typescript
// app/api/webhooks/stripe/route.ts

export async function POST(req: Request) {
  const body = await req.text();
  const signature = req.headers.get("Stripe-Signature")!;

  // 署名検証
  const event = stripe.webhooks.constructEvent(
    body,
    signature,
    process.env.STRIPE_WEBHOOK_SECRET!
  );

  switch (event.type) {
    // チェックアウト完了時
    case "checkout.session.completed": {
      const session = event.data.object;
      const subscription = await stripe.subscriptions.retrieve(
        session.subscription as string
      );

      // ユーザー情報を更新
      await db.user.update({
        where: { id: session.metadata.userId },
        data: {
          stripeSubscriptionId: subscription.id,
          stripeCustomerId: subscription.customer as string,
          stripePriceId: subscription.items.data[0].price.id,
          stripeCurrentPeriodEnd: new Date(
            subscription.current_period_end * 1000
          ),
        },
      });
      break;
    }

    // 請求成功時（更新）
    case "invoice.payment_succeeded": {
      const invoice = event.data.object;
      if (invoice.billing_reason !== "subscription_create") {
        const subscription = await stripe.subscriptions.retrieve(
          invoice.subscription as string
        );
        await db.user.update({
          where: { stripeSubscriptionId: subscription.id },
          data: {
            stripePriceId: subscription.items.data[0].price.id,
            stripeCurrentPeriodEnd: new Date(
              subscription.current_period_end * 1000
            ),
          },
        });
      }
      break;
    }
  }

  return new Response(null, { status: 200 });
}
```

### 5.8 セットアップ手順（完全版）

```bash
# ========================================
# Step 1: プロジェクト作成
# ========================================

# 方法A: npx で直接作成（推奨）
npx create-next-app my-saas --example "https://github.com/mickasmt/next-saas-stripe-starter"

# 方法B: git clone
git clone https://github.com/mickasmt/next-saas-stripe-starter my-saas

cd my-saas

# ========================================
# Step 2: 依存関係インストール
# ========================================
pnpm install

# ========================================
# Step 3: 環境変数設定
# ========================================
cp .env.example .env.local
# エディタで .env.local を編集（5.5 参照）

# ========================================
# Step 4: 外部サービスセットアップ
# ========================================

# 4-1. Neon（データベース）
#   1. https://neon.tech/ でアカウント作成
#   2. プロジェクト作成
#   3. 接続文字列を DATABASE_URL に設定

# 4-2. Auth.js
#   1. AUTH_SECRET を生成: openssl rand -base64 32
#   2. Google OAuth: https://console.cloud.google.com/
#   3. GitHub OAuth: https://github.com/settings/developers

# 4-3. Resend（メール）
#   1. https://resend.com/ でアカウント作成
#   2. API キーを取得
#   3. ドメイン認証（本番用）

# 4-4. Stripe（決済）
#   1. https://stripe.com/ でアカウント作成
#   2. API キーを取得
#   3. 商品・料金プランを作成
#   4. Webhook エンドポイントを設定

# ========================================
# Step 5: データベースセットアップ
# ========================================
npx prisma generate      # Prisma クライアント生成
npx prisma db push       # スキーマをDBに反映

# ========================================
# Step 6: 開発サーバー起動
# ========================================
pnpm run dev             # http://localhost:3000

# ========================================
# Step 7: Stripe ローカルテスト（別ターミナル）
# ========================================
stripe login
stripe listen --forward-to localhost:3000/api/webhooks/stripe
# 表示される whsec_xxx を STRIPE_WEBHOOK_SECRET に設定
```

### 5.9 Vercel デプロイ手順

```bash
# ========================================
# 方法A: ワンクリックデプロイ（最も簡単）
# ========================================
# GitHub の README にある "Deploy to Vercel" ボタンをクリック
# → 自動で Fork + デプロイ

# ========================================
# 方法B: CLI デプロイ
# ========================================

# 1. Vercel CLI インストール
npm i -g vercel

# 2. ログイン
vercel login

# 3. プロジェクトリンク
vercel link

# 4. 環境変数を Vercel に設定
vercel env add AUTH_SECRET
vercel env add DATABASE_URL
vercel env add STRIPE_API_KEY
# ... 他の環境変数も同様

# 5. デプロイ
vercel --prod

# ========================================
# 方法C: GitHub 連携（推奨）
# ========================================
# 1. GitHub にリポジトリを push
# 2. Vercel ダッシュボードで "Import Project"
# 3. リポジトリを選択
# 4. 環境変数を設定
# 5. Deploy

# ========================================
# デプロイ後の設定
# ========================================

# 1. NEXT_PUBLIC_APP_URL を本番 URL に更新
# 2. Stripe Webhook エンドポイントを本番 URL に更新
#    https://yourdomain.com/api/webhooks/stripe
# 3. OAuth リダイレクト URL を更新
# 4. Resend ドメイン認証
```

### 5.10 カスタマイズガイド

```yaml
# よくあるカスタマイズ

サイト情報変更:
  ファイル: config/site.ts
  内容: サイト名、説明、URL、ソーシャルリンク

料金プラン変更:
  ファイル: config/subscriptions.ts
  注意: Stripe ダッシュボードの料金 ID と合わせる

ナビゲーション変更:
  ファイル: config/marketing.ts, config/dashboard.ts

ランディングページ:
  ファイル: app/(marketing)/page.tsx
  セクション: components/sections/

ダッシュボード:
  ファイル: app/(protected)/dashboard/
  コンポーネント: components/dashboard/

認証プロバイダー追加:
  ファイル: auth.ts
  参照: https://authjs.dev/getting-started/providers

メールテンプレート:
  ファイル: emails/
  プレビュー: pnpm run email（localhost:3333）

新しいページ追加:
  - (marketing) 配下: 公開ページ
  - (protected) 配下: 認証必須ページ
  - (protected)/admin 配下: 管理者専用
```

### 5.11 npm スクリプト一覧

```bash
pnpm run dev        # 開発サーバー起動
pnpm run build      # 本番ビルド
pnpm run start      # 本番サーバー起動
pnpm run lint       # ESLint チェック
pnpm run turbo      # Turbo モードで開発
pnpm run preview    # ビルド後プレビュー
pnpm run email      # メールテンプレート開発（:3333）
# postinstall       # Prisma クライアント自動生成
```

---

### 5.12 Vercel AI Chatbot（ChatGPT クローン）

```yaml
種類: AI チャットボットテンプレート
必須度: AI チャット開発時は強く推奨
料金: 無料（MIT ライセンス）
GitHub: https://github.com/vercel/ai-chatbot
スター: 18.9k+

特徴:
  - Vercel 公式テンプレート（品質保証）
  - ChatGPT クローンが一瞬で作れる
  - 複数 AI モデル対応（xAI, OpenAI, Anthropic, Cohere）
  - Vercel AI Gateway で統一インターフェース
  - ファイルアップロード対応（画像解析）
```

#### 技術スタック

```yaml
# フレームワーク
Next.js: 16.x            # App Router + Turbopack
React: 19.0.0-rc         # 最新 React RC

# AI 統合
AI SDK: @ai-sdk/*        # Vercel AI SDK
  - gateway              # 統一 AI API
  - react                # React フック
  - xai                  # xAI プロバイダー
Vercel AI Gateway:       # 複数モデルへの統一アクセス

# データベース
Drizzle ORM: DB 操作     # Prisma の代替（軽量）
Neon: PostgreSQL         # チャット履歴保存
Redis: キャッシュ        # セッション管理

# ストレージ
Vercel Blob: ファイル    # 画像アップロード

# 認証
Auth.js: v5              # ユーザー認証

# UI
shadcn/ui: コンポーネント
Tailwind CSS: スタイリング
Radix UI: アクセシビリティ
Framer Motion: アニメーション

# エディタ
CodeMirror: コードエディタ
ProseMirror: リッチテキスト

# 開発ツール
Biome: Linter/Formatter  # ESLint + Prettier 代替
Playwright: E2E テスト
```

#### ディレクトリ構造

```
vercel-ai-chatbot/
│
├── app/                    # Next.js App Router
│   ├── (auth)/             #   認証ページ（login, register）
│   ├── (chat)/             #   チャット UI
│   ├── layout.tsx          #   ルートレイアウト
│   └── globals.css         #   グローバルスタイル
│
├── components/             # React コンポーネント
│   ├── chat/               #   チャット関連
│   ├── ui/                 #   shadcn/ui
│   └── ...
│
├── lib/                    # ユーティリティ
│   ├── db/                 #   Drizzle スキーマ・マイグレーション
│   ├── ai/                 #   AI SDK 設定
│   └── ...
│
├── public/                 # 静的ファイル
└── ...
```

#### 環境変数（5個）

```bash
# .env.local

# 認証
AUTH_SECRET="openssl rand -base64 32 で生成"

# AI Gateway（非 Vercel 環境のみ必要）
AI_GATEWAY_API_KEY="your-api-key"

# データベース
POSTGRES_URL="postgresql://..."

# Redis
REDIS_URL="redis://..."

# ファイルストレージ
BLOB_READ_WRITE_TOKEN="vercel-blob-token"
```

#### セットアップ手順

```bash
# ========================================
# 方法A: Vercel ワンクリックデプロイ（最も簡単）
# ========================================
# GitHub の README にある "Deploy to Vercel" ボタンをクリック
# → Neon DB, Redis, Blob が自動プロビジョニング

# ========================================
# 方法B: ローカル開発
# ========================================

# 1. Vercel CLI でプロジェクトをリンク
npm i -g vercel
vercel link

# 2. 環境変数をダウンロード
vercel env pull

# 3. 依存関係インストール
pnpm install

# 4. データベースマイグレーション
pnpm db:migrate

# 5. 開発サーバー起動
pnpm dev
# → http://localhost:3000

# ========================================
# 方法C: git clone
# ========================================
git clone https://github.com/vercel/ai-chatbot my-chatbot
cd my-chatbot
pnpm install

# .env.example を .env.local にコピーして編集
cp .env.example .env.local

# Neon, Redis, Vercel Blob を手動セットアップ
# 環境変数を設定後:
pnpm db:migrate
pnpm dev
```

#### 対応 AI モデル

```yaml
# Vercel AI Gateway 経由で以下のモデルに対応

xAI:
  - grok-beta（デフォルト）

OpenAI:
  - gpt-4o
  - gpt-4o-mini
  - gpt-4-turbo

Anthropic:
  - claude-3.5-sonnet
  - claude-3-opus
  - claude-3-haiku

Google:
  - gemini-1.5-pro
  - gemini-1.5-flash

Cohere:
  - command-r-plus
  - command-r

# モデル切り替えは AI Gateway 設定で簡単に変更可能
```

#### npm スクリプト

```bash
pnpm dev            # 開発サーバー起動（Turbopack）
pnpm build          # 本番ビルド（マイグレーション含む）
pnpm start          # 本番サーバー起動
pnpm lint           # Biome でコードチェック
pnpm format         # Biome でフォーマット
pnpm db:generate    # Drizzle スキーマ生成
pnpm db:migrate     # マイグレーション実行
pnpm db:studio      # Drizzle Studio（DB GUI）
pnpm db:push        # スキーマをDBに反映
pnpm test           # Playwright E2E テスト
```

#### SaaS Starter との違い

```yaml
next-saas-stripe-starter:
  用途: SaaS（課金・ユーザー管理）
  DB: Prisma ORM
  決済: Stripe 統合
  認証: Auth.js + OAuth
  特徴: 管理画面、サブスクリプション

vercel-ai-chatbot:
  用途: AI チャットアプリ
  DB: Drizzle ORM（軽量）
  AI: Vercel AI SDK + Gateway
  認証: Auth.js
  特徴: 複数モデル対応、ファイルアップロード

組み合わせ:
  SaaS + AI チャット機能が必要な場合、
  両方のパターンを参考に実装可能
```

---

## 6. SaaS 開発スタック

> **モダン SaaS を構築するための推奨技術スタック。**
> **これらを組み合わせて本番対応のアプリを素早く構築できる。**

### 6.1 shadcn/ui（UI コンポーネント）

```yaml
種類: UI コンポーネントライブラリ
必須度: 推奨
料金: 無料（オープンソース）

概要:
  カスタマイズ可能な美しいコンポーネントセット。
  Tailwind CSS ベースで、コードをコピーして使う設計。
  「ライブラリ」ではなく「コンポーネント集」。

特徴:
  - 60+ コンポーネント（Button, Dialog, Form, Table 等）
  - 完全にカスタマイズ可能（コードが自分のものになる）
  - Radix UI をベースにアクセシビリティ対応
  - ダークモード対応

セットアップ方法:
  # Next.js プロジェクトで初期化
  npx shadcn@latest init

  # コンポーネントを追加
  npx shadcn@latest add button
  npx shadcn@latest add dialog
  npx shadcn@latest add form

公式: https://ui.shadcn.com/
ドキュメント: https://ui.shadcn.com/docs
```

### 6.2 Stack Auth（認証）

```yaml
種類: 認証プラットフォーム
必須度: オプション（Auth.js の代替）
料金: 無料枠あり（オープンソース）

概要:
  Auth0 の代替となるオープンソース認証。
  shadcn/ui スタイルの美しい UI コンポーネント付き。
  B2B 向けの組織・チーム管理機能も備える。

特徴:
  - パスワード / SSO / 2FA 対応
  - 組織・チーム管理（B2B）
  - 権限ベースアクセス制御（RBAC）
  - OAuth 連携（Gmail, OneDrive 等）
  - Webhook 対応
  - Neon Auth として Neon DB と統合可能

セットアップ方法:
  npx @stackframe/init-stack@latest

公式: https://stack-auth.com/
ドキュメント: https://docs.stack-auth.com/
```

### 6.3 Prisma（ORM）

```yaml
種類: データベース ORM / ツールキット
必須度: 推奨
料金: 無料（オープンソース）、Prisma Postgres は有料

概要:
  TypeScript ファーストの次世代 ORM。
  スキーマ定義から型安全なクライアントを自動生成。
  マイグレーション管理も統合。

特徴:
  - 型安全なデータベースクエリ（自動補完付き）
  - スキーマをコードで定義（schema.prisma）
  - マイグレーション管理（prisma migrate）
  - Prisma Studio（GUI でデータ閲覧・編集）
  - 主要 DB 対応（PostgreSQL, MySQL, SQLite, MongoDB）

セットアップ方法:
  pnpm add prisma @prisma/client
  npx prisma init

  # スキーマ定義後
  npx prisma migrate dev --name init
  npx prisma generate

公式: https://www.prisma.io/
ドキュメント: https://www.prisma.io/docs
```

### 6.4 Neon（サーバーレス PostgreSQL）

```yaml
種類: サーバーレスデータベース
必須度: オプション（推奨）
料金: 無料枠あり

概要:
  サーバーレス PostgreSQL。自動スケーリング、
  アイドル時はゼロスケール。ブランチ機能で
  開発/本番を分離しやすい。

特徴:
  - オートスケーリング（トラフィックに応じて）
  - ブランチング（Git のようにDBをコピー）
  - 即座に復元（数TB でも数秒）
  - 接続プーリング（pgBouncer 組み込み）
  - Prisma / Next.js と相性抜群

無料枠:
  - 0.5 GB ストレージ
  - 1 プロジェクト
  - 無制限のブランチ

セットアップ方法:
  1. https://neon.tech/ でアカウント作成
  2. プロジェクト作成
  3. 接続文字列を取得
  4. Prisma の DATABASE_URL に設定

公式: https://neon.tech/
ドキュメント: https://neon.tech/docs
```

### 6.5 Resend（メール配信）

```yaml
種類: メール配信 API
必須度: オプション（メール機能が必要な場合）
料金: 無料枠あり

概要:
  開発者向けメール配信サービス。
  React Email でコンポーネントベースのメール作成が可能。
  トランザクションメール、マーケティングメール両対応。

特徴:
  - React Email（JSX でメール作成）
  - 複数言語 SDK（Node.js, Python, Go 等）
  - Webhook 対応（配信・開封・クリック追跡）
  - DKIM / SPF / DMARC 対応
  - Next.js 統合が簡単

無料枠:
  - 月 3,000 通
  - 1 ドメイン

セットアップ方法:
  pnpm add resend

  # 送信例
  import { Resend } from 'resend';
  const resend = new Resend('re_xxxxxxxxx');
  await resend.emails.send({
    from: 'onboarding@yourdomain.com',
    to: 'user@example.com',
    subject: 'Welcome!',
    html: '<p>Hello!</p>'
  });

公式: https://resend.com/
ドキュメント: https://resend.com/docs
```

### 6.6 Stripe（決済）

```yaml
種類: 決済プラットフォーム
必須度: オプション（課金機能が必要な場合）
料金: 従量課金（3.6% + ¥40 / 決済）

概要:
  世界標準の決済プラットフォーム。
  サブスクリプション、一回払い、従量課金など
  あらゆる課金モデルに対応。

特徴:
  - サブスクリプション管理
  - Customer Portal（顧客セルフサービス）
  - Webhook 連携（決済イベント通知）
  - Stripe CLI（ローカル開発・テスト）
  - 豊富な SDK

セットアップ方法:
  pnpm add stripe @stripe/stripe-js

  # Stripe CLI（ローカル Webhook テスト）
  brew install stripe/stripe-cli/stripe
  stripe login
  stripe listen --forward-to localhost:3000/api/webhooks/stripe

公式: https://stripe.com/
ドキュメント: https://stripe.com/docs
```

### 6.7 SaaS スタック組み合わせ例

```
┌─────────────────────────────────────────────────────────────┐
│                 モダン SaaS アーキテクチャ                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Next.js   │────▶│  Vercel     │────▶│   ユーザー   │
│  App Router │     │  (Deploy)   │     │             │
└─────────────┘     └─────────────┘     └─────────────┘
       │
       ├── UI: shadcn/ui + Tailwind CSS
       │
       ├── 認証: Stack Auth or Auth.js
       │
       ├── DB: Prisma + Neon (PostgreSQL)
       │
       ├── 決済: Stripe
       │
       └── メール: Resend

環境変数例（.env.local）:
  DATABASE_URL="postgresql://..."     # Neon
  STRIPE_SECRET_KEY="sk_..."          # Stripe
  STRIPE_WEBHOOK_SECRET="whsec_..."   # Stripe Webhook
  RESEND_API_KEY="re_..."             # Resend
  NEXT_PUBLIC_STACK_PROJECT_ID="..."  # Stack Auth
```

---

## 7. 料金比較

### 7.1 無料で始められるサービス

| サービス | 無料枠のポイント |
|----------|------------------|
| Cloudflare Pages | 月 500 デプロイ、無制限帯域 |
| Cloudflare Workers | 日 10万リクエスト |
| Vercel | 月 100GB 帯域 |
| Google AI Studio | Gemini API 無料 |
| Context7 | 基本機能無料 |
| ngrok | 基本機能無料 |
| Neon | 0.5GB ストレージ、無制限ブランチ |
| Resend | 月 3,000 通 |
| shadcn/ui | 完全無料（オープンソース）|
| Prisma | 完全無料（オープンソース）|
| Stack Auth | 無料枠あり（オープンソース）|

### 7.2 有料サービス

| サービス | 料金 | 用途 |
|----------|------|------|
| ChatGPT Plus | $20/月 | Codex（コーディングエージェント）|
| Claude Pro | $20/月 | Claude Code |
| OpenRouter | 従量課金 | 複数 AI モデル利用 |
| Stripe | 3.6% + ¥40/決済 | 決済処理 |

---

## 8. サーバー選定フローチャート（意思決定の起点）

> **「どこで動かすか」が最初の分岐点。**
> **ここから逆算してツール・テンプレートを選ぶ。**

### 8.1 最初の質問：デプロイは必要か？

```
「作ったものを公開する必要がありますか？」
        │
        ├── NO（ローカルのみ / 学習目的）
        │   └── デプロイ不要
        │       ├── 基盤ツールのみインストール（Homebrew, Git, Node.js, pnpm）
        │       └── localhost:3000 で開発
        │
        └── YES（公開する）
            └── 次の質問へ → 8.2
```

### 8.2 サーバーサイド処理は必要か？

```
「サーバー側で処理が必要ですか？」
（認証、DB、API、ファイル処理など）
        │
        ├── NO（静的サイトのみ）
        │   └── 8.3 静的サイトの選択肢へ
        │
        └── YES（サーバー処理が必要）
            └── 次の質問へ → 8.4
```

### 8.3 静的サイト（HTML/CSS/JS のみ）

```yaml
条件: サーバー処理不要、HTML/CSS/JS のみ

選択肢:
  Cloudflare Pages（推奨）:
    - 無料枠: 無制限帯域、月500デプロイ
    - 特徴: 最も無料枠が大きい
    - 適用: LP、ポートフォリオ、ブログ（静的生成）

  Vercel:
    - 無料枠: 月100GB帯域
    - 特徴: プレビューURL自動発行、GitHub連携が簡単
    - 適用: 同上

  GitHub Pages:
    - 無料枠: 完全無料
    - 特徴: 最もシンプル、カスタムドメイン対応
    - 適用: ドキュメント、個人サイト

推奨フレームワーク:
  - Astro（最速、静的生成に特化）
  - Next.js（静的エクスポート可能）
  - Hugo（Go製、超高速ビルド）
```

### 8.4 サーバー処理の「重さ」は？

```
「サーバー処理はどのくらい重いですか？」
        │
        ├── 軽い（API、認証、DB読み書き、Webhook）
        │   │
        │   └── 「実行時間は？」
        │       │
        │       ├── 短い（数秒以内）
        │       │   └── 8.5 サーバーレス関数へ
        │       │
        │       └── やや長い（10秒〜数分）
        │           └── 8.6 エッジ/サーバーレスの限界へ
        │
        └── 重い（長時間実行、大量データ処理、GPU）
            └── 8.7 コンテナ/VM へ
```

### 8.5 サーバーレス関数（軽量処理向け）

```yaml
条件: API、認証、DB操作など軽量処理（数秒以内）

# =====================================
# Vercel（推奨：Next.js使うなら）
# =====================================
Vercel Functions:
  実行時間上限: 10秒（Hobby）/ 60秒（Pro）
  無料枠: 月100GB帯域、100GB-Hrs実行時間
  特徴:
    - Next.js と完全統合
    - Edge Functions（超低レイテンシ）
    - Serverless Functions（Node.js）
  適用:
    - SaaS（next-saas-stripe-starter）
    - AIチャット（vercel-ai-chatbot）
    - 一般的なWebアプリ

# =====================================
# Cloudflare Workers（推奨：無料枠重視）
# =====================================
Cloudflare Workers:
  実行時間上限: 10ms CPU（Free）/ 50ms CPU（Paid）
  無料枠: 日10万リクエスト
  特徴:
    - エッジで実行（超高速）
    - D1（SQLite）、KV、R2と統合
    - Hono フレームワークと相性◎
  適用:
    - API サーバー
    - Webhook エンドポイント
    - 軽量バックエンド
  制限:
    - CPU時間が短い（重い処理不可）
    - Node.js API の一部が使えない
```

### 8.6 サーバーレスの限界を超える場合

```yaml
条件:
  - 実行時間が10秒〜数分
  - ストリーミング処理
  - 大きなファイル処理

# =====================================
# Vercel の対応策
# =====================================
Vercel Pro プラン:
  - 実行時間上限: 60秒（さらに延長可能）
  - Streaming: 対応
  - 料金: $20/月〜

Vercel Edge Functions:
  - 実行時間: 無制限（ストリーミング）
  - CPU時間: 50ms
  - 用途: AI ストリーミングレスポンス

# =====================================
# Cloudflare の対応策
# =====================================
Cloudflare Workers Paid:
  - CPU時間: 50ms
  - まだ足りない → Durable Objects、Queues

# =====================================
# それでも足りない場合
# =====================================
→ 8.7 コンテナ/VM へ
```

### 8.7 コンテナ/VM（重い処理向け）

```yaml
条件:
  - 長時間実行（数分〜数時間）
  - 大量データ処理
  - GPU が必要
  - 特殊なランタイム/ライブラリ

# =====================================
# GCP Cloud Run（推奨）
# =====================================
Cloud Run:
  実行時間上限: 60分
  無料枠: 月200万リクエスト、36万GB秒
  特徴:
    - Docker コンテナをそのままデプロイ
    - 自動スケーリング（0までスケールダウン）
    - 従量課金（使わなければ無料）
  適用:
    - バッチ処理
    - 動画/画像処理
    - ML推論（CPU）
  セットアップ:
    gcloud run deploy --source .

# =====================================
# GCP Compute Engine（VM）
# =====================================
Compute Engine:
  用途:
    - GPU が必要（ML学習など）
    - 常時起動サーバー
    - 特殊な要件
  無料枠: e2-micro 1台/月（一部リージョン）
  注意: 常時起動は課金に注意

# =====================================
# GCP Cloud Functions
# =====================================
Cloud Functions:
  実行時間上限: 9分（Gen2）
  用途: Cloud Run より軽い処理
  特徴: Node.js/Python/Go 対応
```

### 8.8 判断フローチャート（完全版）

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        サーバー選定フローチャート                             │
└─────────────────────────────────────────────────────────────────────────────┘

START: 「何を作りたいか」
        │
        ▼
┌───────────────────┐
│ デプロイ必要？     │
└───────────────────┘
        │
    NO ─┼─ YES
        │    │
        ▼    ▼
   ローカル  ┌───────────────────┐
   開発のみ  │ サーバー処理必要？ │
             └───────────────────┘
                      │
                  NO ─┼─ YES
                      │    │
                      ▼    ▼
             ┌─────────┐  ┌───────────────────┐
             │ 静的    │  │ 処理の重さは？     │
             │ サイト  │  └───────────────────┘
             └─────────┘           │
                  │         軽い ─┼─ 重い
                  │               │    │
                  ▼               ▼    ▼
        ┌─────────────────┐  ┌─────┐ ┌─────────┐
        │ Cloudflare Pages│  │     │ │ GCP     │
        │ or Vercel       │  │     │ │ Cloud   │
        │ or GitHub Pages │  │     │ │ Run     │
        └─────────────────┘  │     │ └─────────┘
                             │     │
                             ▼     │
                    ┌────────────┐ │
                    │ 無料重視？  │ │
                    └────────────┘ │
                         │         │
                     YES ┼ NO      │
                         │  │      │
                         ▼  ▼      │
               ┌──────────┐ ┌────┐ │
               │Cloudflare│ │    │ │
               │ Workers  │ │    │ │
               └──────────┘ │    │ │
                            ▼    │
                      ┌────────┐ │
                      │ Vercel │ │
                      │（推奨）│ │
                      └────────┘ │
                                 │
                    ┌────────────┴────────────┐
                    │                         │
                    ▼                         ▼
           ┌────────────────┐        ┌────────────────┐
           │ SaaS 作りたい   │        │ AIチャット     │
           │ （課金機能）    │        │ 作りたい       │
           └────────────────┘        └────────────────┘
                    │                         │
                    ▼                         ▼
           ┌────────────────┐        ┌────────────────┐
           │ next-saas-     │        │ vercel-ai-     │
           │ stripe-starter │        │ chatbot        │
           └────────────────┘        └────────────────┘
```

### 8.9 選定早見表

| 作りたいもの | デプロイ先 | テンプレート | 備考 |
|--------------|------------|--------------|------|
| LP/ポートフォリオ | Cloudflare Pages | - | 無料無制限 |
| ブログ（静的） | Cloudflare Pages / Vercel | Astro | 静的生成 |
| 個人Webアプリ | Vercel | Next.js | DX重視 |
| SaaS（課金あり） | Vercel | next-saas-stripe-starter | 本番対応 |
| AIチャット | Vercel | vercel-ai-chatbot | 複数モデル対応 |
| API サーバー | Cloudflare Workers | Hono | 無料枠大 |
| API サーバー（Node.js） | Vercel Functions | - | Express互換 |
| 重い処理/バッチ | GCP Cloud Run | - | Docker |
| GPU/ML | GCP Compute Engine | - | 要課金 |
| ローカルのみ | - | Next.js | 開発のみ |

### 8.10 コスト比較

```yaml
# 月間コスト目安（個人開発規模）

完全無料で運用可能:
  - Cloudflare Pages + Workers
  - Vercel Hobby（月100GB帯域まで）
  - GCP Cloud Run（無料枠内）
  - Neon Free（0.5GB）
  - Resend Free（月3,000通）

低コスト（$0-20/月）:
  - Vercel Pro: $20/月（チーム開発、長い実行時間）
  - Cloudflare Workers Paid: $5/月〜
  - Neon Pro: $19/月〜

中コスト（$20-100/月）:
  - GCP Cloud Run（トラフィック次第）
  - Stripe 手数料（売上の 3.6%）

注意:
  - AI API は従量課金（OpenAI, Anthropic）
  - DB は容量次第で課金
  - 画像/動画処理は帯域課金に注意
```

---

## 9. チュートリアル（学習用 AI チャット）

> **このセクションは Tutorial Route 専用**
> **本番開発とは完全に分離された、費用ゼロの学習環境**

### 9.1 概要

```yaml
目的: 10分で AI チャットを作り、成功体験を得る
費用: 無料（Google AI Studio 無料枠）
難易度: 初心者向け
所要時間: 10分

作るもの:
  - Next.js + TypeScript の Web アプリ
  - Google Gemini を使った AI チャット
  - ローカルで動作（デプロイなし）

必要なもの:
  - Mac
  - Google アカウント（Gmail）
  - インターネット接続
```

### 9.2 技術スタック

```yaml
フレームワーク:
  name: Next.js 14
  version: 安定版（最新 LTS）
  特徴: React ベース、App Router

言語:
  name: TypeScript
  理由: 型安全、エラーを事前に検出

AI SDK:
  name: Vercel AI SDK
  package: ai
  特徴: 複数 LLM に対応、ストリーミング対応

AI プロバイダー:
  name: Google AI Studio（Gemini）
  package: "@ai-sdk/google"
  モデル: gemini-1.5-flash
  料金: 無料（レート制限あり）
  制限:
    - 1分あたり 15 リクエスト
    - 1日あたり 1,500 リクエスト
    - 商用利用には有料プラン推奨

UI:
  name: Tailwind CSS
  特徴: ユーティリティファースト、簡単なスタイリング
```

### 9.3 Google AI Studio 詳細

```yaml
サービス名: Google AI Studio
URL: https://aistudio.google.com

無料枠:
  - Gemini 1.5 Flash: 無料
  - Gemini 1.5 Pro: 無料（レート制限厳しめ）
  - Gemini 2.0 Flash: 無料

レート制限（gemini-1.5-flash）:
  - RPM: 15（1分あたりリクエスト数）
  - TPM: 100万（1分あたりトークン数）
  - RPD: 1,500（1日あたりリクエスト数）

API キー形式: AIzaSyxxxxxxxxxx

取得手順:
  1. https://aistudio.google.com にアクセス
  2. Google アカウントでログイン
  3. 「Get API key」をクリック
  4. 「Create API key」→ プロジェクトを選択
  5. キーをコピー

注意事項:
  - API キーは公開しない（.env.local に保存）
  - 無料枠を超えると一時的にブロック
  - 商用利用には有料プラン推奨

公式ドキュメント: https://ai.google.dev/docs
```

### 9.4 最小構成コード

#### 環境変数（⚠️ ユーザー自身で作成）

> **セキュリティ注意**: API キーは LLM に教えない。ユーザー自身でファイルを作成する。

```bash
# .env.local（ユーザーが自分で作成）
GOOGLE_GENERATIVE_AI_API_KEY=ここにAPIキーを貼り付け

# ⚠️ このファイルは .gitignore に含まれており、GitHub にはアップロードされない
```

```yaml
# LLM 向けルール
API_KEY_SECURITY:
  禁止事項:
    - ユーザーに API キーをチャットに入力させる
    - API キーを echo コマンドでファイルに書き込む
    - API キーを変数に格納する

  正しい手順:
    - ユーザーに .env.local ファイルを自分で作成させる
    - ファイル形式とキー名だけを教える
    - 「設定完了」の報告を待つ
```

#### API ルート

```typescript
// src/app/api/chat/route.ts
import { streamText } from 'ai';
import { google } from '@ai-sdk/google';

export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = streamText({
    model: google('gemini-1.5-flash'),
    messages,
  });

  return result.toDataStreamResponse();
}
```

#### チャット UI

```typescript
// src/app/page.tsx
'use client';

import { useChat } from 'ai/react';

export default function Chat() {
  const { messages, input, handleInputChange, handleSubmit, isLoading } = useChat();

  return (
    <div className="flex flex-col h-screen max-w-2xl mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">AI Chat Tutorial</h1>

      <div className="flex-1 overflow-y-auto space-y-4 mb-4">
        {messages.map((m) => (
          <div
            key={m.id}
            className={`p-3 rounded-lg ${
              m.role === 'user'
                ? 'bg-blue-100 ml-auto max-w-[80%]'
                : 'bg-gray-100 max-w-[80%]'
            }`}
          >
            <p className="text-sm font-semibold mb-1">
              {m.role === 'user' ? 'あなた' : 'AI'}
            </p>
            <p className="whitespace-pre-wrap">{m.content}</p>
          </div>
        ))}
        {isLoading && (
          <div className="bg-gray-100 p-3 rounded-lg max-w-[80%]">
            <p className="text-gray-500">考え中...</p>
          </div>
        )}
      </div>

      <form onSubmit={handleSubmit} className="flex gap-2">
        <input
          value={input}
          onChange={handleInputChange}
          placeholder="メッセージを入力..."
          className="flex-1 p-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
        <button
          type="submit"
          disabled={isLoading}
          className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 disabled:opacity-50"
        >
          送信
        </button>
      </form>
    </div>
  );
}
```

### 9.5 チュートリアル後の発展

```yaml
Level 1（チュートリアル）:
  構成: Next.js + AI SDK + Google AI
  環境変数: 1つ
  DB: なし
  認証: なし
  費用: 無料

Level 2（履歴保存）:
  追加: Neon（PostgreSQL）
  機能: チャット履歴をDBに保存
  参照: CATALOG.md セクション 6.4

Level 3（認証追加）:
  追加: Auth.js（NextAuth）
  機能: ユーザーログイン、個人履歴
  参照: CATALOG.md セクション 6.1

Level 4（本番品質）:
  構成: vercel-ai-chatbot
  機能: マルチモデル、ファイル添付、履歴管理
  参照: CATALOG.md セクション 5.12
  注意: セットアップ複雑、費用発生

チュートリアル → Level 4 へのスキップ:
  - 非推奨
  - まず Level 1-3 で段階的に学ぶ
  - 本番 AI チャットは Production Route を使用
```

### 9.6 よくある質問

```yaml
Q: 無料枠を超えたらどうなる?
A: 一時的に API がブロックされる。翌日にリセット。

Q: OpenAI（ChatGPT）に切り替えたい
A: |
  1. OpenAI API キーを取得（有料）
  2. pnpm add @ai-sdk/openai
  3. コード変更:
     import { openai } from '@ai-sdk/openai';
     model: openai('gpt-4o-mini')

Q: チュートリアル後にデプロイしたい
A: |
  Tutorial Route 完了後「本番開発したい」と言えば
  Production Route に移行可能。
  Vercel へのデプロイをガイドします。

Q: エラー「API key not valid」が出る
A: |
  1. .env.local のキーが正しいか確認
  2. pnpm dev を再起動
  3. Google AI Studio でキーが有効か確認
```

---

## 10. 公式ドキュメントリンク集

| カテゴリ | サービス | ドキュメント |
|----------|----------|--------------|
| 基盤 | Homebrew | https://docs.brew.sh/ |
| 基盤 | Node.js | https://nodejs.org/docs/ |
| 基盤 | pnpm | https://pnpm.io/motivation |
| AI | ChatGPT Codex | https://developers.openai.com/codex/ |
| AI | Context7 | https://github.com/upstash/context7 |
| AI | OpenRouter | https://openrouter.ai/docs |
| AI | Google AI | https://ai.google.dev/docs |
| AI | Vercel AI SDK | https://sdk.vercel.ai/docs |
| デプロイ | Vercel | https://vercel.com/docs |
| デプロイ | Cloudflare Pages | https://developers.cloudflare.com/pages/ |
| デプロイ | Cloudflare Workers | https://developers.cloudflare.com/workers/ |
| 補助 | ngrok | https://ngrok.com/docs |
| 補助 | GitHub CLI | https://cli.github.com/manual/ |
| SaaS | shadcn/ui | https://ui.shadcn.com/docs |
| SaaS | Stack Auth | https://docs.stack-auth.com/ |
| SaaS | Prisma | https://www.prisma.io/docs |
| SaaS | Neon | https://neon.tech/docs |
| SaaS | Resend | https://resend.com/docs |
| SaaS | Stripe | https://stripe.com/docs |

---

## 11. LLM セキュリティモード

> **Claude Code の権限制御を 3 段階で設定**
> **本番開発では Strict モードを推奨**

### 11.1 概要

```yaml
モード一覧:
  Strict:
    セキュリティ: 最高
    制御方法: hooks で危険コマンドをブロック
    用途: 本番環境、機密データを扱う開発

  Default:
    セキュリティ: 中
    制御方法: 特に設定しない（Claude Code デフォルト）
    用途: 一般的な開発、後から Strict に変更可能

  Trust:
    セキュリティ: 低
    制御方法: 全コマンドを許可
    用途: 信頼できる環境、学習目的、個人開発
```

### 11.2 モード比較

| 項目 | Strict | Default | Trust |
|------|--------|---------|-------|
| rm -rf | ブロック | 確認あり | 許可 |
| sudo | ブロック | 確認あり | 許可 |
| git push | ブロック | 確認あり | 許可 |
| git commit | ブロック | 確認あり | 許可 |
| curl/wget | ブロック | 許可 | 許可 |
| psql/mysql | ブロック | 確認あり | 許可 |
| ファイル編集 | 許可 | 許可 | 許可 |
| ファイル読み取り | 許可 | 許可 | 許可 |

### 11.3 Strict モード設定

#### settings.json

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Edit",
      "Write",
      "Bash(ls:*)",
      "Bash(cat:*)",
      "Bash(echo:*)",
      "Bash(pwd:*)",
      "Bash(cd:*)",
      "Bash(mkdir:*)",
      "Bash(cp:*)",
      "Bash(mv:*)",
      "Bash(node:*)",
      "Bash(npm:*)",
      "Bash(pnpm:*)",
      "Bash(npx:*)"
    ],
    "deny": [
      "Bash(sudo:*)",
      "Bash(rm:*)",
      "Bash(rmdir:*)",
      "Bash(curl:*)",
      "Bash(wget:*)",
      "Bash(nc:*)",
      "Bash(psql:*)",
      "Bash(mysql:*)",
      "Bash(mongod:*)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash(git*push*)",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/block-dangerous.sh git-push",
            "timeout": 5000
          }
        ]
      },
      {
        "matcher": "Bash(git*commit*)",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/block-dangerous.sh git-commit",
            "timeout": 5000
          }
        ]
      },
      {
        "matcher": "Bash(git*reset*)",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/block-dangerous.sh git-reset",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

#### block-dangerous.sh（hooks 用スクリプト）

```bash
#!/bin/bash
# .claude/hooks/block-dangerous.sh
# 危険なコマンドをブロックし、許可を求めるよう促す

COMMAND_TYPE="$1"

case "$COMMAND_TYPE" in
  "git-push")
    echo "🚫 BLOCKED: git push"
    echo ""
    echo "リモートへのプッシュには明示的な許可が必要です。"
    echo ""
    echo "【LLM へ】"
    echo "ユーザーに以下を確認してください:"
    echo "  1. プッシュ先ブランチ"
    echo "  2. プッシュする変更内容"
    echo "  3. 「プッシュしていい」という明示的な許可"
    echo ""
    echo "許可を得たら、ユーザーが settings.json から"
    echo "一時的に deny を解除してください。"
    exit 2
    ;;
  "git-commit")
    echo "🚫 BLOCKED: git commit"
    echo ""
    echo "コミット作成には明示的な許可が必要です。"
    echo ""
    echo "【LLM へ】"
    echo "ユーザーに以下を確認してください:"
    echo "  1. コミットする変更内容"
    echo "  2. コミットメッセージ"
    echo "  3. 「コミットしていい」という明示的な許可"
    exit 2
    ;;
  "git-reset")
    echo "🚫 BLOCKED: git reset"
    echo ""
    echo "⚠️ 危険: 履歴操作は取り消しできません。"
    echo ""
    echo "【LLM へ】"
    echo "この操作は本当に必要ですか？"
    echo "ユーザーに影響を説明し、明示的な許可を得てください。"
    exit 2
    ;;
  *)
    echo "🚫 BLOCKED: Unknown dangerous command"
    exit 2
    ;;
esac
```

### 11.4 Default モード設定

#### settings.json

```json
{
  "permissions": {
    "allow": [],
    "deny": []
  }
}
```

デフォルトでは Claude Code が各コマンドの実行時に確認を求めます。
ユーザーは都度許可/拒否を選択できます。

### 11.5 Trust モード設定

#### settings.json

```json
{
  "permissions": {
    "allow": [
      "Edit",
      "Write",
      "Bash(git:*)",
      "Bash(npm:*)",
      "Bash(chmod:*)",
      "Bash(mkdir:*)",
      "Bash(cp:*)",
      "Bash(mv:*)",
      "Bash(rm:*)",
      "Bash(cat:*)",
      "Bash(ls:*)",
      "Bash(tree:*)",
      "Bash(bash:*)",
      "Bash(node:*)",
      "Bash(pnpm:*)",
      "Bash(npx:*)",
      "Bash(curl:*)",
      "Bash(sudo:*)"
    ],
    "deny": []
  }
}
```

⚠️ **Trust モードのリスク**:
- LLM が誤って `rm -rf` を実行する可能性
- 意図しない `git push` で本番環境に影響
- API キーなどの機密情報が外部送信される可能性

**Trust モードを使う条件**:
- 開発者自身がコマンドを監視している
- 重要なデータがバックアップされている
- 学習目的で素早く試行錯誤したい

### 11.6 モード切り替え方法

```yaml
設定ファイルの場所:
  プロジェクト固有: .claude/settings.json
  ユーザー共通: ~/.claude/settings.json

優先順位:
  1. プロジェクト固有（.claude/settings.json）
  2. ユーザー共通（~/.claude/settings.json）

切り替え手順:
  1. 上記セクションから希望モードの settings.json をコピー
  2. .claude/settings.json に貼り付け
  3. Claude Code を再起動（または新しいセッション開始）

一時的に許可する場合:
  - deny リストから該当コマンドを削除
  - 作業完了後に deny リストに戻す
```

### 11.7 推奨モード

```yaml
チュートリアル（学習目的）:
  推奨: Trust
  理由: 素早く試行錯誤できる、リスクが低い（ローカルのみ）

本番開発（初期）:
  推奨: Default
  理由: 都度確認があるので安全、煩わしくなったら Strict へ

本番開発（慣れたら）:
  推奨: Strict
  理由: 事故防止、特に git push / DB 操作を保護

チーム開発:
  推奨: Strict
  理由: 他メンバーへの影響を防ぐ

機密データを扱う:
  推奨: Strict + カスタム deny
  理由: 情報漏洩防止
```

### 11.8 カスタム deny ルール例

```json
{
  "permissions": {
    "deny": [
      "Bash(rm:*)",
      "Bash(sudo:*)",
      "Bash(curl:*)",
      "Bash(wget:*)",
      "Bash(*supabase*db*)",
      "Bash(*prisma*migrate*)",
      "Bash(*DROP*)",
      "Bash(*DELETE*)",
      "Read(.env*)",
      "Read(*secret*)",
      "Read(*credential*)"
    ]
  }
}
```

**参考**: [Claude Code deny ルール解説](https://izanami.dev/post/d6f25eec-71aa-4746-8c0d-80c67a1459be)
