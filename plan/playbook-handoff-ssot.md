# playbook-handoff-ssot.md

> **この playbook は「完成」を目的にしない。常に修正・追加される前提の単一指示書。**
> **SSOT は `docs/core-feature-reclassification.md` と `docs/ARCHITECTURE.md`。**
> **文脈ゼロ前提のため、参照リンクで完結する。**
> **done_when は「現時点の到達条件」を示すだけで、完了宣言や恒久固定を意味しない。**

---

## meta

```yaml
project: ssot-handoff
branch: docs/ssot-handoff
created: 2026-01-05
issue: null
reviewed: true
```

---

## goal

```yaml
summary: |
  SSOT 準拠で Hook Unit を棚卸し→欠落確定→部分ドッグフーディング→漸進統合し、
  ユーザー体験の一本道（依頼→計画→実行→検証→完了）を維持する。
done_when:
  - docs/core-feature-reclassification.md と docs/ARCHITECTURE.md が最新の Hook timing×ファイルマッピングを反映している
  - 欠落コンポーネントの確定リストが SSOT に固定されている
  - Unit 単位のドッグフーディング記録（ログ/状態/コマンド出力）が残っている
  - 漸進統合の配線結果が SSOT と docs/repository-map.yaml に反映されている
  - Decision Log と DRIFT対応の記録が更新されている
```

---

## context

```yaml
5w1h:
  who: "claudecode / codex / coderabbit / user"
  what: "Hook Unit の棚卸し・欠落確定・部分ドッグフーディング・漸進統合"
  when: "この playbook 実行期間"
  where: "docs/, .claude/, plan/, scripts/"
  why: "報酬詐欺抑制とユーザー体験の一本道維持"
  how: "Hook -> Skill -> SubAgent(or Skill) を遵守し、非機能要件中心で進める"

analysis_result:
  source: "manual-handoff"
  timestamp: "2026-01-05"
  data:
    5w1h: "上記 5w1h を一次情報として扱う"
    risks:
      technical:
        - "Stop/Notification telemetry 未配線"
        - "SessionStart health/integrity 配線未完"
        - "UserPromptSubmit 自動チェーン未完"
      scope: []
      dependency: []
    ambiguity: []
    summary:
      confidence: medium
      ready_for_playbook: true
      blocking_issues: []

user_approved_understanding:
  source: "understanding-check"
  approved_at: "2026-01-05"
  summary: "Hook Unit 棚卸し・欠落確定・ドッグフーディング・漸進統合を Hook→Skill→SubAgent 遵守で進める"
  approved_items:
    - "5W1H 分析内容"
    - "Phases 構成（p1-p4 + p_final）"
    - "done_when 5 項目"
  technical_requirements_confirmed:
    - "SSOT: core-feature-reclassification.md, ARCHITECTURE.md"
    - "Hook timing: 9 イベント全表記"
    - "executor: claudecode/codex/coderabbit/user の 4 層"
```

---

## Context Lock

- SSOT: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`
- 構造キャッシュ: `docs/repository-map.yaml`
- 状態の真実: `state.md`（更新は Skill 経由を優先）
- ユーザー体験は「依頼→計画→実行→検証→完了」の一本道で固定
- Hook → Skill → SubAgent(or Skill) の3層を崩さない
- 非機能要件が中心。細部仕様は Skill 内に閉じる
- フェイルセーフ（codex/coderabbit不在時の代替）を記載しない
- この playbook は常に修正・追加される前提（「完成」を宣言しない）

---

## Decision Log

| Date | Decision | Rationale | Evidence | SSOT impact |
|---|---|---|---|---|
| YYYY-MM-DD | (追記) | (理由) | (ログ/コマンド出力) | docs/core-feature-reclassification.md |

---

## DRIFT対応

1. `bash .claude/hooks/generate-repository-map.sh` を実行し `docs/repository-map.yaml` を再生成
2. `docs/repository-map.yaml` と実際の構造差分を確認（ログ/コマンド出力を証拠化）
3. 差分があれば `docs/core-feature-reclassification.md` と `docs/ARCHITECTURE.md` に反映
4. 反映内容を Decision Log に記録
5. `state.md` 更新が必要な場合は Skill 経由で実施

---

## References

- `docs/core-feature-reclassification.md`
- `docs/ARCHITECTURE.md`
- `docs/repository-map.yaml`
- `plan/template/playbook-format.md`
- `plan/template/planning-rules.md`
- `state.md`

---

## 再導入禁止（削除済み）

- docs: `ai-orchestration.md`, `archive-operation-rules.md`, `dogfooding-findings.md`, `folder-management.md`, `git-operations.md`, `repository-health.md`, `criterion-validation-rules.md`
- skills: `term-translator`, `plan-management`, `health-checker`, `setup-guide`
- .claude: `.claude/mcp.json`, `.claude/schema/`, `.claude/frameworks/self-evaluation-defense.md`, `.claude/logs/subagent.log`
- root: `RUNBOOK.md`

---

## 現状の主要構成（短縮）

- docs: `core-feature-reclassification.md`, `ARCHITECTURE.md`, `repository-map.yaml`
- plan: `playbook-fizzbuzz-dogfooding.md`, `template/`
- scripts: `contract.sh`
- .claude: hooks / events / skills / frameworks / settings.json / protected-files.txt / lib
- tmp: `README.md`, `fizzbuzz.py`（要否判断は Phase2 で固定）

---

## 既知の実装ギャップ（SSOT準拠）

- Stop/Notification の telemetry が未配線（no-op）
- SessionStart で health/integrity の明示配線が未完
- UserPromptSubmit が「指示止まり」で自動チェーン化が未完

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

> **全 subtask / 全 prompt で上記 9 イベントを必ず明記する。**

---

## 実行ルール（必須）

- 各 Phase は **4 subtask 固定**（claudecode → codex → coderabbit → user の順）
- toolstack: C（codex + coderabbit）を前提にする
- 各 Phase の user は 1 回のみ
- 各 subtask に Hook timing を明記（公式フック全イベントを全表記）
- 各 subtask に validations（technical / consistency / completeness）を必ず記載
- validations は by/expected/evidence を必ず含める（複数視点の証拠が必要）
- done の subtask は `- [x] **pN.M**: ... ✓` と `validated: <ISO8601>` を必須化（V12 認識）
- 証拠は「ログ/ファイル存在/状態/コマンド出力」で示す（テスト不要）
- subtask/Phase を done にする前に reviewers の evidence と critic SubAgent の PASS を必須とする
- critic は「subtask の validations 記録 → critic 実行 → subtask/phase の done 変更」の順序で運用する
- Hook→Skill→SubAgent(or Skill) の3層を崩さない
- 非機能要件が中心。細部仕様は Skill 内に閉じる

---

## playbook運用の実装計画（SSOT準拠）

- 参照: `plan/playbook-ops-ssot.md`

---

## validations 記録フォーマット（最小）

> **expected/evidence を必ず残す。** 形式は playbook-format に従い、手動で証拠を補う。

```yaml
validations:
  technical: "PASS - by: <role> / expected: <期待結果> / evidence: <実測出力>"
  consistency: "PASS - by: <role> / expected: <整合条件> / evidence: <確認結果>"
  completeness: "PASS - by: <role> / expected: <充足条件> / evidence: <確認結果>"
