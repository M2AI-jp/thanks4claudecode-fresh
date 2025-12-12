# audit-final-decision.md

> **ドキュメント・コンポーネント監査 最終判定リスト**
>
> M010 最終成果物: Codex 評価を踏まえた削除/保持/改訂の判定

---

## 評価日時

2025-12-13

---

## 評価者

- Claude Code（p0-p4 評価実施）
- Codex（gpt-5.1-codex-max）第三者評価

---

## 最終分類: 3区分

Codex 評価の提案に基づき、以下の 3 分類で最終判定:

1. **必須（Core）** - 削除禁止
2. **任意（Optional）** - 保持推奨、opt-in/opt-out 可能
3. **廃止予定（Deprecated）** - 削除予定、ドキュメント更新後に削除

---

## Hooks 最終判定

### 必須（Core）: 10個

| Hook | 理由 |
|------|------|
| session-start.sh | セッション初期化の中核 |
| prompt-guard.sh | State Injection の実装者 |
| init-guard.sh | INIT フェーズ強制 |
| playbook-guard.sh | playbook 必須の強制 |
| consent-guard.sh | 合意プロセスの強制 |
| critic-guard.sh | critic PASS 強制 |
| check-coherence.sh | 四つ組整合性チェック |
| log-subagent.sh | SubAgent 呼び出しログ |
| scope-guard.sh | スコープガード |
| executor-guard.sh | executor 制御 |

### 任意（Optional）: 6個

| Hook | 理由 | Codex 指摘 |
|------|------|------------|
| lint-check.sh | 品質ゲート | 「単純削除は弱い」- 品質フィードバック維持 |
| test-hooks.sh | Hook 回帰検知 | 「Hook 変更時の回帰検知がなくなる」 |
| failure-logger.sh | エラー記録 | 「将来の自己改善経路」- learning Skill と連携 |
| update-tracker.sh | ファイル変更追跡 | 観測性の補完 |
| generate-implementation-doc.sh | ドキュメント生成 | 観測性の補完 |
| create-pr-hook.sh | PR 作成 | 「ドキュメント更新が前提」- 参照先多数 |

### 廃止予定（Deprecated）: 3個

| Hook | 理由 | 対応 |
|------|------|------|
| depends-check.sh | 情報提示のみ | 削除可能 |
| check-file-dependencies.sh | 情報提示のみ | 削除可能 |
| doc-freshness-check.sh | 情報提示のみ | 削除可能 |

---

## SubAgents 最終判定

### 必須（Core）: 2個

| SubAgent | 理由 |
|----------|------|
| pm.md | playbook 作成必須経由 |
| critic.md | Phase 完了判定必須 |

### 任意（Optional）: 4個

| SubAgent | 理由 | Codex 指摘 |
|----------|------|------------|
| plan-guard.md | 計画整合性チェック | 「他ドキュメントで存在前提」- doc 更新まで保持 |
| health-checker.md | システム健全性 | 「他ドキュメントで存在前提」- doc 更新まで保持 |
| reviewer.md | コードレビュー | 品質向上ツールとして有用 |
| setup-guide.md | 初期セットアップ | 初期設定時に有用 |

---

## Skills 最終判定

### 必須（Core）: 2個

| Skill | 理由 |
|-------|------|
| post-loop/skill.md | CLAUDE.md 直接参照。playbook 完了後処理。 |
| consent-process/skill.md | CLAUDE.md フェーズ 4.5 で機能使用。 |

### 任意（Optional）: 8個

| Skill | 理由 | Codex 指摘 |
|-------|------|------------|
| lint-checker/skill.md | 品質検証 | critic から呼び出し推奨 |
| test-runner/skill.md | テスト実行 | critic から呼び出し推奨 |
| deploy-checker/skill.md | デプロイ検証 | critic から呼び出し推奨 |
| state/SKILL.md | state.md 管理 | 「ドメイン知識を含む」→ 改訂推奨 |
| plan-management/SKILL.md | 計画管理 | 「旧構造→改訂が妥当」 |
| learning/SKILL.md | 失敗学習 | 「failure-logger との連携」→ 温存 |
| context-externalization/skill.md | コンテキスト外部化 | 「compact 手順に統合」推奨 |
| context-management/SKILL.md | /compact ガイド | 「compact 手順に統合」推奨 |

### 廃止予定（Deprecated）: 3個

| Skill | 理由 | 対応 |
|-------|------|------|
| execution-management/SKILL.md | 用途外 | 「削除妥当性が高い」 |
| beginner-advisor/skill.md | 用途外 | 「削除妥当性が高い」 |
| frontend-design/SKILL.md | 用途外 | 「削除妥当性が高い」 |

---

## 次のアクション

Codex 改善提案に基づく推奨アクション:

### 1. ドキュメント更新（削除前提条件）

廃止予定コンポーネントを削除する前に、以下を更新:
- feature-map.md
- tech-stack.md
- current-implementation.md
- doc-reference-audit.md

### 2. 改訂作業

以下の Skill を現行用語（project/playbook/phase）で改訂:
- state/SKILL.md
- plan-management/SKILL.md
- context-externalization/skill.md → compact 手順に統合
- context-management/SKILL.md → compact 手順に統合

### 3. settings.json 更新

任意（Optional）コンポーネントの opt-in/opt-out を明示化:
- デフォルト off で登録
- 必要時に有効化する運用ルールを文書化

### 4. フォールバック明文化

削除時の異常検出（health check）を追加:
- 「この Hook/SubAgent/Skill が存在しない場合のフォールバック」を明文化

---

## サマリー

| カテゴリ | 必須 | 任意 | 廃止予定 | 計 |
|----------|------|------|----------|-----|
| Hooks | 10 | 6 | 3 | 19 |
| SubAgents | 2 | 4 | 0 | 6 |
| Skills | 2 | 8 | 3 | 13 |
| **計** | **14** | **18** | **6** | **38** |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | 初版作成。M010 最終成果物。Codex 評価を反映。 |
