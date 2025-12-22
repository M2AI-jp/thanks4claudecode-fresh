# playbook-test-strengthening.md

> **repository-map ワークフローのテスト強化**
>
> 既存テストの「ザル」状態を解消し、厳格なアサーションに置き換える。

---

## meta

```yaml
project: thanks4claudecode
branch: feat/test-strengthening
created: 2025-12-23
issue: null
derives_from: M082  # テスト強化（新規マイルストーン）
reviewed: true  # 2025-12-23 reviewer PASS
roles:
  worker: claudecode  # テストコード修正は claudecode で実行
```

---

## goal

```yaml
summary: 既存テストの弱いアサーションを厳格化し、repository-map ワークフローの状態遷移 E2E テストを強化
done_when:
  - 既存テストのフォールバック else パターンが全て明示的な fail に置き換えられている
  - exit code を条件としない「処理された」パターンが削除されている
  - 各テストが明確な期待値を持ち、それ以外は FAIL する
  - bash scripts/test-workflows.sh が全テスト PASS で終了する
```

---

## phases

### p1: 問題箇所の特定と分類

**goal**: test-workflows.sh の弱いアサーションを全て特定し、修正計画を立てる

#### subtasks

- [ ] **p1.1**: フォールバック else パターン（何でも PASS）が全て列挙されている
  - executor: claudecode
  - validations:
    - technical: "grep -n 'else.*test_pass' scripts/test-workflows.sh で該当行を特定"
    - consistency: "各パターンの問題点が明確に説明されている"
    - completeness: "全てのフォールバック else が列挙されている"

- [ ] **p1.2**: exit code 無視パターン（どちらでも OK）が全て列挙されている
  - executor: claudecode
  - validations:
    - technical: "grep -n 'processed.*exit=' scripts/test-workflows.sh で該当行を特定"
    - consistency: "各パターンで期待される正しい exit code が特定されている"
    - completeness: "全ての exit code 無視パターンが列挙されている"

- [ ] **p1.3**: 修正計画が docs/test-strengthening-plan.md に作成されている
  - executor: claudecode
  - validations:
    - technical: "修正対象の行番号、現在のコード、修正後のコードが明示されている"
    - consistency: "修正により既存の正常ケースが壊れないことが説明されている"
    - completeness: "全ての問題箇所に対する修正計画がある"

**status**: pending
**max_iterations**: 3

---

### p2: フォールバック else の厳格化

**goal**: 何でも PASS するフォールバックを明示的な FAIL に置き換える
**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: check-main-branch.sh テストのフォールバックが削除されている
  - executor: claudecode
  - validations:
    - technical: "414-420 行の else ブロックが test_fail に変更されている"
    - consistency: "main ブランチで Edit がブロックされる期待動作が明確"
    - completeness: "workspace/setup/Read/git checkout の 4 テスト全て修正済み"

- [ ] **p2.2**: executor-guard.sh テストのフォールバックが削除されている
  - executor: claudecode
  - validations:
    - technical: "604-609, 649, 684, 711-712, 739 行が修正されている"
    - consistency: "各 toolstack/executor の期待動作が明確"
    - completeness: "codex/claudecode/user/Toolstack A 全パターン修正済み"

- [ ] **p2.3**: archive-playbook.sh テストのフォールバックが削除されている
  - executor: claudecode
  - validations:
    - technical: "963 行の else ブロックが test_fail に変更されている"
    - consistency: "完了検出の期待出力が明確"
    - completeness: "完了/未完了両パターン修正済み"

**status**: pending
**max_iterations**: 5

---

### p3: exit code 検証の厳格化

**goal**: 「処理された」という曖昧な判定を明確な exit code チェックに置き換える
**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: 全てのテストが期待する exit code を明示的にチェックしている
  - executor: claudecode
  - validations:
    - technical: "run_hook_test 関数で期待 exit code を必ず指定"
    - consistency: "Hook の仕様と一致する exit code を指定"
    - completeness: "run_hook_safe を使う場合も exit code チェックを追加"

- [ ] **p3.2**: exit code と出力メッセージの両方を検証するヘルパー関数が存在する
  - executor: claudecode
  - validations:
    - technical: "run_hook_test_with_output 関数が期待 exit code と出力パターンを検証"
    - consistency: "既存の run_hook_test との互換性がある"
    - completeness: "stdout と stderr 両方を検証可能"

- [ ] **p3.3**: critic-guard.sh テストが exit code と出力両方を検証している
  - executor: claudecode
  - validations:
    - technical: "770, 922 行が明確な exit code と出力チェックを持つ"
    - consistency: "subtask 変更検出の期待動作と一致"
    - completeness: "PASS/FAIL 両パターンをカバー"

