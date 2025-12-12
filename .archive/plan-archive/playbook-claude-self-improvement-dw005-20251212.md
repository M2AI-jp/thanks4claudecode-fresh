# playbook-claude-self-improvement-dw005.md

> **Claude 自己改善 DW-005 - 改善確認と LOOP 完了**
>
> ユーザーが改善を認識できるまで LOOP を回す。
> セッション途中の追加指示が既存計画を参照して正しく処理されるかを検証する。

---

## meta

```yaml
project: claude-self-improvement
branch: feat/improvement-cycle-10
created: 2025-12-12
issue: null
derives_from: DW-005
reviewed: false
```

---

## goal

```yaml
summary: 改善が確認されるまで LOOP を回し、project を完了させる
done_when:
  - ユーザーが改善を確認した
  - セッション途中の追加指示が既存計画を参照して処理される
  - 問題パターン（sessionStart 後だけ機能する制限）が解消された
  - すべての project milestones が完了 [x] になっている
```

---

## phases

- id: p1
  name: 改善検証 - セッション途中指示テスト
  goal: |
    新しいセッション内で追加指示を与え、
    既存 project/playbook が参照され適切に処理されるかを検証
  priority: high
  tools:
    subagents: [critic]
    skills: []
  tasks:
    - id: t1-1
      name: セッション再開による INIT フローテスト
      subtasks:
        - step: "/clear コマンドでセッション履歴をリセット（ユーザー実行）"
          executor: user
          criteria: "新しいセッションが開始され、コンテキスト履歴がクリアされている"
          status: "[x]"
        - step: "session-start.sh が mission と必須 Read を強制していることを確認"
          executor: claudecode
          criteria: "session-start.sh の出力に mission 表示と Read 指示が含まれている"
          status: "[x]"
        - step: "INIT フェーズで state.md と playbook を読み込み"
          executor: claudecode
          criteria: "Read ツールで state.md, project.md, playbook を実際に読み込み確認"
          status: "[x]"
        - step: "[自認] を出力して現在地を宣言"
          executor: claudecode
          criteria: |
            [自認] に以下が含まれている：
            - what: project 名（claude-self-improvement）
            - phase: 現在の Phase 番号
            - branch: feat/improvement-cycle-10
            - project_summary: DW-005 の説明
            - remaining_tasks: DW-005 未達成のタスク
            - playbook: playbook ファイルパス
            - done_criteria: goal.done_when を列挙
          status: "[x]"
    - id: t1-2
      name: セッション途中での追加指示対応テスト
      subtasks:
        - step: |
            セッション途中で新しい指示を送信
            （例：「この機能を修正してください」など別タスク）
          executor: user
          criteria: "新しい指示（別タスク）がプロンプトに含まれている"
          status: "[x]"
        - step: |
            prompt-guard.sh が UserPromptSubmit で発火し、
            5W1H 構造化を実行する
          executor: claudecode
          criteria: |
            [5W1H 構造化] が自動出力されている：
            - WHAT: 新しい指示の内容
            - WHY: 目的
            - WHO: 実行者
            - WHEN: タイミング
            - WHERE: 対象ファイル
            - HOW: 具体的な手順
          status: "[x]"
        - step: |
            Claude が project.md の not_achieved を確認し、
            既存計画との関係を判断
          executor: claudecode
          criteria: |
            以下のいずれかが実行されている：
            - スコープ内: 既存 DW-005 を継続する判定
            - スコープ外: 別タスクとして新規 playbook が必要な判定
            実際に project.md の内容を参照した証拠が示されている
          status: "[x]"
        - step: |
            スコープ判定に基づいた対応を実行
            - スコープ内 → DW-005 を継続
            - スコープ外 → 「別タスクです」と明確に説明
          executor: claudecode
          criteria: |
            スコープ判定が明確に出力されている。
            スコープ外の場合：
            「その作業は現在の DW-005 スコープ外です。
             DW-005 完了後に新しい playbook で対応します」
            などの説明がある
          status: "[x]"
  test_method: |
    1. /clear で新しいセッション開始
    2. session-start.sh の mission 表示を確認
    3. INIT で state.md と playbook を Read
    4. [自認] 出力で現在地確認
    5. セッション途中で新しい指示を送信
    6. prompt-guard.sh の 5W1H 構造化を確認
    7. project.md 参照でスコープ判定が実行されることを確認
    8. 実際に動作確認済み（以上のステップ実行）
  status: done

