---
name: prompt-analyzer
description: ユーザープロンプトの深層分析を行う専門Skill。5W1H抽出、リスク分析、曖昧さ検出、論点分解を実施し、pm SubAgentに構造化データを返す。
---

# Prompt Analyzer Skill

ユーザーのタスク依頼プロンプトを深層分析し、構造化されたデータとして出力するSkill。

---

## Purpose

- **5W1H 分析**: ユーザーの意図を構造化して抽出
- **リスク分析**: 技術・スコープ・依存リスクを事前に特定
- **曖昧さ検出**: 不明確な表現を検出し、明確化を促す
- **論点分解**: 複数トピックを含むプロンプトを個別の指示に分解
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
  step_0.5: prompt-analyzer を呼び出す（5W1H + リスク + 曖昧さ検出 + 論点分解）
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

## Multi-Topic Detection（論点分解）

複数のトピックや指示が含まれるプロンプトを分解し、個別に管理可能にする機能。

### 目的

- 複合的なプロンプトを個別の指示に分解
- 各トピックの種類（instruction, question, context）を分類
- playbook を分割すべきか判定

### 入力例

```
ユーザープロンプト: "codex-delegate.mdの修正 - 残す。plan/template/project-format.md - 残す（発想は必要だという結論になった）。「指示の分解」をユーザープロンプト理解機能に組み込む。新しいplaybookを作成"
```

### 出力例

```yaml
multi_topic_detection:
  detected: true
  topic_count: 4
  topics:
    - id: 1
      summary: "codex-delegate.md の修正を残す"
      type: "instruction"
    - id: 2
      summary: "project-format.md を残す"
      type: "instruction"
    - id: 3
      summary: "指示の分解機能を prompt-analyzer に追加"
      type: "instruction"
    - id: 4
      summary: "新しい playbook を作成"
      type: "instruction"
  decomposition_needed: true
```

### pm との連携

```yaml
pm_integration:
  when_multi_topic_detected:
    1: prompt-analyzer が multi_topic_detection を返す
    2: pm が topic_count を確認
    3: decomposition_needed が true の場合:
       - 各トピックを個別のタスクとして扱うか確認
       - 単一 playbook で対応するか複数に分割するか判断
    4: understanding-check で分解結果をユーザーに確認

  playbook_strategy:
    single_playbook:
      condition: トピック間に強い依存関係がある
      example: "機能追加 + その機能のテスト作成"
    multiple_playbooks:
      condition: トピックが独立している
      example: "ファイルA修正 + ファイルB修正（関連なし）"
```

### トピックタイプ

```yaml
topic_types:
  instruction: 実行すべきアクション（実装、修正、削除など）
  question: 回答が必要な質問
  context: 背景情報や制約条件
  decision: 決定事項の記録
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

  multi_topic_detection:
    detected: true|false
    topic_count: {数値}
    topics:
      - id: {番号}
        summary: "{要約}"
        type: "instruction|question|context|decision"
    decomposition_needed: true|false
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

  multi_topic_detection:
    detected: false
    topic_count: 1
    topics:
      - id: 1
        summary: "JWT を使用したログイン機能の実装"
        type: "instruction"
    decomposition_needed: false
```

---

## Related Files

| ファイル | 役割 |
|----------|------|
| .claude/skills/prompt-analyzer/agents/prompt-analyzer.md | SubAgent 定義 |
| .claude/skills/understanding-check/SKILL.md | 理解確認フレームワーク |
| .claude/skills/golden-path/agents/pm.md | pm SubAgent（呼び出し元） |
