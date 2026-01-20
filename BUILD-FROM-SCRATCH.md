# BUILD-FROM-SCRATCH.md

> 文書の位置付け: 構築手順書（How）
>
> 一次仕様: REBUILD-DESIGN-SPEC.md
>
> 運用脚本: EXAMPLE-CHATGPT-CLONE.md
>
> 非スコープ: 失敗史、仕様の背景、ケーススタディの詳細
>
> **逆引き設計図**: Claude Code フレームワークをゼロから構築するためのガイド
>
> 更新: 2026-01-20

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

### 2.5 構築順序

1. Module（単機能スクリプト）を作る
2. Skill にパッケージ化する
3. SubAgent を定義する
4. 最後に Hook を接続する

### 2.6 失敗と回復

- 失敗時の分岐を最初から設計に含める
- 失敗ログは Evidence として保存し、再発防止のトリガにする

---

## 3. 現状棚卸し（Hook/Skill/SubAgent）

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
  hooks/
    pre-tool-guard.sh
    session-init.sh
    stop-guard.sh
  skills/
    topic-classifier/
    playbook-creator/
    executor-resolver/
    state-updater/
    lint-runner/
    integrity-checker/
    health-checker/
    test-runner/
    playbook-validator/
    code-validator/
    branch-manager/
    pr-manager/
    archive-manager/
    branch-protector/
    file-protector/
    playbook-gate/
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
```

---

## 8. 構築フェーズ（段階導入）

| Phase | 目的 | Hook |
| --- | --- | --- |
| 0 | 最小環境（CLAUDE.md） | なし |
| 1 | 状態管理（state.md） | なし |
| 2 | Module 単体 | なし |
| 3 | SubAgent 単体 | なし |
| 4 | playbook テンプレ | なし |
| 5 | Skill パッケージ化 | なし |
| 6 | Hook 統合 | ここで初めて有効化 |
| 7 | 自動化（PR/アーカイブ） | 有効 |

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

- 単一責務: 各 Skill/SubAgent が 1 目的のみを持つ
- 呼び出し経路: Skill -> SubAgent のみ（Task 直呼び禁止）
- playbook-gate: playbook 無しの Edit/Write/Bash を遮断できる
- review 分離: playbook と code が別 reviewer に分離されている
- invoker: coderabbit/codex は呼び出しのみで判定しない
- critic: done 判定は critic PASS が必須
- Hook: 強制可能範囲のみを Hook に残している

---

## 11. Claude Code 公式仕様

- Hooks: https://code.claude.com/docs/ja/hooks
- SubAgents: https://code.claude.com/docs/ja/sub-agents
- Settings: https://code.claude.com/docs/ja/settings

---
