# project.md

> **Claude 自己分析と改善 - 機能実装が達成されない問題を根本解決する**

---

## meta

```yaml
project: claude-self-improvement
created: 2025-12-12
type: self-analysis
location: .claude/  # Claude Code 拡張機能の改善
```

---

## vision

### ユーザーの意図

> 「必要な機能の実装を何度依頼しても達成されない」
> Claude 自身が自己分析を行い、原因を特定し、修正・検証を繰り返して改善する。

### 成功の定義

- Claude が自己の問題パターンを明文化して理解している
- 原因が特定され、修正が行われている
- 修正結果が検証され、改善が確認されている
- 改善されるまで LOOP が回っている

---

## problem_statement

```yaml
症状:
  - /clear 後に作業開始すると想定機能が動作する
  - しかしセッション途中で追加指示を与えると既存機能を無視
  - 単一のチャットセッションとして処理してしまう

期待されていたこと:
  - 初動 Hooks → project & playbook 生成 → 達成されるまで LOOP
  - セッション途中の指示でも同じフローで処理される
  - project/playbook を常に参照して作業を進める

実際に起きていたこと:
  - SessionStart Hook は初回のみ発火（セッション途中では発火しない）
  - UserPromptSubmit Hook (prompt-guard.sh) は additionalContext を出力するが:
    1. 出力内容が「判断基準」であり「強制指示」ではない
    2. Claude が additionalContext を無視してユーザープロンプトに引っ張られる
    3. playbook がある場合の処理が「スコープ確認」のみで弱い
  - init-guard.sh は pending ファイルがある場合のみチェック
    → セッション途中では pending がないため何もしない
  - state.md との多重チェックが「初回のみ有効」な設計
```

---

## root_cause_analysis

```yaml
# 根本原因分析（5 Whys）

問題: セッション途中で追加指示を与えると既存機能を無視する

Why-1: なぜ既存機能を無視するのか？
  → Claude が additionalContext よりユーザープロンプトを優先するから

Why-2: なぜユーザープロンプトを優先するのか？
  → additionalContext の内容が「参考情報」レベルで「強制指示」ではないから
  → prompt-guard.sh の出力が「判断基準を示す」だけで「何をすべきか」が不明確

Why-3: なぜ SessionStart の時は正しく動くのか？
  → session-start.sh が大量の情報（MISSION, 必須 Read 指示, state.md 抜粋）を出力
  → init-guard.sh が pending を設定し、必須 Read が完了するまでブロック
  → Claude の思考が「初期化プロセス」に向かう

Why-4: なぜセッション途中では同じことが起きないのか？
  → SessionStart トリガーは初回のみ
  → init-guard.sh の pending は session-start.sh でのみ設定される
  → セッション途中では pending がないため init-guard は何もしない

Why-5: なぜ UserPromptSubmit で同等の強制ができないのか？
  → prompt-guard.sh は additionalContext を出力するが:
    - project.md の内容を注入していない
    - playbook の現在 Phase を注入していない
    - 「これに従え」という明示的な指示がない
  → CLAUDE.md に「additionalContext に従え」という明示的ルールがない

# 根本原因
1. prompt-guard.sh が project/playbook の情報を強制注入していない
2. CLAUDE.md に「全プロンプトで additionalContext を優先せよ」というルールがない
3. init-guard.sh の仕組みがセッション途中では機能しない設計
```

---

## solution_design

```yaml
解決策-1: prompt-guard.sh の強化
  目的: 全プロンプトで project/playbook 情報を強制注入
  変更内容:
    - project.md の vision/goal を additionalContext に注入
    - playbook の現在 Phase (in_progress) と done_criteria を注入
    - 「この情報に従って応答を生成せよ」という明示的指示を追加
    - playbook がある場合も「参考情報」ではなく「強制情報」として出力

解決策-2: CLAUDE.md へのルール追加
  目的: additionalContext を「無視できないもの」にする
  変更内容:
    - 「全プロンプトで additionalContext を最初に確認せよ」を追加
    - 「additionalContext に project/playbook がある場合、それに従え」を追加
    - 「ユーザープロンプトより additionalContext を優先せよ」を明記

解決策-3: state.md 多重チェックの簡素化（オプション）
  目的: init-guard.sh との連携を簡素化
  変更内容:
    - init-guard.sh の pending チェックを UserPromptSubmit でも機能させる
    - または、init-guard.sh を廃止し prompt-guard.sh に統合
```

---

## done_when

