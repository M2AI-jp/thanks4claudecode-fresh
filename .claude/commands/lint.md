---
description: state.md と playbook の整合性チェックを実行。コミット前の検証に使用。
allowed-tools: Read, Bash
---

# /lint - 整合性チェックの実行

state.md と playbook の整合性をチェックしてください。

## 実行内容

```bash
bash .claude/skills/reward-guard/guards/coherence.sh
```

## チェック項目

1. state.md と playbook の整合性
2. playbook.active が存在するか
3. playbook.branch と現在のブランチの一致

---

結果を報告し、問題があれば修正案を提示してください。
