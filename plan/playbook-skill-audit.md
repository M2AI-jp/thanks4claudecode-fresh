# playbook-skill-audit.md

> **74ファイルを1つずつ検証し、存在理由と健全性を可視化する**

---

## meta

```yaml
project: skill-audit
branch: refactor/repository-audit-and-simplification
created: 2026-01-03
issue: null
reviewed: true
roles:
  worker: claudecode
```

---

## context

```yaml
# 5W1H
what: 全74ファイル（Hooks/Skills/SubAgents）の5軸評価とSKILL_INDEX.md作成
why: LLMの自己認識向上、機能可視化、保守性向上
who: Claude Code（claudecode）
where: .claude/配下のHooks、Skills、SubAgents
when: 2026-01-03（ユーザー指示により即時実行）
how: bash -n構文チェック、依存確認、整合性確認

# ユーザー承認
approved: true
approval_note: "評価と可視化のみ。統合・削除は行わない。"
```

---

## goal

```yaml
summary: 全74ファイルを個別検証し、評価結果をSKILL_INDEX.mdに保存する
done_when:
  - 7 Hook スクリプトの評価が完了し記録されている
  - 35 Skill 内スクリプトの評価が完了し記録されている
  - 22 SKILL.md の評価が完了し記録されている
  - 10 SubAgent 定義の評価が完了し記録されている
  - 各ファイルに「次のアクション」が明記されている
```

---

## evaluation_criteria（評価指標）

```yaml
criteria:
  why:
    description: "存在理由・対処するClaudeの欠陥"
    rating: [clear, partial, unclear]
  works:
    description: "動作するか（構文エラーなし）"
    rating: [works, broken, untested]
  depends:
    description: "依存関係"
    rating: [documented, implicit, orphan]
  health:
    description: "健全性"
    rating: [healthy, warning, critical]
  value:
    description: "貢献度"
    rating: [essential, useful, questionable]

next_action:
  keep: "維持"
  fix: "修正必要"
  review: "要レビュー"
  candidate_remove: "削除候補"
```

---

## phases

### p1: Hook スクリプトの検証（7ファイル）

**goal**: 7 Hook スクリプトを個別検証

#### subtasks

- [x] **p1.1**: .claude/hooks/pre-tool.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ PreToolUse(*) 導火線 - 全ツール呼び出し前のゲートチェック"
    - works: "✓ bash -n OK"
    - depends: "✓ 14 guards 全存在確認済"
    - health: "✓ healthy"
    - value: "✓ essential - Core Contract #1/#2/#3 全て実装"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p1.2**: .claude/hooks/post-tool.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ PostToolUse(*) 導火線 - ツール実行後の処理委譲"
    - works: "✓ bash -n OK"
    - depends: "✓ archive-playbook.sh, cleanup.sh, create-pr-hook.sh 全存在"
    - health: "✓ healthy"
    - value: "✓ essential - playbook 完了処理とクリーンアップ"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p1.3**: .claude/hooks/prompt.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ State Injection - playbook/phase 状態をコンテキストに注入"
    - works: "✓ bash -n OK"
    - depends: "✓ state.md, playbook 参照"
    - health: "✓ healthy"
    - value: "✓ essential - Core Contract #1 (Golden Path) 強制"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p1.4**: .claude/hooks/session-start.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ セッション開始時のコンポーネント状態表示 + coherence check"
    - works: "✓ bash -n OK"
    - depends: "✓ settings.json, skills/, coherence-checker 参照"
    - health: "✓ healthy"
    - value: "✓ useful - デバッグ・状態把握支援"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p1.5**: .claude/hooks/session.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ セッションライフサイクルイベントルーター (startup/end/compact)"
    - works: "✓ bash -n OK"
    - depends: "✓ start.sh, end.sh, compact.sh 全存在"
    - health: "✓ healthy"
    - value: "✓ essential - セッション管理の中央ルーター"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p1.6**: .claude/hooks/subagent-stop.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ SubAgent 終了後のクリーンアップ + playbook 完了チェック補完 (M089)"
    - works: "✓ bash -n OK"
    - depends: "✓ archive-playbook.sh 存在"
    - health: "✓ healthy"
    - value: "✓ essential - SubAgent 内 Edit の PostToolUse 未発火を補完"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p1.7**: .claude/hooks/generate-repository-map.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ リポジトリ全ファイル自動マッピング + DRIFT 検出"
    - works: "✓ bash -n OK"
    - depends: "✓ docs/ 出力先存在"
    - health: "✓ healthy"
    - value: "✓ essential - LLM の自己認識支援"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

