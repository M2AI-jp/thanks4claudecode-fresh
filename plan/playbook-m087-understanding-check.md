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

- [ ] **p1.1**: .claude/skills/understanding-check/instructions.md が存在する
  - executor: orchestrator
  - validations:
    - technical: "test -f .claude/skills/understanding-check/instructions.md で確認"
    - consistency: "他の Skill（state, plan-management）と同じ構造であることを確認"
    - completeness: "5W1H フレームワーク、リスク分析、done_when セクションが含まれている"

- [ ] **p1.2**: instructions.md に 5W1H テンプレートが定義されている
  - executor: orchestrator
  - validations:
    - technical: "grep で What/Why/Who/When/Where/How の 6 項目を確認"
    - consistency: "ユーザー提供の新形式と一致している"
    - completeness: "リスク分析セクション、不明点セクション、done_when セクションが含まれている"

**status**: done
**max_iterations**: 5

---

### p2: pm.md への理解確認統合

**goal**: pm.md の playbook 作成フローに理解確認呼び出しを追加する
**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: pm.md の playbook 作成フローに「Step 0.5: 理解確認」が追加されている
  - executor: orchestrator
  - validations:
    - technical: "grep で '理解確認' と 'Skill' の両方が pm.md に存在することを確認"
    - consistency: "既存の playbook 作成フロー（Step 0-11）と整合している"
    - completeness: "理解確認 → ユーザー承認 → playbook 作成の順序が明示されている"

- [ ] **p2.2**: pm.md に「理解確認は playbook 作成前必須」のルールが明記されている
  - executor: orchestrator
  - validations:
    - technical: "grep で '必須' と '理解確認' が同一ブロックに存在することを確認"
    - consistency: "CLAUDE.md Core Contract と整合している"
    - completeness: "スキップ禁止のルールが明示されている"

**status**: done
**max_iterations**: 5

---

### p3: project.md スキーマ定義

**goal**: project.md の新形式スキーマを .claude/schema/project-schema.md に定義する
**depends_on**: [p1]

#### subtasks

- [ ] **p3.1**: .claude/schema/project-schema.md が存在する
  - executor: orchestrator
  - validations:
    - technical: "test -f .claude/schema/project-schema.md で確認"
    - consistency: ".claude/schema/ ディレクトリ構造と整合している"
    - completeness: "スキーマ定義として必要な要素（フィールド、型、必須/任意）が含まれている"

- [ ] **p3.2**: スキーマに vision + active_milestones + constraints + focus_areas が定義されている
  - executor: orchestrator
  - validations:
    - technical: "grep で vision, active_milestones, constraints, focus_areas が存在することを確認"
    - consistency: "ユーザー提供の新形式と一致している"
    - completeness: "各フィールドの説明と制約（例: active_milestones 最大5件）が含まれている"

- [ ] **p3.3**: スキーマに achieved milestone の summary 1行圧縮ルールが定義されている
  - executor: orchestrator
  - validations:
    - technical: "grep で 'summary' と '1行' または '圧縮' が存在することを確認"
    - consistency: "project.md 肥大化防止の目的と整合している"
    - completeness: "圧縮形式のサンプルが含まれている"

**status**: done
**max_iterations**: 5

---

### p4: 長期 goal 保護システム

**goal**: prompt-guard.sh と pre-compact.sh に vision.goal 保護を追加する
**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: prompt-guard.sh が vision.goal を systemMessage に注入している
  - executor: orchestrator
  - validations:
    - technical: "grep で 'vision' または 'goal' が State Injection セクションに存在することを確認"
    - consistency: "既存の SI_PROJECT_GOAL 処理と整合している"
    - completeness: "vision.goal が常に表示されることを確認"

- [ ] **p4.2**: pre-compact.sh が vision.goal を additionalContext に含めている
  - executor: orchestrator
  - validations:
    - technical: "grep で 'vision' または 'goal' が additionalContext 構築部分に存在することを確認"
    - consistency: "既存の compact 前状態保存と整合している"
    - completeness: "compact 後も vision.goal が復元可能であることを確認"

**status**: done
**max_iterations**: 5

---

### p5: 動作検証

**goal**: 理解確認 → playbook 作成フローの E2E 動作を確認する
**depends_on**: [p2, p4]

#### subtasks

- [ ] **p5.1**: pm SubAgent が理解確認 Skill を参照できる
  - executor: orchestrator
  - validations:
    - technical: "pm.md の skills フィールドに understanding-check が含まれている"
    - consistency: "SubAgent の skills 参照形式と整合している"
    - completeness: "pm.md の更新が完了している"

- [ ] **p5.2**: prompt-guard.sh が vision.goal を出力する
  - executor: orchestrator
  - validations:
    - technical: "bash .claude/hooks/prompt-guard.sh を実行し vision が出力されることを確認"
    - consistency: "State Injection フォーマットと整合している"
    - completeness: "vision.goal が SI_MESSAGE に含まれている"

- [ ] **p5.3**: pre-compact.sh が vision.goal を保護する
  - executor: orchestrator
  - validations:
    - technical: "bash .claude/hooks/pre-compact.sh を実行し vision が additionalContext に含まれることを確認"
    - consistency: "snapshot.json フォーマットと整合している"
    - completeness: "vision.goal が snapshot に含まれている"

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証
**depends_on**: [p5]

#### subtasks

- [ ] **p_final.1**: .claude/skills/understanding-check/ に Skill が存在する
  - executor: orchestrator
  - validations:
    - technical: "test -d .claude/skills/understanding-check && test -f .claude/skills/understanding-check/instructions.md で確認"
    - consistency: "他の Skill と同じ構造であることを確認"
    - completeness: "5W1H テンプレートが完全に含まれている"

- [ ] **p_final.2**: pm.md に理解確認呼び出しが統合されている
  - executor: orchestrator
  - validations:
    - technical: "grep -q '理解確認' .claude/agents/pm.md && grep -q 'understanding-check' .claude/agents/pm.md で確認"
    - consistency: "playbook 作成フローと整合している"
    - completeness: "呼び出しタイミングが明示されている"

- [ ] **p_final.3**: project.md のスキーマが .claude/schema/project-schema.md に定義されている
  - executor: orchestrator
  - validations:
    - technical: "test -f .claude/schema/project-schema.md && wc -l で 50 行以上あることを確認"
    - consistency: "ユーザー提供の新形式と一致している"
    - completeness: "全フィールドの説明が含まれている"

- [ ] **p_final.4**: prompt-guard.sh が vision.goal を注入している
  - executor: orchestrator
  - validations:
    - technical: "echo '{}' | bash .claude/hooks/prompt-guard.sh 2>/dev/null | grep -q 'goal' で確認"
    - consistency: "State Injection フォーマットと整合している"
    - completeness: "vision.goal が常に出力される"

- [ ] **p_final.5**: pre-compact.sh が vision.goal を保護している
  - executor: orchestrator
  - validations:
    - technical: "echo '{}' | bash .claude/hooks/pre-compact.sh 2>/dev/null | grep -q 'goal' で確認"
    - consistency: "additionalContext フォーマットと整合している"
    - completeness: "compact 後も復元可能である"

- [ ] **p_final.6**: 動作検証で理解確認 → playbook 作成フローが動く
  - executor: orchestrator
  - validations:
    - technical: "pm.md の skills に understanding-check が含まれていることを確認"
    - consistency: "pm SubAgent の実行フローと整合している"
    - completeness: "全コンポーネントが連携して動作する"

**status**: done
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

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
