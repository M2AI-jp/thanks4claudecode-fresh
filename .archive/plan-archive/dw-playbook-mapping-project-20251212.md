# project.md

> **playbook 生成ルールの明確化 - 1 done_when = 1 playbook**

---

## meta

```yaml
project: dw-playbook-mapping
created: 2025-12-12
type: workspace
location: plan/
```

---

## vision

### ユーザーの意図

> 「DW-001 単位で、1 つ playbook が生成されるように仕様変更して欲しい」

### 成功の定義

- 1 done_when = 1 playbook の関係が明文化されている
- pm が自動的にこの規則に従う

---

## done_when

```yaml
DW-001:
  id: DW-001
  name: 1 done_when = 1 playbook ルールの明文化
  status: not_achieved
  priority: high
  estimated_effort: 2h
  depends_on: []
  decomposition:
    playbook_summary: pm, playbook-format.md, CLAUDE.md に「1 done_when = 1 playbook」ルール追加
    success_indicators:
      - pm.md に「1 done_when = 1 playbook」が明記されている
      - playbook-format.md に、このルールの説明が含まれている
      - CLAUDE.md の「タスク標準化」セクションに、このルールへの参照が含まれている
    phase_hints:
      - phase: 現状分析
      - phase: ルール追加
      - phase: 検証と統合テスト
```

---

## milestones

- [ ] M1: ルール明文化完了