**status**: done
**max_iterations**: 10

---

### p2: access-control Skill の検証（4ファイル）

**goal**: access-control 内の全ファイルを個別検証
**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: .claude/skills/access-control/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ アクセス制御 - 保護ファイル・ブランチ・Bash 契約チェック"
    - works: "✓ 整合性確認済"
    - depends: "✓ guards/, protected-files.txt 参照"
    - health: "✓ healthy"
    - value: "✓ essential - Core Contract file_protection 実装"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p2.2**: .claude/skills/access-control/guards/bash-check.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ 危険 Bash コマンドブロック + HARD_BLOCK 保護 + 回帰テスト実行"
    - works: "✓ bash -n OK"
    - depends: "✓ pre-tool.sh から呼び出し、coherence.sh 連携"
    - health: "✓ healthy"
    - value: "✓ essential - playbook=null で変更系コマンドブロック"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p2.3**: .claude/skills/access-control/guards/main-branch.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ main/master ブランチでの編集系ツールブロック"
    - works: "✓ bash -n OK"
    - depends: "✓ pre-tool.sh から呼び出し"
    - health: "✓ healthy"
    - value: "✓ essential - main 保護（常にブランチを切って作業）"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p2.4**: .claude/skills/access-control/guards/protected-edit.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ HARD_BLOCK/BLOCK/WARN 3階層の保護ファイル編集チェック"
    - works: "✓ bash -n OK"
    - depends: "✓ protected-files.txt 存在確認済"
    - health: "✓ healthy"
    - value: "✓ essential - CLAUDE.md 等の絶対守護"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

**status**: done
**max_iterations**: 10

---

### p3: playbook-gate Skill の検証（7ファイル）

**goal**: playbook-gate 内の全ファイルを個別検証
**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: .claude/skills/playbook-gate/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ Core Contract #2 - playbook なしでの変更ブロック"
    - works: "✓ 整合性確認済"
    - depends: "✓ guards/, workflow/ 参照"
    - health: "✓ healthy"
    - value: "✓ essential - Playbook Gate 実装"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p3.2**: .claude/skills/playbook-gate/guards/playbook-guard.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ playbook.active=null で Edit/Write ブロック"
    - works: "✓ bash -n OK"
    - depends: "✓ state.md 参照"
    - health: "✓ healthy"
    - value: "✓ essential - playbook 強制"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p3.3**: .claude/skills/playbook-gate/guards/executor-guard.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ 現在 executor と playbook.executor の整合性チェック"
    - works: "✓ bash -n OK"
    - depends: "✓ playbook, state.md 参照"
    - health: "✓ healthy"
    - value: "✓ useful - executor 制御"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p3.4**: .claude/skills/playbook-gate/guards/depends-check.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ Phase 依存関係（depends_on）の完了チェック"
    - works: "✓ bash -n OK"
    - depends: "✓ playbook 参照"
    - health: "✓ healthy"
    - value: "✓ useful - 依存管理"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p3.5**: .claude/skills/playbook-gate/guards/role-resolver.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ executor 名（claudecode/codex/user）の解決"
    - works: "✓ bash -n OK"
    - depends: "✓ state.md config.roles 参照"
    - health: "✓ healthy"
    - value: "✓ useful - 役割解決"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p3.6**: .claude/skills/playbook-gate/workflow/archive-playbook.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ playbook 完了時のアーカイブ + 自動コミット + PR"
    - works: "✓ bash -n OK"
    - depends: "✓ state.md, plan/archive/, git-workflow 参照"
    - health: "✓ healthy"
    - value: "✓ essential - 完了処理の自動化"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p3.7**: .claude/skills/playbook-gate/workflow/cleanup.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ tmp/ 内テンポラリファイルの削除"
    - works: "✓ bash -n OK"
    - depends: "✓ tmp/ 参照"
    - health: "✓ healthy"
    - value: "✓ useful - クリーンアップ"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

**status**: done
**max_iterations**: 10

---

### p4: reward-guard Skill の検証（7ファイル）

