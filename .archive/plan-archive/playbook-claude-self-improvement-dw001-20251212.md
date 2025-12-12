# playbook-claude-self-improvement-dw001.md

> **Claude 自己分析と問題パターンの明文化**
>
> DW-001: 自己分析と問題パターンの明文化
>
> Claude 自身の機能、思考パターン、失敗パターンを明文化し、根本原因分析を行うための playbook。

---

## meta

```yaml
project: claude-self-improvement
derives_from: DW-001
branch: feat/improvement-cycle-10
created: 2025-12-12
issue: null
reviewed: false
type: self-analysis
```

---

## goal

```yaml
summary: Claude 自身の行動パターン、思考パターン、失敗パターンを明文化し、根本原因を特定する

done_when:
  - CLAUDE.md のルールが MECE に列挙されている（10 項目以上）
  - Hooks の発火条件が全て列挙されている（8+ 個）
  - SubAgents の呼び出し条件が全て列挙されている（6+ 個）
  - 機能連携図が存在する（ドキュメントに記録）
  - 「あるべき動作」が各機能について記述されている
  - 「実際の動作」が各機能について記述されている
  - 差分（機能不全）が 3 項目以上特定されている
  - 各機能不全の根本原因が 5 Whys で分析されている
```

---

## phases

### Phase 1: 自己機能の棚卸し（Data Collection）

```yaml
id: p1
name: 自己機能の棚卸し
goal: CLAUDE.md、Hooks、SubAgents の全機能をリストアップし、MECE に構造化する
priority: high
max_iterations: 3
tools:
  subagents: [critic]
  skills: []

tasks:
  - id: t1-1
    name: CLAUDE.md のルール抽出
    subtasks:
      - step: "CLAUDE.md を読み、全ルール（制御構文、ルール、原則）を MECE に列挙"
        executor: claudecode
        criteria: "docs/self-analysis-phase1.md に以下が列挙されている: （1）INIT、（2）CORE、（3）LOOP、（4）POST_LOOP、（5）POST_PROJECT_LOOP、（6）ACTION_GUARDS、（7）CRITIQUE、（8）SKILLS_CHAIN、（9）CONTEXT_EXTERNALIZATION、（10）PROTECTED、（11）禁止事項 - 最低11項目"
        status: "[ ]"

  - id: t1-2
    name: Hooks の発火条件抽出
    subtasks:
      - step: ".claude/hooks/ ディレクトリを読み、全 Hook ファイルの発火条件をリストアップ"
        executor: claudecode
        criteria: "docs/self-analysis-phase1.md に以下 Hook の発火条件が列挙されている: session-start.sh, init-guard.sh, playbook-guard.sh, project-guard.sh, check-protected-edit.sh, critic-guard.sh, scope-guard.sh, executor-guard.sh, check-main-branch.sh, check-coherence.sh, prompt-guard.sh, update-tracker.sh, archive-playbook.sh, archive-project.sh, create-pr-hook.sh, log-subagent.sh - 最低8個"
        status: "[ ]"

  - id: t1-3
    name: SubAgents の呼び出し条件抽出
    subtasks:
      - step: ".claude/agents/ ディレクトリを読み、全 SubAgent の呼び出し条件をリストアップ"
        executor: claudecode
        criteria: "docs/self-analysis-phase1.md に以下 SubAgent の呼び出し条件が列挙されている: pm, critic, reviewer, health-checker, plan-guard, setup-guide - 最低6個"
        status: "[ ]"

  - id: t1-4
    name: 機能連携図の作成
    subtasks:
      - step: "Phase 1 で収集した CLAUDE.md ルール、Hooks、SubAgents の関係を図として整理"
        executor: claudecode
        criteria: "docs/self-analysis-phase1.md に「機能連携図」セクションが存在し、以下の関係を示している: （a）Hook → SubAgent、（b）SubAgent → Skill、（c）ルール（CLAUDE.md）→ 実装（Hooks/SubAgents）"
        status: "[ ]"

test_method: |
  1. docs/self-analysis-phase1.md が存在する
  2. CLAUDE.md のルール 11+ 項目が列挙されている
  3. Hooks の発火条件 8+ 個が列挙されている
  4. SubAgents の呼び出し条件 6+ 個が列挙されている
  5. 機能連携図が描かれている
  6. grep で各項目を確認

status: done
```

---

### Phase 2: 機能不全の特定（Problem Identification）

