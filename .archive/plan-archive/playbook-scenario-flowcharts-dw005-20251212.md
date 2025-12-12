# playbook: シナリオ別フローチャート作成

> 作成日: 2025-12-12
> 優先度: 中
> 見積: 2h

---

## goal

```yaml
summary: "Hooks/SubAgents/Skills の発火フロー・強制力を 6 シナリオで可視化"
phase: "p2-create"
done_criteria:
  - "6 つのシナリオフローチャートが docs/hooks-subagents-skills-inventory.md セクション 7 に追記されている"
  - "各フローの Hook/SubAgent/Skill が時系列で記載されている"
  - "強制力（BLOCK/WARN/INFO）が [タグ] で明示されている"
  - "セクション 7 が既存セクション 1-6 直後に挿入されている"
  - "critic が PASS を返す"
```

---

## derives_from

```yaml
project: plan/active/project.md
milestone: "Hooks/SubAgents/Skills 完全整理"
task: "DW-005"
completed_playbook: plan/archive/playbook-hooks-cleanup-dw005-20251212.md
```

---

## phases

### Phase 2: ドキュメント作成

id: p2
name: "ドキュメント作成"
goal: "フローチャートを docs/hooks-subagents-skills-inventory.md セクション 7 に追記"
status: "done"

tasks:
  - id: t8
    name: "シナリオ 1-6 のフローチャート作成"
    status: "done"
    subtasks:
      - step: "各シナリオのフローチャート作成"
        executor: claudecode
        criteria: "docs/hooks-subagents-skills-inventory.md にセクション 7 が追記されている"
        status: "[x]"

---

## metadata

```yaml
branch: feat/scenario-flowcharts
```

### Phase 3: テスト・検証

id: p3
name: "テスト・検証"
goal: "フローチャートが全シナリオを網羅、正確性を確保"
status: "done"

done_criteria:
  - "6 つのシナリオが全てカバーされている"
  - "feature-map.md セクション 4-6 の Hooks/SubAgents/Skills と inventory セクション 1-3 の項目が対応している"
  - "強制力タグが全て付与"
  - "critic が PASS を返す"

tasks:
  - id: t11
    name: "フローチャート検証"
    status: "done"
    subtasks:
      - step: "6 シナリオの全存在確認"
        executor: claudecode
        criteria: "grep で 6行マッチ"
        status: "[x]"

  - id: t12
    name: "critic 呼び出し準備"
    status: "done"
    subtasks:
      - step: "done_criteria の検証可能性を最終確認"
        executor: claudecode
        criteria: "critic が評価可能な done_criteria で記述"
        status: "[x]"
      - step: "critic を呼び出して PASS を取得"
        executor: claudecode
        criteria: "critic が PASS を返す"
        status: "[x]"
```

