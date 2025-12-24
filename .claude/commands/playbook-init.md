---
description: 新しい playbook を作成するウィザード。既存 playbook のチェック、ブランチ作成、pm 呼び出しを含む。
allowed-tools: Read, Write, Edit, Bash, Task
---

# /init - 新しいタスク開始フロー

> **このフローは構造的に強制される。手順をスキップしてはならない。**

---

## Step -1: 再実行チェック（必須・自動実行）

以下のコマンドを**必ず実行**し、playbook の状態を確認せよ：

```bash
echo "=== Step -1: 再実行チェック ===" && \
echo "1. 既存の playbook:" && ls plan/playbook-*.md 2>/dev/null || echo "(なし)" && \
echo "2. playbook の branch:" && grep "^branch:" plan/playbook-*.md 2>/dev/null | head -1 || echo "(なし)" && \
echo "3. in_progress の Phase:" && grep -A1 "status: in_progress" plan/playbook-*.md 2>/dev/null | head -3 || echo "(なし)"
```

### 判定フロー

| 条件 | 対応 |
|------|------|
| playbook なし | → Step 0 へ進む |
| playbook あり & in_progress Phase なし | → ユーザーに確認（下記参照） |
| playbook あり & in_progress Phase あり | → **STOP** → タスク中断の確認が必要 |

### playbook が既に存在する場合

ユーザーに以下を確認せよ：

```
既存の playbook が見つかりました: plan/playbook-{name}.md

選択肢:
1. 既存の playbook を上書きする（現在のタスクを破棄）
2. 新しいブランチで別の playbook を作成する
3. キャンセルして既存のタスクを続行する

どれを選びますか？
```

### in_progress の Phase がある場合

```
⚠️ 進行中のタスクがあります:
  - {Phase 名}: in_progress

このタスクを中断して新しいタスクを開始しますか？
中断する場合、既存の playbook は plan/archive/ に移動されます。

[中断して新規作成] / [キャンセル]
```

---

## Step 0: 前提条件チェック（必須・自動実行）

以下のコマンドを**必ず実行**し、結果を確認せよ：

```bash
echo "=== Step 0: 前提条件チェック ===" && \
echo "1. 未コミット変更:" && git status --short && \
echo "2. 現在のブランチ:" && git branch --show-current && \
echo "3. 未 push コミット:" && git log --oneline @{u}..HEAD 2>/dev/null || echo "(upstream なし)"
```

### チェック項目

| 条件 | 対応 |
|------|------|
| 未コミット変更がある | **STOP** → 先にコミットせよ |
| main ブランチにいる | OK（Step 1 でブランチを切る） |
| 未 push コミットがある | 警告 → push を検討 |

**未コミット変更がある場合、このフローを続行してはならない。**

---

## Step 1: ブランチ作成（必須）

### 1.1 ブランチ名の自動決定

**ユーザーの要求内容からブランチ名を自動推論**せよ。質問するな。

| 要求の種類 | ブランチ名パターン |
|-----------|-------------------|
| 新機能追加 | feat/{機能名を kebab-case に} |
| バグ修正 | fix/{問題の短い説明} |
| リファクタリング | refactor/{対象} |
| ドキュメント | docs/{対象} |
| テスト | test/{対象} |

**推論の例:**
- 「ユーザー認証を追加して」→ `feat/user-authentication`
- 「ログインできないバグを直して」→ `fix/login-bug`
- 「API の構造を整理して」→ `refactor/api-structure`

### 1.2 ブランチ作成（自動実行）

**推論したブランチ名で即座に実行**（確認不要）：

```bash
git checkout -b {推論したブランチ名}
```

**ブランチを作成するまで次のステップに進んではならない。**

---

## Step 1.5: 理解確認（必須・STOP）

> **⚠️ STOP: このステップは必ず実行せよ。スキップ厳禁。**

### 1.5.1 5W1H 分析

ユーザーの要求を以下の観点で分析し、**必ずテーブル形式で出力**せよ：