```

---

## phases

### p1: 現状把握（Hook timing×ファイルマッピングの棚卸し、SSOT更新）

**goal**: Hook timing とファイルマッピングの棚卸し結果を固定し、SSOT 更新範囲を明示する

#### subtasks

- [x] **p1.1**: Hook timing×ファイルマッピングの棚卸しチェックリスト（草案）が作成されている ✓
  - executor: claudecode
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "inventory checklist draft (Hook timing × file mapping headings)"
  - chain: "Hook -> Skill -> SubAgent(or Skill): SessionStart -> session-manager -> quality-assurance (health/integrity)"
  - skill_focus: "non-functional: session-manager(状態整合), quality-assurance(health/integrity), playbook-gate(準拠強制)"
  - references: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`, `docs/repository-map.yaml`
  - reviewers: "codex, coderabbit"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "棚卸し/計画/優先順位の作成のみ。SSOT更新・実装・レビューは行わない"
  - output: "evidence を validations に記録（棚卸し/計画/優先順位の要約）"
  - validations:
    - technical: "PASS - by: claudecode / expected: Hook Timing Index の行番号と .claude/events/ の unit 一覧が記録されている / evidence: rg -n 'Hook Timing Index' docs/core-feature-reclassification.md と ls .claude/events/ の出力ログ"
    - consistency: "PASS - by: codex / expected: 9 events ↔ 10 units の対応表が evidence に記載されている / evidence: 対応表の記載"
    - completeness: "PASS - by: coderabbit / expected: チェックリストの見出しが 9 events を網羅している / evidence: 見出し一覧"
  - validated: 2026-01-04T18:39:30
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

- [ ] **p1.2**: p1.1 のチェックリストに基づく SSOT 更新パッチ（最小差分）が反映されている
  - executor: codex
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "core-feature-reclassification / ARCHITECTURE / repository-map (minimal diff)"
  - chain: "Hook -> Skill -> SubAgent(or Skill): PreToolUse(Edit/Write) -> playbook-gate -> codex-delegate"
  - skill_focus: "non-functional: playbook-gate(準拠強制), reward-guard(報酬詐欺防止), access-control(保護)"
  - references: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`, `docs/repository-map.yaml`
  - reviewers: "claudecode, coderabbit"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "target_unit の編集のみ（新規ファイル禁止/差分最小/範囲外編集禁止）。調査/レビュー/承認は行わない"
  - output: "target_unit 限定の差分（新規ファイルなし）"
  - validations:
    - technical: "by: codex / expected: git diff が上記3ファイルのみに限定されている / evidence: git diff 出力"
    - consistency: "by: claudecode / expected: 差分が p1.1 のチェックリスト項目と対応している / evidence: 差分要約 + チェックリスト参照"
    - completeness: "by: coderabbit / expected: 選定したチェックリスト項目が全て反映されている / evidence: 反映対象一覧"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

- [ ] **p1.3**: SSOT 更新パッチのレビュー結果（summary/findings）が記録されている
  - executor: coderabbit
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "SSOT update diff review"
  - chain: "Hook -> Skill -> SubAgent(or Skill): PreToolUse(Edit/Write) -> quality-assurance -> coderabbit-delegate"
  - skill_focus: "non-functional: quality-assurance(レビュー), reward-guard(critic 強制)"
  - references: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`
  - reviewers: "claudecode, codex"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "差分レビューのみ。修正はしない。summary/findings で出力"
  - output: "review summary + findings（severity/file/line）"
  - validations:
    - technical: "by: coderabbit / expected: coderabbit review --plain の出力が取得されている / evidence: review 出力ログ"
    - consistency: "by: codex / expected: 指摘が差分範囲と一致している / evidence: findings 一覧"
    - completeness: "by: claudecode / expected: summary と findings が揃っている / evidence: review summary + findings"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

- [ ] **p1.4**: 棚卸しチェックリストと SSOT 更新範囲の承認が得られている
  - executor: user
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "inventory checklist + SSOT patch scope"
  - chain: "Hook -> Skill -> SubAgent(or Skill): UserPromptSubmit -> understanding-check -> state (Skill)"
  - skill_focus: "non-functional: understanding-check(合意形成), state(状態整合)"
  - references: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`
  - reviewers: "claudecode, coderabbit"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "承認のみ（チェックリスト回答）。編集/実装/レビューは行わない"
  - output: "承認チェックリストの回答（yes/no）"
  - validations:
    - technical: "by: user / expected: ユーザー承認の回答が記録されている / evidence: 承認コメント/チェックリスト回答"
    - consistency: "by: claudecode / expected: 承認範囲が p1.1/p1.2 の内容と一致している / evidence: 承認文と対象範囲の突合"
    - completeness: "by: coderabbit / expected: 一本道（依頼→計画→実行→検証→完了）の維持を確認 / evidence: 承認内の確認項目"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

**status**: pending
**max_iterations**: 5

---

### p2: 欠落確定（理想フローとの差分を確定、missingコンポーネントを固定）

**goal**: 欠落コンポーネントの確定リストを SSOT に固定し、スコープをロックする

#### subtasks

- [ ] **p2.1**: missing 候補リスト（草案）が作成されている
  - executor: claudecode
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "missing candidates draft"
  - chain: "Hook -> Skill -> SubAgent(or Skill): UserPromptSubmit -> prompt-analyzer -> state (Skill)"
  - skill_focus: "non-functional: prompt-analyzer(依頼理解), state(状態整合), reward-guard(詐欺防止)"
  - references: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`
  - reviewers: "codex, coderabbit"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "棚卸し/計画/優先順位の作成のみ。SSOT更新・実装・レビューは行わない"
  - output: "evidence を validations に記録（棚卸し/計画/優先順位の要約）"
  - validations:
    - technical: "by: claudecode / expected: unit ごとの missing 候補が列挙されている / evidence: 候補リスト"
    - consistency: "by: codex / expected: ideal/current 差分と対応している / evidence: 差分対応メモ"
    - completeness: "by: coderabbit / expected: 既知ギャップ（Stop/Notification/SessionStart/UserPromptSubmit）が含まれている / evidence: 候補リスト内の記載"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

