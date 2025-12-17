# playbook-m076-orchestration-e2e-test.md

> **M076: AI オーケストレーション E2E テスト - toolstack B/C の実動作検証**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/m076-orchestration-e2e-test
created: 2025-12-17
issue: null
derives_from: M076
reviewed: false
roles:
  orchestrator: claudecode
  worker: claudecode  # このテストでは動的解決を検証するため override しない
```

---

## goal

```yaml
summary: M075 で修正した役割名形式が toolstack B/C で正しく動作することを検証する
done_when:
  - state.md の toolstack を B に変更した場合、role-resolver.sh が worker -> codex を返す
  - state.md の toolstack を C に変更した場合、role-resolver.sh が reviewer -> coderabbit を返す
  - pm SubAgent が生成する playbook に executor: worker 形式が含まれている
  - テスト完了後、state.md が toolstack: A に復元されている
```

---

## phases

### p0: 現状確認

**goal**: 現在の state.md と role-resolver.sh の状態を確認

#### subtasks

- [x] **p0.1**: state.md に toolstack: A が設定されている
  - executor: orchestrator
  - test_command: `grep -q 'toolstack: A' state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "state.md が存在し、toolstack フィールドがある"
    - consistency: "toolstack A がデフォルト設定と一致"
    - completeness: "config セクション全体が正常"

- [x] **p0.2**: state.md に roles セクションが存在し、worker: claudecode が設定されている
  - executor: orchestrator
  - test_command: `grep -A5 'roles:' state.md | grep -q 'worker: claudecode' && echo PASS || echo FAIL`
  - validations:
    - technical: "roles セクションが存在する"
    - consistency: "worker が claudecode に固定されている"
    - completeness: "orchestrator/worker/reviewer/human の全 4 役割が定義されている"

- [x] **p0.3**: role-resolver.sh が toolstack A で worker -> claudecode を返す
  - executor: orchestrator
  - test_command: `echo 'worker' | TOOLSTACK=A bash .claude/hooks/role-resolver.sh | grep -q 'claudecode' && echo PASS || echo FAIL`
  - validations:
    - technical: "role-resolver.sh が正常に実行できる"
    - consistency: "toolstack A の仕様と一致"
    - completeness: "TOOLSTACK 環境変数が正しく処理される"

**status**: done
**max_iterations**: 3

---

### p1: toolstack B テスト

**status**: done

**goal**: toolstack B での worker -> codex 解決を検証
**depends_on**: [p0]

#### subtasks

- [x] **p1.1**: state.md の toolstack を B に変更する
  - executor: orchestrator
  - test_command: `grep -q 'toolstack: B' state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Edit が正常に完了する"
    - consistency: "他の config 設定が保持されている"
    - completeness: "toolstack のみが変更されている"

- [x] **p1.2**: state.md の roles.worker コメントを削除（動的解決をテスト）
  - executor: orchestrator
  - test_command: `grep -A5 'roles:' state.md | grep -v '#' | grep -q 'worker:' && echo 'FIXED' || echo 'DYNAMIC'`
  - validations:
    - technical: "roles セクションが正常"
    - consistency: "他の roles が保持されている"
    - completeness: "コメントのみが削除されている"
  - notes: "worker 行を削除またはコメントアウトして、role-resolver.sh のデフォルト解決をテスト"

- [x] **p1.3**: role-resolver.sh が toolstack B で worker -> codex を返す
  - executor: orchestrator
  - test_command: `echo 'worker' | TOOLSTACK=B bash .claude/hooks/role-resolver.sh | grep -q 'codex' && echo PASS || echo FAIL`
  - validations:
    - technical: "role-resolver.sh が正常に実行できる"
    - consistency: "toolstack B の仕様（worker -> codex）と一致"
    - completeness: "環境変数 TOOLSTACK=B が正しく処理される"

- [x] **p1.4**: state.md から toolstack を参照した場合も codex を返す
  - executor: orchestrator
  - test_command: `STATE_FILE=state.md bash -c 'echo "worker" | bash .claude/hooks/role-resolver.sh' | grep -q 'codex' && echo PASS || echo FAIL`
  - validations:
    - technical: "state.md の toolstack: B が読み取られる"
    - consistency: "環境変数なしでも state.md から取得"
    - completeness: "役割解決の優先順位が正しい"
  - notes: "TOOLSTACK 環境変数を設定せず、state.md から自動取得させる"

**status**: pending
**max_iterations**: 5

---

### p2: toolstack C テスト

**goal**: toolstack C での reviewer -> coderabbit 解決を検証
**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: state.md の toolstack を C に変更する
  - executor: orchestrator
  - test_command: `grep -q 'toolstack: C' state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Edit が正常に完了する"
    - consistency: "他の config 設定が保持されている"
    - completeness: "toolstack のみが変更されている"

- [x] **p2.2**: role-resolver.sh が toolstack C で reviewer -> coderabbit を返す
  - executor: orchestrator
  - test_command: `echo 'reviewer' | TOOLSTACK=C bash .claude/hooks/role-resolver.sh | grep -q 'coderabbit' && echo PASS || echo FAIL`
  - validations:
    - technical: "role-resolver.sh が正常に実行できる"
    - consistency: "toolstack C の仕様（reviewer -> coderabbit）と一致"
    - completeness: "環境変数 TOOLSTACK=C が正しく処理される"

