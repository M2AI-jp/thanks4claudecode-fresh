# playbook-{project}.md

> **このテンプレートを埋めて playbook を作成する。**
>
> 詳細な記述方法は planning-rules.md を参照。
> 具体例は playbook-examples.md を参照。

---

## meta

```yaml
project: {プロジェクト名}
branch: {type}/{description}  # feat/xxx, fix/xxx, refactor/xxx, docs/xxx
created: {作成日}
```

> **branch フィールド**: playbook とブランチは 1:1 で紐づく。
> session-start.sh が現在のブランチと照合し、不一致なら警告。

---

## goal

```yaml
summary: {1行の目標}
done_when:
  - {最終完了条件1}
  - {最終完了条件2}
```

---

## phases

```yaml
- id: p1
  name: {フェーズ名}
  goal: {このフェーズの目標}
  executor: {codex | user}
  done_criteria:
    - {完了条件1}
    - {完了条件2}
    - 実際に動作確認済み（test_method 実行）  # ← 必須パターン
  test_method: |
    1. {検証手順1}
    2. {検証手順2}
    3. {期待結果の確認}
  status: pending  # pending | in_progress | done

- id: p2
  name: {フェーズ名}
  goal: {このフェーズの目標}
  executor: {codex | user}
  depends_on: [p1]
  done_criteria:
    - {完了条件1}
    - 実際に動作確認済み
  test_method: |
    1. {検証手順}
  status: pending
```

---

## Phase 記述ルール

### 必須項目

| 項目 | 説明 |
|------|------|
| id | Phase 識別子（p1, p2, ...） |
| name | フェーズ名 |
| goal | このフェーズの目標（1行） |
| executor | 実行者（codex または user） |
| done_criteria | 完了条件のリスト |
| status | 状態（pending / in_progress / done） |

### オプション項目

| 項目 | 説明 |
|------|------|
| depends_on | 依存する Phase の id リスト |
| prerequisites | 前提条件（環境、ツールなど） |
| test_method | **推奨**: done_criteria を検証する具体的な手順 |
| max_iterations | **推奨**: LOOP 回数上限（デフォルト: 10）。デッドロック防止 |
| time_limit | **推奨**: 想定作業時間（例: 30min, 1h）。超過時は警告 |
| priority | **推奨**: 優先度（high / medium / low）。LLM が実行順序を判断 |
| notes | 補足情報 |

### 計画管理フィールドの使い方

```yaml
# タイムボックス機能（task-01）
time_limit: 30min  # 超過時は LLM が [自認] で警告を表示

# 優先順位管理（task-02）
priority: high  # high > medium > low の順で実行を優先

# 依存関係管理（task-03）
depends_on: [p1, p2]  # 依存 Phase が未完了なら実行不可
```

**LLM の行動ルール**:
- `time_limit` 超過 → 「Phase {id} の想定時間を超過しています」と警告
- `priority: high` → 他の Phase より優先して実行
- `depends_on` 未完了 → 「依存 Phase {ids} が未完了です」と警告し実行しない

---

## done_criteria 記述ガイド

```yaml
形式:
  - "{対象} が {状態} である"
  - "{コマンド} が {期待結果} を返す"
  - "実際に動作確認済み"  # ← 推奨: 全 Phase に含める

良い例:
  - "README.md が存在する"
  - "npm test が exit code 0 で終了する"
  - "http://localhost:3000 が 200 を返す"
  - "check-coherence.sh が PASS する"
  - "実際に動作確認済み（test_method 実行）"  # ← 必須パターン

悪い例:
  - "ドキュメントを書く" ← 状態が不明
  - "テストする" ← 何をテストするか不明
  - "完成させる" ← 検証不可能
  - "設定した" ← 動くかどうか不明（要テスト）

⚠️ 注意:
  - 「設定した」≠「動く」
  - 必ず test_method を定義し、実際に実行すること
  - 証拠なしの done は禁止
```

---

## executor 判定ガイド

```yaml
codex:
  - コード実装
  - テスト実行
  - ファイル操作
  - ドキュメント生成

user:
  - 外部サービス登録（Vercel, GCP, Stripe）
  - API キー取得
  - 意思決定
  - 支払い情報入力

キーワード判定:
  - "登録" "サインアップ" "契約" → user
  - "API キー" "シークレット" → user
  - "選んでください" → user
  - それ以外 → codex
```

---

## executor: user の完了確認ガイド

> **user が実行する Phase は「自己申告」に依存するため、完了確認を強化する**

### 完了確認のフロー

```yaml
LLM の行動:
  1. 「次は〇〇を行ってください」と案内
  2. 具体的な手順をリスト形式で提示
  3. 「完了したらお知らせください」と依頼
  4. ユーザーが「完了」と報告
  5. 【重要】done_criteria をチェックリスト形式で確認
  6. 全て確認 → Phase 完了

確認例（デプロイの場合）:
  LLM: 「以下を確認させてください：
    - [ ] Vercel にサインアップ済みですか？
    - [ ] 環境変数（OPENAI_API_KEY）を設定しましたか？
    - [ ] デプロイ URL にアクセスして動作確認しましたか？」
```

