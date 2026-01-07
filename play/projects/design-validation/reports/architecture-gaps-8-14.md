# ARCHITECTURE.md セクション 8-14 乖離レポート

> Generated: 2026-01-07
> Playbook: gap-analysis (p1.2)

---

## Section 7: SubAgent 呼び出し（Task ツール）

| 設計項目 | 実装ファイル | 状態 | 乖離 |
|----------|-------------|------|------|
| pm SubAgent | `.claude/agents/pm.md` | ✓ 存在 | なし |
| reviewer SubAgent | `.claude/agents/reviewer.md` | ✓ 存在 | なし |
| critic SubAgent | `.claude/agents/critic.md` | ✓ 存在 | なし |
| codex-delegate SubAgent | `.claude/agents/codex-delegate.md` | ✓ 存在 | なし |
| coderabbit-delegate SubAgent | `.claude/agents/coderabbit-delegate.md` | ✓ 存在 | なし |
| prompt-analyzer | `.claude/agents/prompt-analyzer.md` | ✓ 存在 | なし |
| executor-resolver | `.claude/agents/executor-resolver.md` | ✓ 存在 | なし |

**乖離**: なし（7 SubAgent 全て登録済み）

---

## Section 8: Skills 一覧と内部構成

| Skill | 設計の構造 | 実装状況 | 乖離 |
|-------|-----------|----------|------|
| session-manager | handlers/init-guard, start, end, compact | ✓ 全存在 | なし |
| access-control | guards/main-branch, protected-edit, bash-check | ✓ 全存在 | なし |
| playbook-gate | guards/playbook-guard, depends-check, executor-guard, role-resolver + workflow/archive, cleanup | ✓ 全存在 | なし |
| reward-guard | agents/critic + guards/critic-guard, subtask-guard, phase-status-guard, scope-guard, coherence | ✓ 全存在 | なし |
| quality-assurance | agents/reviewer, coderabbit-delegate + checkers/lint, integrity, health | ✓ 全存在 | なし |
| golden-path | agents/pm, codex-delegate | ✓ 全存在 | なし |
| git-workflow | handlers/create-pr-hook, create-pr, merge-pr | ✓ 全存在 | なし |
| post-loop | guards/pending-guard + handlers/complete | ✓ 全存在 | なし |
| executor-resolver | agents/executor-resolver | ✓ 存在 | なし |
| playbook-init | SKILL.md | ✓ 存在 | なし |
| prompt-analyzer | agents/prompt-analyzer | ✓ 存在 | なし |
| state | SKILL.md | ✓ 存在 | なし |
| understanding-check | SKILL.md | ✓ 存在 | なし |

**乖離**: なし

---

## Section 9: テンプレート・フレームワーク一覧

| 設計項目 | 実装ファイル | 状態 |
|----------|-------------|------|
| play/template/plan.json | ✓ 存在 | OK |
| play/template/progress.json | ✓ 存在 | OK |
| .claude/frameworks/done-criteria-validation.md | ✓ 存在 | OK |
| .claude/frameworks/playbook-review-criteria.md | ✓ 存在 | OK |
| .claude/frameworks/playbook-reviewer-spec.md | ✓ 存在 | OK |

**乖離**: なし

---

## Section 10-12: 情報フロー図・SSOT・コア契約

これらは設計ドキュメントであり、実装ファイルとの対応は Section 1-8 で確認済み。

**乖離**: なし（設計記述として機能）

---

## Section 13: 補助モジュール（MECE 補完）

| 設計項目 | 実装ファイル | 状態 | 乖離 |
|----------|-------------|------|------|
| scripts/contract.sh | ✗ 不存在 | **乖離** | 設計では scripts/ だが実装は .claude/lib/contract.sh |
| .claude/lib/contract.sh | ✓ 存在 | OK | 実装あり |
| .claude/agents/ | ✓ 存在 | OK | 7 SubAgent 登録済み |
| .claude/settings.json | ✓ 存在 | OK | Hook 定義あり |
| .claude/protected-files.txt | ✓ 存在 | OK | 保護リストあり |
| .claude/.session-init/ | ✓ 存在 | OK | セッション状態ディレクトリ |
| .mcp.json | ✓ 存在 | OK | MCP 設定あり |

**乖離**:
- `scripts/contract.sh` → 実際は `.claude/lib/contract.sh`（パス違い、ドキュメント更新必要）

---

## Section 14: 既知の課題と未実装

### 14.1 存在しないファイルへの参照

| 設計記載 | 参照元 | 実装状況 | 実際の影響 |
|----------|--------|----------|-----------|
| `.claude/hooks/failure-logger.sh` | playbook-guard.sh | ✗ 不存在 | 低（存在チェックでガード済み） |
| `.claude/skills/playbook-gate/workflow/generate-repository-map.sh` | cleanup.sh | ✗ 不存在 | 低（.claude/hooks/ に存在） |
| `.claude/skills/access-control/lib/contract.sh` | access-control SKILL.md | ✗ 不存在 | 低（.claude/lib/contract.sh に存在） |

### 14.2 設計されたが未実装の機能

| 機能 | 状態 | 優先度 |
|------|------|--------|
| failure-logger.sh | 未実装 | Low |
| doc-freshness-check.sh | 未実装 | Low |
| update-tracker.sh | 未実装 | Low |

### 14.3 Hook イベント（no-op chain）

| Hook | 設計記載 | 実際の実装 | 乖離 |
|------|---------|-----------|------|
| Stop | no-op | **completion-check.sh 実装済み** | **ドキュメント更新必要** |
| SessionEnd | wired | end.sh 実装済み | なし |
| Notification | no-op | no-op | なし |

### 14.4 設計と実装の乖離

| セクション | 設計 | 実装状態 | 乖離 |
|-----------|------|---------|------|
| Section 1 | health.sh を SessionStart から呼出 | ✓ 実装済み | なし |
| Playbook v2 | plan.json + progress.json | ✓ 実装済み | なし |
| Stop Hook | no-op | **completion-check.sh 実装済み** | **ドキュメント要更新** |

---

## Summary (Section 8-14)

### 乖離一覧

| # | カテゴリ | 乖離内容 | 優先度 | 対応案 |
|---|---------|---------|--------|--------|
| 1 | パス違い | `scripts/contract.sh` → `.claude/lib/contract.sh` | Low | ドキュメント更新 |
| 2 | 不存在 | `failure-logger.sh` | Low | 実装 or 参照削除 |
| 3 | 不存在 | `playbook-gate/workflow/generate-repository-map.sh` | Low | パス参照修正 |
| 4 | 不存在 | `access-control/lib/contract.sh` | Low | パス参照修正 |
| 5 | ドキュメント | Stop Hook が "no-op" 記載だが実装あり | Medium | ドキュメント更新 |

### 総合評価

セクション 8-14 の実装は設計と概ね整合している。主な乖離は：
- **パス参照の不一致**: ドキュメント上のパスと実際のパスが異なる（3件）
- **ドキュメント drift**: Stop Hook の実装状況がドキュメントに反映されていない（1件）

重大な機能乖離はない。
