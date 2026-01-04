# criterion-validation-rules.md

> **criterion（done_criteria の単位）の検証ルール**
>
> 曖昧な表現を検出・拒否し、検証可能な形式での定義を強制する。

---

## 目的

TDD の本質は「どんな動きが正しいか」を先に定義すること。
曖昧な criterion は「テストをクリアするためのテスト」を生む。
このドキュメントは criterion の品質を検証するルールセットを定義する。

---

## 禁止パターン（15個以上）

> **以下のパターンを含む criterion は拒否される。**

### 1. 動詞で終わる表現（アクション形式）

| 禁止パターン | なぜダメか | 修正例 |
|-------------|----------|--------|
| 「〜を実装する」 | アクションであり状態でない。完了の判定ができない | → 「〜が実装されている」「〜.ts が存在する」 |
| 「〜を作成する」 | 作成したかどうかは主観的 | → 「〜が作成されている」「test -f で PASS」 |
| 「〜を設定する」 | 設定したかと動くかは別問題 | → 「〜が設定されている」「grep で設定値を確認」 |
| 「〜を確認する」 | 確認は検証ではない | → 「〜が〇〇である」（状態を明示） |
| 「〜をテストする」 | テストした事実ではなく結果が重要 | → 「npm test が exit 0 で終了する」 |

### 2. 曖昧な形容詞・副詞

| 禁止パターン | なぜダメか | 修正例 |
|-------------|----------|--------|
| 「適切に〜」 | 「適切」の定義がない | → 具体的な条件を明示（例：「5秒以内に」「100件以上」） |
| 「正しく〜」 | 「正しい」の基準が不明 | → 期待値を明示（例：「200を返す」「エラーなし」） |
| 「良い〜」 | 主観的で検証不可能 | → 定量的な基準を設定 |
| 「うまく〜」 | 判定基準がない | → 具体的な成功条件を記述 |
| 「きちんと〜」 | 曖昧すぎる | → 検証可能な条件に置換 |

### 3. 完了の定義が不明確

| 禁止パターン | なぜダメか | 修正例 |
|-------------|----------|--------|
| 「完成させる」 | 完成の定義がない | → 完成条件を列挙（チェックリスト形式） |
| 「仕上げる」 | 主観的 | → 具体的な受け入れ条件を明示 |
| 「対応する」 | 何をもって対応完了か不明 | → 対応の具体的アクションと結果を記述 |
| 「改善する」 | 改善の程度が不明 | → Before/After の数値目標を設定 |
| 「最適化する」 | 最適の基準がない | → 目標値を設定（例：「レスポンス 200ms 以下」） |

### 4. 検証方法が不明

| 禁止パターン | なぜダメか | 修正例 |
|-------------|----------|--------|
| 「動作する」 | どう動作すれば OK か不明 | → 「GET /api/health が 200 を返す」 |
| 「機能する」 | 機能の範囲が曖昧 | → 具体的な入出力を明示 |
| 「問題ない」 | 問題の定義がない | → チェック項目を列挙 |
| 「エラーがない」 | どのエラーを指すか不明 | → 「exit code 0」「stderr が空」 |
| 「成功する」 | 成功の条件が不明 | → 成功時の具体的な出力や状態を記述 |

---

## 検証可能性チェックリスト

> **criterion を定義する前に、以下を確認せよ。**

```yaml
checklist:
  - [ ] 状態形式か？（「〜である」「〜が存在する」）
  - [ ] validations（3点検証）が書けるか？
  - [ ] 第三者が同じ結果を再現できるか？
  - [ ] 数値・具体例が含まれているか？
  - [ ] 禁止パターンに該当しないか？
```

---

## Given/When/Then テンプレート

> **複雑な criterion は Given/When/Then 形式で分解する。**

### テンプレート

```yaml
Given: {前提条件}
When: {トリガーとなるアクション}
Then: {期待される結果}
```

### 例1: API エンドポイント

```yaml
Given: ユーザーが認証済み
When: GET /api/users を実行
Then: 200 + ユーザー一覧 JSON を返す

validations:
  technical: "curl で API を呼び出し、200 と JSON を確認"
  consistency: "認証トークンが有効であることを確認"
  completeness: "レスポンスにユーザー一覧が含まれていることを確認"
```

### 例2: ファイル操作

