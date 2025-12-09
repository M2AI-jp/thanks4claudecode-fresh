# playbook-repository-refinement.md

> **リポジトリ洗練 - 「読んでも無視できる」問題の構造的解決**
>
> セキュリティモード、未登録 Hooks、不完全 Skills の健全化

---

## meta

```yaml
project: repository-refinement
branch: feat/repository-refinement
created: 2025-12-09
issue: null
derives_from: null  # 独立した洗練タスク
```

---

## goal

```yaml
summary: 「設定はあるが機能していない」問題を構造的に解決し、全機能が意図通り動作する状態を実現
done_when:
  - security.mode が Hook で実際に参照されている
  - 未登録 Hooks が全て処理されている（登録または削除）
  - 不完全 Skills が全て処理されている（frontmatter 追加または削除）
  - init-guard.sh のデッドロック問題が解決されている
  - 新規セッション開始時にシステムが正常動作することを確認できている
```

---

## background

```yaml
発見された核心問題:
  1. security_mode_ignored:
     description: state.md の security.mode が全 Hook で無視されている
     impact: admin モードでも全ガードが発火、設定が「飾り」になっている
     root_cause: Hook が state.md の security セクションを参照していない

  2. init_guard_deadlock:
     description: 存在しないファイルの Read でマーカーが作成されない
     impact: required_playbook が存在しないファイルを参照するとデッドロック
     root_cause: Claude Code が存在しないファイルの Read で PreToolUse Hook を実行しない可能性

  3. unregistered_hooks:
     description: .claude/hooks/ に存在するが settings.json に未登録の Hook が存在
     impact: 意図した制御が発火しない

  4. incomplete_skills:
     description: frontmatter がない Skills が存在
     impact: 自動発火条件が定義されていない
```

---

## phases

```yaml
- id: p1
  name: 現状分析と核心問題の特定
  goal: 全 Hook/Skill を棚卸しし、問題箇所を特定
  executor: claudecode
  done_criteria:
    - playbook evidence に hooks_analysis (total_files=22, registered=19, unregistered=3) が記載されている
    - playbook evidence に unregistered_list として 3 個の Hook 名が記載されている
    - playbook evidence に skills_analysis (total=9, complete=5, incomplete=4) が記載されている
    - playbook evidence に main_guards_security_check として grep 結果が記載されている
  test_method: |
    1. playbook-repository-refinement.md の evidence セクションを Read
    2. hooks_analysis.total_files = 22, hooks_analysis.registered = 19, unregistered = 3 を確認
    3. skills_analysis.total = 9, complete = 5, incomplete = 4 を確認
    4. main_guards_security_check に No matches found が記載されていることを確認
  status: done

- id: p2
  name: security.mode 参照の実装
  goal: 主要 Hook が security.mode を参照し、admin モードで適切にバイパスする
  executor: claudecode
  depends_on: [p1]
  done_criteria:
    - init-guard.sh が security.mode を参照している
    - playbook-guard.sh が security.mode を参照している
    - admin モードで適切にバイパスされる
  test_method: |
    1. security.mode: admin で Hook をテスト
    2. security.mode: strict で Hook をテスト
    3. 挙動の違いを確認
  status: done

- id: p3
  name: init-guard.sh デッドロック対策
  goal: 存在しないファイルの Read でもデッドロックしないように改善
  executor: claudecode
  depends_on: [p1]
  done_criteria:
    - required_playbook が存在しないファイルを参照してもデッドロックしない
    - フォールバック機構が実装されている
  test_method: |
    1. 存在しない playbook を required_playbook に設定
    2. セッションを開始
    3. デッドロックせずに回復できることを確認
  status: done

- id: p4
  name: 未登録 Hooks の処理
  goal: 未登録 Hook を登録または削除し、settings.json と整合させる
  executor: claudecode
  depends_on: [p1]
  done_criteria:
    - 全 Hook が settings.json に登録されているか、削除されている
    - .claude/hooks/ と settings.json が整合
  test_method: |
    1. settings.json の hooks を再確認
    2. .claude/hooks/*.sh を再確認
    3. 差分がないことを確認
  status: done

- id: p5
  name: 不完全 Skills の処理
  goal: 不完全 Skill に frontmatter を追加または削除
  executor: claudecode
  depends_on: [p1]
  done_criteria:
    - 全 Skill に有効な frontmatter が存在する
    - または不要な Skill が削除されている
  test_method: |
    1. .claude/skills/*/skill.md の frontmatter を確認
    2. 全て有効な形式であることを確認
  status: done

- id: p6
  name: 検証
  goal: 新規セッション開始時にシステムが正常動作することを確認
  executor: claudecode
  depends_on: [p2, p3, p4, p5]
  done_criteria:
    - 新規セッションでエラーなし
    - admin モードで適切にバイパス
    - 全 Hook が正常発火
    - critic PASS
  test_method: |
    1. /clear でセッションリセット
    2. 新規セッションを開始
    3. [自認] が正常出力
    4. critic を呼び出して PASS
  status: in_progress
```