- [ ] **p2.2**: missing 確定リストが SSOT に反映されている
  - executor: codex
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "core-feature-reclassification / ARCHITECTURE (missing list)"
  - chain: "Hook -> Skill -> SubAgent(or Skill): PreToolUse(Edit/Write) -> playbook-gate -> codex-delegate"
  - skill_focus: "non-functional: playbook-gate(準拠強制), reward-guard(報酬詐欺防止)"
  - references: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`
  - reviewers: "claudecode, coderabbit"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "target_unit の編集のみ（新規ファイル禁止/差分最小/範囲外編集禁止）。調査/レビュー/承認は行わない"
  - output: "target_unit 限定の差分（新規ファイルなし）"
  - validations:
    - technical: "by: codex / expected: 差分が docs/core-feature-reclassification.md と docs/ARCHITECTURE.md のみに限定されている / evidence: git diff 出力"
    - consistency: "by: claudecode / expected: missing 表記が理想/現状/欠落の形式に揃っている / evidence: 該当セクションの抜粋"
    - completeness: "by: coderabbit / expected: 全 Hook Unit に missing の有無が明記されている / evidence: unit 別一覧"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

- [ ] **p2.3**: missing 確定リストのレビュー結果が記録されている
  - executor: coderabbit
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "missing list diff review"
  - chain: "Hook -> Skill -> SubAgent(or Skill): PreToolUse(Edit/Write) -> quality-assurance -> coderabbit-delegate"
  - skill_focus: "non-functional: quality-assurance(レビュー), reward-guard(critic 強制)"
  - references: `docs/core-feature-reclassification.md`
  - reviewers: "claudecode, codex"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "差分レビューのみ。修正はしない。summary/findings で出力"
  - output: "review summary + findings（severity/file/line）"
  - validations:
    - technical: "by: coderabbit / expected: coderabbit review --plain の出力が取得されている / evidence: review 出力ログ"
    - consistency: "by: codex / expected: 指摘が missing リストの内容と一致している / evidence: findings 一覧"
    - completeness: "by: claudecode / expected: summary と findings が揃っている / evidence: review summary + findings"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

- [ ] **p2.4**: missing 確定リストと tmp/方針の承認が得られている
  - executor: user
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "missing list approval + tmp policy"
  - chain: "Hook -> Skill -> SubAgent(or Skill): UserPromptSubmit -> understanding-check -> state (Skill)"
  - skill_focus: "non-functional: understanding-check(合意形成), state(状態整合)"
  - references: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`
  - reviewers: "claudecode, coderabbit"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "承認のみ（チェックリスト回答）。編集/実装/レビューは行わない"
  - output: "承認チェックリストの回答（yes/no）"
  - validations:
    - technical: "by: user / expected: ユーザー承認の回答が記録されている / evidence: 承認コメント/チェックリスト回答"
    - consistency: "by: claudecode / expected: 承認内容が missing リストと一致している / evidence: 承認文と missing 対応"
    - completeness: "by: coderabbit / expected: tmp/ (README.md/fizzbuzz.py) の扱いが確定している / evidence: 承認内の明記"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

**status**: pending
**max_iterations**: 5

---

### p3: 部分ドッグフーディング（Unit単位で最小発火→失敗ログ→反復修正）

**goal**: Unit 単位の最小発火と失敗ログを確実に取得し、反復修正の基盤を作る

#### subtasks

- [ ] **p3.1**: 最小発火手順（単一 Unit）の草案が作成されている
  - executor: claudecode
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "selected unit (single) minimal trigger draft"
  - chain: "Hook -> Skill -> SubAgent(or Skill): SessionStart -> session-manager -> quality-assurance (health/integrity)"
  - skill_focus: "non-functional: session-manager(状態整合), quality-assurance(健全性), reward-guard(報酬詐欺防止)"
  - references: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`
  - reviewers: "codex, coderabbit"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "棚卸し/計画/優先順位の作成のみ。SSOT更新・実装・レビューは行わない"
  - output: "evidence を validations に記録（棚卸し/計画/優先順位の要約）"
  - validations:
    - technical: "by: claudecode / expected: 単一 Unit の発火手順が 3〜5 ステップで記載されている / evidence: 手順記載"
    - consistency: "by: codex / expected: Hook timing 全表記を含む / evidence: 記載確認"
    - completeness: "by: coderabbit / expected: ログ取得先/失敗ログの記録方法が明示されている / evidence: 記載確認"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

- [ ] **p3.2**: 選定 Unit 1件の最小修正パッチが反映されている
  - executor: codex
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "selected unit (single) minimal patch"
  - chain: "Hook -> Skill -> SubAgent(or Skill): PreToolUse(Edit/Write) -> playbook-gate -> codex-delegate"
  - skill_focus: "non-functional: playbook-gate(準拠強制), reward-guard(報酬詐欺防止)"
  - references: `.claude/events/`, `.claude/skills/`, `docs/core-feature-reclassification.md`
  - reviewers: "claudecode, coderabbit"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "target_unit の編集のみ（新規ファイル禁止/差分最小/範囲外編集禁止）。調査/レビュー/承認は行わない"
  - output: "target_unit 限定の差分（新規ファイルなし）"
  - validations:
    - technical: "by: codex / expected: 差分が選定 Unit に限定されている / evidence: git diff 出力"
    - consistency: "by: claudecode / expected: Hook→Skill→SubAgent の3層が維持されている / evidence: 差分確認"
    - completeness: "by: coderabbit / expected: 失敗ログで指摘された点のみ修正されている / evidence: ログと差分の対応"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

- [ ] **p3.3**: ドッグフーディング修正パッチのレビュー結果が記録されている
  - executor: coderabbit
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "dogfooding fix diff review"
  - chain: "Hook -> Skill -> SubAgent(or Skill): PreToolUse(Edit/Write) -> quality-assurance -> coderabbit-delegate"
  - skill_focus: "non-functional: quality-assurance(レビュー), reward-guard(critic 強制)"
  - references: `.claude/events/`, `.claude/skills/`
  - reviewers: "claudecode, codex"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "差分レビューのみ。修正はしない。summary/findings で出力"
  - output: "review summary + findings（severity/file/line）"
  - validations:
    - technical: "by: coderabbit / expected: coderabbit review --plain の出力が取得されている / evidence: review 出力ログ"
    - consistency: "by: codex / expected: 指摘が修正パッチの範囲と一致している / evidence: findings 一覧"
    - completeness: "by: claudecode / expected: summary と findings が揃っている / evidence: review summary + findings"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

- [ ] **p3.4**: ドッグフーディング結果（単一 Unit）の承認が得られている
  - executor: user
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "dogfooding evidence (single unit)"
  - chain: "Hook -> Skill -> SubAgent(or Skill): UserPromptSubmit -> understanding-check -> state (Skill)"
  - skill_focus: "non-functional: understanding-check(合意形成), state(状態整合)"
  - references: `docs/core-feature-reclassification.md`
  - reviewers: "claudecode, coderabbit"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "承認のみ（チェックリスト回答）。編集/実装/レビューは行わない"
  - output: "承認チェックリストの回答（yes/no）"
  - validations:
    - technical: "by: user / expected: ユーザー承認の回答が記録されている / evidence: 承認コメント/チェックリスト回答"
    - consistency: "by: claudecode / expected: 承認内容がログ/修正内容と一致している / evidence: 承認文とログの突合"
    - completeness: "by: coderabbit / expected: 次の反復方針が合意されている / evidence: 承認内の明記"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

**status**: pending
**max_iterations**: 5

---

### p4: 漸進統合（Unit単位で配線→都度ドッグフーディング→SSOT更新）

**goal**: Unit 単位の配線と統合を進め、SSOT と構造マップを更新する

#### subtasks

- [ ] **p4.1**: 漸進統合の順序草案（優先上位のみ）が作成されている
  - executor: claudecode
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "integration order draft (top priority only)"
  - chain: "Hook -> Skill -> SubAgent(or Skill): UserPromptSubmit -> prompt-analyzer -> state (Skill)"
  - skill_focus: "non-functional: prompt-analyzer(依頼理解), state(状態整合)"
  - references: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`
  - reviewers: "codex, coderabbit"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "棚卸し/計画/優先順位の作成のみ。SSOT更新・実装・レビューは行わない"
  - output: "evidence を validations に記録（棚卸し/計画/優先順位の要約）"
  - validations:
    - technical: "by: claudecode / expected: 優先上位の Unit 順序が 3件以上列挙されている / evidence: 順序リスト"
    - consistency: "by: codex / expected: missing リストの優先度と整合している / evidence: 優先度対応メモ"
    - completeness: "by: coderabbit / expected: 全 Hook timing を含む最終統合の意図が記載されている / evidence: 意図記載"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

