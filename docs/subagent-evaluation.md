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
2. CLAUDE.md での参照状況を grep で定量化（必須かどうか）
3. tech-stack.md での言及を確認
4. settings.json の構造を確認（SubAgent は Task() で動的呼び出し）
5. 実際の使用シーンを分析

---

## CLAUDE.md での参照回数（grep 結果）

| SubAgent | CLAUDE.md 参照回数 | 判定 |
|----------|-------------------|------|
| pm | 10回以上（grep "pm" 結果：68,70,71,123,259,332行） | **Core（必須）** |
| critic | 10回以上（grep "critic" 結果：7,151,163,179,220,230,295,296,330行） | **Core（必須）** |
| plan-guard | **0回**（grep "plan-guard" = 0件） | 削除候補 |
| health-checker | **0回**（grep "health-checker" = 0件） | 削除候補 |
| reviewer | **0回**（grep "reviewer" = 0件） | 保持推奨 |
| setup-guide | **0回**（grep "setup-guide" = 0件） | 保持推奨 |

**重要な発見**: plan-guard, health-checker, reviewer, setup-guide は CLAUDE.md で直接参照されていない。
これは Core フローに組み込まれていないことの明確な証拠である。

---

## settings.json の構造確認

settings.json（258行）を確認した結果：
- SubAgent の定義は **settings.json には含まれていない**
- SubAgent は `Task(subagent_type="...")` で動的に呼び出される
- settings.json には Hook の登録のみ（hooks セクション、22-256行）
- permissions セクション（2-19行）で権限定義

結論: 「settings.json に登録済み」という記述は不正確。正しくは「.claude/agents/*.md に定義ファイルが存在し、Task() で呼び出し可能」

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
| CLAUDE.md 参照 | **0回**（grep "plan-guard" = 0件） |
| 使用頻度 | 低（CLAUDE.md で参照されていない = 自動発火なし） |
| 代替手段 | CLAUDE.md INIT + playbook-guard.sh（下記引用参照） |
| 削除影響 | **軽微** - INIT フローで playbook 存在チェックが行われる |
| Core 関連性 | **低** - CLAUDE.md で参照されていない |
| **判定** | **削除候補** |

**代替手段の根拠（CLAUDE.md 65-71行）**:
```
【フェーズ 3: playbook 準備】★pm 経由必須

  8. playbook=null → pm SubAgent を呼び出す
     - pm が project.milestone を参照して playbook を作成
     - derives_from を必ず設定（milestone ID）
     - ブランチ作成も pm が実行
     ⚠️ pm を経由せずに直接 playbook を作成することは禁止
```

**playbook-guard.sh との機能重複**:
- playbook-guard.sh は PreToolUse:Edit/Write で自動発火
- playbook=null の場合にブロック（settings.json 54-55行、99-100行）
- plan-guard.md の「playbook 存在チェック」は Hook で代替される

---

### 4. reviewer.md

| 項目 | 内容 |
|------|------|
| 役割 | コード品質レビュー。実装後のコードを評価する。 |
| 機能 | 可読性、保守性、安全性の評価。設計レビュー。 |
| 依存関係 | .claude/frameworks/playbook-review-criteria.md |
| CLAUDE.md 参照 | **0回**（grep "reviewer" = 0件） |
| 使用頻度 | 低（明示的な呼び出しが必要、自動発火なし） |
| 代替手段 | critic で done_criteria 検証、手動レビュー |
| 削除影響 | **軽微** - 品質向上ツールとして有用だが必須ではない |
| Core 関連性 | **低** - 補助的なレビュー機能 |
| **判定** | **保持推奨** |

理由: 品質向上のための有用なツール。CLAUDE.md で参照されていないが、tech-stack.md で役割が明記されている（265行）。コードレビューのフレームワークとして価値がある。

---

### 5. setup-guide.md

| 項目 | 内容 |
|------|------|
| 役割 | 初期セットアップをガイドする。focus=setup 時に自動発火。 |
| 機能 | ヒアリング、環境構築、Skills 生成 |
| 依存関係 | plan/template/project-format.md, setup/playbook-setup.md |
| CLAUDE.md 参照 | **0回**（grep "setup-guide" = 0件） |
| 使用頻度 | 低（focus=setup の場合のみ。setup 完了後は使用されない） |
| 代替手段 | 手動での環境構築、pm での playbook 作成 |
| 削除影響 | **軽微** - 新規プロジェクト開始時のみ影響 |
| Core 関連性 | **低** - 初期セットアップ専用 |
| **判定** | **保持推奨** |

理由: 初期セットアップという特定シナリオで有用。CLAUDE.md で参照されていないが、tech-stack.md で役割が明記されている（269行）。focus=setup という明確なトリガー条件があり、その場面では価値がある。

---

### 6. health-checker.md

| 項目 | 内容 |
|------|------|
| 役割 | システム健全性を監視する。state.md と playbook の整合性を確認。 |
| 機能 | state.md 整合性、playbook 整合性、git 状態、ファイル存在チェック |
| 依存関係 | state.md, .claude/settings.json, playbook |
| CLAUDE.md 参照 | **0回**（grep "health-checker" = 0件） |
| 使用頻度 | 低（CLAUDE.md で参照されていない = 自動発火なし） |
| 代替手段 | system-health-check.sh（Hook）で類似機能が実現（下記引用参照） |
| 削除影響 | **軽微** - Hook で代替可能 |
| Core 関連性 | **低** - CLAUDE.md で参照されていない |
| **判定** | **削除候補** |

**代替手段の根拠（system-health-check.sh 1-15行）**:
```bash
# system-health-check.sh - SessionStart 統合: システム健全性チェック
# 目的:
#   - Hook/SubAgent が正常動作しているか自動検証
#   - settings.json と実ファイルの整合性チェック
#   - 問題があれば警告を出力
# 発火: SessionStart イベント（session-start.sh から呼び出し）
```

**機能重複の詳細**:

| チェック項目 | health-checker.md | system-health-check.sh |
|--------------|-------------------|------------------------|
| settings.json 存在・有効性 | チェックあり | チェックあり（27-46行） |
| Hook ファイル存在・権限 | なし | チェックあり（53-68行） |
| SubAgent 定義ファイル | チェックあり | チェックあり（76-85行） |
| Skills ディレクトリ | なし | チェックあり（91-102行） |
| state.md 形式 | チェックあり | チェックあり（109-130行） |

結論: system-health-check.sh は health-checker.md の機能を包含し、さらに Hook 検証機能を追加。Hook は SessionStart で自動実行されるため、SubAgent 版は冗長。

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
| 2025-12-13 | critic FAIL 対応。CLAUDE.md 参照回数（grep 結果）、settings.json 構造確認、代替手段の具体的引用を追加。 |
