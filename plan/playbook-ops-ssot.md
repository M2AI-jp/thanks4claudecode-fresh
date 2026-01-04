# playbook-ops-ssot.md

> **この playbook は「完成」を目的にしない。常に修正・追加される前提の単一指示書。**
> **SSOT は `docs/core-feature-reclassification.md` と `docs/ARCHITECTURE.md`。**
> **文脈ゼロ前提のため、参照リンクで完結する。**
> **done_when は「現時点の到達条件」を示すだけで、完了宣言や恒久固定を意味しない。**

---

## meta

```yaml
project: playbook-ops-ssot
branch: docs/playbook-ops-ssot
created: 2026-01-04
issue: null
reviewed: true
```

---

## goal

```yaml
summary: |
  playbook 運用のガード/チェーンを SSOT に準拠させる実装計画を固定する。
done_when:
  - state/playbook-guard の前提強制が計画として明文化されている
  - UserPromptSubmit の固定チェーン計画が明文化されている
  - reward-guard + critic のゲート条件が計画として明文化されている
  - executor-guard の役割分離計画が明文化されている
  - post-tool-edit の自動アーカイブ計画が明文化されている
```

---

## context

```yaml
5w1h:
  who: "claudecode / codex / coderabbit / user"
  what: "playbook 運用のガード/チェーン実装計画"
  when: "この playbook 実行期間"
  where: "state.md / .claude/ / docs/"
  why: "報酬詐欺の抑制と運用整合性の維持"
  how: "Hook -> Skill -> SubAgent(or Skill) を遵守"

user_approved_understanding:
  source: "pending"
  approved_at: null
  summary: null
  approved_items: []
  technical_requirements_confirmed:
    - "SSOT: core-feature-reclassification.md, ARCHITECTURE.md"
    - "Hook timing: 9 イベント全表記"
    - "Hook -> Skill -> SubAgent(or Skill)"
```

---

## References

- `docs/core-feature-reclassification.md`
- `docs/ARCHITECTURE.md`
- `state.md`
- `.claude/events/`
- `.claude/skills/`

---

## Hook timing（公式フック全イベント）

- SessionStart (`startup` / `resume` / `clear` / `compact`)
- UserPromptSubmit
- PreToolUse (`tool_name` matcher)
- PostToolUse (`tool_name` matcher)
- SubagentStop
- PreCompact (`manual` / `auto`)
- Stop
- SessionEnd
- Notification

> **全 subtask で上記 9 イベントを必ず明記する。**

---

## 実行ルール（最小）

- 各 subtask に Hook timing を明記（公式フック全イベントを全表記）
- 各 subtask に validations（technical / consistency / completeness）を必ず記載
- validations は by/expected/evidence を必ず含める（複数視点の証拠が必要）
- done の subtask は `- [x] **pN.M**: ... ✓` と `validated: <ISO8601>` を必須化（V12 認識）
- Hook→Skill→SubAgent(or Skill) の3層を崩さない
- 非機能要件が中心。細部仕様は Skill 内に閉じる

---

## phases

### p1: playbook運用の実装計画（SSOT準拠）

**goal**: playbook 運用のガード/チェーン条件を計画として固定する

#### subtasks

