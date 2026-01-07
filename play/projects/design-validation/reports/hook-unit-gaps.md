# Hook Unit 目録と実装の乖離レポート

> Generated: 2026-01-07
> Playbook: gap-analysis (p2.1)
> Source: docs/core-feature-reclassification.md Section 10

---

## Hook Unit 目録（理想 -> 現状 -> 欠落）

### session-start

| コンポーネント | 設計（理想） | 実装状況 | 乖離 |
|---------------|-------------|----------|------|
| validator.sh | 入力検証 | ✗ 未実装 | **missing** |
| context-injector.sh | 状態注入 | ✗ 未実装 | **missing** |
| telemetry.sh | 記録 | ✗ 未実装 | **missing** |
| guardrail.sh | 遮断 | ✗ 未実装 | **missing** |
| chain.sh | ✓ | ✓ 実装済み | OK |
| session-manager/start.sh | ✓ | ✓ 実装済み | OK |
| quality-assurance/health.sh | ✓ | ✓ 実装済み | OK |
| quality-assurance/integrity.sh | ✓ | ✓ 実装済み | OK |

**status**: chain.sh と core handlers は実装済み。component 分割（validator/context-injector/telemetry/guardrail）は未実装。

---

### user-prompt-submit

| コンポーネント | 設計（理想） | 実装状況 | 乖離 |
|---------------|-------------|----------|------|
| validator.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| context-injector.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| telemetry.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| guardrail.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| chain.sh | ✓ | ✓ 実装済み | OK |
| prompt-analyzer | ✓ | ✓ 実装済み | OK |
| understanding-check | ✓ | ✓ 実装済み | OK |
| playbook-init | ✓ | ✓ 実装済み | OK |

**status**: chain.sh と Skill/SubAgent は実装済み。component 分割は未実装。

---

### pre-tool-edit

| コンポーネント | 設計（理想） | 実装状況 | 乖離 |
|---------------|-------------|----------|------|
| validator.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| telemetry.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| snapshot.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| chain.sh | ✓ | ✓ 実装済み | OK |
| init-guard.sh | ✓ | ✓ 実装済み | OK |
| main-branch.sh | ✓ | ✓ 実装済み | OK |
| pending-guard.sh | ✓ | ✓ 実装済み | OK |
| protected-edit.sh | ✓ | ✓ 実装済み | OK |
| playbook-guard.sh | ✓ | ✓ 実装済み | OK |
| depends-check.sh | ✓ | ✓ 実装済み | OK |
| executor-guard.sh | ✓ | ✓ 実装済み | OK |
| critic-guard.sh | ✓ | ✓ 実装済み | OK |
| subtask-guard.sh | ✓ | ✓ 実装済み | OK |
| phase-status-guard.sh | ✓ | ✓ 実装済み | OK |
| scope-guard.sh | ✓ | ✓ 実装済み | OK |

**status**: guardrail 集約で動作中。validator/telemetry/snapshot 分割は未実装。

---

### pre-tool-bash

| コンポーネント | 設計（理想） | 実装状況 | 乖離 |
|---------------|-------------|----------|------|
| validator.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| telemetry.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| retry.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| chain.sh | ✓ | ✓ 実装済み | OK |
| bash-check.sh | ✓ | ✓ 実装済み | OK |
| coherence.sh | ✓ | ✓ 実装済み | OK |
| lint.sh | ✓ | ✓ 実装済み | OK |

**status**: guardrail 集約で動作中。validator/telemetry/retry 分割は未実装。

---

### post-tool-edit

| コンポーネント | 設計（理想） | 実装状況 | 乖離 |
|---------------|-------------|----------|------|
| validator.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| telemetry.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| chain.sh | ✓ | ✓ 実装済み | OK |
| progress-reminder.sh | ✓ | ✓ 実装済み | OK |
| archive-playbook.sh | ✓ | ✓ 実装済み | OK |
| cleanup.sh | ✓ | ✓ 実装済み | OK |
| create-pr-hook.sh | ✓ | ✓ 実装済み | OK |

