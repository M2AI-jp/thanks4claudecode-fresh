# PR 自動化設計ドキュメント

> **playbook-pr-automation Phase 1 の成果物**

---

## 1. 現状分析

### 1.1 既存の git 自動化（docs/git-operations.md より）

| 機能 | 実装状況 | トリガー |
|------|----------|----------|
| 自動コミット | ✅ 実装済み | Phase 完了時（critic PASS 後） |
| 自動マージ | ✅ 実装済み | playbook 完了時（ローカル git merge） |
| 自動ブランチ | ✅ 実装済み | 新タスク開始時（pm 経由） |
| **PR 作成** | ❌ 未実装 | - |
| **PR マージ** | ❌ 未実装 | - |

### 1.2 POST_LOOP の現状（.claude/skills/post-loop/skill.md より）

```yaml
現在のフロー:
  1. 自動コミット（最終 Phase 分）
  2. playbook アーカイブ
  3. 自動マージ（git merge --no-edit）
  4. project.done_when 更新
  5. 次タスク導出（pm 経由）

不足:
  - GitHub 上での PR 作成
  - GitHub 上での PR マージ
  - リモートとの同期
```

---

## 2. GitHub API vs gh CLI 比較表

| 項目 | GitHub REST API | gh CLI |
|------|-----------------|--------|
| **認証方式** | Personal Access Token（手動生成・管理） | `gh auth login`（対話式、キーチェーン保存） |
| **インストール** | 不要（curl 使用） | `brew install gh`（Mac） |
| **学習曲線** | 高（REST API 仕様習得、JSON パース） | 低（Bash コマンド相当） |
| **PR 作成** | `curl -X POST /repos/{owner}/{repo}/pulls` | `gh pr create --title "..." --body "..."` |
| **PR マージ** | `curl -X PUT /repos/{owner}/{repo}/pulls/{n}/merge` | `gh pr merge --merge` |
| **エラーハンドリング** | JSON レスポンスのパース必要 | exit code + 人間可読メッセージ |
| **依存** | curl, jq | gh のみ |
| **CI/CD 統合** | 標準対応 | 標準対応 |
| **推奨用途** | プログラム的な複雑処理 | Bash スクリプト、自動化 |

---

## 3. 実装方針決定

### 採用: gh CLI

### 決定根拠

1. **認証済み確認**
   ```
   $ gh auth status
   ✓ Logged in to github.com account M2AI-jp (keyring)
   - Token scopes: admin:repo, repo, workflow, ...
   ```

2. **技術スタック適合**
   - このリポジトリは Bash/Shell ベース（project.md tech_decisions より）
   - gh CLI は Bash スクリプトから直接呼び出し可能

3. **エラーハンドリングの容易さ**
   - exit code で成功/失敗を判定可能
   - `set -e` と組み合わせて安全なスクリプトを構築可能

4. **ShellCheck 対応**
   - gh コマンドは標準的な Bash 構文で呼び出し可能
   - lint-checker Skill で検証可能

### 代替案の却下理由

- **GitHub REST API**: JSON パースが必要で複雑。curl + jq の依存が増える。
- **GitHub GraphQL API**: さらに複雑。このユースケースには過剰。
- **GitHub Actions**: ローカル自動化には不向き。CI/CD 専用。

---

## 4. 実装予定 Phase

| Phase | 名前 | 目標 | 前提条件 |
|-------|------|------|----------|
| p2 | PR 作成スクリプト実装 | create-pr.sh を作成 | gh CLI インストール済み |
| p3 | PR 自動作成フック統合 | POST_LOOP に統合 | p2 完了 |
| p4 | マージ自動化スクリプト強化 | merge-pr.sh を作成 | p3 完了 |
| p5 | POST_LOOP 統合 | CLAUDE.md 更新 | p4 完了 |
| p6 | 統合テスト | 実際の GitHub で検証 | p5 完了 |
| p7 | ドキュメント更新 | current-implementation.md 更新 | p6 完了 |

### 前提条件の確認

```yaml
gh CLI:
  version: 2.74.2
  status: installed
  auth: logged in (M2AI-jp)

GitHub repo:
  name: thanks4claudecode
  remote: origin (https)
  permissions: admin:repo, repo, workflow
```

### リスク評価

| リスク | 影響 | 対策 |
|--------|------|------|
| gh CLI 未インストール環境 | 高 | prerequisites で事前チェック |
| 認証トークン期限切れ | 中 | `gh auth status` で事前確認 |
| PR コンフリクト | 中 | エラーハンドリングで手動解決を促す |
| ネットワーク障害 | 低 | リトライ処理（3回まで） |

---

## 5. 設計図

```
playbook 完了
    │
    ├─→ 自動コミット（既存）
    │
    ├─→ playbook アーカイブ（既存）
    │
    ├─→ 【新規】create-pr.sh
    │       └─→ gh pr create --title "..." --body "..."
    │
    ├─→ 【新規】merge-pr.sh
    │       └─→ gh pr merge --merge
    │
    ├─→ 自動マージ（既存、バックアップ用）
    │
    └─→ 次タスク導出（既存、pm 経由）
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-10 | Phase 1 成果物として作成 |
