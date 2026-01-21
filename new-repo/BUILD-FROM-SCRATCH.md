# BUILD-FROM-SCRATCH.md

> 文書の位置付け: 構築手順書（How）
>
> **MECE 役割**: 構築手順の SSOT（Phase -1〜8、Layer 構造、コンポーネント一覧、ディレクトリ構造）
>
> 読み順: README.md を参照
>
> 一次仕様: REBUILD-DESIGN-SPEC.md
>
> 役割: 概念整理の手順（How）を定義する。内容（What）は REBUILD-DESIGN-SPEC.md の 5 を参照。
>
> 構築シミュレーション: EXAMPLE-FRAMEWORK-BUILD.md
>
> 運用脚本: EXAMPLE-CHATGPT-CLONE.md
>
> 非スコープ: 失敗史、仕様の背景、ケーススタディの詳細
>
> **逆引き設計図**: Claude Code フレームワークをゼロから構築するためのガイド
>
> 更新: 2026-01-21
>
> ---
>
> **SSOT マップ（本文書内の重複と参照先）**:
> - §2 設計原則 → **本文書が SSOT**（PROJECT-STORY.md §6 は背景のみ）
> - §8.0 Phase -1 概念整理 → 手順は本文書、**内容は REBUILD-DESIGN-SPEC.md §5 が SSOT**
> - §8.1 Layer 0-5 → **本文書が SSOT**
> - §11 Claude Code 公式仕様 → **REBUILD-DESIGN-SPEC.md §3 が SSOT**（本文書は URL のみ）

---

## 目次