**status**: chain と workflow は実装済み。validator/telemetry 分割は未実装。

---

### subagent-stop

| コンポーネント | 設計（理想） | 実装状況 | 乖離 |
|---------------|-------------|----------|------|
| validator.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| telemetry.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| chain.sh | ✓ | ✓ 実装済み | OK |
| archive-playbook.sh | ✓ | ✓ 実装済み（疑似呼出） | OK |

**status**: 基本機能は実装済み。validator/telemetry 分割は未実装。

---

### pre-compact

| コンポーネント | 設計（理想） | 実装状況 | 乖離 |
|---------------|-------------|----------|------|
| validator.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| telemetry.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| snapshot.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| chain.sh | ✓ | ✓ 実装済み | OK |
| compact.sh | ✓ | ✓ 実装済み | OK |

**status**: context-injector 機能は compact.sh に実装。validator/telemetry/snapshot 分割は未実装。

---

### stop

| コンポーネント | 設計（理想） | 実装状況 | 乖離 |
|---------------|-------------|----------|------|
| telemetry.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| snapshot.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| chain.sh | ✓ | ✓ 実装済み | OK |
| completion-check.sh | - (no-op 記載) | ✓ **実装済み** | ドキュメント要更新 |

**status**: completion-check.sh が実装済み（ドキュメントとの乖離）。telemetry/snapshot は未実装。

---

### session-end

| コンポーネント | 設計（理想） | 実装状況 | 乖離 |
|---------------|-------------|----------|------|
| validator.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| telemetry.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| snapshot.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| chain.sh | ✓ | ✓ 実装済み | OK |
| end.sh | ✓ | ✓ 実装済み | OK |

**status**: 基本機能は実装済み。validator/telemetry/snapshot 分割は未実装。

---

### notification

| コンポーネント | 設計（理想） | 実装状況 | 乖離 |
|---------------|-------------|----------|------|
| telemetry.sh | ✓ 必要 | ✗ 未実装 | **missing** |
| chain.sh | ✓ | ✓ 実装済み | OK (no-op) |

**status**: no-op のまま。telemetry 未実装。

---

## Summary

### Component 分割状況

| コンポーネント | 実装済み Unit 数 | 未実装 Unit 数 |
|---------------|-----------------|---------------|
| validator.sh | 0 | 9 |
| context-injector.sh | 0 | 2 |
| telemetry.sh | 0 | 10 |
| guardrail.sh | 0 | 2 |
| snapshot.sh | 0 | 4 |
| retry.sh | 0 | 1 |
| chain.sh | 10 | 0 |

### 機能面の実装状況

| Unit | chain.sh | Core Skill/Handler | Component 分割 |
|------|----------|-------------------|---------------|
| session-start | ✓ | ✓ | ✗ |
| user-prompt-submit | ✓ | ✓ | ✗ |
| pre-tool-edit | ✓ | ✓ | ✗ |
| pre-tool-bash | ✓ | ✓ | ✗ |
| post-tool-edit | ✓ | ✓ | ✗ |
| subagent-stop | ✓ | ✓ | ✗ |
| pre-compact | ✓ | ✓ | ✗ |
| stop | ✓ | ✓ | ✗ |
| session-end | ✓ | ✓ | ✗ |
| notification | ✓ | no-op | ✗ |

### 総合評価

**現状**: 全 Hook Unit の chain.sh と core Skill/Handler は実装済み。機能は動作している。

**未実装**: Hook Unit Interface（Section 8）で定義された component 分割（validator/context-injector/telemetry/guardrail/snapshot/retry）は全 Unit で未実装。

**優先度**:
- **High**: なし（現状で機能は動作）
- **Medium**: telemetry.sh（運用監視に必要）
- **Low**: validator.sh, context-injector.sh, snapshot.sh（設計の完全性のため）
