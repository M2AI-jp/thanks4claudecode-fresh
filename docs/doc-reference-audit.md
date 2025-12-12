# doc-reference-audit.md

> **ドキュメント参照状況監査リスト**
>
> tech-stack.md 以外のドキュメントについて、Hooks/SubAgents/Skills/CLAUDE.md/state.md からの参照状況を調査し、削除/保持を判定

---

## 監査日時

2025-12-13

---

## 監査方法

1. Hooks（.claude/hooks/*.sh）内での参照を grep で確認
2. SubAgents（.claude/agents/*.md）内での参照を grep で確認
3. Skills（.claude/skills/*/*.md）内での参照を grep で確認
4. CLAUDE.md からの参照を確認
5. state.md からの参照を確認
6. tech-stack.md からの参照を確認

---

## docs/ 配下（14ファイル）

| ファイル | 参照元 | 判定 | 理由 |
|----------|--------|------|------|
| CLAUDE.md | - | **保持** | ディレクトリ説明（READMEの役割） |
| archive-operation-rules.md | archive-playbook.sh, post-loop/skill.md | **保持** | Core Hook から参照 |
| artifact-management-rules.md | docs/CLAUDE.md | 削除予定 | 実行コードからの参照なし、言及のみ |
| criterion-validation-rules.md | pm.md, critic.md, playbook-format.md | **保持** | Core SubAgent から参照 |
| current-implementation.md | doc-freshness-check.sh | **保持** | Hook から参照 |
| extension-system.md | doc-freshness-check.sh | **保持** | Hook から参照 |
| feature-map.md | CLAUDE.md (INIT必須) | **保持** | INIT 必須読み込み |
| file-inventory.md | docs/CLAUDE.md | 削除予定 | 実行コードからの参照なし、言及のみ |
| git-operations.md | docs/CLAUDE.md | 削除予定 | 実行コードからの参照なし、言及のみ |
| state-injection-guide.md | アーカイブ playbook のみ | 削除予定 | アーカイブ済み playbook からのみ参照 |
| task-initiation-flow.md | docs/CLAUDE.md | 削除予定 | 実行コードからの参照なし、言及のみ |
| tech-stack.md | - | **保持** | 本監査の基準ドキュメント |
| test-results.md | docs/CLAUDE.md | 削除予定 | 実行コードからの参照なし、言及のみ |
| design/pr-automation-design.md | 自己参照のみ | 削除予定 | 自己参照のみ、実装済み |

---

## plan/ 配下（13ファイル）

| ファイル | 参照元 | 判定 | 理由 |
|----------|--------|------|------|
| README.md | - | 削除予定 | ディレクトリ説明、内部参照のみ |
| project.md | CLAUDE.md (INIT必須) | **保持** | INIT 必須読み込み |
| design/README.md | - | 削除予定 | ディレクトリ説明、内部参照のみ |
| design/mission.md | なし | 削除予定 | 参照なし、plan/mission.md は存在しない |
| design/plan-chain-system.md | plan/README.md | 削除予定 | 内部参照のみ、設計完了済み |
| design/self-healing-system.md | plan/README.md | 削除予定 | 内部参照のみ、設計完了済み |
| template/CLAUDE.md | - | 削除予定 | ディレクトリ説明、内部参照のみ |
| template/playbook-format.md | pm.md, CLAUDE.md | **保持** | Core SubAgent から参照 |
| template/playbook-examples.md | playbook-format.md | **保持** | playbook-format.md から参照 |
| template/planning-rules.md | playbook-format.md | **保持** | playbook-format.md から参照 |
| template/project-format.md | setup-guide.md | **保持** | setup SubAgent から参照 |
| template/state-initial.md | plan/template/CLAUDE.md | 削除予定 | 削除予定ファイルからのみ参照 |
| template/vercel-nextjs-saas-structure.md | planning-rules.md | **保持** | planning-rules.md から参照 |

---

## .claude/ 配下（26ファイル）

### agents/ (7ファイル)

| ファイル | 参照元 | 判定 | 理由 |
|----------|--------|------|------|
| CLAUDE.md | - | 削除予定 | ディレクトリ説明のみ |
| critic.md | CLAUDE.md (Task呼び出し) | **保持** | Core SubAgent |
| health-checker.md | settings.json (SubAgent定義) | **保持** | 登録済み SubAgent |
| plan-guard.md | settings.json (SubAgent定義) | **保持** | 登録済み SubAgent |
| pm.md | CLAUDE.md (Task呼び出し) | **保持** | Core SubAgent |
| reviewer.md | settings.json (SubAgent定義) | **保持** | 登録済み SubAgent |
| setup-guide.md | settings.json (SubAgent定義) | **保持** | 登録済み SubAgent |

