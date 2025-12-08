# playbook-session-redesign.md

> **session 定義の再設計: Hook が自動判定・更新する仕組みの構築**

---

## meta

```yaml
project: session-redesign
branch: feat/session-redesign
created: 2025-12-08
issue: null
```

---

## goal

```yaml
summary: session を TASK/CHAT/QUESTION/META に再定義し、Hook + LLM で分類・強制する仕組みを構築
done_when:
  - Hook が発火して Claude に分類を指示している
  - Claude が NLU で分類し state.md を更新している
  - 後続の Guards が session を参照して動作を変えている
  - テスト: 各 session で Guards が正しく動作する
```

---

## phases

```yaml
- id: p0
  name: 設計確認
  goal: 現状分析と done_criteria の明確化
  executor: claudecode
  done_criteria:
    - 現状の session 使用箇所を全て特定している
    - 変更が必要なファイルを特定している
    - 各 Phase の done_criteria が検証可能な形式である
  test_method: |
    1. grep で session を参照している箇所を確認
    2. 変更対象ファイル一覧を作成
  status: done
  evidence:
    - grep で session 使用箇所を特定: Hooks 4ファイル + MD 9ファイル
    - 変更対象ファイル: 必須6件、関連3件
    - 各 Phase の done_criteria は検証可能な形式（critic PASS）

- id: p1
  name: session 定義の明確化
  goal: TASK/CHAT/QUESTION/META の定義を文書化
  executor: claudecode
  depends_on: [p0]
  done_criteria:
    - state.md に session の定義（4値）が記載されている
    - 各値のキーワードパターンが定義されている
    - 各値に対応する動作が定義されている
  test_method: |
    1. state.md を Read して定義を確認
    2. 定義が明確で検証可能か確認
  status: done
  evidence:
    - state.md 22-68行に session_definition セクション追加
    - TASK/CHAT/QUESTION/META の4値を定義
    - 各値に ja/en キーワードと動作を明記
    - critic PASS

- id: p2
  name: prompt-validator.sh にキーワード判定を追加
  goal: プロンプト内容からキーワードで session を判定
  executor: claudecode
  depends_on: [p1]
  done_criteria:
    - prompt-validator.sh にキーワード判定ロジックが実装されている
    - 日本語・英語両方のキーワードに対応している
    - デフォルト値が設定されている
  test_method: |
    1. コードを Read して判定ロジックを確認
    2. 各キーワードパターンが網羅されているか確認
  status: done
  evidence:
    - キーワード判定ロジック: 49-85行
    - 日本語・英語両方: TASK/CHAT/QUESTION/META 各2パターン
    - デフォルト値: 58行 SESSION_TYPE="QUESTION"
    - critic PASS

- id: p3
  name: prompt-validator.sh が session を更新
  goal: 判定結果を state.md に自動書き込み
  executor: claudecode
  depends_on: [p2]
  done_criteria:
    - prompt-validator.sh が state.md の session を sed で更新している
    - 更新前後のログが出力されている
    - エラーハンドリングが実装されている
  test_method: |
    1. 手動でプロンプトを送信
    2. state.md の session が更新されているか確認
    3. ログ出力を確認
  status: done
  evidence:
    - sed で session 更新: 94-114行（GNU/BSD 両対応）
    - ログ出力: 92行で .claude/logs/prompt-validator.log に記録
    - エラーハンドリング: 37-41行で jq parse error をハンドリング
    - 実動作確認: state.md の session が CHAT に自動更新された
    - critic PASS

- id: p4
  name: 後続 Hooks の修正
  goal: session 値を参照する Hooks を新定義に対応
  executor: claudecode
  depends_on: [p3]
  done_criteria:
    - session=TASK/CHAT/QUESTION/META を参照する Hooks が更新されている
    - TASK 以外では guard がスキップされる
  test_method: |
    1. 各 Hook のコードを確認
    2. session 参照ロジックが更新されているか確認
  status: done
  evidence:
    - lib/common.sh: get_session() 更新（40-48行）、should_skip_for_non_task() 追加（208-217行）
    - playbook-guard.sh: SESSION != "TASK" でスキップ（40-43行）
    - session-end.sh: SESSION = "TASK" でチェック（150-152行）
    - 実動作確認: session=CHAT で guard スキップ、Edit ツール動作
    - critic PASS

- id: p5
  name: prompt_type フィールド廃止
  goal: session に統合し prompt_type を削除
  executor: claudecode
  depends_on: [p4]
  done_criteria:
    - state.md から prompt_type フィールドが削除されている
    - CLAUDE.md から prompt_type の参照が削除されている
    - 全ての参照が session に置き換わっている
  test_method: |
    1. grep で prompt_type を検索
    2. 参照が残っていないことを確認
  status: done
  evidence:
    - state.md に prompt_type フィールドなし（focus セクション確認）
    - CLAUDE.md 変更履歴を V4.0 に更新（行265）
    - grep で playbook 以外に prompt_type 参照なし
    - critic PASS

- id: p6
  name: 統合テスト
  goal: 各種プロンプトで正しく動作することを検証
  executor: claudecode
  depends_on: [p5]
  done_criteria:
    - TASK 判定: 「実装して」で session=TASK になる
    - CHAT 判定: 「こんにちは」で session=CHAT になる
    - QUESTION 判定: 「これは何？」で session=QUESTION になる
    - META 判定: 「計画変更」で session=META になる
    - critic PASS
  test_method: |
    1. 各パターンのプロンプトを送信
    2. state.md の session を確認
    3. 対応する Hook の動作を確認
    4. critic で検証
  status: done
  evidence:
    - TASK: echo '{"prompt":"実装して"}' → session=TASK（ログ 17:52:44）
    - CHAT: echo '{"prompt":"こんにちは"}' → session=CHAT（ログ 17:52:52）
    - QUESTION: echo '{"prompt":"これは何？"}' → session=QUESTION（ログ 17:52:59）
    - META: echo '{"prompt":"計画変更"}' → session=META（ログ 17:53:05）
    - 全テストで state.md が実際に更新された
    - critic: 1-4 全て PASS

- id: p7
  name: NLU ベースへの移行
  goal: キーワード判定から LLM の自然言語理解に移行
  executor: claudecode
  depends_on: [p6]
  done_criteria:
    - prompt-validator.sh からキーワード判定ロジックが削除されている
    - prompt-validator.sh は発火・指示出力のみ行う
    - CLAUDE.md に「Claude が NLU で分類し state.md を更新」が明記されている
    - session=CHAT で Guards がスキップされる
    - session=TASK で Guards が発動する
  test_method: |
    1. prompt-validator.sh を Read してキーワード判定がないことを確認
    2. CLAUDE.md を Read して分類フローを確認
    3. session を切り替えて Guard の動作を確認
  status: done
  evidence:
    - grep -c "grep -qE" prompt-validator.sh → 0（キーワード判定削除）
    - 51行にスリム化（元145行 → 62%削減）
    - CLAUDE.md 5行「NLU で判断」、159行「Claude が NLU で判断」
    - session=CHAT → Guard スキップ（exit 0）
    - session=TASK → Guard 発動（playbook チェック）
    - critic PASS
```

---

## notes

```yaml
背景:
  - 現状 prompt_type を Claude が state.md に書く設計だが、確率的に機能しない
  - Hook が自動で判定・更新することで「確実に動く」仕組みにする

キーワードパターン案:
  TASK: 作って、実装、追加、修正、直して、書いて、削除、変更
  CHAT: こんにちは、ありがとう、お疲れ、おはよう、hello
  QUESTION: ？、何、どう、ですか、って、どこ、いつ、why、what、how
  META: ついでに、別の、計画、scope、予定、変更したい

精度の妥協:
  - キーワードベースなので Claude の判定より精度は低い
  - 「確率的に動かない」より「確実に動く（精度は低い）」を優先
```

---

## 変更履歴

| 日時 | Phase | 内容 |
|------|-------|------|
| 2025-12-08 | p0 | playbook 作成、設計開始 |
