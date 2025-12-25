# playbook-post-loop-auto-fire.md

## meta

```yaml
project: post-loop-auto-fire
branch: feat/post-loop-auto-fire
created: 2025-12-25
issue: null
reviewed: true
```

---

## goal

```yaml
summary: playbook 完了時に post-loop 処理が自動発火する仕組みを構築する
done_when:
  - archive-playbook.sh が playbook 完了時にアーカイブ/PR 作成/マージを自動実行する
  - pre-tool.sh が post-loop-pending を検出し、post-loop 実行を強制する
  - post-loop Skill が次タスク導出のみを担当し、pending を削除する
```

---

## phases

### p1: archive-playbook.sh の自動実行化

**goal**: playbook 完了検出時に自動でアーカイブ/PR 作成/マージを実行する

#### subtasks

- [ ] **p1.1**: archive-playbook.sh が全 Phase done 検出時に自動コミットを実行する
  - executor: claudecode
  - validations:
    - technical: "git status --porcelain で未コミット変更がある場合に git commit を実行"
    - consistency: "既存の自動コミットロジック（Phase 完了時）と整合性確認"
    - completeness: "コミットメッセージに playbook 名が含まれる"

- [ ] **p1.2**: archive-playbook.sh が playbook を plan/archive/ に自動移動する
  - executor: claudecode
  - validations:
    - technical: "mv コマンドで plan/playbook-*.md を plan/archive/ に移動"
    - consistency: "既存の archive-playbook.sh の提案ロジックと整合性確認"
    - completeness: "mkdir -p plan/archive が事前に実行される"

- [ ] **p1.3**: archive-playbook.sh が state.md の playbook.active を null に更新する
  - executor: claudecode
  - validations:
    - technical: "sed または yq で state.md の playbook.active を null に変更"
    - consistency: "state.md の YAML 構造が維持される"
    - completeness: "playbook.branch も null に更新される"

- [ ] **p1.4**: archive-playbook.sh が git push を実行する
  - executor: claudecode
  - validations:
    - technical: "git push origin {branch} を実行"
    - consistency: "リモートブランチが存在する場合のみ push"
    - completeness: "push 失敗時は警告を出力して続行"

- [ ] **p1.5**: archive-playbook.sh が create-pr.sh を呼び出す
  - executor: claudecode
  - validations:
    - technical: "bash .claude/skills/git-workflow/handlers/create-pr.sh を実行"
    - consistency: "create-pr.sh の既存インターフェースと整合性確認"
    - completeness: "PR 作成失敗時は警告を出力して続行"

- [ ] **p1.6**: archive-playbook.sh が merge-pr.sh を呼び出す
  - executor: claudecode
  - validations:
    - technical: "bash .claude/skills/git-workflow/handlers/merge-pr.sh を実行"
    - consistency: "merge-pr.sh の既存インターフェースと整合性確認"
    - completeness: "マージ失敗時は警告を出力して続行"

- [ ] **p1.7**: archive-playbook.sh が main ブランチに同期する
  - executor: claudecode
  - validations:
    - technical: "git checkout main && git pull origin main を実行"
    - consistency: "マージ後にのみ実行される"
    - completeness: "同期失敗時は警告を出力"

- [ ] **p1.8**: archive-playbook.sh が post-loop-pending ファイルを作成する（成功時のみ）
  - executor: claudecode
  - validations:
    - technical: "touch .claude/session-state/post-loop-pending を実行"
    - consistency: ".claude/session-state/ ディレクトリが存在しない場合は作成"
    - completeness: "pending ファイルに playbook 名とステータス（success/partial）を記録"

- [ ] **p1.9**: PR マージ失敗時は pending にステータスを記録する
  - executor: claudecode
  - validations:
    - technical: "pending ファイルに status=partial を書き込む"
    - consistency: "成功時は status=success を書き込む"
    - completeness: "pending-guard.sh がステータスに応じた案内を出す"

**status**: pending
**max_iterations**: 5

---

### p2: pre-tool.sh の pending 検出追加

**goal**: post-loop-pending ファイルを検出し、post-loop 実行を強制する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: .claude/session-state/ ディレクトリが存在する
  - executor: claudecode
  - validations:
    - technical: "test -d .claude/session-state で確認"
    - consistency: ".gitignore に追加されている"
    - completeness: "README.md が配置されている"

- [ ] **p2.2**: pre-tool.sh が post-loop-pending を検出し BLOCK する
  - executor: claudecode
  - validations:
    - technical: "test -f .claude/session-state/post-loop-pending でファイル存在を確認"
    - consistency: "既存の pre-tool.sh のチェック順序と整合性確認"
    - completeness: "BLOCK 時に Skill(skill='post-loop') 実行を案内"

- [ ] **p2.3**: pending 検出のガードスクリプトが存在する
  - executor: claudecode
  - validations:
    - technical: ".claude/skills/post-loop/guards/pending-guard.sh が存在する"
    - consistency: "他のガードスクリプト（playbook-guard.sh 等）と同じ構造"
    - completeness: "exit 2 でブロック、systemMessage で案内"

- [ ] **p2.4**: pending-guard.sh に許可リスト（allowlist）が存在する
  - executor: claudecode
  - validations:
    - technical: "state.md と post-loop-pending 自体の操作は許可される"
    - consistency: "許可リストがスクリプト内で定義されている"
    - completeness: "デッドロックを防ぐ最小限のファイルが許可される"

