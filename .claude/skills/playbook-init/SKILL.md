---
name: playbook-init
description: タスク開始フローのエントリーポイント。pm SubAgent への委譲を強制し、Hook → Skill → SubAgent チェーンを実現する。
---

# playbook-init Skill

> **このSkillは pm SubAgent への委譲を強制する。自分で処理してはならない。**

---

## Purpose

Hook → Skill → SubAgent チェーンの Skill 層を担当。
ユーザーからのタスク依頼を受け、pm SubAgent に委譲する。

---

## When to Use

```yaml
triggers:
  - prompt.sh（導火線）から呼び出される
  - playbook=null の状態でタスク依頼を受けた時
  - "作って/実装して/修正して/追加して" 等のタスク要求パターン

invocation:
  - Skill(skill='playbook-init')
  - /playbook-init
```

---

## Required Action

**即座に以下を実行せよ。それ以外の行動は禁止。**

### Step 0: 前提チェック（自分で実行）

```bash
echo "=== 前提チェック ===" && \
echo "1. 既存 playbook:" && ls plan/playbook-*.md 2>/dev/null | head -3 || echo "(なし)" && \
echo "2. git 状態:" && git status --short && \
echo "3. ブランチ:" && git branch --show-current
```

| 条件 | 対応 |
|------|------|
| 未コミット変更がある | ユーザーに確認 |
| main ブランチにいる | 作業ブランチを作成 |
| 既存 playbook あり | ユーザーに上書き確認 |

### Step 1: pm SubAgent に委譲（必須）

**★★★ 絶対禁止: ユーザープロンプトを解釈するな ★★★**

```yaml
禁止（報酬詐欺の原因）:
  - ユーザーの言葉を「要約」「言い換え」「解釈」して pm に渡す
  - 「つまり〇〇ということだ」と勝手に判断する
  - ユーザーが言っていないことを追加する
  - 「達成済み」「未達成」などを勝手に判定する

必須:
  - ユーザーのプロンプトをそのままコピペで渡す
  - 解釈は prompt-analyzer の仕事（pm が呼び出す）
  - 不明点があっても推測せず、そのまま渡す
```

**なぜ解釈が禁止か**:
```
入力が間違っていれば、後続の全てが無意味。
私（メイン Claude）が「達成済みPBをやり直せ」を
「未達成19件をやる」と解釈したら、
playbook 作成しても全て無駄。
これが報酬詐欺の根本原因。
```

**悪い例（禁止）**:
```python
# ユーザー: 「達成済みPBを特定して再度playbookからやり直して」
Task(
  subagent_type='pm',
  prompt='未達成 PB 19件を1つの playbook にまとめる'  # ← 誤解釈
)
```

**良い例（必須）**:
```python
# ユーザー: 「達成済みPBを特定して再度playbookからやり直して」
Task(
  subagent_type='pm',
  prompt='''
  ユーザーの要求（原文そのまま・解釈禁止）:
  「達成済みPBを特定して再度playbookからやり直して」

  ブランチ: fix/xxx
  '''
)
# → pm が prompt-analyzer を呼び出して正しく分析
```

```
Task(
  subagent_type='pm',
  prompt='''
  ユーザーの要求（原文そのまま・解釈禁止）:
  {args から受け取ったユーザープロンプトをそのままコピペ}

  ブランチ: {現在のブランチ名}

  以下を実行してください:
  1. prompt-analyzer でユーザー要求を分析（解釈はここで行う）
  2. understanding-check（5W1H 分析 + ユーザー承認）
  3. playbook 作成（context セクション含む）
  4. reviewer 検証（PASS まで）
  5. state.md 更新
  '''
)
```

---

## Prohibited

```yaml
禁止:
  - pm SubAgent を呼ばずに自分で playbook を作成
  - understanding-check をスキップ
  - reviewer 検証をスキップ
  - Step 0 の前提チェックをスキップ

必須:
  - pm SubAgent への委譲
  - ユーザー承認の取得（understanding-check 内で）
```

---

## Chain Position

```
Hook(prompt.sh)
    │
    │ playbook=null を検出
    │ 「Skill(skill='playbook-init') を呼べ」と指示
    │
    ▼
Skill(playbook-init)  ← このファイル
    │
    │ 前提チェック後、pm SubAgent に委譲
    │
    ▼
pm SubAgent
    │
    ├─→ understanding-check（5W1H 分析）
    ├─→ playbook 作成
    ├─→ reviewer 検証
    └─→ state.md 更新
```

---

## Related Files

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | Core Contract 定義（Golden Path） |
| .claude/hooks/prompt.sh | 導火線（State Injection） |
| .claude/skills/golden-path/agents/pm.md | pm SubAgent |
| .claude/skills/understanding-check/SKILL.md | 理解確認フレームワーク |
| .claude/skills/quality-assurance/agents/reviewer.md | reviewer SubAgent |
