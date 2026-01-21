# 失敗主導シミュレーション: ChatGPTクローン（最新仕様 / ディレクターズ・カット）

> 文書の位置付け: 運用脚本（ケーススタディ）
>
> 読み順: README.md を参照
>
> 一次仕様: REBUILD-DESIGN-SPEC.md
>
> 構築手順: BUILD-FROM-SCRATCH.md
>
> 更新基準: playbook v2 / Event Unit Architecture / Evidence 3点検証 / Temporal Achievability / I-RF / I-DL

## 読み方（ゼロコンテキスト）

- `## [...]` はユーザーの発話
- それ以外は舞台指示（Scene）、内心（User POV）、システム制御（System POV）
- 成功よりも「問題の検知と回復」が主軸
- ChatGPT クローンを題材に、仕組みが失敗を吸収する過程を描く

## 前提（読むタイミング）

- BUILD-FROM-SCRATCH の Phase 8 まで完了していること
- `.claude/agents/` と `.claude/skills/` と `play/template/` が揃っていること
- 構築前に読む場合は「運用の完成像の参考資料」として扱うこと

## 用語（1行で把握できる定義）

- Hook: 公式イベント入口。強制できるのは「ブロック/初期化」まで
- Event Unit: Hook の実処理単位。validator/context/guardrail/telemetry を内包
- Skill: 1 機能単位のパッケージ。必要なら SubAgent を呼ぶ
- SubAgent: 役割分離された担当者。Task の直接呼び出しは禁止
- playbook v2: plan.json（不変）+ progress.json（可変）の二層構造
- context: prompt-analyzer の結果を plan.json に永続化する領域
- state.md: セッションを跨ぐ状態の真実源
- Evidence: 出力 + 検証方法 + 結果（PASS/FAIL）の3点セット
- playbook-reviewer: plan.json の事前検証を担う
- code-reviewer: 実装コードの検証を担う
- critic: 最終完了判定を担う（自己申告は不可）

## 非交渉ルール（最新仕様）

- playbook.active が null の場合、Edit/Write/Bash は停止
- plan.json は reviewer PASS 後に凍結し、変更は禁止
- done は critic PASS + Evidence 凍結 + archive 完了まで禁止
- Task(subagent_type=...) の直接呼び出しは禁止
- Evidence が 3点検証を満たさない場合は「存在しない」と扱う

## 報酬詐欺防止（最優先）

- 自己申告の完了は I-RF-2 として即停止
- Output と Evidence が一致しない場合は I-RF-1
- critic は evidence の 3点検証（technical/consistency/completeness）を要求

## デッドロック回避（最優先）

- ゲート停滞は I-DL-1 を発火し、人間ゲートに退避
- 同一失敗の反復は I-DL-2 として原因分離/縮退へ移行
- 停滞時は「停止/継続/縮退/中断」を user に提示

## 自動化と手動の境界

- Hook 強制可能: Event Unit 連鎖（ブロック/初期化）、ファイル保護、playbook ゲート
- Skill/SubAgent 実行: 検証、Evidence 記録、progress.json 更新（LLM 判断依存）
- 手動: 要件承認、スコープ変更承認、Go/No-Go、最終リリース承認

## Issue コード（運用で使う最小集合）

- I-BOOT-1: 前提欠落（dependency-check -> user 補完）
- I-REQ-2: 要件矛盾（conflict report -> user 判断）
- I-RF-1: 証拠不一致（evidence-audit -> 再検証）
- I-RF-2: 自己申告完了（critic-gate -> 進行停止）
- I-PLAN-FREEZE: plan 凍結違反（plan 変更試行 -> 進行停止）
- I-DL-1: ゲート停滞（deadlock-breaker -> user 判断）
- I-DL-2: 反復失敗（root-cause -> scope 縮退）

## Evidence と 3点検証

- technical: 実行可能なコマンドで証明する
- consistency: 関係ファイルと矛盾しないこと
- completeness: 欠落のない状態であること

Evidence は `docs/evidence/phase-*.md` に集約し、実行ログは `reports/tests/` と `reports/review/` に保存する。

## Temporal Achievability（時間的達成可能性）