- [ ] **p4.2**: 優先 Unit 1件の配線と SSOT 反映が完了している
  - executor: codex
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "selected unit (single) wiring + SSOT update"
  - chain: "Hook -> Skill -> SubAgent(or Skill): PreToolUse(Edit/Write) -> playbook-gate -> codex-delegate"
  - skill_focus: "non-functional: playbook-gate(準拠強制), reward-guard(報酬詐欺防止)"
  - references: `.claude/events/`, `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`
  - reviewers: "claudecode, coderabbit"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "target_unit の編集のみ（新規ファイル禁止/差分最小/範囲外編集禁止）。調査/レビュー/承認は行わない"
  - output: "target_unit 限定の差分（新規ファイルなし）"
  - validations:
    - technical: "by: codex / expected: 差分が選定 Unit と SSOT に限定されている / evidence: git diff 出力"
    - consistency: "by: claudecode / expected: Hook→Skill→SubAgent の3層が維持されている / evidence: 差分確認"
    - completeness: "by: coderabbit / expected: 選定 Unit の配線結果が SSOT に反映されている / evidence: SSOT 抜粋"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

- [ ] **p4.3**: 漸進統合パッチのレビュー結果が記録されている
  - executor: coderabbit
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "integration diff review"
  - chain: "Hook -> Skill -> SubAgent(or Skill): PreToolUse(Edit/Write) -> quality-assurance -> coderabbit-delegate"
  - skill_focus: "non-functional: quality-assurance(レビュー), reward-guard(critic 強制)"
  - references: `.claude/events/`, `docs/core-feature-reclassification.md`
  - reviewers: "claudecode, codex"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "差分レビューのみ。修正はしない。summary/findings で出力"
  - output: "review summary + findings（severity/file/line）"
  - validations:
    - technical: "by: coderabbit / expected: coderabbit review --plain の出力が取得されている / evidence: review 出力ログ"
    - consistency: "by: codex / expected: 指摘が統合パッチの範囲と一致している / evidence: findings 一覧"
    - completeness: "by: claudecode / expected: summary と findings が揃っている / evidence: review summary + findings"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

