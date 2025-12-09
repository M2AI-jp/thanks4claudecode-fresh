# QUICKSTART

**5 分で Claude Code と開発を始める**

---

## 1. フォーク

```bash
# GitHub CLI でフォーク
gh repo fork amano--/dev-workspace --clone
cd dev-workspace

# または手動でフォーク後
git clone https://github.com/YOUR_USERNAME/dev-workspace.git
cd dev-workspace
```

---

## 2. Claude Code 起動

```bash
claude
```

自動的に案内が始まります。

---

## 3. 作りたいものを伝える

例：
- 「ChatGPT クローンを作りたい」
- 「ポートフォリオサイトを作りたい」
- 「課金付き SaaS を作りたい」

Claude Code が最適なテンプレートを選択し、環境構築からデプロイまで案内します。

---

## 必要なもの

| 項目 | 必須 | 備考 |
|------|------|------|
| Mac | Yes | macOS 12.0 以上 |
| Claude Code | Yes | [インストール](https://docs.anthropic.com/en/docs/claude-code) |
| GitHub アカウント | Yes | [作成](https://github.com/signup) |
| Vercel アカウント | Yes | [作成](https://vercel.com/signup)（GitHub 連携推奨） |
| OpenAI API キー | 任意 | AI 機能を使う場合 |

---

## トラブルシューティング

### Claude Code が起動しない

```bash
# Claude Code のインストール確認
claude --version

# 再インストール
npm install -g @anthropic-ai/claude-code
```

### Hook エラーが出る

```bash
# Hook に実行権限を付与
chmod +x .claude/hooks/*.sh
```

### state.md が壊れた

```bash
# 初期状態にリセット
git checkout -- state.md
```

---

## 次のステップ

- [README.md](README.md) - 詳細な説明
- [setup/playbook-setup.md](setup/playbook-setup.md) - セットアップフロー詳細
