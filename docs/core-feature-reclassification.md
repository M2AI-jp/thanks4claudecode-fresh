# core-feature-reclassification.md

> SSOT: Hook Unit catalog + dependency map (ideal -> current -> missing).
> Boundary = Hook event timing. One unit = Hook -> components -> Skill/SubAgent -> docs.

---

## 0. 目的と判断基準

この設計図の目的は「最小化」ではない。
**Hook 起点の疎結合モジュール**として、必要な体験と検証を確実に実現するための地図である。

判断基準:
- ユーザー体験（理想フロー）に必要か
- Hook Unit 境界に閉じているか（外部依存が広がらないか）
- 失敗時の安全性と復旧性を担保できるか
- 変更理由が 1 つにまとまっているか（単一責任）

---

## 1. なぜ Hook -> Skill -> SubAgent(or Skill) なのか

Claude Code 公式の Hook は「イベントで発火できる入口」を提供するが、
**「内部構成」「責務の分離」「検証の独立性」**までは保証しない。

このリポジトリは以下を狙って、Hook -> Skill -> SubAgent(or Skill) を採用する:

- Hook を薄く保ち、**イベント境界で疎結合**を維持する
- Skill をユースケース単位の**安定インターフェース**にする
- SubAgent を**独立検証者**として分離し、自己承認バイアスを抑える
- Hook Unit 単位で機能を差し替え可能にし、拡張と削除を容易にする

結論: Hook は「入口」、Skill は「パッケージ」、SubAgent は「独立検証」。
この 3 層を分けることで、公式フック以上の**安全性・拡張性・検証性**を担保する。

---

## 2. 理想のユーザーフロー（完成形）

ユーザー体験は **「依頼 -> 計画 -> 実行 -> 検証 -> 完了」**の一本線で崩れないことが前提。

```text
1) ユーザー依頼
   -> UserPromptSubmit Unit が意図を解析
   -> playbook を作成（plan/progress のみ）
   -> reviewer が検証し、state.md に反映

2) 実行
   -> PreToolUse(Edit/Write/Bash) Unit が playbook gate と安全性を強制
   -> executor に従って作業（codex/coderabbit/user）
   -> validations を実行

3) 検証
   -> critic が done_criteria を証拠ベースで判定
   -> PASS のみ完了へ進む

4) 完了
   -> PostToolUse(Edit) Unit が整理・PRフロー・アーカイブを実施
   -> Stop/SessionEnd/Notification が状態を記録
```

このフローを **Hook Unit 単位**で保証することが最重要の設計目標。

---

## 3. Dogfooding 所見（根拠の接続）

| 所見 | 対応する Hook Unit | 影響 | 設計上の対応 |
|---|---|---|---|
| prompt-analyzer 強制は正常動作 | user-prompt-submit | 維持 | 強制フローを維持、unit validator/telemetry を追加 |
| main ブランチ保護が正常動作 | pre-tool-edit | 維持 | access-control を guardrail 中核に固定 |
| critic が呼ばれず自己完了し得る | pre-tool-edit / reward-guard | 高 | Phase 完了時の critic 強制（guardrail 増設） |
| coderabbit が差分ベースで動作 | user-prompt-submit / executor | 中 | レビュータイミングを「コミット前 or PR ベース」に再設計 |
| git-workflow hook が発火しない | post-tool-edit | 低 | chain 側で PR/merge フローを強制化 |
| playbook gate / reward-guard 未検証 | pre-tool-edit | 中 | health/integrity の検証項目として追加 |
| playbook 生成中に実装が走る / reviewer が user で自己承認 / progress schema 逸脱 | user-prompt-submit / pre-tool-edit | 高 | planning-only で非playbook編集をブロック、reviewer 独立性と progress schema を強制 |

---

## 4. 現状確認（実装から抽出）

現行の Hook dispatch と chain は以下（ファイル実体ベース）:

- SessionStart: `.claude/hooks/session.sh` -> `.claude/events/session-start/chain.sh` -> `.claude/skills/session-manager/handlers/start.sh`
- UserPromptSubmit: `.claude/hooks/prompt.sh` -> `.claude/events/user-prompt-submit/chain.sh`（prompt-analyzer 呼び出しを指示）
- PreToolUse (共通): `.claude/hooks/pre-tool.sh` -> `session-manager/handlers/init-guard.sh` -> `access-control/guards/main-branch.sh`
- PreToolUse Edit/Write: `.claude/events/pre-tool-edit/chain.sh` -> post-loop/pending-guard -> access-control/protected-edit -> playbook-gate/playbook-guard -> depends-check -> executor-guard -> reward-guard/critic-guard -> subtask-guard -> phase-status-guard -> scope-guard
- PreToolUse Bash: `.claude/events/pre-tool-bash/chain.sh` -> access-control/bash-check -> reward-guard/coherence -> quality-assurance/lint
- PostToolUse Edit: `.claude/hooks/post-tool.sh` -> `.claude/events/post-tool-edit/chain.sh` -> playbook-gate/archive-playbook -> playbook-gate/cleanup -> git-workflow/create-pr-hook
- SubagentStop: `.claude/hooks/subagent-stop.sh` -> `.claude/events/subagent-stop/chain.sh` -> subagent log -> archive-playbook（疑似 Edit）
- PreCompact: `.claude/settings.json` -> `.claude/events/pre-compact/chain.sh` -> session-manager/handlers/compact.sh
- Stop: `.claude/settings.json` -> `.claude/events/stop/chain.sh`（no-op）
- SessionEnd: `.claude/settings.json` -> `.claude/events/session-end/chain.sh` -> session-manager/handlers/end.sh
- Notification: `.claude/settings.json` -> `.claude/events/notification/chain.sh`（no-op）

---

## 5. Hook Timing Index（公式フック: 全タイミング）

> 参照: https://code.claude.com/docs/en/hooks

| Hook timing | Matcher | 役割（非機能要件の入口） | 現状 |
|---|---|---|---|
| SessionStart | `startup` / `resume` / `clear` / `compact` | セッション整合・起動健全性 | wired |
| UserPromptSubmit | - | 依頼理解・計画生成 | wired (partial) |
| PreToolUse | `tool_name` で分岐 | 実行前ガードレール | wired |
| PostToolUse | `tool_name` で分岐 | 完了処理・自動化 | wired (Edit) |
| SubagentStop | - | SubAgent 後処理 | wired |
| PreCompact | `manual` / `auto` | コンテキスト保全 | wired |
| Stop | - | 応答終了の記録 | no-op |
| SessionEnd | - | セッション終了処理 | wired |
| Notification | - | 通知ログ/テレメトリ | no-op |

---

## 6. ユーザー体験のファイルマッピング（SSOT）

ユーザー体験は **Hook Unit → Skill パッケージ → ファイル**で追跡できる必要がある。
ここでは「体験の入口」をファイルで固定する。

### 依頼の理解と playbook 生成
- Hook: UserPromptSubmit
- Files:
  - `.claude/hooks/prompt.sh`
  - `.claude/events/user-prompt-submit/chain.sh`
  - `.claude/skills/prompt-analyzer/agents/prompt-analyzer.md`
  - `.claude/skills/understanding-check/SKILL.md`
  - `.claude/skills/playbook-init/SKILL.md`
  - `.claude/skills/golden-path/agents/pm.md`
  - `.claude/skills/quality-assurance/agents/reviewer.md`
  - `.claude/agents/{pm,reviewer}.md`（Task が参照する登録ディレクトリ）
  - `play/template/plan.json`
  - `play/template/progress.json`
  - `play/README.md`
  - `state.md`
  - 方針: planning-only（plan/progress 以外の編集は禁止）
  - 方針: reviewer は独立（user 不可、state.md の roles.reviewer と一致）
  - 方針: progress.json は template 構造に準拠