```yaml
id: p2
name: 機能不全の特定
goal: 「あるべき動作」と「実際の動作」の差分を分析し、機能不全を特定する
priority: high
depends_on: [p1]
max_iterations: 3
tools:
  subagents: [critic]
  skills: []

tasks:
  - id: t2-1
    name: 各機能の「あるべき動作」を記述
    subtasks:
      - step: "Phase 1 で列挙した各 Hook/SubAgent/ルールについて、仕様書（feature-map.md、CLAUDE.md、agents/*.md）に基づいて「あるべき動作」を記述"
        executor: claudecode
        criteria: "docs/self-analysis-phase2.md に「あるべき動作」セクションが存在し、最低 15 機能について以下の形式で記述されている: 「{機能名}: {あるべき動作の説明}」"
        status: "[ ]"

  - id: t2-2
    name: 各機能の「実際の動作」を記述
    subtasks:
      - step: "過去のセッション履歴（git log、.claude/logs/）を参照し、各機能の実際の動作を記述"
        executor: claudecode
        criteria: "docs/self-analysis-phase2.md に「実際の動作」セクションが存在し、最低 15 機能について以下の形式で記述されている: 「{機能名}: {実際に観測された動作}」"
        status: "[ ]"

  - id: t2-3
    name: 差分（機能不全）の特定
    subtasks:
      - step: "「あるべき動作」と「実際の動作」を比較し、差分（機能不全）を抽出"
        executor: claudecode
        criteria: "docs/self-analysis-phase2.md に「差分」セクションが存在し、最低 3 個の機能不全が以下の形式で記述されている: 「{機能不全ID}: あるべき/実際の差分」"
        status: "[ ]"

  - id: t2-4
    name: 機能不全ごとの 5 Whys 分析
    subtasks:
      - step: "特定した各機能不全に対して、5 Whys を実行し、根本原因を分析"
        executor: claudecode
        criteria: "docs/self-analysis-phase2.md に「5 Whys 分析」セクションが存在し、最低 3 個の機能不全について以下が記述されている: Why-1, Why-2, Why-3, Why-4, Why-5, 根本原因"
        status: "[ ]"

test_method: |
  1. docs/self-analysis-phase2.md が存在する
  2. 「あるべき動作」セクションに 15+ 機能が記述されている
  3. 「実際の動作」セクションに 15+ 機能が記述されている
  4. 「差分」セクションに 3+ 機能不全が記述されている
  5. 「5 Whys 分析」セクションに最低 3 個の根本原因が記述されている
  6. grep で各セクションを確認

status: done
```

---

### Phase 3: 修正の実装（Implementation）

