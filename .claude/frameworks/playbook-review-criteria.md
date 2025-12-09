# Playbook Review Criteria

> **reviewer SubAgent が playbook をレビューする際の評価基準**
>
> 使用方法: `Task(subagent_type='reviewer', prompt='playbook をレビュー。.claude/frameworks/playbook-review-criteria.md を参照')`

## 目的

**「作成者 ≠ 検証者」の原則を実現**

- pm が計画を作成（作成者）
- reviewer が計画を検証（検証者）
- セルフチェックでは見落とす問題を構造的に発見

---

## 検証フロー（3段階）

```yaml
1. 形式検証（Structural Validation）:
   - playbook が必須フィールドを持っているか
   - フォーマットが正しいか
   → 自動チェック可能な項目

2. シミュレーション（Mental Execution）:
   - 計画を最初から最後まで頭の中で実行
   - 各 Phase で「何が起きるか」を具体的に想像
   - 「このステップの後、次のステップは本当に可能か？」

3. 批判的検討（Adversarial Thinking）:
   - 「この計画が失敗するとしたらどこか？」
   - 「見落としている前提条件は何か？」
   - 「より良いアプローチはないか？」
```

---

## 普遍的レビュー基準（Universal Criteria）

> **タスクの種類（コーディング / ドキュメント / 設計 / 運用）に関係なく適用される基準**

### 1. 入力の明確性（Input Clarity）

```yaml
question: "このタスクを開始するために必要な情報・前提は全て明記されているか？"

checklist:
  - [ ] 前提条件が明示されている
  - [ ] 依存する成果物・ファイルが特定されている
  - [ ] 開始時点で揃っているべきものが列挙されている
  - [ ] 不明点がない（または「不明点リスト」として明記）

fail_examples:
  - "〇〇を参照して" → どのファイルの何を参照するか不明
  - "適切に" → 何が適切かの基準がない
  - "必要に応じて" → 必要かどうかの判断基準がない
```

### 2. 出力の検証可能性（Output Verifiability）

```yaml
question: "done_criteria を満たしたかどうか、第三者が客観的に判断できるか？"

checklist:
  - [ ] 各 done_criteria に対して「検証方法」が存在する
  - [ ] 検証結果が YES/NO で判定可能
  - [ ] 主観的判断を必要としない
  - [ ] 検証に必要な情報がアクセス可能

fail_examples:
  - "〇〇が改善されている" → 何をもって改善とするか不明
  - "適切に実装されている" → 適切の基準がない
  - "問題がない" → 何を問題とするかの定義がない

pass_examples:
  - "wc -l で 200 行以下" → コマンドで検証可能
  - "ESLint が 0 エラー" → ツールで検証可能
  - "〇〇関数が△△を返す" → テストで検証可能
  - "ファイル X にセクション Y が存在する" → 目視で検証可能
```

### 3. ステップの論理的連鎖（Logical Chain）

```yaml
question: "Phase N の成果物なしで Phase N+1 を開始できてしまわないか？"

checklist:
  - [ ] 各 Phase の入力が前の Phase の出力と一致
  - [ ] 並行して実行可能な Phase は明示されている
  - [ ] 循環依存がない
  - [ ] スキップ可能な Phase はない（全て必要）

fail_examples:
  - Phase 1 で「設計」、Phase 2 で「実装」、Phase 3 で「設計変更」→ 順序が不適切
  - Phase 1 と Phase 2 に依存関係がないのに直列実行 → 並行可能と明記すべき
```

### 4. 完全性（Completeness）

```yaml
question: "ゴール達成に必要な全てのステップが含まれているか？"

checklist:
  - [ ] クリーンアップ（不要ファイルの削除）が含まれている
  - [ ] 検証ステップ（テスト、レビュー）が含まれている
  - [ ] ドキュメント更新が必要な場合、それが含まれている
  - [ ] 他システムへの影響確認が含まれている

common_omissions:
  - ファイル作成後の「既存ドキュメントへの反映」
  - 設定変更後の「影響範囲の確認」
  - 新機能追加後の「既存機能との整合性確認」
  - 中間成果物の「削除またはアーカイブ」
```

