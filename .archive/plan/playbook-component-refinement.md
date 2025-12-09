# playbook-component-refinement.md

> **コンポーネント構造改善 - 機能重複の解消と効率化**
>
> SubAgent/Skill/Hook の役割を明確化し、保守性を向上

---

## meta

```yaml
project: component-refinement
branch: feat/component-refinement
created: 2025-12-09
issue: null
derives_from: null  # 独立したリファクタリングタスク
```

---

## goal

```yaml
summary: 機能重複の解消と構造最適化により保守性を向上
done_when:
  - 機能重複している SubAgent が削除または統合されている
  - 各コンポーネントの役割が明確になっている
  - ユーザーフリクションが軽減されている
  - 全 Hook が正常に動作している
```

---

## background

```yaml
発見された問題:
  1. coherence SubAgent と check-coherence.sh Hook が機能重複
  2. state-mgr SubAgent と state Skill が機能重複
  3. git-ops SubAgent は実際には参照ドキュメント
  4. beginner-advisor SubAgent は Skill で十分（発火条件が単純）
  5. pre-bash-check.sh のメッセージがうるさい（ユーザー指摘）

設計方針:
  - Hook: 構造的強制（必ず発火）
  - Skill: 知識提供（呼び出し可能）
  - SubAgent: 複雑な判断が必要な処理
  - docs: 参照ドキュメント
```

---

## phases

```yaml
- id: p1
  name: coherence SubAgent 削除
  goal: Hook で十分なため SubAgent を削除
  executor: claudecode
  done_criteria:
    - .claude/agents/coherence.md が削除されている
    - settings.json の subagents から coherence が削除されている（存在する場合）
    - check-coherence.sh が引き続き正常動作している
    - 実際に動作確認済み（test_method 実行）
  test_method: |
    1. ls .claude/agents/ で coherence.md がないことを確認
    2. git commit 前に check-coherence.sh が発火することを確認
  status: done

- id: p2
  name: state-mgr SubAgent 削除
  goal: Skill で十分なため SubAgent を削除
  executor: claudecode
  depends_on: [p1]
  done_criteria:
    - .claude/agents/state-mgr.md が削除されている
    - .claude/skills/state/skill.md が引き続き存在している
    - state.md の更新が正常に動作している
    - 実際に動作確認済み（test_method 実行）
  test_method: |
    1. ls .claude/agents/ で state-mgr.md がないことを確認
    2. ls .claude/skills/state/ で skill.md が存在することを確認
  status: done

- id: p3
  name: git-ops を docs/ へ移動
  goal: 参照ドキュメントとして適切な場所に配置
  executor: claudecode
  depends_on: [p2]
  done_criteria:
    - .claude/agents/git-ops.md が削除されている
    - docs/git-operations.md が作成されている
    - 内容が適切に移行されている（frontmatter 削除、ドキュメント形式に）
    - 実際に動作確認済み（test_method 実行）
  test_method: |
    1. ls .claude/agents/ で git-ops.md がないことを確認
    2. cat docs/git-operations.md で内容を確認
  status: done

- id: p4
  name: beginner-advisor を Skill へ転換
  goal: 発火条件が単純なため Skill として再実装
  executor: claudecode
  depends_on: [p3]
  done_criteria:
    - .claude/agents/beginner-advisor.md が削除されている
    - .claude/skills/beginner-advisor/skill.md が作成されている
    - frontmatter に適切な triggers が定義されている
    - 実際に動作確認済み（test_method 実行）
  test_method: |
    1. ls .claude/agents/ で beginner-advisor.md がないことを確認
    2. cat .claude/skills/beginner-advisor/skill.md で内容を確認
    3. frontmatter に triggers が含まれていることを確認
  status: done

- id: p5
  name: Phase完了メッセージ条件化
  goal: Phase完了メッセージを条件付きにしてユーザーフリクション軽減
  executor: claudecode
  depends_on: [p4]
  done_criteria:
    - check-coherence.sh が修正されている（実際のメッセージ出力元）
    - CLAUDE_VERBOSE 環境変数でメッセージ表示を制御
    - 通常時はメッセージが表示されない
    - Hook の本来機能（整合性チェック）は維持されている
    - 実際に動作確認済み（test_method 実行）
  test_method: |
    1. git commit を実行し、「Phase完了 - コンテキスト確認推奨」が表示されないことを確認
    2. CLAUDE_VERBOSE=1 で実行し、メッセージが表示されることを確認
  status: done

- id: p6
  name: 最終検証
  goal: 全変更が正常に動作することを確認
  executor: claudecode
  depends_on: [p1, p2, p3, p4, p5]
  done_criteria:
    - 削除された SubAgent が .claude/agents/ に存在しない
    - 新規作成された Skill/docs が正しく配置されている
    - 全 Hook が正常に動作している
    - critic PASS
  test_method: |
    1. ls .claude/agents/ で残っている SubAgent を確認
    2. ls .claude/skills/ で Skill を確認
    3. ls docs/ でドキュメントを確認
    4. git commit テストで Hook 発火を確認
    5. critic を呼び出して PASS を取得
  status: done
```

