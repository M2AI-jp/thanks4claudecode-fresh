# playbook-action-based-guards.md

> **session 分類を廃止し、アクションベース Guards に移行**

---

## meta

```yaml
project: action-based-guards
branch: feat/session-redesign
created: 2025-12-08
issue: null
```

---

## goal

```yaml
summary: session 分類を廃止し、Edit/Write 時のみ playbook チェックを行う設計に移行
done_when:
  - session 分類ロジックが完全に削除されている
  - Edit/Write の PreToolUse でのみ playbook-guard が発動する
  - Read/Grep/WebSearch 等は playbook なしでも許可される
  - 「おはよう」でも「調査して」でも、Edit しない限りブロックされない
```

---

## phases

```yaml
- id: p0
  name: 影響範囲の特定
  goal: 変更が必要なファイルを全て洗い出す
  executor: claudecode
  done_criteria:
    - session 分類に関わる全ファイルをリストアップしている
    - 各ファイルの変更内容を明確にしている
  test_method: |
    1. grep で session 関連コードを検索
    2. 変更対象と変更内容を一覧化
  status: done
  evidence:
    - 変更対象7ファイル特定（playbook-guard.sh, prompt-validator.sh, session-start.sh, session-end.sh, lib/common.sh, state.md, CLAUDE.md）

- id: p1
  name: playbook-guard.sh の改修
  goal: session 参照を削除し、Edit/Write 時のみ発火するよう変更
  executor: claudecode
  depends_on: [p0]
  done_criteria:
    - playbook-guard.sh が session を参照していない
    - Edit/Write ツール使用時のみチェックが発動する
    - Read/Grep/Bash 等では発動しない
  test_method: |
    1. grep で session 参照がないことを確認
    2. Edit 時に発動することをテスト
    3. Read 時に発動しないことをテスト
  status: done
  evidence:
    - grep -c "SESSION\|session" playbook-guard.sh → 0
    - ヘッダーコメント更新「アクションベース Guards」

- id: p2
  name: prompt-validator.sh の簡略化
  goal: session リセットロジックを削除
  executor: claudecode
  depends_on: [p1]
  done_criteria:
    - prompt-validator.sh から session リセットロジックが削除されている
    - または prompt-validator.sh 自体を廃止
  test_method: |
    1. ファイルを Read して session 操作がないことを確認
  status: done
  evidence:
    - prompt-validator.sh を .archive/hooks/ に退避
    - settings.json から UserPromptSubmit Hook を削除

- id: p3
  name: state.md の簡略化
  goal: session フィールドと session_definition を削除
  executor: claudecode
  depends_on: [p2]
  done_criteria:
    - state.md から session フィールドが削除されている
    - session_definition セクションが削除されている
  test_method: |
    1. state.md を Read して session 関連がないことを確認
  status: done
  evidence:
    - grep -c "^session:" state.md → 0
    - session_definition セクション削除

- id: p4
  name: CLAUDE.md の更新
  goal: session 関連の記述を削除し、アクションベース設計を文書化
  executor: claudecode
  depends_on: [p3]
  done_criteria:
    - CLAUDE.md から session 分類の説明が削除されている
    - アクションベース Guards の説明が追加されている
  test_method: |
    1. grep で session 関連記述を確認
    2. 新しい設計の説明を確認
  status: done
  evidence:
    - SESSION セクション → ACTION_GUARDS セクションに変更
    - V5.0 変更履歴追加
    - CLAUDE-ref.md も更新

- id: p5
  name: lib/common.sh の更新
  goal: session 関連関数を削除
  executor: claudecode
  depends_on: [p4]
  done_criteria:
    - get_session() 関数が削除されている
    - should_skip_for_non_task() 関数が削除されている
  test_method: |
    1. grep で関数が存在しないことを確認
  status: done
  evidence:
    - grep -c "get_session\|should_skip_for_non_task" lib/common.sh → 0
    - session-start.sh, session-end.sh からも session 参照削除

- id: p6
  name: 統合テスト
  goal: 新設計が正しく動作することを検証
  executor: claudecode
  depends_on: [p5]
  done_criteria:
    - Read ツール使用時に playbook-guard が発動しない
    - Edit ツール使用時に playbook-guard が発動する
    - playbook ありで Edit が許可される
    - playbook なしで Edit がブロックされる
  test_method: |
    1. playbook=null で Read → 許可
    2. playbook=null で Edit → ブロック
    3. playbook あり で Edit → 許可
  status: done
  evidence:
    - Test 1: playbook あり で Edit → Exit 0（許可）
    - Test 2: playbook=null で Edit → Exit 2（ブロック）
    - Test 3: state.md 編集 → Exit 0（常に許可）
    - session 参照確認 → 全ファイル 0 references
    - 追加修正: scope-guard.sh, check-coherence.sh, check-main-branch.sh, check-state-update.sh
    - critic PASS（2回目）
```

---

## notes

```yaml
設計変更の理由:
  - session 分類は「形式」で判定するため、「意図」と乖離する
  - 「計画のレイヤー階層の実装とかって今どうなってる？」が QUESTION になる問題
  - 本当に守りたいのは「計画なしでコードを変更すること」
  - アクション（Edit/Write）を制御点にすれば、意図の推測が不要

削除対象:
  - state.md: session フィールド、session_definition セクション
  - prompt-validator.sh: session リセットロジック（または全体廃止）
  - playbook-guard.sh: session 参照
  - lib/common.sh: get_session(), should_skip_for_non_task()
  - CLAUDE.md: session 分類の説明

新設計:
  - playbook-guard.sh は Edit/Write の PreToolUse でのみ発火
  - Read/Grep/Bash/WebSearch 等は常に許可
  - session という概念自体を廃止
```

---

## 変更履歴

| 日時 | Phase | 内容 |
|------|-------|------|
| 2025-12-08 | p0 | playbook 作成 |
