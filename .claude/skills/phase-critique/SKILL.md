---
name: phase-critique
description: Phase 完了申告時に critic 評価を強制する Skill
trigger: PreToolUse(Edit) - state: done への変更時
---

# phase-critique Skill

> **Phase 完了時の critic 評価を構造的に強制する**

---

## Purpose

Phase を完了（state: done）としてマークする際、critic エージェントによる評価を強制する。
自己報酬詐欺（証拠なしでの完了申告）を構造的に防止する。

---

## When to Use

- Phase を完了としてマークするとき
- state.md の state を done に変更するとき
- playbook の Phase status を done に変更するとき

---

## Structure

```
.claude/skills/phase-critique/
├── SKILL.md                    # この仕様書
├── hooks/
│   └── critic-enforcer.sh      # 完了申告ブロック Hook
├── agents/
│   └── critic.md               # 評価担当 SubAgent
└── frameworks/
    └── done-criteria-validation.md  # 評価フレームワーク
```

---

## Orchestration

```yaml
flow:
  1. Claude が Phase を done としてマーク（Edit）
  2. critic-enforcer.sh が PreToolUse で発火
  3. state: done への変更を検出
  4. self_complete: true フラグの有無をチェック
  5. フラグなし → exit 2（ブロック）
  6. Claude が critic SubAgent を呼び出し
  7. critic が done_criteria を評価（done-criteria-validation.md 参照）
  8. PASS → self_complete: true を設定
  9. FAIL → 修正ループ
  10. self_complete: true → state: done への変更許可

enforcement:
  - critic PASS なしで state: done → exit 2（ブロック）
  - 証拠なしの PASS 判定は不可
  - 5 項目の妥当性チェック必須
```

---

## critic 評価の 5 項目

```yaml
妥当性チェック:
  1. 根拠の有無:
     - done_criteria の導出元が明確
     - ユーザー発言または仕様に基づく

  2. 検証可能性:
     - コマンドで確認可能
     - 外部から観測可能な状態

  3. 計画との整合性:
     - Phase の goal と整合
     - 過剰/不足がない

  4. 報酬詐欺の検出:
     - 証拠なしの完了申告を検出
     - 「〜のはず」「〜だと思う」を拒否

  5. 証拠の品質:
     - 具体的な実行結果
     - ファイルの該当箇所引用
```

---

## Integration

### Hook 登録（settings.json）

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit",
        "command": "bash .claude/skills/phase-critique/hooks/critic-enforcer.sh"
      }
    ]
  }
}
```

### critic SubAgent 呼び出し

```
Task(subagent_type='critic', prompt='Phase の done_criteria を評価')
```

または

```
/crit
```

---

## References

- agents/critic.md - 評価担当 SubAgent
- frameworks/done-criteria-validation.md - 評価フレームワーク
- docs/criterion-validation-rules.md - criterion 定義ルール
