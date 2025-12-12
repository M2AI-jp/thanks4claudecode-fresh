# playbook-playbook-project-lifecycle.md

> **playbook と project の生成・運用ルールの検証と強化**

---

## meta

```yaml
project: playbook & project lifecycle management
branch: feat/playbook-project-lifecycle
created: 2025-12-11
issue: null
derives_from: null
reviewed: false
```

---

## goal

```yaml
summary: playbook と project の生成・運用ルールを検証し、タスク必須フィールドルール・project 運用ルールの実装を確認する

done_when:
  - タスク必須フィールド（id, name, executor, done_criteria）のチェック機能が実装される
  - project.md 運用ルール（生成・更新・アーカイブ）が pm.md に定義される
  - pm による playbook/project 検証が reviewer で確認可能な形で文書化される
  - 実装は "feat/playbook-project-lifecycle" ブランチで完了
```

---

## phases

### Phase 1: タスク必須フィールドルールの検証

> **pm.md 4.6. に定義されたタスク必須フィールドルールが正しく実装されているか確認**

```yaml
id: p1
name: タスク必須フィールドルールの検証
goal: 既存 playbook が必須フィールド（id, name, executor, done_criteria）を正しく持っているか検証
status: done

tasks:
  - id: t1-1
    name: pm.md 4.6. のルールを確認
    subtasks:
      - step: "pm.md の 4.6. セクションの存在を確認"
        executor: claudecode
        criteria: "grep '4.6' .claude/agents/pm.md が結果を返す"
        status: "[x]"
      - step: "チェック項目の内容を確認"
        executor: claudecode
        criteria: "grep 'subtask' .claude/agents/pm.md が結果を返す"
        status: "[x]"

  - id: t1-2
    name: 既存 playbook の構造検証
    subtasks:
      - step: "plan/archive/ 内の playbook を列挙"
        executor: claudecode
        criteria: "ls plan/archive/playbook-*.md が 3 件以上"
        status: "[x]"
      - step: "検証結果を docs/playbook-structure-audit.md に記録"
        executor: claudecode
        criteria: "test -f docs/playbook-structure-audit.md"
        status: "[x]"

  - id: t1-3
    name: playbook-strict-done-criteria の実装内容を確認
    subtasks:
      - step: "playbook-strict-done-criteria の存在確認"
        executor: claudecode
        criteria: "ls plan/archive/playbook-strict-done-criteria-*.md が存在"
        status: "[x]"
      - step: "docs/done-criteria-guide.md の存在確認"
        executor: claudecode
        criteria: "test -f docs/done-criteria-guide.md"
        status: "[x]"

test_method: |
  1. pm.md 4.6. セクションを読んで要件を確認
  2. plan/archive/ のファイルを Glob で列挙
  3. 各 playbook の tasks セクションを Grep で検索し、id/name/executor/done_criteria の有無を確認
  4. playbook-strict-done-criteria-*.md と docs/done-criteria-guide.md を Read して内容を確認
  5. 検証結果を docs/playbook-structure-audit.md に記録
```

---

### Phase 2: project.md 運用ルールの実装確認

> **pm.md に定義された project.md 運用ルール（生成・更新・アーカイブ）が正しく記載されているか確認**

