---
name: deploy-checker
description: デプロイ準備・検証専門スキル。git push 前の最終確認、環境変数チェック、ビルドチェック、セキュリティチェックを実行する。
---

# deploy-checker

> **デプロイ準備・検証専門スキル**

---

## 役割

デプロイ前の最終チェックを行い、本番環境で問題が起きないことを確認する。

---

## 発火条件（確定的パターン）

このスキルは以下の場合に**必ず**実行される：

```yaml
トリガー:
  - git push 前の最終確認
  - ユーザーが「デプロイして」「公開して」と言った場合
  - done_criteria に「デプロイ」が含まれる場合
```

---

## チェック項目

```yaml
1. 環境変数チェック:
   - .env.example と .env.local の整合性
   - 必須環境変数の存在確認
   - 本番用環境変数の設定確認

2. ビルドチェック:
   - pnpm build が成功するか
   - ビルドサイズが適切か（< 1MB）
   - 警告がないか

3. セキュリティチェック:
   - API キーが .gitignore されているか
   - ハードコードされた秘密情報がないか
   - CORS 設定が適切か

4. デプロイ先チェック:
   - Vercel プロジェクトが存在するか
   - Git リポジトリが連携されているか
   - デプロイ設定が正しいか
```

---

## 実行手順

```bash
# 1. 環境変数チェック
echo "=== Environment Variables ===" && \
[ -f .env.example ] && echo "✓ .env.example exists" || echo "✗ .env.example missing"

# 2. ビルドチェック
echo "=== Build Check ===" && pnpm build

# 3. セキュリティチェック
echo "=== Security Check ===" && \
git ls-files | grep -E '\.(env|key|pem)$' && echo "✗ Secret files found" || echo "✓ No secret files"

# 4. Git 状態確認
echo "=== Git Status ===" && \
git status --short && \
git log --oneline -5
```

---

## 出力形式

```
=== Deploy Checker Results ===

[Environment Variables]
✓ .env.example exists
✓ All required vars present:
  - DATABASE_URL
  - OPENAI_API_KEY
  - NEXTAUTH_SECRET

[Build]
✓ Build successful (3.2s)
✓ Bundle size: 847 KB
⚠ 1 warning: 'console.log' found in production code

[Security]
✓ No secret files in Git
✓ .gitignore properly configured
✓ No hardcoded API keys found

[Deploy Target]
✓ Vercel project linked
✓ Git remote configured
✓ Auto-deploy enabled

=== Summary ===
Status: READY (1 warning)
Recommendation: Remove console.log before deploy
```

---

## デプロイ手順

```yaml
準備完了後:
  1. git add .
  2. git commit -m "feat: ..."
  3. git push
  4. Vercel が自動デプロイ開始
  5. デプロイ URL を確認
  6. 本番環境で動作確認

警告がある場合:
  - 修正してから push
  - または、警告内容を確認して判断
```

---

## 使用例

### CLAUDE.md への統合（確定的発火）

```markdown
## デプロイ前の必須事項

- git push 前は、必ず `deploy-checker` スキルを実行すること
- done_criteria に「デプロイ」が含まれる場合は、必ず `deploy-checker` スキルで検証すること
```

この記載により、LLM はデプロイ前に自動的にこのスキルを呼び出す。

---

## トラブルシューティング

```yaml
よくある問題:

Build failed:
  原因: 型エラー、import 漏れ
  対応: pnpm tsc --noEmit で確認

Environment variable missing:
  原因: .env.local の設定漏れ
  対応: .env.example を参考に設定

Vercel deployment failed:
  原因: 環境変数が Vercel に未設定
  対応: Vercel Dashboard で設定

API not working in production:
  原因: CORS、環境変数、API route 設定
  対応: ログを確認し、設定を修正
```

---

## 設定ファイル

```yaml
必要なファイル:
  - .env.example: 環境変数テンプレート
  - .gitignore: 秘密情報除外設定
  - vercel.json: Vercel 設定（オプション）

推奨設定:
  - Auto-deploy: main ブランチのみ
  - Preview deploy: 全ブランチ
  - Environment: Production/Preview 分離
```
