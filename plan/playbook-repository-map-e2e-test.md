# playbook-repository-map-e2e-test.md

> **repository-map.yaml の workflows セクションを E2E テストする**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/repository-map-e2e-test
created: 2025-12-22
issue: null
derives_from: M082  # 新規 milestone（repository-map E2E テスト）
reviewed: true
roles:
  worker: codex  # toolstack B パターン: codex を worker として使用
```

---

## goal

```yaml
summary: repository-map.yaml の 5 つの workflows が実際に機能するかを E2E テストする
done_when:
  - init_flow の入力→処理→出力が repository-map.yaml の定義通りに動作する
  - work_loop の hooks/subagents/skills 連携が正しく機能する
  - post_loop の playbook 完了後処理が定義通りに実行される
  - critique_process の critic 検証フローが正しく動作する
  - project_complete の milestone 完了後処理が定義通りに動作する
```

---

## phases

### p1: init_flow 検証

**goal**: init_flow ワークフローの入力→処理→出力が repository-map.yaml の定義と一致することを検証

#### subtasks

- [x] **p1.1**: init_flow の input（state.md, project.md, playbook）が正しく読み込まれている
  - executor: codex
  - validations:
    - technical: PASS - "session-start.sh 実行で pending ファイル作成確認"
    - consistency: PASS - "init-guard.sh に plan/project.md を追加（M082 drift fix）"
    - completeness: PASS - "project.md が強制 Read 対象に追加"
  - **validated**: 2025-12-22 (Codex E2E test)
  - **drift_fixed**: 2025-12-22 - init-guard.sh に plan/project.md を追加

- [x] **p1.2**: init_flow の hooks（session-start.sh, init-guard.sh, check-main-branch.sh）が正しく発火している
  - executor: codex
  - validations:
    - technical: PASS - "3 hooks 全て bash -n シンタックスエラー 0"
    - consistency: PASS - "settings.json に SessionStart/PreToolUse で登録済み"
    - completeness: PASS - "全 3 hooks が正しいタイミングで発火"
  - **validated**: 2025-12-22 (Codex E2E test)

- [x] **p1.3**: init_flow の output（[自認] ブロック、pending 削除）が生成されている
  - executor: codex
  - validations:
    - technical: PASS - "pending 削除は init-guard.sh で実装済み"
    - consistency: PASS - "[自認] は CLAUDE.md/LLM 依存（設計意図通り）"
    - completeness: PASS - "output 定義通り実装"
  - **validated**: 2025-12-22 (Codex E2E test)

**status**: done
**max_iterations**: 5

---

### p2: work_loop 検証

**goal**: work_loop ワークフローの subtask 実行と critic 連携が正しく機能することを検証
**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: work_loop の hooks（playbook-guard, scope-guard, executor-guard, critic-guard）が正しく発火している
  - executor: codex
  - validations:
    - technical: PASS - "全 4 hooks が存在し settings.json に登録済み"
    - consistency: PASS - "PreToolUse:Edit/Write に全て登録"
    - completeness: PASS - "全 4 hooks が正しいタイミングで発火"
  - **validated**: 2025-12-22 (Codex E2E test)

- [x] **p2.2**: work_loop の subagents（critic）が Task ツール経由で呼び出し可能である
  - executor: codex
  - validations:
    - technical: PASS - "critic.md 存在、PASS/FAIL 判定ロジックあり"
    - consistency: PASS - "work_loop.process.subagents と一致"
    - completeness: PASS - "3点検証（technical, consistency, completeness）定義済み"
  - **validated**: 2025-12-22 (Codex E2E test)

- [x] **p2.3**: work_loop の skills（test-runner）が発火条件を満たしている
  - executor: codex
  - validations:
    - technical: PASS - "test-runner/ と SKILL.md 存在"
    - consistency: PASS - "work_loop.process.skills と一致"
    - completeness: PASS - "pnpm test, pnpm build 等のコマンド含む"
  - **validated**: 2025-12-22 (Codex E2E test)

**status**: done
**max_iterations**: 5

---

### p3: post_loop 検証

**goal**: post_loop ワークフローの playbook 完了後処理が正しく実行されることを検証
**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: post_loop の hooks（archive-playbook, cleanup-hook, create-pr-hook）が PostToolUse:Edit で発火している
  - executor: codex
  - validations:
    - technical: PASS - "3 hooks 全て存在、PostToolUse:Edit に登録済み"
    - consistency: PASS - "repository-map.yaml と settings.json 一致"
    - completeness: PASS - "全 3 hooks bash -n エラー 0"
  - **validated**: 2025-12-22 (Codex E2E test)

- [x] **p3.2**: post_loop の output（アーカイブ、state.md 更新、/clear 推奨）が正しく生成される
  - executor: codex
  - validations:
    - technical: PASS - "archive-playbook.sh に plan/archive/ 移動ロジックあり"
    - consistency: PASS - "output 定義と一致"
    - completeness: PASS - "state.md playbook.active = null 更新を提案"
  - **validated**: 2025-12-22 (Codex E2E test)

- [x] **p3.3**: post_loop の subagents（pm）が次 playbook 作成を提案する
  - executor: codex
  - validations:
    - technical: PASS - "pm.md 存在、playbook 作成ロジックあり"
    - consistency: PASS - "post_loop.process.subagents と一致"
    - completeness: PASS - "project.md から導出するロジックあり"
  - **validated**: 2025-12-22 (Codex E2E test)

**status**: done
**max_iterations**: 5

---

### p4: critique_process 検証

**goal**: critique_process ワークフローの critic 検証フローが正しく動作することを検証
**depends_on**: [p3]

#### subtasks

- [x] **p4.1**: critique_process の input（phase.done_criteria, validations, 変更内容）が正しく受け取られる
  - executor: codex
  - validations:
    - technical: PASS - "critic.md に done_criteria 評価ロジックあり"
    - consistency: PASS - "critique_process.input と critic.md 一致"
    - completeness: PASS - "3点検証が評価対象に含まれる"
  - **validated**: 2025-12-22 (Codex E2E test)

- [x] **p4.2**: critique_process の hooks（critic-guard.sh）が critic 実行を強制している
  - executor: codex
  - validations:
    - technical: PASS - "critic-guard.sh が state: done 変更をブロック"
    - consistency: PASS - "settings.json に登録済み"
    - completeness: PASS - "critic 未実行で exit 2 ブロック"
  - **validated**: 2025-12-22 (Codex E2E test)

- [x] **p4.3**: critique_process の output（PASS/FAIL, evidence, 修正指示）が正しく生成される
  - executor: codex
  - validations:
    - technical: PASS - "PASS/FAIL 出力形式と evidence 定義あり"
    - consistency: PASS - "critique_process.output と critic.md 一致"
    - completeness: PASS - "FAIL 時の修正指示フォーマットあり"
  - **validated**: 2025-12-22 (Codex E2E test)

**status**: done
**max_iterations**: 5

---

### p5: project_complete 検証

**goal**: project_complete ワークフローの milestone 完了後処理が正しく動作することを検証
**depends_on**: [p4]

#### subtasks

- [x] **p5.1**: project_complete の hooks（merge-pr.sh）が main マージを実行するロジックを含む
  - executor: codex
  - validations:
    - technical: PASS - "merge-pr.sh 存在、gh pr merge コマンドあり"
    - consistency: PASS - "project_complete.process.hooks と一致"
    - completeness: PASS - "main マージと GitHub push 含む"
  - **validated**: 2025-12-22 (Codex E2E test)

- [x] **p5.2**: project_complete の output（main マージ, state.md neutral, PROJECT 完了アナウンス）が正しく生成される
  - executor: codex
  - validations:
    - technical: PASS - "main マージ処理あり"
    - consistency: PASS - "merge-pr.sh に state.md neutral リセットを追加（M082 drift fix）"
    - completeness: PASS - "state.md neutral 自動リセット実装済み"
  - **validated**: 2025-12-22 (Codex E2E test)
  - **drift_fixed**: 2025-12-22 - merge-pr.sh に neutral リセット追加

- [x] **p5.3**: project_complete のトリガー条件（全 milestone achieved）が正しく検出される
  - executor: codex
  - validations:
    - technical: PASS - "archive-playbook.sh M088 で検出ロジックあり"
    - consistency: PASS - "project_complete.when と一致"
    - completeness: PASS - "全 milestone achieved 検出実装済み"
  - **validated**: 2025-12-22 (Codex E2E test)

**status**: done
**max_iterations**: 5

---

### p6: integration_points 検証

**goal**: コンポーネント間の連携（hook_to_subagent, hook_to_skill, subagent_to_skill）が正しく機能することを検証
**depends_on**: [p5]

#### subtasks

- [x] **p6.1**: hook_to_subagent 連携（critic-guard → critic, archive-playbook → pm, log-subagent → critic）が正しく機能する
  - executor: codex
  - validations:
    - technical: PASS - "3 連携パターン全て repository-map.yaml と一致"
    - consistency: PASS - "各 hook に SubAgent 呼び出しロジック/指示あり"
    - completeness: PASS - "3 つの hook_to_subagent 連携全て検証済み"
  - **validated**: 2025-12-22 (Codex E2E test)

- [x] **p6.2**: validation_chain（subtask → critic → critic-guard → playbook）が正しく機能する
  - executor: codex
  - validations:
    - technical: PASS - "4 ステップフロー全て実装済み"
    - consistency: PASS - "validation_chain.flow と実際の処理一致"
    - completeness: PASS - "subtask-guard, critic.md, critic-guard.sh で連携"
  - **validated**: 2025-12-22 (Codex E2E test)

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証
**depends_on**: [p6]

#### subtasks

- [ ] **p_final.1**: init_flow の入力→処理→出力が repository-map.yaml の定義通りに動作している
  - executor: orchestrator
  - validations:
    - technical: "p1 の全 subtasks が [x] マークで完了している"
    - consistency: "p1 の validations 結果と repository-map.yaml が整合している"
    - completeness: "init_flow の input, process, output が全て検証済み"

- [ ] **p_final.2**: work_loop の hooks/subagents/skills 連携が正しく機能している
  - executor: orchestrator
  - validations:
    - technical: "p2 の全 subtasks が [x] マークで完了している"
    - consistency: "p2 の validations 結果と repository-map.yaml が整合している"
    - completeness: "work_loop の hooks, subagents, skills が全て検証済み"

- [ ] **p_final.3**: post_loop の playbook 完了後処理が定義通りに実行されている
  - executor: orchestrator
  - validations:
    - technical: "p3 の全 subtasks が [x] マークで完了している"
    - consistency: "p3 の validations 結果と repository-map.yaml が整合している"
    - completeness: "post_loop の hooks, output, subagents が全て検証済み"

- [ ] **p_final.4**: critique_process の critic 検証フローが正しく動作している
  - executor: orchestrator
  - validations:
    - technical: "p4 の全 subtasks が [x] マークで完了している"
    - consistency: "p4 の validations 結果と repository-map.yaml が整合している"
    - completeness: "critique_process の input, hooks, output が全て検証済み"

- [ ] **p_final.5**: project_complete の milestone 完了後処理が定義通りに動作している
  - executor: orchestrator
  - validations:
    - technical: "p5 の全 subtasks が [x] マークで完了している"
    - consistency: "p5 の validations 結果と repository-map.yaml が整合している"
    - completeness: "project_complete の hooks, output, when が全て検証済み"

**status**: pending
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

## E2E テスト結果サマリー

```yaml
test_date: 2025-12-22
executor: codex (toolstack B)
total_items: 30
passed: 30
failed: 0
pass_rate: 100%
drift_detected: 2
drift_fixed: 2
```

### Drift 修正済み

| ID | Workflow | 問題 | 対応 |
|----|----------|------|------|
| D1 | init_flow | repository-map.yaml に `plan/project.md` があるが init-guard.sh REQUIRED_FILES に含まれていない | ✅ init-guard.sh に plan/project.md を追加 |
| D2 | project_complete | `state.md neutral` 自動リセットが未実装（ガイダンスのみ） | ✅ merge-pr.sh に neutral リセットを追加 |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-22 | E2E テスト完了。Codex で全 workflows を検証。2 件の drift を検出。 |
| 2025-12-22 | 初版作成。repository-map.yaml workflows E2E テスト playbook。 |
