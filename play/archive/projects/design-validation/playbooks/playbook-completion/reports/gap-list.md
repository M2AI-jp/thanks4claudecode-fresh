# ARCHITECTURE.md と実装の乖離リスト

> Generated: 2026-01-07
> Playbook: playbook-completion (p1.1)
> Source: docs/ARCHITECTURE.md, docs/core-feature-reclassification.md, 実装確認

---

## 1. 概要

この乖離リストは、設計図（ARCHITECTURE.md, core-feature-reclassification.md）と実装の差分を網羅的に列挙する。

---

## 2. Hook Unit Component 分割の乖離

設計（core-feature-reclassification.md Section 8）では各 Hook Unit が以下のコンポーネントを持つべきとされている:
- validator.sh
- context-injector.sh
- guardrail.sh
- telemetry.sh
- retry.sh (optional)
- snapshot.sh (optional)
- chain.sh

### 2.1 実装状況サマリ

| Unit | chain.sh | validator | context-injector | guardrail | telemetry | snapshot | retry |
|------|----------|-----------|------------------|-----------|-----------|----------|-------|
| session-start | OK | - | - | - | - | - | - |
| user-prompt-submit | OK | - | - | - | - | - | - |
| pre-tool-edit | OK | - | - | (guards で代替) | - | - | - |
| pre-tool-bash | OK | - | - | (guards で代替) | - | - | - |
| post-tool-edit | OK | - | - | - | - | - | - |
| subagent-stop | OK | - | - | - | - | - | - |
| pre-compact | OK | - | - | - | - | - | - |
| stop | OK | - | - | - | - | - | - |
| session-end | OK | - | - | - | - | - | - |
| notification | OK (no-op) | - | - | - | - | - | - |

**結論**: chain.sh と core handlers/guards は全 Unit で実装済み。component 分割（validator/context-injector/telemetry/guardrail/snapshot/retry）は全 Unit で未実装。

### 2.2 乖離の severity

