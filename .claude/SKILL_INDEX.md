# SKILL_INDEX.md

> **LLM 自己認識のための全機能インデックス**
>
> 全 74 ファイルを個別評価し、存在理由と健全性を可視化する。

---

## 評価基準

```yaml
criteria:
  why: [clear, partial, unclear]  # 存在理由
  works: [works, broken, untested]  # 動作確認
  depends: [documented, implicit, orphan]  # 依存関係
  health: [healthy, warning, critical]  # 健全性
  value: [essential, useful, questionable]  # 貢献度

next_action: [keep, fix, review, candidate_remove]
```

---

## サマリー

| カテゴリ | ファイル数 | essential | useful | questionable |
|----------|-----------|-----------|--------|--------------|
| Hooks | 7 | 6 | 1 | 0 |
| access-control | 4 | 4 | 0 | 0 |
| playbook-gate | 7 | 3 | 4 | 0 |
| reward-guard | 7 | 7 | 0 | 0 |
| golden-path | 4 | 4 | 0 | 0 |
| prompt-analyzer | 6 | 4 | 2 | 0 |
| quality-assurance | 8 | 2 | 6 | 0 |
| checkers | 11 | 4 | 7 | 0 |
| state/plan-management | 4 | 1 | 3 | 0 |
| session-manager | 6 | 3 | 3 | 0 |
| context-management | 1 | 1 | 0 | 0 |
| post-loop | 3 | 3 | 0 | 0 |
| abort-playbook | 2 | 0 | 2 | 0 |
| git-workflow | 4 | 4 | 0 | 0 |
| **合計** | **74** | **46** | **28** | **0** |

### Next Action 集計

| Action | 件数 |
|--------|------|
| keep | 74 |
| fix | 0 |
| review | 0 |
| candidate_remove | 0 |

---

## 1. Hooks（7ファイル）

| ファイル | why | works | depends | health | value | next_action |
|----------|-----|-------|---------|--------|-------|-------------|
| pre-tool.sh | clear | works | documented | healthy | essential | keep |
| post-tool.sh | clear | works | documented | healthy | essential | keep |
| prompt.sh | clear | works | documented | healthy | essential | keep |
| session-start.sh | clear | works | documented | healthy | useful | keep |
| session.sh | clear | works | documented | healthy | essential | keep |
| subagent-stop.sh | clear | works | documented | healthy | essential | keep |
| generate-repository-map.sh | clear | works | documented | healthy | essential | keep |

### 詳細

#### pre-tool.sh
- **役割**: PreToolUse(*) 導火線 - 全ツール呼び出し前のゲートチェック
- **依存**: 14 guards（access-control, playbook-gate, reward-guard）
- **価値**: Core Contract #1/#2/#3 全て実装

#### post-tool.sh
- **役割**: PostToolUse(*) 導火線 - ツール実行後の処理委譲
- **依存**: archive-playbook.sh, cleanup.sh, create-pr-hook.sh
- **価値**: playbook 完了処理とクリーンアップ

#### prompt.sh
- **役割**: State Injection - playbook/phase 状態をコンテキストに注入
- **依存**: state.md, playbook
- **価値**: Core Contract #1 (Golden Path) 強制

#### session-start.sh
- **役割**: セッション開始時のコンポーネント状態表示 + coherence check
- **依存**: settings.json, skills/, coherence-checker
- **価値**: デバッグ・状態把握支援

#### session.sh
- **役割**: セッションライフサイクルイベントルーター (startup/end/compact)
- **依存**: start.sh, end.sh, compact.sh
- **価値**: セッション管理の中央ルーター

#### subagent-stop.sh
- **役割**: SubAgent 終了後のクリーンアップ + playbook 完了チェック補完 (M089)
- **依存**: archive-playbook.sh
- **価値**: SubAgent 内 Edit の PostToolUse 未発火を補完

#### generate-repository-map.sh
- **役割**: リポジトリ全ファイル自動マッピング + DRIFT 検出
- **依存**: docs/
- **価値**: LLM の自己認識支援

---

## 2. access-control（4ファイル）

| ファイル | why | works | depends | health | value | next_action |
|----------|-----|-------|---------|--------|-------|-------------|
| SKILL.md | clear | works | documented | healthy | essential | keep |
| bash-check.sh | clear | works | documented | healthy | essential | keep |
| main-branch.sh | clear | works | documented | healthy | essential | keep |
| protected-edit.sh | clear | works | documented | healthy | essential | keep |