### 実行前の安全性（Edit/Write）
- Hook: PreToolUse(Edit/Write)
- Files:
  - `.claude/hooks/pre-tool.sh`
  - `.claude/events/pre-tool-edit/chain.sh`
  - `.claude/skills/session-manager/handlers/init-guard.sh`
  - `.claude/skills/access-control/guards/main-branch.sh`
  - `.claude/skills/access-control/guards/protected-edit.sh`
  - `.claude/skills/playbook-gate/guards/playbook-guard.sh`
  - `.claude/skills/reward-guard/guards/critic-guard.sh`
  - `.claude/skills/reward-guard/guards/subtask-guard.sh`
  - `.claude/skills/reward-guard/guards/phase-status-guard.sh`
  - `.claude/skills/reward-guard/guards/scope-guard.sh`
  - `.claude/frameworks/done-criteria-validation.md`
  - `.claude/protected-files.txt`

### 実行前の安全性（Bash）
- Hook: PreToolUse(Bash)
- Files:
  - `.claude/events/pre-tool-bash/chain.sh`
  - `.claude/skills/access-control/guards/bash-check.sh`
  - `.claude/skills/reward-guard/guards/coherence.sh`
  - `.claude/skills/quality-assurance/checkers/lint.sh`
  - `scripts/contract.sh`

### 完了処理と PR/マージ自動化
- Hook: PostToolUse(Edit)
- Files:
  - `.claude/hooks/post-tool.sh`
  - `.claude/events/post-tool-edit/chain.sh`
  - `.claude/skills/playbook-gate/workflow/archive-playbook.sh`
  - `.claude/skills/playbook-gate/workflow/cleanup.sh`
  - `.claude/skills/git-workflow/handlers/create-pr-hook.sh`
  - `.claude/skills/git-workflow/handlers/create-pr.sh`
  - `.claude/skills/git-workflow/handlers/merge-pr.sh`
  - `state.md`

### セッションライフサイクル
- Hook: SessionStart / PreCompact / SessionEnd
- Files:
  - `.claude/hooks/session.sh`
  - `.claude/events/session-start/chain.sh`
  - `.claude/skills/session-manager/handlers/start.sh`
  - `.claude/events/pre-compact/chain.sh`
  - `.claude/skills/session-manager/handlers/compact.sh`
  - `.claude/events/session-end/chain.sh`
  - `.claude/skills/session-manager/handlers/end.sh`
  - `docs/repository-map.yaml`

### SubAgent 終了後の完了補完
- Hook: SubagentStop
- Files:
  - `.claude/hooks/subagent-stop.sh`
  - `.claude/events/subagent-stop/chain.sh`
  - `.claude/skills/playbook-gate/workflow/archive-playbook.sh`

### 応答終了・通知（将来拡張）
- Hook: Stop / Notification
- Files:
  - `.claude/events/stop/chain.sh`
  - `.claude/events/notification/chain.sh`

---

## 7. Hook 内 Skill 評価（非機能要件の整理）

ここでは **Hook timing ごとに Skill パッケージの価値と要否を評価**する。
細かな仕様は Skill 内部に閉じる。

### SessionStart
| Skill | 非機能要件の役割 | 評価 |
|---|---|---|
| session-manager | 状態整合・初期化 | core / keep |
| quality-assurance (health/integrity) | 健全性/ドリフト検出 | core / wire |

### UserPromptSubmit
| Skill | 非機能要件の役割 | 評価 |
|---|---|---|
| prompt-analyzer | 依頼の明確化 | core / keep |
| understanding-check | 合意形成 | core / keep |
| playbook-init | チェーン強制 | core / keep |
| golden-path (pm) | 計画生成 | core / keep |
| quality-assurance (reviewer) | 計画品質保証 | core / keep |
| executor-resolver (via pm) | 実行者整合 | core / keep |

### PreToolUse(Edit/Write)
| Skill | 非機能要件の役割 | 評価 |
|---|---|---|
| session-manager (init-guard) | 状態前提の強制 | core / keep |
| access-control | 破壊的操作の遮断 | core / keep |
| post-loop | 完了後の安全遷移 | core / keep |
| playbook-gate | playbook 準拠強制 | core / keep |
| reward-guard | 報酬詐欺防止 | core / keep + strengthen |

