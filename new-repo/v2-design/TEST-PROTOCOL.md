# テストプロトコル

> **文書の位置付け**: テスト手順の厳密な定義
>
> **MECE 役割**: テストの定義・種別・手順・出力形式の SSOT
>
> **作成日**: 2026-01-22

---

## 1. テストとは何か

### 1.1 定義

```yaml
test:
  definition: |
    実装が期待動作するかを、
    コンテキスト0（実装意図を知らない状態）で検証する行為

  input:
    - 実装（コード、設定ファイル、Hook スクリプト）
    - テストケース（期待動作の定義）

  output:
    status: PASS | FAIL
    evidence:
      - 実行ログ
      - 期待値と実際値の比較
      - スクリーンショット（該当する場合）

  constraint:
    - テスト実行者は実装の詳細を知らない前提
    - 期待動作はドキュメントから導出
    - 「動いた」ではなく「仕様通りに動いた」を検証
```

### 1.2 なぜコンテキスト0でテストするか

- **客観性**: 実装者のバイアスを排除
- **再現性**: 誰がテストしても同じ結果になる
- **ドキュメント検証**: 仕様書だけでテストできるか確認

---

## 2. テスト種別（5種別）

### 2.1 Structure Test（構造テスト）

```yaml
purpose: ファイル構造が仕様通りか検証
scope: ディレクトリ構造、必須ファイルの存在
method: スクリプトで自動検証

example: |
  # test-file-exists.sh
  assert_file_exists "README.md"
  assert_file_exists "CLAUDE.md"
  assert_file_exists "docs/SPECIFICATION.md"
  assert_dir_exists ".claude/commands"

pass_criteria:
  - 全ての必須ファイルが存在
  - 全ての必須ディレクトリが存在
```

### 2.2 Schema Test（スキーマテスト）

```yaml
purpose: JSON/YAML がスキーマに準拠しているか検証
scope: 設定ファイル、状態ファイル、playbook
method: JSON Schema Validator で自動検証

example: |
  # test-schemas.sh
  validate_json "state.md" "contracts/schemas/state.schema.json"
  validate_json ".claude/state/session.json" "contracts/schemas/session.schema.json"
  validate_json "play/*/plan.json" "contracts/schemas/playbook.schema.json"

pass_criteria:
  - 全ての JSON/YAML がスキーマに準拠
  - 必須フィールドが全て存在
  - 型が正しい
```

### 2.3 Reference Test（参照テスト）

```yaml
purpose: ファイル参照の整合性を検証
scope: ドキュメント間の参照、コード内の参照
method: スクリプトで参照先の存在を確認

example: |
  # test-references.sh
  # CLAUDE.md 内の全ての参照が存在するか
  extract_references "CLAUDE.md" | while read ref; do
    assert_file_exists "$ref"
  done

pass_criteria:
  - 全ての参照先ファイルが存在
  - 壊れたリンクがゼロ
```

### 2.4 Scenario Test（シナリオテスト）

```yaml
purpose: E2E シナリオが期待通り動作するか検証
scope: ユーザーストーリー、ワークフロー
method: シナリオ文書に従って手動実行、結果を記録

example: |
  # scenario-01-basic-task.md
  ## 前提条件
  - 新しい Claude Code セッション
  - playbook なし

  ## 手順
  1. 「ログイン機能を作って」と入力
  2. playbook が作成されることを確認
  3. /work で実装が開始されることを確認

  ## 期待結果
  - playbook が play/{id}/ に作成される
  - state.md の playbook.active が更新される

pass_criteria:
  - 全ての手順が実行可能
  - 期待結果と実際の結果が一致
```

### 2.5 Regression Test（回帰テスト）

```yaml
purpose: 既存機能が壊れていないか検証
scope: 過去に動作していた機能
method: 以前のテスト結果と比較

example: |
  # 全てのテストを実行し、以前の結果と比較
  ./tests/run-all-tests.sh > current_results.txt
  diff previous_results.txt current_results.txt

pass_criteria:
  - 以前 PASS だったテストが引き続き PASS
  - 新たな FAIL が発生していない
```

---

## 3. テスト手順

### Phase 1: 準備

```yaml
actions:
  - 新しい Claude Code セッションを開始（コンテキスト0）
  - テスト対象の Phase を確認
  - 必要なテストケースを特定
```

### Phase 2: 自動テスト実行

