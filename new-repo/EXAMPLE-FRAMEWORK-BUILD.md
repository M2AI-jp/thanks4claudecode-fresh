# フレームワーク構築シミュレーション（Phase -1〜8）

> 文書の位置付け: 構築シミュレーション（依頼例）
>
> **MECE 役割**: 構築依頼例の SSOT（各ACTの依頼例、成果物/Evidence/完了条件の具体例）
>
> 読み順: README.md を参照
>
> 一次仕様: REBUILD-DESIGN-SPEC.md
>
> 構築手順: BUILD-FROM-SCRATCH.md
>
> 更新: 2026-01-21
>
> ---
>
> **SSOT マップ（本文書内の重複と参照先）**:
> - ACT -1〜8 の Phase 構造 → **BUILD-FROM-SCRATCH.md §8 が SSOT**（本文書は依頼例のみ）
> - Layer 0-5 の依存関係 → **BUILD-FROM-SCRATCH.md §8.1 が SSOT**（本文書は ACT 順序のみ）
> - 成果物テンプレート → **BUILD-FROM-SCRATCH.md §8.2 が SSOT**（本文書は具体例のみ）

---

## 前提

- 何もない状態から始める
- 完了条件: EXAMPLE-CHATGPT-CLONE.md が実行可能になる
- 依頼の粒度: 1依頼 = 1概念 or 1機能

## 依頼の原則（最小）

- 依存関係に従う（Phase -1 → Layer 0 → ... → Hook）
- Phase -1 は Hook が無効なので、playbook は手動運用する
- 失敗は許容し、Evidence と回復手順を残す

---

## ACT -1: 概念整理（Phase -1）

> **核心**: モジュール化は"概念の名前"ではなく、**"人間の作業単位"と"合否判定"の境界**で行う。

### [-1.0] 「役割を分解して」
- 判断者/実行者/監査者/強制者の4分類
- SubAgent の責務割り当てまで決める

### [-1.1] 「保護・制御を整理して」
- Hook で強制できる範囲を確定
- playbook-gate / file-protector / branch-protector の責務を決める

### [-1.2] 「計画の概念を整理して」
- playbook v2 の粒度と構造を確定
- planner / playbook-creator / playbook-reviewer を分離
- **タスクは最小作業単位まで分解**（情報収集→方針提案→実装計画→実装→自己検証→変更説明→レビュー対応）

### [-1.3] 「テストの概念を整理して」
- 粒度 × 目的 × タイミングを定義
- test-runner / lint-runner の責務を明確化
- **最小単位に分解**: 観点抽出 → ケース設計 → 実装 → 実行 → 失敗分類 → 修正提案 → 再実行

### [-1.4] 「レビューの概念を整理して」
- playbook/code の分離と観点を定義
- code-reviewer / playbook-reviewer を確定
- **チェックリスト化**: lint/型/循環依存/複雑度/セキュリティ臭/命名/コメント

### [-1.5] 「状態管理を整理して（ロングタームコンテキスト）」
- state.md / progress.json / archive の責務を確定
- 更新ルールと SSOT を決める
- **軸で分解**: 保存対象 / 表現形式 / 粒度 / 更新契機 / 復元手順 / 破綻パターン

### [-1.6] 「追加の分解（仕様/変更/運用）を整理して」
- 仕様: 用語定義 / 目的・非目的 / 受入条件 / 例外系 / 画面UX / 依存 / 計測
- 変更（PR）: 変更理由 / 影響範囲 / 後方互換 / ロールバック / テスト証跡 / リリースノート
- 運用: 監視項目 / アラート分類 / ランブック / ポストモーテム

### [-1.7] 「最小作業単位テンプレを確定して」
- 各コンポーネントに対して Step名/入力/作業内容/完了条件/出力/失敗時 を定義
- 「入力」「処理」「出力」「検証（合否判定）」「失敗時の分岐」を持つ最小単位へ分解

**Phase -1 の playbook 運用（手動）**
- `play/template/` が無ければ、この時点で最小の plan/progress を手動作成（Phase 4 で正式化）
- goal を「概念整理」に設定し、phases に上記 7 概念 + 最小作業単位テンプレを登録
- 各概念を整理するたびに progress.json を更新
- 全概念のマッピング完了後に critic で完了判定

---

## ACT 0: 基盤（Phase 0-1）

### [0.0] 「CLAUDE.md を作って」
- 非交渉ルールと参照先だけを入れる（最小テンプレ）

### [0.1] 「state.md を作って」
- SSOT と roles の最小構成を入れる

---

## ACT 1: Layer 0 機能（Phase 2-5）

