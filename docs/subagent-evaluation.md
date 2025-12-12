# subagent-evaluation.md

> **非Core SubAgents の評価レポート**
>
> M010 p3: 各 SubAgent の機能確認、依存関係、使用状況を分析し、削除候補を提示

---

## 評価日時

2025-12-13

---

## 評価方法

1. 各 SubAgent のソースコード（.claude/agents/*.md）を Read で確認
2. CLAUDE.md での参照状況を確認（必須かどうか）
3. tech-stack.md での言及を確認
4. settings.json での登録状況を確認
5. 実際の使用シーンを分析

---

## 評価対象（全6個）

### Core SubAgent の判定基準

CLAUDE.md で以下のいずれかに該当する場合、Core SubAgent として保護対象：
- 「必須」「経由必須」と明記されている
- LOOP/POST_LOOP フローで必ず呼び出される
- 報酬詐欺防止の仕組みに組み込まれている

---

## Core SubAgents（保護対象・評価対象外）

### 1. pm.md

| 項目 | 内容 |
|------|------|
| 役割 | playbook 作成・milestone 管理。3層構造の運用者。 |
| Core 根拠 | CLAUDE.md「全タスク開始は pm SubAgent 経由必須」 |
| 依存関係 | plan/template/playbook-format.md, plan/project.md, state.md |
| **判定** | **Core（保護対象）** |

### 2. critic.md

| 項目 | 内容 |
|------|------|
| 役割 | Phase 完了判定。報酬詐欺防止の判定者。 |
| Core 根拠 | CLAUDE.md「critic SubAgent が PASS を返すまで done 不可」 |
| 依存関係 | .claude/frameworks/done-criteria-validation.md, playbook |
| **判定** | **Core（保護対象）** |

---

## 非Core SubAgents 評価結果

### 3. plan-guard.md

| 項目 | 内容 |
|------|------|
| 役割 | セッション開始時に3層計画の整合性を検証する |
| 機能 | project.md/playbook/state.md の整合性チェック |
| 依存関係 | state.md, plan/project.md, playbook |
| settings.json | 登録済み（subagent_type: plan-guard） |
| 使用頻度 | 低（自動発火の設定はあるが、実際の発火は限定的） |
| 代替手段 | session-start.sh + CLAUDE.md INIT で類似機能が実現 |
| 削除影響 | **軽微** - INIT フローで playbook 存在チェックが行われる |
| Core 関連性 | **中** - 計画整合性（ただし INIT で代替可能） |
| **判定** | **削除候補** |

理由: session-start.sh の INIT フローと機能が重複。CLAUDE.md の INIT セクションで playbook=null チェックが明記されており、plan-guard の役割は限定的。

---

### 4. reviewer.md

| 項目 | 内容 |
|------|------|
| 役割 | コード品質レビュー。実装後のコードを評価する。 |
| 機能 | 可読性、保守性、安全性の評価。設計レビュー。 |
| 依存関係 | .claude/frameworks/playbook-review-criteria.md |
| settings.json | 登録済み（subagent_type: reviewer） |
| 使用頻度 | 低（明示的な呼び出しが必要、自動発火なし） |
| 代替手段 | critic で done_criteria 検証、手動レビュー |
| 削除影響 | **軽微** - 品質向上ツールとして有用だが必須ではない |
| Core 関連性 | **低** - 補助的なレビュー機能 |
| **判定** | **保持推奨** |

理由: 品質向上のための有用なツール。必須ではないが、コードレビューのフレームワークとして価値がある。tech-stack.md で役割が明記されている。

---

### 5. setup-guide.md

| 項目 | 内容 |
|------|------|
| 役割 | 初期セットアップをガイドする。focus=setup 時に自動発火。 |
| 機能 | ヒアリング、環境構築、Skills 生成 |
| 依存関係 | plan/template/project-format.md, setup/playbook-setup.md |
| settings.json | 登録済み（subagent_type: setup-guide） |
| 使用頻度 | 低（focus=setup の場合のみ。setup 完了後は使用されない） |
| 代替手段 | 手動での環境構築、pm での playbook 作成 |
| 削除影響 | **軽微** - 新規プロジェクト開始時のみ影響 |
| Core 関連性 | **低** - 初期セットアップ専用 |
| **判定** | **保持推奨** |

理由: 初期セットアップという特定シナリオで有用。focus=setup という明確なトリガー条件があり、その場面では価値がある。

---

### 6. health-checker.md

| 項目 | 内容 |
|------|------|
| 役割 | システム健全性を監視する。state.md と playbook の整合性を確認。 |
| 機能 | state.md 整合性、playbook 整合性、git 状態、ファイル存在チェック |
| 依存関係 | state.md, .claude/settings.json, playbook |
| settings.json | 登録済み（subagent_type: health-checker） |
| 使用頻度 | 低（手動呼び出しまたは定期実行が必要） |
| 代替手段 | system-health-check.sh（Hook）で類似機能が実現 |
| 削除影響 | **軽微** - Hook で代替可能 |
| Core 関連性 | **低** - 監視ツール |
| **判定** | **削除候補** |

理由: system-health-check.sh（Hook）と機能が重複。Hook はセッション開始時に自動実行されるため、SubAgent 版は冗長。

---

## サマリー

### Core SubAgents（保護対象：2個）

| SubAgent | 理由 |
|----------|------|
| pm.md | playbook 作成必須経由。CLAUDE.md で「全タスク開始は pm SubAgent 経由必須」 |
| critic.md | Phase 完了判定必須。CLAUDE.md で「critic SubAgent が PASS を返すまで done 不可」 |

### 保持推奨（2個）

| SubAgent | 理由 |
|----------|------|
| reviewer.md | 品質向上ツールとして有用 |
| setup-guide.md | 初期セットアップ時に有用 |

### 削除候補（2個）

| SubAgent | 理由 |
|----------|------|
| plan-guard.md | session-start.sh + CLAUDE.md INIT で代替可能 |
| health-checker.md | system-health-check.sh（Hook）で代替可能 |

---

## 削除候補の詳細理由

### 削除基準

1. **機能重複** - Hook で同等の機能が提供されている
2. **使用頻度が低い** - 実際の発火が限定的
3. **代替手段がある** - CLAUDE.md の INIT フローや Hook で代替可能

### 削除による影響

- **plan-guard.md**: 3層計画の整合性チェックがなくなる → CLAUDE.md INIT + playbook-guard.sh で代替
- **health-checker.md**: SubAgent 経由の健全性チェックがなくなる → system-health-check.sh（Hook）で代替

### 代替手段の対応表

| 削除候補 | 代替手段 |
|----------|----------|
| plan-guard.md | CLAUDE.md INIT「playbook=null → pm SubAgent を呼び出す」 + playbook-guard.sh |
| health-checker.md | system-health-check.sh（SessionStart 時に自動実行） |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | 初版作成。M010 p3 対応。6個の SubAgents を評価。 |
