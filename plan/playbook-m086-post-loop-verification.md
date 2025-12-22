# playbook-m086-post-loop-verification.md

> **post_loop workflow の E2E 検証・修正**

---

## meta

```yaml
project: M086 post_loop workflow 検証
branch: feat/m086-post-loop-verification
created: 2025-12-22
issue: null
derives_from: M083
reviewed: true  # 2025-12-22 reviewer PASS
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: post_loop workflow（playbook 完了時の自動処理）が正しく動作することを検証・修正する
done_when:
  - PostToolUse:Edit で archive-playbook.sh が正しく発火している
  - archive-playbook.sh が playbook 完了を正しく検知している
  - cleanup-hook.sh が tmp/ クリーンアップを正しく実行している
  - create-pr-hook.sh が PR 作成トリガーを正しく発火している
  - E2E テストシナリオで全 Hook が期待通り動作することが確認されている
```

---

## phases

### p1: 現状分析 - PostToolUse:Edit 発火確認

**goal**: PostToolUse:Edit で post_loop 関連 Hook が発火しているか確認

#### subtasks

- [ ] **p1.1**: settings.json の PostToolUse:Edit に archive-playbook.sh, cleanup-hook.sh, create-pr-hook.sh が登録されている
  - executor: claudecode
  - validations:
    - technical: "grep で settings.json の PostToolUse:Edit セクションを確認"
    - consistency: "3 つの Hook が全て登録されているか確認"
    - completeness: "登録順序と timeout 設定が適切か確認"

- [ ] **p1.2**: 各 Hook スクリプトが存在し、実行可能である
  - executor: claudecode
  - validations:
    - technical: "test -x で各スクリプトの存在と実行権限を確認"
    - consistency: "bash -n で構文エラーがないか確認"
    - completeness: "3 つ全てのスクリプトが確認されている"

- [ ] **p1.3**: 各 Hook スクリプトが playbook ファイル編集時にのみ発火するフィルタを持っている
  - executor: claudecode
  - validations:
    - technical: "grep で 'playbook' フィルタの存在を確認"
    - consistency: "フィルタロジックが一貫しているか確認"
    - completeness: "3 つ全てのスクリプトでフィルタが確認されている"

**status**: pending
**max_iterations**: 5

---

### p2: archive-playbook.sh 検証

**goal**: archive-playbook.sh の playbook 完了検知ロジックを検証

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: archive-playbook.sh が全 Phase done の playbook を正しく検知する
  - executor: claudecode
  - validations:
    - technical: "テスト playbook を作成し、Phase 状態変更時の出力を確認"
    - consistency: "検知ロジックが playbook-format.md の Phase 形式と一致している"
    - completeness: "done, pending, in_progress の各状態でテスト済み"

- [ ] **p2.2**: V12 チェックボックス形式（`- [x]` / `- [ ]`）の完了判定が正しく動作する
  - executor: claudecode
  - validations:
    - technical: "チェックボックスカウントロジックをテスト"
    - consistency: "V12 形式の playbook で正しくカウントされる"
    - completeness: "完了/未完了の両ケースでテスト済み"

- [ ] **p2.3**: p_final フェーズの完了チェックが正しく動作する
  - executor: claudecode
  - validations:
    - technical: "p_final セクションの検知と status チェックをテスト"
    - consistency: "p_final が存在しない場合の警告が適切"
    - completeness: "p_final done/pending の両ケースでテスト済み"

- [ ] **p2.4**: final_tasks チェックが正しく動作する
  - executor: claudecode
  - validations:
    - technical: "final_tasks セクションの検知と完了チェックをテスト"
    - consistency: "V12 チェックボックス形式で正しく判定される"
    - completeness: "全完了/一部未完了の両ケースでテスト済み"

**status**: pending
**max_iterations**: 5

---

### p3: cleanup-hook.sh 検証

**goal**: cleanup-hook.sh の tmp/ クリーンアップ機能を検証

**depends_on**: [p1]

#### subtasks

- [ ] **p3.1**: cleanup-hook.sh が playbook 完了時に tmp/ 内のファイルを削除する
  - executor: claudecode
  - validations:
    - technical: "tmp/ にテストファイルを作成し、playbook 完了時に削除されるか確認"
    - consistency: "README.md が保持されることを確認"
    - completeness: "複数ファイル、サブディレクトリでテスト済み"

- [ ] **p3.2**: cleanup-hook.sh が repository-map.yaml を自動更新する
  - executor: claudecode
  - validations:
    - technical: "generate-repository-map.sh の呼び出しを確認"
    - consistency: "更新が playbook 完了時に行われる"
    - completeness: "更新結果が docs/repository-map.yaml に反映される"

**status**: pending
**max_iterations**: 5

---

### p4: create-pr-hook.sh 検証

**goal**: create-pr-hook.sh の PR 作成トリガーを検証

