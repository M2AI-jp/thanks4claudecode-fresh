# regression-targets.md

> **回帰テスト対象リスト**

---

## Hooks（14件）

| ファイル | 機能 | テスト方法 |
|----------|------|-----------|
| session-start.sh | セッション開始時の初期化 | 直接実行、出力確認 |
| session-end.sh | セッション終了時のクリーンアップ | 直接実行、出力確認 |
| init-guard.sh | 必須 Read 完了まで他ツールをブロック | stdin 経由でテスト |
| pre-bash-check.sh | Bash 実行前の保護チェック | stdin 経由でテスト |
| coherence.sh | state/playbook/branch 整合性 | 直接実行、exit code 確認 |
| check-protected-edit.sh | 保護ファイル編集ブロック | stdin 経由でテスト |
| check-main-branch.sh | main ブランチ作業禁止 | 直接実行、exit code 確認 |
| check-playbook-quality.sh | playbook 品質チェック | 直接実行、exit code 確認 |
| check-file-dependencies.sh | ファイル依存チェック | 直接実行、exit code 確認 |
| check-manifest-sync.sh | マニフェスト同期チェック | 直接実行、exit code 確認 |
| critic-guard.sh | critic 呼び出し強制 | stdin 経由でテスト |
| playbook-guard.sh | playbook ガード | stdin 経由でテスト |
| log-subagent.sh | SubAgent ログ記録 | 直接実行、ログ確認 |

---

## Agents（7件）

| ファイル | 機能 | テスト方法 |
|----------|------|-----------|
| critic.md | done_criteria 評価 | Task 呼び出し |
| coherence.md | 整合性チェック | Task 呼び出し |
| pm.md | playbook 管理 | Task 呼び出し |
| state-mgr.md | state.md 管理 | Task 呼び出し |
| plan-guard.md | 計画ガード | Task 呼び出し |
| setup-guide.md | セットアップガイド | Task 呼び出し |
| beginner-advisor.md | 初心者アドバイス | Task 呼び出し |

---

## Commands（4件）

| ファイル | 機能 | テスト方法 |
|----------|------|-----------|
| crit.md | /crit コマンド | コマンド実行 |
| lint.md | /lint コマンド | コマンド実行 |
| playbook-init.md | /playbook-init コマンド | コマンド実行 |
| test.md | /test コマンド | コマンド実行 |

---

## テスト優先度

### 高優先度（コア機能）

```yaml
必須テスト:
  - session-start.sh: セッション開始が正常に動作
  - coherence.sh: 整合性チェックが機能
  - pre-bash-check.sh: 保護チェックが機能
  - init-guard.sh: 初期化ガードが機能
  - critic.md: critic が呼び出せる
```

### 中優先度（品質保証）

```yaml
推奨テスト:
  - check-protected-edit.sh
  - playbook-guard.sh
  - coherence.md
  - pm.md
```

### 低優先度（補助機能）

```yaml
任意テスト:
  - log-subagent.sh
  - check-manifest-sync.sh
  - beginner-advisor.md
  - Commands 全般
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | 初版作成。Issue #9 p1。 |