1. [目的と適用範囲](#1-目的と適用範囲)
2. [設計原則（MECE）](#2-設計原則mece)
3. [現状棚卸し（Hook/Skill/SubAgent）](#3-現状棚卸しhookskillsubagent)
4. [主要な問題点（再評価）](#4-主要な問題点再評価)
5. [必要性判定（維持/分割/削除）](#5-必要性判定維持分割削除)
6. [再設計（MECE な構造）](#6-再設計mece-な構造)
7. [ディレクトリ構造案](#7-ディレクトリ構造案)
8. [構築フェーズ（段階導入）](#8-構築フェーズ段階導入)
9. [移行計画（現状→新設計）](#9-移行計画現状新設計)
10. [検証チェックリスト](#10-検証チェックリスト)
11. [Claude Code 公式仕様](#11-claude-code-公式仕様)

---

## 1. 目的と適用範囲

- 本書は、Claude Code フレームワークを最小の単位から構築するための設計図である
- Hook/Skill/SubAgent を MECE に分離し、責務の重複・密結合・God Object を排除する
- 実装よりも「設計原則」と「構築順序」を優先し、運用可能な形を先に固定する

---

## 2. 設計原則（MECE）

### 2.1 単一責務

- 1 Hook = 1 イベント
- 1 Skill = 1 機能
- 1 SubAgent = 1 役割

### 2.2 分離の原則

- 呼び出しと処理を分離する（Invoker パターン）
- 判定と実行を分離する（Reviewer/Critic と Executor を混ぜない）
- 入力と出力の境界を明示する（依存を曖昧にしない）

### 2.3 必要性の証明

- 追加条件: 入力が明確 / 出力が明確 / 利用者が存在 / 代替不可
- 削除条件: 利用者がいない / 既存と重複 / 入出力が不明

### 2.4 自動化の境界

- Hook は「強制できる範囲（ブロック/初期化）」のみに限定する
- 自動化できない領域（意思決定/承認）は必ず人間ゲートに戻す

### 2.5 構築順序（依頼順番の核心）

構築は「概念 → 実装」の順序で進める。Module を作る前に、何を作るかを決める。

**依頼順番:**

1. **概念の整理**（何を作るか）
   - エンジニアリング概念を**最小作業単位**まで分解する
     - 概念整理の順序（依存関係）: 役割 → 保護・制御 → 計画 → テスト → レビュー → 状態管理
     - 役割: 判断者/実行者/監査者/強制者
     - 保護・制御: 対象（ブランチ/ファイル/スコープ/品質）
     - 計画: 粒度（ロードマップ/プロジェクト/スプリント/タスク）→ **タスクは最小単位まで分解**
     - テスト: 粒度（Unit/Integration/E2E）×目的（機能/回帰/性能）×タイミング → **観点抽出→設計→実装→実行→失敗分類→修正→再実行**
     - レビュー: 対象（要件/設計/コード）×観点（正確性/可読性/保守性）×タイミング → **チェックリスト化**
     - 状態管理: 保存対象/表現形式/粒度/更新契機/復元手順/破綻パターン → **ロングタームコンテキストの設計**
   - 追加の分解: 仕様（入力形式）、変更（PR）、運用
   - **最小作業単位のテンプレ**: Step名/入力/作業内容/完了条件/出力/失敗時
   - REBUILD-DESIGN-SPEC.md のセクション 5 を参照
   - 各概念を Skill/SubAgent/Module/Hook にマッピングする
2. **実装**（どう作るか）
   - Module（単機能スクリプト）を作る
   - SubAgent を定義する
   - Skill にパッケージ化する
   - 最後に Hook を接続する（Event Unit の chain を含む）

> 鉄則: 「モジュールにする前に、エンジニアリングの概念をリストアップする」。この整理が先にあって、初めて「何を Skill にするか」「何を SubAgent にするか」が決まる。
>
> **重要**: モジュール化は"概念の名前"ではなく、**"人間の作業単位"と"合否判定"の境界**で行う。「入力」「処理」「出力」「検証（合否判定）」「失敗時の分岐」を持つ最小作業単位へ分解すると、並列化・リトライ・人間承認ポイント挿入・ログ追跡が可能になる。

> 重要: Phase 順（全 Module → 全 SubAgent → 全 Skill）ではなく、**機能単位で縦に完成させる**。
>
> 例: state-updater を作る場合
> 1. state-updater の Module を作る
> 2. state-updater の Skill を作る（SubAgent は不要）
> 3. 動作確認して次の機能へ
>
> 各機能が独立してテスト可能になり、責務の境界が明確になる。

### 2.6 失敗と回復

- 失敗時の分岐を最初から設計に含める
- 失敗ログは Evidence として保存し、再発防止のトリガにする

---

## 3. 現状棚卸し（Hook/Skill/SubAgent）

> 注意: 本章（3〜5）は既存リポジトリからの移行専用。ゼロベース構築では 6 章へ進む。

### 3.1 Hooks（8 個）

| Hook | ファイル | 責務 | 備考 |
| --- | --- | --- | --- |
| PreToolUse | pre-tool.sh | 全ツール使用前チェック | ブロック可能 |
| PostToolUse | post-tool.sh | 使用後処理 | ほぼ空 |
| SessionStart | session.sh | セッション開始初期化 | 必須 |
| UserPromptSubmit | prompt.sh | プロンプト送信時処理 | 強制不可 |
| SubagentStop | subagent-stop.sh | SubAgent 停止時処理 | 複雑 |
| PreCompact | pre-compact/chain.sh | 圧縮前処理 | 使用不明 |
| Stop | stop/chain.sh | 停止前処理 | 必須 |
| SessionEnd | session-end/chain.sh | セッション終了時 | ほぼ空 |

### 3.2 Skills（13 個）

| Skill | 責務 | 問題点 |
| --- | --- | --- |
| playbook-init | タスク開始 + prompt-analyzer 呼び出し | 密結合 |
| prompt-analyzer | 分析 + topic 判定 | 分離不足 |
| executor-resolver | executor 判定 | pm と重複 |
| understanding-check | 理解確認 | 分散 |
| golden-path | playbook 作成強制 | 重複 |
| quality-assurance | lint + integrity + review | 多責務 |
| access-control | ブランチ保護 + ファイル保護 | 多責務 |
| git-workflow | Git 操作全般 | 多責務 |
| playbook-gate | playbook 無しブロック | 単一責務 |
| session-manager | セッション管理全般 | 多責務 |
| reward-guard | 報酬詐欺防止 + critic | 密結合 |
| state | state.md 管理 | 単一責務 |
| post-loop | ループ後処理 | 単一責務 |

### 3.3 SubAgents（7 個）

| SubAgent | 責務 | 問題点 |
| --- | --- | --- |
| pm | playbook/進捗/スコープ/判定/呼び出し | God Object |
| prompt-analyzer | 分析 + topic 判定 + リスク | 多責務 |
| executor-resolver | executor 判定 | 単一責務 |
| reviewer | playbook 検証 + コード検証 | 多責務 |
| critic | 完了判定 + validations | 大きいが許容 |
| codex-delegate | Codex 呼び出し | 単一責務 |
| coderabbit-delegate | CodeRabbit 呼び出し | 判定混在 |

---

## 4. 主要な問題点（再評価）

- A: pm が God Object（複数責務を抱える）
- B: Skill と SubAgent の 1:1 対応が崩れ、呼び出し経路が不透明
- C: レビューが分離されず、playbook とコードが混在
- D: quality-assurance が複数責務を内包
- E: 自動化が弱く、Hook が「指示」に留まっている
- F: 中期計画と短期計画が同一 SubAgent に混在

---

## 5. 必要性判定（維持/分割/削除）

### 5.1 Hooks

| Hook | 必要性 | 理由 |
| --- | --- | --- |
| PreToolUse | 維持 | ブロック機構として必須 |
| PostToolUse | 要検討 | ほぼ空で利用不明 |
| SessionStart | 維持 | 初期化に必要 |
| UserPromptSubmit | 再設計 | 強制できないため役割再定義 |
| SubagentStop | 再設計 | 複雑・補完用途のみ |
| PreCompact | 要検討 | 利用実態が不明 |
| Stop | 維持 | post-loop 強制に必要 |
| SessionEnd | 要検討 | ほぼ空 |

### 5.2 Skills

| Skill | 必要性 | 理由 |
| --- | --- | --- |
| playbook-init | 再設計 | prompt-analyzer 分離が必要 |
| prompt-analyzer | 分割 | 分析と判定を分ける |
| executor-resolver | 維持 | 単一責務で良い |
| understanding-check | 削除 | AskUserQuestion で直接代替 |
| golden-path | 削除候補 | playbook-init と重複 |
| quality-assurance | 分割 | lint/integrity/review を分離 |
| access-control | 分割 | branch/file を分離 |
| git-workflow | 分割 | branch/pr/merge を分離 |
| playbook-gate | 維持 | 単一責務 |
| session-manager | 分割 | init/compact/end を分離 |
| reward-guard | 分割 | critic を独立 Skill に |
| state | 維持 | 単一責務 |
| post-loop | 維持 | 単一責務 |

### 5.3 SubAgents

| SubAgent | 必要性 | 理由 |
| --- | --- | --- |
| pm | 大幅分割 | 9 責務を分離する必要あり |
| reviewer | 分割 | playbook/code を分離 |
| critic | 維持 | 完了判定を担当 |
| codex-delegate | 維持 | 単一責務 |
| coderabbit-delegate | 分割 | 呼び出しと判定を分離 |

### 5.4 削除候補

- golden-path/SKILL.md（playbook-init と重複）
- understanding-check/SKILL.md（削除: AskUserQuestion で直接代替）
- quality-assurance/SKILL.md（分割後に削除）
- access-control/SKILL.md（分割後に削除）
- git-workflow/SKILL.md（分割後に削除）
- session-manager/SKILL.md（分割後に削除）
- reward-guard/SKILL.md（critic 独立後に削除）

---

## 6. 再設計（MECE な構造）

### 6.1 レイヤー構造（MECE）

1. Hook Layer: 強制可能な範囲のみ
2. Skill Layer: 単一機能のパッケージ
3. SubAgent Layer: 独立エージェント（Skill に属さない）
4. Module Layer: Hook/Skill の内側にある最小単位

### 6.2 機能分類マトリクス（重複なし）

| カテゴリ | Skill | SubAgent |
| --- | --- | --- |
| 入力分類 | topic-classifier | - |
| 分析 | - | prompt-analyzer |
| 計画 | playbook-creator, executor-resolver | planner |
| 進捗/状態 | state-updater | progress-tracker |
| 実装 | - | codex-invoker |
| 検証 | lint-runner, integrity-checker, health-checker, test-runner | - |
| レビュー | playbook-validator, code-validator | playbook-reviewer, code-reviewer |
| 完了判定 | - | critic |
| Git | branch-manager, pr-manager | - |
| 保護/ゲート | branch-protector, file-protector, playbook-gate, post-loop-gate | - |
| 外部連携 | - | coderabbit-invoker |
| 統合 | - | orchestrator, review-aggregator |

### 6.3 新コンポーネント一覧

**Hooks（最小構成）**
- pre-tool-guard: 破壊的操作のブロック
- session-init: 初期化
- stop-guard: post-loop 強制

**Skills（単一責務）**
- topic-classifier
- playbook-creator
- executor-resolver
- state-updater
- lint-runner
- integrity-checker
- health-checker
- test-runner
- playbook-validator
- code-validator
- branch-manager
- pr-manager
- archive-manager
- branch-protector
- file-protector
- playbook-gate
- post-loop-gate

**SubAgents（独立）**
- orchestrator
- planner
- progress-tracker
- playbook-reviewer
- code-reviewer
- review-aggregator
- critic
- codex-invoker
- coderabbit-invoker
- prompt-analyzer

### 6.4 旧 → 新 の責務マッピング

| 旧コンポーネント | 問題 | 新コンポーネント |
| --- | --- | --- |
| pm | 9 責務 | orchestrator + planner + progress-tracker |
| reviewer | 2 責務 | playbook-reviewer + code-reviewer |
| coderabbit-delegate | 呼び出し+処理 | coderabbit-invoker + review-aggregator |
| playbook-init | 内包 | topic-classifier + playbook-creator |
| quality-assurance | 多責務 | lint-runner + integrity-checker + health-checker + validator |

### 6.5 Invoker パターンの適用

- invoker は「呼ぶだけ」。判定は reviewer/critic が実施
- coderabbit-invoker は結果を返すだけで判定しない
- codex-invoker は差分生成のみを担当し、承認は reviewer/critic が担う

---

## 7. ディレクトリ構造案

```
.claude/
  events/
    session-start/
    prompt/
    pre-tool/
    post-tool/
    stop/
    pre-compact/
    session-end/
  hooks/
    session-init.sh
    pre-tool-guard.sh
    post-tool.sh
    stop-guard.sh
    pre-compact.sh
    session-end.sh
  skills/
    topic-classifier/
    playbook-creator/
    executor-resolver/
    state-updater/
    lint-runner/
    type-checker/
    integrity-checker/
    health-checker/
    test-runner/
    dependency-checker/
    playbook-validator/
    code-validator/
    branch-manager/
    pr-manager/
    archive-manager/
    branch-protector/
    file-protector/
    playbook-gate/
    completion-gate/
    scope-guard/
    post-loop-gate/
  agents/
    orchestrator.md
    planner.md
    progress-tracker.md
    playbook-reviewer.md
    code-reviewer.md
    review-aggregator.md
    critic.md
    codex-invoker.md
    coderabbit-invoker.md
    prompt-analyzer.md
modules/
  example.sh
play/
  template/
    plan.json
    progress.json
  archive/
```

---

## 8. 構築フェーズ（段階導入）

| Phase | 目的 | Hook | 依頼の粒度 |
| --- | --- | --- | --- |
| -1 | 概念整理 | なし | 1依頼 = 1概念分解（役割/保護/計画等） |
| 0 | 最小環境（CLAUDE.md） | なし | 手動作成 |
| 1 | 状態管理（state.md） | なし | 手動作成 |
| 2 | Module 単体 | なし | 1依頼 = 1機能の Module |
| 3 | SubAgent 単体 | なし | 1依頼 = 1機能の SubAgent |
| 4 | playbook テンプレ | なし | 手動作成 |
| 5 | Skill パッケージ化 | なし | 1依頼 = 1機能の Skill |
| 6 | Event Unit 構築 | なし | 1依頼 = 1 Event Unit |
| 7 | Hook 統合 | ここで初めて有効化 | 1依頼 = 1 Hook 接続 |
| 8 | 自動化（PR/アーカイブ） | 有効 | 任意 |

---

### 8.0 Phase -1: 概念整理（全ての出発点）

> **SSOT 注記**: 本セクションは「手順」のみ。概念の詳細（What）は **REBUILD-DESIGN-SPEC.md §5** を参照。

Phase 0 に進む前に、エンジニアリング概念を整理する。これが全ての依頼の土台になる。

**なぜ概念整理が先か:**
- Module を作る前に「何の Module を作るか」を決める必要がある
- SubAgent を定義する前に「どの役割を SubAgent にするか」を決める必要がある
- 概念整理なしに実装を始めると「作りながら考える」ことになり、責務の重複や欠落が生じる

**概念整理の順序（依存関係）:**
1. 役割（判断者/実行者/監査者/強制者）
2. 保護・制御（Hook で強制できる範囲の確定）
3. 計画（playbook の粒度と構造）→ **タスクは最小作業単位まで分解**
4. テスト（実行者の責務と実行タイミング）→ **観点抽出→設計→実装→実行→失敗分類→修正→再実行**
5. レビュー（監査者の責務、playbook/code の分離）→ **チェックリスト化**
6. 状態管理（ロングタームコンテキスト設計）→ **保存対象/表現形式/粒度/更新契機/復元手順/破綻パターン**
7. 追加の分解: 仕様（エージェントが迷わない入力形式）、変更（PR）、運用

**Phase -1 の playbook 運用（手動）:**
1. `play/template/` が無ければ、この時点で最小の plan/progress を手動作成（Phase 4 で正式化）
2. plan.json の goal を「概念整理」に設定
3. phases に概念（役割/保護/計画/テスト/レビュー/状態管理）を設定
4. 各概念を整理するたびに progress.json を手動更新
5. 全概念のマッピング完了後に critic で完了判定（Evidence を残す）

**依頼例:**
- 「役割を分解して。判断者/実行者/監査者/強制者の4分類で整理し、各 SubAgent の責務を決めて」
- 「保護・制御という概念を整理して。Hook で強制できる範囲と、Skill/SubAgent に委ねる範囲を明確にして」
- 「計画という概念を分解して。playbook の粒度と reviewer/critic の関係を整理して」
- 「レビューという概念を分解して。playbook レビューとコードレビューを分離し、担当を割り当てて」

**成果物 / 完了条件:**
- 概念分解表（分解軸と分解結果、カバー範囲/非カバー範囲）
- マッピング表（概念 → Skill/SubAgent/Module/Hook、Hook 強制可否）
- コンポーネント仕様一覧（責務1行、入力/出力、依存先）
- 機能依存関係図（Layer 0〜N の分類と構築順序）
- **最小作業単位テンプレ**（各コンポーネントの Step名/入力/作業内容/完了条件/出力/失敗時）
- 作るべきコンポーネントの一覧が確定し、責務の重複がない（MECE）

> **重要**: 「入力」「処理」「出力」「検証（合否判定）」「失敗時の分岐」を持つ最小作業単位へ分解することで、並列化・リトライ・人間承認ポイント挿入・ログ追跡が可能になる。モジュール化は"概念の名前"ではなく、"人間の作業単位"と"合否判定"の境界で行う。

**参照:**
- REBUILD-DESIGN-SPEC.md セクション 5「エンジニアリング概念マップ」
- EXAMPLE-FRAMEWORK-BUILD.md（Phase -1 の依頼例）

### 8.1 機能依存レイヤー（Layer 0-5）

構築は Layer 0 → Layer 5 の順序で進める。

**Layer 0（依存なし）**
- state-updater
- file-protector
- branch-protector
- prompt-analyzer
- test-runner
- lint-runner
- topic-classifier
- executor-resolver
- codex-invoker
- coderabbit-invoker

**Layer 1（Layer 0 に依存）**
- playbook-gate（state-updater）
- integrity-checker（state-updater）
- planner（prompt-analyzer）
- progress-tracker（state-updater）

**Layer 2（Layer 1 に依存）**
- playbook-creator（planner）
- code-reviewer（test-runner, lint-runner）
- review-aggregator（code-reviewer, coderabbit-invoker）

**Layer 3（Layer 2 に依存）**
- playbook-reviewer（playbook-creator）
- code-validator（code-reviewer）

**Layer 4（Layer 3 に依存）**
- critic（playbook-reviewer, code-reviewer）

**Layer 5（Layer 4 に依存）**
- archive-manager（critic）
- orchestrator（全て）

### 8.2 ゼロベース最小成果物（Phaseごと）

**Phase -1: 概念整理（最小成果物テンプレ）**

概念分解表:
| 概念 | 分解軸 | 分解結果 | カバー範囲 |
|------|--------|---------|-----------|
| 役割 | 権限 | 判断者/実行者/監査者/強制者 | 全て |
| 保護 | 対象 | ブランチ/ファイル/スコープ | Hook 強制 |
| 計画 | 粒度 | playbook/phase/subtask | playbook v2 |
| テスト | 粒度 | Unit/Integration/E2E | Unit のみ自動 |
| レビュー | 対象 | playbook/code | 両方 |
| 状態管理 | 対象 | state.md/progress.json | SSOT |

マッピング表:
| 概念 | Skill | SubAgent | Hook強制 |
|------|-------|----------|---------|
| ブランチ保護 | branch-protector | - | Yes |
| ファイル保護 | file-protector | - | Yes |
| playbook ゲート | playbook-gate | - | Yes |
| playbook レビュー | playbook-validator | playbook-reviewer | - |
| code レビュー | code-validator | code-reviewer | - |
| 完了判定 | - | critic | - |
| 実装委譲 | - | codex-invoker | - |
| 外部レビュー | - | coderabbit-invoker | - |

**Phase 0: CLAUDE.md（最小テンプレ）**

```
# CLAUDE.md

## 目的
- このリポジトリの運用原則を定義する

## 非交渉ルール
- playbook.active が null の場合、Edit/Write/Bash を禁止
- done の宣言は critic PASS が必須
- Hook -> Event Unit -> Skill -> SubAgent の順序を崩さない

## 参照
- state.md（現在状態のSSOT）
```

**Phase 1: state.md（最小テンプレ）**

```md
# state.md

## project
active: null
status: idle

## playbook
active: null
branch: null

## config
toolstack: C
roles:
  orchestrator: claudecode
  worker: codex
  reviewer: coderabbit
  human: user
```

**Phase 2: Module（最小スクリプト）**

- 例: `modules/example.sh`

```
#!/usr/bin/env bash
set -euo pipefail
echo "module-ok"
```

**Phase 3: SubAgent（最小定義）**

- 例: `.claude/agents/orchestrator.md`

```
---
name: orchestrator
description: Coordinates roles and phase transitions.
tools: Read, Bash
model: opus
skills: state
---
```

**Phase 4: playbook テンプレ**

- `play/template/plan.json` と `play/template/progress.json` を作成（Phase -1 で暫定作成している場合はここで正式化）
- 具体例は REBUILD-DESIGN-SPEC.md の「14. 付録: 最小 playbook v2 雛形」を参照

**Phase 5: Skill（最小構成）**

- 例: `.claude/skills/topic-classifier/`
  - `SKILL.md`（概要、入力/出力、entrypoint）
  - `run.sh`（Phase 2 の Module を呼ぶだけの薄いラッパー）

**Phase 6: Event Unit（最小チェーン）**

- 例: `.claude/events/pre-tool/chain.sh`

```
#!/usr/bin/env bash
set -euo pipefail
./guardrail.sh
./telemetry.sh
./chain-skill.sh
```

**Phase 7: Hook 統合（最小接続）**

- 例: `.claude/hooks/pre-tool-guard.sh`

```
#!/usr/bin/env bash
set -euo pipefail
./../events/pre-tool/chain.sh
```

**Phase 8: 自動化（任意）**

- 例: archive/pr/merge などの自動化スクリプト
- ゼロベース構築では後回しでよい

---

## 9. 移行計画（現状→新設計）

1. pm を orchestrator / planner / progress-tracker に分割
2. reviewer を playbook-reviewer / code-reviewer に分割
3. coderabbit-delegate を invoker と aggregator に分割
4. quality-assurance/access-control/git-workflow/session-manager/reward-guard を分割
5. playbook-init から prompt-analyzer を分離
6. Hook を最小構成へ縮退し、強制可能範囲のみ残す
7. 旧 Skill/SubAgent を段階的に廃止し、互換レイヤーで移行

---

## 10. 検証チェックリスト

- Phase -1 成果物: 概念分解表/マッピング/仕様一覧/依存関係図が揃っている
- 単一責務: 各 Skill/SubAgent が 1 目的のみを持つ
- 呼び出し経路: Skill -> SubAgent のみ（Task 直呼び禁止）
- playbook-gate: playbook 無しの Edit/Write/Bash を遮断できる
- review 分離: playbook と code が別 reviewer に分離されている
- invoker: coderabbit/codex は呼び出しのみで判定しない
- critic: done 判定は critic PASS が必須
- Hook: 強制可能範囲のみを Hook に残している

---

## 11. Claude Code 公式仕様

> **SSOT 注記**: 仕様の詳細は **REBUILD-DESIGN-SPEC.md §3** を参照。本セクションは URL リンクのみ。

- Hooks: https://code.claude.com/docs/ja/hooks
- SubAgents: https://code.claude.com/docs/ja/sub-agents
- Settings: https://code.claude.com/docs/ja/settings

---