### PreToolUse(Bash)
| Skill | 非機能要件の役割 | 評価 |
|---|---|---|
| access-control | コマンド安全性 | core / keep |
| reward-guard | 参照整合・逸脱検出 | core / keep |
| quality-assurance (lint) | 変更品質 | conditional / keep |

### PostToolUse(Edit)
| Skill | 非機能要件の役割 | 評価 |
|---|---|---|
| playbook-gate (archive/cleanup) | 完了処理 | core / keep |
| git-workflow | PR/マージ自動化 | core / keep |

### SubagentStop
| Skill | 非機能要件の役割 | 評価 |
|---|---|---|
| playbook-gate (archive) | 完了補完 | core / keep |

### PreCompact
| Skill | 非機能要件の役割 | 評価 |
|---|---|---|
| session-manager (compact) | コンテキスト保全 | core / keep |

### Stop
| Skill | 非機能要件の役割 | 評価 |
|---|---|---|
| (none) | 応答終了の記録 | missing / telemetry |

### SessionEnd
| Skill | 非機能要件の役割 | 評価 |
|---|---|---|
| session-manager (end) | 後処理 | core / keep |

### Notification
| Skill | 非機能要件の役割 | 評価 |
|---|---|---|
| (none) | 通知ログ | missing / telemetry |

---

## 8. Hook Unit Interface（target contract）

各ユニットは同じコンポーネント構造を持つ:

- `validator`: 入力検証・整形
- `context-injector`: そのタイミングに必要な情報だけ注入
- `guardrail`: 破壊的操作の遮断
- `telemetry`: 成功/失敗/遅延の記録
- `retry`: 失敗時の再試行（任意）
- `snapshot`: 事前状態保存（任意）
- `chain`: Skill/SubAgent の呼び出し

Target layout:

```
.claude/events/<event-unit>/
  validator.sh
  context-injector.sh
  guardrail.sh
  telemetry.sh
  retry.sh        # optional
  snapshot.sh     # optional
  chain.sh
```

---

## 9. Component Contract（詳細仕様）

共通ルール:
- stdin: Hook から渡された JSON をそのまま受け取る
- exit code: 0=allow, 2=block, other=warn（Hook は続行）
- stdout: context-injector / pre-compact 以外は原則出力しない
- side effects: `.claude/session-state/` と `.claude/logs/` のみ

推奨環境変数:
```
REPO_ROOT
STATE_FILE
UNIT_DIR
UNIT_STATE_DIR=.claude/session-state/<event-unit>
```

### validator.sh
- 役割: 必須フィールド検証、パス正規化、入力整形
- 出力: `$UNIT_STATE_DIR/validated-input.json` に保存
- 失敗: stderr に理由を出して exit 2（fail-closed）

### context-injector.sh
- 役割: state/playbook を読み、必要最小限の情報だけ注入
- 出力:
  - UserPromptSubmit / PreCompact: stdout に JSON を出力
  - その他: `$UNIT_STATE_DIR/context.json` に保存

### guardrail.sh
- 役割: 破壊的操作の遮断とポリシー適用
- 出力: stderr に理由を出して exit 2（block）
- 重要: 直接の編集や状態変更は行わない

### snapshot.sh
- 役割: 破壊的操作の直前に状態を保存
- 出力: `$UNIT_STATE_DIR/snapshot.json`（最小情報）

### retry.sh
- 役割: ネットワーク/一時エラーのみ再試行
- 制約: 破壊的操作は再試行しない
- 既定: exponential backoff / max 3 回

### telemetry.sh
- 役割: 成功/失敗/所要時間を記録
- 出力: `.claude/logs/<event-unit>.log`（JSONL 推奨）

### chain.sh
- 役割: コンポーネント順序の制御と Skill/SubAgent の呼び出し
- 順序: validator -> context-injector -> guardrail -> snapshot -> chain(skills) -> telemetry
- 注記: validated-input があればそれを使用し、未検証入力は使用しない

---

## 10. Hook Unit 目録（理想 -> 現状 -> 欠落）

Format:
`event unit -> intent -> chain -> docs -> outputs -> status`

