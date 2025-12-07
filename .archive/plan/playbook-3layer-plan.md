# playbook-3layer-plan.md

> **3層計画管理システムの実装**

---

## meta

```yaml
project: 3layer-plan-guard
branch: feat/workspace-improvement
created: 2025-12-08
```

---

## goal

```yaml
summary: 計画なし・計画外のユーザープロンプトを拒否/再確認する仕組みを作る
done_when:
  - plan-guard SubAgent が存在し、CLAUDE.md DISPATCH に登録されている
  - シナリオ S0-S5 が全て正しく動作する
  - 3層計画構造（Macro/Medium/Micro）が state.md に反映されている
```

---

## design_decisions

```yaml
LLM主導の原則:
  - LLM がセッション開始時に計画を確認・提示
  - ユーザーは同意/修正/拒否で応答
  - ユーザープロンプト待ちではなく、LLM が先に動く

3層計画構造:
  Macro:
    what: リポジトリ全体の最終目標
    file: plan/project.md（存在する場合）
    scope: プロダクト完成まで
  Medium:
    what: 単機能実装の中期計画
    file: playbook
    scope: 1ブランチ = 1playbook
  Micro:
    what: セッション単位の作業
    file: playbook の 1 Phase
    scope: 1セッション

plan-guard の役割:
  - Hooks ではなく SubAgent で実装
  - CLAUDE.md DISPATCH でトリガー条件を明記
  - LLM の判断が必要な整合性チェックを担当

Hooks との使い分け:
  Hooks: 機械的に判定可能なルール（ファイルパス、ブランチ名）
  SubAgents: LLM の判断が必要なルール（計画の整合性）
```

---

## scenarios

```yaml
S0_セッション開始:
  trigger: セッション開始（ユーザーが何も言わなくても）
  llm_action:
    1. state.md を読む
    2. plan-guard を自動発火
    3. 3層計画を確認・提示
    4. 「今日は〇〇をやります。よろしいですか？」
  user_response: agree | modify | reject
  test_method: |
    1. 新規セッションを開始
    2. LLM が [自認] + 計画提示を行うか確認
    3. 期待: ユーザー入力前に計画が提示される

S1_計画なしで要求:
  state: playbook = null AND project.md = null
  user_prompt: 「〇〇を作って」
  llm_action:
    1. 「計画がありません。まず計画を作成します」
    2. pm エージェントを呼び出し
    3. Macro 計画 → Medium 計画の順で作成
  test_method: |
    1. playbook=null, project.md なしの状態で要求
    2. LLM が計画作成を強制するか確認
    3. 期待: 即座に実装開始しない

S2_計画と無関係な要求:
  state: playbook exists
  user_prompt: playbook にない作業を依頼
  llm_action:
    1. 「現在の計画と異なります」と警告
    2. 選択肢を提示:
       a) 計画を更新して進める
       b) 割り込みタスクとして処理
       c) 強制実行する（非推奨）
    3. ユーザーの明示的な選択後に作業開始
  test_method: |
    1. playbook が存在する状態で関係ない要求
    2. LLM が警告を出すか確認
    3. 期待: 無条件に従わない

S3_計画に沿った要求:
  state: playbook exists, prompt が playbook と整合
  llm_action:
    1. 計画との整合性を確認
    2. 「計画に沿って進めます」と宣言
    3. 作業続行
  test_method: |
    1. playbook と整合する要求を出す
    2. スムーズに作業が進むか確認

S4_Macro計画がない:
  state: project.md = null
  user_prompt: 何らかの開発要求
  llm_action:
    1. 「リポジトリ全体の目標が未定義です」
    2. project.md の作成を強制
    3. Macro → Medium → Micro の順で計画確立
  test_method: |
    1. project.md なしで開発要求
    2. Macro 計画作成が強制されるか確認

S5_Medium計画がない:
  state: project.md exists, playbook = null
  user_prompt: 機能実装の要求
  llm_action:
    1. 「Macro 計画はありますが、Medium 計画がありません」
    2. playbook 作成を強制
    3. /playbook-init または pm エージェント
  test_method: |
    1. project.md あり、playbook なしで要求
    2. playbook 作成が強制されるか確認
```

---

## phases

```yaml
- id: p1
  name: playbook 作成
  goal: この playbook 自体を作成し、state.md に登録
  executor: claude_code
  done_criteria:
    - plan/active/playbook-3layer-plan.md が存在する
    - state.md の active_playbooks.workspace がこの playbook を参照
  test_method: |
    1. ls plan/active/playbook-3layer-plan.md
    2. grep "playbook-3layer-plan" state.md
  status: done

- id: p2
  name: plan-guard SubAgent 作成
  goal: 計画整合性チェックを行う SubAgent を作成
  executor: claude_code
  depends_on: [p1]
  done_criteria:
    - .claude/agents/plan-guard.md が存在する
    - 3層計画の整合性チェックロジックを含む
    - シナリオ S0-S5 のハンドリングを含む
  test_method: |
    1. cat .claude/agents/plan-guard.md
    2. 内容にシナリオ対応が含まれるか確認
  status: done

- id: p3
  name: CLAUDE.md DISPATCH 更新
  goal: plan-guard の発火条件を CLAUDE.md に追加
  executor: claude_code
  depends_on: [p2]
  done_criteria:
    - CLAUDE-ref.md の DISPATCH セクションに plan-guard が追加
    - セッション開始時の自動発火が明記
  test_method: |
    1. grep "plan-guard" .claude/CLAUDE-ref.md
    2. 発火条件が明記されているか確認
  status: done

- id: p4
  name: state.md 3層構造への更新
  goal: plan_hierarchy を3層構造に簡素化
  executor: claude_code
  depends_on: [p3]
  done_criteria:
    - state.md の plan_hierarchy が Macro/Medium/Micro の3層
    - 6層からの移行が完了
  test_method: |
    1. cat state.md の plan_hierarchy セクション
    2. 3層構造になっているか確認
  status: done

- id: p5
  name: シナリオテスト
  goal: S0-S5 のハンドリングが仕組みとして定義されていることを確認
  executor: claude_code
  depends_on: [p4]
  done_criteria:
    # 仕組みの存在確認（ドキュメントベース）
    - plan-guard.md にシナリオ S0-S5 のハンドリングが定義されている
    - DISPATCH に plan-guard の発火条件が明記されている
    - state.md の plan_hierarchy が 3層構造になっている
    # 注: plan-guard は SubAgent ではなく、LLM が INIT 時に参照する設計ドキュメント
    # 実際の動作確認は次回セッション開始時に自然に行われる
  test_method: |
    1. grep "S0_セッション開始" .claude/agents/plan-guard.md
    2. grep "plan-guard" .claude/CLAUDE-ref.md
    3. grep "3層計画構造" state.md
  note: |
    plan-guard は Claude Code の SubAgent リストに登録されていないため、
    Task(subagent_type='plan-guard') としては呼び出せない。
    代わりに LLM が INIT 時に plan-guard.md を参照し、
    そのロジックに従って自己判断を行う設計。
  status: done
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | V1: 初版作成 |