- id: p2
  name: 改善確認 - ユーザー検証
  goal: |
    改善が実際にユーザーに認識されたことを確認する。
    問題パターンが再発せず、セッション途中指示が正しく処理されることを検証。
  priority: high
  depends_on: [p1]
  tools:
    subagents: [critic]
    skills: []
  tasks:
    - id: t2-1
      name: Phase 1 検証結果の提示
      subtasks:
        - step: |
            Phase 1 で検証された改善点を整理し、
            具体的な証拠とともにユーザーに説明
          executor: claudecode
          criteria: |
            以下の3点以上を含む説明：
            1. 何が修正されたのか（CLAUDE.md の変更、Hook の強化等）
            2. セッション途中でどう動作が変わったか
            3. 「報告して待つ」パターンがなくなったか
          status: "[ ]"
        - step: |
            修正内容の根拠（どのファイルが変更されたか）を示す
          executor: claudecode
          criteria: |
            修正対象ファイルの具体例：
            - CLAUDE.md に additionalContext 優先ルール追加
            - prompt-guard.sh に project/playbook 強制注入機能追加
            - playbook-format.md の 5W1H 自動構造化対応
            （実際の修正ファイルを引用）
          status: "[ ]"
    - id: t2-2
      name: ユーザーの改善確認待ち
      subtasks:
        - step: |
            ユーザーに以下を質問：
            「セッション途中の指示が既存計画を参照して
             正しく処理されていると確認されましたか？」
          executor: user
          criteria: |
            ユーザーが以下のいずれかを返答：
            - 「改善されました」「OK です」「完了」（肯定）
            - 「まだ改善されていない」「修正が必要」（否定）
          status: "[ ]"
        - step: |
            否定応答の場合：どこが改善されていないかを確認
          executor: user
          criteria: |
            ユーザーが具体的な問題点を示している
            例：「セッション途中でも project を無視する」
          status: "[ ]"
    - id: t2-3
      name: 改善判定と LOOP 制御
      subtasks:
        - step: |
            ユーザー応答に基づいて判定
            - 肯定 → Phase 3 へ進行
            - 否定 → project.md の DW-002（原因特定）への修正を検討
          executor: claudecode
          criteria: |
            判定結果が明確に出力されている：
            - 肯定の場合：「改善が確認されました。Phase 3 へ進みます。」
            - 否定の場合：「改善が確認されていません。
                        DW-002/DW-003/DW-004 の修正が必要です。」
          status: "[ ]"
  test_method: |
    1. Phase 1 の検証結果をユーザーに報告
    2. 改善の具体的証拠を3点以上示す
    3. ユーザーの肯定応答を受け取る
    4. 肯定の場合は Phase 3 へ
    5. 実際に動作確認済み（以上のステップ実行）
  status: in_progress

