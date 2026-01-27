# claude-code-harness 深層分析レポート

> **文書の位置付け**: harness リポジトリの成功要因分析
>
> **MECE 役割**: harness の設計パターンと new-repo への適用指針の SSOT
>
> **作成日**: 2026-01-22

---

## 1. 概要

[claude-code-harness](https://github.com/Chachamaru127/claude-code-harness) は、Claude Code のイベント駆動フローを成功裏に実装したリポジトリである。本文書は、harness の設計思想・パターン・成功要因を分析し、new-repo 設計への改善指針を導出する。

---

## 2. harness の優れた設計要素（16点）

### A. アーキテクチャ設計

#### 2.1 決定論的状態機械オーケストレーション

```
状態遷移: idle → initialized → planning → executing → reviewing → verifying
          ↓                                                           ↓
        stopped ← ─ ─ ─ ─ ─ escalated ← ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
                                         (3回失敗時)
```

- 非決定論的なLLMの動作を決定論的なフローでラップ
- 各状態間の遷移ルールが明確
- セッション永続化（Snapshot + Event Log）で Resume/Fork 可能

#### 2.2 3層防御戦略（最重要）

```yaml
Layer 1 (Rules):    CLAUDE.md などのルール → 最も軽い
Layer 2 (Skills):   Skill 内のガードロジック → 中程度
Layer 3 (Hooks):    技術的強制 → 最終手段、最も重い
```

**これが new-repo との根本的な設計思想の違い**:
- new-repo: Hook で自動強制を第一層として目指した
- harness: Hook を最終手段（第三層）として、まず Rules と Skills で防御

#### 2.3 宣言的ワークフロー定義（YAML）

```yaml
# workflow/review.yaml の例
steps:
  - id: security-check
    skill: review-security
    parallel: true    # 並列実行の宣言
    condition: "..."  # 条件付き実行

on_success:
  message: "..."
on_error:
  message: "..."
```

- 可視性・保守性が高い
- 条件分岐、並列実行、エラーハンドリングを宣言的に記述

### B. 品質保証設計

#### 2.4 品質ガードレール（Purpose-Driven Implementation）

```python
# 絶対禁止パターン
def slugify(text: str) -> str:
    answers = {"HelloWorld": "hello-world"}  # ハードコード
    return answers.get(text, "")

# 正しい実装
def slugify(text: str) -> str:
    return re.sub(r'[\s_]+', '-', text.strip().lower())
```

- impl スキルに組み込み
- 困難な場合は「形骸化実装を書かずに正直に報告」

#### 2.5 品質判定ゲート

- TDD 推奨度（★★★表示）
- セキュリティ注意判定（auth/, api/）
- パフォーマンス注意判定
- 実装前とレビュー前の両方で実行

#### 2.6 task-worker パターン

```yaml
フロー: implement → self-review (4観点) → fix → build verify → test
出力: commit_ready | needs_escalation | failed
ルール: 3回失敗でエスカレーション
制約: disallowedTools: [Task]（委譲不可、自己完結）
```

### C. 状態管理設計

#### 2.7 Plans.md によるタスク管理

```markdown
# マーカーシステム
- [ ] タスク名 `cc:TODO`    → 未着手
- [ ] タスク名 `cc:WIP`     → 作業中
- [x] タスク名 `cc:完了`    → 完了（確認待ち）
- [x] タスク名 `pm:確認済`  → PM確認完了
```

- Markdown ベース（JSON ではない）
- 人間が読みやすく編集しやすい

#### 2.8 セッション永続化

```
Snapshot:   .claude/state/session.json
Event Log:  .claude/state/session.events.jsonl

→ Resume（中断再開）/ Fork（ブランチ分岐）が可能
```

#### 2.9 SSOT 分割

```
decisions.md  → Why（なぜその判断をしたか）
patterns.md   → How（どう実装するか）
.claude/state/ → 実行時状態
```

### D. エラーハンドリング設計

#### 2.10 error-recovery agent

```yaml
原則: Safety First
ルール:
  - 事前サマリ必須（修正前に何をするか表示）
  - 確認を求める（デフォルト require_confirmation: true）
  - 3回ルール（3回失敗で必ずエスカレーション）
  - パス制限（allowed_modify, protected）

設定ファイル: claude-code-harness.config.json
```

#### 2.11 3回ルール

- シンプルで明確なルール
- Issue codes より直感的
- 無限ループ防止が確実

### E. 開発体験設計

#### 2.12 VibeCoder 対応

```markdown
| やりたいこと | 言い方 |
|-------------|--------|
| プロジェクト開始 | 「〇〇を作りたい」 |
| 作業を開始 | 「始めて」「作って」 |
| 困った時 | 「どうすればいい？」「助けて」 |
| 全部任せる | 「全部やって」「おまかせ」 |
```

- 自然言語でのインタラクション
- 非技術者向けの言い方例

#### 2.13 並列実行の最適化

```
判定条件:
  ✅ ファイル依存なし（同じファイルを編集しない）
  ✅ データ依存なし（出力が他の入力にならない）
  ✅ 順序依存なし

パフォーマンス:
  | シナリオ | 直列 | 並列 | 改善率 |
  |---------|------|------|--------|
  | 3ファイル分析 | 30秒 | 12秒 | 60% |
```

### F. ツール活用設計

#### 2.14 LSP 活用

```
実装前:   goToDefinition → 既存パターンを確認
実装中:   diagnostics → 型エラー即座検出
レビュー時: findReferences → 影響範囲を自動検出
```

#### 2.15 Memory-Enhanced 実装・レビュー

```
mem-search: type:feature "{キーワード}"
→ 過去の実装パターン、設計決定、gotcha（落とし穴）を表示
```

#### 2.16 Codex モードレビュー

- 8つの専門エキスパートを並列呼び出し
- Security, Accessibility, Performance, Quality, SEO, Architect, Plan Reviewer, Scope Analyst

---

## 3. 根本的な設計思想の違い（深層分析）

### 3.1 制御の主体

```
new-repo の設計:
  Hook（自動）────────────────────→ LLM に強制
        ↓
  「LLM が従わなかったらどうする？」→ より多くの Hook
        ↓
  Hook チェーンの複雑化 → デバッグ困難 → 破綻

harness の設計:
  ユーザー（手動）── /plan /work /review ──→ Workflow
        ↓
  Workflow が状態機械で LLM をラップ
        ↓
  Hook は「補助」「最終防衛線」のみ → シンプル
```

### 3.2 なぜ new-repo は失敗し、harness は成功したか

**new-repo の失敗要因**:
1. LLM の非決定性を Hook で「強制」しようとした
2. 強制が効かない → より多くの Hook → 複雑化
3. Hook 間の依存関係が暗黙的 → デバッグ不能

**harness の成功要因**:
1. LLM の非決定性を状態機械で「ラップ」した
2. Hook は最終防衛線（Layer 3）に限定
3. Workflow YAML で依存関係が明示的 → 可視・保守可能

### 3.3 核心的洞察

```yaml
insight:
  name: "制御の反転"
  description: |
    new-repo は「Hook が LLM を制御する」設計
    harness は「ユーザーが Workflow を制御し、Workflow が LLM をラップする」設計

    前者は LLM の非決定性と戦う
    後者は LLM の非決定性を受け入れ、外側でラップする

  implication:
    Hook の役割を根本的に見直す必要がある
    Hook は「強制」ではなく「検出・通知」に限定すべき
```

---

## 4. new-repo との差分分析

| 側面 | new-repo | harness | 評価 |
|------|----------|---------|------|
| **自動化の位置づけ** | Hook で自動強制（第一層） | Hook は最終手段（第三層） | harness ✓ |
| **計画フォーマット** | JSON (plan.json + progress.json) | Markdown (Plans.md) | harness ✓ |
| **状態管理** | state.md（単一 SSOT） | 責務分割（decisions/patterns/state） | harness ✓ |
| **失敗対応** | Issue codes（複雑） | 3回ルール（シンプル） | harness ✓ |
| **ワークフロー定義** | 暗黙的（Event Unit チェーン） | 宣言的（YAML） | harness ✓ |
| **セッション永続化** | なし | Snapshot + Event Log | harness ✓ |
| **非技術者対応** | なし | VibeCoder ガイド | harness ✓ |
| **レビュー構造** | 3層分離（reviewer/code-reviewer/critic） | 自己完結（task-worker） | 一長一短 |
| **Evidence 検証** | 3点検証（technical/consistency/completeness） | なし | new-repo ✓ |
| **概念整理の深さ** | Phase -1 で徹底的に分解 | 薄い | new-repo ✓ |

---

## 5. harness から吸収すべき改善案

### 5.1 3層防御戦略の採用

```yaml
# 現在の new-repo 設計
Layer 0 (Hook): 全てを Hook で自動強制 ← 重すぎる

# 改善後
Layer 1 (Rules):   CLAUDE.md, state.md → ヒント
Layer 2 (Skills):  Skill 内ガードロジック → チェック
Layer 3 (Hooks):   技術的強制 → 最終手段のみ
```

### 5.2 3回ルールの採用

```yaml
# 現在の new-repo 設計
failure_handling:
  detection: Issue codes (I-RF-1, I-DL-1, ...)
  complexity: 高（Issue 毎の対応ロジック）

# 改善後
failure_handling:
  detection: カウンター
  rule: 3回失敗 → 必ずエスカレーション
  complexity: 低（シンプルで確実）
```

### 5.3 宣言的ワークフロー定義

```yaml
# 新規ファイル: .claude/workflows/golden-path.yaml
name: golden-path
description: タスク依頼から完了までの標準フロー

steps:
  - id: analyze-prompt
    skill: prompt-analyzer
    mode: required

  - id: create-playbook
    skill: playbook-creator
    depends_on: [analyze-prompt]

on_success:
  message: "playbook 作成完了。実装を開始します。"
```

### 5.4 セッション永続化の追加

```yaml
# 新規ファイル: .claude/state/session.json
{
  "state": "executing",
  "playbook": "playbook-example",
  "current_phase": 2,
  "retry_count": 1
}

# 新規ファイル: .claude/state/session.events.jsonl
{"event": "phase_start", "phase": 2, "timestamp": "..."}
```

### 5.5 Plan 二層化

```yaml
architecture:
  ssot: play/{id}/plan.json + progress.json  # 機械可読（SSOT）
  view: play/{id}/PLAYBOOK.md                # 人間可読（ビュー）
  sync: .claude/scripts/sync-playbook.sh     # 同期スクリプト
```

---

## 6. 結論

**harness が成功した理由**:
1. Hook を「最終手段」と位置づけ、段階的防御を設計した
2. 人間が読みやすい Markdown ベースのタスク管理
3. 3回ルールによるシンプルで確実な失敗ハンドリング
4. 宣言的なワークフロー定義による可視性と保守性
5. セッション永続化による中断再開の実現

**new-repo への示唆**:
- Hook 自動化の前に、Layer 1-2 を強化すべきだった
- playbook の JSON 形式は機械向けすぎた（人間が編集しにくい）
- Issue codes は複雑すぎた（3回ルールがシンプルで有効）
- セッション永続化がないため、長期タスクで脆弱

**最終提言**:
new-repo の設計文書（特に REBUILD-DESIGN-SPEC.md の Evidence/Issue codes/6軸分解）は理論的に優れているが、harness の「実用的なシンプルさ」を取り入れることで、実装可能性が大幅に向上する。

---

## 参照

- [claude-code-harness](https://github.com/Chachamaru127/claude-code-harness)
- IMPLEMENTATION-PLAN-V2.md（実装計画）
- FAILURE-CATALOG.md（失敗カタログ）
- ../archive/REBUILD-DESIGN-SPEC.md（旧一次仕様、参照用）
- ../archive/BUILD-FROM-SCRATCH.md（旧構築手順、参照用）