**goal**: reward-guard 内の全ファイルを個別検証
**depends_on**: [p3]

#### subtasks

- [x] **p4.1**: .claude/skills/reward-guard/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ Core Contract #3 - 報酬詐欺防止"
    - works: "✓ 整合性確認済"
    - depends: "✓ guards/, agents/ 参照"
    - health: "✓ healthy"
    - value: "✓ essential - 自己承認バイアス防止"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p4.2**: .claude/skills/reward-guard/guards/critic-guard.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ done 変更前に critic 実行を強制"
    - works: "✓ bash -n OK"
    - depends: "✓ critic SubAgent 参照"
    - health: "✓ healthy"
    - value: "✓ essential - 報酬詐欺防止"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p4.3**: .claude/skills/reward-guard/guards/subtask-guard.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ subtask 未完了なら Phase 完了ブロック"
    - works: "✓ bash -n OK"
    - depends: "✓ playbook 参照"
    - health: "✓ healthy"
    - value: "✓ essential - 3検証強制"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p4.4**: .claude/skills/reward-guard/guards/scope-guard.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ スコープ外ファイルへの変更を検出"
    - works: "✓ bash -n OK"
    - depends: "✓ playbook 参照"
    - health: "✓ healthy"
    - value: "✓ essential - スコープクリープ防止"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p4.5**: .claude/skills/reward-guard/guards/coherence.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ state.md と playbook の整合性チェック"
    - works: "✓ bash -n OK"
    - depends: "✓ state.md, playbook 参照"
    - health: "✓ healthy"
    - value: "✓ essential - 整合性維持"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p4.6**: .claude/skills/reward-guard/guards/phase-status-guard.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ Phase status 変更時の subtask 完了チェック"
    - works: "✓ bash -n OK"
    - depends: "✓ playbook 参照"
    - health: "✓ healthy"
    - value: "✓ essential - 形式的完了防止"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p4.7**: .claude/skills/reward-guard/agents/critic.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ done_criteria の独立検証を行う SubAgent"
    - works: "✓ 整合性確認済"
    - depends: "✓ reward-guard Skill 連携"
    - health: "✓ healthy"
    - value: "✓ essential - 報酬詐欺防止の中核"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

**status**: done
**max_iterations**: 10

---

### p5: golden-path Skill の検証（4ファイル）

**goal**: golden-path 内の全ファイルを個別検証
**depends_on**: [p4]

#### subtasks

- [x] **p5.1**: .claude/skills/golden-path/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ Core Contract #1 - Hook→Skill→SubAgent チェーン"
    - works: "✓ 整合性確認済"
    - depends: "✓ playbook-init, pm.md 参照"
    - health: "✓ healthy"
    - value: "✓ essential - Golden Path 実装"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p5.2**: .claude/skills/golden-path/agents/pm.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ タスク開始の必須エントリーポイント SubAgent"
    - works: "✓ 整合性確認済（33KB）"
    - depends: "✓ playbook-init, understanding-check 連携"
    - health: "✓ healthy"
    - value: "✓ essential - playbook 作成の中核"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p5.3**: .claude/skills/golden-path/agents/codex-delegate.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ Codex MCP をラップしてコンテキスト膨張防止"
    - works: "✓ 整合性確認済（7KB）"
    - depends: "✓ Codex MCP 連携"
    - health: "✓ healthy"
    - value: "✓ essential - 実装作業の委譲"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p5.4**: .claude/skills/playbook-init/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ pm SubAgent への委譲を強制"
    - works: "✓ 整合性確認済（3KB）"
    - depends: "✓ prompt.sh, pm 連携"
    - health: "✓ healthy"
    - value: "✓ essential - Golden Path Skill 層"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

**status**: done
**max_iterations**: 10

---

### p6: prompt-analyzer + understanding-check + term-translator の検証（6ファイル）

**goal**: プロンプト理解関連の全ファイルを個別検証
**depends_on**: [p5]

#### subtasks

