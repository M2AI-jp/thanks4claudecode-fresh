---
name: subtask-review
description: subtask 完了時に 3 点検証（technical/consistency/completeness）を強制する Skill
trigger: PreToolUse(Edit) - playbook 内 subtask の完了変更時
---

# subtask-review Skill

> **subtask 完了時の 3 点検証を構造的に強制する**

---

## Purpose

subtask を完了としてマークする際、以下の 3 点検証を強制する:
- **technical**: 技術的に正しく動作するか
- **consistency**: 他のコンポーネントと整合性があるか
- **completeness**: 必要な変更が全て完了しているか

validations なしでの subtask 完了をブロック（exit 2）する。

---

## When to Use

- playbook 内の subtask を `- [ ]` から `- [x]` に変更するとき
- subtask の status を pending/in_progress から done に変更するとき
- Phase の status を done に変更するとき（全 subtask 完了確認）

---

## Structure

```
.claude/skills/subtask-review/
├── SKILL.md                    # この仕様書
├── hooks/
│   └── subtask-validator.sh    # 検証 Hook（validations 必須）
└── frameworks/
    └── subtask-validation-rules.md  # 3 点検証の基準
```

---

## Orchestration

```yaml
flow:
  1. Claude が subtask を完了としてマーク（Edit）
  2. subtask-validator.sh が PreToolUse で発火
  3. 変更が subtask 完了変更か判定
  4. validations フィールドの有無をチェック
  5. 3 点検証（technical/consistency/completeness）の完全性をチェック
  6. validations なし or 不完全 → exit 2（ブロック）
  7. validations 完全 → exit 0（許可）

enforcement:
  - subtask 完了時に validations 必須（exit 2 でブロック）
  - 3 点検証の完全性チェック（technical/consistency/completeness が全て存在）
  - Phase 完了時に全 subtask 完了を確認（未完了あれば exit 2）
  - final_tasks の変更は例外（validations 不要）
```

---

## 3 点検証（validations）

```yaml
validations:
  technical: "PASS - 技術的検証の結果"
  consistency: "PASS - 整合性検証の結果"
  completeness: "PASS - 完全性検証の結果"
```

### technical（技術検証）
- 実装が技術的に正しいか
- コマンドやテストの実行結果
- 例: `test -f で確認済み`、`npm test PASS`

### consistency（整合性検証）
- 他のコンポーネント・ドキュメントとの整合性
- 命名規則、構造の一貫性
- 例: `他の Skill と同じディレクトリ構造`

### completeness（完全性検証）
- 必要な変更が全て完了しているか
- 漏れがないか
- 例: `全必須セクションが存在する`

---

## Integration

### Hook 登録（settings.json）

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit",
        "command": "bash .claude/skills/subtask-review/hooks/subtask-validator.sh"
      }
    ]
  }
}
```

---

## References

- frameworks/subtask-validation-rules.md - 検証基準の詳細
- docs/criterion-validation-rules.md - criterion 定義ルール
- plan/template/playbook-format.md - playbook フォーマット