| 乖離 | 説明 | severity | 理由 |
|------|------|----------|------|
| validator.sh 未実装 | 入力検証が chain.sh に埋め込み or なし | Low | 現状で機能は動作 |
| context-injector.sh 未実装 | 状態注入が chain.sh に埋め込み | Low | 現状で機能は動作 |
| guardrail.sh 未分離 | guards/*.sh で代替中 | Low | 設計の完全性のみ |
| telemetry.sh 未実装 | 成功/失敗/遅延の記録がない | **Medium** | 運用監視に必要 |
| snapshot.sh 未実装 | 事前状態保存がない | Low | リカバリ機能のため |
| retry.sh 未実装 | 再試行ロジックがない | Low | ネットワーク系のみ |

---

## 3. Project 階層の乖離

設計では project 生成時にも reviewer 検証が必須とされているが、実装されていない。

### 3.1 生成時チェックの乖離

| チェック機能 | Playbook 生成時 | Project 生成時 | 乖離 | severity |
|-------------|----------------|----------------|------|----------|
| prompt-analyzer | OK | - | Gap | Medium |
| understanding-check | OK | - | Gap | Medium |
| reviewer 検証 | OK (4QV+ PASS 必須) | - | **Critical Gap** | **Critical** |
| meta.reviewed | OK (plan.json に存在) | - (project.json にない) | Gap | Medium |
| meta.reviewed_by | OK (plan.json に存在) | - (project.json にない) | Gap | Medium |

### 3.2 完了時チェックの乖離

| チェック機能 | Playbook 完了時 | Project/Milestone 完了時 | 乖離 | severity |
|-------------|----------------|------------------------|------|----------|
| critic 検証 | OK | milestone 完了時は未定義 | Gap | Medium |
| subtask-guard | OK | milestone に対応なし | Gap | Low |
| p_final reviewer | OK | - | Gap | Low |

### 3.3 運用時ガードの乖離

| ガード機能 | Playbook 運用時 | Project 運用時 | 乖離 | severity |
|-----------|----------------|----------------|------|----------|
| playbook-guard | OK | OK (同じ) | - | - |
| depends-check | OK | milestone 依存確認なし | Gap | Low |
| scope-guard | OK | project scope なし | Gap | Low |

---

## 4. ドキュメントと実装の乖離

ARCHITECTURE.md Section 14 に記載された既知の課題。

### 4.1 存在しないファイルへの参照

| 参照元 | 参照先 | 状態 | severity |
|--------|--------|------|----------|
| playbook-guard.sh (行 107, 138, 171) | .claude/hooks/failure-logger.sh | 不存在 | Low |
| cleanup.sh (行 85) | .claude/skills/playbook-gate/workflow/generate-repository-map.sh | 不存在 | Low |
| access-control/SKILL.md | .claude/skills/access-control/lib/contract.sh | 不存在 | Low |

**備考**: failure-logger.sh は存在チェック `[[ -f ... ]]` でガードされているため、機能への影響なし。

### 4.2 Stop Hook の乖離

| 設計 | 実装 | 乖離 | severity |
|------|------|------|----------|
| no-op (ARCHITECTURE.md Section 14.3) | completion-check + post-loop pending チェック | ドキュメント古い | Low |

**備考**: 実装が設計より進んでいる。ARCHITECTURE.md の更新が必要。

---

## 5. 乖離サマリ（severity 別）

### Critical (1件)

| ID | 乖離 | 説明 | 対応方針 |
|----|------|------|----------|
| GAP-C1 | Project reviewer 検証なし | project 生成時に reviewer チェックがない | pm.md に reviewer 呼び出しステップ追加 |

### High (0件)

なし（機能面は全て動作中）

### Medium (5件)

| ID | 乖離 | 説明 | 対応方針 |
|----|------|------|----------|
| GAP-M1 | telemetry.sh 未実装 | 全 Unit で telemetry がない | 運用監視が必要なら実装 |
| GAP-M2 | meta.reviewed 未実装 | project.json に reviewed フィールドがない | template と design-validation を更新 |
| GAP-M3 | meta.reviewed_by 未実装 | project.json に reviewed_by フィールドがない | 同上 |
| GAP-M4 | prompt-analyzer 未実装 (project) | project 作成時に 5W1H 分析がない | project-init Skill を作成または pm.md 拡張 |
| GAP-M5 | understanding-check 未実装 (project) | project 作成時にユーザー確認がない | 同上 |

### Low (10件)

| ID | 乖離 | 説明 | 対応方針 |
|----|------|------|----------|
| GAP-L1 | validator.sh 未実装 | 全 Unit で未実装 | 設計の完全性のため（優先度低） |
| GAP-L2 | context-injector.sh 未分離 | chain.sh に埋め込み | 同上 |
| GAP-L3 | guardrail.sh 未分離 | guards/*.sh で代替中 | 同上 |
| GAP-L4 | snapshot.sh 未実装 | 事前状態保存なし | リカバリ機能のため |
| GAP-L5 | retry.sh 未実装 | 再試行ロジックなし | ネットワーク系のみ |
| GAP-L6 | milestone depends-check 未実装 | milestone 間の依存確認なし | 運用で回避可能 |
| GAP-L7 | project scope-guard 未実装 | project の scope チェックなし | 同上 |
| GAP-L8 | failure-logger.sh 不存在 | 参照あるが実装なし | 存在チェックでガード済み |
| GAP-L9 | generate-repository-map.sh 不存在 | 参照あるが実装なし | パス修正必要 |
| GAP-L10 | Stop Hook ドキュメント古い | 実装が進んでいる | ARCHITECTURE.md 更新 |

---

## 6. 対応優先度

本 playbook の scope に従い、Critical/High のみ対応:

1. **GAP-C1** (Critical): Project reviewer 検証なし → p2 で対応
2. Medium/Low は本 playbook の scope 外（excludes に明記済み）

---

## 7. 検証コマンド

```bash
# Hook Unit chain.sh の存在確認
find .claude/events -name "chain.sh" | wc -l
# → 10 (全 Unit 実装済み)

# project.json の meta.reviewed フィールド確認
grep -l "reviewed" play/projects/*/project.json || echo "No reviewed field found"

# ARCHITECTURE.md の Stop Hook 記載確認
grep -A5 "Stop" docs/ARCHITECTURE.md | grep -i "no-op"
```

---

## 8. 結論

- **機能面**: 全 Hook Unit の chain.sh と core handlers/guards は実装済み。システムは動作中。
- **設計との乖離**: Component 分割（validator/telemetry 等）は全て未実装だが、severity は Low/Medium。
- **Critical Gap**: Project 階層の reviewer 検証なし（1件）→ p2 で対応必須。
- **本 playbook の対応範囲**: Critical のみ（GAP-C1）。
