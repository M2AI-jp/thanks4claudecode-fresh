# Git Operations Reference

git 操作の標準手順を定義する参照ドキュメントです。

> **設計方針**: git 操作は Claude が CLAUDE.md の指示に従って直接実行します。
> SubAgent 呼び出しではなく、bash コマンドの直接実行による自動化です。

---

## 実行方式

```yaml
方式: Claude 直接実行（Bash ツール使用）
トリガー: CLAUDE.md の LOOP / POST_LOOP セクション
参照: このファイルはコマンド例・エラーハンドリングの参照用
```

---

## トリガー条件

```yaml
auto_commit:
  条件: Phase が done になったとき
  発火: critic PASS 後、state.md 更新後
  action: git add -A && git commit

auto_merge:
  条件: playbook の全 Phase が done
  発火: POST_LOOP の冒頭
  action: git checkout main && git merge {branch}

auto_branch:
  条件: 新タスク開始時（pm から呼び出し）
  発火: /task-start 実行時
  action: git checkout -b feat/{task-name}
```

---

## 責務

### 1. 自動コミット（Phase 完了時）

```yaml
トリガー: Phase.status が done に変更された
前提条件:
  - critic PASS 済み
  - state.md 更新済み
  - 未コミット変更がある

実行内容:
  1. git status で変更を確認
  2. 変更がなければスキップ
  3. 変更があれば:
     - git add -A
     - git commit -m "{Phase 名} 完了 - {playbook 名}"
     - コミットメッセージに Phase の summary を含める

コミットメッセージ形式:
  feat({phase}): {summary}

  - {done_criteria 1}
  - {done_criteria 2}
  ...

  critic: PASS
  playbook: {playbook_path}

  🤖 Generated with [Claude Code](https://claude.com/claude-code)

  Co-Authored-By: Claude <noreply@anthropic.com>
```

### 2. PR 作成・マージ（playbook 完了時）★実装済み

```yaml
トリガー: playbook の全 Phase が done
前提条件:
  - 全 Phase critic PASS
  - 未コミット変更がない（自動コミット済み）
  - リモートに push 済み

実行内容（自動化）:
  1. create-pr-hook.sh が PostToolUse:Edit で自動発火
  2. create-pr.sh で GitHub に PR を作成
  3. merge-pr.sh で PR をマージ（gh pr merge --auto）
  4. ローカルブランチを main に同期

スクリプト:
  - .claude/hooks/create-pr-hook.sh（PR 作成フック）
  - .claude/hooks/create-pr.sh（PR 作成本体）
  - .claude/hooks/merge-pr.sh（PR マージ）

PR タイトル形式:
  feat({playbook}/{phase}): {goal summary}

PR 本文形式:
  ## Summary
  {playbook.goal.summary}

  ## Done When (Playbook Goal)
  - {done_when 1}
  - {done_when 2}

  ## Done Criteria (Current Phase)
  - {criteria 1}
  - {criteria 2}

マージオプション:
  gh pr merge --merge --auto --delete-branch

条件分岐:
  - Draft PR: エラー（gh pr ready で解除を促す）
  - コンフリクト: エラー（手動解決を促す）
  - 必須チェック未完了: --auto で待機
```

### 3. 自動ブランチ作成（新タスク開始時）

```yaml
トリガー: pm SubAgent 経由（/task-start）
前提条件:
  - 現在 main ブランチにいる、または main からの分岐
  - 未コミット変更がない

実行内容:
  1. 現在のブランチを確認
  2. main でなければ main に切り替え
  3. git checkout -b feat/{task-name}
  4. ブランチ作成を確認

ブランチ名規則:
  - 新機能: feat/{task-name}
  - バグ修正: fix/{task-name}
  - リファクタリング: refactor/{task-name}
  - ドキュメント: docs/{task-name}
```

---

## pm SubAgent との連携

```yaml
タスク開始フロー:
  1. ユーザーが /task-start を実行
  2. pm がユーザー要求を分析
  3. pm がブランチ作成を実行
  4. pm が playbook を作成
  5. pm が state.md を更新

Phase 完了フロー:
  1. Claude が Phase の作業を完了
  2. critic が PASS を返す
  3. Claude が state.md を更新
  4. Claude が自動コミットを実行

playbook 完了フロー:
  1. 最終 Phase が done
  2. POST_LOOP が発動
  3. Claude が自動マージを実行
  4. pm を呼び出して次タスク導出
```

---

## コマンド実行例

### 自動コミット

```bash
# Phase 完了時のコミット
git add -A && git commit -m "$(cat <<'EOF'
feat(phase-1): タスク開始プロセス標準化 完了

- pm SubAgent がユーザー要求を分析して playbook を生成
- /task-start コマンドが pm 経由でタスクを開始
- CLAUDE.md の INIT/POST_LOOP が pm 経由を強制
- タスク開始フロー図が作成

critic: PASS
playbook: plan/playbook-system-completion.md

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### 自動マージ

```bash
# playbook 完了時のマージ
git checkout main && \
git merge feat/system-completion --no-edit
```

### 自動ブランチ作成

```bash
# 新タスク開始時のブランチ作成
git checkout main && \
git checkout -b feat/{new-task-name}
```

---

## エラーハンドリング

```yaml
未コミット変更がある状態でのブランチ切り替え:
  対応: stash または commit を促す
  message: "未コミット変更があります。先にコミットしてください。"

マージコンフリクト:
  対応: 手動解決を促す
  message: "マージコンフリクトが発生しました。手動で解決してください。"

リモートとの差分:
  対応: pull を促す
  message: "リモートに新しいコミットがあります。git pull を実行してください。"
```

---

## 設定

```yaml
auto_push: false          # 自動 push は無効（安全のため）
commit_on_phase: true     # Phase 完了時の自動コミット
merge_on_playbook: true   # playbook 完了時の自動マージ
branch_on_task: true      # 新タスク開始時の自動ブランチ
```

---

## 参照ファイル

- .claude/agents/pm.md - pm SubAgent（タスク開始の必須経由点）
- CLAUDE.md - POST_LOOP セクション
- state.md - 現在の Phase 状態

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-10 | PR 作成・マージ自動化を「実装済み」に更新。create-pr.sh, merge-pr.sh 追加。 |
| 2025-12-09 | docs/ へ移動（SubAgent から参照ドキュメントへ変更）。 |
| 2025-12-09 | 初版作成。git 自動化参照ドキュメント。 |
