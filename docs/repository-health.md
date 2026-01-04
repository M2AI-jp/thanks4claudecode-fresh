# repository-health.md

> **リポジトリ健全性の判定基準と抽出結果**
>
> 判定は証拠ベース（参照箇所 + 実行結果）で行う。

---

## 1. 判定基準

### 必須（required）

このファイルが存在しないと **コア契約のいずれかが破綻する**もの。

### 壊れている必須（required_broken）

必須だが **実行エラー/期待動作しない**もの。

### 不要（optional）

削除しても **コア契約が維持される**もの。

---

## 2. 証拠フォーマット

- **reference**: 参照箇所（ファイル/行）
- **evidence**: 実行結果（exit code + stdout/stderr）
- **decision**: required / required_broken / optional / undetermined

例:

```
component: .claude/hooks/pre-tool.sh
reference: .claude/settings.json:PreToolUse
evidence: bash -n .claude/hooks/pre-tool.sh (exit 0)
decision: required
```

---

## 3. 依存抽出手法

> hooks → skills → agents の実参照チェーンを起点に抽出する。

```
rg --no-filename "invoke_skill|source.*skill" .claude/hooks/
rg "subagent_type=" .claude/
rg -l "guards/|handlers/|agents/" .claude/skills/*/SKILL.md
```

- 参照切れは required_broken に分類
- 参照先は `test -f` などで実在確認する

---

## 4. playbook 生成方針

- SSOT は `docs/repository-health.md`
- `required_broken` は 1 件 = 1 playbook の単位で扱う
- 生成タイミングはユーザー指示またはメンテナンス実行時
- playbook の `derives_from` には該当コンポーネントのパスを記載する
- 実行の起点はユーザー指示に依存するが、対象は required_broken の上から順に固定する

---

## 5. 抽出結果（Inventory）

> 依存抽出: `rg` / `test -f` / `test -x` の結果を根拠に記載。

### Hooks

| component | reference | evidence | decision | notes |
|---|---|---|---|---|
| .claude/hooks/pre-tool.sh | .claude/settings.json:23-31 | test -x .claude/hooks/pre-tool.sh (exit 0) | required | PreToolUse ゲート |
| .claude/hooks/post-tool.sh | .claude/settings.json:35-43 | test -x .claude/hooks/post-tool.sh (exit 0) | required | PostToolUse 処理 |
| .claude/hooks/session.sh | .claude/settings.json:47-55 | test -x .claude/hooks/session.sh (exit 0) | required | SessionStart |
| .claude/hooks/prompt.sh | .claude/settings.json:59-67 | test -x .claude/hooks/prompt.sh (exit 0) | required | UserPromptSubmit |
| .claude/hooks/subagent-stop.sh | .claude/settings.json:71-79 | test -x .claude/hooks/subagent-stop.sh (exit 0) | required | SubagentStop |
| .claude/events/pre-compact/chain.sh | .claude/settings.json:89 | test -f .claude/events/pre-compact/chain.sh (exit 0) | required | PreCompact |
| .claude/events/stop/chain.sh | .claude/settings.json:95-103 | test -f .claude/events/stop/chain.sh (exit 0) | required | Stop |
| .claude/events/session-end/chain.sh | .claude/settings.json:108-114 | test -f .claude/events/session-end/chain.sh (exit 0) | required | SessionEnd |
| .claude/events/notification/chain.sh | .claude/settings.json:119-125 | test -f .claude/events/notification/chain.sh (exit 0) | required | Notification |

### Event Units

| component | reference | evidence | decision | notes |
|---|---|---|---|---|
| .claude/events/session-start/chain.sh | .claude/hooks/session.sh:31 | test -f .claude/events/session-start/chain.sh (exit 0) | required | SessionStart chain |
| .claude/events/user-prompt-submit/chain.sh | .claude/hooks/prompt.sh:9 | test -f .claude/events/user-prompt-submit/chain.sh (exit 0) | required | UserPromptSubmit chain |
| .claude/events/pre-tool-edit/chain.sh | .claude/hooks/pre-tool.sh:94 | test -f .claude/events/pre-tool-edit/chain.sh (exit 0) | required | PreToolUse(Edit/Write) chain |
| .claude/events/pre-tool-bash/chain.sh | .claude/hooks/pre-tool.sh:97 | test -f .claude/events/pre-tool-bash/chain.sh (exit 0) | required | PreToolUse(Bash) chain |
| .claude/events/post-tool-edit/chain.sh | .claude/hooks/post-tool.sh:41 | test -f .claude/events/post-tool-edit/chain.sh (exit 0) | required | PostToolUse(Edit) chain |
| .claude/events/subagent-stop/chain.sh | .claude/hooks/subagent-stop.sh:9 | test -f .claude/events/subagent-stop/chain.sh (exit 0) | required | SubagentStop chain |
| .claude/events/pre-compact/chain.sh | .claude/settings.json:89 | test -f .claude/events/pre-compact/chain.sh (exit 0) | required | PreCompact chain |
| .claude/events/stop/chain.sh | .claude/settings.json:95-103 | test -f .claude/events/stop/chain.sh (exit 0) | required | Stop chain |
| .claude/events/session-end/chain.sh | .claude/settings.json:108-114 | test -f .claude/events/session-end/chain.sh (exit 0) | required | SessionEnd chain |
| .claude/events/notification/chain.sh | .claude/settings.json:119-125 | test -f .claude/events/notification/chain.sh (exit 0) | required | Notification chain |

