# LLM Workspace Template

**Claude Code と一緒に開発を始めるためのテンプレート。**

---

## Getting Started

### 前提条件

- Mac（macOS 12.0 以上）
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) がインストール済み

### 1. フォーク

GitHub の「Fork」ボタンをクリック、または:

```bash
gh repo fork amano--/dev-workspace --clone
cd dev-workspace
```

### 2. Claude Code を起動

```bash
claude
```

### 3. 案内に従う

Claude Code が自動的に案内を始めます。「何を作りたいか」を伝えるだけで、環境構築から開発まで一緒に進められます。

**できること**:
- ChatGPT クローン / AI チャット
- ポートフォリオサイト
- SaaS（課金付き）
- Web アプリ
- 自動化スクリプト

---

## 動作の仕組み

```
フォーク → Claude Code 起動 → ヒアリング → 環境構築 → 開発開始
```

1. Claude Code が起動時に自動で案内を開始
2. 「何を作りたいか」を聞いてカテゴリを判定
3. 必要なアカウント作成をガイド（GitHub, Vercel 等）
4. 開発環境を自動構築
5. テンプレートからプロジェクト作成
6. デプロイまでサポート

---

## よくある質問

**Q: プログラミング初心者でも使えますか？**

A: はい。Claude Code が一つずつ案内します。「チュートリアル」モードなら 10 分で AI チャットが動きます。

**Q: 費用はかかりますか？**

A: 基本的に無料です。ただし OpenAI API など一部サービスは従量課金が発生します。事前に説明があります。

**Q: Windows / Linux でも使えますか？**

A: 現在は Mac のみ対応しています。

---

## ファイル構成（参考）

```
.
├── CLAUDE.md               # LLM への指示（最優先）
├── state.md                # 現在の状態（Single Source of Truth）
├── architecture-*.md       # システム設計図（Mermaid）
├── setup/                  # セットアップガイド
│   ├── playbook-setup.md   # 環境構築フロー（Phase 0-8）
│   └── CATALOG.md          # 技術詳細リファレンス
├── plan/                   # 計画関連
│   ├── project.md          # Macro 計画（最終目標）
│   ├── template/           # playbook/project テンプレート
│   └── active/             # 現在進行中の playbook
└── .claude/                # Claude Code 拡張
    ├── hooks/              # 自動実行スクリプト
    ├── agents/             # サブエージェント定義
    ├── skills/             # 専門知識（デプロイ、テスト等）
    └── commands/           # カスタムコマンド
```

詳細は [CLAUDE.md](CLAUDE.md) と [architecture-plan.md](architecture-plan.md) を参照してください。