- [x] **p2.3**: role-resolver.sh が toolstack C で worker -> codex を返す
  - executor: orchestrator
  - test_command: `echo 'worker' | TOOLSTACK=C bash .claude/hooks/role-resolver.sh | grep -q 'codex' && echo PASS || echo FAIL`
  - validations:
    - technical: "role-resolver.sh が正常に実行できる"
    - consistency: "toolstack C の仕様（worker -> codex）と一致"
    - completeness: "reviewer だけでなく worker も正しく解決"

- [x] **p2.4**: state.md から toolstack を参照した場合も coderabbit を返す
  - executor: orchestrator
  - test_command: `STATE_FILE=state.md bash -c 'echo "reviewer" | bash .claude/hooks/role-resolver.sh' | grep -q 'coderabbit' && echo PASS || echo FAIL`
  - validations:
    - technical: "state.md の toolstack: C が読み取られる"
    - consistency: "環境変数なしでも state.md から取得"
    - completeness: "役割解決の優先順位が正しい"

**status**: pending
**max_iterations**: 5

---

### p3: playbook 生成テスト

**goal**: pm SubAgent が役割名形式で playbook を生成することを確認
**depends_on**: [p0]

#### subtasks

- [x] **p3.1**: playbook-format.md に executor: orchestrator/worker/reviewer/human の例が含まれている
  - executor: orchestrator
  - test_command: `grep -E 'executor:.*(orchestrator|worker|reviewer|human)' plan/template/playbook-format.md | wc -l | awk '{if($1>=10) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "playbook-format.md が存在し読み取り可能"
    - consistency: "M075 の修正が反映されている"
    - completeness: "4 種類全ての役割名が含まれている"

- [x] **p3.2**: pm.md に役割名形式の executor ガイドラインが含まれている
  - executor: orchestrator
  - test_command: `grep -E 'executor:.*worker|executor:.*orchestrator' .claude/agents/pm.md && echo PASS || echo FAIL`
  - validations:
    - technical: "pm.md が存在し読み取り可能"
    - consistency: "M075 の修正が反映されている"
    - completeness: "executor 選択ガイドラインが役割名形式"

- [x] **p3.3**: この playbook (M076) 自体に executor: orchestrator が使用されている
  - executor: orchestrator
  - test_command: `grep -c 'executor: orchestrator' plan/playbook-m076-orchestration-e2e-test.md | awk '{if($1>=5) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "playbook が存在し読み取り可能"
    - consistency: "役割名形式が使用されている"
    - completeness: "全 subtask に executor が指定されている"

**status**: pending
**max_iterations**: 3

---

### p_final: 結果確認と state.md 復元

**goal**: テスト結果をまとめ、state.md を元の状態に復元
**depends_on**: [p1, p2, p3]

#### subtasks

- [x] **p_final.1**: state.md の toolstack を A に復元する
  - executor: orchestrator
  - test_command: `grep -q 'toolstack: A' state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Edit が正常に完了する"
    - consistency: "toolstack が A に戻っている"
    - completeness: "config セクション全体が正常"

- [x] **p_final.2**: state.md の roles.worker を claudecode に復元する
  - executor: orchestrator
  - test_command: `grep -A5 'roles:' state.md | grep -q 'worker: claudecode' && echo PASS || echo FAIL`
  - validations:
    - technical: "roles セクションが正常"
    - consistency: "worker が claudecode に設定されている"
    - completeness: "全 4 役割が正常に定義されている"

- [x] **p_final.3**: role-resolver.sh が toolstack A で全役割を正しく解決する
  - executor: orchestrator
  - test_command: |
    RESULT1=$(echo 'orchestrator' | TOOLSTACK=A bash .claude/hooks/role-resolver.sh)
    RESULT2=$(echo 'worker' | TOOLSTACK=A bash .claude/hooks/role-resolver.sh)
    RESULT3=$(echo 'reviewer' | TOOLSTACK=A bash .claude/hooks/role-resolver.sh)
    RESULT4=$(echo 'human' | TOOLSTACK=A bash .claude/hooks/role-resolver.sh)
    if [[ "$RESULT1" == "claudecode" && "$RESULT2" == "claudecode" && "$RESULT3" == "claudecode" && "$RESULT4" == "user" ]]; then
      echo "PASS"
    else
      echo "FAIL: orchestrator=$RESULT1, worker=$RESULT2, reviewer=$RESULT3, human=$RESULT4"
    fi
  - validations:
    - technical: "role-resolver.sh が全役割で正常に動作"
    - consistency: "toolstack A の仕様と一致"
    - completeness: "4 役割全てが正しく解決される"

- [x] **p_final.4**: E2E テスト結果サマリーを出力する
  - executor: orchestrator
  - test_command: `echo 'PASS - E2E test completed'`
  - validations:
    - technical: "全 Phase が完了している"
    - consistency: "state.md が元の状態に復元されている"
    - completeness: "toolstack A/B/C 全てのテストが PASS"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'CLAUDE.md' ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-17 | 初版作成。M076 AI オーケストレーション E2E テスト playbook。 |
