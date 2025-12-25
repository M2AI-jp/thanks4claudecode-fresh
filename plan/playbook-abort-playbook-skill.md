# playbook-abort-playbook-skill.md

> **playbook 中断時のクリーンアップフロー問題を解決する**
>
> アプローチ C: abort-playbook Skill 新設 + health-checker orphan 検出拡張

---

## meta

```yaml
project: abort-playbook-skill
branch: feat/abort-playbook-skill
created: 2025-12-25
issue: null
reviewed: true
```

---

## context

```yaml
problem:
  description: |
    正常完了時は archive-playbook.sh が自動実行されるが、
    中断時はクリーンアップフローがなく、playbook ファイルと state.md が不整合状態で残る。
  evidence:
    - plan/playbook-fix-playbook-branch-check.md が orphan として残存
    - state.md の playbook.active は null だが、plan/ にファイルが残っている

current_state:
  正常完了フロー:
    - playbook の全 Phase が done になる
    - archive-playbook.sh が自動発火
    - PR 作成 → アーカイブ → state.md 更新 → マージ
  中断時の問題:
    - ユーザーがセッション終了、または別タスクに移行
    - playbook ファイルは plan/ に残る
    - state.md は playbook.active が null または別 playbook
    - 不整合状態が発生

solution:
  approach: |
    アプローチ C を採用:
    1. abort-playbook Skill を新設（明示的中断用）
    2. health-checker に orphan playbook 検出を追加（暗黙的中断検出）
  user_choices:
    branch_handling: ユーザーに確認（削除 or 保持）
    orphan_action: WARNING + abort-playbook 実行を提案

orphan_definition:
  - plan/ に playbook-*.md が存在する
  - AND (state.md の playbook.active が null OR 別の playbook を指している)
  - OR (playbook.branch と現在のブランチが一致しない)
```

---

## goal

```yaml
summary: playbook 中断時のクリーンアップフローを確立し、orphan playbook 問題を解決する
done_when:
  - abort-playbook Skill が存在し、playbook を plan/archive/ に移動できる
  - health.sh に orphan playbook 検出機能が存在する
  - health-checker.md に orphan 検出の説明が追加されている
  - 既存の orphan playbook-fix-playbook-branch-check.md が abort 処理されている
```

---

## phases

### p1: abort-playbook Skill 新設

**goal**: 明示的な playbook 中断用の Skill を作成する

#### subtasks

- [x] **p1.1**: .claude/skills/abort-playbook/SKILL.md が存在する
  - executor: claudecode
  - validations:
    - technical: "test -f .claude/skills/abort-playbook/SKILL.md で確認"
    - consistency: "他の Skill と同じ構造（---name/description---）を持つ"
    - completeness: "abort 処理の全ステップ（確認、アーカイブ、state.md 更新、ブランチ処理）が記述されている"

- [x] **p1.2**: .claude/skills/abort-playbook/abort.sh スクリプトが存在する
  - executor: claudecode
  - validations:
    - technical: "bash -n で構文チェック PASS、chmod +x で実行権限あり"
    - consistency: "archive-playbook.sh と同様のアーカイブ処理を行う"
    - completeness: "引数として playbook パスを受け取り、status: aborted を付与してアーカイブする"

**status**: done
**max_iterations**: 5

---

### p2: health-checker orphan 検出拡張

**goal**: health.sh に orphan playbook 検出機能を追加する

**depends_on**: []

#### subtasks

- [x] **p2.1**: health.sh に check_orphan_playbooks 関数が存在する
  - executor: claudecode
  - validations:
    - technical: "grep 'check_orphan_playbooks' health.sh が成功する"
    - consistency: "他のチェック関数（settings, hooks 等）と同じ出力形式"
    - completeness: "orphan 検出ロジック（plan/*.md vs state.md 照合）が実装されている"

- [x] **p2.2**: orphan 検出時に WARNING と abort-playbook 提案が出力される
  - executor: claudecode
  - validations:
    - technical: "orphan がある状態で health.sh を実行すると WARNING が出力される"
    - consistency: "既存の WARNING 形式（[WARN] ...）と統一"
    - completeness: "abort-playbook Skill の呼び出し方法が提示される"