---

## evidence

```yaml
p1:
  deadlock_discovered: |
    - init-guard.sh が存在しないファイルの Read でマーカー未作成
    - security.mode: admin なのに全ガード発火
    - 手動で .claude/.session-init/ を削除して解消

  hooks_analysis:
    total_files: 22
    registered: 19
    unregistered: 3
    unregistered_list:
      - check-manifest-sync.sh
      - check-playbook-quality.sh
      - check-state-update.sh

  security_mode_reference:
    total_hooks: 22
    referencing_security: 1  # check-protected-edit.sh のみ
    not_referencing:
      - init-guard.sh
      - playbook-guard.sh
      - consent-guard.sh
      - critic-guard.sh
      - scope-guard.sh
      - executor-guard.sh
      - depends-check.sh
      - その他 15 個

  skills_analysis:
    total: 9
    complete: 5   # YAML frontmatter あり
    incomplete: 4  # YAML frontmatter なし
    complete_list:
      - context-management/skill.md
      - execution-management/skill.md
      - learning/skill.md
      - plan-management/skill.md
      - state/skill.md
    incomplete_list:
      - deploy-checker/skill.md
      - frontend-design/skill.md
      - lint-checker/skill.md
      - test-runner/skill.md
    evidence: |
      head -3 で全 9 ディレクトリを確認:
      - context-management: "---" で開始（frontmatter あり）
      - execution-management: "---" で開始（frontmatter あり）
      - learning: "---" で開始（frontmatter あり）
      - plan-management: "---" で開始（frontmatter あり）
      - state: "---" で開始（frontmatter あり）
      - deploy-checker: "# deploy-checker" で開始（frontmatter なし）
      - frontend-design: "# frontend-design" で開始（frontmatter なし）
      - lint-checker: "# lint-checker" で開始（frontmatter なし）
      - test-runner: "# test-runner" で開始（frontmatter なし）

  main_guards_security_check:
    init_guard_sh:
      grep_result: "No matches found"
      conclusion: security.mode を参照していない
    playbook_guard_sh:
      grep_result: "No matches found"
      conclusion: security.mode を参照していない
    evidence: |
      grep "security|SECURITY|get_security" で両ファイルを検索
      → どちらも 0 件マッチ
      → admin モードでも通常モードでも同じ動作

p2:
  implementation:
    init_guard_sh:
      added_lines: "21-32"
      grep_result: "SECURITY_MODE が 3 箇所で参照されている（行24, 26, 30）"
      behavior: "admin モードで exit 0（バイパス）"
    playbook_guard_sh:
      added_lines: "38-46"
      grep_result: "SECURITY_MODE が 2 箇所で参照されている（行41, 44）"
      behavior: "admin モードで exit 0（バイパス）"
  test:
    admin_mode:
      security_mode_set: admin
      init_guard_result: "バイパス (exit 0)"
      playbook_guard_result: "バイパス (exit 0)"
      evidence: "この playbook 自体の編集が成功していることが証拠"
    strict_mode:
      security_mode_set: strict
      init_guard_result: "ブロック継続 (admin でないため)"
      playbook_guard_result: "playbook チェック継続 (admin でないため)"
      evidence: |
        /tmp/test-security-mode.sh でシミュレーション実行:
        - strict モードで SECURITY_MODE='strict' を取得
        - admin チェックが false → ブロック継続のパスに入る
        - admin モードに戻すと SECURITY_MODE='admin' → バイパス
p3:
  implementation:
    file: init-guard.sh
    modified_lines: "50-63"
    change: |
      playbook ファイルの存在確認を追加。
      存在しない場合は REQUIRED_FILES に追加しない。
      警告メッセージを stderr に出力。
  test:
    non_existent_playbook:
      input: "plan/active/non-existent-playbook.md"
      result: "REQUIRED_FILES: state.md のみ（playbook 除外）"
      conclusion: "デッドロック回避成功"
    existing_playbook:
      input: "plan/active/playbook-repository-refinement.md"
      result: "REQUIRED_FILES: state.md + playbook"
      conclusion: "正常動作（存在する playbook は含まれる）"
  fallback_mechanism:
    condition: "playbook ファイルが存在しない"
    behavior: "REQUIRED_FILES から除外 + 警告表示"
    message: "⚠️ playbook ファイルが存在しません → 必須 Read 対象から除外"
p4:
  deleted_hooks:
    - check-manifest-sync.sh: "削除 - spec.yaml 廃止済みのため不要"
    - check-playbook-quality.sh: "削除 - 現在の playbook フォーマット（V10）と不一致、critic で代替"
    - check-state-update.sh: "削除 - 自動コミットで state.md は常に更新される"
  verification:
    settings_json_count: 19
    hooks_dir_count: 19
    match: true
  registered_hooks:
    - archive-playbook.sh
    - check-coherence.sh
    - check-file-dependencies.sh
    - check-main-branch.sh
    - check-protected-edit.sh
    - consent-guard.sh
    - critic-guard.sh
    - depends-check.sh
    - executor-guard.sh
    - init-guard.sh
    - lint-check.sh
    - log-subagent.sh
    - playbook-guard.sh
    - pre-bash-check.sh
    - prompt-guard.sh
    - scope-guard.sh
    - session-end.sh
    - session-start.sh
    - stop-summary.sh
p5:
  action: frontmatter 追加（4件）
  updated_skills:
    - deploy-checker: "frontmatter 追加（name, description）"
    - frontend-design: "frontmatter 追加（name, description）"
    - lint-checker: "frontmatter 追加（name, description）"
    - test-runner: "frontmatter 追加（name, description）"
  verification:
    total_skills: 9
    with_frontmatter: 9
    all_start_with_delimiter: true
  complete_list:
    - context-management
    - deploy-checker
    - execution-management
    - frontend-design
    - learning
    - lint-checker
    - plan-management
    - state
    - test-runner
p6:
  verification_summary:
    p2_security_mode:
      implemented: true
      test_result: "admin モードで Edit/Write がバイパスされている（本 playbook 編集が成功）"
    p3_deadlock_fix:
      implemented: true
      test_result: "init-guard.sh に存在確認追加、非存在 playbook は REQUIRED_FILES から除外"
    p4_hooks_sync:
      implemented: true
      test_result: "settings.json: 19, .claude/hooks/: 19, 完全一致"
    p5_skills_frontmatter:
      implemented: true
      test_result: "全 9 Skills に frontmatter 存在"
  session_check:
    current_session_errors: 0
    admin_mode_bypass: "confirmed (Edit/Write 許可)"
    hooks_firing: "confirmed (init-guard, playbook-guard, critic-guard 等)"
  goal_achievement:
    security_mode_referenced: true
    unregistered_hooks_processed: true
    incomplete_skills_processed: true
    init_guard_deadlock_fixed: true
```

---

## known_issues

```yaml
- claude_code_behavior: |
    Claude Code が存在しないファイルの Read で PreToolUse Hook を実行しない可能性。
    これは Claude Code 側の仕様であり、Hook 側での対応が必要。
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | 初版作成。security.mode 無視問題、init-guard デッドロック、未登録 Hooks、不完全 Skills。 |
