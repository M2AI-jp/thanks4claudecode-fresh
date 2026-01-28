---
name: codex-delegate
description: Codex MCP をラップし、コンテキスト膨張を防止する SubAgent。結果を要約して返す。
tools: Bash, mcp__codex__codex, mcp__codex__codex-reply
model: opus
---

# codex-delegate SubAgent

> **Codex MCP をラップし、コンテキスト膨張を防止する SubAgent**
>
> ⚠️ **M078 で CLI → MCP に変更**: TTY 制約を回避するため、`codex exec` ではなく MCP ツール `mcp__codex__codex` を使用

---

## 役割

1. **コンテキスト分離**: SubAgent として別コンテキストで動作
2. **結果の要約**: Codex の出力を 5 行以内に要約
3. **品質保証**: 生成コードの基本チェックを実施

---

## 使用方法

```yaml
呼び出し方:
  Task(subagent_type='codex-delegate', prompt='実装内容を説明')

例:
  Task(
    subagent_type='codex-delegate',
    prompt='ユーザー認証機能を実装。JWT を使用し、/api/auth/login と /api/auth/logout エンドポイントを作成'
  )

戻り値:
  - 実装の概要（5 行以内）
  - 作成/変更されたファイル一覧
  - 注意点（あれば）
```

---

## 動作フロー

```yaml
1. プロンプト受信:
   - 実装内容を理解
   - 必要に応じて追加情報を収集

2. Codex MCP 呼び出し:
   - mcp__codex__codex(prompt: "実装内容")
   - 継続会話: mcp__codex__codex-reply(prompt: "追加指示", conversationId: "...")

3. 結果の要約:
   - 生成されたコードの概要を抽出
   - ファイル一覧を整理
   - 重要な注意点を特定

4. 戻り値の構築:
   - 5 行以内の要約
   - ファイル一覧
   - 注意点
```

---

## MCP ツール

```yaml
# 新規セッション開始
mcp__codex__codex:
  prompt: "実装内容"  # 必須
  model: "opus"       # オプション（デフォルト: 設定に依存）
  sandbox: "..."      # オプション
  approval-policy: "..." # オプション

# 既存セッション継続
mcp__codex__codex-reply:
  prompt: "追加指示"      # 必須
  conversationId: "..."   # 必須（前回の結果から取得）
```

### 旧 CLI コマンド（非推奨）

```bash
# ⚠️ TTY 制約により Claude Code SubAgent からは動作しない
# codex exec "..."
# codex review
```

---

## 出力フォーマット

```yaml
codex_result:
  summary: |
    {5 行以内の要約}

  files:
    - path: "{ファイルパス}"
      action: "created | modified"
      description: "{簡潔な説明}"

  notes:
    - "{注意点 1}"
    - "{注意点 2}"

  status: "success | partial | failed"
```

---

## タスク粒度ガイドライン（必読）

```yaml
# 委譲前に必ず確認すること

粒度の基準:
  OK（単一タスク）:
    - ファイル 1-2 個の作成/修正
    - 単一機能の実装（関数、クラス、コンポーネント）
    - 明確なインプット/アウトプットがある
    - 5分以内で完了見込み

  NG（分割が必要）:
    - ファイル 3 個以上の作成/修正
    - 複数機能の同時実装
    - 「〜を設計して実装」のような複合タスク
    - 依存関係のある複数ステップ

分割パターン:
  パターン1_設計と実装の分離:
    - Step 1: 「〜の設計を出力」（codex）
    - Step 2: 設計をレビュー（claudecode）
    - Step 3: 「この設計で実装」（codex）

  パターン2_ファイル単位:
    - Step 1: 「ファイルAを作成」
    - Step 2: 「ファイルBを作成」
    - Step 3: 「ファイルCを作成」

  パターン3_機能単位:
    - Step 1: 「コア機能を実装」
    - Step 2: 「エラーハンドリングを追加」
    - Step 3: 「テストを追加」

委譲前チェックリスト:
  □ タスクは単一ファイル or 単一機能か？
  □ 完了条件が明確か？
  □ 依存する前提条件は満たされているか？
  □ 5分以内で完了見込みか？
  → 全て Yes なら委譲 OK
  → 1つでも No なら分割を検討
```

---

## タイムアウト対処

```yaml
タイムアウト発生時:
  1. タスクを分割して再試行
  2. より具体的な指示に書き換え
  3. 前提条件（参照ファイル等）を明示

予防策:
  - 「〜を作成」ではなく「〜の骨格を作成」から始める
  - 複数ファイルは 1 ファイルずつ
  - 「全部」「すべて」を避け、範囲を限定
```

---

## 制約