```yaml
id: p3
name: 修正の実装
goal: Phase 2 で特定した根本原因に対する修正を実装する
priority: high
depends_on: [p2]
max_iterations: 5
tools:
  subagents: [critic]
  skills: [lint-checker]

tasks:
  - id: t3-1
    name: prompt-guard.sh の強化（A1）
    subtasks:
      - step: "prompt-guard.sh を読み、現在実装を理解する"
        executor: claudecode
        criteria: "prompt-guard.sh が存在し、additionalContext の形式を確認できる"
        status: "[ ]"

      - step: "prompt-guard.sh に project.md / playbook 情報の強制注入機能を追加"
        executor: codex
        criteria: "prompt-guard.sh が修正され、以下を含む: （1）project.md の vision/goal の注入、（2）playbook の現在 Phase と done_criteria の注入、（3）「この情報に従って応答を生成せよ」という明示的指示"
        status: "[ ]"
        tools:
          skills: [lint-checker]

      - step: "修正内容の検証: git diff で変更を確認"
        executor: claudecode
        criteria: "git diff .claude/hooks/prompt-guard.sh で、vision/goal の注入と明示的指示が追加されているのが確認できる"
        status: "[ ]"

  - id: t3-2
    name: CLAUDE.md へのルール追加（B1）
    subtasks:
      - step: "CLAUDE.md に「全プロンプトで additionalContext を優先」ルールを追加"
        executor: claudecode
        criteria: "CLAUDE.md の CORE セクション（またはそれに準ずる箇所）に以下の 2 ルールが追加されている: （1）「全プロンプトで additionalContext を最初に確認せよ」、（2）「ユーザープロンプトより additionalContext を優先せよ」"
        status: "[ ]"

      - step: "修正内容の検証: git diff で変更を確認"
        executor: claudecode
        criteria: "git diff CLAUDE.md で、新しいルール 2 項目が追加されているのが確認できる"
        status: "[ ]"

  - id: t3-3
    name: 5W1H 自動構造化の常時発動修正（C1）★根本修正
    subtasks:
      - step: "CLAUDE.md のフェーズ 4.5 の条件を変更: 「playbook=null の場合のみ」→「全てのユーザープロンプトで実行」"
        executor: claudecode
        criteria: "CLAUDE.md のフェーズ 4.5 セクションから「playbook=null の場合のみ」という条件が削除され、「全ユーザープロンプトで 5W1H 構造化を実行」に変更されている"
        status: "[ ]"

      - step: "prompt-guard.sh の条件分岐を修正: playbook の有無に関係なく、全プロンプトで 5W1H 構造化を出力"
        executor: codex
        criteria: "prompt-guard.sh の if [ -z \"$PLAYBOOK\" ] 分岐が削除または統合され、全プロンプトで以下を出力: （1）5W1H 構造化の指示、（2）project/playbook 情報、（3）スコープ判断の要求"
        status: "[ ]"
        tools:
          skills: [lint-checker]

      - step: "修正内容の検証: git diff で変更を確認"
        executor: claudecode
        criteria: "git diff で以下が確認できる: （1）CLAUDE.md から playbook=null 条件が削除、（2）prompt-guard.sh から条件分岐が統合"
        status: "[ ]"

  - id: t3-4
    name: 用語統一（D1）★根本修正★優先
    subtasks:
      - step: "CLAUDE.md の用語を統一: macro = mission = project → 全て「project」に統一"
        executor: claudecode
        criteria: "CLAUDE.md 内の以下が統一されている: （1）「Macro」→「project」、（2）「mission」→「project.vision」、（3）「Macro チェック」→「project チェック」。grep -i 'macro' CLAUDE.md で旧表記がヒットしない"
        status: "[ ]"

      - step: "session-start.sh の用語を統一"
        executor: codex
        criteria: "session-start.sh 内の MISSION 関連表記が「project.vision」に統一されている。出力メッセージが一貫している"
        status: "[ ]"
        tools:
          skills: [lint-checker]

      - step: "feature-map.md、その他ドキュメントの用語統一"
        executor: claudecode
        criteria: "docs/feature-map.md 内の用語が統一されている。grep -ri 'macro' docs/ でヒットしない（または意図的な使用のみ）"
        status: "[ ]"

      - step: "用語対応表を docs/self-analysis-phase1.md に追加"
        executor: claudecode
        criteria: "docs/self-analysis-phase1.md に「用語対応表」セクションが存在し、以下が記述されている: 旧表記（macro/mission）→ 新表記（project/project.vision）の対応関係"
        status: "[ ]"

test_method: |
  1. git diff で修正内容を確認
  2. prompt-guard.sh に project/playbook 情報の注入が含まれている
  3. CLAUDE.md に 2 つの新しいルール行が含まれている
  4. shellcheck .claude/hooks/prompt-guard.sh が成功する

status: in_progress
```

---

### Phase 4: テストシナリオの設計と検証（Verification）