- [ ] **p2.5**: pending-guard.sh がステータスに応じた案内を出す
  - executor: claudecode
  - validations:
    - technical: "status=success の場合は post-loop 実行を案内"
    - consistency: "status=partial の場合は手動リカバリを案内"
    - completeness: "ステータス不明の場合のフォールバックがある"

**status**: pending
**max_iterations**: 3

---

### p3: post-loop Skill の責務変更

**goal**: post-loop Skill を「次タスク導出のみ」に変更し、pending を削除する

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: post-loop SKILL.md が更新されている
  - executor: claudecode
  - validations:
    - technical: "SKILL.md の行動セクションが「次タスク導出のみ」に変更されている"
    - consistency: "他の SKILL.md と同じフォーマット"
    - completeness: "自動コミット/アーカイブ/PR 作成/マージは archive-playbook.sh に移管と明記"

- [ ] **p3.2**: post-loop/handlers/complete.sh が pending を削除する
  - executor: claudecode
  - validations:
    - technical: "rm -f .claude/session-state/post-loop-pending を実行"
    - consistency: "pending ファイルが存在しない場合もエラーにならない"
    - completeness: "削除後に成功メッセージを出力"

- [ ] **p3.3**: post-loop SKILL.md の行動に「最初に complete.sh を実行」と明記されている
  - executor: claudecode
  - validations:
    - technical: "SKILL.md の行動セクション冒頭に complete.sh 実行が記載されている"
    - consistency: "Claude が post-loop Skill を読んで最初に complete.sh を実行できる"
    - completeness: "complete.sh のパスが明記されている"

- [ ] **p3.4**: complete.sh が pending ファイル削除後に state.md を更新する
  - executor: claudecode
  - validations:
    - technical: "state.md の playbook.active を null に更新する"
    - consistency: "archive-playbook.sh との責務分担が明確"
    - completeness: "playbook.last_archived も更新される"

**status**: pending
**max_iterations**: 3

---

### p4: ドキュメント更新と E2E テスト

**goal**: ARCHITECTURE.md にフロー図を追加し、実際の動作を確認する

**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: docs/ARCHITECTURE.md に post-loop 自動発火フローが追記されている
  - executor: claudecode
  - validations:
    - technical: "「PostToolUse:Edit → archive-playbook.sh → post-loop 強制」のフロー図が存在する"
    - consistency: "既存のフロー図と同じ記法"
    - completeness: "pending ファイルの役割が説明されている"

- [ ] **p4.2**: archive-playbook.sh のコメントが更新されている
  - executor: claudecode
  - validations:
    - technical: "冒頭コメントに「自動実行」の説明が追加されている"
    - consistency: "他のスクリプトのコメントスタイルと整合性確認"
    - completeness: "変更履歴に今回の変更が記載されている"

- [ ] **p4.3**: E2E テストシナリオが実行されている
  - executor: claudecode
  - validations:
    - technical: "テスト用の小さな playbook を作成し、全 Phase を done にする"
    - consistency: "archive-playbook.sh が発火し、pending ファイルが作成される"
    - completeness: "pending-guard.sh がブロックし、post-loop 実行後にブロック解除される"

**status**: pending
**max_iterations**: 3

---

### p_self_update: playbook 自己更新

**goal**: 実装中に発見した問題や設計変更を playbook に反映する

**depends_on**: [p1, p2, p3]

#### subtasks

- [ ] **p_self_update.1**: 実装中の発見事項が playbook に反映されている
  - executor: claudecode
  - validations:
    - technical: "発見した問題や追加 subtask が playbook に記載されている"
    - consistency: "既存の subtask 構造と整合性確認"
    - completeness: "全ての発見事項が記録されている"

**status**: pending
**max_iterations**: 2

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p4, p_self_update]

#### subtasks

- [ ] **p_final.1**: archive-playbook.sh が playbook 完了時にアーカイブ/PR 作成/マージを自動実行する
  - executor: claudecode
  - validations:
    - technical: "archive-playbook.sh を実行し、全ステップが実行されることを確認"
    - consistency: "既存の post-tool.sh からの呼び出しと整合性確認"
    - completeness: "自動コミット、アーカイブ、push、PR 作成、マージ、main 同期、pending 作成が実行される"

- [ ] **p_final.2**: pre-tool.sh が post-loop-pending を検出し、post-loop 実行を強制する
  - executor: claudecode
  - validations:
    - technical: "pending ファイル存在時に Edit/Write がブロックされることを確認"
    - consistency: "ブロックメッセージが Skill(skill='post-loop') 実行を案内している"
    - completeness: "全ての Edit/Write ツールがブロックされる"

- [ ] **p_final.3**: post-loop Skill が次タスク導出のみを担当し、pending を削除する
  - executor: claudecode
  - validations:
    - technical: "post-loop SKILL.md が「次タスク導出のみ」と記載されている"
    - consistency: "complete.sh が pending ファイルを削除する"
    - completeness: "pending 削除後に Edit/Write がブロック解除される"

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
| 2025-12-25 | 初版作成。ハイブリッドアプローチで post-loop 自動発火を実装。 |
