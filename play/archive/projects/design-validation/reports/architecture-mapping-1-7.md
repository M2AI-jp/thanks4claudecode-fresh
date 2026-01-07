# ARCHITECTURE.md セクション 1-7 対応リスト

> Generated: 2026-01-07
> Playbook: gap-analysis (p1.1)

---

## Section 0: Hook リファレンス（公式）

| 設計項目 | 実装ファイル | 状態 |
|----------|-------------|------|
| Hook イベント一覧 | (参照ドキュメント) | OK |
| 入力パラメータ（stdin JSON） | 各 chain.sh で使用 | OK |
| Exit Code の意味 | 各 guard で使用 | OK |
| JSON 出力（高度な制御） | compact.sh, archive-playbook.sh で使用 | OK |

---

## Section 1: SessionStart

| 設計項目 | 実装ファイル | 状態 |
|----------|-------------|------|
| Dispatcher | `.claude/hooks/session.sh` | ✓ 存在 |
| Event Unit | `.claude/events/session-start/chain.sh` | ✓ 存在 |
| Handler | `.claude/skills/session-manager/handlers/start.sh` | ✓ 存在 |
| Health Check | `.claude/skills/quality-assurance/checkers/health.sh` | ✓ 存在 |
| Integrity Check | `.claude/skills/quality-assurance/checkers/integrity.sh` | ✓ 存在 |

**乖離**: なし

---

## Section 1.5: PreCompact

| 設計項目 | 実装ファイル | 状態 |
|----------|-------------|------|
| Event Unit | `.claude/events/pre-compact/chain.sh` | ✓ 存在 |
| Handler | `.claude/skills/session-manager/handlers/compact.sh` | ✓ 存在 |

**乖離**: なし

---

## Section 2: UserPromptSubmit

| 設計項目 | 実装ファイル | 状態 |
|----------|-------------|------|
| Dispatcher | `.claude/hooks/prompt.sh` | ✓ 存在 |
| Event Unit | `.claude/events/user-prompt-submit/chain.sh` | ✓ 存在 |
| prompt-analyzer | `.claude/skills/prompt-analyzer/agents/prompt-analyzer.md` | ✓ 存在 |
| understanding-check | `.claude/skills/understanding-check/SKILL.md` | 要確認 |
| playbook-init | `.claude/skills/playbook-init/SKILL.md` | ✓ 存在 |
| pm SubAgent | `.claude/skills/golden-path/agents/pm.md` | ✓ 存在 |
| reviewer SubAgent | `.claude/skills/quality-assurance/agents/reviewer.md` | ✓ 存在 |

**乖離**: understanding-check SKILL.md の存在確認が必要

---

## Section 3: PreToolUse:* (全ツール共通)

| 設計項目 | 実装ファイル | 状態 |
|----------|-------------|------|
| Dispatcher | `.claude/hooks/pre-tool.sh` | ✓ 存在 |
| init-guard | `.claude/skills/session-manager/handlers/init-guard.sh` | ✓ 存在 |
| main-branch guard | `.claude/skills/access-control/guards/main-branch.sh` | ✓ 存在 |

**乖離**: なし

---

## Section 4: PreToolUse:Edit/Write

| 設計項目 | 実装ファイル | 状態 |
|----------|-------------|------|
| Event Unit | `.claude/events/pre-tool-edit/chain.sh` | ✓ 存在 |
| pending-guard | `.claude/skills/post-loop/guards/pending-guard.sh` | ✓ 存在 |
| protected-edit | `.claude/skills/access-control/guards/protected-edit.sh` | ✓ 存在 |
| playbook-guard | `.claude/skills/playbook-gate/guards/playbook-guard.sh` | ✓ 存在 |
| depends-check | `.claude/skills/playbook-gate/guards/depends-check.sh` | ✓ 存在 |
| executor-guard | `.claude/skills/playbook-gate/guards/executor-guard.sh` | ✓ 存在 |
| critic-guard | `.claude/skills/reward-guard/guards/critic-guard.sh` | ✓ 存在 |
| subtask-guard | `.claude/skills/reward-guard/guards/subtask-guard.sh` | ✓ 存在 |
| phase-status-guard | `.claude/skills/reward-guard/guards/phase-status-guard.sh` | ✓ 存在 |
| scope-guard | `.claude/skills/reward-guard/guards/scope-guard.sh` | ✓ 存在 |

**乖離**: なし

---

## Section 5: PreToolUse:Bash

| 設計項目 | 実装ファイル | 状態 |
|----------|-------------|------|
| Event Unit | `.claude/events/pre-tool-bash/chain.sh` | ✓ 存在 |
| bash-check | `.claude/skills/access-control/guards/bash-check.sh` | ✓ 存在 |
| coherence | `.claude/skills/reward-guard/guards/coherence.sh` | ✓ 存在 |
| lint | `.claude/skills/quality-assurance/checkers/lint.sh` | ✓ 存在 |

**乖離**: なし

---

## Section 6: PostToolUse:Edit/Write

| 設計項目 | 実装ファイル | 状態 |
|----------|-------------|------|
| Dispatcher | `.claude/hooks/post-tool.sh` | ✓ 存在 |
| Event Unit | `.claude/events/post-tool-edit/chain.sh` | ✓ 存在 |
| progress-reminder | `.claude/skills/reward-guard/guards/progress-reminder.sh` | ✓ 存在 |
| archive-playbook | `.claude/skills/playbook-gate/workflow/archive-playbook.sh` | ✓ 存在 |
| cleanup | `.claude/skills/playbook-gate/workflow/cleanup.sh` | ✓ 存在 |
| create-pr-hook | `.claude/skills/git-workflow/handlers/create-pr-hook.sh` | ✓ 存在 |
| create-pr | `.claude/skills/git-workflow/handlers/create-pr.sh` | ✓ 存在 |
| merge-pr | `.claude/skills/git-workflow/handlers/merge-pr.sh` | ✓ 存在 |

**乖離**: なし

---

## Section 6.5: Stop

| 設計項目 | 実装ファイル | 状態 |
|----------|-------------|------|
| Event Unit | `.claude/events/stop/chain.sh` | ✓ 存在 |
| completion-check | `.claude/skills/reward-guard/guards/completion-check.sh` | ✓ 存在 |

**乖離**: ARCHITECTURE.md Section 14.3 では Stop が "no-op" と記載されているが、completion-check.sh が実装済み（ドキュメント更新必要）

---

## Summary (Section 1-7)

| セクション | 状態 | 乖離 |
|-----------|------|------|
| 0. Hook リファレンス | ✓ OK | なし |
| 1. SessionStart | ✓ OK | なし |
| 1.5. PreCompact | ✓ OK | なし |
| 2. UserPromptSubmit | △ 要確認 | understanding-check SKILL.md 確認必要 |
| 3. PreToolUse:* | ✓ OK | なし |
| 4. PreToolUse:Edit/Write | ✓ OK | なし |
| 5. PreToolUse:Bash | ✓ OK | なし |
| 6. PostToolUse:Edit/Write | ✓ OK | なし |
| 6.5. Stop | △ ドキュメント要更新 | 実装済みだがドキュメントが "no-op" |

**総合**: セクション 1-7 は概ね設計通り実装されている。主要な乖離は documentation drift のみ。