```yaml
id: p4
name: テストシナリオの設計と検証
goal: 修正が意図した効果を持つことを検証する 4 つのテストシナリオを実行
priority: high
depends_on: [p3]
max_iterations: 5
tools:
  subagents: [critic]
  skills: []

tasks:
  - id: t4-1
    name: テストシナリオの設計
    subtasks:
      - step: "以下の 4 つのテストシナリオを docs/self-analysis-phase4.md に記述: （T1）セッション開始時の動作、（T2）セッション途中の追加指示、（T3）playbook 完了後の自動進行、（T4）project 完了後の state リセット"
        executor: claudecode
        criteria: "docs/self-analysis-phase4.md に「テストシナリオ」セクションが存在し、以下 4 シナリオが記述されている: T1: セッション開始時に project.md と playbook が自動注入される、T2: セッション途中の新指示で project/playbook 情報が参照される、T3: playbook 全 Phase 完了で自動進行、T4: project 全 done_when 達成で state リセット"
        status: "[ ]"

  - id: t4-2
    name: テストシナリオ T1 の実行（セッション開始時）
    subtasks:
      - step: "/clear コマンドで新しいセッションを開始し、session-start.sh と prompt-guard.sh が正しく project/playbook 情報を出力することを確認"
        executor: user
        criteria: "セッション開始時の出力に以下が含まれている: （1）[自認] セクション、（2）project.md の vision/goal 情報、（3）playbook の現在 Phase 情報、（4）明示的に「この情報に従って応答を生成せよ」というメッセージ"
        status: "[ ]"
        tools:
          subagents: []

      - step: "T1 の実行結果を docs/self-analysis-phase4.md に記録"
        executor: claudecode
        criteria: "docs/self-analysis-phase4.md に「T1 実行結果」セクションが存在し、以下が記述されている: 実行日時、出力内容（引用）、検証項目と PASS/FAIL"
        status: "[ ]"

  - id: t4-3
    name: テストシナリオ T2 の実行（セッション途中の追加指示）
    subtasks:
      - step: "セッション途中で新しい指示を入力し、prompt-guard.sh が既存 playbook を参照しながら新指示を構造化することを確認"
        executor: user
        criteria: "セッション途中のプロンプト処理で [5W1H 構造化] が出力され、既存 playbook の情報が参照されているのが確認できる"
        status: "[ ]"

      - step: "T2 の実行結果を docs/self-analysis-phase4.md に記録"
        executor: claudecode
        criteria: "docs/self-analysis-phase4.md に「T2 実行結果」セクションが存在し、以下が記述されている: 実行日時、[5W1H 構造化] の出力、既存 playbook 参照の確認、PASS/FAIL"
        status: "[ ]"

  - id: t4-4
    name: テストシナリオ T3 の実行（playbook 完了後の自動進行）
    subtasks:
      - step: "現在進行中の playbook を完了させ、post-loop が自動実行されることを確認"
        executor: claudecode
        criteria: "playbook の全 Phase が done になった後、以下が自動実行されるのが確認できる: （1）自動コミット、（2）PR 作成、（3）次タスクの導出または次 playbook の開始"
        status: "[ ]"

      - step: "T3 の実行結果を docs/self-analysis-phase4.md に記録"
        executor: claudecode
        criteria: "docs/self-analysis-phase4.md に「T3 実行結果」セクションが存在し、以下が記述されている: playbook 完了日時、自動実行された処理（git log から引用）、state.md の更新確認、PASS/FAIL"
        status: "[ ]"

  - id: t4-5
    name: テストシナリオ T4 の実行（project 完了後の state リセット）
    subtasks:
      - step: "project.md の全 done_when が achieved になることを確認し、post-project-loop が自動実行されることを確認"
        executor: claudecode
        criteria: "project.md の全 done_when が achieved になった後、以下が自動実行されるのが確認できる: （1）project.md のアーカイブ、（2）state.md の focus.current が null または次 project に更新、（3）active_playbooks が全て null に更新"
        status: "[ ]"

      - step: "T4 の実行結果を docs/self-analysis-phase4.md に記録"
        executor: claudecode
        criteria: "docs/self-analysis-phase4.md に「T4 実行結果」セクションが存在し、以下が記述されている: project 完了日時、アーカイブされたファイル（ls で確認）、state.md の更新内容、PASS/FAIL"
        status: "[ ]"

test_method: |
  1. docs/self-analysis-phase4.md が存在する
  2. 「テストシナリオ」セクションに 4 シナリオが記述されている
  3. 「T1 実行結果」セクションで T1 が PASS している
  4. 「T2 実行結果」セクションで T2 が PASS している
  5. 「T3 実行結果」セクションで T3 が PASS している
  6. 「T4 実行結果」セクションで T4 が PASS している

status: done
```

---

### Phase 5: 回帰テストと完了確認（Regression & Closure）