### 詳細

#### SKILL.md
- **役割**: アクセス制御 - 保護ファイル・ブランチ・Bash 契約チェック
- **依存**: guards/, protected-files.txt
- **価値**: Core Contract file_protection 実装

#### bash-check.sh
- **役割**: 危険 Bash コマンドブロック + HARD_BLOCK 保護 + 回帰テスト実行
- **依存**: pre-tool.sh, coherence.sh
- **価値**: playbook=null で変更系コマンドブロック

#### main-branch.sh
- **役割**: main/master ブランチでの編集系ツールブロック
- **依存**: pre-tool.sh
- **価値**: main 保護（常にブランチを切って作業）

#### protected-edit.sh
- **役割**: HARD_BLOCK/BLOCK/WARN 3階層の保護ファイル編集チェック
- **依存**: protected-files.txt
- **価値**: CLAUDE.md 等の絶対守護

---

## 3. playbook-gate（7ファイル）

| ファイル | why | works | depends | health | value | next_action |
|----------|-----|-------|---------|--------|-------|-------------|
| SKILL.md | clear | works | documented | healthy | essential | keep |
| playbook-guard.sh | clear | works | documented | healthy | essential | keep |
| executor-guard.sh | clear | works | documented | healthy | useful | keep |
| depends-check.sh | clear | works | documented | healthy | useful | keep |
| role-resolver.sh | clear | works | documented | healthy | useful | keep |
| archive-playbook.sh | clear | works | documented | healthy | essential | keep |
| cleanup.sh | clear | works | documented | healthy | useful | keep |

### 詳細

#### SKILL.md
- **役割**: Core Contract #2 - playbook なしでの変更ブロック
- **価値**: Playbook Gate 実装

#### playbook-guard.sh
- **役割**: playbook.active=null で Edit/Write ブロック
- **価値**: playbook 強制

#### archive-playbook.sh
- **役割**: playbook 完了時のアーカイブ + 自動コミット + PR
- **価値**: 完了処理の自動化

---

## 4. reward-guard（7ファイル）

| ファイル | why | works | depends | health | value | next_action |
|----------|-----|-------|---------|--------|-------|-------------|
| SKILL.md | clear | works | documented | healthy | essential | keep |
| critic-guard.sh | clear | works | documented | healthy | essential | keep |
| subtask-guard.sh | clear | works | documented | healthy | essential | keep |
| scope-guard.sh | clear | works | documented | healthy | essential | keep |
| coherence.sh | clear | works | documented | healthy | essential | keep |
| phase-status-guard.sh | clear | works | documented | healthy | essential | keep |
| critic.md | clear | works | documented | healthy | essential | keep |

### 詳細

#### SKILL.md
- **役割**: Core Contract #3 - 報酬詐欺防止
- **価値**: 自己承認バイアス防止

#### critic.md (SubAgent)
- **役割**: done_criteria の独立検証を行う SubAgent
- **価値**: 報酬詐欺防止の中核

---

## 5. golden-path（4ファイル）

| ファイル | why | works | depends | health | value | next_action |
|----------|-----|-------|---------|--------|-------|-------------|
| SKILL.md | clear | works | documented | healthy | essential | keep |
| pm.md | clear | works | documented | healthy | essential | keep |
| codex-delegate.md | clear | works | documented | healthy | essential | keep |
| playbook-init/SKILL.md | clear | works | documented | healthy | essential | keep |

### 詳細

#### pm.md (SubAgent)
- **役割**: タスク開始の必須エントリーポイント SubAgent
- **依存**: playbook-init, understanding-check
- **価値**: playbook 作成の中核

#### codex-delegate.md (SubAgent)
- **役割**: Codex MCP をラップしてコンテキスト膨張防止
- **価値**: 実装作業の委譲

---

## 6. prompt-analyzer（6ファイル）

| ファイル | why | works | depends | health | value | next_action |
|----------|-----|-------|---------|--------|-------|-------------|
| SKILL.md | clear | works | documented | healthy | essential | keep |
| prompt-analyzer.md | clear | works | documented | healthy | essential | keep |
| understanding-check/SKILL.md | clear | works | documented | healthy | essential | keep |
| term-translator/SKILL.md | clear | works | documented | healthy | useful | keep |
| term-translator.md | clear | works | documented | healthy | useful | keep |
| executor-resolver/SKILL.md | clear | works | documented | healthy | useful | keep |

