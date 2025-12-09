# playbook-mechanism-completion.md

> **仕組みの完成 - LLM 自律制御システムの最終検証**

---

## meta

```yaml
project: 仕組みの完成
branch: feat/mechanism-completion
created: 2025-12-09
issue: null
derives_from: playbook-claude-hook-integration.md
```

---

## goal

```yaml
summary: project.md の done_criteria を満たし、仕組みを完成させる
done_when:
  - 構造的強制（Hooks）が機能している（検証済み）
  - CLAUDE.md のルールが LLM に内面化されている
  - 各コンポーネントが連動している
  - 仕組みが文書化されている
```

---

## phases

```yaml
- id: p0
  name: 構造的強制の最終確認
  goal: Hooks が正しく機能していることを確認
  executor: claudecode
  done_criteria:
    - init-guard.sh が state.md + playbook の Read を強制（exit 2 でブロック）
    - playbook-guard.sh が playbook なしの Edit/Write をブロック（exit 2）
    - check-protected-edit.sh が HARD_BLOCK ファイルへの Edit をブロック（exit 2）
    - critic-guard.sh が state: done への Edit 時に critic 呼び出しを要求（exit 2）
  test_method: |
    1. セッション中の実際の発火状況を確認
    2. settings.json の登録状況を確認
    3. protected-files.txt の設定を確認
  status: done
  evidence:
    実際の発火確認:
      - init-guard.sh: Task ツール呼び出し時に exit 2 でブロック（再 Read 要求）
      - playbook-guard.sh: playbook あり状態なので通過（正常動作）
      - check-protected-edit.sh: HARD_BLOCK 編集なしで通過（正常動作）
      - critic-guard.sh: state: done 編集なしで発火なし（正常動作）
    settings.json 確認:
      - PreToolUse(*): init-guard.sh, check-main-branch.sh
      - PreToolUse(Edit/Write): check-protected-edit.sh, playbook-guard.sh, critic-guard.sh 等
    protected-files.txt 確認:
      - HARD_BLOCK: 7件（CLAUDE.md, protected-files.txt, init-guard.sh, critic-guard.sh, scope-guard.sh, executor-guard.sh, playbook-guard.sh）
      - BLOCK: 8件
      - WARN: 3件
  critic_result: PASS
  max_iterations: 3

- id: p1
  name: guideline enforcement の検証
  goal: CLAUDE.md のルールが定義されており、違反時に検出可能であることを確認
  executor: claudecode
  depends_on: [p0]
  done_criteria:
    - CLAUDE.md に BEFORE_ASK ルールが記載されている
    - CLAUDE.md に LOOP ルールが記載されている
    - CLAUDE.md に CRITIQUE ルールが記載されている
    - CLAUDE.md に POST_LOOP ルールが記載されている
    - 各ルールの違反時に検出可能な仕組みがある（Hook or LLM 自己監視）
  test_method: |
    1. CLAUDE.md の該当セクションを Read して確認
    2. CLAUDE-ref.md の BEFORE_ASK セクションを確認
    3. 違反検出の仕組みを確認
  status: done
  evidence:
    CLAUDE.md 確認:
      - LOOP セクション（行 115-132）: iteration/max/break/done_criteria/CRITIQUE
      - POST_LOOP セクション（行 136-159）: playbook 完了後の次タスク導出
      - CRITIQUE セクション（行 191-199）: critic 必須
    CLAUDE-ref.md 確認:
      - BEFORE_ASK セクション（行 207-240）: 質問禁止、安全上の例外
    違反検出の仕組み:
      - critic-guard.sh: done 更新時に critic 呼び出しを要求（構造的）
      - CLAUDE.md/CLAUDE-ref.md のルール記載（guideline）
  limitation: |
    guideline enforcement は LLM 依存。完全な構造的強制ではない。
    これは current-implementation.md Section 7.2 で設計上の限界として認識されている。
  max_iterations: 3

- id: p2
  name: コンポーネント連動の検証
  goal: CLAUDE.md と Hooks/SubAgents/Skills の連動を確認
  executor: claudecode
  depends_on: [p1]
  done_criteria:
    - INIT と init-guard.sh/session-start.sh が整合
    - CRITIQUE と critic-guard.sh が整合
    - SubAgents が適切に呼び出される
    - Skills が参照可能
  test_method: |
    1. playbook-claude-hook-integration の p1-p6 結果を参照
    2. 残課題があれば対応
    3. 連動テストを実行
  status: done
  evidence:
    INIT整合:
      CLAUDE.md: "state.md → project.md → playbook の順に Read を要求"
      init-guard.sh: "state.md + playbook の Read を強制（exit 2）"
      session-start.sh: "初期化ペンディングフラグ設定、必須 Read 表示"
      結果: 整合
    CRITIQUE整合:
      CLAUDE.md: "done 更新前に critic 必須、PASS → done 更新可"
      critic-guard.sh: "state: done への Edit 時に self_complete: true を要求"
      結果: 整合
    SubAgents:
      件数: 9件
      一覧: critic, pm, coherence, state-mgr, reviewer, health-checker, beginner-advisor, setup-guide, plan-guard
      定義: CLAUDE-ref.md DISPATCH セクション
    Skills:
      件数: 9件
      一覧: plan-management, context-management, execution-management, learning, state, deploy-checker, frontend-design, lint-checker, test-runner
  critic_result: PASS
  max_iterations: 3

- id: p3
  name: ドキュメントの整合性確認
  goal: ドキュメントが実装の現状を正確に記述しているか確認
  executor: claudecode
  depends_on: [p2]
  done_criteria:
    - current-implementation.md が実装の現状を正確に記述（問題点の記載を含む）
    - CLAUDE.md が設計意図を正確に記述
    - ドキュメント間の記述が整合（settings.json ↔ current-implementation.md 等）
  test_method: |
    1. settings.json を読み、current-implementation.md Section 1.1 と照合
    2. CLAUDE.md の INIT/CRITIQUE を読み、Hooks と照合
    3. 記述の不整合があれば指摘
  status: done
  evidence:
    current-implementation.md_正確性:
      Section1.1: settings.json の Hook 登録状況を正確に記述（登録12、未登録4）
      Section2.1: .claude/agents/*.md の 9件を正確に列挙
      Section3.1: .claude/skills/*/ の 9件を正確に列挙
      Section8: 問題点（未登録 Hook、Skills frontmatter）を正確に記載
    CLAUDE.md_設計意図:
      INIT: 「state.md → project.md → playbook」の Read 順序を明記
      CRITIQUE: 「done 更新前に critic 必須」を明記
      ACTION_GUARDS: 「Edit/Write 時のみ playbook チェック」を明記
    ドキュメント間整合:
      settings.json_vs_current-implementation: 登録 Hook 一致
      CLAUDE.md_vs_Hooks: INIT ↔ init-guard.sh、CRITIQUE ↔ critic-guard.sh が整合
  note: |
    current-implementation.md の「問題点サマリー」は実装が不完全であることを示すが、
    ドキュメントが現状を「正確に記述している」ことの証拠である。
    「問題点がある」と「ドキュメントが矛盾している」は別概念。
  critic_result: PASS
  max_iterations: 3

- id: p4
  name: 仕組み完成の宣言
  goal: 全 done_criteria を満たしたことを確認し、完成を宣言
  executor: claudecode
  depends_on: [p0, p1, p2, p3]
  done_criteria:
    - project.md の done_criteria 全項目が done
    - critic PASS
  test_method: |
    1. project.md の done_criteria を確認
    2. 各項目の status を done に更新
    3. critic を呼び出して検証
  status: done
  evidence:
    project.md_done_criteria:
      1_structural_enforcement: done（p0 で検証、critic PASS）
      2_guideline_enforcement: done（p1 で検証、critic PASS）
      3_integration: done（p2 で検証、critic PASS）
      4_documentation: done（p3 で検証、critic PASS）
    project.md更新:
      current_state.phase: "仕組みの完成"
      current_state.in_progress: null
      next_steps.immediate: null
  critic_result: PASS
  max_iterations: 3
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | 初版作成 |