### 自動検証可能な場合

```yaml
検証可能な done_criteria:
  - URL にアクセスして 200 が返る
    → LLM が curl で確認可能
  - 環境変数が設定されている
    → LLM が確認不可（ユーザーに確認を依頼）

検証方法の記載例:
  done_criteria:
    - デプロイ URL が 200 を返す
  test_method: |
    curl -I {url} でステータスコードを確認
    または LLM が WebFetch で確認
```

### 自動検証不可の場合

```yaml
ユーザーに明示的な確認を求める:
  - 「〇〇を完了しましたか？」と YES/NO で聞く
  - 複数項目がある場合はチェックリスト形式

禁止事項:
  - ユーザーが「完了」と言っただけで Phase を done にする
  - 確認なしで次の Phase に進む
```

---

## ダブルチェック機能（Phase 完了前必須）

> **Phase を done にする前に、必ず以下のチェックを実行すること。**
> **これは自己報酬詐欺を防止するための構造的強制である。**

### pre_done_checklist

```yaml
# Phase を done にする前の必須チェックリスト
pre_done_checklist:
  evidence_check:
    - [ ] done_criteria の全項目に「証拠」を示せるか?
    - [ ] 証拠は「コマンド実行結果」または「ファイル引用」か?
    - [ ] 「満たしている気がする」で判定していないか?
    - [ ] 「設定した」ではなく「動作確認した」か?

  critic_check:
    - [ ] critic エージェントを呼び出したか?
    - [ ] critic が PASS を返したか?
    - [ ] critic が指摘した問題を全て解決したか?

  test_execution:
    - [ ] playbook の test_method を実際に実行したか?
    - [ ] test_method の期待結果と一致したか?
    - [ ] エッジケースを考慮したか?
```

### 自己報酬詐欺の検出パターン

```yaml
# 以下の症状がある場合、報酬詐欺の可能性が高い
fraud_symptoms:
  language_patterns:
    - 「〇〇した」だけで証拠なし
    - 「〇〇のはず」「〇〇だと思う」
    - 「シミュレーションでは...」（実行なし）
    - 「設計上は...」（動作確認なし）

  behavior_patterns:
    - done_criteria の一部のみ確認
    - critic を呼び出さずに done 判定
    - test_method を実行せずに PASS
    - 机上の検討のみで実装完了と主張

  action_on_detection:
    1. 即座に critic エージェントを呼び出す
    2. 不足している証拠を収集
    3. 問題を修正してから再判定
```

### ダブルチェック実行フロー

```yaml
# Phase 完了判定時の必須フロー
double_check_flow:
  step_1:
    name: 自己評価
    action: done_criteria を1つずつ確認し、証拠を列挙

  step_2:
    name: critic 呼び出し（必須）
    action: |
      Task(subagent_type="critic"):
        評価対象: 全 done_criteria
        判定: PASS/FAIL（証拠ベース）

  step_3:
    name: critic 結果の処理
    if_pass: Phase を done に更新
    if_fail: 問題を修正 → step_1 に戻る

  step_4:
    name: 最終確認
    action: |
      LLM の自問:
        - 「本当に終わったか?」
        - 「ユーザーが見たら満足するか?」
        - 「証拠なしで完了と言っていないか?」
```

### playbook への統合

```yaml
# playbook 作成時、各 Phase に以下を含める（推奨）
- id: p1
  name: {フェーズ名}
  done_criteria:
    - {完了条件}
    - 実際に動作確認済み（test_method 実行）
  test_method: |
    1. {検証手順}
  double_check: true  # ← ダブルチェック必須フラグ（デフォルト true）
  status: pending
```

### 強制メカニズム

```yaml
# ダブルチェックを強制するための仕組み
enforcement:
  claude_md_rule:
    location: CLAUDE.md LOOP セクション
    content: |
      全て PASS?
        - YES → CRITIQUE() を実行
          - CRITIQUE pass → state.md更新 → 次のPhaseへ
          - CRITIQUE fail → 問題を修正 → continue

  critic_agent:
    trigger: done 判定前に自動委譲
    model: haiku（軽量・高速）
    output: PASS/FAIL + 証拠

  check_coherence:
    trigger: git commit 前
    action: state.md と playbook の整合性チェック
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | V7: max_iterations フィールド追加。デッドロック防止。 |
| 2025-12-02 | V6: ダブルチェック機能追加。自己報酬詐欺防止の構造的強制。 |
| 2025-12-01 | V5: executor:user 完了確認ガイドを追加。 |
| 2025-12-01 | V4: branch フィールド追加。playbook とブランチの 1:1 紐づけ。 |
| 2025-12-01 | V3: タイプ別分類を削除。純粋なフォーマット定義に。 |
| 2025-12-01 | V2: タイプ別最小構造に再設計。 |
| 2025-12-01 | V1: 初版。 |