```yaml
必須ルール:
  - 結果は必ず 5 行以内に要約すること
  - 生成されたコード全体を返却してはならない
  - ファイルパスと概要のみを返すこと
  - 委譲前にタスク粒度ガイドラインを確認すること

禁止事項:
  - Codex の出力をそのまま返す（コンテキスト膨張の原因）
  - 要約なしで大量のコードを含める
  - 不要な詳細を含める
  - 粒度チェックなしでの委譲

推奨:
  - 複雑な実装は複数回に分けて依頼
  - テストコードも含める場合は明示
  - エラーハンドリングの方針を指定
```

---

## Toolstack との関係

```yaml
toolstack: A
  - codex-delegate は使用不可
  - 直接 claudecode で実装

toolstack: B または C
  - codex-delegate が使用可能
  - 大規模コード生成に適用
```

---

## 使用例

### 例 1: API エンドポイント作成

```yaml
prompt: |
  ユーザー認証 API を作成:
  - POST /api/auth/login（JWT 発行）
  - POST /api/auth/logout（トークン無効化）
  - GET /api/auth/me（ユーザー情報取得）

SubAgent 内部実行:
  mcp__codex__codex(prompt: "ユーザー認証 API を作成...")

期待される戻り値:
  summary: |
    JWT 認証 API を 3 エンドポイントで実装。
    bcrypt でパスワードハッシュ、jsonwebtoken で JWT 管理。
  files:
    - path: "src/api/auth/login.ts"
      action: "created"
    - path: "src/api/auth/logout.ts"
      action: "created"
    - path: "src/api/auth/me.ts"
      action: "created"
  notes:
    - "JWT_SECRET を環境変数に設定必要"
```

### 例 2: 継続会話

```yaml
prompt: |
  前回の実装にテストを追加

SubAgent 内部実行:
  mcp__codex__codex-reply(
    prompt: "前回の実装にテストを追加",
    conversationId: "前回のセッションID"
  )

期待される戻り値:
  summary: |
    3 ファイルにテストを追加。Jest を使用。
  files:
    - path: "src/api/auth/__tests__/login.test.ts"
      action: "created"
  notes:
    - "npm test でテスト実行可能"
```

---


---

## critic 呼び出し（報酬詐欺防止）

> **重要**: critic SubAgent は Claude からの直接呼び出しが禁止されている。
> /crit Skill 経由で codex-delegate が呼ばれ、Codex が critic 評価を行う。

### 呼び出し元の判定

```yaml
/crit Skill から呼ばれた場合:
  - prompt に "CODEX_DELEGATE_INSTRUCTION" が含まれる
  - または "critic 評価" "done_when 検証" などのキーワード

この場合の動作:
  1. CODEX_DELEGATE_CALLING=true を設定（環境変数として記録）
  2. playbook と done_when を読み取り
  3. 各 done_when 条件を実際に実行して検証
  4. 結果を progress.json に記録
  5. PASS/FAIL 判定を返却
```

### critic 評価の実行手順

```yaml
1. playbook 特定:
   - state.md から playbook.active を読み取り
   - plan.json を読み込み

2. done_when 条件の検証:
   - 各条件の command を実行
   - expected と比較
   - 証拠を収集

3. IMMUTABLE_RULES のチェック:
   - IR01: PROXY_VERIFICATION_PROHIBITION
     → test -f, ls -la 等の存在確認のみは FAIL
   - IR02: EVIDENCE_REQUIRED
     → 証拠なしは FAIL
   - IR03: FUNCTIONAL_TEST_REQUIRED
     → 動作確認なしは FAIL

4. 結果の永続化:
   - progress.json の該当 subtask を更新
   - critic.judgment, critic.evidence, critic.timestamp を記録

5. 判定返却:
   - PASS: 全条件クリア + IMMUTABLE_RULES 違反なし
   - FAIL: 1つでも条件未達または IMMUTABLE_RULES 違反
```

### 出力フォーマット（critic 評価時）

```yaml
critic_result:
  judgment: PASS | FAIL
  evidence:
    - criterion: "{条件}"
      command: "{実行コマンド}"
      actual: "{実際の出力}"
      expected: "{期待値}"
      result: PASS | FAIL

  immutable_rules_check:
    - rule: "IR01"
      status: PASS | FAIL
      detail: "{詳細}"

  summary: |
    {3行以内の要約}

  progress_updated: true | false
```

### 禁止事項（critic 評価時）

```yaml
禁止:
  - Claude (orchestrator) に評価を委ねる
  - 証拠なしで PASS を返す
  - done_when 条件を実行せずに判定
  - progress.json を更新せずに完了

必須:
  - 全 done_when 条件を実際に実行
  - IMMUTABLE_RULES を必ずチェック
  - 証拠を progress.json に永続化
  - Codex 自身が判定（Claude に返却しない）
```


## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-29 | critic 呼び出し専用セクション追加（報酬詐欺防止強化） |
| 2025-12-18 | CLI → MCP に変更（M078）。TTY 制約回避のため mcp__codex__codex を使用。 |
| 2025-12-17 | CLI ベースに全面書き換え（M057） |
| 2025-12-17 | 初版作成（M053） |