### [1.0] 「state-updater を作って（Module → Skill）」

**成果物:**
- `modules/state-updater.sh`
- `.claude/skills/state-updater/SKILL.md`
- `.claude/skills/state-updater/run.sh`

**Evidence:**
- technical: `bash modules/state-updater.sh read` が state.md を返す
- consistency: 既存の state.md フォーマットと一致
- completeness: read/write/update が揃う

**完了条件:**
- state.md の読み書きが正常動作

**失敗時:**
- Module が動かない → シェルスクリプトのパス確認
- Skill から Module を呼べない → SKILL.md の entrypoint 確認

### [1.1] 「file-protector を作って」

**成果物:**
- `modules/file-protector.sh`
- `.claude/skills/file-protector/SKILL.md`

**Evidence:**
- technical: 保護対象ファイルへの Edit がブロックされる
- consistency: `.claude/protected-files.txt` と整合

**完了条件:**
- Hook 接続前でも手動テストで動作確認

### [1.2] 「branch-protector を作って」

**成果物:**
- `modules/branch-protector.sh`
- `.claude/skills/branch-protector/SKILL.md`

**Evidence:**
- technical: main/master への直接 push がブロックされる

### [1.3] 「prompt-analyzer を作って（Module → SubAgent → Skill）」

**成果物:**
- `.claude/agents/prompt-analyzer.md`
- `.claude/skills/prompt-analyzer/SKILL.md`

**Evidence:**
- technical: ユーザープロンプトを分析し 5W1H を返す
- consistency: analysis_result フォーマットが plan.json の context と整合

**完了条件:**
- instruction/question/context の判定が正常動作

### [1.4] 「lint-runner を作って」

**成果物:**
- `modules/lint-runner.sh`
- `.claude/skills/lint-runner/SKILL.md`

**Evidence:**
- technical: 指定ディレクトリの lint を実行し結果を返す

### [1.5] 「test-runner を作って」

**成果物:**
- `modules/test-runner.sh`
- `.claude/skills/test-runner/SKILL.md`

**Evidence:**
- technical: 指定テストを実行し PASS/FAIL を返す

---

## ACT 2: Layer 1 機能

### [2.0] 「playbook-gate を作って（state-updater に依存）」

**成果物:**
- `modules/playbook-gate.sh`
- `.claude/skills/playbook-gate/SKILL.md`

**Evidence:**
- technical: playbook.active == null の時に Edit/Write をブロック
- consistency: state.md の playbook.active と連携
- completeness: ブロック時のエラーメッセージが明確

**完了条件:**
- playbook なしで Edit を実行 → ブロックされる

**失敗時:**
- state-updater が未完成 → ACT 1 に戻る
- 状態読み取りエラー → state.md のフォーマット確認

### [2.1] 「integrity-checker を作って（state-updater に依存）」

**成果物:**
- `modules/integrity-checker.sh`
- `.claude/skills/integrity-checker/SKILL.md`

**Evidence:**
- technical: state.md と playbook の整合性を検証
- completeness: 不整合検出時にエラーを返す

**完了条件:**
- 意図的な不整合を検出できる

### [2.2] 「planner を作って（prompt-analyzer に依存）」

**成果物:**
- `.claude/agents/planner.md`
- `.claude/skills/planner/SKILL.md`

**Evidence:**
- technical: prompt-analyzer の出力を受けて phases を生成
- consistency: plan.json のスキーマと一致

**完了条件:**
- 分析結果から phases と tasks を生成できる

---

## ACT 3: Layer 2 機能

### [3.0] 「playbook-creator を作って（planner に依存）」

**成果物:**
- `.claude/agents/playbook-creator.md`
- `.claude/skills/playbook-creator/SKILL.md`

**Evidence:**
- technical: plan.json と progress.json を生成
- consistency: play/template/ のスキーマと一致
- completeness: phases/tasks/done_criteria が揃う

**完了条件:**
- 有効な playbook が生成される

### [3.1] 「code-reviewer SubAgent を作って（lint/test に依存）」

**成果物:**
- `.claude/agents/code-reviewer.md`（SubAgent 定義）

**Evidence:**
- technical: lint/test 結果を統合してレビュー
- consistency: レビュー観点が定義済み

**完了条件:**
- 変更コードに対してレビューを生成できる

> 注意: code-reviewer は **SubAgent**。対応する **Skill** は code-validator（Layer 3 で作成）。

---

## ACT 4: Layer 3 機能

### [4.0] 「playbook-reviewer SubAgent + playbook-validator Skill を作って（playbook-creator に依存）」