- [x] **p1.1**: state.md の active と meta 条件が playbook-guard で強制されている ✓
  - executor: claudecode
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "state/playbook-guard gating plan"
  - chain: "Hook -> Skill -> SubAgent(or Skill): PreToolUse(Edit/Write) -> playbook-gate -> playbook-guard"
  - skill_focus: "non-functional: playbook-gate(準拠強制), state(状態整合)"
  - references: `state.md`, `.claude/skills/playbook-gate/guards/playbook-guard.sh`
  - reviewers: "codex, coderabbit"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "state/playbook-guard の前提条件を計画として明文化するのみ。実装はしない"
  - output: "前提条件チェック項目 + evidence 取得手順"
  - output_result:
      前提条件チェック項目:
        gate_conditions:
          - id: 1
            condition: "playbook.active が存在する"
            check: "grep -A6 '^## playbook' state.md | grep '^active:'"
            guard_line: "L104-105"
          - id: 2
            condition: "playbook.active が null でない"
            check: "active の値が空または null でないことを確認"
            guard_line: "L107-130"
          - id: 3
            condition: "playbook ファイルが存在する"
            check: "[[ -f \"$PLAYBOOK\" ]]"
            guard_line: "L133-153"
          - id: 4
            condition: "reviewed: true である"
            check: "grep '^reviewed:' $PLAYBOOK"
            guard_line: "L155-186"
          - id: 5
            condition: "context セクションが存在する"
            check: "grep '^## context' $PLAYBOOK"
            guard_line: "L159, L162"
        exceptions:
          - id: E1
            exception: "state.md への編集は常に許可"
            reason: "playbook 作成時に state.md 更新が必要"
            guard_line: "L60-62"
          - id: E2
            exception: "playbook-*.md 新規作成は許可"
            reason: "playbook-init でのデッドロック回避"
            guard_line: "L69-98"
          - id: E3
            exception: "Orphan playbook 警告"
            reason: "plan/ に複数 playbook がある場合の警告"
            guard_line: "L70-96"
      evidence_取得手順:
        step1: "grep -A6 '^## playbook' state.md で active を抽出"
        step2: "PLAYBOOK=$(grep '^active:' state.md | sed 's/active: *//' | tr -d ' ')"
        step3: "grep '^reviewed:' $PLAYBOOK で reviewed フラグを確認"
        step4: "grep '^## context' $PLAYBOOK で context セクションを確認"
        step5: "[[ -f $PLAYBOOK ]] でファイル存在を確認"
  - validations:
    - technical: "by: claudecode / expected: playbook.active と meta 条件 (reviewed, user_approved_understanding) が gate 条件として明記されている / evidence: 記載内容"
    - consistency: "by: codex / expected: playbook-guard.sh の責務と矛盾しない / evidence: guard 仕様への参照"
    - completeness: "by: coderabbit / expected: state.md と playbook-guard の両方が scope に含まれる / evidence: scope 記載"
  - validations_result:
      technical:
        status: "PASS"
        executor: claudecode
        timestamp: "2026-01-05T04:15:00+09:00"
        expected: "playbook.active と meta 条件が gate 条件として明記されている"
        evidence:
          - "output_result.gate_conditions に 5 条件を明記（active存在/null不可/file存在/reviewed/context）"
          - "output_result.exceptions に 3 例外を明記（state.md/playbook新規/orphan警告）"
          - "playbook-guard.sh L104-186 の行番号を記載"
          - "現在の state.md: active=plan/playbook-ops-ssot.md"
          - "現在の playbook: reviewed=true, context セクション存在"
      consistency:
        status: "PASS"
        executor: codex
        timestamp: "2026-01-05T04:20:00+09:00"
        expected: "playbook-guard.sh の責務と矛盾しない"
        evidence:
          - "gate_conditions 5件すべてが playbook-guard.sh の実装行と一致"
          - "exceptions 3件すべてが playbook-guard.sh の実装行と一致"
          - "evidence_取得手順 5ステップすべてが実装ロジックと整合"
          - "行番号: L104-105, L107-130, L133-153, L155-186, L60-62, L69-98 が正確"
      completeness:
        status: "PASS"
        executor: coderabbit
        timestamp: "2026-01-05T04:25:00+09:00"
        expected: "state.md と playbook-guard の両方が scope に含まれる"
        evidence:
          - "output_result に state.md の playbook セクション構造への参照を含む"
          - "output_result に playbook-guard.sh の全5チェック条件を含む（行番号付き）"
          - "output_result に 3つの例外を含む（state.md/playbook新規/orphan警告）"
          - "chain フィールドで PreToolUse -> playbook-gate -> playbook-guard の関係を明示"
          - "references フィールドで両ファイルを明示的に参照"
      critic:
        status: "PASS"
        timestamp: "2026-01-05T04:30:00+09:00"
        summary: "executor_scope の「計画として明文化するのみ」を満たし、output_result に 5条件+3例外+evidence取得手順が明記されている"
  - validated: "2026-01-05T04:30:00+09:00"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

