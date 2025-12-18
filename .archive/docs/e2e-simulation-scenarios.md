# E2E シミュレーションシナリオ

> **目的**: 架空ユーザーとの会話形式で全機能の動作を確認
> **テスト対象**: 全 Hook / SubAgent / Skill

---

## テスト対象一覧

### Hooks (32個中 主要20件)

| # | Hook | トリガー | テストシナリオ |
|---|------|----------|---------------|
| 1 | session-start.sh | SessionStart | Scenario 1 |
| 2 | init-guard.sh | PreToolUse:* | Scenario 1, 2 |
| 3 | playbook-guard.sh | PreToolUse:Edit/Write | Scenario 2, 3 |
| 4 | consent-guard.sh | PreToolUse:Edit/Write | Scenario 3 |
| 5 | check-coherence.sh | SessionStart | Scenario 1 |
| 6 | archive-playbook.sh | PostToolUse:Edit | Scenario 8 |
| 7 | subtask-guard.sh | PreToolUse:Edit | Scenario 4 |
| 8 | critic-guard.sh | PreToolUse:* | Scenario 5 |
| 9 | executor-guard.sh | PreToolUse:Bash | Scenario 6 |
| 10 | cleanup-hook.sh | PostToolUse | Scenario 8 |
| 11 | create-pr.sh | PostToolUse | Scenario 9 |
| 12 | check-protected-edit.sh | PreToolUse:Edit | Scenario 3 |
| 13 | done-when-validator.sh | PreToolUse:Edit | Scenario 4 |
| 14 | generate-repository-map.sh | Manual | Scenario 10 |
| 15 | failure-logger.sh | Error | Scenario 7 |
| 16 | state-schema.sh | Source | Scenario 1 |
| 17 | check-main-branch.sh | PreToolUse:Bash | Scenario 2 |
| 18 | depends-check.sh | PreToolUse | Scenario 4 |
| 19 | doc-freshness-check.sh | PostToolUse | Scenario 10 |
| 20 | stop-summary.sh | Stop | Scenario 11 |

### SubAgents (7個 全て)

| # | SubAgent | 役割 | テストシナリオ |
|---|----------|------|---------------|
| 1 | pm | playbook 作成・管理 | Scenario 2 |
| 2 | critic | done_criteria 検証 | Scenario 5 |
| 3 | reviewer | playbook レビュー | Scenario 6 |
| 4 | plan-guard | 計画整合性チェック | Scenario 2 |
| 5 | health-checker | システム健全性確認 | Scenario 7 |
| 6 | codex-delegate | Codex CLI 呼び出し | Scenario 6 |
| 7 | setup-guide | セットアップガイド | Scenario 12 |

### Skills (7個)

| # | Skill | 役割 | テストシナリオ |
|---|-------|------|---------------|
| 1 | consent-process | 合意プロセス | Scenario 3 |
| 2 | post-loop | playbook 完了処理 | Scenario 8 |
| 3 | context-management | コンテキスト管理 | Scenario 11 |
| 4 | plan-management | 計画管理 | Scenario 2 |
| 5 | state | state.md 管理 | Scenario 1 |
| 6 | lint-checker | 静的解析 | Scenario 4 |
| 7 | test-runner | テスト実行 | Scenario 5 |

---

## シナリオ定義

### Scenario 1: セッション開始（SessionStart Hook 群）

**架空ユーザー**: 「こんにちは、作業を始めたいです」

**期待される動作**:
1. Hook: session-start.sh が発火
2. Hook: check-coherence.sh が state.md と playbook の整合性を確認
3. Hook: init-guard.sh が必須ファイル Read を強制
4. Skill: state が参照される
5. Hook: state-schema.sh が source される

**検証ポイント**:
- `[自認]` ブロックが出力される
- state.md の情報が正しく表示される
- playbook.active が認識される

---

### Scenario 2: playbook 作成（pm SubAgent）

**架空ユーザー**: 「新しいタスクを始めたい。ログイン機能を追加して」

**期待される動作**:
1. Hook: playbook-guard.sh が playbook=null を検出
2. SubAgent: pm が呼び出される
3. SubAgent: plan-guard が計画整合性を確認
4. Skill: plan-management が適用される
5. Hook: check-main-branch.sh が main ブランチを検出
6. git checkout -b で新ブランチ作成

**検証ポイント**:
- pm が playbook を作成
- derives_from が milestone に紐付く
- ブランチが作成される

---