- reviewer は plan.json の criterion を時間軸で検証する
- 「将来完了していること」を前提にした criterion は FAIL
- 時間的達成可能性はデッドロック回避と同じく重要

## 登場人物（役割）

- 人間: 最終承認と方向修正
- orchestrator: 全体調整と主体間の調整
- planner: playbook 作成
- prompt-analyzer: 解釈/前提/リスク整理
- progress-tracker: 進捗追跡と progress.json 更新
- playbook-reviewer: plan.json の検証
- code-reviewer: 実装の検証
- critic: 完了判定
- codex-invoker: 実装委譲（判断しない）
- coderabbit-invoker: レビュー委譲（判断しない）
- review-aggregator: レビュー結果の統合

## フェーズゲート（進行判定）

- 理解: 解釈結果 + 人間確認
- 計画: plan.json + reviewer PASS + plan 凍結
- 実装: コード変更 + テスト PASS
- 検証: code reviewer PASS
- 完了: critic PASS + Evidence 凍結 + archive

---

### ACT 0: ブートストラップ（世界の扉が閉じている）

## [B-00] 「今の状態を読んで、続きから始めて。」

### Scene
ユーザーは席に着く。前回の作業は中断されている。セッションは空白から始まる。

### User POV
「どこまで進んだのか分からない。続きを再開したい。」

### System POV
SessionStart の Event Unit が state.md と playbook を読み込み、playbook.active が null なら編集は停止される。

### Event Units/Hooks
- SessionStart -> events/session-start/chain.sh
- PreToolUse -> events/pre-tool/guardrail.sh

### Required Skills
- state-updater
- playbook-gate
- integrity-checker

### Called SubAgents
- orchestrator

### Output
- 現在の playbook.active と progress.json の読み込み結果

### Evidence
- docs/evidence/phase-bootstrap.md

### Done Criteria
- state.md と playbook.active の整合確認が完了

### Failure/Recovery
- state.md が壊れている -> integrity-check -> Git 復元
- playbook.active が null -> I-BOOT-1 -> user 補完

### Deadlock Watch
- playbook が無いまま停止したら I-DL-1

### Next
- [B-01]

## [B-01] 「前提チェックをして、足りないものを出して。」

### Scene
システムは静かに前提条件を洗い出す。動かない理由を光に晒す。

### User POV
「どれが足りないのか知りたい。いまの停止は正常なのか？」

### System POV
dependency-check が Hook/Skill/SubAgent の稼働可否を確認し、不足は playbook.issue-log に記録する。

### Event Units/Hooks
- UserPromptSubmit -> events/prompt/chain.sh

### Required Skills
- dependency-check

### Called SubAgents
- orchestrator

### Output
- 前提チェックリスト（present/missing/blocked）

### Evidence
- docs/evidence/phase-bootstrap.md（追記）

### Done Criteria
- 不足項目に owner と補完方針が付与される

### Failure/Recovery
- 前提が埋まらない -> I-BOOT-1 -> user 補完

### Deadlock Watch
- 前提確認が反復したら I-DL-2

---

### ACT 1: 理解（曖昧さが敵）

## [U-00] 「ChatGPT クローンを作りたい。まず理解して。」

### Scene
ユーザーの目的が投げ込まれる。まだ形はない。

### User POV
「最短で作りたい。でも曖昧なままだと詰まる。」

### System POV
topic-classifier が分類し、prompt-analyzer が前提・制約・リスクを整理する。ここで context の原型が生まれる。

### Event Units/Hooks
- UserPromptSubmit -> events/prompt/chain.sh

### Required Skills
- topic-classifier

### Called SubAgents
- prompt-analyzer
- orchestrator

### Output
- 解釈サマリ（目的/制約/未確定/リスク）

### Evidence
- docs/evidence/phase-understanding.md

### Done Criteria
- 解釈サマリに未確定項目が明記される

### Failure/Recovery
- 要件が矛盾する -> I-REQ-2 -> user 判断

### Deadlock Watch
- 未確定が減らない -> I-DL-1

### Next
- [U-01]

## [U-01] 「確認質問を全部出して。」

### Scene
質問が列挙される。人間の意思決定が必要になる。