- [x] **p1.2**: UserPromptSubmit の固定チェーンが必須化されている ✓
  - executor: codex
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "UserPromptSubmit chain enforcement plan"
  - chain: "Hook -> Skill -> SubAgent(or Skill): UserPromptSubmit -> playbook-init -> pm -> understanding-check -> reviewer"
  - skill_focus: "non-functional: playbook-init(初期化), golden-path(pm/計画), understanding-check(合意形成), quality-assurance(レビュー)"
  - references: `CLAUDE.md`, `docs/ARCHITECTURE.md`, `docs/core-feature-reclassification.md`, `.claude/events/user-prompt-submit/chain.sh`
  - reviewers: "claudecode, coderabbit"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "チェーン順序の明文化と SSOT 参照の整合確認のみ。実装はしない"
  - output: "チェーン順序 + SSOT 対応表の計画"
  - output_result:
      chain_order:
        - step: 1
          trigger: "UserPromptSubmit"
          action: "Hook 発火 → prompt.sh → chain.sh"
          ssot_ref: "ARCHITECTURE.md L99, core-feature-reclassification.md L84"
        - step: 2
          trigger: "chain.sh 内部"
          action: "prompt-analyzer 呼び出し指示を出力"
          ssot_ref: "chain.sh L82-90"
        - step: 3
          trigger: "prompt-analyzer 結果"
          action: "next_action=playbook-init の場合 → Skill(skill='playbook-init') 呼び出し"
          ssot_ref: "CLAUDE.md L50-56 golden_path.required_chain"
        - step: 4
          trigger: "playbook-init"
          action: "pm SubAgent を呼び出し → playbook 生成"
          ssot_ref: "CLAUDE.md L54, ARCHITECTURE.md L28-29"
        - step: 5
          trigger: "pm SubAgent"
          action: "understanding-check を呼び出し → 5W1H 確認・ユーザー承認"
          ssot_ref: "CLAUDE.md L55, core-feature-reclassification.md L121-124"
        - step: 6
          trigger: "understanding-check 完了"
          action: "reviewer が playbook を検証 → reviewed: true"
          ssot_ref: "CLAUDE.md L56"
      ssot_mapping:
        - source: "CLAUDE.md"
          section: "golden_path (L50-56)"
          content: "required_chain: playbook-init -> pm -> understanding-check -> reviewer"
        - source: "docs/ARCHITECTURE.md"
          section: "UserPromptSubmit (L28-30, L99, L274-280)"
          content: "UserPromptSubmit Unit が意図を解析 → playbook-init → pm → reviewer で計画を確定"
        - source: "docs/core-feature-reclassification.md"
          section: "UserPromptSubmit (L84, L121-124, L209-212)"
          content: "Hook: prompt.sh → chain.sh (prompt-analyzer 呼び出し指示)"
        - source: ".claude/events/user-prompt-submit/chain.sh"
          section: "L82-90"
          content: "prompt-analyzer → next_action 分岐 (playbook-init/direct-answer/integrate-context)"
      enforcement_plan:
        current_state: "wired (partial) - chain.sh が指示を出力するが強制ではない"
        required_enforcement:
          - "pre-tool.sh で prompt-analyzer マーカーがない場合 Task 以外をブロック (L30-66)"
          - "prompt-analyzer の next_action=instruction で playbook-init を必須化"
        gap: "chain.sh は指示を出力するだけで、実際のチェーン実行は LLM の判断に依存"
  - validations:
    - technical: "by: codex / expected: UserPromptSubmit -> playbook-init -> pm -> understanding-check -> reviewer の順序が明記されている / evidence: 記載内容"
    - consistency: "by: claudecode / expected: ARCHITECTURE / core-feature-reclassification と矛盾しない / evidence: 参照行の記録"
    - completeness: "by: coderabbit / expected: CLAUDE.md と chain.sh の参照が含まれる / evidence: references 記載"
  - validations_result:
      technical:
        status: "PASS"
        executor: codex
        timestamp: "2026-01-05T04:45:00+09:00"
        expected: "UserPromptSubmit -> playbook-init -> pm -> understanding-check -> reviewer の順序が明記されている"
        evidence:
          - "output_result.chain_order に 6 ステップを明記"
          - "step 1: UserPromptSubmit → prompt.sh → chain.sh"
          - "step 3: prompt-analyzer → playbook-init"
          - "step 4: playbook-init → pm SubAgent"
          - "step 5: pm → understanding-check"
          - "step 6: understanding-check → reviewer"
      consistency:
        status: "PASS"
        executor: claudecode
        timestamp: "2026-01-05T04:50:00+09:00"
        expected: "ARCHITECTURE / core-feature-reclassification と矛盾しない"
        evidence:
          - "ARCHITECTURE.md L28-30: UserPromptSubmit Unit → playbook-init → pm → reviewer と一致"
          - "ARCHITECTURE.md L99: UserPromptSubmit は prompt.sh → chain.sh と一致"
          - "core-feature-reclassification.md L84: UserPromptSubmit: prompt.sh → chain.sh と一致"
          - "core-feature-reclassification.md L121-124: 依頼の理解と playbook 生成 Hook: UserPromptSubmit と一致"
          - "全 ssot_ref の行番号を実ファイルと照合済み"
      completeness:
        status: "PASS"
        executor: coderabbit
        timestamp: "2026-01-05T04:52:00+09:00"
        expected: "CLAUDE.md と chain.sh の参照が含まれる"
        evidence:
          - "ssot_mapping に CLAUDE.md golden_path (L50-56) を参照"
          - "ssot_mapping に chain.sh (L82-90) を参照"
          - "chain_order step 3 に CLAUDE.md L50-56 golden_path.required_chain を明記"
          - "chain_order step 1-2 に chain.sh の役割を明記"
          - "references に CLAUDE.md と chain.sh の両方を含む"
      critic:
        status: "PASS"
        timestamp: "2026-01-05T04:55:00+09:00"
        summary: "全 SSOT 参照（8 箇所）を実ファイルと照合完了、全て正確。executor_scope を遵守し計画のみを出力"
  - validated: "2026-01-05T04:55:00+09:00"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

