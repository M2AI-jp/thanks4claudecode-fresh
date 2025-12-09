# Playbook Archive Analysis

> **目的**: plan/active/ に残存する完了済み playbook がなぜアーカイブされていないか根本原因を特定
>
> **作成日**: 2025-12-09
> **playbook**: playbook-artifact-health.md p1

---

## 調査結果サマリー

| 項目 | 数 |
|------|-----|
| plan/active/ の playbook | 11 件 |
| .archive/plan/ の playbook | 10 件 |
| 「完了・アーカイブ」記録あり | 2 件 |
| 「完了」のみ記録（アーカイブなし） | 4 件以上 |

---

## 1. plan/active/ に残存する playbook（完了済み）

| playbook 名 | 最終更新 | state.md 完了記録 | アーカイブ状態 |
|-------------|---------|------------------|---------------|
| playbook-action-based-guards.md | Dec 9 00:06 | 2025-12-08「アクションベース Guards 完了」 | 未アーカイブ |
| playbook-consent-integration.md | Dec 9 13:18 | 記録なし（p12 で作成？） | 未アーカイブ |
| playbook-current-implementation-redesign.md | Dec 9 16:43 | 2025-12-09「全8Phase完了」 | 未アーカイブ |
| playbook-ecosystem-improvements.md | Dec 9 16:43 | 2025-12-09「全5Phase完了」 | 未アーカイブ |
| playbook-engineering-ecosystem.md | Dec 9 16:43 | 2025-12-09「全6Phase完了」 | 未アーカイブ |
| playbook-implementation-validation.md | Dec 9 12:12 | 記録なし | 未アーカイブ |
| playbook-plan-chain.md | Dec 9 00:06 | 記録なし | 未アーカイブ |
| playbook-session-redesign.md | Dec 9 00:06 | 記録なし | 未アーカイブ |
| playbook-skills-integration.md | Dec 9 21:19 | pm により移動済み | 移動中 |
| playbook-structure-optimization.md | Dec 9 00:06 | 記録なし | 未アーカイブ |
| playbook-trinity-validation.md | Dec 9 12:12 | 2025-12-09「全12Phase完了」 | 未アーカイブ |

---

## 2. .archive/plan/ に存在する playbook（アーカイブ済み）

| playbook 名 | アーカイブ日時 | state.md 記録 |
|-------------|--------------|---------------|
| playbook-3layer-plan.md | Dec 8 22:45 | - |
| playbook-auto-clear.md | Dec 8 22:45 | - |
| playbook-claude-hook-integration.md | Dec 9 12:12 | - |
| playbook-claude-improvement.md | Dec 9 12:12 | - |
| playbook-mechanism-completion.md | Dec 9 12:12 | - |
| playbook-regression-test.md | Dec 8 22:45 | - |
| playbook-rollback.md | Dec 8 22:45 | - |
| playbook-skills-integration.md | Dec 9 21:37 | pm により移動 |
| playbook-system-completion.md | Dec 9 20:46 | 「完了・アーカイブ」 |
| playbook-system-improvements.md | Dec 9 12:56 | 「完了・アーカイブ」 |

---

## 3. 根本原因分析

### 3.1 archive-playbook.sh の設計

```yaml
発火条件: PostToolUse:Edit
対象: playbook*.md ファイルが編集されたとき
動作: 全 Phase が done なら「提案」を出力
問題: 提案のみで自動実行しない
```

**設計思想（archive-playbook.sh:9-10）:**
```
#   - 移動は提案のみ（自動実行しない）
#   - ユーザー判断でアーカイブを実行
```

### 3.2 POST_LOOP の流れ

CLAUDE.md POST_LOOP セクションによると:
```
1. 自動コミット（最終 Phase 分）
2. 自動マージ
3. project.done_when の更新
4. 次タスクの導出
5. 残タスクあり → ブランチ作成 → playbook 作成 → LOOP
6. 残タスクなし → 「全タスク完了。次の指示を待ちます。」
```