### User POV
「答えるべきことが一気に来る。ここで迷うと後で崩れる。」

### System POV
prompt-analyzer が特定した未確定項目に対し、AskUserQuestion を直接使って確認する。回答は context として plan.json に引き継がれる。

### Event Units/Hooks
- UserPromptSubmit -> events/prompt/chain.sh

### Required Skills
- prompt-analyzer（確認質問の生成）

### Called SubAgents
- orchestrator

### Output
- 確認質問リスト

### Evidence
- docs/evidence/phase-understanding.md（追記）

### Done Criteria
- 回答が context として記録可能な形で整理される

### Failure/Recovery
- 回答が不足 -> I-REQ-2 -> 再質問

---

### ACT 2: 計画（playbook v2 の確定）

## [P-00] 「plan.json と progress.json を作って。」

### Scene
計画が形になる瞬間。ここで未来の事故が決まる。

### User POV
「計画が欲しい。あとからやり直せないから、ここは慎重に。」

### System POV
playbook-creator が plan.json と progress.json を生成。context セクションに解釈結果を永続化する。

### Event Units/Hooks
- UserPromptSubmit -> events/prompt/chain.sh

### Required Skills
- playbook-creator

### Called SubAgents
- planner
- progress-tracker

### Output
- plan.json（goal/scope/phases/validation_plan/context）
- progress.json（status/validations/evidence/critic）

### Evidence
- docs/evidence/phase-plan.md

### Done Criteria
- plan.json に context と validations が含まれる

### Failure/Recovery
- plan が空疎 -> reviewer で差し戻し

### Deadlock Watch
- plan の再生成が 2 回超 -> I-DL-2

### Next
- [P-01]

## [P-01] 「plan をレビューして。時間的達成可能性もチェック。」

### Scene
レビューが冷静に計画を切り分ける。

### User POV
「レビューで止まるなら、止めてほしい。」

### System POV
playbook-reviewer が technical/consistency/completeness を評価し、temporal achievability を通す。

### Event Units/Hooks
- PostToolUse -> events/post-tool/telemetry.sh

### Required Skills
- playbook-validator

### Called SubAgents
- playbook-reviewer
- review-aggregator

### Output
- reviewer PASS または指摘リスト

### Evidence
- reports/review/plan-review.md

### Done Criteria
- reviewer PASS が記録される

### Failure/Recovery
- 達成不能基準 -> FAIL -> plan 修正
- 矛盾が残る -> I-REQ-2

### Deadlock Watch
- レビュー否決が反復 -> I-DL-2

### Next
- [P-02]

## [P-02] 「plan を凍結して進めて。」

### Scene
計画が固定される。改ざんが禁止される。

### User POV
「ここからは計画通りに進めるしかない。」

### System POV
plan.json を凍結し、state.md の playbook.active を更新。以降の変更はスコープ変更手順へ迂回する。

### Event Units/Hooks
- PreToolUse -> events/pre-tool/guardrail.sh

### Required Skills
- state-updater
- playbook-gate

### Output
- playbook.active 更新済みの state.md

### Evidence
- docs/evidence/phase-plan.md（追記）

### Done Criteria
- plan.json が凍結状態である

### Failure/Recovery
- plan 変更が試みられる -> I-PLAN-FREEZE -> 進行停止

---

### ACT 3: 実装（壊れやすい現場）

## [I-00] 「実装に入って。ブランチを切って。」

### Scene
現場が動き出す。小さなズレが致命傷になる。

### User POV
「実装は速く進めたい。だが壊れても困る。」

### System POV
branch-manager が作業ブランチを作成し、progress.json を更新する。

### Event Units/Hooks
- UserPromptSubmit -> events/prompt/chain.sh

### Required Skills
- branch-manager

### Called SubAgents
- progress-tracker

### Output
- 作業ブランチ作成
- progress.json の実装フェーズ開始

### Evidence
- docs/evidence/phase-implement.md

### Done Criteria
- ブランチ名が plan.json と一致

### Failure/Recovery
- ブランチ作成失敗 -> I-BOOT-1

---

## [I-01] 「UI を作って。チャット画面まで。」

### Scene
見える成果が出る。だが見た目だけでは完了ではない。

