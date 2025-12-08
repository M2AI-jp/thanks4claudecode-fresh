# playbook-claude-hook-integration.md

> **CLAUDE.md と Hooks/SubAgents の連動を1つずつ検証し、最適化する**

---

## meta

```yaml
project: CLAUDE.md - Hooks/SubAgents 連動最適化
branch: feat/claude-hook-integration
created: 2025-12-09
issue: null
derives_from: null  # ユーザー要求による
```

---

## goal

```yaml
summary: current-implementation.md の各機能と CLAUDE.md の連動を検証・最適化する
done_when:
  - state.md の二重管理問題が解消されている
  - INIT と init-guard/session-start の連動が検証済み
  - [自認] テンプレートが正しく機能している
  - LOOP/CRITIQUE と critic-guard の連動が強化されている
  - 各 Hook の動作テストが PASS
```

---

## phases

```yaml
- id: p0
  name: state.md 二重管理問題の修正
  goal: active_playbooks と layer.*.playbook の不整合を解消する
  executor: claudecode
  done_criteria:
    - active_playbooks と layer.*.playbook が一致している
    - session-start.sh が正しい playbook パスを取得できる
    - 実際に動作確認済み（test_method 実行）
  test_method: |
    1. state.md の active_playbooks と layer.*.playbook を照合
    2. bash .claude/hooks/session-start.sh を実行し、playbook が正しく表示されるか確認
    3. PLAYBOOK 変数が null でないことを確認
  status: done
  evidence:
    - active_playbooks.product = layer.product.playbook（一致確認済み）
    - session-start.sh 出力で playbook パス正常表示
    - init-guard.sh 連動も確認（ブロック動作で実証）
  max_iterations: 3

- id: p1
  name: INIT と init-guard の連動検証
  goal: CLAUDE.md の INIT セクションと init-guard.sh の連動を検証する
  executor: claudecode
  depends_on: [p0]
  done_criteria:
    - CLAUDE.md INIT の「必須 Read」と init-guard.sh の要求ファイルの差異を特定
    - init-guard.sh が state.md Read 前のツール使用をブロックする
    - 実際に動作確認済み
    - 差異がある場合は p7 の改善案に記録
  test_method: |
    1. CLAUDE.md の INIT セクションを読み、必須 Read を特定
    2. init-guard.sh のブロック条件を確認
    3. 新セッションをシミュレートし、Read 前の Bash がブロックされることを確認
  status: done
  evidence:
    - CLAUDE.md INIT: state.md, project.md, playbook が必須（行 20-22）
    - init-guard.sh: state.md, playbook のみブロック（行 33-43）
    - 差異: project.md は init-guard.sh に含まれていない
    - ブロック動作確認: p0 で Bash ブロック時に exit 2 を確認
  issues_for_p7:
    - project.md を init-guard.sh に追加すべきか？
    - または CLAUDE.md の記述を「推奨」に変更すべきか？
  max_iterations: 3

- id: p2
  name: [自認] テンプレートの整合性確認
  goal: session-start.sh の [自認] テンプレートが state.md から正しい値を取得するか検証
  executor: claudecode
  depends_on: [p0]
  done_criteria:
    - session-start.sh と CLAUDE.md の [自認] フィールドの差異を特定
    - playbook パスが null でない
    - done_criteria が正しく表示される
    - 差異がある場合は p7 の改善案に記録
  test_method: |
    1. bash .claude/hooks/session-start.sh を実行
    2. 出力の [自認] テンプレートを確認
    3. CLAUDE.md の [自認] と比較
  status: done
  evidence:
    - session-start.sh 出力: what, phase, branch, project, playbook, done_criteria（6 フィールド）
    - CLAUDE.md 定義: 上記 + macro_goal, remaining_tasks, git_status, last_critic（10 フィールド）
    - playbook パス: plan/active/playbook-claude-hook-integration.md（正常）
    - done_criteria: 正常に表示（p0 で確認済み）
  issues_for_p7:
    - session-start.sh に macro_goal, remaining_tasks, git_status, last_critic を追加すべきか？
    - または CLAUDE.md から「LLM が追加で出力すべきフィールド」として分離すべきか？
  max_iterations: 3

- id: p3
  name: LOOP/CRITIQUE と critic-guard の連動強化
  goal: critic-guard.sh の警告が CLAUDE.md の CRITIQUE ルールと整合するか検証
  executor: claudecode
  depends_on: [p1]
  done_criteria:
    - critic-guard.sh が done 更新時に警告を出す
    - 警告メッセージが CLAUDE.md の CRITIQUE セクションと一致
    - critic 呼び出しの発火条件が明確
    - 差異がある場合は p7 の改善案に記録
  test_method: |
    1. state.md の goal.phase を done に変更しようとする
    2. critic-guard.sh の出力を確認
    3. CLAUDE.md CRITIQUE セクションとの整合性を確認
  status: done
  evidence:
    - critic-guard.sh: state.md の state: done 編集時に exit 2 でブロック
    - 警告メッセージ: Task(subagent_type='critic') または /crit を案内（CLAUDE.md と一致）
    - 発火条件: state.md への Edit で "state: done" パターン検出
  issues_for_p7:
    - playbook の status: done には critic-guard が発火しない
    - Phase done 判定は CLAUDE.md ルール依存（構造的強制なし）
    - playbook 用の critic-guard を追加すべきか？
  max_iterations: 3

- id: p4
  name: ACTION_GUARDS と playbook-guard の連動検証
  goal: playbook-guard.sh が CLAUDE.md の ACTION_GUARDS と整合するか検証
  executor: claudecode
  depends_on: [p0]
  done_criteria:
    - playbook-guard.sh が playbook=null で Edit/Write をブロックする
    - state.md への編集は許可される（デッドロック回避）
    - CLAUDE.md ACTION_GUARDS セクションとの整合性確認済み
  test_method: |
    1. playbook-guard.sh のソースを確認
    2. ブロック条件と許可条件を特定
  status: done
  evidence:
    - playbook-guard.sh は active_playbooks.$FOCUS から playbook を取得（行 42）
    - playbook=null または空なら exit 2 でブロック
    - state.md への編集は常に許可（行 34-36）
    - CLAUDE.md ACTION_GUARDS と整合
  issues_for_p7:
    - なし（設計通り動作）
  max_iterations: 3

- id: p5
  name: PROTECTED と check-protected-edit の連動検証
  goal: check-protected-edit.sh が CLAUDE.md の PROTECTED と整合するか検証
  executor: claudecode
  depends_on: [p0]
  done_criteria:
    - HARD_BLOCK ファイルへの Edit がブロックされる
    - BLOCK ファイルへの Edit が security.mode に応じて処理される
    - CLAUDE.md PROTECTED セクションとの整合性確認済み
  test_method: |
    1. protected-files.txt の内容を確認
    2. check-protected-edit.sh のソースを確認
    3. 保護レベルと security.mode の組み合わせを検証
  status: done
  evidence:
    - protected-files.txt に HARD_BLOCK 7 件、BLOCK 8 件、WARN 3 件を定義
    - HARD_BLOCK: CLAUDE.md, protected-files.txt, 重要 Hook（init-guard, critic-guard 等）
    - security.mode が admin 以外では HARD_BLOCK は常にブロック
    - CLAUDE.md PROTECTED と整合
  issues_for_p7:
    - playbook-guard.sh が HARD_BLOCK されていない（追加検討）
  max_iterations: 3

- id: p6
  name: 未登録 Hook の必要性評価
  goal: check-coherence.sh, check-state-update.sh の登録是非を判断
  executor: claudecode
  depends_on: [p3, p4, p5]
  done_criteria:
    - 各未登録 Hook の役割が明確化されている
    - settings.json への登録是非が判断されている
    - 判断根拠が記録されている
  test_method: |
    1. current-implementation.md の「未登録 Hook」セクションを参照
    2. 各 Hook の役割を特定
    3. 登録による改善効果を評価
  status: done
  evidence:
    - check-coherence.sh: pre-bash-check.sh から間接呼び出し（登録済み）
    - check-state-update.sh: pre-bash-check.sh から間接呼び出し（登録済み）
    - check-manifest-sync.sh, check-playbook-quality.sh: 手動用（登録不要）
  decision:
    - check-coherence.sh: 直接登録は不要（pre-bash-check.sh 経由で機能）
    - check-state-update.sh: 同上
    - 未活用イベント（UserPromptSubmit, Stop）: p7 で検討
  max_iterations: 3

- id: p7
  name: CLAUDE.md 最適化案の策定
  goal: 検証結果に基づき CLAUDE.md の改善案をまとめる
  executor: claudecode
  depends_on: [p1, p2, p3, p4, p5, p6]
  done_criteria:
    - 発見した問題点のリストが作成されている
    - 各問題に対する改善案が提示されている
    - ユーザーレビュー待ち状態
  test_method: |
    1. p1-p6 の結果をまとめる
    2. 問題点と改善案を整理
    3. ユーザーに提示
  status: done
  summary:
    issues_found:
      - p1: project.md が init-guard.sh に含まれていない
      - p2: [自認] の 4 フィールド（macro_goal, remaining_tasks, git_status, last_critic）が session-start.sh に欠落
      - p3: playbook status: done に critic-guard が発火しない
      - p5: playbook-guard.sh が HARD_BLOCK されていない
    recommendations:
      - CLAUDE.md の [自認] テンプレートを session-start.sh 出力に合わせて簡素化
      - INIT の project.md を「必須」から「推奨」に変更
      - playbook Phase done の critic チェックは現状維持（LLM ルール依存）
      - playbook-guard.sh を HARD_BLOCK に追加検討
    next_actions:
      - ユーザーに改善案を提示
      - 承認後に CLAUDE.md を編集
  max_iterations: 3
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | 初版作成 |