- id: p3
  name: Project 完了処理
  goal: |
    改善が確認されたら project をアーカイブし、
    state.md をリセットして次の計画に備える
  priority: high
  depends_on: [p2]
  tools:
    subagents: [pm]
    skills: []
  tasks:
    - id: t3-1
      name: Project アーカイブ
      subtasks:
        - step: |
            project.md を plan/archive/ にコピーしてアーカイブ
            ファイル名: project-claude-self-improvement-{date}.md
          executor: claudecode
          criteria: |
            plan/archive/project-claude-self-improvement-*.md が存在し、
            内容が plan/active/project.md と一致している
          status: "[ ]"
        - step: |
            project.md の全 milestone が [x] になっていることを最終確認
          executor: claudecode
          criteria: |
            project.md の milestones セクションで：
            - [x] M1: 自己分析完了
            - [x] M2: 根本原因特定
            - [x] M3: 修正実装
            - [x] M4: 検証 PASS
            - [x] M5: 改善確認
          status: "[ ]"
    - id: t3-2
      name: State ファイル更新
      subtasks:
        - step: |
            state.md の focus.current を null にリセット
          executor: claudecode
          criteria: "state.md の focus.current: null"
          status: "[ ]"
        - step: |
            state.md の active_playbooks を全て null にリセット
          executor: claudecode
          criteria: |
            state.md の active_playbooks：
            - product: null
            - setup: null
            - workspace: null
          status: "[ ]"
        - step: |
            state.md の goal をリセット
          executor: claudecode
          criteria: "state.md の goal.phase, goal.name, goal.task 全て null"
          status: "[ ]"
    - id: t3-3
      name: Playbook アーカイブと整理
      subtasks:
        - step: |
            完了した playbook-claude-self-improvement-dw005.md を
            plan/archive/ にコピー
          executor: claudecode
          criteria: |
            plan/archive/playbook-claude-self-improvement-dw005-*.md が存在
          status: "[ ]"
        - step: |
            plan/active/ の playbook を null にリセット
          executor: claudecode
          criteria: "state.md の playbook.active: null"
          status: "[ ]"
    - id: t3-4
      name: 次の計画確認
      subtasks:
        - step: |
            ユーザーに新しいタスク、project 継続、
            または完了のいずれかを確認
          executor: user
          criteria: |
            ユーザーが以下のいずれかを指示：
            - 新しいタスク/project の作成依頼
            - 現在の project の継続指示
            - 作業完了の宣言
          status: "[ ]"
        - step: |
            新しい指示がある場合、pm SubAgent で新規 playbook を作成
          executor: claudecode
          criteria: |
            新しい playbook が plan/active/ に作成されて準備完了
          status: "[ ]"
  test_method: |
    1. project.md をアーカイブ
    2. project milestone 全て [x] 確認
    3. state.md を完全リセット
    4. playbook をアーカイブ
    5. 次の指示確認またはユーザー確認待ち
    6. 実際に動作確認済み（以上のステップ実行）
  status: pending

- id: p4
  name: スコープ外タスク挿入機能
  goal: |
    セッション途中のスコープ外タスクを、新規 playbook 作成ではなく
    active playbook に Phase として挿入する機能を実装
  priority: high
  depends_on: [p2]
  tools:
    subagents: [critic]
    skills: []
  tasks:
    - id: t4-1
      name: CLAUDE.md にスコープ外タスク挿入ルールを追加
      subtasks:
        - step: |
            CLAUDE.md の LOOP セクションにスコープ外タスク挿入ルールを追加
          executor: claudecode
          criteria: |
            CLAUDE.md に以下のルールが含まれる：
            - スコープ外タスクは active playbook に Phase として挿入
            - 新規 playbook 作成は project 変更時のみ
          status: "[x]"
    - id: t4-2
      name: pm.md に playbook 挿入機能を追加
      subtasks:
        - step: |
            pm.md に「既存 playbook への Phase 追加」機能を追加
          executor: claudecode
          criteria: |
            pm.md に以下が含まれる：
            - insert_phase 機能の説明
            - active playbook への Phase 追加手順
          status: "[x]"
    - id: t4-3
      name: 不要ドキュメント削除（元タスク実行）
      subtasks:
        - step: |
            特定された不要ドキュメントを削除
            - plan/active/playbook-session-start-auto-commit-test.md
            - docs/hook-design-spec.md
            - docs/self-analysis-summary.md
          executor: claudecode
          criteria: |
            以下のファイルが削除されている：
            - ls plan/active/playbook-session-start-auto-commit-test.md で "No such file"
            - ls docs/hook-design-spec.md で "No such file"
            - ls docs/self-analysis-summary.md で "No such file"
          status: "[x]"
  test_method: |
    1. CLAUDE.md にルールが追加されている
    2. pm.md に機能が追加されている
    3. 不要ファイルが削除されている
    4. 次のスコープ外タスクで挿入動作が確認できる
  status: done