### commands/ (7ファイル)

| ファイル | 参照元 | 判定 | 理由 |
|----------|--------|------|------|
| crit.md | - | 削除予定 | スラッシュコマンド、使用頻度不明 |
| focus.md | - | 削除予定 | スラッシュコマンド、使用頻度不明 |
| lint.md | - | 削除予定 | スラッシュコマンド、使用頻度不明 |
| playbook-init.md | - | 削除予定 | スラッシュコマンド、pm経由が標準 |
| rollback.md | scripts/rollback.sh | **保持** | 実スクリプトを呼び出し |
| state-rollback.md | scripts/state-rollback.sh | **保持** | 実スクリプトを呼び出し |
| task-start.md | docs/task-initiation-flow.md | 削除予定 | 削除予定ドキュメントからのみ参照 |
| test.md | - | 削除予定 | スラッシュコマンド、使用頻度不明 |

### context/ (3ファイル)

| ファイル | 参照元 | 判定 | 理由 |
|----------|--------|------|------|
| CLAUDE.md | - | 削除予定 | ディレクトリ説明のみ |
| claude-md-history.md | context/CLAUDE.md | 削除予定 | 削除予定ファイルからのみ参照 |
| history.md | アーカイブ playbook のみ | 削除予定 | アーカイブ済み playbook からのみ参照 |

### frameworks/ (3ファイル)

| ファイル | 参照元 | 判定 | 理由 |
|----------|--------|------|------|
| CLAUDE.md | - | 削除予定 | ディレクトリ説明のみ |
| done-criteria-validation.md | CLAUDE.md, critic.md | **保持** | Core 機能 |
| playbook-review-criteria.md | reviewer.md, agents/CLAUDE.md | **保持** | reviewer SubAgent から参照 |

### その他

| ファイル | 参照元 | 判定 | 理由 |
|----------|--------|------|------|
| CLAUDE-ref.md | docs/file-inventory.md | 削除予定 | 削除予定ドキュメントからのみ参照 |
| templates/linter-formatter-config.md | setup/playbook-setup.md | **保持** | setup playbook から参照 |
| tests/regression-targets.md | docs/file-inventory.md | 削除予定 | 削除予定ドキュメントからのみ参照 |
| state-history/*.md (3ファイル) | - | 削除予定 | 内部バックアップ、参照なし |
| scripts/rollback.sh | commands/rollback.md | **保持** | コマンドから参照 |
| scripts/state-rollback.sh | commands/state-rollback.md | **保持** | コマンドから参照 |
| scripts/test-rollback.sh | - | 削除予定 | テスト用、通常運用で参照なし |

---

## サマリー

### 保持（26ファイル）

**docs/**:
- archive-operation-rules.md, criterion-validation-rules.md, current-implementation.md
- extension-system.md, feature-map.md, tech-stack.md, CLAUDE.md

**plan/**:
- project.md
- template/: playbook-format.md, playbook-examples.md, planning-rules.md, project-format.md, vercel-nextjs-saas-structure.md

**.claude/**:
- agents/: critic.md, health-checker.md, plan-guard.md, pm.md, reviewer.md, setup-guide.md
- commands/: rollback.md, state-rollback.md
- frameworks/: done-criteria-validation.md, playbook-review-criteria.md
- templates/: linter-formatter-config.md
- scripts/: rollback.sh, state-rollback.sh

### 削除予定（27ファイル）

**docs/** (7ファイル):
- artifact-management-rules.md, file-inventory.md, git-operations.md
- state-injection-guide.md, task-initiation-flow.md, test-results.md
- design/pr-automation-design.md

**plan/** (6ファイル):
- README.md, design/README.md, design/mission.md
- design/plan-chain-system.md, design/self-healing-system.md
- template/CLAUDE.md, template/state-initial.md

**.claude/** (14ファイル):
- CLAUDE-ref.md
- agents/CLAUDE.md
- commands/: crit.md, focus.md, lint.md, playbook-init.md, task-start.md, test.md
- context/: CLAUDE.md, claude-md-history.md, history.md
- frameworks/CLAUDE.md
- tests/regression-targets.md
- scripts/test-rollback.sh
- state-history/*.md (3ファイル)

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | 初版作成。M010 p0 対応。 |