- [x] **p6.1**: .claude/skills/prompt-analyzer/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ 5W1H 分析 + リスク分析 + 曖昧さ検出 + 論点分解"
    - works: "✓ 整合性確認済（7KB）"
    - depends: "✓ pm, understanding-check 連携"
    - health: "✓ healthy"
    - value: "✓ essential - プロンプト理解の自動化"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p6.2**: .claude/skills/prompt-analyzer/agents/prompt-analyzer.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ プロンプト深層分析 SubAgent"
    - works: "✓ 整合性確認済"
    - depends: "✓ Skill 連携"
    - health: "✓ healthy"
    - value: "✓ essential - 要件抽出"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p6.3**: .claude/skills/understanding-check/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ 5W1H フレームワークでユーザー意図確認"
    - works: "✓ 整合性確認済（11KB）"
    - depends: "✓ prompt-analyzer, AskUserQuestion 連携"
    - health: "✓ healthy"
    - value: "✓ essential - 手戻り防止"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p6.4**: .claude/skills/term-translator/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ 曖昧表現をエンジニア用語に変換"
    - works: "✓ 整合性確認済（5KB）"
    - depends: "✓ prompt-analyzer 連携"
    - health: "✓ healthy"
    - value: "✓ useful - 要件明確化"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p6.5**: .claude/skills/term-translator/agents/term-translator.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ 用語変換 SubAgent"
    - works: "✓ 整合性確認済"
    - depends: "✓ Skill 連携"
    - health: "✓ healthy"
    - value: "✓ useful - 要件明確化"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p6.6**: .claude/skills/executor-resolver/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ タスク性質から executor を LLM ベースで判定"
    - works: "✓ 整合性確認済（5KB）"
    - depends: "✓ playbook-gate 連携"
    - health: "✓ healthy"
    - value: "✓ useful - 自動判定"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

**status**: done
**max_iterations**: 10

---

### p7: executor-resolver + quality-assurance の検証（8ファイル）

**goal**: 実行判定と品質保証関連の全ファイルを個別検証
**depends_on**: [p6]

#### subtasks

- [x] **p7.1**: .claude/skills/executor-resolver/agents/executor-resolver.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ executor 判定 SubAgent"
    - works: "✓ 整合性確認済"
    - depends: "✓ Skill 連携"
    - health: "✓ healthy"
    - value: "✓ useful - 自動判定"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p7.2**: .claude/skills/quality-assurance/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ 品質保証 - ヘルス/整合性/lint チェック"
    - works: "✓ 整合性確認済（4KB）"
    - depends: "✓ checkers/, agents/ 参照"
    - health: "✓ healthy"
    - value: "✓ essential - コード品質保証"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p7.3**: .claude/skills/quality-assurance/checkers/health.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ システム健全性チェック（9KB）"
    - works: "✓ bash -n OK"
    - depends: "✓ SKILL.md 連携"
    - health: "✓ healthy"
    - value: "✓ useful - 健全性監視"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p7.4**: .claude/skills/quality-assurance/checkers/integrity.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ ファイル整合性チェック（6KB）"
    - works: "✓ bash -n OK"
    - depends: "✓ SKILL.md 連携"
    - health: "✓ healthy"
    - value: "✓ useful - 整合性維持"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p7.5**: .claude/skills/quality-assurance/checkers/lint.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ lint チェック（4KB）"
    - works: "✓ bash -n OK"
    - depends: "✓ SKILL.md 連携"
    - health: "✓ healthy"
    - value: "✓ useful - コード品質"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p7.6**: .claude/skills/quality-assurance/agents/reviewer.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ playbook レビュー SubAgent（14KB）"
    - works: "✓ 整合性確認済"
    - depends: "✓ SKILL.md 連携"
    - health: "✓ healthy"
    - value: "✓ essential - 品質保証"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p7.7**: .claude/skills/quality-assurance/agents/health-checker.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ システム状態監視 SubAgent（3KB）"
    - works: "✓ 整合性確認済"
    - depends: "✓ SKILL.md 連携"
    - health: "✓ healthy"
    - value: "✓ useful - 健全性監視"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p7.8**: .claude/skills/quality-assurance/agents/coderabbit-delegate.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ CodeRabbit CLI ラップ SubAgent（5KB）"
    - works: "✓ 整合性確認済"
    - depends: "✓ CodeRabbit CLI 連携"
    - health: "✓ healthy"
    - value: "✓ useful - コードレビュー自動化"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

**status**: done
**max_iterations**: 10

---

### p8: lint-checker + test-runner + deploy-checker + coherence-checker の検証（11ファイル）

**goal**: チェッカー系 Skill の全ファイルを個別検証
**depends_on**: [p7]

#### subtasks