### session-start
- intent: セッション開始時の状態整合と初期検証
- chain (ideal): session-manager/start -> quality-assurance/health -> quality-assurance/integrity
- docs: state.md, docs/repository-map.yaml, docs/ARCHITECTURE.md
- outputs: 初期状態の警告/ドリフト報告
- status:
  - current: chain.sh + session-manager/start + quality-assurance(health/integrity)
  - missing: guardrail/telemetry 分離

### user-prompt-submit
- intent: 依頼の意図理解と playbook 生成
- chain (ideal): prompt-analyzer -> understanding-check -> playbook-init -> pm -> reviewer
- docs: play/template/plan.json, play/template/progress.json, play/README.md
- outputs: 解析結果 + playbook + reviewer verdict
- status:
  - current: prompt-analyzer 経由だが unit validator/telemetry 未分離
  - missing: unit-level validator/telemetry/guardrail

### pre-tool-edit
- intent: 変更系操作の安全性と playbook 準拠を強制
- chain (ideal):
  session-manager/init-guard -> access-control/main-branch -> post-loop/pending-guard
  -> access-control/protected-edit -> playbook-gate/playbook-guard
  -> playbook-gate/depends-check -> playbook-gate/executor-guard
  -> reward-guard/critic-guard -> reward-guard/subtask-guard
  -> reward-guard/phase-status-guard -> reward-guard/scope-guard
- docs: state.md, playbook.active, .claude/protected-files.txt, .claude/frameworks/done-criteria-validation.md
- outputs: allow/block + 理由
- status:
  - current: guardrail 集中、snapshot/telemetry 未分離
  - missing: validator/telemetry/snapshot 分割、critic 強制トリガーの強化

### pre-tool-bash
- intent: 破壊的コマンドの遮断と契約チェック
- chain (ideal): access-control/bash-check -> reward-guard/coherence -> quality-assurance/lint
- docs: state.md, scripts/contract.sh
- outputs: allow/block + 理由
- status:
  - current: guardrail 集中、retry/telemetry 未分離
  - missing: retry/telemetry 分割

### post-tool-edit
- intent: 作業後の整理とレポート
- chain (ideal): playbook-gate/archive-playbook -> playbook-gate/cleanup -> git-workflow/create-pr-hook
- docs: docs/repository-map.yaml
- outputs: アーカイブ/整理/PR
- status:
  - current: chain のみ
  - missing: validator/telemetry

### subagent-stop
- intent: SubAgent 結果の記録と後処理
- chain (ideal): subagent-stop logger -> playbook-gate/archive-playbook
- docs: state.md
- outputs: subagent log + 完了判定
- status:
  - current: 簡易ログのみ
  - missing: validator/telemetry 分割

### pre-compact
- intent: コンテキスト縮約と復元橋の生成
- chain (ideal): session-manager/compact
- docs: state.md, playbook.active
- outputs: additionalContext
- status:
  - current: context-injector のみ
  - missing: validator/telemetry/snapshot

### stop
- intent: 応答完了時の記録
- chain (ideal): telemetry + snapshot
- docs: state.md
- outputs: 応答サマリ
- status:
  - current: no-op
  - missing: telemetry/snapshot/chain

### session-end
- intent: セッション終了時の健康状態記録
- chain (ideal): session-manager/end
- docs: state.md
- outputs: 終了時の警告/状態
- status:
  - current: end.sh のみ
  - missing: validator/telemetry/snapshot 分割

### notification
- intent: 通知イベントの記録
- chain (ideal): telemetry only
- docs: none
- outputs: notification log
- status:
  - current: no-op
  - missing: telemetry

---

## 11. Hook Unit 実装タスク分解（component stub / chain wiring）

方針: 各 Unit の `chain.sh` から component stub を必ず呼ぶ。
現行ロジックは component に移送し、chain は順序制御のみを担う。

### session-start
- create: validator.sh / context-injector.sh / telemetry.sh / guardrail.sh
- move: start.sh の state 取得と drift 警告を context-injector / telemetry に分割
- wire: chain.sh が component -> session-manager/start を順に実行