```yaml
id: p2
name: project.md 運用ルールの実装確認
goal: pm.md 5. に定義された project.md の運用ルール（テンポラリー管理、生成、更新、アーカイブ）が完全に記載されていることを確認
depends_on: [p1]
status: done

tasks:
  - id: t2-1
    name: pm.md 5. のルールを確認
    subtasks:
      - step: "pm.md の 5. セクションの存在確認"
        executor: claudecode
        criteria: "grep 'project.md 管理' .claude/agents/pm.md が結果を返す"
        status: "[x]"
      - step: "生成・更新・アーカイブルールの確認"
        executor: claudecode
        criteria: "grep -E '(生成|更新|アーカイブ)' .claude/agents/pm.md が 3 件以上"
        status: "[x]"

  - id: t2-2
    name: project-format.md の生成ガイドを確認
    subtasks:
      - step: "project-format.md の存在確認"
        executor: claudecode
        criteria: "test -f plan/template/project-format.md"
        status: "[x]"
      - step: "必須セクションの確認"
        executor: claudecode
        criteria: "grep -E '(meta|vision|tech_decisions|stack)' plan/template/project-format.md が結果を返す"
        status: "[x]"

  - id: t2-3
    name: playbook-format.md の導出ガイドを確認
    subtasks:
      - step: "playbook 導出ガイドセクションの確認"
        executor: claudecode
        criteria: "grep 'playbook 導出ガイド' plan/template/playbook-format.md が結果を返す"
        status: "[x]"
      - step: "変換ルールの確認"
        executor: claudecode
        criteria: "grep 'derives_from' plan/template/playbook-format.md が結果を返す"
        status: "[x]"

  - id: t2-4
    name: pm.md の project.md 管理責務を確認
    subtasks:
      - step: "CRUD 操作の管理責務確認"
        executor: claudecode
        criteria: "grep '責務' .claude/agents/pm.md | grep -i project が結果を返す"
        status: "[x]"
      - step: "計画の導出フローの確認"
        executor: claudecode
        criteria: "grep '計画の導出' .claude/agents/pm.md が結果を返す"
        status: "[x]"

test_method: |
  1. pm.md の 5. セクションを Read して要件を確認
  2. plan/template/project-format.md の各セクションを Read して completeness を確認
  3. playbook-format.md の「playbook 導出ガイド」セクションを Read して手順を確認
  4. pm.md の「計画の導出フロー」セクションを Read して flow を確認
  5. 検証結果を記録（どの項目が実装済みか、欠落部分は何か）
```

---

### Phase 3: reviewer による playbook 検証フローの確認

> **reviewer SubAgent が playbook をどのように検証するかを確認し、検証基準が明確に定義されているか確認**

```yaml
id: p3
name: reviewer による playbook 検証フローの確認
goal: reviewer.md で定義されている playbook レビュー基準と検証フローが、pm.md のタスク必須フィールドルールと project.md 運用ルールに対応しているかを確認
depends_on: [p2]
status: done

tasks:
  - id: t3-1
    name: reviewer.md の検証基準を確認
    subtasks:
      - step: "reviewer.md の存在確認"
        executor: claudecode
        criteria: "test -f .claude/agents/reviewer.md"
        status: "[x]"
      - step: "subtask 構造検証の記載確認"
        executor: claudecode
        criteria: "grep 'subtask' .claude/agents/reviewer.md が結果を返す"
        status: "[x]"

  - id: t3-2
    name: playbook-review-criteria.md を確認
    subtasks:
      - step: "ファイルの存在確認"
        executor: claudecode
        criteria: "test -f .claude/rules/frameworks/playbook-review-criteria.md"
        status: "[x]"
      - step: "検証フローの確認"
        executor: claudecode
        criteria: "grep -E '(形式検証|シミュレーション|批判的検討)' .claude/rules/frameworks/playbook-review-criteria.md が結果を返す"
        status: "[x]"

  - id: t3-3
    name: critic.md の done_criteria 評価フローを確認
    subtasks:
      - step: "critic.md の存在確認"
        executor: claudecode
        criteria: "test -f .claude/agents/critic.md"
        status: "[x]"
      - step: "評価観点の記載確認"
        executor: claudecode
        criteria: "grep -E '(根拠|検証可能性|報酬詐欺)' .claude/agents/critic.md が結果を返す"
        status: "[x]"

  - id: t3-4
    name: pm.md と reviewer.md/critic.md の一貫性を確認
    subtasks:
      - step: "pm.md での reviewer 呼び出し確認"
        executor: claudecode
        criteria: "grep 'reviewer' .claude/agents/pm.md が結果を返す"
        status: "[x]"
      - step: "役割分担の一貫性確認"
        executor: claudecode
        criteria: "grep -l 'playbook' .claude/agents/{pm,reviewer,critic}.md が 3 件"
        status: "[x]"

test_method: |
  1. .claude/agents/reviewer.md を Read して検証基準を確認
  2. .claude/agents/critic.md を Read して評価フロー確認
  3. .claude/rules/frameworks/playbook-review-criteria.md を Read して基準を確認
  4. pm.md, reviewer.md, critic.md の整合性を Grep で "reviewer", "critic" を検索して確認
  5. 検証結果を docs/reviewer-critic-architecture.md に記録
```