- [x] **p8.1**: .claude/skills/lint-checker/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ ESLint/型チェック専門 Skill"
    - works: "✓ 整合性確認済"
    - depends: "✓ quality-assurance 連携"
    - health: "✓ healthy"
    - value: "✓ useful - コード品質"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p8.2**: .claude/skills/test-runner/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ テスト実行専門 Skill"
    - works: "✓ 整合性確認済"
    - depends: "✓ scripts/ 参照"
    - health: "✓ healthy"
    - value: "✓ essential - 品質保証"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p8.3**: .claude/skills/test-runner/scripts/run-all.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ 全テスト実行"
    - works: "✓ bash -n OK"
    - depends: "✓ 他 scripts 連携"
    - health: "✓ healthy"
    - value: "✓ essential - テスト自動化"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p8.4**: .claude/skills/test-runner/scripts/run-build.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ ビルドテスト"
    - works: "✓ bash -n OK"
    - depends: "✓ SKILL.md 連携"
    - health: "✓ healthy"
    - value: "✓ useful - ビルド検証"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p8.5**: .claude/skills/test-runner/scripts/run-critic.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ critic テスト"
    - works: "✓ bash -n OK"
    - depends: "✓ critic SubAgent 連携"
    - health: "✓ healthy"
    - value: "✓ useful - critic 検証"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p8.6**: .claude/skills/test-runner/scripts/run-e2e.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ E2E テスト"
    - works: "✓ bash -n OK"
    - depends: "✓ SKILL.md 連携"
    - health: "✓ healthy"
    - value: "✓ useful - E2E テスト"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p8.7**: .claude/skills/test-runner/scripts/run-typecheck.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ 型チェック"
    - works: "✓ bash -n OK"
    - depends: "✓ SKILL.md 連携"
    - health: "✓ healthy"
    - value: "✓ useful - 型安全"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p8.8**: .claude/skills/test-runner/scripts/run-unit.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ Unit テスト"
    - works: "✓ bash -n OK"
    - depends: "✓ SKILL.md 連携"
    - health: "✓ healthy"
    - value: "✓ useful - Unit テスト"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p8.9**: .claude/skills/deploy-checker/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ デプロイ前チェック専門 Skill"
    - works: "✓ 整合性確認済"
    - depends: "✓ test-runner 連携"
    - health: "✓ healthy"
    - value: "✓ useful - デプロイ安全性"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p8.10**: .claude/skills/coherence-checker/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ ARCHITECTURE.md と実装の整合性確認"
    - works: "✓ 整合性確認済"
    - depends: "✓ scripts/ 参照"
    - health: "✓ healthy"
    - value: "✓ essential - ドキュメント整合性"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p8.11**: .claude/skills/coherence-checker/scripts/check.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ 整合性チェック実装"
    - works: "✓ bash -n OK"
    - depends: "✓ ARCHITECTURE.md 連携"
    - health: "✓ healthy"
    - value: "✓ essential - 整合性チェック"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

**status**: done
**max_iterations**: 10

---

### p9: coherence-checker (続き) + state + plan-management の検証（4ファイル）

**goal**: 状態管理関連の全ファイルを個別検証
**depends_on**: [p8]

#### subtasks

- [x] **p9.1**: .claude/skills/coherence-checker/scripts/apply-fixes.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ 整合性問題の自動修正"
    - works: "✓ bash -n OK"
    - depends: "✓ check.sh 連携"
    - health: "✓ healthy"
    - value: "✓ useful - 自動修正"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p9.2**: .claude/skills/state/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ state.md 管理専門 Skill"
    - works: "✓ 整合性確認済"
    - depends: "✓ state.md, playbook 連携"
    - health: "✓ healthy"
    - value: "✓ essential - SSOT 維持"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p9.3**: .claude/skills/plan-management/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ 多層計画管理 Skill"
    - works: "✓ 整合性確認済"
    - depends: "✓ playbook 連携"
    - health: "✓ healthy"
    - value: "✓ useful - 計画管理"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p9.4**: .claude/skills/frontend-design/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ フロントエンドデザインガイド Skill"
    - works: "✓ 整合性確認済"
    - depends: "✓ 独立"
    - health: "✓ healthy"
    - value: "✓ useful - デザイン品質"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

**status**: done
**max_iterations**: 10

---

### p10: session-manager の検証（6ファイル）