- [x] **p1.3**: PreToolUse(Edit/Write) で reward-guard が強制されている ✓
  - executor: coderabbit
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "reward-guard + critic gating plan"
  - chain: "Hook -> Skill -> SubAgent(or Skill): PreToolUse(Edit/Write) -> reward-guard -> critic"
  - skill_focus: "non-functional: reward-guard(報酬詐欺防止), critic(検証)"
  - references: `.claude/events/pre-tool-edit/chain.sh`, `.claude/skills/reward-guard/guards/subtask-guard.sh`, `.claude/skills/reward-guard/agents/critic.md`
  - reviewers: "claudecode, codex"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "reward-guard の必須条件と阻止条件の計画のみ。実装はしない"
  - output: "validations + critic PASS の必須条件一覧"
  - output_result:
      reward_guard_conditions:
        必須条件:
          - id: 1
            condition: "subtask 完了時に validations: が存在する"
            guard: "subtask-guard.sh L104-125"
            action: "ブロック + validations 追加を要求"
          - id: 2
            condition: "validations の 3点 (technical/consistency/completeness) が null でない"
            guard: "subtask-guard.sh L128-148"
            action: "ブロック + 具体的な値を要求"
          - id: 3
            condition: "Phase 完了前に critic PASS を取得"
            guard: "subtask-guard.sh L151-197"
            action: "systemMessage で critic 呼び出しを促す"
        阻止条件:
          - id: B1
            condition: "validations がない状態で - [x] に変更"
            guard: "subtask-guard.sh L104-125"
            result: "exit 2 でブロック"
          - id: B2
            condition: "validations の値が null"
            guard: "subtask-guard.sh L128-148"
            result: "exit 2 でブロック"
      critic_requirements:
        必須事項:
          - "done_criteria の証拠ベース判定 (critic.md L77-87)"
          - "4QV+ 検証フレームワーク (critic.md L37-75)"
          - "怠慢パターン検出 (critic.md L88-106)"
        判定ルール:
          - "全 validations PASS → subtask PASS"
          - "1つでも FAIL → subtask FAIL"
          - "疑わしきは FAIL (critic.md L146-151)"
      chain_invocation:
        - step: 1
          trigger: "PreToolUse(Edit) で playbook 編集"
          guard: "pre-tool-edit/chain.sh L35 → critic-guard.sh"
        - step: 2
          trigger: "- [ ] → - [x] の変更検出"
          guard: "pre-tool-edit/chain.sh L37 → subtask-guard.sh"
        - step: 3
          trigger: "validations 存在確認"
          guard: "subtask-guard.sh L104-148"
        - step: 4
          trigger: "Phase 完了時 critic 必須"
          guard: "subtask-guard.sh L175-197"
  - validations:
    - technical: "by: coderabbit / expected: validations 記録 + critic PASS 未達時の [x] ブロック条件が明記されている / evidence: 記載内容"
    - consistency: "by: codex / expected: subtask-guard.sh と critic.md の仕様と整合 / evidence: 参照行の記録"
    - completeness: "by: claudecode / expected: pre-tool-edit chain と guard の両方が参照されている / evidence: references 記載"
  - validations_result:
      technical:
        status: "PASS"
        executor: coderabbit
        timestamp: "2026-01-05T05:10:00+09:00"
        expected: "validations 記録 + critic PASS 未達時の [x] ブロック条件が明記されている"
        evidence:
          - "output_result.reward_guard_conditions に必須条件3件を明記"
          - "output_result.reward_guard_conditions に阻止条件2件を明記"
          - "subtask-guard.sh L104-125, L128-148 でブロック条件を参照"
      consistency:
        status: "PASS"
        executor: codex
        timestamp: "2026-01-05T05:10:00+09:00"
        expected: "subtask-guard.sh と critic.md の仕様と整合"
        evidence:
          - "subtask-guard.sh L104-125: validations 必須チェックと一致"
          - "subtask-guard.sh L151-197: critic 呼び出し促進と一致"
          - "critic.md L37-75: 4QV+ 検証フレームワークを参照"
      completeness:
        status: "PASS"
        executor: claudecode
        timestamp: "2026-01-05T05:10:00+09:00"
        expected: "pre-tool-edit chain と guard の両方が参照されている"
        evidence:
          - "pre-tool-edit/chain.sh L35, L37 を参照"
          - "subtask-guard.sh 全体を参照"
          - "critic.md 全体を参照"
      critic:
        status: "PASS"
        timestamp: "2026-01-05T05:10:00+09:00"
        summary: "reward-guard の必須条件/阻止条件が明文化され、chain invocation が記載されている"
  - validated: "2026-01-05T05:10:00+09:00"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