### Skills

#### required

| component | reference | evidence | decision | notes |
|---|---|---|---|---|
| session-manager | .claude/hooks/pre-tool.sh:75-76 | test -x .claude/skills/session-manager/handlers/init-guard.sh (exit 0) | required | init-guard + session lifecycle |
| access-control | .claude/hooks/pre-tool.sh:78-86 | test -x .claude/skills/access-control/guards/main-branch.sh (exit 0) | required | main/protected/bash guard |
| post-loop | .claude/hooks/pre-tool.sh:83-84 | test -x .claude/skills/post-loop/guards/pending-guard.sh (exit 0) | required | pending ガード |
| playbook-gate | .claude/hooks/pre-tool.sh:88-92 | test -x .claude/skills/playbook-gate/guards/playbook-guard.sh (exit 0) | required | playbook gate + workflow |
| reward-guard | .claude/hooks/pre-tool.sh:94-100 | test -x .claude/skills/reward-guard/guards/critic-guard.sh (exit 0) | required | critic/scope/subtask guard |
| quality-assurance | .claude/hooks/pre-tool.sh:108 | test -x .claude/skills/quality-assurance/checkers/lint.sh (exit 0) | required | lint/coherence |
| git-workflow | .claude/hooks/post-tool.sh:37 | test -x .claude/skills/git-workflow/handlers/create-pr-hook.sh (exit 0) | required | PR 補助 |
| prompt-analyzer | .claude/hooks/prompt.sh:94-95 | test -f .claude/skills/prompt-analyzer/agents/prompt-analyzer.md (exit 0) | required | pre-tool の前提 |
| playbook-init | CLAUDE.md:core_contract.golden_path | test -f .claude/skills/playbook-init/SKILL.md (exit 0) | required | golden path エントリ |
| golden-path | CLAUDE.md:core_contract.golden_path | test -f .claude/skills/golden-path/SKILL.md (exit 0) | required | Core Contract #1 |
| understanding-check | CLAUDE.md:core_contract.golden_path | test -f .claude/skills/understanding-check/SKILL.md (exit 0) | required | pm 必須手順 |
| term-translator | .claude/skills/golden-path/agents/pm.md:86 | test -f .claude/skills/term-translator/agents/term-translator.md (exit 0) | required | 曖昧さ変換 |
| executor-resolver | .claude/skills/golden-path/agents/pm.md:91 | test -f .claude/skills/executor-resolver/agents/executor-resolver.md (exit 0) | required | executor 判定 |
| plan-management | .claude/skills/golden-path/agents/pm.md:6 | test -f .claude/skills/plan-management/SKILL.md (exit 0) | required | pm 依存 |
| state | .claude/skills/golden-path/agents/pm.md:6 | test -f .claude/skills/state/SKILL.md (exit 0) | required | pm 依存 |

#### required_broken

| component | reference | evidence | decision | notes |
|---|---|---|---|---|
| .claude/skills/playbook-gate/workflow/generate-repository-map.sh | .claude/skills/playbook-gate/workflow/cleanup.sh:85 | test -f .claude/skills/playbook-gate/workflow/generate-repository-map.sh (exit 1) | required_broken | 実体は .claude/hooks/generate-repository-map.sh |
| .claude/skills/access-control/lib/contract.sh | .claude/skills/access-control/SKILL.md:18-26 | test -f .claude/skills/access-control/lib/contract.sh (exit 1) | required_broken | 実体は scripts/contract.sh |

#### optional

なし（core 以外の手動 Skill は削除済み）

### SubAgents

| component | reference | evidence | decision | notes |
|---|---|---|---|---|
| prompt-analyzer | .claude/hooks/prompt.sh:94-95 | test -f .claude/skills/prompt-analyzer/agents/prompt-analyzer.md (exit 0) | required | 解析必須 |
| pm | .claude/skills/playbook-init/SKILL.md:190 | test -f .claude/skills/golden-path/agents/pm.md (exit 0) | required | playbook 作成 |
| critic | .claude/skills/reward-guard/SKILL.md:68 | test -f .claude/skills/reward-guard/agents/critic.md (exit 0) | required | done 検証 |
| reviewer | .claude/skills/quality-assurance/SKILL.md:61 | test -f .claude/skills/quality-assurance/agents/reviewer.md (exit 0) | required | playbook レビュー |
| term-translator | .claude/skills/golden-path/agents/pm.md:86 | test -f .claude/skills/term-translator/agents/term-translator.md (exit 0) | required | 曖昧さ変換 |
| executor-resolver | .claude/skills/golden-path/agents/pm.md:91 | test -f .claude/skills/executor-resolver/agents/executor-resolver.md (exit 0) | required | executor 判定 |
| codex-delegate | .claude/skills/playbook-gate/guards/executor-guard.sh:268-271 | test -f .claude/skills/golden-path/agents/codex-delegate.md (exit 0) | required | executor=codex 時 |
| coderabbit-delegate | .claude/skills/playbook-gate/guards/executor-guard.sh:290-293 | test -f .claude/skills/quality-assurance/agents/coderabbit-delegate.md (exit 0) | required | executor=coderabbit 時 |
| health-checker | .claude/skills/quality-assurance/SKILL.md:73 | test -f .claude/skills/quality-assurance/agents/health-checker.md (exit 0) | optional | 任意監視 |
| setup-guide | docs/ARCHITECTURE.md:661 | test -f .claude/skills/session-manager/agents/setup-guide.md (exit 0) | optional | setup 専用 |

