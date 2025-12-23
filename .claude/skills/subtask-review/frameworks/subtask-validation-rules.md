# subtask-validation-rules.md

> **subtask 完了時の 3 点検証（validations）ルール**
>
> 技術的正確性、整合性、完全性を検証する基準を定義する。

---

## Purpose

subtask を完了としてマークする際、以下の 3 点検証を実施する:
- **technical**: 技術的に正しく動作するか
- **consistency**: 他のコンポーネントと整合性があるか
- **completeness**: 必要な変更が全て完了しているか

---

## 3 点検証（validations）の定義

### 1. technical（技術検証）

**目的**: 実装が技術的に正しいことを確認する

```yaml
検証項目:
  - コマンドの実行結果（exit code）
  - テストの成否
  - ファイルの存在確認（test -f/-d）
  - 構文チェック（bash -n, eslint, etc.）
  - 期待する出力との一致

記述例:
  - "PASS - test -f で確認済み"
  - "PASS - bash -n で構文エラーなし"
  - "PASS - npm test 全テスト PASS"
  - "PASS - API が 200 を返す"
```

### 2. consistency（整合性検証）

**目的**: 他のコンポーネント・ドキュメントとの整合性を確認する

```yaml
検証項目:
  - 命名規則の一貫性
  - ディレクトリ構造の一貫性
  - 他の同種コンポーネントとの構造一致
  - 参照先ドキュメントとの整合
  - 設定ファイルとの整合

記述例:
  - "PASS - 他の Skill と同じディレクトリ構造"
  - "PASS - 命名規則に従っている"
  - "PASS - settings.json との参照が一致"
  - "PASS - 他の Hook と同じインターフェース"
```

### 3. completeness（完全性検証）

**目的**: 必要な変更が全て完了していることを確認する

```yaml
検証項目:
  - 必須ファイルの存在
  - 必須セクション・フィールドの存在
  - 依存する変更の完了
  - ドキュメント更新の完了
  - 関連ファイルの更新

記述例:
  - "PASS - 全必須セクションが存在"
  - "PASS - hooks/, agents/, frameworks/ が揃っている"
  - "PASS - README に記載済み"
  - "PASS - settings.json に登録済み"
```

---

## validations の記述フォーマット

### 基本フォーマット

```yaml
- [x] **p1.1**: criterion が満たされている
  - executor: claudecode
  - validations:
    - technical: "PASS - 技術的検証の詳細"
    - consistency: "PASS - 整合性検証の詳細"
    - completeness: "PASS - 完全性検証の詳細"
  - validated: 2025-12-23T12:00:00
```

### 検証結果の記述

```yaml
PASS:
  - "PASS - ..." で始める
  - 具体的な検証方法・結果を記述

FAIL:
  - "FAIL - ..." で始める
  - 失敗理由を明記
  - FAIL がある場合は subtask を完了にしてはいけない

SKIP:
  - "SKIP - ..." で始める
  - スキップ理由を明記
  - 正当な理由がある場合のみ使用
```

---

## 検証が不要なケース

以下は validations なしでも変更可能:

1. **final_tasks の変更**
   - 単純なチェックリストのため validations 不要
   - `- [ ] **ft1**: ...` → `- [x] **ft1**: ...`

2. **状態フィールドの更新**
   - `status: pending` → `status: in_progress`
   - 作業開始の表明のみ

3. **コメントの追加・修正**
   - criterion や validations の内容変更ではない場合

---

## 禁止事項

```yaml
禁止:
  - validations なしでの subtask 完了
  - 全て "PASS" と記述するだけで具体的な検証内容がない
  - 自己申告のみで客観的証拠がない
  - 検証を実施せずに PASS と記述
```

---

## 参照

- docs/criterion-validation-rules.md - criterion 定義のルール
- plan/template/playbook-format.md - playbook フォーマット
- .claude/skills/subtask-review/SKILL.md - Skill 仕様
