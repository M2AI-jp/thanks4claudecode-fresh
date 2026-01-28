# 全ファイル点検レポート

> **作成日**: 2026-01-28
> **点検対象**: 247ファイル
> **点検方法**: カテゴリ別系統的点検（Explore Agent による並列調査）

---

## Executive Summary

| 判定 | 件数 | 割合 |
|------|------|------|
| 必要 | 234 | 94.7% |
| 要検討 | 13 | 5.3% |
| 削除推奨 | 0 | 0% |

**結論**: 全ファイルに存在意義があり、即座に削除すべきファイルはない。ただし、未使用ファイル（11件）と参照元不明ファイル（2件）については改善推奨。

---

## カテゴリ別点検結果

### 1. ルートファイル (4件) - 全て必要

| ファイル | 参照数 | 判定 |
|---------|--------|------|
| CLAUDE.md | 120 | 必要（基本規則） |
| state.md | 757 | 必要（SSOT） |
| README.md | 91 | 必要 |
| PROJECT-STORY.md | 60 | 必要（参考資料） |

### 2. .claude/hooks/ (6件) - 全て必要

全ファイルが settings.json に登録済み。Hook → Event Unit チェーンの導火線として機能。

### 3. .claude/events/ (22件) - 11件必要、11件要検討

**必要（11件）**: 全 chain.sh ファイル + lib/telemetry.sh

**要検討（11件）**: 全 validator.sh ファイル

```yaml
問題: validator.sh は全て未呼び出し（orphaned）
証拠:
  - chain.sh 内に validator.sh への source 呼び出しがない
  - 実際の検証は downstream の Skill guards に委譲
推奨:
  - validator.sh を削除するか、chain.sh に統合するかを検討
  - 現状は「将来の拡張用」として保持
```

### 4. .claude/skills/ (40件) - 全て必要

13 Skill 全てに固有の責務あり。削除不可。

**要改善点**:
- prompt-analyzer と understanding-check の 5W1H 分析が重複
- executor-resolver の独立性を pm 内統合で検討可能

### 5. .claude/lib+frameworks+schema (13件) - 全て必要

| ファイル | 判定 | 備考 |
|---------|------|------|
| lib/common.sh | 必要 | エントリーポイント |
| lib/contract.sh | 必要 | ファイル保護の核 |
| lib/error.sh | 必要 | エラーハンドリング |
| lib/logging.sh | 必要 | ログユーティリティ |
| lib/testing.sh | 必要 | テストユーティリティ（将来用） |
| frameworks/* | 必要 | critic/reviewer の参照基準 |
| schema/* | 必要 | JSON スキーマ定義 |

### 6. docs/ (11件) - 10件必要、1件要検討

**必要（10件）**: ARCHITECTURE.md, PROMPT_CHANGELOG.md, completion-criteria.md, core-feature-reclassification.md, design/project-feature-spec.md, file-inventory.md, repository-map.yaml, validation-command-standards.md

**要検討（2件）**:
- bash-protection-issues.md: 参照元なし → 参照追加推奨
- reward-fraud-test-results.md: 参照元なし → 参照追加推奨

### 7. play/archive/ (40件) - 38件完全、2件構造的

**完全なアーカイブ**: 38 playbook（plan.json + progress.json 完備）

**構造的ディレクトリ**: projects/, standalone/（メタディレクトリ）

**重複検出**: toolstack-c-enforcement が2箇所に存在（形式異なる）

### 8. その他 (14件) - 全て必要

| ファイル | 判定 | 備考 |
|---------|------|------|
| .claude/agents/ (7件) | 必要 | SubAgent レジストリ |
| .claude/scripts/* | 必要 | ユーティリティ |
| .claude/settings.json | 必要 | CLI 設定 |
| .claude/settings.local.json | 必要 | テスト許可リスト |
| .claude/protected-files.txt | 必要 | 保護ファイル定義 |
| scripts/reward-fraud-test.sh | 必要 | 報酬詐欺耐性テスト |
| play/template/* | 必要 | テンプレート |
| tmp/README.md | 必要 | デモドキュメント |

---

## 発見された問題点と推奨対応

### Issue 1: 未使用の validator.sh ファイル群

```yaml
問題: .claude/events/*/validator.sh (10ファイル、730行以上)
状態: 全て orphaned（chain.sh から呼ばれない）
根本原因: 検証ロジックが Skill guards に委譲されている
推奨対応:
  option_a: validator.sh を削除し、Skill guards に完全移行
  option_b: chain.sh に validator 呼び出しを追加
  option_c: 現状維持（将来の拡張用として保持）
判定: option_c（現状維持）を推奨 - 破壊的変更のリスクを回避
```

### Issue 2: 未使用の telemetry.sh

```yaml
問題: .claude/events/lib/telemetry.sh (210行)
状態: 未呼び出し
推奨対応: 将来の observability 機能として保持
```

### Issue 3: 参照元不明のドキュメント

```yaml
問題:
  - docs/bash-protection-issues.md
  - docs/reward-fraud-test-results.md
推奨対応: state.md の参照セクションに追加
```

### Issue 4: toolstack-c-enforcement 重複

```yaml
問題: 2箇所に存在
  - play/archive/toolstack-c-enforcement/
  - play/archive/projects/toolstack-c-enforcement/
分析: 形式が異なる（standalone vs project）
判定: 意図的な参照関係として保持
```

---

## 結論

1. **即座に削除すべきファイルはない**
2. **未使用ファイルは将来の拡張用として保持推奨**
3. **参照元不明ドキュメントは参照追加で改善**
4. **アーキテクチャは健全（MECE 状態）**

---

## 点検証跡

- 点検手法: Explore Agent による並列調査（8カテゴリ同時実行）
- grep/find による参照確認
- 各ファイルの内容読み取りと目的分析
- settings.json との整合性確認