- [ ] **p4.4**: 統合結果（単一 Unit）と SSOT 反映の承認が得られている
  - executor: user
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - target_unit: "integration evidence (single unit)"
  - chain: "Hook -> Skill -> SubAgent(or Skill): UserPromptSubmit -> understanding-check -> state (Skill)"
  - skill_focus: "non-functional: understanding-check(合意形成), state(状態整合)"
  - references: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`, `docs/repository-map.yaml`
  - reviewers: "claudecode, coderabbit"
  - review_gate: "reviewers の evidence が揃うまで done 不可"
  - executor_scope: "承認のみ（チェックリスト回答）。編集/実装/レビューは行わない"
  - output: "承認チェックリストの回答（yes/no）"
  - validations:
    - technical: "by: user / expected: ユーザー承認の回答が記録されている / evidence: 承認コメント/チェックリスト回答"
    - consistency: "by: claudecode / expected: 承認内容が統合結果と一致している / evidence: 承認文と統合結果の突合"
    - completeness: "by: coderabbit / expected: DRIFT対応と Decision Log 更新が確認されている / evidence: 承認内の明記"
  - enforcement: "validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: done_when の全項目が実際に満たされていることを証拠付きで検証する

**depends_on**: [p4]

#### subtasks

- [ ] **p_final.1**: docs/core-feature-reclassification.md と docs/ARCHITECTURE.md が最新の Hook timing×ファイルマッピングを反映している
  - executor: claudecode
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - validations:
    - technical: "expected: rg -n 'Hook Timing Index' docs/core-feature-reclassification.md で Section 5 が存在 / evidence: コマンド出力を記録"
    - consistency: "expected: 9 Hook timing が全て Section 5 に記載されている / evidence: 照合結果を記録"
    - completeness: "expected: ファイルマッピング（Section 6）が .claude/events/ と一致 / evidence: ls .claude/events/ との照合結果を記録"
  - enforcement: "critic PASS 後に done"

- [ ] **p_final.2**: 欠落コンポーネントの確定リストが SSOT に固定されている
  - executor: claudecode
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - validations:
    - technical: "expected: rg -n 'missing' docs/core-feature-reclassification.md で missing 記載が存在 / evidence: コマンド出力を記録"
    - consistency: "expected: Section 10 の missing が各 Hook Unit に対応している / evidence: 照合結果を記録"
    - completeness: "expected: 全 10 Unit (session-start, user-prompt-submit, pre-tool-edit, pre-tool-bash, post-tool-edit, subagent-stop, pre-compact, stop, session-end, notification) の missing 状況が記載 / evidence: 確認結果を記録"
  - enforcement: "critic PASS 後に done"

- [ ] **p_final.3**: Unit 単位のドッグフーディング記録（ログ/状態/コマンド出力）が残っている
  - executor: claudecode
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - validations:
    - technical: "expected: playbook の Decision Log に記録が存在する / evidence: rg -n 'Decision Log' の出力を記録"
    - consistency: "expected: 記録内容が p3 で実施したドッグフーディングと整合している / evidence: 照合結果を記録"
    - completeness: "expected: 対象 Unit（user-prompt-submit, pre-tool-edit, post-tool-edit）の記録が存在 / evidence: 確認結果を記録"
  - enforcement: "critic PASS 後に done"

- [ ] **p_final.4**: 漸進統合の配線結果が SSOT と docs/repository-map.yaml に反映されている
  - executor: claudecode
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - validations:
    - technical: "expected: bash .claude/hooks/generate-repository-map.sh 実行後、docs/repository-map.yaml が更新される / evidence: コマンド出力と diff を記録"
    - consistency: "expected: repository-map.yaml の events セクションが .claude/events/ と一致 / evidence: 照合結果を記録"
    - completeness: "expected: skills/agents/hooks のカウントが実際のファイル数と一致 / evidence: ls と yaml の比較結果を記録"
  - enforcement: "critic PASS 後に done"

- [ ] **p_final.5**: Decision Log と DRIFT対応の記録が更新されている
  - executor: claudecode
  - hook_timing: "SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification"
  - validations:
    - technical: "expected: playbook の Decision Log セクションに作業中の決定事項が記録されている / evidence: rg -n 'Decision Log' の出力を記録"
    - consistency: "expected: DRIFT対応セクションの手順が実行済み / evidence: repository-map.yaml の generated 日時を確認"
    - completeness: "expected: p1-p4 で発生した決定事項が全て記録されている / evidence: Decision Log のエントリ数を確認"
  - enforcement: "critic PASS 後に done"

**status**: pending
**max_iterations**: 3

---

## 作業順の実行プロンプト設計（100本の方向性）

> 各 prompt は固定フォーマットで記述する。
> Hook timing は公式フック全イベントを全表記する。
> Phase1/2 を厚めに配分（P1=30, P2=30, P3=20, P4=20）。

### 使用ルール

- 各 prompt は該当 Phase/subtask を進めるための作業テンプレート
- 実行は手動で行い、結果は該当 subtask の validations に証拠として反映する
- prompt 実行時に subtask ID を紐づけ、validations の evidence に `prompt_id` を記録する
- prompt の採用順は Phase の順序に従い、Hook timing 全表記を崩さない

### Phase 1（30）

- [ ] **P1-01**
  - 目的: SSOT の読み取りと Context Lock の確立
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: all (SSOT baseline)
  - 参照: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`, `state.md`
  - 作業: SSOT を読み取り、Context Lock の前提を記録する
  - 期待結果: SSOT を基準にした作業前提が明文化されている
  - SSOT更新先: `docs/core-feature-reclassification.md`（差分があれば）
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-02**
  - 目的: 公式 Hook timing 全イベントの全表記を確認する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: hook timing index
  - 参照: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`
  - 作業: Hook timing index を照合し、9イベントを明示する
  - 期待結果: 9イベントの表記が揃っている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-03**
  - 目的: SessionStart Unit のファイルマッピングを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: session-start
  - 参照: `docs/core-feature-reclassification.md`, `.claude/hooks/session.sh`, `.claude/events/session-start/chain.sh`
  - 作業: SessionStart の Hook/Skill ファイルを棚卸しする
  - 期待結果: SessionStart の mapping が SSOT に一致している
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-04**
  - 目的: UserPromptSubmit Unit のファイルマッピングを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: user-prompt-submit
  - 参照: `docs/core-feature-reclassification.md`, `.claude/hooks/prompt.sh`, `.claude/events/user-prompt-submit/chain.sh`
  - 作業: UserPromptSubmit の Hook/Skill/SubAgent の入口を棚卸しする
  - 期待結果: UserPromptSubmit の mapping が SSOT に一致している
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-05**
  - 目的: PreToolUse(Edit/Write) Unit のファイルマッピングを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: pre-tool-edit
  - 参照: `docs/core-feature-reclassification.md`, `.claude/events/pre-tool-edit/chain.sh`
  - 作業: pre-tool-edit の guard/chain を棚卸しする
  - 期待結果: pre-tool-edit の mapping が SSOT に一致している
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-06**
  - 目的: PreToolUse(Bash) Unit のファイルマッピングを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: pre-tool-bash
  - 参照: `docs/core-feature-reclassification.md`, `.claude/events/pre-tool-bash/chain.sh`
  - 作業: pre-tool-bash の guard/chain を棚卸しする
  - 期待結果: pre-tool-bash の mapping が SSOT に一致している
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-07**
  - 目的: PostToolUse(Edit) Unit のファイルマッピングを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: post-tool-edit
  - 参照: `docs/core-feature-reclassification.md`, `.claude/events/post-tool-edit/chain.sh`
  - 作業: post-tool-edit の chain と workflow を棚卸しする
  - 期待結果: post-tool-edit の mapping が SSOT に一致している
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-08**
  - 目的: SubagentStop Unit のファイルマッピングを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: subagent-stop
  - 参照: `docs/core-feature-reclassification.md`, `.claude/events/subagent-stop/chain.sh`
  - 作業: subagent-stop の chain と後処理を棚卸しする
  - 期待結果: subagent-stop の mapping が SSOT に一致している
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-09**
  - 目的: PreCompact Unit のファイルマッピングを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: pre-compact
  - 参照: `docs/core-feature-reclassification.md`, `.claude/events/pre-compact/chain.sh`
  - 作業: pre-compact の chain と additionalContext 出力を棚卸しする
  - 期待結果: pre-compact の mapping が SSOT に一致している
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-10**
  - 目的: Stop Unit のファイルマッピングを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: stop
  - 参照: `docs/core-feature-reclassification.md`, `.claude/events/stop/chain.sh`
  - 作業: stop の no-op 状態と参照ファイルを棚卸しする
  - 期待結果: stop の mapping が SSOT に一致している
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-11**
  - 目的: SessionEnd Unit のファイルマッピングを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: session-end
  - 参照: `docs/core-feature-reclassification.md`, `.claude/events/session-end/chain.sh`
  - 作業: session-end の chain と後処理を棚卸しする
  - 期待結果: session-end の mapping が SSOT に一致している
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-12**
  - 目的: Notification Unit のファイルマッピングを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: notification
  - 参照: `docs/core-feature-reclassification.md`, `.claude/events/notification/chain.sh`
  - 作業: notification の no-op 状態と参照ファイルを棚卸しする
  - 期待結果: notification の mapping が SSOT に一致している
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-13**
  - 目的: `.claude/events/` と `docs/repository-map.yaml` の整合性を確認する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: events directory
  - 参照: `docs/repository-map.yaml`, `.claude/events/`
  - 作業: repository-map のイベント一覧と実ファイルを突合する
  - 期待結果: event unit の一覧が一致している
  - SSOT更新先: `docs/repository-map.yaml`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-14**
  - 目的: `.claude/hooks/` と repository-map の整合性を確認する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: hooks directory
  - 参照: `docs/repository-map.yaml`, `.claude/hooks/`
  - 作業: hooks の一覧と repository-map を突合する
  - 期待結果: hooks の一覧が一致している
  - SSOT更新先: `docs/repository-map.yaml`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-15**
  - 目的: Skill 評価リスト（core/keep 等）と現行 skills を照合する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: skills inventory
  - 参照: `docs/core-feature-reclassification.md`, `.claude/skills/`
  - 作業: Skill 評価と実体の差分を抽出する
  - 期待結果: core/keep/remove の整合が確認できる
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-16**
  - 目的: 再導入禁止ファイルが復活していないことを確認する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: removed list
  - 参照: `plan/playbook-handoff-ssot.md`
  - 作業: 削除済みリストとリポジトリを照合する
  - 期待結果: 再導入禁止が守られている
  - SSOT更新先: `docs/repository-map.yaml`（差分があれば）
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-17**
  - 目的: 現状の主要構成（短縮版）を検証する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: root structure
  - 参照: `docs/repository-map.yaml`, `plan/playbook-handoff-ssot.md`
  - 作業: 主要構成の記載と現行構造を突合する
  - 期待結果: 主要構成の記載が正確である
  - SSOT更新先: `docs/repository-map.yaml`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-18**
  - 目的: no-op Unit（Stop/Notification）の現状を棚卸しする
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: stop, notification
  - 参照: `docs/core-feature-reclassification.md`, `.claude/events/stop/chain.sh`, `.claude/events/notification/chain.sh`
  - 作業: no-op 状態と欠落要素を明記する
  - 期待結果: no-op 状態が SSOT に反映されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-19**
  - 目的: pre-tool-edit の guard/chain 構成を棚卸しする
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: pre-tool-edit
  - 参照: `.claude/events/pre-tool-edit/chain.sh`, `docs/core-feature-reclassification.md`
  - 作業: guard の順序と参照ファイルを確認する
  - 期待結果: guard 構成が SSOT に一致している
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-20**
  - 目的: post-tool-edit の workflow/PR 連携を棚卸しする
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: post-tool-edit
  - 参照: `.claude/events/post-tool-edit/chain.sh`, `.claude/skills/git-workflow/handlers/`
  - 作業: archive/cleanup/create-pr の経路を確認する
  - 期待結果: workflow の実体と SSOT が一致している
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-21**
  - 目的: Hook timing×ファイルマッピングの差分を core-feature に反映する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: all (mapping diff)
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: 棚卸し差分を SSOT に追記する
  - 期待結果: core-feature の mapping が最新化されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-22**
  - 目的: user flow / event unit の差分を ARCHITECTURE に反映する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: architecture mapping
  - 参照: `docs/ARCHITECTURE.md`
  - 作業: ユーザーフローと event unit の差分を更新する
  - 期待結果: ARCHITECTURE が最新化されている
  - SSOT更新先: `docs/ARCHITECTURE.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-23**
  - 目的: DRIFT を検出した場合に repository-map を再生成する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: repository-map
  - 参照: `docs/repository-map.yaml`, `.claude/hooks/generate-repository-map.sh`
  - 作業: repository-map を再生成し差分を記録する
  - 期待結果: repository-map が現行構造と一致している
  - SSOT更新先: `docs/repository-map.yaml`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-24**
  - 目的: Hook timing index が SSOT 全体で一貫していることを検証する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: hook timing index
  - 参照: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`
  - 作業: Hook timing 表記の揺れを修正する
  - 期待結果: 9イベントの表記が統一されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-25**
  - 目的: ユーザー体験の一本道が SSOT に明記されていることを検証する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: user flow
  - 参照: `docs/ARCHITECTURE.md`
  - 作業: 依頼→計画→実行→検証→完了 の文脈を確認する
  - 期待結果: 一本道の記述が SSOT に残っている
  - SSOT更新先: `docs/ARCHITECTURE.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-26**
  - 目的: Hook→Skill→SubAgent(or Skill) の3層が SSOT に明記されていることを検証する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: chain definition
  - 参照: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`
  - 作業: 3層構造の記載を確認し差分を修正する
  - 期待結果: 3層構造の記述が揃っている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-27**
  - 目的: 棚卸しに関する意思決定を Decision Log に記録する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: Decision Log
  - 参照: `plan/playbook-handoff-ssot.md`
  - 作業: 決定事項と根拠を追記する
  - 期待結果: Decision Log が更新されている
  - SSOT更新先: `docs/core-feature-reclassification.md`（Decision Log と整合）
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-28**
  - 目的: playbook テンプレート参照の整合性を確認する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: playbook templates
  - 参照: `plan/template/playbook-format.md`, `plan/template/planning-rules.md`
  - 作業: テンプレート参照が SSOT に反映されているか確認する
  - 期待結果: テンプレート参照が最新である
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-29**
  - 目的: state.md 参照の整合性を確認する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: state management
  - 参照: `state.md`, `docs/ARCHITECTURE.md`
  - 作業: state.md の参照位置と役割を確認する
  - 期待結果: SSOT と state の役割が一致している
  - SSOT更新先: `docs/ARCHITECTURE.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P1-30**
  - 目的: Phase1 の棚卸し結果についてユーザー承認を得る
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: inventory summary
  - 参照: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`
  - 作業: 棚卸し結果を提示し承認を依頼する
  - 期待結果: ユーザー承認が得られている
  - SSOT更新先: `state.md`（承認記録は Skill 経由）
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

### Phase 2（30）

- [ ] **P2-01**
  - 目的: SessionStart の missing コンポーネントを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: session-start
  - 参照: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`
  - 作業: validator/telemetry/guardrail の欠落を抽出する
  - 期待結果: session-start の missing が明確になっている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-02**
  - 目的: UserPromptSubmit の missing コンポーネントを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: user-prompt-submit
  - 参照: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`
  - 作業: validator/telemetry/guardrail の欠落と自動チェーン不足を抽出する
  - 期待結果: user-prompt-submit の missing が明確になっている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-03**
  - 目的: pre-tool-edit の missing コンポーネントを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: pre-tool-edit
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: validator/telemetry/snapshot の欠落を抽出する
  - 期待結果: pre-tool-edit の missing が明確になっている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-04**
  - 目的: pre-tool-bash の missing コンポーネントを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: pre-tool-bash
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: validator/telemetry/retry の欠落を抽出する
  - 期待結果: pre-tool-bash の missing が明確になっている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-05**
  - 目的: post-tool-edit の missing コンポーネントを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: post-tool-edit
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: validator/telemetry の欠落を抽出する
  - 期待結果: post-tool-edit の missing が明確になっている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-06**
  - 目的: subagent-stop の missing コンポーネントを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: subagent-stop
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: validator/telemetry の欠落を抽出する
  - 期待結果: subagent-stop の missing が明確になっている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-07**
  - 目的: pre-compact の missing コンポーネントを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: pre-compact
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: validator/telemetry/snapshot の欠落を抽出する
  - 期待結果: pre-compact の missing が明確になっている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-08**
  - 目的: stop の missing コンポーネントを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: stop
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: telemetry/snapshot の欠落を抽出する
  - 期待結果: stop の missing が明確になっている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-09**
  - 目的: session-end の missing コンポーネントを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: session-end
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: validator/telemetry/snapshot の欠落を抽出する
  - 期待結果: session-end の missing が明確になっている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-10**
  - 目的: notification の missing コンポーネントを確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: notification
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: telemetry の欠落を抽出する
  - 期待結果: notification の missing が明確になっている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-11**
  - 目的: SessionStart の health/integrity 配線不足を確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: session-start
  - 参照: `docs/core-feature-reclassification.md`, `.claude/skills/quality-assurance/checkers/`
  - 作業: health/integrity の現状配線を確認する
  - 期待結果: 未配線が missing に明記されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-12**
  - 目的: UserPromptSubmit の自動チェーン不足を確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: user-prompt-submit
  - 参照: `docs/core-feature-reclassification.md`, `.claude/events/user-prompt-submit/chain.sh`
  - 作業: prompt-analyzer → understanding-check → playbook-init の自動化不足を確認する
  - 期待結果: 未完箇所が missing に明記されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-13**
  - 目的: Stop/Notification の telemetry 未配線を確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: stop, notification
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: no-op 状態と telemetry 欠落を確認する
  - 期待結果: 未配線が missing に明記されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-14**
  - 目的: PreToolUse 系の validator/telemetry/snapshot 分割不足を確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: pre-tool-edit, pre-tool-bash
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: component 分割の欠落を抽出する
  - 期待結果: 分割不足が missing に明記されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-15**
  - 目的: 全 Unit の missing リストを core-feature に集約する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: all (missing list)
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: missing の一覧を統合し重複を整理する
  - 期待結果: missing リストが一貫している
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-16**
  - 目的: missing リストの影響を ARCHITECTURE に反映する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: architecture mapping
  - 参照: `docs/ARCHITECTURE.md`
  - 作業: ユーザーフローの未完領域を明記する
  - 期待結果: ARCHITECTURE が missing リストと整合している
  - SSOT更新先: `docs/ARCHITECTURE.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-17**
  - 目的: missing コンポーネントの依存関係を確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: dependency map
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: missing の依存関係を列挙する
  - 期待結果: 統合順序の基礎ができている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-18**
  - 目的: missing コンポーネントの証拠指標を定義する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: evidence definition
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: ログ/状態/コマンド出力の証拠形式を決める
  - 期待結果: 証拠指標が SSOT に紐づいている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-19**
  - 目的: Skill 評価（非機能要件）を missing リストに紐づける
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: skill evaluation
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: Skill の役割を欠落項目と対応させる
  - 期待結果: 非機能要件の役割が明示されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-20**
  - 目的: 削除済み Skill/Docs の再導入禁止を再確認する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: removed list
  - 参照: `plan/playbook-handoff-ssot.md`
  - 作業: 再導入禁止の対象を missing リストと分離する
  - 期待結果: 再導入禁止が維持されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-21**
  - 目的: Hook timing の全表記を missing リストに反映する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: missing list format
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: missing 記載で Hook timing を明示する
  - 期待結果: missing の表記が Hook timing と一致している
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-22**
  - 目的: missing リストと repository-map の整合性を確認する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: repository-map consistency
  - 参照: `docs/repository-map.yaml`, `docs/core-feature-reclassification.md`
  - 作業: missing 対象のファイル有無を確認する
  - 期待結果: missing と構造差分が一致している
  - SSOT更新先: `docs/repository-map.yaml`（差分があれば）
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-23**
  - 目的: missing の status 表記を統一する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: status notation
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: current/missing 表記の揺れを修正する
  - 期待結果: status 表記が統一されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-24**
  - 目的: missing 確定の意思決定を Decision Log に記録する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: Decision Log
  - 参照: `plan/playbook-handoff-ssot.md`
  - 作業: missing 確定の決定事項を追記する
  - 期待結果: Decision Log が更新されている
  - SSOT更新先: `docs/core-feature-reclassification.md`（Decision Log と整合）
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-25**
  - 目的: Phase3 のドッグフーディング対象 Unit を確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: dogfooding scope
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: missing リストから優先 Unit を選定する
  - 期待結果: dogfooding 対象が明確になっている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-26**
  - 目的: Phase4 の漸進統合対象を確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: integration scope
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: missing リストから統合対象を選定する
  - 期待結果: 統合対象が明確になっている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-27**
  - 目的: テスト不要の証拠方針を明文化する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: evidence policy
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: ログ/状態/コマンド出力で検証する方針を固定する
  - 期待結果: 証拠方針が SSOT に明記されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-28**
  - 目的: 一本道（依頼→計画→実行→検証→完了）を欠落確定フェーズで保持する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: user flow
  - 参照: `docs/ARCHITECTURE.md`
  - 作業: 欠落確定の記載が一本道を崩していないか確認する
  - 期待結果: 一本道の記述が維持されている
  - SSOT更新先: `docs/ARCHITECTURE.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-29**
  - 目的: tmp/ の扱い（README.md/fizzbuzz.py）を確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: tmp policy
  - 参照: `plan/playbook-handoff-ssot.md`
  - 作業: ユーザーに保持/削除の判断を求める
  - 期待結果: tmp の扱いが確定している
  - SSOT更新先: `docs/core-feature-reclassification.md`（決定を反映）
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P2-30**
  - 目的: missing リストとスコープ境界についてユーザー承認を得る
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: missing list approval
  - 参照: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`
  - 作業: missing リストと境界を提示して承認を依頼する
  - 期待結果: ユーザー承認が得られている
  - SSOT更新先: `state.md`（承認記録は Skill 経由）
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

