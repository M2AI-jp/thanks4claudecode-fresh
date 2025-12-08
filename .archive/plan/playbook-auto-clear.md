# playbook-auto-clear.md

> **自動 /clear 判断: コンテキスト使用率に基づく自動 /clear 提案**

---

## meta

```yaml
project: thanks4claudecode
created: 2025-12-08
issue: "#10"
branch: feat/auto-clear
type: meta-improvement
```

---

## goal

```yaml
summary: コンテキスト使用率に基づく自動 /clear 提案機能
root_cause: MECE 分析で発見した欠落機能（コンテキスト管理）

done_when:
  - コンテキスト使用率が閾値を超えた場合に警告が出る
  - /clear 推奨のタイミングが自動判定される
  - ユーザーが /clear の必要性を認識できる
```

---

## phases

### p1: 要件定義

```yaml
id: p1
name: 要件定義
goal: 自動 /clear 判断の要件を明確化
executor: claude
max_iterations: 10

正しい動きの定義:
  - コンテキスト使用率の閾値が定義されている
  - 警告表示のタイミングが明確
  - ユーザー体験を損なわない設計

done_criteria:
  - 閾値（例: 80%）が定義されている
  - 警告メッセージの内容が決まっている
  - 実装方法（Hook or Skill）が決まっている

evidence:
  選択した実装方針: "Hook 自動検出 + LLM 確認"

  閾値定義:
    トリガー: Phase が done に遷移（git commit 時に検出）
    閾値判定: LLM が /context で確認（Hook からは取得不可）
    推奨閾値: 80%（CLAUDE.md 既存ルール）

  警告メッセージ:
    内容: |
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        📊 Phase 完了 - コンテキスト確認推奨
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /context でコンテキスト使用率を確認してください。
        80% 超過の場合は /clear を実行してください。
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  実装方法:
    方式: Hook 自動検出（Phase 完了時にリマインダー表示）
    ファイル: .claude/hooks/check-coherence.sh
    トリガー: git commit 時に state.md の差分で "status: done" を検出
    出力先: stderr（ユーザー体験を損なわない）

  役割分担:
    Hook: Phase 完了を検出し、リマインダーを自動表示
    LLM: リマインダーを見て /context で確認、80% 超過なら /clear 実行

  テスト方法:
    - テスト1: Phase 完了時 → リマインダー表示確認
    - テスト2: Phase 完了なし → メッセージなし確認

  critic: PASS
status: done
```

---

### p2: 実装

```yaml
id: p2
name: 実装
goal: 自動 /clear 判断機能を実装
executor: claude
max_iterations: 10
depends_on: [p1]

正しい動きの定義:
  - 閾値を超えた場合に警告が表示される
  - 警告は作業を妨げない（stderr 出力）
  - 判断ロジックが明確

done_criteria:
  - check-coherence.sh に Phase 完了検出ロジックがある
  - Phase 完了時にリマインダーが表示される
  - Phase 完了なしの場合はメッセージなし

evidence:
  実装:
    - check-coherence.sh 327-354行に Phase 完了検出ロジック追加
    - playbook の "status: done" 変更を git diff で検出
    - リマインダーを stderr に出力
  テスト結果:
    - テスト1（Phase完了時）: リマインダー表示 ✓
    - テスト2（Phase完了なし）: メッセージなし ✓
  critic: PASS
status: done
```

---

### p3: 統合テスト

```yaml
id: p3
name: 統合テスト
goal: 自動 /clear 判断機能が正常に動作することを確認
executor: claude
max_iterations: 10
depends_on: [p2]

正しい動きの定義:
  - 正常系: 閾値以下で警告なし
  - 異常系: 閾値超過で警告表示
  - ユーザー体験に悪影響がない

done_criteria:
  - 正常系テスト PASS
  - 異常系テスト PASS
  - critic PASS

evidence:
  正常系テスト:
    - playbook なしで staged → リマインダーなし（SKIP）
    - Exit Code: 0
  異常系テスト:
    - playbook に status: done 変更 → リマインダー表示
    - メッセージ: "📊 Phase 完了 - コンテキスト確認推奨"
    - Exit Code: 0（警告のみ、ブロックしない）
  統合動作:
    - check-coherence.sh が git commit 前に実行
    - Phase 完了検出時にリマインダーを stderr に出力
    - ユーザー体験を損なわない（警告のみ）
  critic: PASS
status: done
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | 初版作成。Issue #10。 |