| 項目 | 質問 | 分析結果 |
|------|------|----------|
| What | 何を作るのか？ | {具体的な成果物} |
| Why | なぜ必要なのか？ | {目的・背景} |
| Who | 誰が使うのか？ | {ユーザー・利用者} |
| When | いつ使うのか？ | {利用タイミング} |
| Where | どこで使うのか？ | {配置場所・環境} |
| How | どう実現するのか？ | {技術スタック・アプローチ} |

**推論できない項目は「不明（要確認）」と記載せよ。**

### 1.5.2 リスク・不明点の洗い出し

以下を列挙せよ：

```markdown
### リスク
- {潜在的な問題点}

### 不明点
- {確認が必要な事項}

### 前提条件
- {暗黙の前提}
```

### 1.5.3 理解内容の提示

以下のフォーマットで理解内容を提示せよ：

```markdown
## 理解確認

**要約**: {1行での要約}

**成果物**:
- {成果物1}
- {成果物2}

**完了条件**:
- {条件1}
- {条件2}

この理解で合っていますか？
```

### 1.5.4 AskUserQuestion で承認を求める（必須）

**テキストで質問するな。必ず AskUserQuestion ツールを使用せよ。**

```
AskUserQuestion:
  question: "この理解で playbook を作成してよいですか？"
  header: "確認"
  options:
    - label: "はい、作成してください"
      description: "上記の理解で playbook を作成し、実装を開始します"
    - label: "いいえ、修正があります"
      description: "理解に誤りがあるため、修正を伝えます"
```

### 1.5.5 承認結果の記録

承認された場合、以下の情報を Step 3 の playbook に含める：
- 5W1H 分析結果
- 承認日時（approved_at）

**承認されるまで Step 2 に進んではならない。**

---

## Step 2: playbook 自動生成（必須）

**ユーザーの最初の要求から以下を自動推論**せよ。追加の質問は禁止。

1. **ゴール**: 要求の本質を 1 行で要約
2. **done_criteria**: 完了条件をテスト可能な形式で列挙
3. **phases**: 論理的なフェーズに分割

**推論できない場合のみ**、最小限の確認を行う（「何を作りますか？」ではなく「〇〇という理解で合っていますか？」）

---

## Step 3: playbook 作成（自動実行）

### 3.1 ファイル作成

`plan/playbook-{project-name}.md` を作成。

**重要**: `branch:` フィールドには **Step 1 で作成したブランチ名を自動設定**せよ。

```yaml
meta:
  project: {プロジェクト名}
  branch: {Step 1 で作成したブランチ名}  # ← 自動設定（手入力禁止）
  created: {今日の日付}
  reviewed: false  # ← Step 6 で reviewer PASS 後に true に変更

context:  # ← Step 1.5 の分析結果を記録
  approved_at: {承認日時}
  analysis:
    what: {何を作るか}
    why: {なぜ必要か}
    who: {誰が使うか}
    when: {いつ使うか}
    where: {どこで使うか}
    how: {どう実現するか}
  risks:
    - {リスク1}
  assumptions:
    - {前提条件1}

goal:
  summary: {1行の目標}
  done_when:
    - {最終完了条件}

phases:
  - id: p1
    name: {フェーズ名}
    goal: {目標}
    executor: codex
    done_criteria:
      - {完了条件}
    status: pending
```

### 3.2 整合性確認

playbook 作成後、以下を実行して整合性を確認：

```bash
echo "=== 整合性確認 ===" && \
echo "現在のブランチ:" && git branch --show-current && \
echo "playbook の branch:" && grep "^branch:" plan/playbook-*.md | tail -1
```

**両者が一致していなければ、playbook を修正せよ。**

---

## Step 4: state.md 更新（自動実行）

以下のセクションを更新：

1. `playbook.active:` → 作成した playbook のパス
2. `playbook.branch:` → Step 1 で作成したブランチ名
3. `goal.phase:` → p0 または最初の phase ID

```yaml
# state.md の playbook セクション
playbook:
  active: plan/playbook-{project-name}.md
  branch: {Step 1 で作成したブランチ名}
```

---

## Step 5: 最終確認（自動実行）

以下を実行して全体の整合性を確認：

```bash
bash .claude/hooks/check-coherence.sh
```

**ERROR がある場合、修正するまで Step 6 に進んではならない。**

---

## Step 6: Reviewer 検証（必須・STOP）