**goal**: session-manager 内の全ファイルを個別検証
**depends_on**: [p9]

#### subtasks

- [x] **p10.1**: .claude/skills/session-manager/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ セッションライフサイクル管理"
    - works: "✓ 整合性確認済"
    - depends: "✓ handlers/, agents/ 参照"
    - health: "✓ healthy"
    - value: "✓ essential - セッション管理"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p10.2**: .claude/skills/session-manager/handlers/start.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ セッション開始処理"
    - works: "✓ bash -n OK"
    - depends: "✓ session.sh 連携"
    - health: "✓ healthy"
    - value: "✓ essential - 初期化"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p10.3**: .claude/skills/session-manager/handlers/end.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ セッション終了処理"
    - works: "✓ bash -n OK"
    - depends: "✓ SKILL.md 連携"
    - health: "✓ healthy"
    - value: "✓ useful - 終了処理"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p10.4**: .claude/skills/session-manager/handlers/compact.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ /compact 時の処理"
    - works: "✓ bash -n OK"
    - depends: "✓ context-management 連携"
    - health: "✓ healthy"
    - value: "✓ useful - コンテキスト管理"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p10.5**: .claude/skills/session-manager/handlers/init-guard.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ 必須ファイル Read 強制"
    - works: "✓ bash -n OK"
    - depends: "✓ SKILL.md 連携"
    - health: "✓ healthy"
    - value: "✓ essential - 初期化チェック"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p10.6**: .claude/skills/session-manager/agents/setup-guide.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ セットアップガイド SubAgent"
    - works: "✓ 整合性確認済"
    - depends: "✓ SKILL.md 連携"
    - health: "✓ healthy"
    - value: "✓ useful - オンボーディング"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

**status**: done
**max_iterations**: 10

---

### p11: context-management + post-loop + abort-playbook + git-workflow の検証（8ファイル）

**goal**: ワークフロー関連の全ファイルを個別検証
**depends_on**: [p10]

#### subtasks

- [x] **p11.1**: .claude/skills/context-management/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ /compact 最適化・履歴要約ガイドライン"
    - works: "✓ 整合性確認済"
    - depends: "✓ session-manager 連携"
    - health: "✓ healthy"
    - value: "✓ essential - コンテキスト管理の専門知識"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p11.2**: .claude/skills/post-loop/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ playbook 完了後のブロック解除・次タスク導出"
    - works: "✓ 整合性確認済"
    - depends: "✓ handlers/complete.sh, guards/pending-guard.sh 連携"
    - health: "✓ healthy"
    - value: "✓ essential - タスク連鎖の継続性"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p11.3**: .claude/skills/post-loop/guards/pending-guard.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ Edit/Write ブロック（pending 状態検出）"
    - works: "✓ bash -n OK"
    - depends: "✓ .claude/session-state/post-loop-pending 連携"
    - health: "✓ healthy"
    - value: "✓ essential - post-loop 強制"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p11.4**: .claude/skills/post-loop/handlers/complete.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ pending ファイル削除・ブロック解除"
    - works: "✓ bash -n OK"
    - depends: "✓ pending-guard.sh 連携"
    - health: "✓ healthy"
    - value: "✓ essential - ブロック解除"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p11.5**: .claude/skills/abort-playbook/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ playbook 中断・破棄処理"
    - works: "✓ 整合性確認済"
    - depends: "✓ abort.sh 連携"
    - health: "✓ healthy"
    - value: "✓ useful - クリーンアップ"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p11.6**: .claude/skills/abort-playbook/abort.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ playbook アーカイブ・state.md 更新"
    - works: "✓ bash -n OK"
    - depends: "✓ state.md, plan/archive/ 連携"
    - health: "✓ healthy"
    - value: "✓ useful - 中断処理実装"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: useful, next_action: keep }

- [x] **p11.7**: .claude/skills/git-workflow/SKILL.md の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ Git/PR ワークフロー管理"
    - works: "✓ 整合性確認済"
    - depends: "✓ handlers/ 連携"
    - health: "✓ healthy"
    - value: "✓ essential - PR 自動化"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p11.8**: .claude/skills/git-workflow/handlers/create-pr.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ gh pr create 実行"
    - works: "✓ bash -n OK"
    - depends: "✓ gh CLI 連携"
    - health: "✓ healthy"
    - value: "✓ essential - PR 自動化"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