```yaml
Given: src/components/ ディレクトリが存在
When: Button.tsx を作成
Then: src/components/Button.tsx が存在し、export default Button を含む

validations:
  technical: "test -f と grep で存在と内容を確認"
  consistency: "他のコンポーネントと同じ構造であることを確認"
  completeness: "export default Button が含まれていることを確認"
```

### 例3: テスト実行

```yaml
Given: 依存パッケージがインストール済み
When: npm test を実行
Then: 全テストが PASS し、カバレッジ 80% 以上

validations:
  technical: "npm test を実行し全テスト PASS を確認"
  consistency: "カバレッジレポートが生成されることを確認"
  completeness: "カバレッジ 80% 以上を確認"
```

---

## 良い criterion の例

```yaml
examples:
  - criterion: "README.md が存在する"
    validations:
      technical: "test -f README.md で確認"
      consistency: "他ドキュメントと整合性確認"
      completeness: "必須セクションが含まれているか確認"
    why: 状態形式、validations が明確

  - criterion: "npm test が exit code 0 で終了する"
    validations:
      technical: "npm test を実行し exit code 確認"
      consistency: "テスト対象コードと整合性確認"
      completeness: "全テストケースが含まれているか確認"
    why: 具体的な成功条件、再現可能

  - criterion: "禁止パターンが15個以上列挙されている"
    validations:
      technical: "grep -c で件数をカウント"
      consistency: "パターン形式が統一されているか確認"
      completeness: "必要なパターンが全て含まれているか確認"
    why: 数値目標が明確、検証可能

  - criterion: "API レスポンスが 200ms 以内"
    validations:
      technical: "curl でレスポンス時間を測定"
      consistency: "他のエンドポイントと整合性確認"
      completeness: "複数回測定で安定しているか確認"
    why: 定量的な基準、測定可能

  - criterion: "全 subtask に executor フィールドが存在する"
    validations:
      technical: "grep で executor: の存在を確認"
      consistency: "executor の値が有効か確認"
      completeness: "全 subtask が確認されているか確認"
    why: 構造的な要件、検証可能
```

---

## 悪い criterion の例（禁止）

```yaml
bad_examples:
  - criterion: "ドキュメントを書く"
    why: アクション形式、完了条件が不明
    fix: "docs/guide.md が存在し、50行以上である"

  - criterion: "テストする"
    why: 何をどうテストするか不明
    fix: "npm test が exit 0 で終了する"

  - criterion: "適切に設定する"
    why: 「適切」の定義がない
    fix: ".env に API_KEY が設定されている（grep で確認）"

  - criterion: "正しく動作する"
    why: 「正しく」の基準がない
    fix: "GET /api/health が 200 を返す"

  - criterion: "完成させる"
    why: 完成の定義がない
    fix: 具体的なチェックリストに分解
```

---

## pm/critic が使用する検出ロジック

```yaml
detection_algorithm:
  1. criterion を行単位で抽出
  2. 禁止パターン（正規表現）に照合:
     - /する$/ → 動詞で終わる
     - /した$/ → 過去形だがアクション
     - /適切|正しく|良い|うまく|きちんと/ → 曖昧形容詞
     - /完成|仕上げ|対応|改善|最適化/ → 完了定義不明
     - /動作|機能|問題ない|成功/ → 検証方法不明
  3. 1つでも該当 → FAIL + 修正案を提示
  4. 全て OK → PASS

regex_patterns:
  - pattern: "(する|した)$"
    message: "動詞で終わっています。状態形式（〜である、〜が存在する）に修正してください"
  - pattern: "適切|正しく|良い|うまく|きちんと"
    message: "曖昧な形容詞です。具体的な条件に置換してください"
  - pattern: "完成|仕上げ|対応する|改善|最適化"
    message: "完了の定義が不明確です。具体的なチェックリストに分解してください"
  - pattern: "動作する|機能する|問題ない|成功する"
    message: "検証方法が不明です。validations が書ける形式に修正してください"
```

---

## 参照

- plan/template/playbook-format.md（subtasks 構造）
- .claude/skills/golden-path/agents/pm.md（playbook 生成時に参照）
- .claude/skills/reward-guard/agents/critic.md（criterion 検証時に参照）

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-22 | test_command を廃止、validations（3点検証）ベースに移行。 |
| 2025-12-13 | 初版作成。禁止パターン15個、Given/When/Then テンプレート、検出ロジックを定義。 |