**depends_on**: [p1]

#### subtasks

- [ ] **p4.1**: create-pr-hook.sh が playbook 完了を正しく検知する
  - executor: claudecode
  - validations:
    - technical: "state.md から active playbook を取得し、完了状態をチェックするロジック確認"
    - consistency: "archive-playbook.sh と同様の完了判定ロジック"
    - completeness: "playbook 完了/未完了の両ケースでテスト済み"

- [ ] **p4.2**: create-pr-hook.sh が未コミット変更を検出した場合に警告を出す
  - executor: claudecode
  - validations:
    - technical: "git status --porcelain の呼び出しと警告出力を確認"
    - consistency: "警告メッセージが適切で次のアクションが明確"
    - completeness: "未コミット有/無の両ケースでテスト済み"

- [ ] **p4.3**: create-pr-hook.sh が create-pr.sh を正しく呼び出す
  - executor: claudecode
  - validations:
    - technical: "exec 呼び出しの存在と引数を確認"
    - consistency: "create-pr.sh が存在し実行可能であることを確認"
    - completeness: "呼び出し経路が完全に確認されている"

**status**: pending
**max_iterations**: 5

---

### p5: E2E テストシナリオ実行

**goal**: 全 Hook を統合した E2E テストシナリオを実行

**depends_on**: [p2, p3, p4]

#### subtasks

- [ ] **p5.1**: テスト用 playbook を作成し、全 Phase を done に変更した場合の動作を確認
  - executor: claudecode
  - validations:
    - technical: "tmp/test-playbook.md を作成し、Phase 状態変更をシミュレート"
    - consistency: "archive-playbook.sh の出力が期待通り"
    - completeness: "アーカイブ提案メッセージが表示される"

- [ ] **p5.2**: 実際の playbook 編集で post_loop Hook チェーンが発火することを確認
  - executor: claudecode
  - validations:
    - technical: "現在の playbook を編集し、Hook の発火を確認"
    - consistency: "3 つの Hook が順番に発火する"
    - completeness: "エラーなく完了する"

- [ ] **p5.3**: E2E テスト結果を docs/e2e-post-loop-test.md に記録
  - executor: claudecode
  - validations:
    - technical: "テスト結果ドキュメントが作成されている"
    - consistency: "テストシナリオと結果が対応している"
    - completeness: "全テストケースの結果が記録されている"

**status**: pending
**max_iterations**: 5

---

### p6: 発見した問題の修正（必要な場合）

**goal**: E2E テストで発見した問題を修正

**depends_on**: [p5]

#### subtasks

- [ ] **p6.1**: 発見した問題がある場合、修正を実施
  - executor: claudecode
  - validations:
    - technical: "問題が再現しないことを確認"
    - consistency: "修正が他のコンポーネントに影響しないことを確認"
    - completeness: "全ての発見された問題が修正されている"

- [ ] **p6.2**: 修正後の再テストで全 Hook が正常動作することを確認
  - executor: claudecode
  - validations:
    - technical: "再テストで全て PASS"
    - consistency: "修正前後で挙動が一貫している"
    - completeness: "全テストケースで再確認済み"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p6]

#### subtasks

- [ ] **p_final.1**: PostToolUse:Edit で archive-playbook.sh が正しく発火している
  - executor: claudecode
  - validations:
    - technical: "settings.json の登録と実際の発火を確認"
    - consistency: "p1 の検証結果と一致"
    - completeness: "発火条件が全て満たされている"

- [ ] **p_final.2**: archive-playbook.sh が playbook 完了を正しく検知している
  - executor: claudecode
  - validations:
    - technical: "p2 のテスト結果を確認"
    - consistency: "全ての検知パターンで正しく動作"
    - completeness: "V12 形式、p_final、final_tasks 全てが機能"

- [ ] **p_final.3**: cleanup-hook.sh が tmp/ クリーンアップを正しく実行している
  - executor: claudecode
  - validations:
    - technical: "p3 のテスト結果を確認"
    - consistency: "README.md 保持、ファイル削除が正常"
    - completeness: "repository-map.yaml 更新も確認"

- [ ] **p_final.4**: create-pr-hook.sh が PR 作成トリガーを正しく発火している
  - executor: claudecode
  - validations:
    - technical: "p4 のテスト結果を確認"
    - consistency: "完了検知、未コミット検出、create-pr.sh 呼び出しが正常"
    - completeness: "全ての条件分岐がテストされている"

- [ ] **p_final.5**: E2E テストシナリオで全 Hook が期待通り動作することが確認されている
  - executor: claudecode
  - validations:
    - technical: "p5 のテスト結果を確認"
    - consistency: "docs/e2e-post-loop-test.md に記録されている"
    - completeness: "全 Hook の連携動作が確認されている"

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

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-22 | 初版作成。M083 検証結果に基づく post_loop workflow E2E 検証。 |
