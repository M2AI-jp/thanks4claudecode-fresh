---
name: playbook-review
description: playbook 作成後に reviewer による検証を強制する Skill
trigger: PostToolUse:Write (playbook-*.md 作成後)
---

# playbook-review Skill

> **playbook 作成後のレビューを構造的に強制する**

---

## Purpose

pm が playbook を作成した後、reviewer SubAgent による検証を強制する。
`reviewed: false` の状態で作業を開始させない。

---

## When to Use

- playbook が新規作成されたとき
- playbook の reviewed フラグが false のとき
- Edit/Write 操作が playbook 以外のファイルに対して行われるとき

---

## Structure

```
.claude/skills/playbook-review/
├── SKILL.md                    # この仕様書
├── hooks/
│   └── playbook-review-trigger.sh  # 導火線（reviewed: false で exit 2）
├── agents/
│   └── reviewer.md             # playbook レビュー SubAgent
└── frameworks/
    └── playbook-review-criteria.md  # レビュー基準
```

---

## Orchestration

```yaml
flow:
  1. pm が playbook 作成（reviewed: false）
  2. playbook-review-trigger.sh が Edit/Write 時に発火
  3. reviewed: false を検出 → exit 2（ブロック）
  4. Claude が reviewer SubAgent を呼び出し
  5. reviewer が検証（playbook-review-criteria.md 参照）
  6. PASS → reviewed: true に更新
  7. FAIL → 修正ループ（最大3回）
  8. reviewed: true → 作業開始許可

enforcement:
  - reviewed: false の playbook で Edit/Write → exit 2 (ブロック)
  - playbook ファイル自体の編集は例外（ブートストラップ）
  - state.md の編集も例外
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
        "command": "bash .claude/skills/playbook-review/hooks/playbook-review-trigger.sh"
      },
      {
        "matcher": "Write",
        "command": "bash .claude/skills/playbook-review/hooks/playbook-review-trigger.sh"
      }
    ]
  }
}
```

### reviewer SubAgent 呼び出し

```
Task(subagent_type='reviewer', prompt='playbook をレビュー。.claude/skills/playbook-review/frameworks/playbook-review-criteria.md を参照')
```

---

## References

- agents/reviewer.md - playbook レビュー担当 SubAgent
- frameworks/playbook-review-criteria.md - レビュー基準
- plan/template/playbook-format.md - playbook フォーマット