- [x] **p2.3**: health-checker.md に orphan 検出の責務が追加されている
  - executor: claudecode
  - validations:
    - technical: "grep 'orphan' .claude/agents/health-checker.md が成功する"
    - consistency: "既存の責務セクション形式と統一"
    - completeness: "orphan の定義、検出方法、対処法が記述されている"

**status**: done
**max_iterations**: 5

---

### p3: 既存 orphan の処理

**goal**: 既存の orphan playbook を abort 処理して動作確認を兼ねる

**depends_on**: [p1, p2]

#### subtasks

- [x] **p3.1**: plan/playbook-fix-playbook-branch-check.md が plan/archive/ に移動している
  - executor: claudecode
  - validations:
    - technical: "test -f plan/archive/playbook-fix-playbook-branch-check.md で確認"
    - consistency: "status: aborted が meta セクションに追加されている"
    - completeness: "plan/ から元ファイルが削除されている"

- [x] **p3.2**: health.sh 実行時に orphan 警告が出力されない
  - executor: claudecode
  - validations:
    - technical: "bash .claude/skills/quality-assurance/checkers/health.sh | grep -v orphan または orphan 関連メッセージなし"
    - consistency: "他のチェック項目は正常に動作する"
    - completeness: "orphan が解消された状態が確認できる"

**status**: done
**max_iterations**: 3

---

### p_self_update: フレームワーク改善

**goal**: 実装中に発見した改善点を記録・反映する

**depends_on**: [p1, p2, p3]

#### subtasks

- [x] **p_self_update.1**: 改善点の洗い出しが完了している
  - executor: claudecode
  - validations:
    - technical: "改善点リストが作成されている（該当なしの場合は明示）"
    - consistency: "playbook 内に notes または別途記録"
    - completeness: "発見した全ての改善点が列挙されている"
  - notes: |
      発見した改善点:
      1. abort.sh が orphan playbook を処理する際に state.md を誤って null に更新する問題
         → 修正済み: active と一致する場合のみ state.md を更新するように変更

- [x] **p_self_update.2**: 重要な改善点が適用されている（該当する場合）
  - executor: claudecode
  - validations:
    - technical: "改善が適用済み、または次タスクとして記録"
    - consistency: "既存のドキュメント/コードと整合"
    - completeness: "適用可能な改善は全て反映"
  - notes: |
      適用済み: abort.sh 行 148-172 に条件分岐を追加

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p1, p2, p3, p_self_update]

#### subtasks

- [x] **p_final.1**: abort-playbook Skill が存在し、playbook を plan/archive/ に移動できる
  - executor: claudecode
  - validations:
    - technical: "SKILL.md と abort.sh が存在し、実行可能"
    - consistency: "archive-playbook.sh と同様のアーカイブ形式"
    - completeness: "status: aborted マーク、state.md 更新、ブランチ処理の全機能が含まれる"

- [x] **p_final.2**: health.sh に orphan playbook 検出機能が存在する
  - executor: claudecode
  - validations:
    - technical: "check_orphan_playbooks 関数が存在し、呼び出されている"
    - consistency: "他のチェック機能と同じ出力形式"
    - completeness: "orphan 検出 + WARNING + 提案出力が動作する"

- [x] **p_final.3**: health-checker.md に orphan 検出の説明が追加されている
  - executor: claudecode
  - validations:
    - technical: "orphan 関連の記述が存在する"
    - consistency: "既存の責務セクションと同じ形式"
    - completeness: "orphan の定義、検出、対処が全て記述されている"

- [x] **p_final.4**: 既存の orphan playbook-fix-playbook-branch-check.md が abort 処理されている
  - executor: claudecode
  - validations:
    - technical: "plan/archive/ に移動済み、plan/ から削除済み"
    - consistency: "status: aborted が付与されている"
    - completeness: "health.sh で orphan 警告が出ない"

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

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done