### Scenario 3: Edit ガード（合意プロセス）

**架空ユーザー**: 「src/auth.ts を編集して」

**期待される動作**:
1. Hook: playbook-guard.sh が playbook 存在を確認
2. Skill: consent-process が適用される
3. `[理解確認]` ブロックが出力される
4. Hook: consent-guard.sh が consent ファイルを確認
5. Hook: check-protected-edit.sh が保護ファイルをチェック

**検証ポイント**:
- `[理解確認]` に what/why/how/scope/exclusions/risks が含まれる
- ユーザー承認後に Edit が許可される

---

### Scenario 4: subtask 完了と検証

**架空ユーザー**: 「p1.1 の subtask を完了としてマークして」

**期待される動作**:
1. Hook: subtask-guard.sh が subtask 変更を検出
2. Hook: depends-check.sh が依存関係を確認
3. Hook: done-when-validator.sh が done_when を検証
4. Skill: lint-checker が適用される
5. `- [ ]` → `- [x]` に変更

**検証ポイント**:
- validations が記録される
- validated タイムスタンプが追加される

---

### Scenario 5: critic による検証

**架空ユーザー**: 「Phase が完了したか確認して」

**期待される動作**:
1. Hook: critic-guard.sh が critic 呼び出しを検出
2. SubAgent: critic が done_criteria を検証
3. Skill: test-runner が test_command を実行
4. PASS/FAIL が返される

**検証ポイント**:
- technical/consistency/completeness の 3 検証が実行される
- PASS の場合のみ phase.status = done

---

### Scenario 6: executor 制御（Toolstack）

**架空ユーザー**: 「Codex でコードを実装して」

**期待される動作**:
1. Hook: executor-guard.sh が toolstack を確認
2. state.md の config.toolstack を参照
3. toolstack=A なら Codex ブロック、B/C なら許可
4. SubAgent: codex-delegate が呼び出される（B/C の場合）
5. SubAgent: reviewer がコードレビュー（C の場合）

**検証ポイント**:
- toolstack 設定に応じた制御が機能する

---

### Scenario 7: エラーハンドリング

**架空ユーザー**: 「エラーが発生した」

**期待される動作**:
1. Hook: failure-logger.sh がエラーを記録
2. SubAgent: health-checker がシステム状態を確認
3. .claude/logs/failures.log に記録される

**検証ポイント**:
- 失敗パターンが学習される
- 次回セッションで警告表示

---

### Scenario 8: playbook 完了とアーカイブ

**架空ユーザー**: 「playbook の全 Phase が完了した」

**期待される動作**:
1. Hook: archive-playbook.sh が全 Phase done を検出
2. V12 チェックボックス形式で完了率を確認
3. Skill: post-loop が適用される
4. Hook: cleanup-hook.sh が tmp/ をクリーン
5. アーカイブ提案が出力される

**検証ポイント**:
- `- [x]` の完了率が 100%
- /clear 推奨がアナウンスされる

---

### Scenario 9: PR 作成

**架空ユーザー**: 「PR を作成して」

**期待される動作**:
1. Hook: create-pr.sh が呼び出される
2. gh pr create が実行される
3. PR URL が返される

**検証ポイント**:
- PR テンプレートが適用される
- レビュアーが自動設定される

---

### Scenario 10: ドキュメント更新

**架空ユーザー**: 「repository-map を更新して」

**期待される動作**:
1. Hook: generate-repository-map.sh が実行される
2. Hook: doc-freshness-check.sh がドキュメント鮮度を確認
3. repository-map.yaml が更新される

**検証ポイント**:
- 冪等性が保証される（2回実行しても同じ結果）

---

### Scenario 11: セッション終了

**架空ユーザー**: 「/clear を実行」

**期待される動作**:
1. Hook: stop-summary.sh がサマリーを出力
2. Skill: context-management が適用される
3. state.md の session.last_clear が更新される

**検証ポイント**:
- 作業サマリーが出力される
- 次回セッションで resume 可能

---

### Scenario 12: 新規セットアップ

**架空ユーザー**: 「新しいプロジェクトをセットアップしたい」

**期待される動作**:
1. SubAgent: setup-guide が呼び出される
2. setup/playbook-setup.md が参照される
3. toolstack 選択が求められる

**検証ポイント**:
- state.md が初期化される
- project.md が作成される

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-17 | 初版作成。12 シナリオ、20 Hook、7 SubAgent、7 Skill をカバー。 |