### User POV
「UI は早く見たい。でも見た目だけで終わりたくない。」

### System POV
codex-invoker に実装を委譲。成果は progress.json に記録し、Evidence を作る。

### Event Units/Hooks
- UserPromptSubmit -> events/prompt/chain.sh

### Called SubAgents
- codex-invoker
- progress-tracker

### Output
- UI 実装（components, styles）

### Evidence
- docs/evidence/phase-implement.md（UI セクション）

### Validations
- technical: UI のビルドが通る
- consistency: 既存ルーティングと矛盾しない
- completeness: 主要画面が揃う

### Failure/Recovery
- ビルド失敗 -> 修正 -> 再実行

### Deadlock Watch
- 修正が 3 回超 -> I-DL-2

---

## [I-02] 「API とデータ層を作って。」

### Scene
見えない基盤が組み上がる。ここが弱いと後で崩れる。

### User POV
「見えないけど重要。壊れるのが怖い。」

### System POV
codex-invoker が実装、integrity-checker が依存と整合を確認。

### Event Units/Hooks
- UserPromptSubmit -> events/prompt/chain.sh

### Required Skills
- integrity-checker

### Called SubAgents
- codex-invoker
- progress-tracker

### Output
- API 実装、データアクセス層

### Evidence
- docs/evidence/phase-implement.md（API セクション）

### Validations
- technical: API 起動確認
- consistency: スキーマとエンドポイントが一致
- completeness: CRUD が揃う

### Failure/Recovery
- 依存不整合 -> I-BOOT-1

---

## [I-03] 「UI と API を繋いで動かして。」

### Scene
結合でバグが噴き出す。ここからが本番。

### User POV
「動けばいい。でも動くだけじゃだめ。」

### System POV
統合テスト前に最小起動確認を行い、progress.json を更新する。

### Event Units/Hooks
- PostToolUse -> events/post-tool/telemetry.sh

### Required Skills
- lint-runner
- test-runner

### Called SubAgents
- progress-tracker

### Output
- 最小起動確認

### Evidence
- docs/evidence/phase-implement.md（統合セクション）

### Failure/Recovery
- 起動失敗 -> 修正 -> 再実行
- 反復失敗 -> I-DL-2

---

### ACT 4: 検証（壊すために動かす）

## [V-00] 「lint と unit テストを通して。」

### Scene
壊すことで守る。テストは嘘を暴く。

### User POV
「壊れているなら今知りたい。」

### System POV
lint-runner/test-runner が実行され、結果が Evidence と progress.json に記録される。

### Event Units/Hooks
- PreToolUse -> events/pre-tool/guardrail.sh

### Required Skills
- lint-runner
- test-runner

### Called SubAgents
- progress-tracker

### Output
- lint/test 結果

### Evidence
- reports/tests/unit.md
- docs/evidence/phase-verify.md

### Failure/Recovery
- FAIL -> 修正 -> 再実行
- 3 回連続 FAIL -> I-DL-2

---

## [V-01] 「E2E とパフォーマンステストまで。」

### Scene
現実に近い負荷で嘘を暴く。ここで止まるのは正常。

### User POV
「遅いなら今知りたい。後で痛い目を見たくない。」

### System POV
E2E/性能テストを実行し、Evidence の technical/consistency/completeness を満たすかを判定する。

### Event Units/Hooks
- PostToolUse -> events/post-tool/telemetry.sh

### Required Skills
- test-runner

### Called SubAgents
- progress-tracker

### Output
- E2E/性能テスト結果

### Evidence
- reports/tests/e2e.md
- reports/tests/perf.md

### Failure/Recovery
- FAIL -> 影響範囲を特定 -> 修正

---

### ACT 5: レビュー（第三者の冷たい目）

## [R-00] 「レビューと外部レビューを通して。」

### Scene
他人の目で自分の盲点を見つける。

### User POV
「自分の確認だけでは不安。第三者の否定が欲しい。」

### System POV
code-reviewer が内部レビューを行い、coderabbit-invoker が外部レビューを取得。review-aggregator が統合する。

### Event Units/Hooks
- UserPromptSubmit -> events/prompt/chain.sh

### Required Skills
- code-validator

