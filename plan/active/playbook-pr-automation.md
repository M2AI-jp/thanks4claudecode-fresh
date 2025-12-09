# playbook-pr-automation.md

> **PR 作成・マージの自動化**
>
> project.md の milestone「PR 作成・マージの自動化」を達成する playbook

---

## meta

```yaml
project: thanks4claudecode
branch: feat/pr-automation
created: 2025-12-10
issue: null
derives_from: milestone-pr-automation
reviewed: false
```

---

## goal

```yaml
summary: |
  Phase 完了時の自動 PR 作成・マージフローを実装。
  ユーザーの手作業を排除し、playbook 完了 → PR 作成 → マージの一貫自動化を実現。

done_when:
  - playbook 完了時に GitHub API で PR が自動作成される
  - PR に正しい説明文（done_criteria を含む）が記載される
  - PR が自動的にマージ可能な状態に移行する
  - git log に自動マージコミットが記録される
  - check-coherence.sh が全て PASS する
```

---

## phases

```yaml
# Phase 1: 現状分析と設計
- id: p1
  name: 現状分析と設計
  goal: |
    PR 作成・マージフローの現状を分析し、
    GitHub CLI（gh）を用いた実装方法を設計する。
  executor: claudecode
  depends_on: []
  done_criteria:
    - docs/git-operations.md の「PR 作成・マージ」セクションを読んだ
    - CLAUDE.md の「POST_LOOP」セクションを読んだ
    - GitHub API vs gh CLI の比較表を作成した
    - 実装方針（gh CLI 使用）を決定した
    - 実装予定の Phase を列挙した
    - 実際に分析完了を確認済み（読了確認）
  test_method: |
    1. docs/git-operations.md を Read して内容を確認
    2. CLAUDE.md POST_LOOP を Read して処理フローを確認
    3. GitHub API と gh CLI の比較を実施
    4. 決定内容をテキストで出力
    5. 実装 Phase の列挙を確認
  status: pending

# Phase 2: PR 作成スクリプト実装
- id: p2
  name: PR 作成スクリプト実装
  goal: |
    Phase 完了時に自動的に PR を作成する Bash スクリプトを実装。
    gh CLI を使用して GitHub へ PR を送信する。
  executor: claudecode
  depends_on: [p1]
  done_criteria:
    - create-pr.sh が .claude/hooks/ に存在する
    - スクリプトが gh API で PR を作成する処理を含む
    - PR の説明文に done_criteria を含める仕様が実装されている
    - PR タイトルに playbook 名と phase 名を含める仕様が実装されている
    - エラーハンドリング（PR 既存の場合の対応）が実装されている
    - ShellCheck でエラーなしに通る
    - 実際に動作確認済み（test_method 実行）
  test_method: |
    1. ShellCheck を実行: shellcheck /path/to/create-pr.sh
    2. スクリプト内容をテキストで確認
    3. GitHub CLI の検証: gh --version で確認
    4. dry-run または test branch で動作確認
    5. PR オブジェクト構造の確認
  prerequisites:
    - gh CLI がインストール済み（brew install gh）
    - gh auth でログイン済み
    - main ブランチが push 済み
  status: pending

# Phase 3: PR 自動作成フック統合
- id: p3
  name: PR 自動作成フック統合
  goal: |
    POST_LOOP で create-pr.sh を自動呼び出しするフックを設定。
    CLAUDE.md と settings.json を更新。
  executor: claudecode
  depends_on: [p2]
  done_criteria:
    - create-pr-hook.sh が .claude/hooks/ に存在する
    - POST_LOOP で PR 作成が自動呼び出しされる
    - CLAUDE.md POST_LOOP セクションに「PR 作成」を記載
    - .claude/settings.json に hook 登録が追加される
    - settings.json の JSON 形式が正しい
    - check-coherence.sh が PASS する
    - 実際に動作確認済み（test_method 実行）
  test_method: |
    1. settings.json を JSON lint で検証
    2. hook スクリプトをテキストで確認
    3. CLAUDE.md 更新内容を視認確認
    4. test 環境で hook の呼び出し順序を確認
    5. git log で正しく記録されているか確認
  status: done

# Phase 4: マージ自動化スクリプト強化
- id: p4
  name: マージ自動化スクリプト強化
  goal: |
    既存の自動マージ処理（git merge）を拡張し、
    GitHub 上での PR ステータス確認とマージ実行を実装。
  executor: claudecode
  depends_on: [p3]
  done_criteria:
    - merge-pr.sh が .claude/hooks/ に存在する
    - PR のステータスを確認する処理を含む（draft → ready）
    - gh pr merge コマンドで自動マージを実行する処理を含む
    - マージコンフリクト検出とエラー通知を含む
    - マージコミットメッセージが CLAUDE.md に従っている
    - ShellCheck でエラーなしに通る
    - 実際に動作確認済み（test_method 実行）
  test_method: |
    1. ShellCheck を実行: shellcheck /path/to/merge-pr.sh
    2. gh pr merge --help で オプションを確認
    3. スクリプト内容をテキストで確認
    4. test ブランチで dry-run を実行
    5. git log でマージコミットが正しく記録されているか確認
  prerequisites:
    - PR が GitHub に作成済み
    - CI/CD チェック（GitHub Actions）が PASS（あれば）
  status: pending

# Phase 5: POST_LOOP 統合と CLAUDE.md 更新
- id: p5
  name: POST_LOOP 統合と CLAUDE.md 更新
  goal: |
    PR 作成・マージフローを POST_LOOP に組み込み、
    playbook 完了時の自動処理として実装。
  executor: claudecode
  depends_on: [p4]
  done_criteria:
    - CLAUDE.md の POST_LOOP セクションに PR 作成・マージフローを記載
    - 実行順序が明記されている（PR 作成 → PR マージ → 次タスク導出）
    - 各ステップの条件分岐を明記している（成功時・失敗時）
    - state.md と playbook との整合性を確認する処理を追加
    - CLAUDE.md の syntax が正しい（YAML/Markdown）
    - check-coherence.sh が PASS する
    - 実際に動作確認済み（test_method 実行）
  test_method: |
    1. CLAUDE.md を Markdown lint で検証
    2. POST_LOOP セクションを読んで内容を確認
    3. フロー図を描いて実行順序を確認
    4. test 環境で playbook をシミュレート実行
    5. 全 Phase の状態遷移を確認
  status: pending

# Phase 6: 統合テストと動作確認
- id: p6
  name: 統合テストと動作確認
  goal: |
    PR 作成・マージフロー全体の動作確認。
    実際の GitHub リポジトリで PR 生成・マージを検証。
  executor: claudecode
  depends_on: [p5]
  done_criteria:
    - test ブランチで playbook を完了させた
    - test ブランチから PR が自動作成された
    - PR が GitHub に表示されている
    - PR の説明文に done_criteria が含まれている
    - PR が自動的にマージされた
    - git log に自動マージコミットが記録されている
    - 次の playbook が自動導出されている
    - check-coherence.sh が PASS する
    - 実際に動作確認済み（test_method 実行）
  test_method: |
    1. test ブランチで playbook を作成
    2. すべての Phase を進行中に変更
    3. critic SubAgent を呼び出して PASS 取得
    4. playbook を done に変更
    5. GitHub にアクセスして PR が作成されているか確認
    6. git log でマージコミットを確認
    7. state.md が自動更新されているか確認
  prerequisites:
    - test ブランチが git で作成済み
    - GitHub リポジトリに push 権限がある
  status: pending

# Phase 7: ドキュメント更新とクリーンアップ
- id: p7
  name: ドキュメント更新とクリーンアップ
  goal: |
    PR 自動化機能の実装完了をドキュメントに反映。
    中間成果物がある場合は削除・統合。
  executor: claudecode
  depends_on: [p6]
  done_criteria:
    - docs/git-operations.md の「PR 作成・マージ」セクションを「実装済み」に更新
    - docs/current-implementation.md が自動更新されている
    - 実装関連のメモファイルが削除されている（temp-*.md など）
    - README.md に「PR 自動化」機能を追加
    - check-coherence.sh が PASS する
    - 実際に動作確認済み（test_method 実行）
  test_method: |
    1. docs/ フォルダのファイルを確認
    2. current-implementation.md に新規 Hook が記載されているか確認
    3. README.md を読んで機能説明が正確か確認
    4. test ブランチで git status を実行して stray file がないか確認
    5. check-coherence.sh を実行して整合性を確認
  status: pending
```

---

## 実装のポイント

### gh CLI の利用

```bash
# PR 作成
gh pr create --title "..." --body "..." --base main

# PR マージ
gh pr merge {pr-number} --merge --auto
```

### PR 説明文の自動生成

```markdown
## Summary
{playbook.goal.summary}

## Phases Completed
- p1: {done_criteria}
- p2: {done_criteria}
...

## Test
Verified with check-coherence.sh
```

### エラーハンドリング

- PR 既存: スキップまたは更新
- マージコンフリクト: 手動解決待機
- 権限なし: エラーログ出力

---

## 参考資料

- docs/git-operations.md
- CLAUDE.md POST_LOOP セクション
- GitHub CLI 公式ドキュメント: https://cli.github.com/

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-10 | 初版。phase 1-7 を定義。 |
