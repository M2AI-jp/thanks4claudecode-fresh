# playbook-fix-post-loop-order.md

## meta

```yaml
project: fix-post-loop-order
branch: fix/post-loop-order
created: 2026-01-03
issue: null
reviewed: true
```

---

## goal

```yaml
summary: post-loop 処理順序バグを修正し、playbook 完了後のアーカイブコミットが正常に動作するようにする
done_when:
  - archive-playbook.sh で state.md 更新が全コミット後に実行される
  - post-loop/SKILL.md の手順が明確で整合性がある
```

---

## context

```yaml
5w1h:
  who: Claude Code ユーザー（playbook 完了時にアーカイブが失敗する）
  what: post-loop 処理の順序バグを修正
  when: 今回のセッションで完了
  where: archive-playbook.sh, post-loop/SKILL.md
  why: playbook 完了後、state.md を null にした後にコミットしようとすると playbook-guard でブロックされる可能性がある
  how: 処理順序を修正（コミット/プッシュを state.md 更新より先に実行）

analysis_result:
  source: prompt-analyzer
  timestamp: 2026-01-03T16:45:00Z
  data:
    root_cause: |
      archive-playbook.sh の Step 5 で state.md を更新（playbook.active = null）し、
      Step 6 でアーカイブコミットを行う。
      この順序では、bash-check.sh は git 操作を許可するが、
      Claude が手動で操作する場合に混乱が生じる可能性がある。

    proposed_fix: |
      1. archive-playbook.sh の処理順序を変更:
         - Step 4: アーカイブ
         - Step 5: アーカイブコミット（state.md 更新前）
         - Step 6: Push
         - Step 7: state.md 更新（全コミット後）
         - Step 8: state.md 更新のコミット
         - Step 9: Push
         - Step 10: PR マージ
         - Step 11: main 同期
         - Step 12: pending ファイル作成

      2. post-loop/SKILL.md の手順を明確化

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-03T16:50:00Z
  summary: ユーザーが「この理解で playbook を作成してください」と承認
```

---

## phases

### p1: archive-playbook.sh の処理順序修正

**goal**: state.md 更新を全コミット後に移動し、処理順序を最適化する

#### subtasks

- [x] **p1.1**: archive-playbook.sh の Step 4-7 が「アーカイブ → コミット → Push → state.md 更新」の順序になっている
  - executor: codex
  - validations:
    - technical: "PASS - Step 4:アーカイブ→Step 5:コミット→Step 6:Push→Step 7:state.md更新 の順序を確認"
    - consistency: "PASS - Step 4-9 が連番で処理内容と整合"
    - completeness: "PASS - Step 4-12 まで全て定義されている"
  - validated: 2026-01-03T17:00:00Z

- [x] **p1.2**: bash -n archive-playbook.sh がエラーなしで終了する
  - executor: claudecode
  - validations:
    - technical: "PASS - bash -n 実行結果: exit 0, エラーなし"
    - consistency: "PASS - 変数定義と使用箇所の整合性確認済み"
    - completeness: "PASS - Step 1-12 の全処理パスが定義されている"
  - validated: 2026-01-03T17:00:00Z

**status**: done
**max_iterations**: 5

---

### p2: post-loop/SKILL.md の手順明確化

**goal**: post-loop Skill の手順を archive-playbook.sh と整合させる

#### subtasks

- [x] **p2.1**: post-loop/SKILL.md の「自動化フロー」セクションが archive-playbook.sh の実際の処理順序と一致している
  - executor: codex
  - validations:
    - technical: "PASS - Step 1-12 の処理順序が archive-playbook.sh と一致"
    - consistency: "PASS - 前提条件セクションと自動化フローセクションを更新済み"
    - completeness: "PASS - 全 Step（1-12）が記載されている"
  - validated: 2026-01-03T17:00:00Z

**status**: done
**depends_on**: [p1]

---

### p_final: 完了検証

**goal**: done_when が全て満たされているか最終検証

#### subtasks

- [x] **p_final.1**: archive-playbook.sh で state.md 更新が全コミット後に実行されることを確認
  - executor: claudecode
  - validations:
    - technical: "PASS - Step 5(line 360):アーカイブコミット→Step 7(line 384):state.md更新→Step 8(line 416):state.mdコミット"
    - consistency: "PASS - Step 番号と行番号が一致し、コメントと処理内容が整合"
    - completeness: "PASS - state.md 更新(Step 7)がアーカイブコミット(Step 5)の後に実行される"
  - validated: 2026-01-03T17:05:00Z

- [x] **p_final.2**: post-loop/SKILL.md の手順が明確で整合性があることを確認
  - executor: claudecode
  - validations:
    - technical: "PASS - SKILL.md に Step 1-12 が明記されている（line 92-116）"
    - consistency: "PASS - archive-playbook.sh の処理順序と完全一致"
    - completeness: "PASS - 全 Step（1-2, 3, 4-6, 7-9, 10-11, 12）がカバーされている"
  - validated: 2026-01-03T17:05:00Z

**status**: done
**depends_on**: [p1, p2]

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: done

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done
