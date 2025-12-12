# playbook-system-architecture-map.md

> **Hooks/SubAgents/Skills の発火タイミング別一覧と依存関係マップを作成**

---

## meta

```yaml
project: thanks4claudecode
created: 2025-12-13
derives_from: M007
branch: feat/system-architecture-map
reviewed: false
```

---

## goal

```yaml
summary: "リポジトリ内の全 Hooks/SubAgents/Skills を発火タイミング別に整理し、入出力と依存関係を docs/feature-map.md に文書化"

done_when:
  - docs/feature-map.md が存在する
  - 全 Hook（29ファイル）が発火タイミング別に整理されている
  - 各 Hook の入力（stdin JSON）と出力（exit code / stdout）が明示されている
  - SubAgent 一覧（8種類）が記載されている
  - Skill 一覧（13個）とトリガー条件が記載されている
  - ファイル間の依存関係・連携が図解または表で示されている
```

---

## phases

```yaml
- id: p0
  name: "Hook 一覧表の作成"
  goal: "発火タイミング別（SessionStart/PreToolUse/PostToolUse/Stop/PreCompact/UserPromptSubmit/SessionEnd）に Hook を整理"
  executor: claudecode
  subtasks:
    - criterion: "SessionStart Hook が一覧化されている"
      executor: claudecode
      test_command: "grep -q 'SessionStart' docs/feature-map.md"
    - criterion: "PreToolUse Hook（matcher 別）が一覧化されている"
      executor: claudecode
      test_command: "grep -q 'PreToolUse' docs/feature-map.md"
    - criterion: "PostToolUse Hook が一覧化されている"
      executor: claudecode
      test_command: "grep -q 'PostToolUse' docs/feature-map.md"
    - criterion: "各 Hook の入力 JSON 形式と出力が明示されている"
      executor: claudecode
      test_command: "grep -q 'stdin' docs/feature-map.md && grep -q 'exit' docs/feature-map.md"
  status: done

- id: p1
  name: "SubAgent/Skill 一覧の作成"
  goal: "SubAgent と Skill の役割・トリガー・入出力を整理"
  executor: claudecode
  subtasks:
    - criterion: "SubAgent 一覧（pm, critic, plan-guard, reviewer, Explore, setup-guide, health-checker）が記載されている"
      executor: claudecode
      test_command: "grep -q 'pm' docs/feature-map.md && grep -q 'critic' docs/feature-map.md"
    - criterion: "Skill 一覧（13個）とトリガー条件が記載されている"
      executor: claudecode
      test_command: "grep -c 'Skill' docs/feature-map.md | xargs test 5 -lt"
  status: done

- id: p2
  name: "依存関係図と統合"
  goal: "コンポーネント間の連携を図解し、ドキュメントを完成"
  executor: claudecode
  subtasks:
    - criterion: "Hook → SubAgent → Skill の連携フローが図解されている"
      executor: claudecode
      test_command: "grep -q '連携' docs/feature-map.md || grep -q 'フロー' docs/feature-map.md"
    - criterion: "ドキュメントが 100 行以上で完成している"
      executor: claudecode
      test_command: "test -f docs/feature-map.md && [ $(wc -l < docs/feature-map.md) -gt 100 ]"
  status: done
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | 初版作成。M007 対応。 |
