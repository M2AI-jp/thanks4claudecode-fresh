# Operations Rules

> **運用規約とデプロイ手順**

---

## Git ワークフロー

```yaml
git:
  main_branch: main
  protection:
    - main への直接コミット禁止
    - PR 必須
    - レビュー必須

  branch_naming:
    feat: 新機能
    fix: バグ修正
    refactor: リファクタリング
    docs: ドキュメント
    test: テスト追加

  commit_message:
    format: "{type}({scope}): {description}"
    footer: "Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## playbook 運用

```yaml
playbook:
  lifecycle:
    1: playbook-init で作成
    2: reviewer で検証
    3: phase ごとに実行
    4: critic で完了検証
    5: アーカイブ

  rules:
    - 1 playbook = 1 ブランチ
    - phase 順序を守る
    - done_criteria を満たすまで完了しない
```

---

## デプロイ

```yaml
deploy:
  pre_check:
    - lint pass
    - test pass
    - build success
    - security scan

  flow:
    1: PR 作成
    2: CI 通過
    3: レビュー承認
    4: main マージ
    5: 自動デプロイ
```

---

## 監視

```yaml
monitoring:
  logs:
    format: JSON
    levels: [error, warn, info, debug]
    retention: 30日

  metrics:
    - Hook 実行時間
    - BLOCK 発生率
    - テスト成功率

  alerts:
    - Hook タイムアウト連続発生
    - テスト失敗率上昇
    - セキュリティ違反
```

---

## インシデント対応

```yaml
incident:
  severity:
    critical: サービス停止
    major: 機能障害
    minor: 軽微な問題

  response:
    1: 状況確認
    2: 影響範囲特定
    3: 一次対応
    4: 根本原因分析
    5: 再発防止策
```

---

## ロールバック

```yaml
rollback:
  commands:
    soft: git reset --soft HEAD~1
    mixed: git reset HEAD~1
    hard: git reset --hard HEAD~1
    revert: git revert HEAD

  when:
    - デプロイ後の重大バグ
    - パフォーマンス劣化
    - セキュリティ問題

  reference: .claude/commands/rollback.md
```
