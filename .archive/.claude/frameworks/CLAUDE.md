# .claude/frameworks/

> **Frameworks - 評価基準と検証フレームワーク**

---

## 役割

Frameworks は SubAgents（特に critic）が参照する評価基準を定義します。
都度生成ではなく、一貫した基準で検証を行うために使用されます。

---

## 設計原則

```yaml
禁止: 都度生成の評価基準
必須: Frameworks を参照した一貫した評価
```

---

## 利用可能な Frameworks

| Framework | 役割 | 主な参照元 |
|-----------|------|------------|
| done-criteria-validation.md | done_criteria の検証基準 | critic SubAgent |
| playbook-review-criteria.md | playbook の品質評価基準 | reviewer SubAgent |

---

## done-criteria-validation.md

critic SubAgent が Phase 完了を判定する際の評価基準：

1. **根拠の有無** - done_criteria に根拠があるか
2. **検証可能性** - 客観的に検証可能か
3. **計画との整合性** - playbook のゴールと整合しているか
4. **報酬詐欺の検出** - 「〇〇した」だけで終わっていないか
5. **証拠の品質** - 具体的な証拠が示されているか

---

## 連携

- **critic SubAgent** → Frameworks を参照して評価
- **Skills** → 評価に必要な情報を提供
- **CLAUDE.md** → CRITIQUE セクションで Frameworks を指定