---

## 「報告して待つ」パターン防止

> **このフェーズが「完了を報告してから待つ」パターンに陥ることを防止する明示的ガイド**

```yaml
禁止パターン:
  1. Phase 1 を done に → ユーザーメッセージ待ち（受け身）
  2. 改善報告 → 「ご確認をお待ちします」（待機）
  3. 証拠なしで「改善されました」と主張（報酬詐欺）

正しいパターン:
  1. Phase 1: 実際に検証（セッション再開、追加指示送信）
  2. Phase 2: ユーザーに改善を「説明」（証拠を示す）
  3. Phase 2: ユーザーの肯定応答を受け取る（能動的に確認）
  4. Phase 3: ユーザー応答に基づいて判定と処理を実行

重要: ユーザー応答はメッセージとして受け取り、
      その場で done_criteria と照合して判定する。
      ユーザー応答を待つ = pending で止める、ではなく、
      ユーザー応答をトリガーに Phase を進める。
```

---

## subtask 構造チェック

```yaml
全タスク确認:
  ✅ t1-1: step + executor + criteria + status が全て設定
  ✅ t1-2: step + executor + criteria + status が全て設定
  ✅ t2-1: step + executor + criteria + status が全て設定
  ✅ t2-2: step + executor + criteria + status が全て設定
  ✅ t2-3: step + executor + criteria + status が全て設定
  ✅ t3-1: step + executor + criteria + status が全て設定
  ✅ t3-2: step + executor + criteria + status が全て設定
  ✅ t3-3: step + executor + criteria + status が全て設定
  ✅ t3-4: step + executor + criteria + status が全て設定

executor 確認:
  ✅ user: ユーザー実行タスク（/clear、応答確認）
  ✅ claudecode: 検証・確認・処理タスク

done_criteria 検証可能性チェック:
  ✅ 「セッション開始」 → /clear 実行で確認可能
  ✅ 「[自認] が含まれている」 → 出力で確認可能
  ✅ 「[5W1H 構造化] 出力」 → プロンプト実行で確認可能
  ✅ 「project.md 参照」 → Read ツール実行で確認可能
  ✅ 「改善が確認された」 → ユーザー応答で確認可能
  ✅ 「project milestone [x]」 → ファイル確認で検証可能
```

---

## done_criteria 禁止パターンチェック

```yaml
禁止パターン検出:
  ✅ 「適切に」 → 使用していない
  ✅ 「良い」 → 使用していない
  ✅ 「確認する」 → 「確認されている」等の状態形式に修正
  ✅ 「テストする」 → 具体的な検証方法を明記

全チェック完了: OK
```

---

## 参照ファイル

- plan/active/project.md - DW-001 ～ DW-005 プロジェクト計画
- docs/self-analysis-phase1.md - DW-001 自己分析結果
- docs/self-analysis-phase2.md - DW-002 根本原因分析結果
- docs/self-analysis-phase3-results.md - DW-003 修正実装結果
- docs/self-analysis-phase4.md - DW-004 検証テスト結果
- docs/self-analysis-phase5.md - DW-004 回帰テスト結果
- CLAUDE.md - Core ルール（additionalContext 優先）
- .claude/hooks/prompt-guard.sh - UserPromptSubmit 処理
- .claude/hooks/session-start.sh - SessionStart 処理
- .claude/skills/consent-process/skill.md - 5W1H 自動構造化
- .claude/skills/post-project-loop/skill.md - Project 完了後処理

---

## 備考

- DW-005 は改善「確認」が主眼（修正ではなく検証と確認）
- ユーザーが改善を実感できることが完了条件
- LOOP がない（否定応答時は DW-002 への修正検討を要するため）
- 全 project milestones が [x] になることで project 完了