---

### Phase 4: 実装ドキュメントの作成

> **検証結果をドキュメントにまとめ、今後の改善提案を記載**

```yaml
id: p4
name: 実装ドキュメントの作成
goal: 検証結果を体系的にドキュメント化し、今後の改善提案と実装ロードマップを明記
depends_on: [p3]
status: done

tasks:
  - id: t4-1
    name: 監査結果ドキュメント（playbook-structure-audit.md）を作成
    subtasks:
      - step: "docs/playbook-structure-audit.md を作成"
        executor: claudecode
        criteria: "test -f docs/playbook-structure-audit.md"
        status: "[x]"
      - step: "タスク必須フィールドルールの概要を記載"
        executor: claudecode
        criteria: "grep 'タスク必須フィールド' docs/playbook-structure-audit.md が結果を返す"
        status: "[x]"

  - id: t4-2
    name: subtask 構造への移行
    subtasks:
      - step: "playbook-format.md を subtask 構造に修正"
        executor: claudecode
        criteria: "grep 'subtasks' plan/template/playbook-format.md が結果を返す"
        status: "[x]"
      - step: "pm.md 4.6. を subtask 構造に修正"
        executor: claudecode
        criteria: "grep 'subtask 構造チェック' .claude/agents/pm.md が結果を返す"
        status: "[x]"
      - step: "reviewer.md を subtask 構造に修正"
        executor: claudecode
        criteria: "grep 'subtask 構造チェック' .claude/agents/reviewer.md が結果を返す"
        status: "[x]"
      - step: "CLAUDE.md を subtask 構造に修正"
        executor: claudecode
        criteria: "grep 'subtask 構造' CLAUDE.md が結果を返す"
        status: "[x]"
      - step: "playbook を subtask 構造に修正"
        executor: claudecode
        criteria: "grep 'subtasks:' plan/active/playbook-playbook-project-lifecycle.md が結果を返す"
        status: "[x]"

test_method: |
  1. Phase 1-3 の検証結果から、主要な発見事項をまとめる
  2. 各ドキュメント（audit, lifecycle-rules, architecture）を作成
  3. 作成したドキュメントを自己検証：
     - 論理的整合性（contradictions がないか）
     - 完全性（全てのユースケースを網羅しているか）
     - 実装可能性（他者が手順に従えるか）
  4. docs/CLAUDE.md に新規ドキュメントへの参照を追加
```

---

### Phase 5: 実装（project.md 運用ルール、タスク必須フィールドルール）

> **pm.md, reviewer.md, critic.md に運用ルールが完全に実装されているか、不足部分があれば追加実装**