### user-prompt-submit
- create: validator.sh / context-injector.sh / telemetry.sh / guardrail.sh
- move: prompt.sh の state 注入ロジックを context-injector に分離
- wire: chain.sh が validator -> context-injector -> prompt-analyzer を強制

### pre-tool-edit
- create: validator.sh / telemetry.sh / snapshot.sh
- move: init-guard / guard scripts を guardrail に整理
- add: Phase 完了時の critic 強制トリガー（subtask or status change）

### pre-tool-bash
- create: validator.sh / telemetry.sh / retry.sh
- move: bash-check/coherence/lint を guardrail に整理
- add: retry はネットワーク系の失敗に限定

### post-tool-edit
- create: validator.sh / telemetry.sh
- wire: archive/cleanup/create-pr を chain に固定
- add: PR 作成時の git-workflow を強制

### subagent-stop
- create: validator.sh / telemetry.sh
- wire: subagent log -> archive-playbook を chain に固定

### pre-compact
- create: validator.sh / telemetry.sh / snapshot.sh
- move: compact.sh の出力生成を context-injector として明確化

### stop
- create: telemetry.sh / snapshot.sh
- wire: chain.sh で記録のみ行う

### session-end
- create: validator.sh / telemetry.sh / snapshot.sh
- move: end.sh を chain から呼び出し、telemetry を分離

### notification
- create: telemetry.sh
- wire: chain.sh で notification を記録

---

## 12. Skill/SubAgent 必要性評価（価値と役割）

判断軸:
- Hook Unit に直結するか（ユーザーフローの必須ライン）
- 同じ役割が重複していないか（統合余地）
- 特定の toolstack / playbook 依存か（条件付き）

### Skills（決定）

| Skill | Hook Unit | 価値/役割 | 判定 | アクション |
|---|---|---|---|---|
| session-manager | session-start, pre-compact, session-end | 状態初期化/compact/終了処理 | core | keep |
| prompt-analyzer | user-prompt-submit | 依頼理解の強制 | core | keep |
| term-translator | user-prompt-submit | 用語整備と曖昧さ除去 | remove | prompt-analyzer に統合 |
| understanding-check | user-prompt-submit | 要件確認の強制 | core | keep |
| playbook-init | user-prompt-submit | playbook 起点 | core | keep |
| golden-path | user-prompt-submit | pm/reviewer の編成 | core | keep |
| plan-management | user-prompt-submit | plan 更新の一貫性 | remove | pm/state に統合 |
| state | user-prompt-submit, pre-tool-edit | state 操作の単一窓口 | core | keep |
| access-control | pre-tool-edit, pre-tool-bash | main/protected/bash ガード | core | keep |
| post-loop | pre-tool-edit | playbook 完了後の遷移ガード | core | keep |
| playbook-gate | pre-tool-edit, post-tool-edit | playbook gate + archive/cleanup | core | keep |
| reward-guard | pre-tool-edit, pre-tool-bash | critic/phase/subtask ガード | core | keep + 強化 |
| quality-assurance | session-start, pre-tool-bash | health/integrity/lint | core | keep + unit 配線 |
| executor-resolver | pre-tool-edit | executor 役割解決 | core | keep |
| git-workflow | post-tool-edit | PR/merge 体験 | conditional | PR 自動化を使わないなら削除 |

### SubAgents（決定）

| SubAgent | Hook Unit | 価値/役割 | 判定 | アクション |
|---|---|---|---|---|
| pm | user-prompt-submit | playbook 作成の中核 | core | keep |
| reviewer | user-prompt-submit | playbook 品質検証 | core | keep |
| critic | pre-tool-edit | done_criteria 検証 | core | keep + 強制 |
| prompt-analyzer | user-prompt-submit | 依頼解析 | core | keep |
| term-translator | user-prompt-submit | 曖昧さ解消 | remove | prompt-analyzer に統合 |
| executor-resolver | pre-tool-edit | executor 判定 | core | keep |
| codex-delegate | pre-tool-edit | 実装委譲 | conditional | codex 運用しないなら削除 |
| coderabbit-delegate | pre-tool-edit / review | レビュー委譲 | conditional | coderabbit 運用しないなら削除 |
| health-checker | session-start | 監視補助 | remove | unit に配線しないなら削除 |
| setup-guide | session-start | setup 専用 | remove | setup playbook を使わないなら削除 |