> **⚠️ STOP: このステップは必ず実行せよ。スキップ厳禁。**

### 6.1 Reviewer 呼び出し

**Task ツールで reviewer SubAgent を呼び出せ：**

```
Task:
  subagent_type: reviewer
  prompt: |
    以下の playbook をレビューしてください：
    - ファイル: plan/playbook-{project-name}.md

    検証項目：
    1. context セクションが存在し、5W1H が記載されているか
    2. goal.done_when が検証可能な形式か
    3. phases の done_criteria が具体的か
    4. branch と現在のブランチが一致しているか

    PASS / FAIL で判定し、FAIL の場合は修正点を列挙してください。
```

### 6.2 レビュー結果の処理

| 結果 | 対応 |
|------|------|
| PASS | `meta.reviewed: true` に更新し、作業開始可能 |
| FAIL | 指摘事項を修正し、再度 reviewer を呼び出す |

### 6.3 reviewed フラグの更新

reviewer が PASS を返したら、playbook の `meta.reviewed` を更新：

```yaml
meta:
  reviewed: true  # ← false から true に変更
```

**`reviewed: true` になるまで Phase 1 の作業を開始してはならない。**

---

## フロー図

```
┌─────────────────────────────────────────────────┐
│ /init 実行                                       │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ Step -1: 再実行チェック                          │
│   - playbook あり & in_progress? → STOP          │
│   - playbook あり? → ユーザーに確認              │
│   - playbook なし? → 続行                        │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ Step 0: 前提条件チェック                         │
│   - 未コミット変更あり? → STOP                   │
│   - main ブランチ? → OK（次で切る）              │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ Step 1: ブランチ作成                             │
│   - ブランチ名を自動推論                         │
│   - git checkout -b {branch}                    │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ Step 1.5: 理解確認 ⚠️ STOP                       │
│   - 5W1H 分析をテーブル出力                      │
│   - リスク・不明点の洗い出し                     │
│   - AskUserQuestion で承認を求める               │
│   - 承認されるまで次に進まない                   │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ Step 2: playbook 自動生成                        │
│   - ゴール、done_criteria、phases を推論         │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ Step 3: playbook 作成                            │
│   - context セクションに 5W1H を記録             │
│   - branch: は Step 1 のブランチを自動設定       │
│   - reviewed: false で作成                       │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ Step 4: state.md 更新                            │
│   - playbook.active, playbook.branch を更新      │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ Step 5: 最終確認                                 │
│   - check-coherence.sh で整合性チェック          │
│   - ERROR なし → Step 6 へ                       │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ Step 6: Reviewer 検証 ⚠️ STOP                    │
│   - Task(subagent_type='reviewer') を呼び出し    │
│   - PASS → reviewed: true に更新                 │
│   - FAIL → 修正して再レビュー                    │
│   - reviewed: true まで作業開始禁止              │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ ✅ 作業開始可能                                  │
│   - Phase 1 を開始                               │
└─────────────────────────────────────────────────┘
```

---

## 禁止事項

```
❌ Step 0 をスキップして playbook 作成を始める
❌ 未コミット変更がある状態で新しいタスクを始める
❌ ブランチを作成せずに playbook を作成する
❌ playbook の branch: を手入力する（現在のブランチを自動取得）
❌ check-coherence.sh で ERROR があるまま作業を開始する
❌ Step 1.5 をスキップして Step 2 に進む（5W1H 分析必須）
❌ AskUserQuestion を使わずにテキストで承認を求める
❌ playbook に context セクションを含めない
❌ Step 6 をスキップして作業を開始する（reviewer 検証必須）
❌ reviewed: false のまま Phase 1 を開始する
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-24 | V4: Step 1.5（5W1H 理解確認）と Step 6（Reviewer 検証）を追加。playbook テンプレートに context セクションと reviewed フラグを追加。 |
| 2025-12-02 | V3: Step -1（再実行チェック）を追加。playbook 再作成時の挙動を明確化。 |
| 2025-12-02 | V2: 構造的強制を追加。Step 0（前提条件チェック）、自動実行ステップを明確化。 |
| 2025-12-01 | V1: 初版作成。 |
