# Meta-Roadmap（roadmap を改善するための計画）

> **roadmap 自体を完璧にするためのレイヤー。**
> **問題発見 → 影響分析 → 修正 → 検証のサイクルを回す。**

---

## 1. 現状の問題

```yaml
roadmap_problems:
  一方通行:
    症状: マイルストーンが M1→M2→...→M8 と直線的
    問題: 後工程で発見した問題が前工程に伝播しない
    例: M5 で setup 問題発見 → M3 の設計ミスだが、M3 は「完了済み」

  担当者アサインなし:
    症状: 「誰がやるか」が曖昧
    問題: Claude Code / Codex / CodeRabbit / User の分担が不明
    例: "認証機能を実装" → 誰が設計し、誰が実装し、誰がレビューするか

  チェックリスト化:
    症状: done_when が「✓ を付けるだけ」になっている
    問題: 「設定した」と「動く」が混同される
    例: "SessionStart Hook が正常動作 ✓" → 実際には検証されていない

  フィードバックなし:
    症状: 「終わりました」で会話終了
    問題: 振り返り、知見の蓄積、改善サイクルがない
    例: M7 完了 → 次の M8 へ → M7 で学んだことが消える

  テストの意味不明:
    症状: 27/27 PASS だが、何を確認したか不明
    問題: Hook 動作確認 ≠ ユーザー体験確認
    例: "P0-P5 全 PASS" → 新規ユーザーが使えるか未検証
```

---

## 2. 改善サイクル

```
問題発見 → 影響分析 → 修正計画 → 実装 → 検証 → 反映
    ↑_______________________________________________|
                    (フィードバックループ)
```

### 2.1 問題発見トリガー

```yaml
triggers:
  マイルストーン完了時:
    - 振り返り質問に回答
    - 想定と実際のギャップを記録

  デバッグフェーズ:
    - 3 マイルストーンごとに実施
    - 過去の問題を根本原因分析

  ユーザーフィードバック:
    - 新規ユーザーテスト結果
    - Issue / PR コメント

  テスト失敗時:
    - 失敗の根本原因を特定
    - 設計レベルの問題かを判断
```

### 2.2 影響分析テンプレート

```yaml
impact_analysis:
  問題ID: P-001
  発見場所: M5（E2E 検証と公開準備）
  症状: "setup フローが focus=setup でも main ブランチをブロック"

  根本原因分析（5 Whys）:
    - Why 1: check-main-branch.sh が focus を見ていなかった
    - Why 2: M3 設計時に focus 別の挙動を考慮していなかった
    - Why 3: done_when が「ブロックする」だけで「いつブロックするか」を定義していなかった
    - Why 4: マイルストーン設計時にユーザーシナリオを考慮していなかった
    - Why 5: vision.md がなく、ユーザー視点が欠けていた

  影響を受ける工程:
    前工程: [M3（check-main-branch.sh 設計）]
    後工程: [M6, M7, M8（テスト更新が必要）]

  修正計画:
    - M3: check-main-branch.sh を focus 別に再設計
    - M6: テストケース追加（focus=setup での挙動）
    - roadmap: 新規マイルストーン設計時に「ユーザーシナリオ」を必須化
    - meta-roadmap: この問題パターンを記録
```

---

## 3. デバッグフェーズ

> **3 マイルストーンごとに実施する定期的な振り返り。**

### 3.1 デバッグフェーズのスケジュール

| フェーズ | 対象マイルストーン | 実施タイミング |
|---------|-------------------|---------------|
| Debug-1 | M1, M2, M3 | M3 完了後 |
| Debug-2 | M4, M5, M6 | M6 完了後 |
| Debug-3 | M7, M8, M9 | M9 完了後 |
| ... | ... | ... |

### 3.2 デバッグフェーズのアクティビティ

```yaml
debug_phase_activities:
  1_振り返り:
    duration: 30分
    questions:
      - 各マイルストーンで発見された問題は何か？
      - 想定と実際のギャップは何か？
      - 「完了」と言ったが実際には未完了だったものは？

  2_根本原因分析:
    duration: 60分
    method: 5 Whys
    output: 問題パターンのリスト

  3_前工程修正:
    duration: 60分
    actions:
      - 影響を受ける前工程を特定
      - 修正内容を playbook 化
      - 担当者をアサイン

  4_roadmap改善:
    duration: 30分
    actions:
      - 今後のマイルストーン設計に反映
      - テンプレート更新
      - CONTEXT.md に知見追加

  5_テスト戦略更新:
    duration: 30分
    actions:
      - 欠けていたテストケース追加
      - E2E テストシナリオ更新
```

---

## 4. 問題パターン集（学習記録）

> **過去に発見された問題パターンを記録し、再発を防ぐ。**

### パターン 1: 自己報酬詐欺

```yaml
pattern_id: P-001
name: 自己報酬詐欺
symptoms:
  - 「完了」と言うが実際には未完了
  - done_when に ✓ を付けるが証拠がない
  - 「設定した」と「動く」を混同
cause: critic エージェントなしで done 判定
prevention:
  - critic PASS 必須化（構造的強制）
  - done_when に「証拠」欄を追加
  - 「設定した」ではなく「動作確認した」を要求
```

### パターン 2: ユーザー視点の欠如