### Phase 3（20）

- [ ] **P3-01**
  - 目的: ドッグフーディング対象 Unit の優先順位を確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: dogfooding priority
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: missing リストから優先 Unit を選定する
  - 期待結果: 優先順位が明示されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P3-02**
  - 目的: SessionStart の最小発火でログを取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: session-start
  - 参照: `.claude/hooks/session.sh`, `.claude/events/session-start/`
  - 作業: SessionStart 発火とログ取得を行う
  - 期待結果: ログ/状態が取得されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P3-03**
  - 目的: UserPromptSubmit の最小発火でログを取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: user-prompt-submit
  - 参照: `.claude/hooks/prompt.sh`, `.claude/events/user-prompt-submit/`
  - 作業: UserPromptSubmit 発火とログ取得を行う
  - 期待結果: ログ/状態が取得されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P3-04**
  - 目的: pre-tool-edit の最小発火でログを取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: pre-tool-edit
  - 参照: `.claude/hooks/pre-tool.sh`, `.claude/events/pre-tool-edit/`
  - 作業: Edit/Write 実行前の Hook を発火させる
  - 期待結果: guard のログが取得されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P3-05**
  - 目的: pre-tool-bash の最小発火でログを取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: pre-tool-bash
  - 参照: `.claude/hooks/pre-tool.sh`, `.claude/events/pre-tool-bash/`
  - 作業: Bash 実行前の Hook を発火させる
  - 期待結果: guard のログが取得されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P3-06**
  - 目的: post-tool-edit の最小発火でログを取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: post-tool-edit
  - 参照: `.claude/hooks/post-tool.sh`, `.claude/events/post-tool-edit/`
  - 作業: Edit 実行後の Hook を発火させる
  - 期待結果: workflow のログが取得されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P3-07**
  - 目的: subagent-stop の最小発火でログを取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: subagent-stop
  - 参照: `.claude/hooks/subagent-stop.sh`, `.claude/events/subagent-stop/`
  - 作業: SubAgent 終了フローのログを取得する
  - 期待結果: subagent-stop のログが取得されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P3-08**
  - 目的: pre-compact の最小発火でログを取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: pre-compact
  - 参照: `.claude/events/pre-compact/chain.sh`
  - 作業: compact 前の Hook を発火させる
  - 期待結果: additionalContext の出力が取得されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P3-09**
  - 目的: stop の最小発火でログを取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: stop
  - 参照: `.claude/events/stop/chain.sh`
  - 作業: stop の Hook を発火させる
  - 期待結果: stop のログが取得されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P3-10**
  - 目的: session-end の最小発火でログを取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: session-end
  - 参照: `.claude/events/session-end/chain.sh`
  - 作業: session-end の Hook を発火させる
  - 期待結果: session-end のログが取得されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P3-11**
  - 目的: notification の最小発火でログを取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: notification
  - 参照: `.claude/events/notification/chain.sh`
  - 作業: notification の Hook を発火させる
  - 期待結果: notification のログが取得されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P3-12**
  - 目的: 失敗ログを Unit 単位で整理し missing と紐づける
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: failure logs
  - 参照: `.claude/logs/`, `docs/core-feature-reclassification.md`
  - 作業: 失敗ログを整理し欠落項目に紐づける
  - 期待結果: 失敗ログと missing の対応が明確である
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P3-13**
  - 目的: 最初の失敗箇所に対する最小修正を行う
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: selected unit fix
  - 参照: `.claude/events/`, `.claude/skills/`
  - 作業: 失敗ログに対応する最小修正を行う
  - 期待結果: 修正差分が unit に限定されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P3-14**
  - 目的: 修正後の Unit を再発火してログを再取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: selected unit
  - 参照: `.claude/events/`
  - 作業: 修正済み Unit を再発火する
  - 期待結果: 失敗ログが解消している
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P3-15**
  - 目的: ドッグフーディング証拠を SSOT に記録する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: evidence log
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: ログ/状態/コマンド出力を SSOT に反映する
  - 期待結果: ドッグフーディング証拠が記録されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P3-16**
  - 目的: reward-guard/critic の挙動をログで確認する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: reward-guard
  - 参照: `.claude/skills/reward-guard/guards/`
  - 作業: critic 強制のログを確認する
  - 期待結果: 報酬詐欺防止の挙動が確認できる
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P3-17**
  - 目的: post-loop pending の挙動をログで確認する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: post-loop
  - 参照: `.claude/skills/post-loop/guards/pending-guard.sh`
  - 作業: pending ブロックのログを確認する
  - 期待結果: post-loop の挙動が確認できる
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P3-18**
  - 目的: ドッグフーディングの意思決定を Decision Log に記録する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: Decision Log
  - 参照: `plan/playbook-handoff-ssot.md`
  - 作業: 反復修正の決定事項を追記する
  - 期待結果: Decision Log が更新されている
  - SSOT更新先: `docs/core-feature-reclassification.md`（Decision Log と整合）
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P3-19**
  - 目的: ドッグフーディング修正を reviewer/coderabbit で確認する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: review
  - 参照: `.claude/skills/quality-assurance/agents/coderabbit-delegate.md`
  - 作業: coderabbit のレビュー結果を取得する
  - 期待結果: レビュー結果が整理されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P3-20**
  - 目的: ドッグフーディング結果のユーザー承認を得る
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: dogfooding approval
  - 参照: `docs/core-feature-reclassification.md`
  - 作業: 取得した証拠を提示し承認を依頼する
  - 期待結果: ユーザー承認が得られている
  - SSOT更新先: `state.md`（承認記録は Skill 経由）
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

