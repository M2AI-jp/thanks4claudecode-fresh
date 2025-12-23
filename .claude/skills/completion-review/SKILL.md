---
name: completion-review
description: playbook/milestone 完了時の検証とアーカイブ管理を行う Skill
trigger: PostToolUse(Edit) - playbook の全 Phase done 時
---

# completion-review Skill

> **playbook/milestone 完了時の検証とアーカイブを管理する**

---

## Purpose

playbook が完了（全 Phase done）した際の:
- 完了条件の最終検証
- アーカイブ前の整合性チェック
- milestone 影響分析
- project.md との同期

---

## When to Use

- playbook の全 Phase が done になったとき
- アーカイブ前の最終確認が必要なとき
- milestone 完了による影響を確認するとき
- project.md の milestone status を更新するとき

---

## Structure

```
.claude/skills/completion-review/
├── SKILL.md                    # この仕様書
├── hooks/
│   ├── archive-validator.sh    # アーカイブ前検証 Hook
│   └── milestone-impact-analyzer.sh  # milestone 影響分析 Hook
└── frameworks/
    └── completion-criteria.md  # 完了基準の定義
```

---

## Orchestration

```yaml
flow:
  1. playbook の Phase が done になる（Edit）
  2. archive-validator.sh が PostToolUse で発火
  3. 全 Phase done を検出
  4. 完了条件をチェック:
     - 全 subtask 完了（- [x]）
     - final_tasks 完了
     - p_final の validations が全て PASS
  5. 条件未達 → exit 2（アーカイブブロック）
  6. 条件達成 → アーカイブ提案を出力
  7. milestone-impact-analyzer.sh で影響分析
  8. project.md の milestone status 更新

enforcement:
  - p_final 未完了でのアーカイブ → exit 2（ブロック）
  - subtask 未完了でのアーカイブ → exit 2（ブロック）
  - final_tasks 未完了でのアーカイブ → 警告
  - milestone 影響がある場合 → 警告
```

---

## 完了検証項目

### 1. Phase 完了検証

```yaml
チェック項目:
  - 全 Phase の status が done
  - 全 subtask が完了（- [x]）
  - validations が全て PASS
```

### 2. final_tasks 検証

```yaml
チェック項目:
  - final_tasks セクションが存在する場合
  - 全てのタスクが完了（- [x]）
```

### 3. p_final 検証

```yaml
チェック項目:
  - p_final Phase が存在
  - p_final の全 subtask が完了
  - done_when の各項目が検証済み
```

### 4. milestone 影響分析

```yaml
チェック項目:
  - 完了 milestone に依存する他の milestone がないか
  - project.md との整合性
  - 関連 playbook の状態
```

---

## Integration

### Hook 登録（settings.json）

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit",
        "command": "bash .claude/skills/completion-review/hooks/archive-validator.sh"
      }
    ]
  }
}
```

---

## References

- hooks/archive-validator.sh - アーカイブ前検証 Hook
- hooks/milestone-impact-analyzer.sh - milestone 影響分析 Hook
- frameworks/completion-criteria.md - 完了基準の定義
- docs/archive-operation-rules.md - アーカイブ操作ルール