---

## evidence

```yaml
p1:
  action: coherence SubAgent 削除
  files_deleted:
    - .claude/agents/coherence.md
  files_updated:
    - .claude/CLAUDE-ref.md: SubAgent 参照を Hook 参照に変更
    - docs/file-inventory.md: 削除済みとマーク
  verification:
    ls_agents: "coherence.md が存在しない（9ファイル表示）"
    hook_registered: "check-coherence.sh が settings.json line 134 に登録済み"
p2:
  action: state-mgr SubAgent 削除
  files_deleted:
    - .claude/agents/state-mgr.md
  files_updated:
    - .claude/CLAUDE-ref.md: SubAgent 参照を Skill 参照に変更
    - docs/file-inventory.md: 削除済みとマーク
  verification:
    skill_exists: ".claude/skills/state/SKILL.md が存在"
    ls_agents: "state-mgr.md が存在しない（8ファイル表示）"
p3:
  action: git-ops を docs/ へ移動
  files_deleted:
    - .claude/agents/git-ops.md
  files_created:
    - docs/git-operations.md
  files_updated:
    - docs/file-inventory.md: 移動済みとマーク
  verification:
    new_location: "docs/git-operations.md が存在"
    ls_agents: "git-ops.md が存在しない（7ファイル表示）"
p4:
  action: beginner-advisor を Skill へ転換
  files_deleted:
    - .claude/agents/beginner-advisor.md
  files_created:
    - .claude/skills/beginner-advisor/skill.md
  files_updated:
    - .claude/CLAUDE-ref.md: SubAgent 参照を Skill 参照に変更
    - docs/file-inventory.md: Skill へ転換とマーク
  verification:
    ls_agents: "beginner-advisor.md が存在しない（6ファイル表示）"
    skill_exists: ".claude/skills/beginner-advisor/skill.md が存在"
    frontmatter_triggers: "triggers セクションが含まれている"
p5:
  action: Phase完了メッセージを CLAUDE_VERBOSE で条件化
  files_updated:
    - .claude/hooks/check-coherence.sh: CLAUDE_VERBOSE 環境変数チェックを追加
  verification:
    code_change: "行311-324: if [ -n \"$CLAUDE_VERBOSE\" ]; then でメッセージをラップ"
    default_behavior: "CLAUDE_VERBOSE 未設定時はメッセージ非表示"
    verbose_behavior: "CLAUDE_VERBOSE=1 設定時のみメッセージ表示"
  note: "playbook 記載の pre-bash-check.sh ではなく、実際のメッセージ出力元は check-coherence.sh だった"
p6:
  action: 最終検証
  verification:
    agents_count: "6ファイル: critic, health-checker, plan-guard, pm, reviewer, setup-guide"
    deleted_agents: "coherence, state-mgr, git-ops, beginner-advisor が存在しない"
    skills_count: "10ディレクトリ（beginner-advisor 新規追加）"
    docs_git_ops: "docs/git-operations.md が存在"
    git_commit: "69cc0c5 - Phase完了メッセージ非表示を確認"
    critic: "PASS（2回目）"
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | **全 Phase 完了**: p1-p6 done。critic PASS。main マージ準備完了。 |
| 2025-12-09 | 初版作成。コンポーネント構造改善 playbook。 |