### Phase 4（20）

- [ ] **P4-01**
  - 目的: 統合順序と依存関係を最終確定する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: integration order
  - 参照: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`
  - 作業: missing リストから統合順序を決定する
  - 期待結果: 統合順序が明文化されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P4-02**
  - 目的: session-start の component stub 配線を統合する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: session-start
  - 参照: `.claude/events/session-start/`, `docs/core-feature-reclassification.md`
  - 作業: validator/context/telemetry の配線を進める
  - 期待結果: session-start の配線が SSOT に反映されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P4-03**
  - 目的: session-start 統合後の最小発火ログを取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: session-start
  - 参照: `.claude/events/session-start/`
  - 作業: 統合後の Hook を発火させる
  - 期待結果: ログが取得できる
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P4-04**
  - 目的: user-prompt-submit の component stub 配線を統合する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: user-prompt-submit
  - 参照: `.claude/events/user-prompt-submit/`, `docs/core-feature-reclassification.md`
  - 作業: validator/context/telemetry/guardrail の配線を進める
  - 期待結果: user-prompt-submit の配線が SSOT に反映されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P4-05**
  - 目的: user-prompt-submit 統合後の最小発火ログを取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: user-prompt-submit
  - 参照: `.claude/events/user-prompt-submit/`
  - 作業: 統合後の Hook を発火させる
  - 期待結果: ログが取得できる
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P4-06**
  - 目的: pre-tool-edit の component stub 配線を統合する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: pre-tool-edit
  - 参照: `.claude/events/pre-tool-edit/`, `docs/core-feature-reclassification.md`
  - 作業: validator/telemetry/snapshot の配線を進める
  - 期待結果: pre-tool-edit の配線が SSOT に反映されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P4-07**
  - 目的: pre-tool-edit 統合後の最小発火ログを取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: pre-tool-edit
  - 参照: `.claude/events/pre-tool-edit/`
  - 作業: 統合後の Hook を発火させる
  - 期待結果: ログが取得できる
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P4-08**
  - 目的: pre-tool-bash の component stub 配線を統合する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: pre-tool-bash
  - 参照: `.claude/events/pre-tool-bash/`, `docs/core-feature-reclassification.md`
  - 作業: validator/telemetry/retry の配線を進める
  - 期待結果: pre-tool-bash の配線が SSOT に反映されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P4-09**
  - 目的: pre-tool-bash 統合後の最小発火ログを取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: pre-tool-bash
  - 参照: `.claude/events/pre-tool-bash/`
  - 作業: 統合後の Hook を発火させる
  - 期待結果: ログが取得できる
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P4-10**
  - 目的: post-tool-edit の component stub 配線を統合する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: post-tool-edit
  - 参照: `.claude/events/post-tool-edit/`, `docs/core-feature-reclassification.md`
  - 作業: validator/telemetry の配線を進める
  - 期待結果: post-tool-edit の配線が SSOT に反映されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P4-11**
  - 目的: post-tool-edit 統合後の最小発火ログを取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: post-tool-edit
  - 参照: `.claude/events/post-tool-edit/`
  - 作業: 統合後の Hook を発火させる
  - 期待結果: ログが取得できる
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P4-12**
  - 目的: subagent-stop の component stub 配線を統合する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: subagent-stop
  - 参照: `.claude/events/subagent-stop/`, `docs/core-feature-reclassification.md`
  - 作業: validator/telemetry の配線を進める
  - 期待結果: subagent-stop の配線が SSOT に反映されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P4-13**
  - 目的: subagent-stop 統合後の最小発火ログを取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: subagent-stop
  - 参照: `.claude/events/subagent-stop/`
  - 作業: 統合後の Hook を発火させる
  - 期待結果: ログが取得できる
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P4-14**
  - 目的: pre-compact の component stub 配線を統合する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: pre-compact
  - 参照: `.claude/events/pre-compact/`, `docs/core-feature-reclassification.md`
  - 作業: validator/telemetry/snapshot の配線を進める
  - 期待結果: pre-compact の配線が SSOT に反映されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P4-15**
  - 目的: pre-compact 統合後の最小発火ログを取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: pre-compact
  - 参照: `.claude/events/pre-compact/`
  - 作業: 統合後の Hook を発火させる
  - 期待結果: ログが取得できる
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P4-16**
  - 目的: stop/session-end/notification の telemetry 配線を統合する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: stop, session-end, notification
  - 参照: `.claude/events/stop/`, `.claude/events/session-end/`, `.claude/events/notification/`
  - 作業: telemetry コンポーネントの配線を進める
  - 期待結果: no-op が解消される
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P4-17**
  - 目的: stop/session-end/notification 統合後の最小発火ログを取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: stop, session-end, notification
  - 参照: `.claude/events/stop/`, `.claude/events/session-end/`, `.claude/events/notification/`
  - 作業: 統合後の Hook を発火させる
  - 期待結果: ログが取得できる
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P4-18**
  - 目的: 統合結果を repository-map と SSOT に反映する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: repository-map update
  - 参照: `docs/repository-map.yaml`, `.claude/hooks/generate-repository-map.sh`
  - 作業: repository-map を再生成し SSOT に反映する
  - 期待結果: 構造マップが最新化されている
  - SSOT更新先: `docs/repository-map.yaml`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P4-19**
  - 目的: 漸進統合のレビュー結果を取得する
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: review
  - 参照: `.claude/skills/quality-assurance/agents/coderabbit-delegate.md`
  - 作業: coderabbit のレビュー結果を取得する
  - 期待結果: レビュー結果が整理されている
  - SSOT更新先: `docs/core-feature-reclassification.md`
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

- [ ] **P4-20**
  - 目的: 統合結果についてユーザー承認を得る
  - Hook timing: SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / SubagentStop / PreCompact / Stop / SessionEnd / Notification
  - 対象Unit: integration approval
  - 参照: `docs/core-feature-reclassification.md`, `docs/ARCHITECTURE.md`
  - 作業: 統合結果と証拠を提示し承認を依頼する
  - 期待結果: ユーザー承認が得られている
  - SSOT更新先: `state.md`（承認記録は Skill 経由）
  - enforcement: validations は by/expected/evidence 形式で記録し、reviewers の evidence と prompt_id を残す。critic PASS 後に done

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを整理する（README.md と fizzbuzz.py は Phase2 の判断に従う）
  - command: `find tmp/ -type f ! -name 'README.md' ! -name 'fizzbuzz.py' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: Decision Log と SSOT の整合性を確認する
  - command: `rg -n "Decision Log" plan/playbook-handoff-ssot.md`
  - status: pending
