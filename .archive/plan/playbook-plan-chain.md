# playbook-plan-chain.md

> **計画の連鎖的導出システム: project → playbook → phase の自動導出**

---

## meta

```yaml
project: plan-chain-system
branch: feat/project-completion
created: 2025-12-08
issue: null
derives_from: project.done_when（システム基盤の改善）
```

---

## goal

```yaml
summary: 計画の連鎖的導出システムを構築し、LLM が project.done_when から playbook/phase を自律的に導出できるようにする

why:
  問題: project.md に done_when を書いても、LLM はそこから playbook を自律的に作れない
  原因: done_when → playbook → phase への「導出の仕組み」がない
  影響: 計画の連鎖が断絶し、人間が毎回手動で playbook を書く必要がある

done_when:
  - project.done_when に decomposition（分解指針）が構造化されている
  - pm SubAgent が計画の導出を支援できる
  - /playbook-init が decomposition を参照して playbook を生成できる
  - CLAUDE.md に計画の連鎖ルールが明記されている
  - 実際に project.done_when から playbook を自動導出できることを検証
```

---

## phases

```yaml
- id: p0
  name: 設計ドキュメント作成
  goal: 計画の連鎖システムの詳細設計を文書化
  executor: claudecode
  done_criteria:
    - decomposition の構造が定義されている
    - playbook への導出フローが図示されている
    - pm の拡張役割が定義されている
  test_method: |
    設計ドキュメントを読み、以下が明確か確認:
    1. decomposition の各フィールドの意味
    2. 導出フローの各ステップ
    3. pm が何をするか
  status: done
  evidence:
    - plan/design/plan-chain-system.md 作成
    - Section 2: decomposition 構造（7フィールド定義）
    - Section 3: 導出フロー（5ステップ + フロー図）
    - Section 4: pm 拡張役割（計画の導出、優先度判断、依存解決）

- id: p1
  name: project.md の done_when 構造化
  goal: 各 done_when に decomposition セクションを追加
  executor: claudecode
  depends_on: [p0]
  done_criteria:
    - 全 not_achieved 項目に decomposition がある
    - decomposition に playbook_summary, phase_hints, success_indicators がある
    - depends_on で依存関係が明示されている
  test_method: |
    project.md を Read し、構造を確認
  status: done
  evidence:
    - 4項目全てに decomposition 追加（DW-001〜DW-004）
    - 各項目に id, playbook_summary, phase_hints, success_indicators, depends_on, estimated_effort
    - 依存グラフ: DW-001 → DW-002 → DW-003/DW-004

- id: p2
  name: playbook テンプレート改善
  goal: derives_from と導出ガイドを追加
  executor: claudecode
  depends_on: [p1]
  done_criteria:
    - plan/template/playbook-format.md に derives_from フィールドがある
    - decomposition を参照する手順が明記されている
    - 新規 playbook 作成時のガイドがある
  test_method: |
    playbook-format.md を Read し、新フィールドを確認
  status: done
  evidence:
    - meta セクションに derives_from 追加
    - "playbook 導出ガイド" セクション新設（手順5ステップ + 変換ルール + 例）
    - V9 として変更履歴に記録

- id: p3
  name: pm SubAgent の拡張
  goal: 計画の導出機能を追加
  executor: claudecode
  depends_on: [p2]
  done_criteria:
    - .claude/agents/pm.md に「計画の導出」役割が追加されている
    - project.done_when → playbook の導出手順が明記されている
    - playbook.goal → phases の導出手順が明記されている
  test_method: |
    pm.md を Read し、導出機能を確認
  status: done
  evidence:
    - 責務に「計画の導出（Plan Derivation）」追加
    - "計画の導出フロー" セクション新設（6ステップ）
    - トリガー条件に "playbook が完了した" を追加

- id: p4
  name: CLAUDE.md 更新
  goal: 計画の連鎖ルールを追加
  executor: claudecode
  depends_on: [p3]
  done_criteria:
    - INIT フローに「計画の導出」ステップがある
    - pm 呼び出しタイミングが明記されている
    - playbook 作成時の decomposition 参照ルールがある
  test_method: |
    CLAUDE.md を Read し、計画の連鎖ルールを確認
  status: done
  evidence:
    - INIT フェーズ 5 を「Macro チェック & 計画の導出」に更新
    - POST_LOOP に「次タスクの導出（計画の連鎖）」追加
    - V5.1 として変更履歴に記録

- id: p5
  name: 統合テスト
  goal: 実際に計画の連鎖を使って検証
  executor: claudecode
  depends_on: [p4]
  done_criteria:
    - project.done_when から playbook skeleton を導出できる
    - decomposition.phase_hints から phases を導出できる
    - pm が導出を支援している
  test_method: |
    1. 新規 playbook を作成（project.done_when を参照）
    2. pm を呼び出し、導出支援を確認
    3. 生成された playbook が decomposition と整合するか確認
  status: done
  evidence:
    - pm.md に「計画の導出（Plan Derivation）」責務が存在（pm.md:22-27）
    - pm.md に「計画の導出フロー」が定義（pm.md:59-87、6ステップ）
    - playbook-format.md に「playbook 導出ガイド」セクション追加（V9）
    - playbook-format.md に phase_hints → phases 変換ルールが定義
    - project.md DW-001 に decomposition 構造が存在（playbook_summary, phase_hints x5, success_indicators x4）
    - CLAUDE.md に INIT フェーズ 5「Macro チェック & 計画の導出」追加
    - 検証: pm SubAgent を Task ツールで呼び出し、DW-001 の導出を実行
    - pm 出力: derives_from=DW-001, goal="setup フローの検証と改善", phases=p0-p4 (5 Phase)
```

---

## design

> **p0 で詳細化する設計の概要**

```yaml
decomposition_structure:
  playbook_summary: この done_when を達成するための playbook の一言説明

  phase_hints:
    - name: Phase 名
      what: 何をするか
      why: なぜ必要か（オプション）

  success_indicators:
    - playbook の done_when に変換される条件

  depends_on:
    - 先に達成すべき他の done_when の ID

derivation_flow:
  step_1: project.md を読み、not_achieved を特定
  step_2: depends_on を解決し、着手可能な done_when を特定
  step_3: pm を呼び出し、playbook skeleton を生成
  step_4: decomposition.phase_hints から phases を導出
  step_5: success_indicators から done_when を導出
  step_6: playbook を完成させ、作業開始

pm_extended_role:
  existing:
    - スコープクリープの防止
    - playbook の管理

  new:
    - 計画の導出: project.done_when → playbook
    - Phase の導出: playbook.goal → phases
    - 優先度判断: 何を先にやるべきか
    - 依存解決: depends_on を考慮した順序決定
```

---

## notes

```yaml
設計判断:
  なぜ SubAgent を増やさないか:
    - pm の役割を拡張する方がシンプル
    - 新しい SubAgent は認知負荷を増やす
    - pm は「Project Manager」なので計画の導出は自然な役割

  なぜ decomposition を project.md に置くか:
    - 「何を達成するか」と「どう達成するか」を近くに置く
    - playbook 作成時に参照しやすい
    - done_when の定義と分解指針を一元管理

関連ファイル:
  - plan/project.md: done_when の構造化
  - plan/template/playbook-format.md: テンプレート改善
  - .claude/agents/pm.md: 役割拡張
  - CLAUDE.md: 計画の連鎖ルール
  - .claude/CLAUDE-ref.md: 詳細手順
```

---

## 変更履歴

| 日時 | Phase | 内容 |
|------|-------|------|
| 2025-12-08 | - | playbook 作成 |
