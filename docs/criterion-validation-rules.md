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
  - [ ] test_command が書けるか？
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

test_command: |
  TOKEN=$(cat .env | grep API_TOKEN | cut -d= -f2)
  curl -H "Authorization: Bearer $TOKEN" http://localhost:3000/api/users | jq '.users | length > 0'
```

### 例2: ファイル操作

```yaml
Given: src/components/ ディレクトリが存在
When: Button.tsx を作成
Then: src/components/Button.tsx が存在し、export default Button を含む

test_command: |
  test -f src/components/Button.tsx && \
  grep -q 'export default Button' src/components/Button.tsx && \
  echo PASS
```

### 例3: テスト実行

```yaml
Given: 依存パッケージがインストール済み
When: npm test を実行
Then: 全テストが PASS し、カバレッジ 80% 以上

test_command: |
  npm test -- --coverage 2>&1 | grep -q 'All tests passed' && \
  npm test -- --coverage 2>&1 | grep -oP 'Coverage: \K[0-9]+' | awk '{if($1>=80) print "PASS"; else print "FAIL"}'
```

---

## 良い criterion の例

```yaml
examples:
  - criterion: "README.md が存在する"
    test_command: "test -f README.md && echo PASS"
    why: 状態形式、test_command が明確

  - criterion: "npm test が exit code 0 で終了する"
    test_command: "npm test && echo PASS || echo FAIL"
    why: 具体的な成功条件、再現可能

  - criterion: "禁止パターンが15個以上列挙されている"
    test_command: "grep -c '^| 「' docs/criterion-validation-rules.md | awk '{if($1>=15) print \"PASS\"}'"
    why: 数値目標が明確、grep で検証可能

  - criterion: "API レスポンスが 200ms 以内"
    test_command: "curl -w '%{time_total}' -o /dev/null -s http://localhost:3000/api/health | awk '{if($1<0.2) print \"PASS\"; else print \"FAIL\"}'"
    why: 定量的な基準、測定可能

  - criterion: "全 subtask に executor フィールドが存在する"
    test_command: "grep -c 'executor:' plan/active/*.md | awk -F: '{sum+=$2} END {if(sum>=10) print \"PASS\"}'"
    why: 構造的な要件、grep で検証可能
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
    message: "検証方法が不明です。test_command が書ける形式に修正してください"
```

---

## 参照

- plan/template/playbook-format.md（subtasks 構造）
- .claude/agents/pm.md（playbook 生成時に参照）
- .claude/agents/critic.md（criterion 検証時に参照）

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | 初版作成。禁止パターン15個、Given/When/Then テンプレート、検出ロジックを定義。 |
