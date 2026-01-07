# 設計と実装の乖離レポート

> **Project**: design-validation
> **Milestone**: m1 - Gap Analysis and Prioritization
> **Generated**: 2026-01-07
> **Source Documents**:
> - docs/ARCHITECTURE.md
> - docs/core-feature-reclassification.md

---

## Executive Summary

設計図（docs/ARCHITECTURE.md, docs/core-feature-reclassification.md）と現在の実装を比較した結果：

- **機能面**: 設計通り実装済み（Hook dispatcher, Event Unit chain, Skill/SubAgent）
- **構造面**: Hook Unit component 分割が未実装（validator/telemetry/snapshot 等）
- **ドキュメント**: 一部のパス参照とステータス記載に drift あり

**総合評価**: 設計の機能要件は達成。構造的完全性（component 分割）は将来課題。

---

## 乖離一覧（優先度付き）

### High Priority

| # | カテゴリ | 乖離内容 | 影響 | 対応案 |
|---|---------|---------|------|--------|
| (なし) | - | - | - | - |

**High 乖離はなし** - 機能は全て動作している。

---

### Medium Priority

| # | カテゴリ | 乖離内容 | 影響 | 対応案 |
|---|---------|---------|------|--------|
| M1 | Hook Unit Component | telemetry.sh が全 Unit で未実装 | 運用監視不可 | 優先実装（10 Unit 分） |
| M2 | Documentation | Stop Hook が "no-op" 記載だが completion-check.sh 実装済み | 設計理解の混乱 | ARCHITECTURE.md Section 14.3 更新 |
| M3 | Project Hierarchy | project 運用ロジックが pm/state に統合されていない | project 機能が手動 | pm.md と state Skill の拡張 |

---

### Low Priority

| # | カテゴリ | 乖離内容 | 影響 | 対応案 |
|---|---------|---------|------|--------|
| L1 | パス参照 | `scripts/contract.sh` → 実際は `.claude/lib/contract.sh` | ドキュメント不整合 | ARCHITECTURE.md Section 13 更新 |
| L2 | Missing File | `failure-logger.sh` が不存在 | なし（存在チェック済み） | 実装 or 参照削除 |
| L3 | Missing File | `playbook-gate/workflow/generate-repository-map.sh` が不存在 | なし（hooks 版存在） | パス参照を修正 |
| L4 | Missing File | `access-control/lib/contract.sh` が不存在 | なし（.claude/lib 版存在） | パス参照を修正 |
| L5 | Hook Unit Component | validator.sh が全 Unit で未実装 | 入力検証が chain.sh に混在 | 将来分割 |
| L6 | Hook Unit Component | context-injector.sh が未実装（2 Unit） | 機能は実装済み | 将来分割 |
| L7 | Hook Unit Component | snapshot.sh が未実装（4 Unit） | 事前状態保存なし | 将来実装 |
| L8 | Hook Unit Component | guardrail.sh が未実装（2 Unit） | 機能は guard scripts に実装 | 将来分割 |
| L9 | Hook Unit Component | retry.sh が未実装（1 Unit） | リトライ機構なし | 将来実装 |

---

## 詳細分析レポート

| レポートファイル | 内容 |
|-----------------|------|
| `architecture-mapping-1-7.md` | ARCHITECTURE.md セクション 1-7 の設計と実装の対応 |
| `architecture-gaps-8-14.md` | ARCHITECTURE.md セクション 8-14 の乖離特定 |
| `hook-unit-gaps.md` | Hook Unit 目録（10 Unit）と実装の component 分割状況 |
| `skill-subagent-evaluation.md` | Skill/SubAgent 評価と実装の整合性確認 |

---

## 整合している項目

以下は設計通り実装されている：

### Hook Infrastructure
- ✓ Hook dispatcher（6ファイル）: session.sh, prompt.sh, pre-tool.sh, post-tool.sh, subagent-stop.sh, generate-repository-map.sh
- ✓ Event Unit chain.sh（10 Unit）: 全 Hook イベントに対応
- ✓ settings.json: 全 Hook イベント登録済み

### Skills
- ✓ Core Skills（13）: 全て実装済み
- ✓ Remove 判定（2）: 削除済み（term-translator, plan-management）

### SubAgents
- ✓ Core SubAgents（5）: pm, reviewer, critic, prompt-analyzer, executor-resolver
- ✓ Conditional SubAgents（2）: codex-delegate, coderabbit-delegate
- ✓ Remove 判定（3）: 削除済み
- ✓ Registry（.claude/agents/）: 7 SubAgent 登録済み

### Templates & Frameworks
- ✓ play/template/plan.json
- ✓ play/template/progress.json
- ✓ .claude/frameworks/*.md（3ファイル）

### Guards
- ✓ 全 guard スクリプト実装済み（15ファイル）

### Workflow
- ✓ archive-playbook.sh
- ✓ cleanup.sh
- ✓ create-pr.sh / merge-pr.sh

---

## 推奨アクション

### 即時（このプロジェクト内）

1. **M2**: ARCHITECTURE.md Section 14.3 の Stop Hook ステータスを更新
2. **L1-L4**: パス参照のドキュメント更新

### 次期マイルストーン（m2）

1. **M3**: project 階層の運用ロジック実装
   - pm.md の project 対応拡張
   - state Skill の project 操作追加
   - archive-playbook.sh の project 対応

### 将来（backlog）

1. **M1**: telemetry.sh の実装（全 10 Unit）
2. **L5-L9**: Hook Unit component 分割
   - validator.sh
   - context-injector.sh
   - snapshot.sh
   - guardrail.sh
   - retry.sh

---

## 結論

設計図（ARCHITECTURE.md, core-feature-reclassification.md）と実装は**機能面で高い整合性**を持っている。

**主な乖離**:
1. Hook Unit の component 分割が未実装（設計の理想形 vs 現実的な実装）
2. ドキュメントの軽微な drift（パス参照、ステータス記載）
3. project 階層の運用ロジック未実装

**推奨**: 機能は動作しているため、ドキュメント更新と project 階層実装を優先し、component 分割は将来課題として扱う。