### 5. スコープの明確性（Scope Clarity）

```yaml
question: "何をやり、何をやらないかが明確か？"

checklist:
  - [ ] スコープ内の作業が列挙されている
  - [ ] スコープ外の作業が明示されている（exclusions）
  - [ ] 「ついでに」「ながら」の誘惑を排除する記述がある
  - [ ] 変更対象ファイルが具体的に列挙されている

fail_examples:
  - "関連ファイルを更新" → どのファイルか不明
  - "必要な修正を行う" → 何が必要かの判断基準がない
```

### 6. リスクと対策（Risk Mitigation）

```yaml
question: "この計画が失敗するとしたら、どこで失敗するか？"

checklist:
  - [ ] 高リスクポイントが特定されている
  - [ ] 各リスクに対する対策または回避策がある
  - [ ] ロールバック方法が明記されている
  - [ ] 「想定外」の事態への対応方針がある

risk_categories:
  - 技術的リスク: 動かない、互換性がない
  - 範囲リスク: スコープクリープ、要件追加
  - 依存リスク: 外部システム、他タスクへの依存
  - 知識リスク: 前提知識の不足、誤解
```

---

## タスク種別ごとの追加基準

### コーディングタスク

```yaml
additional_checks:
  - [ ] テスト戦略が含まれている（TDD / 後付け / 手動）
  - [ ] 静的解析（ESLint, TypeScript）への対応が含まれている
  - [ ] 既存コードへの影響が分析されている
  - [ ] エラーハンドリングの方針が明記されている
```

### ドキュメントタスク

```yaml
additional_checks:
  - [ ] 対象読者が明確
  - [ ] 既存ドキュメントとの整合性確認が含まれている
  - [ ] フォーマット/スタイルガイドへの準拠が明記
  - [ ] 図表の必要性が検討されている
```

### 設計タスク

```yaml
additional_checks:
  - [ ] 代替案の検討が含まれている
  - [ ] 選定理由が明記されている
  - [ ] 将来の拡張性が考慮されている
  - [ ] 制約条件が明示されている
```

### 運用/インフラタスク

```yaml
additional_checks:
  - [ ] ロールバック手順が明記されている
  - [ ] 影響範囲（ダウンタイム等）が明記されている
  - [ ] 監視/アラートの設定が含まれている
  - [ ] 本番環境への適用手順が明記されている
```

---

## シミュレーション実行プロトコル

```yaml
手順:
  1. playbook の Phase 0 から開始
  2. 各 Phase について以下を実行:
     a. 「この Phase を開始するとき、何が揃っているか？」を確認
     b. 「この Phase で何をするか」を具体的に想像
     c. 「この Phase が終わったとき、何ができているか？」を確認
     d. 次の Phase の入力として十分か判定
  3. 最終 Phase まで完了したら、goal.done_when を確認
  4. 「このまま実行して、本当に done_when は達成されるか？」を判定

シミュレーション中の質問:
  - "ここで詰まったらどうする？"
  - "この前提が間違っていたらどうなる？"
  - "想定より時間がかかったら？"
  - "途中で要件が変わったら？"
```

---

## 批判的検討プロトコル

```yaml
悪魔の代弁者（Devil's Advocate）:
  - "この計画の最大の弱点は何か？"
  - "1年後の自分がこの計画を見たら何と言うか？"
  - "なぜこの方法でなければならないのか？"
  - "もっとシンプルな方法はないか？"

レッドチーム思考:
  - "この計画を失敗させるには何をすればいいか？"
  - "意図的に品質を下げるならどこを手抜きするか？"
  - "done と偽装するなら何を隠すか？"
  → これらが可能なら、計画に穴がある

見落としチェック:
  - "やるべきことリスト"を作成後、"やらないことリスト"を作成
  - "やらないこと"に本来やるべきことが含まれていないか確認
```