**成果物:**
- `.claude/agents/playbook-reviewer.md`（SubAgent 定義）
- `.claude/skills/playbook-validator/SKILL.md`（Skill、playbook-reviewer を呼び出す）

**Evidence:**
- technical: playbook を検証し reviewed: true を設定
- consistency: playbook-review-criteria.md と照合

**完了条件:**
- 不備のある playbook を検出できる

> 注意: Skill（playbook-validator）→ SubAgent（playbook-reviewer）の呼び出し構造を維持。

### [4.1] 「code-validator Skill を作って（code-reviewer SubAgent に依存）」

**成果物:**
- `.claude/skills/code-validator/SKILL.md`（Skill、code-reviewer を呼び出す）

**Evidence:**
- technical: code-reviewer の結果を検証
- completeness: 全検証項目をカバー

**完了条件:**
- 検証結果を統合して PASS/FAIL を判定

---

## ACT 5: Layer 4 機能

### [5.0] 「critic を作って（reviewer 群に依存）」

**成果物:**
- `.claude/agents/critic.md`
- `.claude/skills/critic/SKILL.md`

**Evidence:**
- technical: done_criteria の検証と PASS/FAIL 判定
- consistency: done-criteria-validation.md と照合
- completeness: Evidence 3点検証（technical/consistency/completeness）

**完了条件:**
- タスク完了の最終判定ができる

**失敗時:**
- reviewer 群が未完成 → ACT 3-4 に戻る
- Evidence 不足 → 検証項目を追加

---

## ACT 6: Layer 5 機能

### [6.0] 「archive-manager を作って（critic に依存）」

**成果物:**
- `.claude/agents/archive-manager.md`
- `.claude/skills/archive-manager/SKILL.md`

**Evidence:**
- technical: 完了した playbook を archive/ に移動
- consistency: アーカイブ構造が定義済み

**完了条件:**
- playbook の完了後にアーカイブが正常動作

### [6.1] 「orchestrator を作って（全体統合）」

**成果物:**
- `.claude/agents/orchestrator.md`
- `.claude/skills/orchestrator/SKILL.md`

**Evidence:**
- technical: 全コンポーネントを連携して動作
- completeness: Hook → Skill → SubAgent チェーンが機能

**完了条件:**
- E2E で Golden Path が動作する

---

## ACT 7: Event Unit と Hook 統合（Phase 6-7）

### [7.0] 「Event Unit の最小チェーンを作って」

**成果物:**
- `.claude/events/session-start/`（session-init.sh から呼ばれる）
- `.claude/events/prompt/`（UserPromptSubmit 用）
- `.claude/events/pre-tool/`（pre-tool-guard.sh から呼ばれる）
- `.claude/events/post-tool/`
- `.claude/events/stop/`（stop-guard.sh から呼ばれる）
- `.claude/events/pre-compact/`
- `.claude/events/session-end/`
- `.claude/hooks/settings.json`

**Evidence:**
- technical: Hook が正しく発火する
- consistency: BUILD-FROM-SCRATCH.md §7 のディレクトリ構造と一致

**完了条件:**
- session 開始時に state.md が注入される
- Edit 前に playbook-gate が検証される

### [7.1] 「Hook スクリプトを接続して」

**成果物:**
- `.claude/hooks/session-init.sh`
- `.claude/hooks/pre-tool-guard.sh`
- `.claude/hooks/post-tool.sh`
- `.claude/hooks/stop-guard.sh`
- `.claude/hooks/pre-compact.sh`
- `.claude/hooks/session-end.sh`

**Evidence:**
- technical: 各ガードが正しく動作
- completeness: 必要な Hook が全て接続

**完了条件:**
- 保護機能が Hook 経由で自動発火

---

## ACT 8: 自動化（Phase 8）

### [8.0] 「PR/アーカイブの自動化を追加して（任意）」

**成果物:**
- `.claude/skills/git-workflow/SKILL.md`
- 自動 PR テンプレート

**Evidence:**
- technical: PR 作成が自動化される
- completeness: アーカイブと連携

**完了条件:**
- タスク完了後に PR が自動生成される（オプション）

---

## 失敗パターンと回復

### F-1: Layer 1 を Layer 0 より先に作ろうとした
- 原因: 依存関係の無視
- 回復: Layer 0 に戻って構築

### F-2: 概念整理を飛ばして Module から作り始めた
- 原因: Phase -1 をスキップ
- 回復: Phase -1 に戻って概念整理

### F-3: playbook を使わずに進めた
- 原因: Hook が無いので運用を省略
- 回復: plan/progress を手動作成し、Evidence を補完