```yaml
actions:
  - ./tests/run-all-tests.sh を実行
  - Structure Test → Schema Test → Reference Test の順
  - 失敗したテストを記録

order:
  1. Structure Test（ファイル存在）
  2. Schema Test（スキーマ準拠）
  3. Reference Test（参照整合性）
```

### Phase 3: シナリオテスト実行

```yaml
actions:
  - tests/scenarios/ のシナリオを順番に実行
  - 各ステップの結果を記録
  - 期待結果との差異を記録
```

### Phase 4: レポート作成

```yaml
actions:
  - テスト結果サマリーを作成
  - PASS/FAIL の判定
  - 失敗したテストの原因分析
```

---

## 4. テスト結果テンプレート

```markdown
# Test Report

## メタ情報
- テスト対象: Phase {N}
- テスト日時: {YYYY-MM-DD HH:MM}
- テスト実行者: Claude Code (Context-0)

## 総合結果
**{PASS | FAIL}**

## 自動テスト結果

| テスト種別 | 実行数 | 成功 | 失敗 | スキップ |
|-----------|--------|------|------|---------|
| Structure | {N} | {N} | {N} | {N} |
| Schema | {N} | {N} | {N} | {N} |
| Reference | {N} | {N} | {N} | {N} |

## シナリオテスト結果

| シナリオ | 結果 | 備考 |
|---------|------|------|
| scenario-01-basic-task | {PASS/FAIL} | {備考} |
| scenario-02-resume | {PASS/FAIL} | {備考} |

## 失敗したテスト

### {テスト名}
- **期待値**: {expected}
- **実際値**: {actual}
- **原因分析**: {analysis}

## 次のアクション
1. {具体的なアクション}
```

---

## 5. テストスクリプト仕様

### run-all-tests.sh

```bash
#!/bin/bash
# 全テストを実行するエントリーポイント

set -e

echo "=== Structure Tests ==="
./tests/structure/test-file-exists.sh

echo "=== Schema Tests ==="
./tests/structure/test-schemas.sh

echo "=== Reference Tests ==="
./tests/structure/test-references.sh

echo "=== All Tests Passed ==="
```

### アサーション関数

```bash
# assert_file_exists: ファイルが存在することを確認
assert_file_exists() {
  local file="$1"
  if [[ -f "$file" ]]; then
    echo "✓ $file exists"
    return 0
  else
    echo "✗ $file not found"
    return 1
  fi
}

# assert_dir_exists: ディレクトリが存在することを確認
assert_dir_exists() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    echo "✓ $dir exists"
    return 0
  else
    echo "✗ $dir not found"
    return 1
  fi
}

# validate_json: JSON がスキーマに準拠することを確認
validate_json() {
  local json_file="$1"
  local schema_file="$2"
  # ajv などのツールを使用
  ajv validate -s "$schema_file" -d "$json_file"
}
```

---

## 6. シナリオテスト例

### scenario-01-basic-task.md

```markdown
# シナリオ: 基本的なタスク実行

## 前提条件
- 新しい Claude Code セッション（コンテキスト0）
- playbook なし（state.md の playbook.active = null）

## 手順

### Step 1: タスク依頼
- 入力: 「ログイン機能を作って」
- 期待: playbook-init が呼び出される

### Step 2: playbook 作成確認
- 確認: play/{id}/plan.json が存在する
- 確認: play/{id}/PLAYBOOK.md が存在する
- 確認: state.md の playbook.active が更新されている

### Step 3: 実装開始
- 入力: /work
- 期待: Phase 1 のタスクが実行される

## 期待結果

| 確認項目 | 期待値 |
|---------|--------|
| playbook 作成 | play/{id}/ に plan.json と PLAYBOOK.md |
| state.md 更新 | playbook.active = play/{id}/plan.json |
| /work 実行 | Phase 1 のタスクが開始 |

## 合否判定
- 全ての期待結果を満たす: PASS
- 1つでも満たさない: FAIL
```

---

## 7. テストカバレッジ目標

```yaml
coverage_targets:
  phase_0:
    structure: 100%  # 全ての必須ファイル
    schema: 100%     # 全ての JSON/YAML
    reference: 100%  # 全ての参照
    scenario: 3件    # 基本操作

  phase_1:
    scenario: +2件   # Resume, Fork

  phase_2:
    scenario: +2件   # playbook 作成, 同期

  phase_3:
    scenario: +2件   # レビュー, テスト

  phase_4:
    regression: 100% # 全ての既存テスト
```

---

## 参照

- REVIEW-PROTOCOL.md（レビュー手順）
- GLOSSARY.md（用語定義）
- SPECIFICATION.md（仕様書）
