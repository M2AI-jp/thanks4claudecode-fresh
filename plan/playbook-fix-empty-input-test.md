# playbook-fix-empty-input-test.md

> **単純なテストケース修正**

---

## meta

```yaml
project: fix-empty-input-test
branch: feat/multi-language-orchestration-demo  # 既存ブランチで作業
created: 2026-01-02
issue: null
reviewed: true  # 単純なバグ修正のためスキップ
roles:
  worker: claudecode  # テストコード修正のみ
```

---

## goal

```yaml
summary: tests/tmp-run.bats の空入力テストの期待値を修正する
done_when:
  - テスト名が "run.sh with empty input fails gracefully" に変更されている
  - テストが exit code != 0 を検証している
  - bats テストが全て PASS する
```

---

## context

```yaml
5w1h:
  who: 開発者
  what: 空入力テストの期待値修正
  when: 即時
  where: tests/tmp-run.bats
  why: 実際の動作（空入力でエラー終了）とテスト期待値が不一致
  how: テスト名とアサーションを修正

analysis_result:
  source: user-provided
  timestamp: 2026-01-02T10:00:00Z
  data:
    実際の動作: 空入力は Python で "Empty input received" エラー（exit 1）
    現在の期待値: .python_output.original.input == "default"（誤り）
    修正内容: exit code != 0 を検証

user_approved_understanding:
  source: user-direct
  approved_at: 2026-01-02T10:00:00Z
  summary: ユーザーが修正内容を明示的に指定
```

---

## phases

### p1: テスト修正

**goal**: 空入力テストの期待値を修正する

#### subtasks

- [x] **p1.1**: テスト名が "run.sh with empty input fails gracefully" に変更されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で新しいテスト名が存在することを確認"
    - consistency: "PASS - 他のエラーケーステストと命名規則が一致"
    - completeness: "PASS - 旧テスト名が残っていないこと"
  - validated: 2026-01-02T10:15:00Z

- [x] **p1.2**: テストが exit code != 0 を検証している
  - executor: claudecode
  - validations:
    - technical: "PASS - run コマンドと status 変数を使用していること"
    - consistency: "PASS - 他のエラーテスト（invalid JSON）と同様のパターン"
    - completeness: "PASS - 不要なアサーションが削除されていること"
  - validated: 2026-01-02T10:15:00Z

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: 修正後のテストが全て PASS することを確認

**depends_on**: [p1]

#### subtasks

- [x] **p_final.1**: bats テストが全て PASS する
  - executor: claudecode
  - validations:
    - technical: "PASS - bats tests/tmp-run.bats を実行して全 11 テスト PASS"
    - consistency: "PASS - 他のテストに影響がないこと"
    - completeness: "PASS - 空入力テストが正しく動作すること"
  - validated: 2026-01-02T10:15:00Z

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: 変更をコミットする
  - command: `git add -A && git commit -m "fix(tests): update empty input test expectation"`
  - status: done
  - executed: 2026-01-02T10:15:00Z