### Called SubAgents
- code-reviewer
- coderabbit-invoker
- review-aggregator

### Output
- レビュー結果（内部/外部の統合）

### Evidence
- reports/review/code-review.md

### Done Criteria
- reviewer PASS が記録される

### Failure/Recovery
- 指摘が致命的 -> 実装フェーズに戻る

---

### ACT 6: 完了判定（終わらせるための終わり）

## [C-00] 「最終チェックと完了判定をして。」

### Scene
終わりは自己申告でなく、証拠で決まる。

### User POV
「終わらせたい。でも詐欺はしたくない。」

### System POV
critic が done_criteria を検証し、Evidence 凍結と archive を行う。

### Event Units/Hooks
- PreToolUse -> events/pre-tool/guardrail.sh
- Stop -> events/stop/chain.sh

### Required Skills
- archive-manager

### Called SubAgents
- critic
- progress-tracker

### Output
- critic PASS
- archive 作成

### Evidence
- docs/evidence/phase-done.md

### Done Criteria
- Evidence 凍結済み
- archive に保存済み

### Failure/Recovery
- Evidence 不一致 -> I-RF-1
- 自己申告 -> I-RF-2

---

### ACT 7: 介入イベント（現実は継続する）

## [X-00] 「途中で音声入力も欲しくなった。」

### Scene
スコープ変更は必ず発生する。止めるのが正しい。

### User POV
「欲しい機能が増えた。今入れたい。」

### System POV
scope-guard が検知し、計画変更手順に誘導する。plan は凍結中のため直接変更は禁止。

### Event Units/Hooks
- PreToolUse -> events/pre-tool/guardrail.sh

### Required Skills
- scope-guard

### Called SubAgents
- playbook-reviewer
- planner

### Output
- 追加スコープ提案

### Failure/Recovery
- 変更が未承認 -> I-DL-1 -> 人間判断

---

## [X-01] 「LLM がダウンした。どうする？」

### Scene
外部依存は落ちる。ここで止まるか縮退するか。

### User POV
「止まるなら止まっていい。どう再開する？」

### System POV
タイムアウトを検知し、codex-invoker を fallback するか、user に停止/継続を提示する。

### Event Units/Hooks
- PostToolUse -> events/post-tool/telemetry.sh

### Called SubAgents
- codex-invoker
- orchestrator

### Output
- fallback 実行 or 停止宣言

### Failure/Recovery
- 繰り返し停止 -> I-DL-1

---

## [X-02] 「同じ失敗が続く。どう抜ける？」

### Scene
ループは正当な停止理由になる。

### User POV
「もう同じ失敗は見たくない。」

### System POV
I-DL-2 を発火し、root-cause を整理し、スコープ縮退案を提示する。

### Event Units/Hooks
- Stop -> events/stop/chain.sh

### Called SubAgents
- orchestrator
- planner

### Output
- 縮退プラン案

### Failure/Recovery
- user が縮退拒否 -> 停止/中断の決定

---

## [X-03] 「セッションが切れる。次回の復元を準備して。」

### Scene
コンテキストは消える。残すべきものだけを残す。

### User POV
「次回どこから始めるか分かる状態にしてほしい。」

### System POV
PreCompact と SessionEnd の Event Unit が state.md と progress.json を更新する。

### Event Units/Hooks
- PreCompact -> events/pre-compact/chain.sh
- SessionEnd -> events/session-end/chain.sh

### Required Skills
- state-updater
- archive-manager

### Called SubAgents
- progress-tracker

### Output
- state.md 更新
- progress.json 更新

### Evidence
- docs/evidence/phase-session.md

### Done Criteria
- 次回再開手順が state.md に明記される

---

## エンディング

この脚本が示すのは「成功」ではなく「止まれる設計」だ。報酬詐欺を防ぎ、デッドロックを避け、失敗を証拠に変える。そのために必要なのは、Hook の強制範囲を理解し、Event Unit で失敗を閉じ込め、Evidence を凍結し、critic に完了を委ねることだ。

次に進むなら、`REBUILD-DESIGN-SPEC.md` を一次仕様として、`BUILD-FROM-SCRATCH.md` の手順に従い、この脚本を実運用に落とし込む。
