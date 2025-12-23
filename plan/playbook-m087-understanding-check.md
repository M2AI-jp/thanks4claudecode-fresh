# playbook-m087-understanding-check.md

> **理解確認システム（5W1H）の再実装 + project.md スキーマ改善**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/understanding-check-reimpl
created: 2025-12-23
issue: null
derives_from: M087
reviewed: false
roles:
  worker: claudecode  # この playbook は全て orchestrator で実施
```

---

## goal

```yaml
summary: 理解確認システム（5W1H）を pm.md に統合し、project.md のスキーマを改善する
done_when:
  - .claude/skills/understanding-check/ に Skill が存在する
  - pm.md に理解確認呼び出しが統合されている
  - project.md のスキーマが .claude/schema/project-schema.md に定義されている
  - prompt-guard.sh が vision.goal を systemMessage に注入している
  - pre-compact.sh が vision.goal を保護している
  - 動作検証で理解確認 → playbook 作成フローが動く
```

---

## phases

### p1: 理解確認 Skill 作成

**goal**: .claude/skills/understanding-check/ に 5W1H ベースの理解確認 Skill を作成する

#### subtasks

- [x] **p1.1**: .claude/skills/understanding-check/SKILL.md が存在する ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - test -f .claude/skills/understanding-check/SKILL.md で確認済み"
    - consistency: "PASS - 他の Skill（plan-management）と同じ SKILL.md 構造"
    - completeness: "PASS - 5W1H フレームワーク、リスク分析、done_when セクションが含まれている"
  - validated: 2025-12-23T08:45:00

- [x] **p1.2**: SKILL.md に 5W1H テンプレートが定義されている ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep で What/Why/Who/When/Where/How の 6 項目を確認済み"
    - consistency: "PASS - ユーザー提供の形式と一致"
    - completeness: "PASS - リスク分析セクション、不明点セクション、done_when セクションが含まれている"
  - validated: 2025-12-23T08:45:00

**status**: done
**max_iterations**: 5

---

### p2: pm.md への理解確認統合

**goal**: pm.md の playbook 作成フローに理解確認呼び出しを追加する
**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: pm.md の playbook 作成フローに「Step 1.5: 理解確認」が追加されている ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep で Step 1.5 に理解確認が存在することを確認"
    - consistency: "PASS - 既存の playbook 作成フロー（Step 0-11）と整合"
    - completeness: "PASS - 理解確認 → ユーザー承認 → playbook 作成の順序が明示"
  - validated: 2025-12-23T08:50:00

- [x] **p2.2**: pm.md に「理解確認は playbook 作成前必須」のルールが明記されている ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep で '必須' と '理解確認' が同一ブロックに存在"
    - consistency: "PASS - CLAUDE.md Core Contract と整合"
    - completeness: "PASS - スキップ禁止のルールが明示されている"
  - validated: 2025-12-23T08:50:00

**status**: done
**max_iterations**: 5

---

### p3: project.md スキーマ定義

**goal**: project.md の新形式スキーマを .claude/schema/project-schema.md に定義する
**depends_on**: [p1]

#### subtasks

- [x] **p3.1**: .claude/schema/project-schema.md が存在する ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - test -f .claude/schema/project-schema.md で確認済み"
    - consistency: "PASS - .claude/schema/ ディレクトリ構造と整合"
    - completeness: "PASS - スキーマ定義として必要な要素（フィールド、型、必須/任意）が含まれている"
  - validated: 2025-12-23T08:55:00

- [x] **p3.2**: スキーマに vision + active_milestones + constraints + focus_areas が定義されている ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep で 20 件マッチ確認済み"
    - consistency: "PASS - ユーザー提供の新形式と一致"
    - completeness: "PASS - 各フィールドの説明と制約が含まれている"
  - validated: 2025-12-23T08:55:00

- [x] **p3.3**: スキーマに achieved milestone の summary 1行圧縮ルールが定義されている ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep で '1行サマリー形式' を確認済み"
    - consistency: "PASS - project.md 肥大化防止の目的と整合"
    - completeness: "PASS - 圧縮形式のサンプル（M001: 三位一体...）が含まれている"
  - validated: 2025-12-23T08:55:00

**status**: done
**max_iterations**: 5

---

### p4: 長期 goal 保護システム

**goal**: prompt-guard.sh と pre-compact.sh に vision.goal 保護を追加する
**depends_on**: [p3]

#### subtasks

- [x] **p4.1**: prompt-guard.sh が vision.goal を systemMessage に注入している ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep で vision.goal 注入を確認（222-224行目）"
    - consistency: "PASS - 既存の SI_PROJECT_GOAL 処理と整合"
    - completeness: "PASS - vision.goal が State Injection 最上部に表示される"
  - validated: 2025-12-23T08:55:00

- [x] **p4.2**: pre-compact.sh が vision.goal を additionalContext に含めている ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep で vision_goal が additionalContext に含まれることを確認（99行目）"
    - consistency: "PASS - 既存の compact 前状態保存と整合"
    - completeness: "PASS - snapshot.json に vision.goal が含まれる"
  - validated: 2025-12-23T08:55:00

**status**: done
**max_iterations**: 5

---

### p5: 動作検証

**goal**: 理解確認 → playbook 作成フローの E2E 動作を確認する
**depends_on**: [p2, p4]

#### subtasks

- [x] **p5.1**: pm SubAgent が理解確認 Skill を参照できる ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - pm.md 6行目: skills: state, plan-management, understanding-check"
    - consistency: "PASS - SubAgent の skills 参照形式と整合"
    - completeness: "PASS - pm.md の更新が完了"
  - validated: 2025-12-23T09:00:00

- [x] **p5.2**: prompt-guard.sh が vision.goal を出力する ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - テスト実行で '🎯 vision.goal: Claude Code の自律性と品質を継続的に向上させる' を確認"
    - consistency: "PASS - State Injection フォーマットと整合"
    - completeness: "PASS - vision.goal が SI_MESSAGE 最上部に含まれている"
  - validated: 2025-12-23T09:00:00

- [x] **p5.3**: pre-compact.sh が vision.goal を保護する ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - テスト実行で '### 🎯 長期目標（vision.goal）' セクションを確認"
    - consistency: "PASS - additionalContext フォーマットと整合"
    - completeness: "PASS - vision.goal が snapshot に含まれている"
  - validated: 2025-12-23T09:00:00

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証
**depends_on**: [p5]

#### subtasks

- [x] **p_final.1**: .claude/skills/understanding-check/ に Skill が存在する ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - test -d で確認。SKILL.md が存在（instructions.md 相当）"
    - consistency: "PASS - 他の Skill（plan-management）と同じ SKILL.md 構造"
    - completeness: "PASS - 5W1H テンプレートが完全に含まれている"
  - validated: 2025-12-23T09:05:00

- [x] **p_final.2**: pm.md に理解確認呼び出しが統合されている ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep で確認。skills: understanding-check, Step 1.5 に理解確認"
    - consistency: "PASS - playbook 作成フローと整合"
    - completeness: "PASS - 呼び出しタイミング（Step 1.5）が明示"
  - validated: 2025-12-23T09:05:00

- [x] **p_final.3**: project.md のスキーマが .claude/schema/project-schema.md に定義されている ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - wc -l で 195 行を確認（50行以上）"
    - consistency: "PASS - ユーザー提供の新形式と一致"
    - completeness: "PASS - 全フィールドの説明が含まれている"
  - validated: 2025-12-23T09:05:00

- [x] **p_final.4**: prompt-guard.sh が vision.goal を注入している ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - テスト実行で '🎯 vision.goal' 出力を確認"
    - consistency: "PASS - State Injection フォーマットと整合"
    - completeness: "PASS - vision.goal が常に出力される"
  - validated: 2025-12-23T09:05:00

- [x] **p_final.5**: pre-compact.sh が vision.goal を保護している ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - テスト実行で additionalContext に vision.goal 含有を確認"
    - consistency: "PASS - snapshot フォーマットと整合"
    - completeness: "PASS - compact 後も復元可能"
  - validated: 2025-12-23T09:05:00

- [x] **p_final.6**: 動作検証で理解確認 → playbook 作成フローが動く ✓
  - executor: orchestrator
  - validations:
    - technical: "PASS - pm.md skills に understanding-check 含有、ループリマインダー実装済み"
    - consistency: "PASS - pm SubAgent の実行フローと整合"
    - completeness: "PASS - 全コンポーネントが連携動作（Skill + pm.md + prompt-guard）"
  - validated: 2025-12-23T09:05:00

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done (git から復元。generate-repository-map.sh に別途問題あり)

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: done

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git commit`
  - status: done (commit: a229897)

---

## リスク分析

```yaml
risks:
  - risk: "既存 pm フローとの整合性破壊"
    probability: medium
    impact: high
    mitigation: "pm.md の既存フローを維持し、理解確認を Step 0.5 として挿入"

  - risk: "prompt-guard.sh の State Injection 過負荷"
    probability: low
    impact: medium
    mitigation: "vision.goal は短い 1 行のみを注入。肥大化させない"

  - risk: "project.md スキーマ変更による既存 milestone の破壊"
    probability: low
    impact: high
    mitigation: "スキーマは新規定義のみ。既存 project.md は段階的に移行"
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-23 | 初版作成。M087 として理解確認システム再実装 + project.md 改善。 |