### Supporting files

| component | reference | evidence | decision | notes |
|---|---|---|---|---|
| .claude/settings.json | .claude/hooks/pre-tool.sh:15 | test -f .claude/settings.json (exit 0) | required | Hook 設定 |
| scripts/contract.sh | .claude/hooks/pre-tool.sh:10-33 | test -f scripts/contract.sh (exit 0) | required | Bash 契約判定 |
| .claude/schema/state-schema.sh | .claude/skills/session-manager/handlers/start.sh:43 | test -f .claude/schema/state-schema.sh (exit 0) | required | state スキーマ |
| .claude/protected-files.txt | .claude/skills/access-control/guards/protected-edit.sh:37 | test -f .claude/protected-files.txt (exit 0) | required | HARD_BLOCK |
| .claude/lib/common.sh | .claude/hooks/pre-tool.sh:15 | test -f .claude/lib/common.sh (exit 0) | optional | 共通関数 |
| .claude/hooks/generate-repository-map.sh | .claude/skills/session-manager/handlers/start.sh:98 | test -f .claude/hooks/generate-repository-map.sh (exit 0) | optional | map 自動生成 |

### Frameworks

| component | reference | evidence | decision | notes |
|---|---|---|---|---|
| .claude/frameworks/done-criteria-validation.md | .claude/skills/reward-guard/agents/critic.md:531-543 | test -f .claude/frameworks/done-criteria-validation.md (exit 0) | required | critic 必須 |
| .claude/frameworks/playbook-review-criteria.md | .claude/skills/quality-assurance/agents/reviewer.md:14-30 | test -f .claude/frameworks/playbook-review-criteria.md (exit 0) | required | reviewer 必須 |
| .claude/frameworks/playbook-reviewer-spec.md | .claude/skills/quality-assurance/agents/reviewer.md:15 | test -f .claude/frameworks/playbook-reviewer-spec.md (exit 0) | required | reviewer LOOP |

### Docs

| component | reference | evidence | decision | notes |
|---|---|---|---|---|
| CLAUDE.md | .claude/protected-files.txt:12 | test -f CLAUDE.md (exit 0) | required | コア契約 |
| state.md | .claude/skills/session-manager/handlers/init-guard.sh:30-38 | test -f state.md (exit 0) | required | SSOT |
| docs/ARCHITECTURE.md | .claude/skills/session-manager/handlers/start.sh:131 | test -f docs/ARCHITECTURE.md (exit 0) | required | 参照ガイド |
| docs/core-feature-reclassification.md | docs/core-feature-reclassification.md:1 | test -f docs/core-feature-reclassification.md (exit 0) | required | Hook Unit 目録 |
| docs/repository-map.yaml | .claude/skills/session-manager/handlers/start.sh:53 | test -f docs/repository-map.yaml (exit 0) | required | マップ参照 |
| docs/criterion-validation-rules.md | .claude/skills/golden-path/agents/pm.md:421 | test -f docs/criterion-validation-rules.md (exit 0) | required | criterion ルール |
| docs/ai-orchestration.md | .claude/skills/golden-path/agents/pm.md:131 | test -f docs/ai-orchestration.md (exit 0) | required | executor 指針 |
| docs/git-operations.md | .claude/skills/golden-path/agents/pm.md:891 | test -f docs/git-operations.md (exit 0) | required | git 指針 |
| docs/folder-management.md | .claude/skills/playbook-gate/workflow/cleanup.sh:16 | test -f docs/folder-management.md (exit 0) | required | tmp 方針 |
| docs/archive-operation-rules.md | .claude/skills/playbook-gate/workflow/archive-playbook.sh:29 | test -f docs/archive-operation-rules.md (exit 0) | required | アーカイブ規則 |
| docs/repository-health.md | docs/repository-health.md:1 | test -f docs/repository-health.md (exit 0) | required | 健全性 SSOT |

---

## 6. メンテナンス方針

- **修復**: required_broken を最優先で修復し、該当行の decision を required に更新する。
- **削除**: optional のうち `rg` で参照が見つからないものは削除候補に移動する。
- **保留**: optional だが運用上の手動ガイドとして必要なものは維持（説明は docs/ARCHITECTURE.md に統合）。
- **同期**: docs/repository-map.yaml は自動生成対象のため、workflows 更新時は .claude/hooks/generate-repository-map.sh も更新する。
