# Skill/SubAgent 評価と整合性レポート

> Generated: 2026-01-07
> Playbook: gap-analysis (p2.2)
> Source: docs/core-feature-reclassification.md Section 12

---

## Skills 評価（セクション 12 より）

### Core Skills（判定: keep）

| Skill | Hook Unit | 設計判定 | 実装状況 | 整合性 |
|-------|-----------|---------|----------|--------|
| session-manager | session-start, pre-compact, session-end | core / keep | ✓ handlers/: init-guard, start, end, compact | ✓ OK |
| prompt-analyzer | user-prompt-submit | core / keep | ✓ agents/prompt-analyzer.md | ✓ OK |
| understanding-check | user-prompt-submit | core / keep | ✓ SKILL.md | ✓ OK |
| playbook-init | user-prompt-submit | core / keep | ✓ SKILL.md | ✓ OK |
| golden-path | user-prompt-submit | core / keep | ✓ agents/pm.md, codex-delegate.md | ✓ OK |
| state | user-prompt-submit, pre-tool-edit | core / keep | ✓ SKILL.md | ✓ OK |
| access-control | pre-tool-edit, pre-tool-bash | core / keep | ✓ guards/: main-branch, protected-edit, bash-check | ✓ OK |
| post-loop | pre-tool-edit | core / keep | ✓ guards/pending-guard, handlers/complete | ✓ OK |
| playbook-gate | pre-tool-edit, post-tool-edit | core / keep | ✓ guards/ + workflow/ | ✓ OK |
| reward-guard | pre-tool-edit, pre-tool-bash | core / keep | ✓ guards/ + agents/critic | ✓ OK |
| quality-assurance | session-start, pre-tool-bash | core / keep | ✓ checkers/ + agents/ | ✓ OK |
| executor-resolver | pre-tool-edit | core / keep | ✓ agents/executor-resolver.md | ✓ OK |
| git-workflow | post-tool-edit | conditional / keep | ✓ handlers/: create-pr, merge-pr | ✓ OK |

### Remove 判定された Skills

| Skill | 設計判定 | 実装状況 | 整合性 |
|-------|---------|----------|--------|
| term-translator | remove (prompt-analyzer に統合) | ✗ 不存在 | ✓ OK（削除済み） |
| plan-management | remove (pm/state に統合) | ✗ 不存在 | ✓ OK（削除済み） |

---

## SubAgents 評価（セクション 12 より）

### Core SubAgents（判定: keep）

| SubAgent | Hook Unit | 設計判定 | 実装状況 | 整合性 |
|----------|-----------|---------|----------|--------|
| pm | user-prompt-submit | core / keep | ✓ .claude/agents/pm.md | ✓ OK |
| reviewer | user-prompt-submit | core / keep | ✓ .claude/agents/reviewer.md | ✓ OK |
| critic | pre-tool-edit | core / keep | ✓ .claude/agents/critic.md | ✓ OK |
| prompt-analyzer | user-prompt-submit | core / keep | ✓ .claude/agents/prompt-analyzer.md | ✓ OK |
| executor-resolver | pre-tool-edit | core / keep | ✓ .claude/agents/executor-resolver.md | ✓ OK |

### Conditional SubAgents

| SubAgent | 設計判定 | 条件 | 実装状況 | 整合性 |
|----------|---------|------|----------|--------|
| codex-delegate | conditional | codex 運用時 | ✓ .claude/agents/codex-delegate.md | ✓ OK |
| coderabbit-delegate | conditional | coderabbit 運用時 | ✓ .claude/agents/coderabbit-delegate.md | ✓ OK |

### Remove 判定された SubAgents

| SubAgent | 設計判定 | 実装状況 | 整合性 |
|----------|---------|----------|--------|
| term-translator | remove (prompt-analyzer に統合) | ✗ 不存在 | ✓ OK（削除済み） |
| health-checker | remove (unit に配線しないなら削除) | ✗ 不存在 | ✓ OK（削除済み） |
| setup-guide | remove (setup playbook を使わないなら削除) | ✗ 不存在 | ✓ OK（削除済み） |

---

## SubAgent Registry 確認

設計: `.claude/agents/` が Task の参照ディレクトリ

```
.claude/agents/
├── pm.md
├── reviewer.md
├── critic.md
├── prompt-analyzer.md
├── executor-resolver.md
├── codex-delegate.md
└── coderabbit-delegate.md
```

**実装状況**: 7 SubAgent 全て登録済み ✓

---

## Summary

### 整合性チェック結果

| カテゴリ | 設計 | 実装 | 整合性 |
|---------|------|------|--------|
| Core Skills | 13 | 13 | ✓ 100% |
| Remove Skills | 2 | 0（削除済み） | ✓ OK |
| Core SubAgents | 5 | 5 | ✓ 100% |
| Conditional SubAgents | 2 | 2 | ✓ 100% |
| Remove SubAgents | 3 | 0（削除済み） | ✓ OK |
| SubAgent Registry | 7 | 7 | ✓ 100% |

### 乖離

**なし** - Skill/SubAgent の実装は設計と完全に整合している。

### 補足

- remove 判定された Skill/SubAgent は全て削除済み
- conditional 判定の codex-delegate, coderabbit-delegate は実装済み（toolstack: C で使用可能）
- SubAgent の tools 制限は各 agent 定義ファイル内で設定されている