```yaml
id: p5
name: 運用ルール実装の検証と補完
goal: pm.md に project.md 運用ルール、タスク必須フィールドルール、検証責務が完全に実装されていることを確認
depends_on: [p4]
status: done

tasks:
  - id: t5-0
    name: 実装対象ファイルの先行確認
    subtasks:
      - step: "pm.md の存在確認"
        executor: claudecode
        criteria: "test -f .claude/agents/pm.md"
        status: "[x]"
      - step: "reviewer.md の存在確認"
        executor: claudecode
        criteria: "test -f .claude/agents/reviewer.md"
        status: "[x]"
      - step: "critic.md の存在確認"
        executor: claudecode
        criteria: "test -f .claude/agents/critic.md"
        status: "[x]"

  - id: t5-1
    name: pm.md の completeness を確認
    subtasks:
      - step: "計画の導出フローの確認"
        executor: claudecode
        criteria: "grep '計画の導出フロー' .claude/agents/pm.md が結果を返す"
        status: "[x]"
      - step: "4.5. done_criteria 検証可能性チェックの確認"
        executor: claudecode
        criteria: "grep '4.5' .claude/agents/pm.md が結果を返す"
        status: "[x]"
      - step: "4.6. subtask 構造チェックの確認"
        executor: claudecode
        criteria: "grep 'subtask 構造チェック' .claude/agents/pm.md が結果を返す"
        status: "[x]"

  - id: t5-2
    name: pm.md に project.md 管理責務を追加
    subtasks:
      - step: "5. project.md 管理セクションの確認"
        executor: claudecode
        criteria: "grep 'project.md 管理' .claude/agents/pm.md が結果を返す"
        status: "[x]"
      - step: "生成・更新・アーカイブルールの確認"
        executor: claudecode
        criteria: "grep -E '(生成:|更新:|アーカイブ)' .claude/agents/pm.md が 3 件以上"
        status: "[x]"

  - id: t5-3
    name: reviewer.md が playbook 構造検証を実施
    subtasks:
      - step: "subtask 構造検証セクションの確認"
        executor: claudecode
        criteria: "grep 'subtask 構造チェック' .claude/agents/reviewer.md が結果を返す"
        status: "[x]"

test_method: |
  1. pm.md を Read して 5. project.md 管理セクションを確認
  2. reviewer.md を Read して構造検証セクションを確認
  3. 不足部分をリストアップ
  4. Edit で実装
  5. check-coherence.sh を実行して整合性を確認
```

---

### Phase 6: reviewer によるブランチレビュー

> **ここまでの実装を reviewer SubAgent が検証**

```yaml
id: p6
name: reviewer による最終検証
goal: 実装したルール、ドキュメント、コード変更が reviewer.md の基準を満たしていることを確認
depends_on: [p5]
status: done

tasks:
  - id: t6-1
    name: reviewer を呼び出してブランチをレビュー
    subtasks:
      - step: "Task(subagent_type='reviewer') を実行"
        executor: claudecode
        criteria: "reviewer SubAgent の実行結果が返される"
        status: "[x]"
      - step: "reviewer の判定結果を確認"
        executor: claudecode
        criteria: "PASS または FAIL の判定が得られる"
        status: "[x]"
      - step: "FAIL の場合は修正してリトライ（最大 3 回）"
        executor: claudecode
        criteria: "最終的に PASS が得られる、または 3 回リトライ後ユーザー判断"
        status: "[x]"

test_method: |
  1. Task(subagent_type="reviewer", prompt="{executor_config.prompt}") を実行
  2. reviewer の判定を待つ
  3. PASS → Phase 7 へ
  4. FAIL → 重大度に応じてリトライ:
     - Critical: Phase 5 に戻る
     - Major: Edit で修正 → t6-1 再実行
     - Minor: 記録して Phase 7 へ
```

---

### Phase 7: 最終統合と実行可能性検証

> **実装した運用ルールが実際に機能するか、簡単な scenario テストで検証**