---

## 7. quality-assurance（8ファイル）

| ファイル | why | works | depends | health | value | next_action |
|----------|-----|-------|---------|--------|-------|-------------|
| SKILL.md | clear | works | documented | healthy | essential | keep |
| executor-resolver.md | clear | works | documented | healthy | useful | keep |
| health.sh | clear | works | documented | healthy | useful | keep |
| integrity.sh | clear | works | documented | healthy | useful | keep |
| lint.sh | clear | works | documented | healthy | useful | keep |
| reviewer.md | clear | works | documented | healthy | essential | keep |
| health-checker.md | clear | works | documented | healthy | useful | keep |
| coderabbit-delegate.md | clear | works | documented | healthy | useful | keep |

---

## 8. checkers（11ファイル）

| ファイル | why | works | depends | health | value | next_action |
|----------|-----|-------|---------|--------|-------|-------------|
| lint-checker/SKILL.md | clear | works | documented | healthy | useful | keep |
| test-runner/SKILL.md | clear | works | documented | healthy | essential | keep |
| run-all.sh | clear | works | documented | healthy | essential | keep |
| run-build.sh | clear | works | documented | healthy | useful | keep |
| run-critic.sh | clear | works | documented | healthy | useful | keep |
| run-e2e.sh | clear | works | documented | healthy | useful | keep |
| run-typecheck.sh | clear | works | documented | healthy | useful | keep |
| run-unit.sh | clear | works | documented | healthy | useful | keep |
| deploy-checker/SKILL.md | clear | works | documented | healthy | useful | keep |
| coherence-checker/SKILL.md | clear | works | documented | healthy | essential | keep |
| check.sh | clear | works | documented | healthy | essential | keep |

---

## 9. state/plan-management（4ファイル）

| ファイル | why | works | depends | health | value | next_action |
|----------|-----|-------|---------|--------|-------|-------------|
| apply-fixes.sh | clear | works | documented | healthy | useful | keep |
| state/SKILL.md | clear | works | documented | healthy | essential | keep |
| plan-management/SKILL.md | clear | works | documented | healthy | useful | keep |
| frontend-design/SKILL.md | clear | works | documented | healthy | useful | keep |

---

## 10. session-manager（6ファイル）

| ファイル | why | works | depends | health | value | next_action |
|----------|-----|-------|---------|--------|-------|-------------|
| SKILL.md | clear | works | documented | healthy | essential | keep |
| start.sh | clear | works | documented | healthy | essential | keep |
| end.sh | clear | works | documented | healthy | useful | keep |
| compact.sh | clear | works | documented | healthy | useful | keep |
| init-guard.sh | clear | works | documented | healthy | essential | keep |
| setup-guide.md | clear | works | documented | healthy | useful | keep |

---

## 11. context-management（1ファイル）

| ファイル | why | works | depends | health | value | next_action |
|----------|-----|-------|---------|--------|-------|-------------|
| SKILL.md | clear | works | documented | healthy | essential | keep |

---

## 12. post-loop（3ファイル）

| ファイル | why | works | depends | health | value | next_action |
|----------|-----|-------|---------|--------|-------|-------------|
| SKILL.md | clear | works | documented | healthy | essential | keep |
| pending-guard.sh | clear | works | documented | healthy | essential | keep |
| complete.sh | clear | works | documented | healthy | essential | keep |

---

## 13. abort-playbook（2ファイル）

| ファイル | why | works | depends | health | value | next_action |
|----------|-----|-------|---------|--------|-------|-------------|
| SKILL.md | clear | works | documented | healthy | useful | keep |
| abort.sh | clear | works | documented | healthy | useful | keep |

---

## 14. git-workflow（4ファイル）

| ファイル | why | works | depends | health | value | next_action |
|----------|-----|-------|---------|--------|-------|-------------|
| SKILL.md | clear | works | documented | healthy | essential | keep |
| create-pr.sh | clear | works | documented | healthy | essential | keep |
| create-pr-hook.sh | clear | works | documented | healthy | essential | keep |
| merge-pr.sh | clear | works | documented | healthy | essential | keep |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-03 | 初版作成。全 74 ファイルの 5 軸評価完了。 |