**status**: pending
**max_iterations**: 5

---

### p4: キーワード検索の実質検証化

**goal**: grep によるキーワード存在確認を実際の動作検証に置き換える
**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: CRITIQUE 3-point validation テストが実際の検証を行っている
  - executor: claudecode
  - validations:
    - technical: "830-919 行のテストが Hook 実行と出力検証を行う"
    - consistency: "technical/consistency/completeness の検証が実際に動作"
    - completeness: "単独検証と 3 点同時検証両方をカバー"

- [ ] **p4.2**: playbook ファイル作成後に Hook を実行して動作を確認している
  - executor: claudecode
  - validations:
    - technical: "playbook 作成 -> critic-guard.sh 実行 -> 出力検証の流れ"
    - consistency: "V12 チェックボックス形式と整合"
    - completeness: "全 validation タイプで Hook 実行を確認"

**status**: pending
**max_iterations**: 3

---

### p5: repository-map ワークフロー状態遷移テスト

**goal**: repository-map の更新を含むワークフロー全体の状態遷移をテスト
**depends_on**: [p4]

#### subtasks

- [ ] **p5.1**: generate-repository-map.sh の入出力テストが存在する
  - executor: claudecode
  - validations:
    - technical: "テスト環境で generate-repository-map.sh を実行し、yaml 出力を検証"
    - consistency: "repository-map.yaml のスキーマと一致"
    - completeness: "hooks/agents/skills/commands 全セクションを検証"

- [ ] **p5.2**: playbook 完了 -> repository-map 更新のフローがテストされている
  - executor: claudecode
  - validations:
    - technical: "final_tasks の ft1 が generate-repository-map.sh を呼ぶテスト"
    - consistency: "archive-playbook.sh との連携を確認"
    - completeness: "更新前後の yaml 差分を検証"

- [ ] **p5.3**: 全テストが PASS することを確認
  - executor: claudecode
  - validations:
    - technical: "bash scripts/test-workflows.sh が exit 0 で終了"
    - consistency: "修正前より厳格になっている（FAIL 検出力が向上）"
    - completeness: "回帰がなく全テスト PASS"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

#### subtasks

- [ ] **p_final.1**: フォールバック else パターンが 0 件になっている
  - executor: claudecode
  - validations:
    - technical: "grep -c 'else.*test_pass.*processed\\|else.*test_pass.*exit=' scripts/test-workflows.sh が 0 を返す"
    - consistency: "全ての else ブロックが明示的な期待値を持つ"
    - completeness: "新規追加テストにもフォールバックがない"

- [ ] **p_final.2**: exit code を条件としない「処理された」パターンが 0 件になっている
  - executor: claudecode
  - validations:
    - technical: "grep -c 'processed.*exit=' scripts/test-workflows.sh が 0 または明示的な期待値付きのみ"
    - consistency: "全テストが期待 exit code を明示"
    - completeness: "曖昧な判定が排除されている"

- [ ] **p_final.3**: 全テストが PASS する
  - executor: claudecode
  - validations:
    - technical: "bash scripts/test-workflows.sh が exit 0 で終了"
    - consistency: "55 テスト以上が実行される"
    - completeness: "FAIL が 0 件"

- [ ] **p_final.4**: テストの厳格性が向上している
  - executor: claudecode
  - validations:
    - technical: "意図的に Hook を壊したときに FAIL を検出できる"
    - consistency: "修正前のザル状態では PASS していたケースが FAIL になる"
    - completeness: "偽陽性（実際は壊れているが PASS）が減少"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 技術的アプローチ

```yaml
問題パターンと修正方針:

1. フォールバック else（何でも PASS）:
   現状: if [条件]; then test_pass; else test_pass "processed" fi
   修正: if [条件]; then test_pass; else test_fail "期待外れの結果" fi

2. exit code 無視:
   現状: run_hook_safe ... ; test_pass "processed (exit=$HOOK_EXIT)"
   修正: run_hook_test ... 0 "期待通り許可" または
         run_hook_test ... 2 "期待通りブロック"

3. キーワード存在だけ確認:
   現状: grep -q "keyword" file && test_pass
   修正: Hook を実行して出力を検証

4. 厳格性検証:
   - 意図的に Hook を壊す（exit code を変える等）
   - 修正後のテストが FAIL を検出することを確認
   - 修正前のテストでは PASS だったことを示す
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-23 | 初版作成。テスト強化 playbook。 |