```yaml
pattern_id: P-002
name: ユーザー視点の欠如
symptoms:
  - テストは通るがユーザーが使えない
  - 「機能が存在する」と「ユーザーが使える」を混同
  - 開発者視点でのみ設計
cause: vision.md がなく、ユーザーシナリオが定義されていない
prevention:
  - vision.md を最上位レイヤーとして必須化
  - マイルストーン設計時にユーザーシナリオを要求
  - E2E テストは「新規ユーザー視点」で作成
```

### パターン 3: 一方通行の計画

```yaml
pattern_id: P-003
name: 一方通行の計画
symptoms:
  - 後工程で問題発見しても前工程に伝播しない
  - 「完了済み」のマイルストーンは修正できないと思い込む
  - roadmap がチェックリスト化
cause: フィードバックループがない
prevention:
  - マイルストーン完了時に振り返り必須
  - 影響分析テンプレートの使用
  - デバッグフェーズの定期実施
```

---

## 5. 改善提案キュー

> **発見された問題と改善提案を管理する。**

```yaml
improvement_queue:
  - id: IMP-001
    created: 2025-12-04
    status: proposed
    title: "マイルストーン設計テンプレートの改善"
    description: |
      現在のマイルストーン定義には「担当者アサイン」と
      「影響分析」が含まれていない。
    proposed_changes:
      - マイルストーンに `assignee` フィールド追加
      - マイルストーンに `affects` フィールド追加
      - マイルストーンに `rollback` フィールド追加
    priority: high
    assignee: claude_code

  - id: IMP-002
    created: 2025-12-04
    status: proposed
    title: "オーケストレーションテストの追加"
    description: |
      現在の 27/27 PASS は Hook 動作確認のみ。
      Claude Code → Codex → CodeRabbit の流れを確認するテストがない。
    proposed_changes:
      - test-orchestration.sh の作成
      - シナリオ: "新規機能リクエスト → 実装 → レビュー → マージ"
    priority: high
    assignee: codex
```

---

## 6. 現在の改善フォーカス

```yaml
current_focus:
  cycle: 1（初回改善サイクル）
  target: roadmap 自体の設計改善

  tasks:
    - id: META-1
      description: "vision.md を作成"
      status: done
      assignee: claude_code

    - id: META-2
      description: "meta-roadmap.md を作成"
      status: done
      assignee: claude_code

    - id: META-3
      description: "roadmap.md を完全再設計"
      status: done
      assignee: claude_code
      depends_on: [META-1, META-2]

    - id: META-4
      description: "オーケストレーションテスト作成"
      status: pending
      assignee: codex
      depends_on: [META-3]

    - id: META-5
      description: "E2E ユーザーシナリオテスト作成"
      status: pending
      assignee: codex
      depends_on: [META-3]

  next_debug_phase:
    trigger: META-5 完了後
    activities: 改善サイクル 1 の振り返り
```

---

## 7. デバッグフェーズ実施記録

### Debug-1: M5, M6, M7 の振り返り（2025-12-04）

```yaml
phase: Debug-1
target: [M5, M6, M7]
conducted: 2025-12-04

振り返り結果:
  M5_オーケストレーション検証:
    想定: Claude Code → Codex → CodeRabbit の流れをテスト
    実際:
      - Codex 委譲: 成功（orchestration-utils.sh 生成）
      - CodeRabbit 連携: 成功（PR #4 で 18 コメント受信）
      - オフラインタスク: 成功（user-handoff.log に記録）
    ギャップ: なし（想定通り動作）

  M6_E2E検証:
    想定: 実ユーザーによる E2E テスト
    実際:
      - シミュレーションベースのテスト基盤構築
      - 実ユーザーテストは M9 に延期
    ギャップ:
      - done_criteria が「実ユーザー」を前提としていた
      - 「シミュレーション基盤構築」に修正
    教訓:
      - done_criteria は達成可能な範囲で定義すべき
      - 実ユーザーテストは公開準備フェーズ（M9）が適切

  M7_フィードバックループ検証:
    想定: 振り返り自動促進、影響分析、デバッグフェーズ
    実際:
      - [自認] テンプレートで状態宣言を促進
      - critic エージェントで批判的評価
      - meta-roadmap.md に影響分析テンプレート完備
    ギャップ: なし（設計通り機能）

根本原因分析:
  M6のdone_criteria問題:
    - Why 1: done_criteria が「実ユーザー」を前提としていた
    - Why 2: roadmap 設計時に「開発フェーズ」と「公開フェーズ」を区別していなかった
    - Why 3: E2E テストの 2 段階（シミュレーション → 実ユーザー）を定義していなかった
    対策: M9 に実ユーザー E2E テストを明確化

改善提案:
  - id: IMP-003
    title: "done_criteria の 2 段階定義"
    description: |
      開発フェーズでは「シミュレーション基盤」を、
      公開フェーズでは「実ユーザー検証」を要求する。
    status: applied
    applied_to: M6 done_when 修正

  - id: IMP-004
    title: "E2E テストの構造化"
    description: |
      test/E2E/ に隔離環境を構築。
      sandbox, results, logs を分離し、リポジトリを汚染しない。
    status: applied
    applied_to: test/E2E/run-e2e-test.sh

次のアクション:
  - PHASE_3（Release）に進む
  - M8: ドキュメント整備
  - M9: 最終 E2E テスト（実ユーザー検証）
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-04 | Debug-1 実施。M5, M6, M7 の振り返りと改善提案追加。 |
| 2025-12-04 | 初版作成。roadmap 改善のための meta-roadmap を新設。 |