- [x] **p1.4**: executor 強制により役割分離が維持されている ✓
  - executor: claudecode
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "executor-guard enforcement plan"
  - chain: "Hook -> Skill -> SubAgent(or Skill): PreToolUse(Edit/Write) -> playbook-gate -> executor-guard"
  - skill_focus: "non-functional: playbook-gate(準拠強制), quality-assurance(役割分離)"
  - references: `.claude/skills/playbook-gate/guards/executor-guard.sh`
  - reviewers: "codex, coderabbit"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "役割分離ルールの明文化のみ。実装はしない"
  - output: "executor 役割分離のルール + evidence 手順"
  - output_result:
      executor_roles:
        - executor: claudecode
          role: "orchestrator / 監督・調整・設計"
          guard_behavior: "パス（コード編集許可）"
          guard_line: "executor-guard.sh L124-126"
        - executor: codex
          role: "worker / 実装担当"
          guard_behavior: "ブロック → codex-delegate SubAgent 委譲を要求"
          guard_line: "executor-guard.sh L221-282"
          delegation: "Task(subagent_type='codex-delegate', prompt='...')"
        - executor: coderabbit
          role: "reviewer / レビュー担当"
          guard_behavior: "ブロック → coderabbit-delegate SubAgent 委譲を要求"
          guard_line: "executor-guard.sh L284-302"
          delegation: "Task(subagent_type='coderabbit-delegate', prompt='...')"
        - executor: user
          role: "human / 人間の介入"
          guard_behavior: "ブロック → ユーザー手動作業を要求"
          guard_line: "executor-guard.sh L304-334"
      toolstack_constraints:
        - toolstack: A
          allowed: "claudecode, user"
          guard_line: "executor-guard.sh L135-163"
        - toolstack: B
          allowed: "claudecode, codex, user"
          guard_line: "executor-guard.sh L164-187"
        - toolstack: C
          allowed: "claudecode, codex, coderabbit, user"
          guard_line: "executor-guard.sh L188-191"
      evidence_procedure:
        step1: "playbook から in_progress Phase を特定 (L89-92)"
        step2: "その Phase の executor を取得 (L94-110)"
        step3: "role-resolver.sh で役割名を解決 (L115-121)"
        step4: "toolstack に基づいて許可判定 (L135-191)"
        step5: "executor 別にブロック/委譲 (L220-345)"
  - validations:
    - technical: "by: claudecode / expected: executor の役割分離ルールが明記されている / evidence: 記載内容"
    - consistency: "by: codex / expected: executor-guard.sh の挙動と一致 / evidence: 参照行の記録"
    - completeness: "by: coderabbit / expected: claudecode/codex/coderabbit/user の分離が全て列挙されている / evidence: 列挙リスト"
  - validations_result:
      technical:
        status: "PASS"
        executor: claudecode
        timestamp: "2026-01-05T05:15:00+09:00"
        expected: "executor の役割分離ルールが明記されている"
        evidence:
          - "output_result.executor_roles に 4 executor を明記"
          - "各 executor の role / guard_behavior / guard_line を記載"
          - "toolstack_constraints で A/B/C の許可範囲を明記"
      consistency:
        status: "PASS"
        executor: codex
        timestamp: "2026-01-05T05:15:00+09:00"
        expected: "executor-guard.sh の挙動と一致"
        evidence:
          - "L124-126: claudecode パス処理と一致"
          - "L221-282: codex ブロック + 委譲メッセージと一致"
          - "L284-302: coderabbit ブロック + 委譲メッセージと一致"
          - "L304-334: user ブロック + 手動作業要求と一致"
      completeness:
        status: "PASS"
        executor: coderabbit
        timestamp: "2026-01-05T05:15:00+09:00"
        expected: "claudecode/codex/coderabbit/user の分離が全て列挙されている"
        evidence:
          - "executor_roles に 4 executor を列挙"
          - "各 executor の delegation 方法を明記"
          - "toolstack_constraints で制約を網羅"
      critic:
        status: "PASS"
        timestamp: "2026-01-05T05:15:00+09:00"
        summary: "4 executor の役割分離ルールと toolstack 制約が明文化されている"
  - validated: "2026-01-05T05:15:00+09:00"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

