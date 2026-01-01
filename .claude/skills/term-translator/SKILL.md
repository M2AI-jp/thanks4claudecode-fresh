---
name: term-translator
description: ユーザープロンプト内の曖昧な表現をエンジニア用語に変換する専門Skill。prompt-analyzer の ambiguity セクションを受け取り、技術的に明確な表現に変換する。
---

# Term Translator Skill

曖昧な表現を技術的に明確なエンジニア用語に変換し、実装可能な要件に落とし込む Skill。

---

## Purpose

- **用語変換**: 曖昧な日本語表現を具体的なエンジニア用語に変換
- **技術要件抽出**: 変換結果から実装可能な技術要件を導出
- **コードベース文脈**: 既存コードベースの規約・パターンを考慮した変換
- **pm SubAgent 支援**: playbook 作成時の要件明確化を自動化

---

## When to Use

```yaml
triggers:
  - prompt-analyzer が ambiguity を検出した後
  - pm SubAgent から playbook 作成前に呼び出される
  - 曖昧な要件を具体化する必要がある場合

invocation:
  # pm SubAgent からの呼び出し
  Task(
    subagent_type='term-translator',
    prompt='prompt-analyzer の ambiguity 出力'
  )

  # または Skill として呼び出し
  Skill(skill='term-translator', input='曖昧な表現リスト')
```

---

## Integration with prompt-analyzer and pm.md

```yaml
pm_flow:
  step_0: ユーザープロンプトを受ける
  step_0.5: prompt-analyzer を呼び出す（5W1H + リスク + 曖昧さ検出）
  step_0.6: term-translator を呼び出す（曖昧表現 → エンジニア用語）★
  step_1: 分析結果と変換結果を基に understanding-check を実施
  step_2: ユーザー承認を得る
  step_3: playbook を作成する

連携フロー:
  1. prompt-analyzer が ambiguity セクションを出力
  2. pm が term-translator を呼び出す
  3. term-translator が技術用語に変換
  4. pm が変換結果を基に done_criteria を具体化
  5. understanding-check でユーザーに確認
```

---

## Output Format

term-translator は以下の YAML 形式で出力する:

```yaml
translation:
  original_terms:
    - original: "{元の表現}"
      translated: "{変換後}"
      rationale: "{変換理由}"
      alternatives: ["{代替候補}"]
  
  technical_requirements:
    - requirement: "{技術要件}"
      derived_from: "{元の表現}"
      implementation_hint: "{実装ヒント}"
  
  codebase_context:
    relevant_files: ["{関連ファイル}"]
    existing_patterns: ["{既存パターン}"]
    conventions: ["{コーディング規約}"]
```

---

## Example

### 入力（prompt-analyzer の ambiguity 出力）

```yaml
ambiguity:
  - term: "高速に動作する"
    clarification_needed: "具体的なパフォーマンス要件"
  - term: "安全に処理する"
    clarification_needed: "セキュリティ要件の詳細"
  - term: "きれいなコード"
    clarification_needed: "コード品質の基準"
```

### 出力

```yaml
translation:
  original_terms:
    - original: "高速に動作する"
      translated: "レスポンスタイム 200ms 以下、O(n) 以下の計算量"
      rationale: "一般的な Web API のパフォーマンス基準を適用"
      alternatives:
        - "レスポンスタイム 100ms 以下（厳格）"
        - "レスポンスタイム 500ms 以下（緩和）"
    
    - original: "安全に処理する"
      translated: "入力バリデーション + サニタイズ + エラーハンドリング"
      rationale: "基本的なセキュリティ対策として必須の 3 要素"
      alternatives:
        - "追加: レート制限"
        - "追加: 監査ログ"
    
    - original: "きれいなコード"
      translated: "ESLint ルール準拠 + Prettier フォーマット + 関数 30 行以内"
      rationale: "プロジェクトの既存 lint 設定に準拠"
      alternatives:
        - "追加: 単体テストカバレッジ 80% 以上"
        - "追加: JSDoc コメント必須"
  
  technical_requirements:
    - requirement: "API レスポンスタイム計測の実装"
      derived_from: "高速に動作する"
      implementation_hint: "ミドルウェアで計測、閾値超過時にログ出力"
    
    - requirement: "入力バリデーションスキーマの定義"
      derived_from: "安全に処理する"
      implementation_hint: "zod または joi でスキーマ定義"
    
    - requirement: "ESLint 設定の適用確認"
      derived_from: "きれいなコード"
      implementation_hint: "pre-commit hook で自動チェック"
  
  codebase_context:
    relevant_files:
      - ".eslintrc.js"
      - ".prettierrc"
    existing_patterns:
      - "zod によるバリデーション"
      - "try-catch による統一的エラーハンドリング"
    conventions:
      - "関数名は camelCase"
      - "型定義は interface 優先"
```

---

## Related Files

| ファイル | 役割 |
|----------|------|
| .claude/skills/term-translator/agents/term-translator.md | SubAgent 定義 |
| .claude/skills/prompt-analyzer/SKILL.md | 前段の分析 Skill |
| .claude/skills/golden-path/agents/pm.md | pm SubAgent（呼び出し元） |
| plan/template/playbook-format.md | playbook テンプレート |