### 削除優先候補（コンテキスト削減）

- term-translator（SubAgent/Skill）: prompt-analyzer に統合して二重化を解消
- plan-management: pm/state に統合し、入口を 1 つに固定
- health-checker: unit 配線がない場合は削除
- setup-guide: setup playbook を廃止するなら削除

---

## 13. フォルダ構成図（現在）

```
.
├── AGENTS.md
├── CLAUDE.md
├── README.md
├── state.md
├── .gitignore
├── .mcp.json
├── .env.example
├── .shellcheckrc
├── docs/
├── governance/
├── play/
├── scripts/
├── tmp/
└── .claude/
```

### .claude/ 構成（主要ディレクトリ）

```
.claude/
├── agents/  # Task registry (synced from .claude/skills/*/agents)
├── events/
├── hooks/
├── skills/
├── frameworks/
├── lib/
├── settings.json
└── protected-files.txt
```

---

## 14. ファイル構成図（設計に必要な範囲）

```
.claude/
├── agents/  # Task registry (synced from .claude/skills/*/agents)
├── hooks/
│   ├── session.sh
│   ├── prompt.sh
│   ├── pre-tool.sh
│   ├── post-tool.sh
│   └── subagent-stop.sh
├── events/
│   ├── session-start/chain.sh
│   ├── user-prompt-submit/chain.sh
│   ├── pre-tool-edit/chain.sh
│   ├── pre-tool-bash/chain.sh
│   ├── post-tool-edit/chain.sh
│   ├── subagent-stop/chain.sh
│   ├── pre-compact/chain.sh
│   ├── stop/chain.sh
│   ├── session-end/chain.sh
│   └── notification/chain.sh
├── frameworks/*.md
├── lib/common.sh
├── settings.json
└── protected-files.txt

.claude/skills/
├── access-control/guards/*.sh
├── executor-resolver/agents/executor-resolver.md
├── git-workflow/handlers/*.sh
├── golden-path/agents/{pm,codex-delegate}.md
├── playbook-gate/guards/*.sh
├── playbook-gate/workflow/*.sh
├── playbook-init/SKILL.md
├── post-loop/{guards,handlers}/*.sh
├── prompt-analyzer/agents/prompt-analyzer.md
├── quality-assurance/checkers/{health,integrity,lint}.sh
├── quality-assurance/agents/{reviewer,coderabbit-delegate}.md
├── reward-guard/guards/*.sh
├── reward-guard/agents/critic.md
├── session-manager/handlers/{start,compact,end,init-guard}.sh
├── state/SKILL.md
└── understanding-check/SKILL.md

Docs (SSOT)
├── docs/ARCHITECTURE.md
├── docs/core-feature-reclassification.md
├── docs/repository-map.yaml
```

---

## 15. 作業指示書（次のエージェント向け）

目的: 上記 Hook Unit 目録を SSOT として、現状の実装と差分を埋める。

手順:
1. このファイルを SSOT として固定
2. Unit ごとに component stub を作成し chain に配線
3. 既存ロジックを component に移送（挙動変更なし）
4. Dogfooding 所見に対応する強制条件を実装
5. Skill/SubAgent の判定に基づき保持/削除を実施
6. 変更後は `docs/repository-map.yaml` を再生成

---

## 16. Doc Retention Rule

この設計図に明示的に参照されないドキュメントは削除候補。
ただし「理想ユーザーフロー」「Hook Unit 依存マップ」の SSOT は必ず維持する。

保持対象:
- `CLAUDE.md`
- `AGENTS.md`
- `README.md`
- `state.md`
- `docs/ARCHITECTURE.md`
- `docs/core-feature-reclassification.md`
- `docs/repository-map.yaml`
- `play/template/plan.json`
- `play/template/progress.json`
- `play/README.md`
- `governance/PROMPT_CHANGELOG.md`
