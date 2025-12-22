# playbook-workflow-e2e-simulation.md

> **ワークフロー仕様のE2Eテストシミュレーションを作成する playbook**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/workflow-e2e-simulation
created: 2025-12-22
issue: null
derives_from: M082  # 新規 milestone として追加予定
reviewed: true  # reviewer PASS: 2025-12-22
roles:
  worker: claudecode  # この playbook ではドキュメント作成が主なのでclaudecode
```

---

## goal

```yaml
summary: ワークフロー仕様のE2Eテストシミュレーションを作成し、repository-map.yaml に登録されている全機能の仕様が100%正確か検証する

done_when:
  - tmp/workflow-simulation.md が存在し、1000行以上である
  - シミュレーションに INIT フローの対話が含まれている
  - シミュレーションに pm 呼び出し -> playbook 作成の対話が含まれている
  - シミュレーションに reviewer 検証（PASS/FAIL フロー両方）の対話が含まれている
  - シミュレーションに LOOP（Phase 実行、subtask、executor）の対話が含まれている
  - シミュレーションに critic 検証（3点検証、PASS/FAIL）の対話が含まれている
  - シミュレーションに POST_LOOP（アーカイブ、PR作成、milestone更新）の対話が含まれている
  - シナリオが「認証付きアプリ作成」という複数Phase・依存関係ありのタスクである
