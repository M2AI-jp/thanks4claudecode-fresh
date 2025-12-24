---
description: 新しい playbook を作成するウィザード。pm SubAgent に委譲して playbook 作成を行う。
allowed-tools: Read, Bash, Task
---

# /init - 新しいタスク開始フロー

> **このフローは pm SubAgent に委譲される。直接 playbook を作成してはならない。**

---

## アーキテクチャ

```
Hook(prompt.sh) → Skill(playbook-init) → pm SubAgent → understanding-check
                                              ↓
                                         playbook 作成
                                              ↓
                                         reviewer 検証
```

---

## Step 0: 前提チェック（自動実行）

このステップは Skill 内で実行する。

### 0.1 再実行チェック

```bash
echo "=== 再実行チェック ===" && \
ls plan/playbook-*.md 2>/dev/null || echo "(playbook なし)" && \
grep -A1 "status: in_progress" plan/playbook-*.md 2>/dev/null | head -3 || echo "(in_progress なし)"
```

| 条件 | 対応 |
|------|------|
| playbook なし | → Step 0.2 へ |
| playbook あり & in_progress なし | → ユーザーに上書き確認 |
| playbook あり & in_progress あり | → **STOP** → タスク中断の確認 |

### 0.2 git 状態チェック

```bash
echo "=== git 状態チェック ===" && \
git status --short && \
git branch --show-current
```

| 条件 | 対応 |
|------|------|
| 未コミット変更がある | **STOP** → 先にコミット |
| main ブランチにいる | → Step 0.3 でブランチ作成 |

### 0.3 ブランチ作成

ユーザーの要求から自動推論してブランチを作成:

```bash
git checkout -b {feat|fix|refactor|docs}/{task-name}
```

---

## Step 1: pm SubAgent 呼び出し（必須）

> **ここから先は pm SubAgent に委譲する。自分で実行してはならない。**

### 呼び出し方法

```
Task:
  subagent_type: pm
  prompt: |
    ユーザーの要求: $ARGUMENTS
    ブランチ: {現在のブランチ名}

    以下を実行してください:
    1. understanding-check（5W1H 分析 + ユーザー承認）
    2. playbook 作成（context セクション含む）
    3. reviewer 検証（PASS まで）
    4. state.md 更新
```

### pm SubAgent の責務

pm SubAgent は以下を実行:

1. **理解確認（understanding-check）**
   - 5W1H 分析をテーブル形式で出力
   - リスク・不明点の洗い出し
   - AskUserQuestion でユーザー承認を取得

2. **playbook 作成**
   - context セクションに 5W1H を記録
   - branch フィールドに現在のブランチを設定
   - reviewed: false で作成

3. **reviewer 検証**
   - Task(subagent_type='reviewer') を呼び出し
   - PASS → reviewed: true に更新
   - FAIL → 修正して再レビュー

4. **state.md 更新**
   - playbook.active を設定
   - playbook.branch を設定

---

## 禁止事項

```yaml
禁止:
  - pm SubAgent を呼ばずに自分で playbook を作成
  - understanding-check をスキップ
  - reviewer 検証をスキップ
  - reviewed: false のまま作業開始

必須:
  - Step 0 の前提チェック
  - pm SubAgent への委譲
  - ユーザー承認の取得
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| .claude/skills/golden-path/agents/pm.md | pm SubAgent 定義 |
| .claude/skills/understanding-check/SKILL.md | 理解確認フレームワーク |
| .claude/skills/quality-assurance/agents/reviewer.md | reviewer SubAgent 定義 |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-24 | V5: pm SubAgent 委譲方式に全面改訂。理解確認と reviewer 検証を pm に委譲。 |
| 2025-12-24 | V4: Step 1.5（5W1H 理解確認）と Step 6（Reviewer 検証）を追加。 |
| 2025-12-02 | V3: Step -1（再実行チェック）を追加。 |
| 2025-12-02 | V2: 構造的強制を追加。 |
| 2025-12-01 | V1: 初版作成。 |
