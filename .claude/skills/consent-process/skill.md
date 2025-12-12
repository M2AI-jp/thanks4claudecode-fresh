# consent-process

> **合意プロセス（CONSENT）- ユーザープロンプトの誤解釈防止**

---

## frontmatter

```yaml
name: consent-process
description: ユーザープロンプトの誤解釈防止。[理解確認] ブロックを強制。
triggers:
  - playbook=null で新規タスク開始時
  - Edit/Write 前の合意取得が必要な時
auto_invoke: false  # INIT フェーズ 4.5 で手動参照
```

---

## 目的

```yaml
problem: |
  Claude がユーザープロンプトを「良かれと思って省略」し、
  意図しない大規模変更や方向性のずれが発生する。

solution: |
  Edit/Write 前に処理結果を構造化出力し、ユーザー合意を取得。
  Hook（consent-guard.sh）で合意ファイルの有無をチェック。
```

---

## [理解確認] フォーマット（5W1H形式）

> **5W1H**: What, Why, Who, When, Where, How の6つの観点で構造化

```
[理解確認]
What（何を）:
  「〇〇を実装/作成/修正すること」と理解しました

Why（なぜ）:
  目的: 「△△という課題を解決するため」
  背景: 「□□という状況があるため」

Who（誰が）:
  - claudecode: ファイル作成・編集・コマンド実行
  - user: 外部サービス登録（該当する場合）
  - codex: 本格的なコード実装（該当する場合）

When（いつまでに）:
  特に期限指定なし / 〇〇までに完了

Where（どこに）:
  新規作成:
    - docs/xxx.md
  更新:
    - .claude/hooks/xxx.sh
  変更なし:
    - CLAUDE.md
    - state.md

How（どのように）:
  1. 〇〇を調査する
  2. △△を設計する
  3. □□を実装する
  4. テストで検証する
```

### 5W1H 各項目の説明

| 項目 | 説明 | 必須 |
|------|------|------|
| What | 何をするか（タスクの要約） | 必須 |
| Why | なぜするか（目的・背景） | 必須 |
| Who | 誰が実行するか（executor） | 必須 |
| When | いつまでに（期限） | 任意 |
| Where | どこに作成/変更するか（ファイル） | 必須 |
| How | どのように進めるか（手順） | 必須 |

---

## ユーザー応答フロー

```yaml
OK: |
  「了解」または「OK」→ Claude がファイルを削除（.claude/.session-init/consent）→ 処理開始
修正: |
  「〇〇ではなく△△です」→ Claude が [理解確認] を再出力 → 再合意
却下: |
  「やめて」または「キャンセル」→ 処理中止
```

---

## Hook 統合

```yaml
hook_name: consent-guard.sh
trigger: PreToolUse:Edit/Write
location: .claude/hooks/consent-guard.sh

workflow: |
  1. session-start.sh:
     → .claude/.session-init/pending 作成
     → .claude/.session-init/consent 作成

  2. init-guard.sh:
     → pending 存在 → Read 強制
     → Read 完了 → pending 削除

  3. [理解確認]:
     → Claude が処理結果を構造化出力
     → ユーザー応答待機

  4. consent-guard.sh:
     → consent ファイル存在?
     → YES（ユーザー OK) → ファイル削除 → 通過 → Edit/Write 実行
     → NO（未承認） → exit 2 ブロック → [理解確認] 再表示

  5. playbook-guard.sh:
     → playbook チェック → 通過

  6. LOOP:
     → done_criteria 検証 → 実行

file_locations:
  pending: .claude/.session-init/pending
  consent: .claude/.session-init/consent
```

---

## 実装状態

```yaml
status: implemented

components:
  consent_guard_sh:
    file: .claude/hooks/consent-guard.sh
    status: created
    functionality: consent ファイルの有無を確認、exit 2 でブロック

  settings_json:
    file: .claude/settings.json
    status: REGISTERED
    hook: PreToolUse:Edit/Write
    script: consent-guard.sh

  session_start_sh:
    file: .claude/hooks/session-start.sh
    status: INTEGRATED
    new_functionality: consent ファイル作成機能追加
```

---

## 禁止パターン

```yaml
forbidden:
  - [理解確認] なしで Edit/Write 実行
  - ユーザー応答なしで consent ファイル削除
  - consent ファイル作成後、[理解確認] を出力しない
```