```

---

## phases

### p1: シナリオ設計

**goal**: シミュレーション用の認証付きアプリシナリオを設計する

#### subtasks

- [x] **p1.1**: シナリオ概要が定義されている
  - executor: orchestrator
  - validations:
    - technical: "シナリオ概要が tmp/workflow-simulation.md の冒頭に記載されている"
    - consistency: "シナリオが「認証付きアプリ」というテーマに沿っている"
    - completeness: "目標、Phase構成、依存関係が明記されている"

- [x] **p1.2**: 架空の playbook 構造が設計されている
  - executor: orchestrator
  - validations:
    - technical: "5つ以上の Phase が定義されている"
    - consistency: "Phase 間に depends_on が適切に設定されている"
    - completeness: "各 Phase に subtasks（criterion + executor + validations）が含まれている"

**status**: done
**max_iterations**: 5

---

### p2: INIT フローシミュレーション

**goal**: セッション開始からの自己認識フローを再現する
**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: SessionStart Hook の発火が記録されている
  - executor: orchestrator
  - validations:
    - technical: "session-start.sh の出力形式が再現されている"
    - consistency: "state.md の読み込みが含まれている"
    - completeness: "pending ファイル作成・削除フローが含まれている"

- [x] **p2.2**: [自認] 出力が含まれている
  - executor: orchestrator
  - validations:
    - technical: "[自認] ブロックが対話形式で出力されている"
    - consistency: "what, milestone, phase, branch 等の必須項目が含まれている"
    - completeness: "CLAUDE.md INIT セクションの仕様に準拠している"

- [x] **p2.3**: init-guard.sh の動作が記録されている
  - executor: orchestrator
  - validations:
    - technical: "必須ファイル Read 強制の動作が再現されている"
    - consistency: "state.md, project.md, playbook の Read が含まれている"
    - completeness: "Read 前に Edit/Write がブロックされるシナリオが含まれている"

**status**: done
**max_iterations**: 5

---

### p3: pm 呼び出し -> playbook 作成シミュレーション

**goal**: pm SubAgent による playbook 作成フローを再現する
**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: pm 呼び出しトリガーが記録されている
  - executor: orchestrator
  - validations:
    - technical: "playbook=null 検出 -> pm 呼び出しの流れが再現されている"
    - consistency: "Golden Path ルール（CLAUDE.md Section 11）に準拠している"
    - completeness: "/task-start コマンド発火が含まれている"

- [x] **p3.2**: project.md 参照と derives_from 設定が記録されている
  - executor: orchestrator
  - validations:
    - technical: "project.md の milestone 確認が含まれている"
    - consistency: "derives_from が適切な milestone ID に設定されている"
    - completeness: "not_achieved 分析、depends_on 解決が含まれている"

- [x] **p3.3**: playbook ドラフト作成が記録されている
  - executor: orchestrator
  - validations:
    - technical: "plan/template/playbook-format.md 参照が含まれている"
    - consistency: "V12 チェックボックス形式で subtasks が定義されている"
    - completeness: "meta, goal, phases, p_final, final_tasks が含まれている"

**status**: done
**max_iterations**: 5

---

### p4: reviewer 検証シミュレーション

**goal**: playbook レビューの PASS/FAIL 両方のフローを再現する
**depends_on**: [p3]

#### subtasks

- [x] **p4.1**: reviewer 呼び出しが記録されている
  - executor: orchestrator
  - validations:
    - technical: "Task(subagent_type=reviewer) の呼び出しが含まれている"
    - consistency: "pm.md の reviewer 連携セクションに準拠している"
    - completeness: "playbook ファイルパスが引数として渡されている"

- [x] **p4.2**: reviewer FAIL -> 修正 -> 再レビューのフローが記録されている
  - executor: orchestrator
  - validations:
    - technical: "FAIL 理由と修正案が具体的に記載されている"
    - consistency: "最大リトライ 3回のルールが言及されている"
    - completeness: "修正内容と再レビュー結果が含まれている"

- [x] **p4.3**: reviewer PASS -> playbook 確定のフローが記録されている
  - executor: orchestrator
  - validations:
    - technical: "PASS 判定と確定処理が含まれている"
    - consistency: "reviewed: true への更新が含まれている"
    - completeness: "state.md 更新、ブランチ作成が含まれている"

**status**: done
**max_iterations**: 5

---

### p5: LOOP シミュレーション

**goal**: Phase 実行、subtask、executor の動作を再現する
**depends_on**: [p4]

#### subtasks

- [x] **p5.1**: Phase 実行フローが記録されている
  - executor: orchestrator
  - validations:
    - technical: "pending -> in_progress -> done の状態遷移が含まれている"
    - consistency: "CLAUDE.md LOOP セクションに準拠している"
    - completeness: "複数 Phase の順次実行が含まれている"

- [x] **p5.2**: subtask 実行と validations が記録されている
  - executor: orchestrator
  - validations:
    - technical: "各 subtask の criterion 実行が含まれている"
    - consistency: "V12 チェックボックス形式（- [ ] -> - [x]）の変化が含まれている"
    - completeness: "3点検証（technical, consistency, completeness）の実行が含まれている"

- [x] **p5.3**: executor 別の処理が記録されている
  - executor: orchestrator
  - validations:
    - technical: "claudecode, codex, coderabbit, user の各 executor が登場している"
    - consistency: "executor-guard.sh の動作が再現されている"
    - completeness: "role-resolver.sh による役割解決が含まれている"

- [x] **p5.4**: depends_on による Phase 依存が記録されている
  - executor: orchestrator
  - validations:
    - technical: "depends_on 未完了時のブロックが含まれている"
    - consistency: "depends-check.sh の動作が再現されている"
    - completeness: "依存解決後の実行開始が含まれている"

**status**: done
**max_iterations**: 5

---

### p6: critic 検証シミュレーション

**goal**: critic SubAgent による PASS/FAIL 検証を再現する
**depends_on**: [p5]

#### subtasks

- [x] **p6.1**: critic 呼び出しトリガーが記録されている
  - executor: orchestrator
  - validations:
    - technical: "Phase 完了申告時の critic 呼び出しが含まれている"
    - consistency: "critic-guard.sh の動作が再現されている"
    - completeness: "自己完了申告のブロックが含まれている"

- [x] **p6.2**: validations 3点検証が記録されている
  - executor: orchestrator
  - validations:
    - technical: "technical, consistency, completeness の各項目が評価されている"
    - consistency: "critic.md の出力フォーマットに準拠している"
    - completeness: "各項目に証拠（evidence）が含まれている"

- [x] **p6.3**: critic FAIL -> 修正 -> 再評価のフローが記録されている
  - executor: orchestrator
  - validations:
    - technical: "FAIL 理由と修正指示が具体的に記載されている"
    - consistency: "修正後の再評価フローが含まれている"
    - completeness: "報酬詐欺防止の観点からの評価が含まれている"

- [x] **p6.4**: critic PASS -> Phase 完了のフローが記録されている
  - executor: orchestrator
  - validations:
    - technical: "PASS 判定後の state.md 更新が含まれている"
    - consistency: "phase.status = done への変更が含まれている"
    - completeness: "Phase 完了時の自動コミットが含まれている"

**status**: done
**max_iterations**: 5

---

### p7: POST_LOOP シミュレーション

**goal**: playbook 完了後の自動処理を再現する
**depends_on**: [p6]

#### subtasks

- [x] **p7.1**: archive-playbook.sh の動作が記録されている
  - executor: orchestrator
  - validations:
    - technical: "playbook アーカイブ処理が含まれている"
    - consistency: "plan/archive/ への移動が含まれている"
    - completeness: "final_tasks 完了チェックが含まれている"

- [x] **p7.2**: cleanup-hook.sh の動作が記録されている
  - executor: orchestrator
  - validations:
    - technical: "tmp/ クリーンアップ処理が含まれている"
    - consistency: "docs/folder-management.md のルールに準拠している"
    - completeness: "README.md 保持が含まれている"

- [x] **p7.3**: create-pr-hook.sh の動作が記録されている
  - executor: orchestrator
  - validations:
    - technical: "PR 作成トリガーが含まれている"
    - consistency: "gh pr create コマンド形式が含まれている"
    - completeness: "PR テンプレート（Summary, Test plan）が含まれている"

- [x] **p7.4**: project.md milestone 更新が記録されている
  - executor: orchestrator
  - validations:
    - technical: "milestone.status = achieved への更新が含まれている"
    - consistency: "achieved_at, playbooks[] への追記が含まれている"
    - completeness: "次 milestone の自動特定が含まれている"

- [x] **p7.5**: /clear 推奨アナウンスが記録されている
  - executor: orchestrator
  - validations:
    - technical: "/clear 推奨メッセージが含まれている"
    - consistency: "コンテキスト膨張防止の観点が含まれている"
    - completeness: "Named Sessions への言及が含まれている"

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when の全項目が実際に満たされているか検証する

#### subtasks

- [x] **p_final.1**: tmp/workflow-simulation.md が存在し、1000行以上である
  - executor: orchestrator
  - validations:
    - technical: "test -f tmp/workflow-simulation.md && wc -l で確認"
    - consistency: "ファイルが正常に読み込めることを確認"
    - completeness: "1000行以上の条件を満たしていることを確認"

- [x] **p_final.2**: シミュレーションに INIT フローの対話が含まれている
  - executor: orchestrator
  - validations:
    - technical: "grep で INIT 関連キーワードの存在を確認"
    - consistency: "session-start.sh, init-guard.sh, [自認] が含まれている"
    - completeness: "INIT フローの全ステップが含まれている"

- [x] **p_final.3**: シミュレーションに pm/playbook 作成の対話が含まれている
  - executor: orchestrator
  - validations:
    - technical: "grep で pm, playbook 関連キーワードの存在を確認"
    - consistency: "project.md 参照、derives_from 設定が含まれている"
    - completeness: "playbook 作成の全ステップが含まれている"

- [x] **p_final.4**: シミュレーションに reviewer PASS/FAIL の対話が含まれている
  - executor: orchestrator
  - validations:
    - technical: "grep で reviewer, PASS, FAIL の存在を確認"
    - consistency: "FAIL -> 修正 -> 再レビューのフローが含まれている"
    - completeness: "最終的に PASS となるフローが含まれている"

- [x] **p_final.5**: シミュレーションに LOOP の対話が含まれている
  - executor: orchestrator
  - validations:
    - technical: "grep で Phase, subtask, executor の存在を確認"
    - consistency: "複数 Phase の実行、依存関係処理が含まれている"
    - completeness: "LOOP フローの全ステップが含まれている"

- [x] **p_final.6**: シミュレーションに critic PASS/FAIL の対話が含まれている
  - executor: orchestrator
  - validations:
    - technical: "grep で critic, validations, 3点検証の存在を確認"
    - consistency: "FAIL -> 修正 -> 再評価のフローが含まれている"
    - completeness: "最終的に PASS となるフローが含まれている"

- [x] **p_final.7**: シミュレーションに POST_LOOP の対話が含まれている
  - executor: orchestrator
  - validations:
    - technical: "grep で archive, PR, milestone の存在を確認"
    - consistency: "アーカイブ、クリーンアップ、PR作成、milestone更新が含まれている"
    - completeness: "POST_LOOP フローの全ステップが含まれている"

- [x] **p_final.8**: シナリオが「認証付きアプリ」である
  - executor: orchestrator
  - validations:
    - technical: "grep で 認証, auth, login の存在を確認"
    - consistency: "複数 Phase、依存関係ありの構造である"
    - completeness: "認証に関連する機能（ログイン、サインアップ等）が含まれている"

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done

- [x] **ft2**: tmp/ 内の一時ファイルを確認する（今回は成果物なので削除しない）
  - command: `ls -la tmp/`
  - status: done
  - note: workflow-simulation.md は成果物のため保持

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-22 | 初版作成。ワークフロー E2E シミュレーション playbook。 |