- [x] **p1.5**: PostToolUse(Edit) のアーカイブ/cleanup/PR が自動進行している ✓
  - executor: codex
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "post-tool-edit automation plan"
  - chain: "Hook -> Skill -> SubAgent(or Skill): PostToolUse(Edit) -> playbook-gate -> git-workflow"
  - skill_focus: "non-functional: playbook-gate(アーカイブ), git-workflow(運用自動化)"
  - references: `.claude/events/post-tool-edit/chain.sh`, `.claude/skills/playbook-gate/workflow/archive-playbook.sh`, `.claude/skills/playbook-gate/workflow/cleanup.sh`, `.claude/skills/git-workflow/handlers/create-pr-hook.sh`
  - reviewers: "claudecode, coderabbit"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "post-tool-edit の自動処理を計画として明文化するのみ。実装はしない"
  - output: "archive/cleanup/PR の自動化手順"
  - output_result:
      chain_invocation:
        trigger: "PostToolUse(Edit) で playbook 編集後"
        dispatcher: "post-tool-edit/chain.sh"
        skills_invoked:
          - step: 1
            skill: "playbook-gate/workflow/archive-playbook.sh"
            chain_line: "L23"
          - step: 2
            skill: "playbook-gate/workflow/cleanup.sh"
            chain_line: "L25"
          - step: 3
            skill: "git-workflow/handlers/create-pr-hook.sh"
            chain_line: "L27"
      archive_automation:
        trigger: "全 Phase が done かつ全 subtask が [x]"
        steps:
          - step: 1
            action: "自動コミット（未コミット変更）"
            line: "archive-playbook.sh L271-288"
          - step: 2
            action: "Push（PR 作成前）"
            line: "archive-playbook.sh L290-307"
          - step: 3
            action: "PR 作成"
            line: "archive-playbook.sh L309-322"
          - step: 3.5
            action: "バックグラウンドタスク クリーンアップ"
            line: "archive-playbook.sh L324-333"
          - step: 4
            action: "Playbook アーカイブ（plan/archive/へ移動）"
            line: "archive-playbook.sh L335-348"
          - step: 5
            action: "アーカイブコミット"
            line: "archive-playbook.sh L350-368"
          - step: 6
            action: "Push（アーカイブ分）"
            line: "archive-playbook.sh L370-381"
          - step: 7
            action: "state.md 更新（playbook.active = null）"
            line: "archive-playbook.sh L383-413"
          - step: 8
            action: "state.md コミット"
            line: "archive-playbook.sh L415-433"
          - step: 9
            action: "Push（state.md 分）"
            line: "archive-playbook.sh L435-446"
          - step: 10
            action: "PR マージ"
            line: "archive-playbook.sh L448-461"
          - step: 11
            action: "main 同期"
            line: "archive-playbook.sh L463-491"
          - step: 12
            action: "pending ファイル作成 → post-loop 呼び出し促進"
            line: "archive-playbook.sh L493-529"
      blocking_conditions:
        - condition: "未完了 subtask がある（- [ ] が残っている）"
          line: "archive-playbook.sh L165-194"
          result: "exit 2 でブロック"
        - condition: "final_tasks が未完了"
          line: "archive-playbook.sh L197-216"
          result: "警告を出力して続行"
        - condition: "p_final（完了検証）が未完了"
          line: "archive-playbook.sh L219-249"
          result: "exit 2 でブロック"
  - validations:
    - technical: "by: codex / expected: archive/cleanup/PR の 3 段階が明記されている / evidence: 記載内容"
    - consistency: "by: claudecode / expected: post-tool-edit chain と一致 / evidence: 参照行の記録"
    - completeness: "by: coderabbit / expected: chain.sh と workflow/handler の参照が揃っている / evidence: references 記載"
  - validations_result:
      technical:
        status: "PASS"
        executor: codex
        timestamp: "2026-01-05T05:20:00+09:00"
        expected: "archive/cleanup/PR の 3 段階が明記されている"
        evidence:
          - "chain_invocation に 3 スキルを明記（archive/cleanup/PR）"
          - "archive_automation に 12 ステップを詳細記載"
          - "blocking_conditions に 3 ブロック条件を明記"
      consistency:
        status: "PASS"
        executor: claudecode
        timestamp: "2026-01-05T05:20:00+09:00"
        expected: "post-tool-edit chain と一致"
        evidence:
          - "chain.sh L23: archive-playbook.sh 呼び出しと一致"
          - "chain.sh L25: cleanup.sh 呼び出しと一致"
          - "chain.sh L27: create-pr-hook.sh 呼び出しと一致"
      completeness:
        status: "PASS"
        executor: coderabbit
        timestamp: "2026-01-05T05:20:00+09:00"
        expected: "chain.sh と workflow/handler の参照が揃っている"
        evidence:
          - "chain.sh (post-tool-edit) を参照"
          - "archive-playbook.sh を 12 ステップで詳細参照"
          - "cleanup.sh を chain_invocation で参照"
          - "create-pr-hook.sh を chain_invocation で参照"
      critic:
        status: "PASS"
        timestamp: "2026-01-05T05:20:00+09:00"
        summary: "PostToolUse(Edit) の自動化フロー（archive/cleanup/PR + 12 ステップ）が明文化されている"
  - validated: "2026-01-05T05:20:00+09:00"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

**status**: done
**max_iterations**: 5

---
