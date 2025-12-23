# git-workflow Skill

> **Git/PR ワークフロー**
>
> PR 作成〜マージのワークフロー管理

---

## 責務

このSkillは以下を担当:
1. PR の自動作成
2. PR のマージ
3. マージ後の main ブランチ同期
4. ブランチ管理

---

## ディレクトリ構造

```
git-workflow/
├── SKILL.md              ← このファイル
└── handlers/
    ├── create-pr.sh          ← PR 作成
    ├── merge-pr.sh           ← PR マージ
    └── post-merge.sh         ← マージ後処理（main checkout + pull）
```

---

## 発火条件

- playbook 完了後（PostToolUse:Edit）
- ユーザーが PR 作成/マージを指示した時
- post-tool.sh（導火線）から呼び出される

---

## ハンドラー一覧

| ハンドラー | トリガー | 役割 |
|------------|----------|------|
| create-pr.sh | playbook 完了時 | gh pr create で PR 自動作成 |
| merge-pr.sh | ユーザー指示時 | gh pr merge で PR マージ |
| post-merge.sh | マージ完了後 | main checkout & pull |

---

## PR 作成ルール

```yaml
auto_create:
  condition: "playbook の全 Phase が done"
  template:
    title: "feat/fix/refactor: {playbook.goal.summary}"
    body: |
      ## Summary
      - {done_when の要約}

      ## Test plan
      - [ ] {検証項目}

      Generated with Claude Code

branch_naming:
  pattern: "{type}/{description}"
  types:
    - feat
    - fix
    - refactor
    - docs
    - chore
```

---

## マージルール

```yaml
pre_merge_checks:
  - "全テストが PASS"
  - "reviewer の PASS（または LGTM）"
  - "コンフリクトなし"

merge_strategy:
  default: squash
  options:
    - merge
    - squash
    - rebase

post_merge:
  - "git checkout main"
  - "git pull origin main"
  - "state.md の playbook.active を null に"
  - "playbook をアーカイブ"
```

---

## 使用方法

### PR 作成
```bash
bash .claude/skills/git-workflow/handlers/create-pr.sh
```

### PR マージ
```bash
bash .claude/skills/git-workflow/handlers/merge-pr.sh
```

---

## 関連

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | Git Workflow ルール |
| state.md | playbook.branch の参照 |
| .claude/hooks/post-tool.sh | 導火線 |