**status**: done
**max_iterations**: 10

---

### p12: git-workflow (続き) の検証（2ファイル）

**goal**: git-workflow 残りファイルを個別検証
**depends_on**: [p11]

#### subtasks

- [x] **p12.1**: .claude/skills/git-workflow/handlers/create-pr-hook.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ PostToolUse:Edit からの PR 作成フック"
    - works: "✓ bash -n OK"
    - depends: "✓ create-pr.sh 連携"
    - health: "✓ healthy"
    - value: "✓ essential - 自動 PR 作成"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

- [x] **p12.2**: .claude/skills/git-workflow/handlers/merge-pr.sh の評価完了
  - executor: claudecode
  - validations:
    - why: "✓ gh pr merge 実行"
    - works: "✓ bash -n OK"
    - depends: "✓ gh CLI 連携"
    - health: "✓ healthy"
    - value: "✓ essential - マージ自動化"
  - result: { why: clear, works: works, depends: documented, health: healthy, value: essential, next_action: keep }

**status**: done
**max_iterations**: 10

---

### p13: SKILL_INDEX.md 作成

**goal**: 全74ファイルの評価結果を SKILL_INDEX.md に集約
**depends_on**: [p12]

#### subtasks

- [x] **p13.1**: SKILL_INDEX.md ファイルを作成
  - executor: claudecode
  - validations:
    - technical: "✓ .claude/SKILL_INDEX.md が存在"
    - consistency: "✓ evaluation_criteria が記載"
    - completeness: "✓ ヘッダーセクションが完備"
  - result: { created: true }

- [x] **p13.2**: Hooks セクション（7ファイル）を記載
  - executor: claudecode
  - validations:
    - technical: "✓ 7 Hook の評価結果が記載"
    - consistency: "✓ p1 の検証結果と一致"
    - completeness: "✓ 5軸評価 + Next Action"
  - result: { entries: 7 }

- [x] **p13.3**: access-control セクション（4ファイル）を記載
  - executor: claudecode
  - validations:
    - technical: "✓ 4 ファイルの評価結果が記載"
    - consistency: "✓ p2 の検証結果と一致"
    - completeness: "✓ 5軸評価 + Next Action"
  - result: { entries: 4 }

- [x] **p13.4**: playbook-gate セクション（7ファイル）を記載
  - executor: claudecode
  - validations:
    - technical: "✓ 7 ファイルの評価結果が記載"
    - consistency: "✓ p3 の検証結果と一致"
    - completeness: "✓ 5軸評価 + Next Action"
  - result: { entries: 7 }

- [x] **p13.5**: reward-guard セクション（7ファイル）を記載
  - executor: claudecode
  - validations:
    - technical: "✓ 7 ファイルの評価結果が記載"
    - consistency: "✓ p4 の検証結果と一致"
    - completeness: "✓ 5軸評価 + Next Action"
  - result: { entries: 7 }

- [x] **p13.6**: golden-path + playbook-init セクション（4ファイル）を記載
  - executor: claudecode
  - validations:
    - technical: "✓ 4 ファイルの評価結果が記載"
    - consistency: "✓ p5 の検証結果と一致"
    - completeness: "✓ 5軸評価 + Next Action"
  - result: { entries: 4 }

- [x] **p13.7**: prompt-analyzer + understanding-check + term-translator + executor-resolver セクション（6ファイル）を記載
  - executor: claudecode
  - validations:
    - technical: "✓ 6 ファイルの評価結果が記載"
    - consistency: "✓ p6 の検証結果と一致"
    - completeness: "✓ 5軸評価 + Next Action"
  - result: { entries: 6 }

- [x] **p13.8**: executor-resolver (agent) + quality-assurance セクション（8ファイル）を記載
  - executor: claudecode
  - validations:
    - technical: "✓ 8 ファイルの評価結果が記載"
    - consistency: "✓ p7 の検証結果と一致"
    - completeness: "✓ 5軸評価 + Next Action"
  - result: { entries: 8 }

- [x] **p13.9**: lint-checker + test-runner + deploy-checker + coherence-checker セクション（11ファイル）を記載
  - executor: claudecode
  - validations:
    - technical: "✓ 11 ファイルの評価結果が記載"
    - consistency: "✓ p8 の検証結果と一致"
    - completeness: "✓ 5軸評価 + Next Action"
  - result: { entries: 11 }

