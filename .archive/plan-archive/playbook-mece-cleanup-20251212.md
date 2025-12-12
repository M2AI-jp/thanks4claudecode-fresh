# playbook-mece-cleanup

> **基幹システムの MECE 整理 + 理解確認機能の改善**
>
> ファイル削減によるコンテキスト効率化と、consent-process の構造化変換機能を実装する。

---

## meta

```yaml
project: mece-cleanup-consent-improvement
branch: feat/mece-cleanup-consent-improvement
created: 2025-12-12
issue: null
derives_from: null  # 新規タスク
reviewed: false
```

---

## goal

```yaml
summary: 不要ファイル33件を削除し、理解確認機能をユーザープロンプト構造化変換機能に改善する

done_when:
  - シミュレーションログ等33ファイルが削除されている
  - consent-process が「ユーザープロンプト → 構造化コンテキスト」変換機能を持つ
  - 既存機能（Hooks/SubAgents/Skills）が正常動作する
```

---

## phases

### Phase 1: 不要ファイルの削除

```yaml
- id: p1
  name: 不要ファイルの削除
  goal: 参照されていないファイル33件を削除し、システムを簡潔化する
  tasks:
    - id: t1-1
      name: シミュレーション・テスト結果の削除
      subtasks:
        - step: ".claude/logs/simulation-log-*.md を削除"
          executor: claudecode
          criteria: "ls .claude/logs/simulation-log-*.md 2>/dev/null | wc -l が 0"
          status: "[x]"
        - step: ".claude/logs/simulation-issues/ と simulation-summary.md を削除"
          executor: claudecode
          criteria: "ls .claude/logs/simulation-issues/ 2>/dev/null | wc -l が 0"
          status: "[x]"
        - step: ".claude/logs/attempts/ を削除"
          executor: claudecode
          criteria: "ls .claude/logs/attempts/ 2>/dev/null | wc -l が 0"
          status: "[x]"
        - step: ".claude/hooks/test-results/ を削除"
          executor: claudecode
          criteria: "ls .claude/hooks/test-results/ 2>/dev/null | wc -l が 0"
          status: "[x]"
    - id: t1-2
      name: 古いバックアップ・未使用ファイルの削除
      subtasks:
        - step: ".claude/state-history/ を削除"
          executor: claudecode
          criteria: "ls .claude/state-history/ 2>/dev/null | wc -l が 0"
          status: "[x]"
        - step: ".claude/templates/ を削除"
          executor: claudecode
          criteria: "test -d .claude/templates && echo 'exists' || echo 'deleted' が deleted"
          status: "[x]"
        - step: "plan/design/ を削除"
          executor: claudecode
          criteria: "test -d plan/design && echo 'exists' || echo 'deleted' が deleted"
          status: "[x]"
    - id: t1-3
      name: 未参照ドキュメントの削除
      subtasks:
        - step: "docs/hooks-edge-cases.md, hooks-fire-matrix.md, hooks-specification.md, hooks-test-design.md を削除"
          executor: claudecode
          criteria: "ls docs/hooks-*.md 2>/dev/null | wc -l が 0"
          status: "[x]"
        - step: "docs/done-criteria-guide.md, playbook-structure-audit.md を削除"
          executor: claudecode
          criteria: "test -f docs/done-criteria-guide.md || test -f docs/playbook-structure-audit.md でどちらも存在しない"
          status: "[x]"
  test_method: |
    1. 削除対象ファイルが全て存在しないことを確認
    2. git status で削除状態を確認
    3. 既存機能（session-start.sh 等）が正常動作することを確認
  status: done
```

### Phase 2: 理解確認機能の改善

```yaml
- id: p2
  name: 理解確認機能の改善
  goal: consent-process を「ユーザープロンプト構造化変換機能」に進化させる
  depends_on: [p1]
  tasks:
    - id: t2-1
      name: consent-process Skill の再設計
      subtasks:
        - step: ".claude/skills/consent-process/skill.md を読み込み、現状を分析"
          executor: claudecode
          criteria: "skill.md の内容を把握し、改善ポイントを特定"
          status: "[x]"
        - step: "skill.md を更新: [理解確認] フォーマットを拡張（what/why/how/scope/exclusions + 構造化 done_criteria）"
          executor: claudecode
          criteria: "skill.md に「構造化変換」セクションが追加されている"
          status: "[x]"
        - step: "「曖昧表現の具体化」ルールを追加"
          executor: claudecode
          criteria: "skill.md に曖昧表現 → 具体化の変換ルールが記載されている"
          status: "[x]"
        - step: "「検証可能な done_criteria 自動提案」機能を追加"
          executor: claudecode
          criteria: "skill.md に done_criteria 提案ロジックが記載されている"
          status: "[x]"
  test_method: |
    1. skill.md の新セクションが正しく構造化されているか確認
    2. 曖昧表現の具体化例が含まれているか確認
    3. done_criteria 提案ロジックが実用的か確認
  status: done
```

### Phase 3: 動作確認とコミット

```yaml
- id: p3
  name: 動作確認とコミット
  goal: 全変更が正常に動作し、既存機能に影響がないことを確認
  depends_on: [p1, p2]
  tasks:
    - id: t3-1
      name: 既存機能の動作確認
      subtasks:
        - step: "session-start.sh の発火を確認（ログ参照なし）"
          executor: claudecode
          criteria: "bash -n .claude/hooks/session-start.sh が exit 0"
          status: "[x]"
        - step: "system-health-check.sh --level light を実行"
          executor: claudecode
          criteria: "system-health-check.sh が正常終了（exit 0）"
          status: "[x]"
    - id: t3-2
      name: コミットと PR 更新
      subtasks:
        - step: "全変更をコミット"
          executor: claudecode
          criteria: "git log --oneline -1 でコミットが存在"
          status: "[x]"
        - step: "PR を作成"
          executor: claudecode
          criteria: "gh pr list で PR が表示される"
          status: "[x]"
  test_method: |
    1. bash -n で全 Hook スクリプトの構文チェック
    2. system-health-check.sh でシステム状態確認
    3. git status で clean な状態を確認
  status: done
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| .claude/skills/consent-process/skill.md | 改善対象 |
| docs/feature-map.md | 機能マップ |
| .claude/hooks/session-start.sh | 動作確認対象 |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-12 | 初版作成。3 Phase で MECE 整理と consent-process 改善を実装。 |