```yaml
DW-001:
  id: DW-001
  name: 自己分析と問題パターンの明文化
  status: achieved
  priority: high
  depends_on: []
  description: |
    Claude 自身の行動パターン、思考パターン、失敗パターンを明文化する。
    過去のセッション履歴、failures.log、playbook 実行結果を分析し、
    「なぜ達成されなかったか」のパターンを特定する。
  completed_by: plan/playbook-claude-self-improvement-dw001.md (Phase 1)
  evidence: docs/self-analysis-phase1.md

DW-002:
  id: DW-002
  name: 原因の特定と根本原因分析
  status: achieved
  priority: high
  depends_on: [DW-001]
  description: |
    特定した問題パターンの根本原因を分析する。
    - コンテキストの問題か？
    - ルールの理解不足か？
    - done_criteria の解釈ミスか？
    - 報酬詐欺的な自己完結か？
  completed_by: plan/playbook-claude-self-improvement-dw001.md (Phase 2)
  evidence: docs/self-analysis-phase2.md

DW-003:
  id: DW-003
  name: 修正の実装
  status: achieved
  priority: high
  depends_on: [DW-002]
  description: |
    特定した根本原因に対する修正を実装する。
    - CLAUDE.md の修正
    - Hook の追加/修正
    - SubAgent の修正
    - Skill の追加/修正
  completed_by: plan/playbook-claude-self-improvement-dw001.md (Phase 3)
  evidence: docs/self-analysis-phase3-results.md

DW-004:
  id: DW-004
  name: 修正結果の検証
  status: achieved
  priority: high
  depends_on: [DW-003]
  description: |
    修正が有効かどうかを検証する。
    - テストケースを作成
  completed_by: plan/playbook-claude-self-improvement-dw001.md (Phase 4-5)
  evidence: docs/self-analysis-phase4.md, docs/self-analysis-phase5.md

DW-005:
  id: DW-005
  name: 改善確認と LOOP 完了
  status: not_achieved
  priority: high
  depends_on: [DW-004]
  description: |
    改善が確認されるまで DW-002 〜 DW-004 を繰り返す。
    ユーザーが「改善された」と認識できる状態になったら完了。
```

---

## decomposition

```yaml
DW-001:
  summary: "自己分析と問題パターンの明文化"
  playbook_summary: "Claude の行動・思考・失敗パターンを分析し、明文化する"

  phase_hints:
    - name: "データ収集"
      what: "failures.log、playbook 履歴、ユーザープロンプト履歴を収集"
    - name: "パターン分析"
      what: "繰り返し発生している問題を特定"
    - name: "明文化"
      what: "問題パターンをドキュメント化"

  success_indicators:
    - "問題パターンが明文化されている"
    - "少なくとも 3 つ以上の問題パターンが特定されている"
    - "各パターンに具体例が付いている"

DW-002:
  summary: "原因の特定と根本原因分析"
  playbook_summary: "問題パターンの根本原因を 5 Whys で分析"

  phase_hints:
    - name: "5 Whys 分析"
      what: "各問題パターンに対して 5 Whys を実行"
    - name: "根本原因の特定"
      what: "表層的な症状ではなく、根本原因を特定"

  success_indicators:
    - "各問題パターンに根本原因が特定されている"
    - "根本原因が「なぜ」を 5 回繰り返して導出されている"
    - "修正可能な形で原因が記述されている"

DW-003:
  summary: "修正の実装"
  playbook_summary: "根本原因に対する修正を実装"

  phase_hints:
    - name: "修正方針決定"
      what: "どのファイルをどう修正するか決定"
    - name: "修正実装"
      what: "実際に修正を行う"

  success_indicators:
    - "修正が実装されている"
    - "修正が意図した効果を持つことが論理的に説明できる"

DW-004:
  summary: "修正結果の検証"
  playbook_summary: "修正が有効かどうかを検証"

  phase_hints:
    - name: "テストケース作成"
      what: "問題パターンを再現するテストケースを作成"
    - name: "検証実行"
      what: "修正後にテストケースを実行"

  success_indicators:
    - "テストケースが存在する"
    - "テストケースが PASS する"
    - "問題パターンが再現しない"

DW-005:
  summary: "改善確認と LOOP 完了"
  playbook_summary: "改善が確認されるまで繰り返す"

  phase_hints:
    - name: "改善判定"
      what: "ユーザーが改善を確認するまで LOOP"
    - name: "LOOP 完了"
      what: "改善が確認されたら project 完了"

  success_indicators:
    - "ユーザーが改善を確認した"
    - "問題パターンが再発しない"
```

---

## milestones

- [x] M1: 自己分析完了（DW-001）
- [x] M2: 根本原因特定（DW-002）
- [x] M3: 修正実装（DW-003）
- [x] M4: 検証 PASS（DW-004）
- [x] M5: 改善確認（DW-005）

---

## notes

- この project はユーザーの直接指示により作成
- 「何度依頼しても達成されない」という問題を根本解決する
- LOOP を回して改善が確認されるまで終了しない
- ユーザーの「次の指示」を待つ