**問題: POST_LOOP にアーカイブステップがない**

### 3.3 アーカイブされた playbook とされなかった playbook の違い

**アーカイブされたもの（Dec 8 22:45 の 4 件）:**
- playbook-3layer-plan.md
- playbook-auto-clear.md
- playbook-regression-test.md
- playbook-rollback.md

**推測**: これらは一括でアーカイブされた可能性が高い（同じタイムスタンプ）。
おそらく手動で `mv plan/active/playbook-*.md .archive/plan/` を実行。

**アーカイブされたもの（Dec 9 12:12 の 3 件）:**
- playbook-claude-hook-integration.md
- playbook-claude-improvement.md
- playbook-mechanism-completion.md

**推測**: これも一括アーカイブ。

**state.md に「完了・アーカイブ」と記録されたもの:**
- playbook-system-completion.md (Dec 9 20:46)
- playbook-system-improvements.md (Dec 9 12:56)

**推測**: これらは POST_LOOP で明示的にアーカイブ指示があった可能性。

---

## 4. 根本原因の結論

### 主原因

1. **archive-playbook.sh が「提案のみ」設計**
   - 自動実行しないため、提案を見逃すとアーカイブされない
   - 提案が stdout に出力されるだけで、永続化されない

2. **POST_LOOP にアーカイブステップがない**
   - playbook 完了時の標準フローにアーカイブが含まれていない
   - 「完了・アーカイブ」は例外的に明示された場合のみ

3. **アーカイブの実行者が不明確**
   - 「ユーザー判断で実行」と設計されているが、LLM が実行すべきか不明確
   - state.md の「完了」記録とアーカイブが連動していない

### 副因

1. **一貫性のない運用**
   - 一部の playbook は一括アーカイブされた（Dec 8 22:45）
   - 一部の playbook は個別にアーカイブされた
   - 一部の playbook はアーカイブされなかった

2. **archive-playbook.sh の発火条件が限定的**
   - PostToolUse:Edit でのみ発火
   - playbook が編集されないと発火しない
   - Phase 完了時に state.md が更新されても発火しない

---

## 5. 各 playbook の精査結果

### アーカイブすべき playbook（plan/active/ から .archive/plan/ へ）

| playbook | 理由 |
|----------|------|
| playbook-action-based-guards.md | 完了済み（アクションベース Guards 完了記録あり） |
| playbook-consent-integration.md | 完了済み（p12 の成果物、CONSENT 実装済み） |
| playbook-current-implementation-redesign.md | 完了済み（全8Phase完了記録あり） |
| playbook-ecosystem-improvements.md | 完了済み（全5Phase完了記録あり） |
| playbook-engineering-ecosystem.md | 完了済み（全6Phase完了記録あり） |
| playbook-implementation-validation.md | 完了済み（内容確認必要） |
| playbook-plan-chain.md | 完了済み（内容確認必要） |
| playbook-session-redesign.md | 完了済み（内容確認必要） |
| playbook-structure-optimization.md | 完了済み（内容確認必要） |
| playbook-trinity-validation.md | 完了済み（全12Phase完了記録あり） |

### 保持すべき playbook

| playbook | 理由 |
|----------|------|
| playbook-artifact-health.md | 現在進行中 |

---

## 6. 再発防止に向けた提言

1. **POST_LOOP にアーカイブステップを追加**
   - playbook 完了 → 自動コミット → **アーカイブ** → 自動マージ → 次タスク

2. **archive-playbook.sh の自動化検討**
   - 「提案のみ」から「自動実行」への変更
   - または、CLAUDE.md に「提案を見たら必ず実行」ルールを追加

3. **state.md との連動**
   - playbook 完了時に active_playbooks を null に更新するだけでなく
   - アーカイブも自動的に実行

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | 初版作成。p1 根本原因分析完了。 |
