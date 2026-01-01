---
name: prompt-analyzer
description: ユーザープロンプトの深層分析を行う専門Skill。5W1H抽出、リスク分析、曖昧さ検出を実施し、pm SubAgentに構造化データを返す。
---

# Prompt Analyzer Skill

ユーザーのタスク依頼プロンプトを深層分析し、構造化されたデータとして出力するSkill。

---

## Purpose

- **5W1H 分析**: ユーザーの意図を構造化して抽出
- **リスク分析**: 技術・スコープ・依存リスクを事前に特定
- **曖昧さ検出**: 不明確な表現を検出し、明確化を促す
- **pm SubAgent 支援**: playbook 作成前の情報収集を自動化

---

## When to Use

```yaml
triggers:
  - pm SubAgent から playbook 作成前に呼び出される
  - タスク依頼パターン（作って/実装して/修正して/追加して）を検出時
  - 複雑な要件でユーザーの意図が不明確な場合

invocation:
  # pm SubAgent からの呼び出し
  Task(
    subagent_type='prompt-analyzer',
    prompt='ユーザーの元プロンプト'
  )

  # または Skill として呼び出し
  Skill(skill='prompt-analyzer', input='ユーザーのプロンプト')
```

---

## Integration with pm.md

```yaml
pm_flow:
  step_0: ユーザープロンプトを受ける
  step_0.5: prompt-analyzer を呼び出す（5W1H + リスク + 曖昧さ検出）
  step_1: 分析結果を基に understanding-check を実施
  step_2: ユーザー承認を得る
  step_3: playbook を作成する

連携方法:
  1. pm が prompt-analyzer を呼び出す
  2. prompt-analyzer が構造化された分析結果を返す
  3. pm が分析結果を基にユーザーへの確認事項を整理
  4. understanding-check で最終確認
```

---

## Output Format

prompt-analyzer は以下の YAML 形式で出力する:

```yaml
analysis:
  5w1h:
    who: "{誰が}"
    what: "{何を}"
    when: "{いつ}"
    where: "{どこで}"
    why: "{なぜ}"
    how: "{どのように}"
    missing: ["{不足項目}"]
  
  risks:
    technical:
      - risk: "{リスク}"
        severity: high|medium|low
        mitigation: "{対策}"
    scope:
      - risk: "{リスク}"
        severity: high|medium|low
        mitigation: "{対策}"
    dependency:
      - risk: "{リスク}"
        severity: high|medium|low
        mitigation: "{対策}"
  
  ambiguity:
    - term: "{曖昧な表現}"
      clarification_needed: "{必要な明確化}"
```

---

## Example

### 入力プロンプト

```
ログイン機能を実装して。JWT を使って。
```

### 出力

```yaml
analysis:
  5w1h:
    who: "一般ユーザー（推定）"
    what: "ログイン機能の実装"
    when: "未指定"
    where: "未指定（API? フロントエンド?）"
    why: "未指定（認証が必要と推定）"
    how: "JWT を使用した認証"
    missing:
      - "when（期限）"
      - "where（実装場所）"
      - "why（目的）"
  
  risks:
    technical:
      - risk: "JWT の署名アルゴリズム選択"
        severity: medium
        mitigation: "RS256 または HS256 を選択、セキュリティ要件を確認"
      - risk: "トークンの有効期限管理"
        severity: medium
        mitigation: "リフレッシュトークン戦略を検討"
    scope:
      - risk: "ログアウト、パスワードリセット等の関連機能が不明"
        severity: high
        mitigation: "スコープを明確化、必要な機能を確認"
    dependency:
      - risk: "既存の認証システムとの統合"
        severity: medium
        mitigation: "現在の認証状況を調査"
  
  ambiguity:
    - term: "ログイン機能"
      clarification_needed: "メール/パスワード? ソーシャルログイン? 2FA?"
    - term: "実装場所"
      clarification_needed: "バックエンド API のみ? フロントエンドも含む?"
```

---

## Related Files

| ファイル | 役割 |
|----------|------|
| .claude/skills/prompt-analyzer/agents/prompt-analyzer.md | SubAgent 定義 |
| .claude/skills/understanding-check/SKILL.md | 理解確認フレームワーク |
| .claude/skills/golden-path/agents/pm.md | pm SubAgent（呼び出し元） |
