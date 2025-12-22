# playbook-auto-merge-workflow.md

> **post_loop workflow で PR 作成後に自動マージまで実行する改修**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/auto-merge-workflow
created: 2025-12-22
issue: null
derives_from: null  # 新規機能追加
reviewed: true
roles:
  worker: claudecode  # シェルスクリプト修正のため claudecode
```

---

## goal

```yaml
summary: |
  playbook 完了時に PR 作成からマージ、main push までが自動で一連実行されるようにする
done_when:
  - create-pr-hook.sh が PR 作成後に merge-pr.sh を自動呼び出しする
  - PR 作成 -> マージ -> main checkout -> pull が一連のフローで実行される
  - マージ失敗時（コンフリクト等）は適切なエラーメッセージを表示して停止する
```

---

## phases

### p1: 現状分析と設計

**goal**: 現在の PR 作成・マージフローを理解し、統合設計を行う

#### subtasks

- [x] **p1.1**: create-pr-hook.sh の処理フローが理解されている
  - executor: claudecode
  - validations:
    - technical: "スクリプトの各セクション（前提条件チェック、playbook 完了チェック、PR 作成）が特定されている"
    - consistency: "create-pr.sh との関係が明確である"
    - completeness: "exit code と分岐条件が全て理解されている"

- [x] **p1.2**: merge-pr.sh の処理フローが理解されている
  - executor: claudecode
  - validations:
    - technical: "スクリプトの各セクション（PR 情報取得、ステータスチェック、マージ実行）が特定されている"
    - consistency: "state.md 更新処理が理解されている"
    - completeness: "exit code とエラーケースが全て理解されている"

- [x] **p1.3**: 統合フローの設計が決定されている
  - executor: claudecode
  - validations:
    - technical: "create-pr-hook.sh -> create-pr.sh -> merge-pr.sh の呼び出しチェーンが設計されている"
    - consistency: "既存の処理を壊さない設計である"
    - completeness: "エラーハンドリング方針が決定されている"

**status**: done
**max_iterations**: 3

---

### p2: create-pr-hook.sh 改修

**goal**: PR 作成後に merge-pr.sh を自動呼び出しするように改修

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: create-pr-hook.sh に merge-pr.sh 呼び出しが追加されている
  - executor: claudecode
  - validations:
    - technical: "bash -n でシンタックスエラーがない"
    - consistency: "既存の PR 作成処理が正常に動作する"
    - completeness: "PR 作成成功後にのみマージが呼び出される"

- [x] **p2.2**: PR 作成の成功/失敗を正しく判定している
  - executor: claudecode
  - validations:
    - technical: "create-pr.sh の exit code を正しくハンドリングしている"
    - consistency: "exit 2（スキップ）の場合はマージをスキップする"
    - completeness: "exit 1（エラー）の場合は処理を停止する"

- [x] **p2.3**: マージ失敗時のエラーハンドリングが実装されている
  - executor: claudecode
  - validations:
    - technical: "merge-pr.sh の exit code を正しくハンドリングしている"
    - consistency: "エラーメッセージが一貫している"
    - completeness: "ユーザーが次のアクションを理解できる"

**status**: done
**max_iterations**: 5

---

### p3: 動作検証

**goal**: 改修後の一連のフローが正常に動作することを確認

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: bash -n で create-pr-hook.sh にシンタックスエラーがない
  - executor: claudecode
  - validations:
    - technical: "bash -n .claude/hooks/create-pr-hook.sh が exit 0"
    - consistency: "他のスクリプト（create-pr.sh, merge-pr.sh）もエラーなし"
    - completeness: "依存ライブラリ（lib/common.sh 等）も問題なし"

- [x] **p3.2**: スクリプトのヘルプコメントが更新されている
  - executor: claudecode
  - validations:
    - technical: "スクリプト冒頭のコメントが新しい動作を反映している"
    - consistency: "他のドキュメント（docs/hook-responsibilities.md 等）との整合性"
    - completeness: "新しい機能（自動マージ）が説明されている"

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p3]

#### subtasks

- [x] **p_final.1**: create-pr-hook.sh が PR 作成後に merge-pr.sh を自動呼び出しする
  - executor: claudecode
  - validations:
    - technical: "grep で merge-pr.sh 呼び出しコードが存在することを確認"
    - consistency: "呼び出し順序が create-pr.sh の後である"
    - completeness: "条件分岐（成功時のみ呼び出し）が実装されている"

- [x] **p_final.2**: PR 作成 -> マージ -> main checkout -> pull が一連のフローで実行される
  - executor: claudecode
  - validations:
    - technical: "merge-pr.sh 内の git checkout/pull 処理が確認できる"
    - consistency: "create-pr-hook.sh からの呼び出しチェーンが完成している"
    - completeness: "state.md リセット処理も含まれている"

- [x] **p_final.3**: マージ失敗時（コンフリクト等）は適切なエラーメッセージを表示して停止する
  - executor: claudecode
  - validations:
    - technical: "merge-pr.sh のエラーハンドリングコードが存在する"
    - consistency: "create-pr-hook.sh がエラーを伝播する"
    - completeness: "ユーザーへのガイダンスメッセージが含まれている"

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: done

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-22 | 初版作成 |
| 2025-12-22 | 全 Phase 完了、自動マージ機能実装 |