- [x] **p13.10**: coherence-checker (続き) + state + plan-management + frontend-design セクション（4ファイル）を記載
  - executor: claudecode
  - validations:
    - technical: "✓ 4 ファイルの評価結果が記載"
    - consistency: "✓ p9 の検証結果と一致"
    - completeness: "✓ 5軸評価 + Next Action"
  - result: { entries: 4 }

- [x] **p13.11**: session-manager セクション（6ファイル）を記載
  - executor: claudecode
  - validations:
    - technical: "✓ 6 ファイルの評価結果が記載"
    - consistency: "✓ p10 の検証結果と一致"
    - completeness: "✓ 5軸評価 + Next Action"
  - result: { entries: 6 }

- [x] **p13.12**: context-management + post-loop + abort-playbook + git-workflow セクション（8ファイル）を記載
  - executor: claudecode
  - validations:
    - technical: "✓ 8 ファイルの評価結果が記載"
    - consistency: "✓ p11 の検証結果と一致"
    - completeness: "✓ 5軸評価 + Next Action"
  - result: { entries: 8 }

- [x] **p13.13**: git-workflow (続き) セクション（2ファイル）を記載
  - executor: claudecode
  - validations:
    - technical: "✓ 2 ファイルの評価結果が記載"
    - consistency: "✓ p12 の検証結果と一致"
    - completeness: "✓ 5軸評価 + Next Action"
  - result: { entries: 2 }

- [x] **p13.14**: サマリーセクション（統計）を作成
  - executor: claudecode
  - validations:
    - technical: "✓ keep: 74, fix: 0, review: 0, candidate_remove: 0"
    - consistency: "✓ 各ファイルの Next Action と一致"
    - completeness: "✓ 統計が正確"
  - result: { keep: 74, fix: 0, review: 0, candidate_remove: 0 }

- [x] **p13.15**: 次アクション一覧セクションを作成
  - executor: claudecode
  - validations:
    - technical: "✓ fix/review/candidate_remove = 0件（全て keep）"
    - consistency: "✓ サマリーと一致"
    - completeness: "✓ 全ファイル健全"
  - result: { action_items: 0 }

**status**: done
**max_iterations**: 10

---

### p_final: 完了検証

**goal**: done_when が全て満たされているか最終検証

#### subtasks

- [x] **p_final.1**: 7 Hook スクリプトの評価が記録されている
  - executor: claudecode
  - validations:
    - technical: "✓ SKILL_INDEX.md セクション1に7 Hook記載"
    - consistency: "✓ p1 の全 subtask が完了"
    - completeness: "✓ 全評価項目が記載"
  - result: { hooks: 7 }

- [x] **p_final.2**: 35 Skill 内スクリプトの評価が記録されている
  - executor: claudecode
  - validations:
    - technical: "✓ grep -c '\\.sh' = 59（スクリプト参照）"
    - consistency: "✓ p2-p12 の関連 subtask が完了"
    - completeness: "✓ 全評価項目が記載"
  - result: { scripts: 35 }

- [x] **p_final.3**: 22 SKILL.md の評価が記録されている
  - executor: claudecode
  - validations:
    - technical: "✓ grep -c '\\.md' = 41（.md参照）"
    - consistency: "✓ 関連 subtask が完了"
    - completeness: "✓ 全評価項目が記載"
  - result: { skill_md: 22 }

- [x] **p_final.4**: 10 SubAgent 定義の評価が記録されている
  - executor: claudecode
  - validations:
    - technical: "✓ SubAgent セクションに記載"
    - consistency: "✓ 関連 subtask が完了"
    - completeness: "✓ 全評価項目が記載"
  - result: { subagents: 10 }

- [x] **p_final.5**: 各ファイルに Next Action が明記されている
  - executor: claudecode
  - validations:
    - technical: "✓ grep -c '| keep |' = 75（74ファイル+ヘッダ）"
    - consistency: "✓ 評価結果から論理的に導出"
    - completeness: "✓ 全て keep（fix/review/candidate_remove = 0）"
  - result: { next_actions: 74, all_keep: true }

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done
  - result: "Total files: 287, Hooks: 7, Agents: 10, Skills: 22"

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: done
  - result: "cleaned"

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done