---

## 出力フォーマット

```yaml
plan_review:
  target: "{playbook_path}"
  timestamp: "{ISO8601}"
  task_type: "coding | documentation | design | operations | mixed"

  structural_validation:
    required_fields: PASS | FAIL
    format_compliance: PASS | FAIL

  universal_criteria:
    input_clarity: PASS | FAIL
    output_verifiability: PASS | FAIL
    logical_chain: PASS | FAIL
    completeness: PASS | FAIL
    scope_clarity: PASS | FAIL
    risk_mitigation: PASS | FAIL

  task_specific_criteria:
    # タスク種別に応じた追加基準の結果

  simulation_result:
    executed: true
    bottlenecks: ["Phase X で Y が不明", ...]
    assumptions: ["Z が前提", ...]

  adversarial_analysis:
    weakest_point: "..."
    failure_scenarios: ["...", ...]
    gaming_opportunities: ["...", ...]  # 不正の余地

  judgment: PASS | FAIL

  # FAIL の場合
  issues:
    - category: "{基準名}"
      severity: "critical | major | minor"
      description: "問題の詳細"
      evidence: "根拠となる引用"
      suggestion: "修正案"

  # 常に出力
  recommendations:
    - "推奨事項（PASS でも改善の余地がある場合）"
```

---

## 判定基準

```yaml
PASS 条件（全て満たす必要あり）:
  - structural_validation: 全て PASS
  - universal_criteria: 全て PASS
  - task_specific_criteria: 全て PASS
  - simulation_result: 重大なボトルネックなし
  - adversarial_analysis: 致命的な弱点なし

FAIL 条件（1つでも該当すれば FAIL）:
  - universal_criteria のいずれかが FAIL
  - done_criteria が検証不可能
  - 必要なステップの欠落
  - 重大なリスクに対する対策なし
  - スコープが曖昧

severity による判定:
  - critical: 1つでもあれば即 FAIL
  - major: 2つ以上で FAIL
  - minor: 3つ以上で FAIL（ただし推奨事項として記録）
```

---

## アンチゲーミング措置

```yaml
自己満足の防止:
  - "PASS を出すための計画修正" ではなく "良い計画にするための修正"
  - 形式的にチェックを通すだけの修正は禁止
  - "なぜこの計画が良いのか" を説明できない場合は FAIL

甘い判定の防止:
  - 「たぶん大丈夫」→ FAIL（確証がなければ不合格）
  - 「後で調整すればいい」→ FAIL（計画段階で詰める）
  - 「細かいことは実行時に」→ FAIL（細部も計画に含める）

レビュー品質の自己監視:
  - レビュー所要時間が 1 分未満 → 形式的すぎる可能性
  - 全項目 PASS で issues なし → 見落としの可能性を疑う
  - recommendations が 0 件 → 改善の余地を探していない
```

---

## reviewer SubAgent との連携

```yaml
呼び出しタイミング:
  - pm が playbook を作成した直後
  - playbook-guard.sh が reviewed: false を検出したとき（警告表示）

連携フロー:
  1. pm: playbook 作成（reviewed: false）
  2. Claude: reviewer を呼び出し
     Task(subagent_type='reviewer', prompt='playbook をレビュー。.claude/frameworks/playbook-review-criteria.md を参照')
  3. reviewer: 検証実行（3段階）
  4. PASS の場合:
     - playbook の reviewed: true に更新
     - Claude: LOOP 開始
  5. FAIL の場合:
     - reviewer: 問題点と修正案を提示
     - pm: playbook を修正
     - reviewer を再呼び出し（ループ）

構造的強制:
  - playbook-guard.sh が reviewed: false を検出すると警告を出力
  - reviewed: true になるまで警告が表示され続ける
```

---

## 参照ファイル

- plan/project.md - Macro 計画
- plan/playbook-*.md - 検証対象
- plan/template/playbook-format.md - フォーマット仕様
- .claude/frameworks/done-criteria-validation.md - done_criteria 評価基準
