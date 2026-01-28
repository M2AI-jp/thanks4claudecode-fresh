# crit Skill

> **報酬詐欺防止: Codex 経由の独立検証**
>
> critic SubAgent を Codex MCP 経由で呼び出し、自己評価を防止する

---

## Purpose

Claude (orchestrator) が自分自身で done 判定することを防ぐ。
Codex (別の LLM) に critic 評価を委譲することで、独立した第三者検証を実現。

---

## Invocation

```
/crit
```

または

```python
Skill(skill='crit')
```

---

## Behavior

1. 現在の playbook と phase を特定
2. done_when 条件を抽出
3. codex-delegate SubAgent を呼び出し
4. Codex が critic 評価を実行
5. 結果を progress.json に永続化

---

## Why Codex?

```yaml
問題: Claude が自分で critic を呼ぶ = 自己評価 = 報酬詐欺
解決: Codex (GPT-4o) に委譲 = 独立した第三者検証

構造:
  Claude (orchestrator)
    → /crit Skill
      → codex-delegate SubAgent
        → Codex MCP (GPT-4o)
          → critic 評価実行
            → 結果返却

利点:
  - Claude は評価に関与しない
  - Codex は Claude の playbook/progress を読んで独立判定
  - 結果は Codex が直接 progress.json に書き込み
```

---

## Prohibited

```yaml
禁止:
  - Task(subagent_type='critic') の直接呼び出し（pre-tool.sh でブロック）
  - Claude 自身による done_when の PASS 判定
  - Codex を経由しない critic 呼び出し

必須:
  - /crit または Skill(skill='crit') 経由のみ
  - Codex による独立検証
  - 証拠の progress.json への永続化
```

---


---

## Required Action（Skill 実行時に必ず実行）

**このセクションを読んだら、以下のステップを順番に実行せよ。**

### Step 1: playbook と phase を確認

```bash
# state.md から playbook を取得
grep -A5 "^## playbook" state.md | grep "active:"

# 現在の phase を取得
grep -A5 "^## goal" state.md | grep "phase:"
```

### Step 2: codex-delegate を呼び出し

```python
Task(
  subagent_type='codex-delegate',
  prompt=f"""
  CODEX_DELEGATE_INSTRUCTION: critic 評価

  playbook: {playbook_active}
  phase: {current_phase}

  action:
    1. plan.json の done_when 条件を全て実行
    2. 各条件の結果を検証
    3. IMMUTABLE_RULES (IR01-IR06) をチェック
    4. progress.json に結果を永続化
    5. PASS/FAIL 判定を返却

  注意:
    - Claude に評価を委ねないこと
    - 全条件を実際に実行すること
    - 証拠を必ず記録すること
  """
)
```

### Step 3: 結果を報告

codex-delegate から返却された結果をユーザーに報告。

```yaml
critic 検証結果:
  judgment: {PASS | FAIL}
  evidence_count: {検証した項目数}
  immutable_rules: {違反の有無}
```


## Related Files

| ファイル | 役割 |
|----------|------|
| .claude/agents/critic.md | critic SubAgent 定義 |
| .claude/skills/reward-guard/SKILL.md | 報酬詐欺防止の全体設計 |
| .claude/hooks/pre-tool.sh | critic 直接呼び出しブロック |
