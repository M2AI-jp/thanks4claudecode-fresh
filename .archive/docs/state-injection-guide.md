# State Injection Guide

> **UserPromptSubmit Hook による systemMessage 自動注入の仕組み**

---

## 概要

State Injection は、ユーザーがプロンプトを送信するたびに `state.md` / `project.md` / `playbook` から必要な情報を抽出し、`systemMessage` として LLM に注入する仕組みです。

**目的:**
- LLM が `Read` ツールを使わなくても現在の状態を把握できる
- `/clear` 後でも最初のプロンプトから正しい情報が届く
- CLAUDE.md の `[自認]` と同等の情報を構造的に強制する

---

## 注入フロー

```
User Prompt
    ↓
UserPromptSubmit Hook (prompt-guard.sh)
    ↓
┌─────────────────────────────────────┐
│ 1. state.md から情報抽出            │
│    - focus, milestone, phase        │
│    - playbook, branch               │
│    - done_criteria                  │
├─────────────────────────────────────┤
│ 2. project.md から情報抽出          │
│    - project_summary (vision.goal)  │
│    - remaining milestones           │
├─────────────────────────────────────┤
│ 3. playbook から情報抽出            │
│    - remaining phases               │
├─────────────────────────────────────┤
│ 4. git から情報抽出                 │
│    - branch, status                 │
├─────────────────────────────────────┤
│ 5. logs から情報抽出                │
│    - last_critic (PASS/FAIL/null)   │
└─────────────────────────────────────┘
    ↓
systemMessage を JSON で出力
    ↓
LLM が受信（Read 不要）
```

---

## 注入する情報（9 フィールド）

| フィールド | 取得元 | 説明 |
|-----------|--------|------|
| `focus` | state.md | 現在のプロジェクト名 |
| `milestone` | state.md | 現在の milestone ID |
| `phase` | state.md | 現在の phase ID |
| `playbook` | state.md | アクティブな playbook パス |
| `branch` | git | 現在のブランチ名 |
| `git` | git status | clean / N modified |
| `remaining` | playbook + project | 残り phase 数 / milestone 数 |
| `project_summary` | project.md | vision.goal の内容 |
| `last_critic` | .claude/logs/ | 最新の critic 結果 |

---

## 出力フォーマット

```
━━━ State Injection ━━━
focus: thanks4claudecode
milestone: M005
phase: p2
playbook: plan/active/playbook-state-injection.md
branch: feat/state-injection
git: clean
remaining: 2 phases / 0 milestones
project_summary: Claude Code の自律性と品質を継続的に向上させる
last_critic: PASS
━━━━━━━━━━━━━━━━━━━━━━━━
done_criteria:
• "criteria 1"
• "criteria 2"
• ...
```

---

## 警告メッセージ

状況に応じて警告が追加されます:

| パターン | 警告 |
|----------|------|
| playbook=null で作業要求 | `🚨 playbook がありません。Edit/Write 時にブロックされます。` |
| スコープ拡張検出 | `⚠️ スコープ拡張を検出。現在の phase に集中してください。` |
| 報酬詐欺パターン | `⚠️ 報酬詐欺パターン検出: critic PASS なしで done にしないこと。` |

---

## 実装ファイル

- **本体**: `.claude/hooks/prompt-guard.sh`
- **設定**: `.claude/settings.json` の `hooks.UserPromptSubmit`

---

## CLAUDE.md [自認] との対応

| [自認] フィールド | systemMessage フィールド |
|------------------|-------------------------|
| what | focus |
| milestone | milestone |
| phase | phase |
| branch | branch |
| project_summary | project_summary |
| remaining | remaining |
| playbook | playbook |
| done_criteria | done_criteria |
| git_status | git |
| last_critic | last_critic |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | M005 実装完了。project_summary, last_critic 追加。 |
