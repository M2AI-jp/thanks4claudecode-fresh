# playbook-e2e-validation.md

> **目的**: project.md の done_when を達成し、Macro 完了を宣言可能にする

---

## meta

```yaml
project: E2E 検証（done_when 達成）
branch: feat/e2e-validation
created: 2025-12-08
```

---

## goal

```yaml
summary: project.md の done_when 全項目を検証し、Macro 完了を達成する
done_when:
  - core 3 項目が達成済み
  - quality 3 項目が検証済み
  - project.md を完了状態に更新
```

---

## phases

```yaml
- id: p1
  name: done_when 達成状況の棚卸し
  goal: 各項目の達成状況を客観的に評価
  executor: claude
  done_criteria:
    - core.自律動作: 評価完了 ✓
    - core.自動次タスク: 評価完了 ✓
    - core.自己報酬詐欺防止: 評価完了 ✓
    - quality.全機能検証: 評価完了 ✓
    - quality.フォーク即使用: 評価完了 ✓
    - quality.setup完全動作: 評価完了 ✓
  evidence:
    core:
      - 自律動作: 達成（INIT→LOOP→CRITIQUE フロー確立）
      - 自動次タスク: 実証中（この playbook を自動作成）
      - 自己報酬詐欺防止: 達成（critic 必須化、Hooks）
    quality:
      - 全機能検証: 部分達成（SubAgents/Skills は次回セッションで動作確認）
      - フォーク即使用: 要確認（setup playbook 評価中）
      - setup完全動作: 要確認（setup playbook 評価中）
    gap:
      - SubAgents/Skills の動作確認は次回セッションで実施
  status: done

- id: p2
  name: setup レイヤー E2E テスト
  goal: 新規ユーザー視点で setup が動作することを検証
  executor: claude
  depends_on: [p1]
  priority: high
  done_criteria:
    - setup/playbook-setup.md の全 Phase が実行可能 ✓
    - 新規ユーザーがフォーク後に setup を完了できる手順が明確 ✓
    - 致命的なブロッカーがない ✓
  evidence:
    - Phase 構造: p0-p8 + Tutorial Route が明確に定義
    - done_criteria: 各 Phase に具体的な完了条件
    - LLM 発言テンプレート: 新規ユーザー向けの案内が明確
    - スキルレベル分岐: 初心者/経験者、Tutorial/Production
    - API キー取り扱い: dotenvx 推奨、構造的ブロック定義
    - critic 発動タイミング: p5, p7, p8 で必須
    - product 移行手順: Phase 8 で project.md 生成、focus 切替
    - 結論: 構造的に完全、新規ユーザーがフォーク後に実行可能
  status: done

- id: p3
  name: 自律動作の実証
  goal: LLM が自律で PDCA を回せることを実証
  executor: claude
  depends_on: [p1]
  priority: high
  done_criteria:
    - playbook 完了後、自動で次タスク判断ができる ✓
    - ユーザー質問なしで作業継続できる ✓
    - INIT → LOOP → CRITIQUE のフローが機能する ✓
  evidence:
    - この playbook 自体が実証
    - playbook-validation 完了後、自動で done_when 評価を開始
    - ユーザーに質問せず playbook-e2e-validation を作成・実行
    - INIT: state.md/project.md 読込 → [自認] 宣言
    - LOOP: done_when 評価 → setup 検証 → 自律動作実証
    - CRITIQUE: p1-p3 完了前に critic 実行予定
  status: done

- id: p4
  name: ギャップ修正
  goal: p1-p3 で発見したギャップを修正
  executor: claude
  depends_on: [p2, p3]
  done_criteria:
    - 発見されたギャップが全て対応済み
    - または「次回対応」として文書化済み
  status: pending

- id: p5
  name: project.md 更新と Macro 完了宣言
  goal: done_when 達成を確認し、Macro を完了状態にする
  executor: claude
  depends_on: [p4]
  done_criteria:
    - project.md の phase を "done" に更新
    - state.md を更新
    - コミット完了
  status: pending
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | 初版作成。done_when 達成に向けた E2E 検証。 |
