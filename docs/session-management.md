# session-management.md

> **M023: セッション管理ガイド - Named Sessions と Plan Mode の活用**

---

## Named Sessions

### /rename - セッション名の設定

```yaml
用途:
  - セッションに意味のある名前を付ける
  - 後から /resume で再開しやすくする

構文: /rename {session-name}

例:
  /rename m023-plan-mode-guide
  /rename bugfix-init-guard
  /rename feature-auth-system

命名規則:
  - 小文字のケバブケース（kebab-case）
  - milestone ID を含めると追跡しやすい
  - 作業内容を端的に表す
```

### /resume - セッションの再開

```yaml
用途:
  - 中断したセッションを再開
  - 名前付きセッションに戻る

構文: /resume {session-name}

例:
  /resume m023-plan-mode-guide
  /resume bugfix-init-guard

注意:
  - 再開時は INIT から実行される
  - state.md を読んで現在地を把握
  - playbook がある場合は続きから作業
```

---

## Plan Mode

### think - 思考深化

```yaml
トリガー: ユーザーメッセージに「think」を含める

効果:
  - 通常より深く考え、複数の選択肢を検討
  - 設計判断、トレードオフ分析に有効

例:
  「この設計でいいか think」
  「エラーハンドリングの方針を think」
```

### ultrathink - 最大深度思考

```yaml
トリガー: ユーザーメッセージに「ultrathink」を含める

効果:
  - 最大限の思考深度で分析
  - 報酬詐欺の自己検証を含む
  - 長期的影響を考慮

例:
  「アーキテクチャを ultrathink」
  「根本原因を ultrathink」
  「全部やり直して ultrathink」

特徴:
  - 複数の選択肢を列挙
  - 各メリット・デメリットを分析
  - 最終的な推奨案を根拠と共に提示
```

---

## ベストプラクティス

### セッション開始時

```yaml
1. /rename で意味のある名前を付ける
2. state.md と playbook を確認
3. [自認] で現在地を宣言
```

### 複雑なタスク時

```yaml
1. 「ultrathink」で深い分析を要求
2. 複数の選択肢を比較
3. 決定後に playbook を作成
```

### セッション中断時

```yaml
1. state.md が最新であることを確認
2. 作業途中なら playbook に進捗を記録
3. /rename で名前が付いていることを確認
4. 次回 /resume で再開
```

### playbook 完了時

```yaml
1. /clear でコンテキストをリフレッシュ
2. 新しいセッションで次の milestone へ
3. 必要に応じて /rename で新しい名前を設定
```

---

## トラブルシューティング

### セッションが見つからない

```yaml
原因: /rename していない、または名前を忘れた
対処:
  1. 新しいセッションを開始
  2. state.md を読んで現在地を把握
  3. playbook があれば続きから作業
```

### 再開後に状態がずれている

```yaml
原因: state.md と実際の状態が不一致
対処:
  1. git status で変更を確認
  2. state.md を手動で修正
  3. [自認] で現在地を再宣言
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-14 | M023: 初版作成。Named Sessions と Plan Mode の活用ガイド。 |