```yaml
id: p7
name: 運用ルール実行可能性検証
goal: 実装したルール（自動導出、タスク検証、project 運用）が実際に機能することを確認
depends_on: [p6]
status: done

tasks:
  - id: t7-1
    name: playbook 導出フローのシミュレーション
    subtasks:
      - step: "project.md から playbook 導出をシミュレート"
        executor: claudecode
        criteria: "derives_from が設定された playbook 構造が得られる"
        status: "[x]"

  - id: t7-2
    name: subtask 構造チェックのシミュレーション
    subtasks:
      - step: "意図的に違反構造を作成してチェック"
        executor: claudecode
        criteria: "subtasks なし、executor なしの違反を検出できる"
        status: "[x]"

  - id: t7-3
    name: state.md と playbook の整合性確認
    subtasks:
      - step: "active_playbooks と実際の playbook の一致確認"
        executor: claudecode
        criteria: "state.md の playbook パスにファイルが存在する"
        status: "[x]"
      - step: "focus の設定確認"
        executor: claudecode
        criteria: "state.md の focus.current が product"
        status: "[x]"

  - id: t7-4
    name: テストファイルのクリーンアップ
    subtasks:
      - step: "一時ファイルの削除"
        executor: claudecode
        criteria: "git status に untracked の一時ファイルがない"
        status: "[x]"

test_method: |
  1. Phase 1-3 の検証結果を参考に、仮の project.md を作成
  2. playbook 導出フローに従って playbook を生成
  3. 生成されたファイルを検査（format, field, integrity）
  4. 意図的な違反パターンをテストして検出可能性を確認
  5. 全体的な整合性を確認
  6. テストファイルを削除してクリーンアップ
```

---

### Phase 8: 最終統合と状態管理

> **全ての変更を git にコミット、state.md を更新、ブランチを整理**

```yaml
id: p8
name: 最終統合と状態管理
goal: 全ての変更を git にコミット、state.md を更新、ブランチを整理
depends_on: [p7]
status: done

tasks:
  - id: t8-1
    name: 変更内容の整理
    subtasks:
      - step: "git status で変更を確認"
        executor: claudecode
        criteria: "git status が変更ファイルを表示"
        status: "[x]"
      - step: "不要な一時ファイルを削除"
        executor: claudecode
        criteria: "git status -s に一時ファイルがない"
        status: "[x]"

  - id: t8-2
    name: git commit and push
    subtasks:
      - step: "git add で全変更をステージング"
        executor: claudecode
        criteria: "git add -A が成功"
        status: "[x]"
      - step: "git commit を実行"
        executor: claudecode
        criteria: "git commit が成功（exit code 0）"
        status: "[x]"
      - step: "git push を実行"
        executor: claudecode
        criteria: "git push origin feat/playbook-project-lifecycle が成功"
        status: "[ ]"

  - id: t8-3
    name: state.md の更新と playbook アーカイブ
    subtasks:
      - step: "playbook を plan/archive/ に移動"
        executor: claudecode
        criteria: "mv で playbook が plan/archive/ に移動"
        status: "[ ]"
      - step: "state.md の active_playbooks を null に更新"
        executor: claudecode
        criteria: "grep 'product: null' state.md が結果を返す"
        status: "[ ]"
      - step: "completion セクションに完了記録を追加"
        executor: claudecode
        criteria: "grep 'playbook-playbook-project-lifecycle' state.md が結果を返す"
        status: "[ ]"

test_method: |
  1. git status で変更状況を確認
  2. git add && git commit && git push を実行
  3. state.md を更新
  4. playbook を plan/archive/ に移動
```

---

## test_method（全 Phase 検証）

```yaml
全体検証フロー:
  1. Phase 1-3: 既存実装の検証（監査）
  2. Phase 4: 検証結果のドキュメント化
  3. Phase 5: 不足部分の実装補完
  4. Phase 6: reviewer による最終検証
  5. Phase 7: 運用ルール実行可能性確認
  6. Phase 8: 最終統合と状態管理

最終確認:
  - git status で全ての変更が追跡されていること
  - check-coherence.sh が PASS すること
  - state.md が現在の状態を正しく反映していること
  - playbook が plan/archive/ にアーカイブされていること
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-12 | reviewer 指摘に基づき修正。Phase 4 に t4-5、Phase 5 に t5-0、Phase 6 prompt 具体化、Phase 7 に t7-4、Phase 8 新規追加。 |
| 2025-12-11 | 初版作成。playbook & project lifecycle management。 |