```yaml
id: p5
name: 回帰テストと完了確認
goal: 修正による既存機能への影響を確認し、3 つ以上の回帰テストが PASS することを検証
priority: high
depends_on: [p4]
max_iterations: 3
tools:
  subagents: [critic]
  skills: []

tasks:
  - id: t5-1
    name: 回帰テストシナリオの設計
    subtasks:
      - step: "以下の 3 つの回帰テストシナリオを docs/self-analysis-phase5.md に記述: （R1）既存ルール（CLAUDE.md）の検証、（R2）既存 Hooks の発火テスト、（R3）既存 SubAgents の動作確認"
        executor: claudecode
        criteria: "docs/self-analysis-phase5.md に「回帰テスト」セクションが存在し、以下 3 テストシナリオが記述されている: R1: CLAUDE.md の既存ルールが機能する、R2: session-start.sh, init-guard.sh, playbook-guard.sh が正常に発火する、R3: pm, critic, reviewer SubAgent が正常に動作する"
        status: "[ ]"

  - id: t5-2
    name: 回帰テスト R1 の実行（既存ルール検証）
    subtasks:
      - step: "CLAUDE.md の既存ルール（INIT、LOOP、CORE 等）が修正後も変わらず機能することを確認"
        executor: claudecode
        criteria: "以下の既存ルールが修正後も動作確認できる: （1）INIT セクションの必須 Read、（2）LOOP のタスク status 更新、（3）POST_LOOP の自動コミット。docs/self-analysis-phase5.md に「R1 実行結果」セクションが存在し、各項目が PASS と記録されている"
        status: "[ ]"

  - id: t5-3
    name: 回帰テスト R2 の実行（既存 Hooks 発火テスト）
    subtasks:
      - step: "修正されない Hooks（session-start.sh, init-guard.sh, playbook-guard.sh）が修正後も正常に発火することを確認"
        executor: claudecode
        criteria: "以下の Hooks が正常に発火することを確認できる: （1）session-start.sh: セッション開始時に mission を表示、（2）init-guard.sh: Read なしでツール使用をブロック、（3）playbook-guard.sh: playbook なしで Edit をブロック。docs/self-analysis-phase5.md に「R2 実行結果」セクションが存在し、各 Hook が PASS と記録されている"
        status: "[ ]"

  - id: t5-4
    name: 回帰テスト R3 の実行（既存 SubAgent 動作確認）
    subtasks:
      - step: "修正されない SubAgents（critic, pm, reviewer）が修正後も正常に動作することを確認"
        executor: claudecode
        criteria: "以下の SubAgents が正常に動作することを確認できる: （1）critic: Phase 完了時に done_criteria を検証できる、（2）pm: playbook を作成できる、（3）reviewer: playbook をレビューできる。docs/self-analysis-phase5.md に「R3 実行結果」セクションが存在し、各 SubAgent が PASS と記録されている"
        status: "[ ]"

  - id: t5-5
    name: 分析サマリーの作成
    subtasks:
      - step: "Phase 1-5 の分析結果をまとめ、docs/self-analysis-summary.md にサマリーを作成"
        executor: claudecode
        criteria: "docs/self-analysis-summary.md が存在し、以下セクションが含まれている: （1）分析対象（CLAUDE.md ルール 10+ 項目、Hooks 8+ 個、SubAgents 6+ 個）、（2）特定した機能不全 3+ 個、（3）根本原因分析結果、（4）実装した修正（prompt-guard.sh、CLAUDE.md）、（5）テスト結果（T1-T4 PASS、回帰テスト 3+ PASS）、（6）改善効果の評価"
        status: "[ ]"

test_method: |
  1. docs/self-analysis-phase5.md が存在する
  2. 「回帰テスト」セクションに R1, R2, R3 が記述されている
  3. 「R1 実行結果」セクションで既存ルール 3+ 個が PASS と記録されている
  4. 「R2 実行結果」セクションで既存 Hooks 3+ 個が PASS と記録されている
  5. 「R3 実行結果」セクションで既存 SubAgents 3+ 個が PASS と記録されている
  6. docs/self-analysis-summary.md が存在し、サマリーが完成している

status: done
```

---

## 出力成果物

```yaml
docs/:
  - self-analysis-phase1.md  # CLAUDE.md ルール、Hooks、SubAgents リスト + 機能連携図
  - self-analysis-phase2.md  # あるべき動作 vs 実際の動作 + 差分 + 5 Whys 分析
  - self-analysis-phase4.md  # テストシナリオ 4 個と実行結果
  - self-analysis-phase5.md  # 回帰テスト結果
  - self-analysis-summary.md  # 全体サマリーと改善効果評価

修正ファイル:
  - .claude/hooks/prompt-guard.sh  # 強化（project/playbook 情報注入）
  - CLAUDE.md  # 新ルール追加（additionalContext 優先）

git:
  - commit: feat(self-improvement-dw001): 自己分析と機能不全特定・修正
```

---

## 参照ドキュメント

- CLAUDE.md - LLM 振る舞いルール（root_cause_analysis 参照）
- project.md (plan/active/project.md) - DW-001 の完全仕様
- feature-map.md - 機能連携図（Phase 1 の参考）
- plan/playbook-session-start-auto-commit-test.md - 既存 playbook（参考）

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-12 | V1: DW-001 用 playbook 作成。5 Phase + 事前定義 done_criteria。 |
