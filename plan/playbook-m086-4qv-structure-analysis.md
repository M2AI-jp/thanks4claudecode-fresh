# playbook-m086-4qv-structure-analysis.md

> **state.md, project.md, playbook 周りの Hook/SubAgent/Skill 運用を 4QV+ 構成に最適化するための現状分析**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/4qv-structure-analysis
created: 2025-12-23
issue: null
derives_from: M086
reviewed: true
roles:
  worker: claudecode  # 調査・分析タスクのため orchestrator で十分
```

---

## goal

```yaml
summary: Hook/SubAgent/Skill の現状をマッピングし、4QV+ 構成との差分を明確化する

done_when:
  - tmp/analysis-4qv-structure.md に現状マッピング図（テキスト形式）が存在する
  - tmp/analysis-4qv-structure.md に課題リストが 5 項目以上含まれている
  - tmp/analysis-4qv-structure.md に改善の方向性案が記載されている
  - 仮想シナリオ「ChatGPT アプリを作る」の動線検証結果が含まれている
```

---

## phases

### p1: 現状マッピング

**goal**: state.md, project.md, playbook 関連の Hook/SubAgent/Skill を全て洗い出す

#### subtasks

- [x] **p1.1**: state.md 関連の Hook 一覧が作成されている
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep で 30 Hook が state.md を参照"
    - consistency: "PASS - settings.json の 15 Hook と整合"
    - completeness: "PASS - 全 Hook をスキャン済み"
  - validated: 2025-12-23T17:30:00

- [x] **p1.2**: project.md 関連の Hook 一覧が作成されている
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep で 8 Hook が project.md を参照"
    - consistency: "PASS - init-guard, scope-guard, cleanup-hook 等を確認"
    - completeness: "PASS - 関連 Hook が網羅されている"
  - validated: 2025-12-23T17:30:00

- [x] **p1.3**: playbook 関連の Hook/SubAgent 一覧が作成されている
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep で 28 Hook が playbook を参照"
    - consistency: "PASS - pm.md, reviewer.md, critic.md との関連を確認"
    - completeness: "PASS - playbook ライフサイクル全体をカバー"
  - validated: 2025-12-23T17:30:00

- [x] **p1.4**: Skill の役割と呼び出しパターンが整理されている
  - executor: orchestrator
  - validations:
    - technical: "PASS - 8 Skill 全ての概要を整理"
    - consistency: "PASS - SubAgent との紐付けを確認（現状: 連携なし）"
    - completeness: "PASS - 全 Skill をカバー"
  - validated: 2025-12-23T17:30:00

**status**: done
**max_iterations**: 5

---

### p2: 4QV+ 構成との比較分析

**goal**: 現状と 4QV+ 理想形との差分を明確化
**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: 4QV+ 構成（Hook=導火線、Skill が SubAgent をパッケージ）の定義が明文化されている
  - executor: orchestrator
  - validations:
    - technical: "PASS - tmp/analysis-4qv-structure.md セクション 3.1 に定義"
    - consistency: "PASS - docs/ai-orchestration.md との整合確認"
    - completeness: "PASS - Hook/Skill/SubAgent の役割分担が明確"
  - validated: 2025-12-23T17:30:00

- [x] **p2.2**: 現状が 4QV+ に沿っているか/外れているかの評価表が作成されている
  - executor: orchestrator
  - validations:
    - technical: "PASS - セクション 3.2 に評価表あり"
    - consistency: "PASS - p1 のマッピング結果を参照"
    - completeness: "PASS - 4観点で評価"
  - validated: 2025-12-23T17:30:00

- [x] **p2.3**: 課題リストが 5 項目以上存在する
  - executor: orchestrator
  - validations:
    - technical: "PASS - 7 課題を列挙（セクション 4）"
    - consistency: "PASS - 4QV+ との差分に基づく"
    - completeness: "PASS - 重要な課題を網羅"
  - validated: 2025-12-23T17:30:00

**status**: done
**max_iterations**: 5

---

### p3: 仮想シナリオ検証

**goal**: 「ChatGPT アプリを作る」シナリオで動線を検証
**depends_on**: [p1]

#### subtasks

- [x] **p3.1**: 新規ユーザーの初回起動フローが検証されている
  - executor: orchestrator
  - validations:
    - technical: "PASS - セクション 5.1 に動線追跡結果"
    - consistency: "PASS - session-start.sh の動作と一致確認"
    - completeness: "PASS - 期待フロー vs 現状フローを比較"
  - validated: 2025-12-23T17:30:00

- [x] **p3.2**: project.md 作成フローが検証されている
  - executor: orchestrator
  - validations:
    - technical: "PASS - セクション 5.2 に検証結果"
    - consistency: "PASS - pm.md 責務との比較"
    - completeness: "PASS - 自動生成パスがないことを確認"
  - validated: 2025-12-23T17:30:00

- [x] **p3.3**: focus 切り替えフローが検証されている
  - executor: orchestrator
  - validations:
    - technical: "PASS - セクション 5.3 に検証結果"
    - consistency: "PASS - state Skill との比較"
    - completeness: "PASS - ブランチ制御以上の価値がないことを確認"
  - validated: 2025-12-23T17:30:00

- [x] **p3.4**: goal 保護機能の動作が検証されている
  - executor: orchestrator
  - validations:
    - technical: "PASS - セクション 5.4 に検証結果"
    - consistency: "PASS - prompt-guard.sh の State Injection 確認"
    - completeness: "PASS - 短期 goal 保護あり、長期 goal 保護弱い"
  - validated: 2025-12-23T17:30:00

**status**: done
**max_iterations**: 5

---

### p4: 分析レポート作成

**goal**: 分析結果を tmp/analysis-4qv-structure.md に統合
**depends_on**: [p1, p2, p3]

#### subtasks

- [x] **p4.1**: 現状マッピング図がレポートに含まれている
  - executor: orchestrator
  - validations:
    - technical: "PASS - セクション 1 に ASCII マッピング図"
    - consistency: "PASS - p1 の結果と一致"
    - completeness: "PASS - Hook/SubAgent/Skill 全てをカバー"
  - validated: 2025-12-23T17:30:00

- [x] **p4.2**: 課題リストがレポートに含まれている
  - executor: orchestrator
  - validations:
    - technical: "PASS - セクション 4 に 7 課題を列挙"
    - consistency: "PASS - p2 の評価結果と一致"
    - completeness: "PASS - 5 項目以上"
  - validated: 2025-12-23T17:30:00

- [x] **p4.3**: 改善の方向性案がレポートに含まれている
  - executor: orchestrator
  - validations:
    - technical: "PASS - セクション 6 に 4 つの改善案"
    - consistency: "PASS - 4QV+ 構成に向かう方向性"
    - completeness: "PASS - 優先順位が明示されている"
  - validated: 2025-12-23T17:30:00

- [x] **p4.4**: 仮想シナリオ検証結果がレポートに含まれている
  - executor: orchestrator
  - validations:
    - technical: "PASS - セクション 5 に 4 フロー検証"
    - consistency: "PASS - p3 の結果と一致"
    - completeness: "PASS - 問題点と期待フローが対"
  - validated: 2025-12-23T17:30:00

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証（必須）

**goal**: done_when の全項目が実際に満たされているか最終検証
**depends_on**: [p4]

#### subtasks

- [x] **p_final.1**: tmp/analysis-4qv-structure.md が存在し、現状マッピング図を含む
  - executor: orchestrator
  - validations:
    - technical: "PASS - ファイル存在 + grep 'マッピング' 成功"
    - consistency: "PASS - goal.done_when[0] と一致"
    - completeness: "PASS - Hook/SubAgent/Skill の全カテゴリが含まれている"
  - validated: 2025-12-23T17:30:00

- [x] **p_final.2**: 課題リストが 5 項目以上含まれている
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep -c '^### 課題' = 7"
    - consistency: "PASS - goal.done_when[1] と一致"
    - completeness: "PASS - 各課題に詳細説明がある"
  - validated: 2025-12-23T17:30:00

- [x] **p_final.3**: 改善の方向性案が記載されている
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep '改善' 成功"
    - consistency: "PASS - goal.done_when[2] と一致"
    - completeness: "PASS - 4 つの優先順位付き改善案"
  - validated: 2025-12-23T17:30:00

- [x] **p_final.4**: 仮想シナリオ検証結果が含まれている
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep 'ChatGPT' 成功"
    - consistency: "PASS - goal.done_when[3] と一致"
    - completeness: "PASS - 4 つのフロー全てが検証されている"
  - validated: 2025-12-23T17:30:00

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done

- [x] **ft2**: tmp/ 内の一時ファイルを削除する（分析レポートは保持）
  - command: `echo "分析レポートは tmp/analysis-4qv-structure.md に保持"`
  - status: done

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-23 | 初版作成 |
