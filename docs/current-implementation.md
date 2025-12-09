# ユーザー確認事項（2025-12-09）

> 最終確認: 2025-12-09
> 確認者: Claude

## 確認事項と分析結果

| No | 確認事項 | 状態 | 詳細 |
|----|---------|------|------|
| 1 | ユーザーがどんなプロンプトを入力しても、同一ワークフローが最初に必ず発火するか | ⚠️ GAP | UserPromptSubmit Hook 未使用 |
| 2 | 最初に発火したワークフロー（Subagent、またはHooks）から次の入力処理出力につながっているか | ✅ OK | session-start → pending → init-guard → Read |
| 3 | state.md によるセッション行動定義 | ✅ OK | focus, playbook, done_criteria で定義 |
| 4 | git/branch/remote 操作 | ✅ OK | check-main-branch, session-end で管理 |
| 5 | project.md と playbook の同期、ではなく相互に監視し合う構造になっており、ユーザープロンプトや現在の進行と乖離している時に、project.mdを疑い修正する能力があるか | ⚠️ 部分的 | check-coherence.sh が未登録 |
| 6 | playbook のチェックボックス方式 | ✅ OK | ✅ + test_method + executor 定義あり |
| 7 | TDD と報酬詐欺防止。これが最重要。 テスト駆動に関してだと、「どんな動きをするのが正しいか」を先に定義するのが大事である。事前定義は構造的に行われているか、またあらゆるタスクに対応可能か、ループ的な試験に最適化されているか| ✅ OK | critic + critic-guard で多層防御 |
| 8 | phaseが失敗している時に、playbook 参照を参照してplaybook自体を疑うことが可能か。playbookはチェックボックス式になっていて、かならず1タスクあたりにclaudecode,codex.coderabbit.ユーザーが割り当てられているか。playbookには必ずTDDhがタスクとして登録されているか | ⚠️ GAP | .archive/ はあるが自動参照機構なし |
| 9 | Phase 終了時の構造的出力、つまりそのphaseで何をやったのかがlogとして構造的に記録され続けているか、ユーザープロンプトとセットになっていることが望ましい。 | ⚠️ GAP | [自認] はあるが Phase 完了サマリーなし |
| 10 | ユーザープロンプトが妥当でない時に、ユーザーにNOを突きつけることができるか | ✅ OK | plan-guard + scope-guard で拒否可能 |
| 11 | Hooks/SubAgent 連携最適化。ではなくすべての入力処理出力処理が明確につながっているか、構造が参照できるようにリポジトリ内のファイルに保存されているか | ⚠️ 要判断 | UserPromptSubmit, Stop 未使用 |

---

## 入力→処理→出力フロー（公式仕様準拠）

> **Source**: extension-system.md Section 1.7
> **目的**: 全ユーザープロンプトが同一ワークフローで処理されることを保証

### 全体フロー図

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Claude Code 処理パイプライン                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  [入力] ユーザープロンプト                                                │
│           │                                                              │
│           ▼                                                              │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ SessionStart (セッション開始/再開/clear/compact)                 │    │
│  │   → session-start.sh: 状態表示、pending 作成、ガイダンス        │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│           │                                                              │
│           ▼                                                              │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ UserPromptSubmit (全プロンプト受信時)                           │    │
│  │   → ??? : 未実装 ← 確認事項 #1 の GAP                          │    │
│  │   期待: plan との整合性チェック、スコープ外検出                  │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│           │                                                              │
│           ▼                                                              │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ [処理] LLM がツール選択                                          │    │
│  │   → description 照合で SubAgent/Skill 自動委譲判断              │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│           │                                                              │
│           ▼                                                              │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ PreToolUse(*) - 全ツール共通                                    │    │
│  │   → init-guard.sh: 必須 Read 強制                               │    │
│  │   → check-main-branch.sh: main ブランチ警告                     │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│           │                                                              │
│           ├── Edit/Write の場合 ─────────────────────────────────────┐  │
│           │                                                          │  │
│           ▼                                                          ▼  │
│  ┌───────────────────────┐  ┌───────────────────────────────────────┐  │
│  │ PreToolUse(Bash)      │  │ PreToolUse(Edit/Write)                │  │
│  │   → pre-bash-check.sh │  │   → check-protected-edit.sh          │  │
│  │     (git commit 検出) │  │   → playbook-guard.sh                │  │
│  │     → check-coherence │  │   → critic-guard.sh                  │  │
│  │     → check-state-upd │  │   → scope-guard.sh                   │  │
│  └───────────────────────┘  │   → executor-guard.sh                │  │
│           │                  └───────────────────────────────────────┘  │
│           │                              │                               │
│           ▼                              ▼                               │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ [ツール実行]                                                     │    │
│  │   ブロック(exit 2) → エラー表示、処理中断                        │    │
│  │   許可(exit 0) → 実行継続                                       │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│           │                                                              │
│           ▼                                                              │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ PostToolUse(Task)                                                │    │
│  │   → log-subagent.sh: SubAgent 発動ログ                          │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│           │                                                              │
│           ▼                                                              │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ Stop/SubagentStop (停止試行時)                                  │    │
│  │   → ??? : 未実装 ← 確認事項 #9, #11 の GAP                      │    │
│  │   期待: Phase 完了サマリー、継続判定                             │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│           │                                                              │
│           ▼                                                              │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ SessionEnd (セッション終了時)                                    │    │
│  │   → session-end.sh: 状態保存、未 push 警告                      │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│           │                                                              │
│           ▼                                                              │
│  [出力] 結果をユーザーに表示                                             │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### フロー上の GAP

| 位置 | イベント | 現状 | 必要な実装 |
|------|---------|------|-----------|
| 入力直後 | UserPromptSubmit | **未使用** | プロンプト判別 → plan 整合性チェック |
| 処理後 | Stop | **未使用** | Phase 完了サマリー、継続判定 |
| SubAgent 後 | SubagentStop | **未使用** | critic 結果自動処理 |

### 確認事項との対応

| 確認事項 | フロー上の位置 | 対応状況 |
|---------|--------------|---------|
| #1 同一ワークフロー | UserPromptSubmit | ⚠️ GAP - 入口がない |
| #2 Hook 連携 | 全体フロー | ⚠️ 部分的 - 連鎖が不完全 |
| #9 Phase 完了出力 | Stop | ⚠️ GAP - 未実装 |
| #11 最適連携 | 全イベント | ⚠️ GAP - 3箇所未使用 |

---

## GAP 詳細と対策

### GAP 1: UserPromptSubmit Hook 未使用

```yaml
問題: セッション開始時のみ Hook 発火。個別プロンプトは Hook なしで処理
影響: プロンプト単位での制御が構造的にできない
フロー上の位置: 入力直後（全プロンプトの入口）

対策案:
  priority: 高
  action: UserPromptSubmit Hook を settings.json に追加
  効果: 全プロンプトで plan-guard ロジックを構造的に強制
```

### GAP 5: check-coherence.sh が settings.json 未登録

```yaml
問題: project.md と playbook の整合性チェックが自動発火しない
影響: 矛盾があってもコミット可能

対策案:
  priority: 高
  action: PreToolUse(Bash) に check-coherence.sh を追加
  効果: コミット前に整合性を構造的にチェック

注記: pre-bash-check.sh 経由で間接呼出されているが、
      フロー図に明記されていなかった
```

### GAP 8: 中断時の以前 playbook 参照機構なし

```yaml
問題: Phase 中断時に .archive/ の playbook を自動参照する仕組みがない
影響: 過去の失敗パターンを活かせない

対策案:
  priority: 中
  action: learning Skill の拡張または専用 SubAgent 作成
  効果: 過去の playbook から教訓を自動取得

注記: Skill はガイドライン（LLM 依存）であり、
      「構造的に自動参照」するには Hook が必要
```

### GAP 9: Phase 終了時の構造的出力なし

```yaml
問題: Phase 完了時に「何をやったか」が構造化されていない
影響: ユーザーへの報告が LLM 依存
フロー上の位置: Stop（停止試行時）

対策案:
  priority: 中
  action: Stop Hook を settings.json に追加
  効果: Phase 完了を自動検出し、構造的にサマリー出力

注記: Stop は「エージェント停止試行時」であり、
      「Phase 完了時」とは異なる可能性がある
```

### 確認事項 11: 最適化の余地

```yaml
未使用の Hook イベント:
  - UserPromptSubmit: プロンプト単位制御 ← 入口
  - Stop: POST_LOOP 自動化 ← 出口
  - SubagentStop: critic 結果自動評価
  - PreCompact: 重要情報保持

推奨アクション（ユーザー判断必要）:
  1. UserPromptSubmit を追加して plan-guard を構造的に強制
  2. Stop を追加して Phase 完了サマリーを自動出力
  3. SubagentStop を追加して critic PASS/FAIL を自動処理
```

---

## GAP 対応計画（厳密版）

> 各確認事項の意図を厳密に反映。一切の省略なし。

### 確認事項の意図マッピング

| No | 確認事項 | 意図（厳密解釈） | 必要な実装 |
|----|---------|----------------|-----------|
| 1 | 同一ワークフロー | **全て**のユーザープロンプトが**同じ**経路で処理される | UserPromptSubmit Hook |
| 2 | 連鎖 | Hook A → Hook B → Action の**明確な連鎖** | Hook 間の依存関係定義 |
| 3 | state.md 定義 | 行動が state.md で**定義**され、**更新**される | check-state-update.sh 登録 |
| 4 | git 操作 | ブランチ・リモート操作が**構造的に管理** | 既存で OK |
| 5 | project.md 同期 | 矛盾時に **project.md を疑う**ロジック | check-coherence.sh 登録 + 矛盾検出強化 |
| 6 | チェックボックス | test_method + executor（**作業者明記**） | 既存で OK |
| 7 | 予実管理・報酬詐欺 | **多層（トリプル以上）**のチェック機構 | 5層防御の確立 |
| 8 | 過去 playbook 参照 | 中断時に**自動で**以前の playbook を参照 | archive-reference 機能 |
| 9 | Phase 完了出力 | **構造的に**（LLM 依存なく）出力 | Stop/PostToolUse Hook |
| 10 | プロンプト拒否 | **構造的に**拒否可能（exit 2） | UserPromptSubmit + exit 2 |
| 11 | 最適連携 | 公式仕様に基づく**最適化** | 未使用 Hook の活用 |

---

### Phase 1: 高優先度（構造的ブロックの補完）

```yaml
対象: 確認事項 #3, #5
目的: 構造的ブロックの穴を塞ぐ

実装内容:
  1. check-coherence.sh を settings.json に登録:
     - トリガー: PreToolUse(Bash) - git commit 時
     - 効果: project.md と playbook の矛盾を構造的にブロック
     - 矛盾検出時: 「project.md の done_when を確認してください」と出力

  2. check-state-update.sh を settings.json に登録:
     - トリガー: PreToolUse(Bash) - git commit 時
     - 効果: state.md 未更新でのコミットを警告

検証方法:
  - git commit を試行し、矛盾時にブロックされることを確認
```

---

### Phase 2: UserPromptSubmit Hook（全プロンプト統一処理）

```yaml
対象: 確認事項 #1, #10
目的: 全ユーザープロンプトを同一ワークフローで処理

実装内容:
  1. .claude/hooks/prompt-guard.sh を作成:
     入力: { "prompt": "ユーザー入力" }
     処理:
       a. state.md から focus.current を取得
       b. active_playbooks.{focus} を取得
       c. playbook の current phase を取得
       d. プロンプトと plan の整合性をチェック
     出力:
       - 整合: continue
       - 不整合: systemMessage で警告（ブロックはしない）
       - 明確なスコープ外: decision: block + reason

  2. settings.json に UserPromptSubmit を登録:
     {
       "hooks": {
         "UserPromptSubmit": [
           {
             "type": "command",
             "command": "bash .claude/hooks/prompt-guard.sh"
           }
         ]
       }
     }

連鎖の実現（確認事項 #2）:
  UserPromptSubmit (prompt-guard.sh)
       ↓
  plan との整合性判定
       ↓
  PreToolUse(*) (init-guard.sh)
       ↓
  必須ファイル Read 強制
       ↓
  PreToolUse(Edit/Write) (playbook-guard.sh, scope-guard.sh)
       ↓
  実際の作業

検証方法:
  - スコープ外プロンプトを送信し、警告またはブロックを確認
```

---

### Phase 3: 多層報酬詐欺防止（5層防御）

```yaml
対象: 確認事項 #7
目的: 報酬詐欺の可能性を 0% に近づける

現在の防御層:
  Layer 1: CLAUDE.md ルール（ガイドライン）
  Layer 2: critic SubAgent（判断）
  Layer 3: critic-guard.sh（視覚的警告、settings.json 登録済み）

追加する防御層:
  Layer 4: check-coherence.sh（構造的ブロック）
    - Phase 1 で登録
    - state: done への遷移時に self_complete を確認
    - 矛盾検出で exit 2

  Layer 5: SubagentStop Hook（critic 結果自動評価）
    - .claude/hooks/critic-result-handler.sh を作成
    - critic が FAIL を返した場合:
      - state.md の self_complete を false に維持
      - 「修正が必要です」と構造的に出力
    - critic が PASS を返した場合:
      - state.md の self_complete を true に更新可能に

5層防御の全体像:
  ┌─────────────────────────────────────────────────────────────┐
  │                    5層報酬詐欺防御                           │
  ├─────────────────────────────────────────────────────────────┤
  │ L1: CLAUDE.md LOOP/CRITIQUE（行動ルール）                    │
  │     ↓ LLM が「critic 呼ぶべき」と判断                        │
  │ L2: critic SubAgent（証拠ベース判断）                        │
  │     ↓ critic が PASS/FAIL 返す                              │
  │ L3: critic-guard.sh（done 更新前に警告）                     │
  │     ↓ self_complete: false なら警告                         │
  │ L4: check-coherence.sh（state-playbook 整合性）              │
  │     ↓ 矛盾あれば exit 2 でブロック                           │
  │ L5: SubagentStop Hook（critic 結果自動処理）                 │
  │     ↓ FAIL なら self_complete 更新をブロック                 │
  └─────────────────────────────────────────────────────────────┘

検証方法:
  - 証拠なしで done を主張 → 5層全てが反応することを確認
```

---

### Phase 4: Phase 完了サマリー出力（構造的）

```yaml
対象: 確認事項 #9
目的: Phase 完了時に LLM 依存なく構造的に出力

実装内容:
  1. Stop Hook を追加:
     .claude/hooks/phase-summary.sh
     トリガー: Stop イベント（エージェント停止試行時）
     処理:
       a. playbook の現在 Phase を取得
       b. done_criteria の達成状況を取得
       c. evidence を取得
       d. 構造化されたサマリーを出力

  2. 出力形式:
     ┌─────────────────────────────────────────┐
     │ Phase 完了サマリー                       │
     ├─────────────────────────────────────────┤
     │ Phase: p1 (構造的ブロックテスト)         │
     │ Status: done                            │
     │ done_criteria:                          │
     │   - T1: ✅ (exit 2 確認)                │
     │   - T2: ✅ (exit 2 確認)                │
     │   - T3: ✅ (exit 2 確認)                │
     │   - T4: ✅ (exit 2 確認)                │
     │ Evidence: playbook に記録済み            │
     │ Next: p2 (失敗シナリオ防御テスト)        │
     └─────────────────────────────────────────┘

検証方法:
  - Phase 完了後にセッション終了 → サマリーが出力されることを確認
```

---

### Phase 5: 過去 playbook 参照機能

```yaml
対象: 確認事項 #8
目的: Phase 中断時に過去の playbook を自動参照

実装内容:
  1. learning Skill の拡張:
     .claude/skills/learning/SKILL.md に追加:
     ```
     中断検出時の行動:
       1. .archive/plan/ を検索
       2. 類似の Phase 名または done_criteria を持つ playbook を特定
       3. その playbook の evidence / known_issues を参照
       4. 「過去の教訓」として出力
     ```

  2. または archive-reference SubAgent を作成:
     .claude/agents/archive-reference.md
     description: AUTOMATICALLY references archived playbooks when phase completion is blocked or fails. Learns from past failures.
     tools: Read, Grep, Glob
     trigger: Phase 中断時、critic FAIL 時

  3. init-guard.sh の拡張:
     ブロック時に .archive/ を検索し、関連 playbook を提示

検証方法:
  - Phase 中断 → 過去の関連 playbook が参照されることを確認
```

---

### Phase 6: 最適連携の実現（全 Hook イベント活用）

```yaml
対象: 確認事項 #11
目的: 公式仕様に基づく最適な Hook/SubAgent 連携

追加する Hook:
  1. UserPromptSubmit (Phase 2 で実装)
  2. Stop (Phase 4 で実装)
  3. SubagentStop (Phase 3 で実装)
  4. PreCompact:
     .claude/hooks/pre-compact.sh
     処理: 重要情報（current phase, done_criteria, evidence）を保持指示

最終的な Hook 連携図:
  SessionStart ──→ session-start.sh（状態表示、pending 作成）
       ↓
  UserPromptSubmit ──→ prompt-guard.sh（plan 整合性チェック）
       ↓
  PreToolUse(*) ──→ init-guard.sh（必須 Read 強制）
       ↓
  PreToolUse(Edit/Write) ──→ playbook-guard.sh, scope-guard.sh, critic-guard.sh
       ↓
  PostToolUse(Task) ──→ log-subagent.sh
       ↓
  SubagentStop ──→ critic-result-handler.sh（critic 結果処理）
       ↓
  PreToolUse(Bash) ──→ pre-bash-check.sh, check-coherence.sh
       ↓
  Stop ──→ phase-summary.sh（Phase サマリー出力）
       ↓
  PreCompact ──→ pre-compact.sh（重要情報保持）
       ↓
  SessionEnd ──→ session-end.sh（状態保存）
```

---

### 実行計画

| Phase | 所要時間 | 成果物 |
|-------|---------|--------|
| 1 | 10分 | settings.json 更新 |
| 2 | 30分 | prompt-guard.sh + settings.json |
| 3 | 30分 | critic-result-handler.sh + settings.json |
| 4 | 20分 | phase-summary.sh + settings.json |
| 5 | 30分 | learning Skill 拡張 または archive-reference.md |
| 6 | 20分 | pre-compact.sh + 最終検証 |

**合計: 約 2時間 20分**

---

# 現在実装の棚卸し・完全版
>
> 最終確認: 2025-12-09
> 検証方法: settings.json, .claude/agents/*.md, .claude/skills/*/, .claude/commands/*.md を直接読み込み
> 追加検証: 13 テストケース（T1-T13）による動作実証
>
> 関連ドキュメント:
> - [extension-system.md](./extension-system.md): Claude Code 公式リファレンスに基づく拡張システム体系
> - [plan/project.md](../plan/project.md): Macro 計画（DW-000 に最適化計画を含む）

---

## 1. Hooks 実装状況

### 1.1 settings.json 登録済み（実際の設定）

> ソース: `.claude/settings.json`

#### PreToolUse（*）- 全ツール対象
| Hook | timeout | 用途 |
|------|---------|------|
| init-guard.sh | 3000ms | 必須ファイル Read 前のツールブロック |
| check-main-branch.sh | 3000ms | main ブランチ警告 |

#### PreToolUse（Edit）- 編集ツール対象
| Hook | timeout | 用途 |
|------|---------|------|
| check-protected-edit.sh | 5000ms | 保護ファイル編集ブロック |
| playbook-guard.sh | 3000ms | playbook=null でブロック |
| check-file-dependencies.sh | 3000ms | 依存ファイル情報表示 |
| critic-guard.sh | 3000ms | done 更新前に critic 要求 |
| scope-guard.sh | 3000ms | スコープ外編集警告 |
| executor-guard.sh | 3000ms | executor 不一致警告 |

#### PreToolUse（Write）- 同上（Edit と同一）
| Hook | timeout | 用途 |
|------|---------|------|
| check-protected-edit.sh | 5000ms | 保護ファイル編集ブロック |
| playbook-guard.sh | 3000ms | playbook=null でブロック |
| check-file-dependencies.sh | 3000ms | 依存ファイル情報表示 |
| critic-guard.sh | 3000ms | done 更新前に critic 要求 |
| scope-guard.sh | 3000ms | スコープ外編集警告 |
| executor-guard.sh | 3000ms | executor 不一致警告 |

#### PreToolUse（Bash）
| Hook | timeout | 用途 |
|------|---------|------|
| pre-bash-check.sh | 10000ms | git commit 前チェック呼び出し |

#### SessionStart（*）
| Hook | timeout | 用途 |
|------|---------|------|
| session-start.sh | 5000ms | 状態表示、ガイダンス、pending 作成 |

#### PostToolUse（Task）
| Hook | timeout | 用途 |
|------|---------|------|
| log-subagent.sh | 3000ms | SubAgent 実行ログ記録 |

#### SessionEnd（*）
| Hook | timeout | 用途 |
|------|---------|------|
| session-end.sh | 5000ms | 状態保存、未 push 警告 |

#### UserPromptSubmit（*）- 新規追加
| Hook | timeout | 用途 |
|------|---------|------|
| prompt-guard.sh | 3000ms | プロンプト単位の plan 整合性チェック、スコープ外ブロック |

#### Stop（*）- 新規追加
| Hook | timeout | 用途 |
|------|---------|------|
| stop-summary.sh | 3000ms | Phase 状態サマリー出力 |

### 1.2 間接呼び出しの Hook

> ✅ これらは settings.json に直接登録されていないが、pre-bash-check.sh 経由で呼び出される

| Hook | ファイルパス | 呼び出し元 | 発火タイミング |
|------|------------|-----------|--------------|
| check-coherence.sh | .claude/hooks/ | pre-bash-check.sh | git commit 時 |
| check-state-update.sh | .claude/hooks/ | pre-bash-check.sh | git commit 時 |
| check-manifest-sync.sh | .claude/hooks/ | 手動 | 手動呼び出しのみ |
| check-playbook-quality.sh | .claude/hooks/ | 手動 | 手動呼び出しのみ |

### 1.3 Hook ファイル一覧（18個）

```
.claude/hooks/
├── init-guard.sh            ✓ 登録済み (PreToolUse *)
├── check-main-branch.sh     ✓ 登録済み (PreToolUse *)
├── check-protected-edit.sh  ✓ 登録済み (PreToolUse Edit/Write)
├── playbook-guard.sh        ✓ 登録済み (PreToolUse Edit/Write)
├── check-file-dependencies.sh ✓ 登録済み (PreToolUse Edit/Write)
├── critic-guard.sh          ✓ 登録済み (PreToolUse Edit/Write)
├── scope-guard.sh           ✓ 登録済み (PreToolUse Edit/Write)
├── executor-guard.sh        ✓ 登録済み (PreToolUse Edit/Write)
├── pre-bash-check.sh        ✓ 登録済み (PreToolUse Bash)
├── session-start.sh         ✓ 登録済み (SessionStart)
├── log-subagent.sh          ✓ 登録済み (PostToolUse Task) + Layer 5
├── session-end.sh           ✓ 登録済み (SessionEnd)
├── prompt-guard.sh          ✓ 登録済み (UserPromptSubmit) ← 新規
├── stop-summary.sh          ✓ 登録済み (Stop) ← 新規
├── check-coherence.sh       ✓ 間接呼出 (pre-bash-check.sh → git commit)
├── check-state-update.sh    ✓ 間接呼出 (pre-bash-check.sh → git commit)
├── check-manifest-sync.sh   - 手動用
└── check-playbook-quality.sh - 手動用
```

### 1.4 優先度ツリー

```
P0 ─── 絶対守護（HARD_BLOCK）
│      ├── CLAUDE.md
│      └── .claude/protected-files.txt
│
P1 ─── セーフティ機構（BLOCK/WARN）
│      └── check-protected-edit.sh
│
P2 ─── 初期化強制 + プロンプト制御
│      ├── session-start.sh (SessionStart)
│      ├── init-guard.sh (PreToolUse *)
│      └── prompt-guard.sh (UserPromptSubmit) ← 新規
│
P3 ─── 状態連動（四つ組の整合性）
│      ├── check-main-branch.sh
│      ├── playbook-guard.sh
│      ├── scope-guard.sh
│      └── executor-guard.sh
│
P4 ─── 検証強制
│      ├── critic-guard.sh
│      ├── pre-bash-check.sh
│      ├── check-coherence.sh      ← 間接呼出（pre-bash-check.sh）
│      └── check-state-update.sh   ← 間接呼出（pre-bash-check.sh）
│
P5 ─── 監視・記録・サマリー
       ├── check-file-dependencies.sh
       ├── log-subagent.sh + Layer 5
       ├── session-end.sh
       └── stop-summary.sh (Stop) ← 新規
```

### 1.5 Hook イベント活用状況

| イベント | 公式仕様 | 現状 | 実装 |
|---------|---------|------|------|
| **UserPromptSubmit** | プロンプト送信時 | ✅ 活用中 | prompt-guard.sh |
| **Stop** | エージェント停止時 | ✅ 活用中 | stop-summary.sh |
| **SubagentStop** | SubAgent 完了時 | ⚠️ 代替実装 | PostToolUse(Task) で critic 処理 |
| **PreCompact** | コンパクト前 | 未使用 | 優先度低（必要時追加） |
| **PermissionRequest** | 権限確認時 | 未使用 | bypassPermissions で不要 |
| **Notification** | 通知時 | 未使用 | 優先度低 |

---

## 2. SubAgents 実装状況

### 2.1 現在の SubAgents（9個）

> ソース: `.claude/agents/*.md` の frontmatter を直接読み込み

| Agent | model | tools | description キーワード |
|-------|-------|-------|---------------------|
| **critic** | haiku | Read, Grep, Bash | MUST BE USED before marking any task as done |
| **pm** | haiku | Read, Write, Edit, Grep, Glob | PROACTIVELY manages playbooks and project progress |
| **coherence** | haiku | Read, Bash, Grep | PROACTIVELY checks state.md and playbook consistency |
| **state-mgr** | haiku | Read, Edit, Write, Grep, Bash | AUTOMATICALLY manages state.md, playbook operations |
| **reviewer** | haiku | Read, Grep, Glob, Bash | Use this agent for code and design reviews |
| **health-checker** | haiku | Read, Grep, Glob, Bash | システム状態の定期監視 |
| **plan-guard** | haiku | Read, Grep, Glob | PROACTIVELY checks 3-layer plan coherence |
| **setup-guide** | sonnet | Read, Write, Edit, Bash, Grep, Glob | AUTOMATICALLY guides setup process |
| **beginner-advisor** | haiku | Read | AUTOMATICALLY explains technical terms with metaphors |

### 2.2 SubAgents 詳細

#### critic
```yaml
file: .claude/agents/critic.md
description: MUST BE USED before marking any task as done. Evaluates done_criteria with evidence-based judgment. Prevents self-reward fraud through critical thinking.
model: haiku
tools: Read, Grep, Bash
trigger: done 判定前（必須）
enforcement: 複合的防御（構造的ブロック困難）
  - CLAUDE.md LOOP（行動ルール MUST）
  - critic-guard.sh（視覚的警告）
```

#### pm
```yaml
file: .claude/agents/pm.md
description: PROACTIVELY manages playbooks and project progress. Creates playbook when missing, tracks phase completion, manages scope. Says NO to scope creep.
model: haiku
tools: Read, Write, Edit, Grep, Glob
trigger: playbook=null, Phase 完了, スコープ外要求
機能:
  - 計画の導出（Plan Derivation）
  - playbook 作成
  - 進捗管理
  - スコープ管理（NO と言う）
```

#### coherence
```yaml
file: .claude/agents/coherence.md
description: PROACTIVELY checks state.md and playbook consistency before git commit. Detects focus mismatch and forbidden state transitions.
model: haiku
tools: Read, Bash, Grep
trigger: commit 前、整合性確認
```

#### state-mgr
```yaml
file: .claude/agents/state-mgr.md
description: AUTOMATICALLY manages state.md, playbook operations, and layer structure. Use for focus switching, state transitions, and playbook phase updates.
model: haiku
tools: Read, Edit, Write, Grep, Bash
trigger: focus 切替、状態遷移
```

#### reviewer
```yaml
file: .claude/agents/reviewer.md
description: Use this agent for code and design reviews. Evaluates code quality, design patterns, and best practices. Provides constructive feedback for improvements.
model: haiku
tools: Read, Grep, Glob, Bash
trigger: 手動呼び出し
⚠️ PROACTIVELY/AUTOMATICALLY なし → 自動委譲されにくい
```

#### health-checker
```yaml
file: .claude/agents/health-checker.md
description: システム状態の定期監視。state.md/playbook の整合性、git 状態、ファイル存在確認などを行う。
model: haiku
tools: Read, Grep, Glob, Bash
trigger: 手動呼び出し
⚠️ 日本語 description → 自動委譲されにくい可能性
```

#### plan-guard
```yaml
file: .claude/agents/plan-guard.md
description: PROACTIVELY checks 3-layer plan coherence at session start. Rejects or reconfirms when no plan exists or user prompt is unrelated to existing plan. LLM-led session flow.
model: haiku
tools: Read, Grep, Glob
trigger: セッション開始、プロンプト受信
```

#### setup-guide
```yaml
file: .claude/agents/setup-guide.md
description: AUTOMATICALLY guides setup process when focus.current=setup. Conducts hearing, environment setup, and Skills generation. Does not ask unnecessary questions.
model: sonnet  # 唯一の sonnet
tools: Read, Write, Edit, Bash, Grep, Glob
trigger: focus.current=setup
```

#### beginner-advisor
```yaml
file: .claude/agents/beginner-advisor.md
description: AUTOMATICALLY explains technical terms with metaphors when beginner-level questions are detected. Proactively simplifies complex concepts.
model: haiku
tools: Read
trigger: 初心者質問検出、重要タイミング
```

---

## 3. Skills 実装状況

### 3.1 現在の Skills（9個）

> ソース: `.claude/skills/*/SKILL.md` または `skill.md` を直接読み込み

| Skill | ファイル名 | frontmatter | 状態 |
|-------|----------|-------------|------|
| **state** | SKILL.md | ✓ あり | 正常 |
| **plan-management** | SKILL.md | ✓ あり | 正常 |
| **context-management** | SKILL.md | ✓ あり（triggers含む） | 正常 |
| **execution-management** | SKILL.md | ✓ あり（triggers含む） | 正常 |
| **learning** | SKILL.md | ✓ あり（triggers含む） | 正常 |
| **frontend-design** | SKILL.md | ✗ なし | ⚠️ 要修正 |
| **lint-checker** | skill.md | ✗ なし | ⚠️ 要修正（ファイル名＋frontmatter） |
| **test-runner** | skill.md | ✗ なし | ⚠️ 要修正（ファイル名＋frontmatter） |
| **deploy-checker** | skill.md | ✗ なし | ⚠️ 要修正（ファイル名＋frontmatter） |

### 3.2 Skills 詳細

#### 正常な Skills

```yaml
state:
  name: state
  description: このワークスペースの state.md 管理、playbook 運用、レイヤー構造の専門知識。

plan-management:
  name: plan-management
  description: Multi-layer planning and playbook management. Use when creating playbooks, transitioning phases, or managing plan hierarchy. Triggers on "plan", "playbook", "phase", "roadmap", "milestone" keywords.

context-management:
  name: context-management
  description: /compact 最適化と履歴要約のガイドライン。コンテキスト管理の専門知識を提供。
  triggers:
    - /compact を実行する前
    - コンテキストが 80% を超えたとき
    - セッション終了時

execution-management:
  name: execution-management
  description: 並列実行制御とリソース配分のガイドライン。タスク実行の最適化を支援。
  triggers:
    - 複数タスクを同時に実行するとき
    - コンテキストが逼迫しているとき

learning:
  name: learning
  description: 失敗パターンの記録・学習。過去の失敗から学び、同じ問題を繰り返さない。
  triggers:
    - エラーが発生したとき
    - critic が FAIL を返したとき
```

#### 問題のある Skills

```yaml
frontend-design:
  file: .claude/skills/frontend-design/SKILL.md
  問題: frontmatter なし
  対策: YAML frontmatter を追加する

lint-checker:
  file: .claude/skills/lint-checker/skill.md
  問題:
    1. ファイル名が小文字（公式仕様は SKILL.md）
    2. frontmatter なし
  対策: SKILL.md にリネーム + frontmatter 追加

test-runner:
  file: .claude/skills/test-runner/skill.md
  問題: 同上
  対策: 同上

deploy-checker:
  file: .claude/skills/deploy-checker/skill.md
  問題: 同上
  対策: 同上
```

---

## 4. Commands 実装状況

### 4.1 現在の Commands（7個）

> ソース: `.claude/commands/*.md`

| Command | ファイル | 用途 | 関連 Agent |
|---------|---------|------|-----------|
| /crit | crit.md | done_criteria 達成状況チェック | critic |
| /playbook-init | playbook-init.md | 新しいタスク開始フロー | pm |
| /lint | lint.md | 整合性チェック実行 | coherence |
| /focus | focus.md | レイヤーフォーカス切替 | state-mgr |
| /test | test.md | done_criteria テスト実行 | - |
| /rollback | rollback.md | Git ロールバック | - |
| /state-rollback | state-rollback.md | state.md バックアップ・復元 | - |

### 4.2 不足している Commands

```yaml
提案:
  - /health: health-checker 呼び出し
  - /review: reviewer 呼び出し
  - /plan: plan-guard 呼び出し
```

---

## 5. Git 操作自律化

> **四つ組（state-playbook-git-branch）の整合性を自動で維持する仕組み**

### 5.1 ブランチ保護フロー

```
                    ┌─────────────────────────────────────┐
                    │          PreToolUse(*)              │
                    │        check-main-branch.sh         │
                    └─────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
              focus=setup     focus=product   focus=workspace
                    │               │               │
                 許可            許可          main ブランチ?
                                                    │
                                            ┌───────┴───────┐
                                           YES              NO
                                            │               │
                                      ブロック(exit 2)    許可
                                            │
                                   「git checkout -b」を促す
```

#### check-main-branch.sh の詳細

```yaml
発火: PreToolUse(*)
対象: Edit, Write, Bash（git checkout/switch/branch は除外）
許可ツール: Read, Grep, Glob（読み取りは常に許可）

条件判定:
  focus=setup|product|plan-template: main でも許可（新規ユーザー用）
  focus=workspace:
    main/master ブランチ → exit 2（ブロック）
    それ以外 → 許可

例外:
  - state.md への Edit は許可（デッドロック回避）
  - git checkout/switch/branch は許可（ブランチ切り替え用）
```

### 5.2 コミット前自動チェック

```
                    ┌─────────────────────────────────────┐
                    │          PreToolUse(Bash)           │
                    │          pre-bash-check.sh          │
                    └─────────────────────────────────────┘
                                    │
                          "git commit" を検出?
                                    │
                            ┌───────┴───────┐
                           YES              NO
                            │               │
                    ┌───────┴───────┐     通過
                    │               │
            回帰テスト実行     整合性チェック
   .claude/tests/regression-test.sh    │
                    │               │
                 FAIL?          check-coherence.sh
                    │           check-state-update.sh
                 exit 1              │
                (ブロック)        警告表示
```

#### pre-bash-check.sh の詳細

```yaml
発火: PreToolUse(Bash)
トリガー: "git commit" パターン検出

実行内容:
  1. 保護ファイル書き込み検出:
     - HARD_BLOCK: CLAUDE.md, .claude/protected-files.txt
     - BLOCK (strict mode): settings.json, hooks/, plan/template/

  2. 回帰テスト（存在する場合）:
     - .claude/tests/regression-test.sh を実行
     - 失敗 → exit 1（コミットブロック）

  3. 整合性チェック:
     - check-coherence.sh を呼び出し
     - check-state-update.sh を呼び出し
```

#### check-coherence.sh の詳細

```yaml
呼び出し元: pre-bash-check.sh（git commit 時）
登録状況: ⚠️ settings.json 未登録（手動/間接呼び出しのみ）

チェック項目:
  1. 全レイヤーの state と playbook.phases の整合性
     - state=pending なのに done phases がある → ERROR
     - state=done なのに pending phases がある → ERROR

  2. ブランチ整合性
     - playbook.branch と現在のブランチが一致するか
     - 不一致 → ERROR + exit 2

  3. focus 矛盾検出
     - staged ファイルが focus.current の editable 範囲外 → WARN

  4. critic 強制
     - state: done への変更 + self_complete: false → exit 2（ブロック）

  5. コンテキスト管理リマインダー
     - Phase 完了時に /context 確認を促す
```

#### check-state-update.sh の詳細

```yaml
呼び出し元: pre-bash-check.sh（git commit 時）
登録状況: ⚠️ settings.json 未登録

動作:
  - state.md が staged されていない場合 → 警告（ブロックなし）
  - 「state.md を更新してください」と表示
```

### 5.3 セッションライフサイクル

```
SessionStart                                              SessionEnd
    │                                                         │
    ▼                                                         ▼
session-start.sh                                      session-end.sh
    │                                                         │
    ├── 未コミット変更警告                                     ├── 未コミット変更チェック
    ├── playbook 有無チェック                                 ├── 四つ組整合性チェック
    ├── INIT ガイダンス表示                                   ├── critic リマインド
    └── session_tracking.last_start 更新                      ├── 未 push コミット検出
                                                              └── session_tracking.last_end 更新
```

#### session-end.sh の詳細

```yaml
発火: SessionEnd(*)

自動更新（LLM 依存なし）:
  - session_tracking.last_end: タイムスタンプ
  - session_tracking.uncommitted_warning: true/false

チェック項目:
  1. 未コミット変更数
  2. playbook-branch 整合性
  3. layer.state と playbook.phases の整合性
  4. 未 push コミット数（git fetch → 比較）

出力:
  - [OK] / [WARNING] のサマリー
  - 次セッション開始前の対処を促す
```

### 5.4 CLAUDE.md のルール連携

```yaml
INIT フェーズ 2:
  - git rev-parse --abbrev-ref HEAD（ブランチ確認）
  - git status -sb（変更確認）
  - main ブランチ → 新ブランチ作成を促す

CORE:
  - git_branch_sync: 1 playbook = 1 branch

POST_LOOP:
  - 残タスクあり → git checkout -b feat/{next-task}
  - 新 playbook 作成 → state.md 更新 → LOOP 継続

[自認] 出力:
  - branch: 現在のブランチ名
  - git_status: clean | modified | untracked
```

### 5.5 四つ組の連動図

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     四つ組（Four-Tuple Coherence）                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   state.md          playbook            git branch         CLAUDE.md    │
│   (focus.current)   (active_playbooks)  (HEAD)             ([自認])     │
│        │                 │                  │                   │        │
│        └────────────────┬┴──────────────────┴───────────────────┘        │
│                         │                                                │
│              ┌──────────┴──────────┐                                     │
│              │    整合性チェック    │                                     │
│              │ check-coherence.sh  │                                     │
│              └──────────┬──────────┘                                     │
│                         │                                                │
│      ┌──────────────────┼──────────────────┐                             │
│      │                  │                  │                             │
│  branch 不一致      state 矛盾       focus 外編集                         │
│      │                  │                  │                             │
│   ERROR              ERROR              WARN                             │
│  (exit 2)           (exit 2)         (警告のみ)                          │
│                                                                          │
│   → コミットブロック      → コミットブロック     → 注意喚起                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.6 Git 自律化のまとめ

| フェーズ | Hook/ルール | チェック内容 | 強制度 |
|---------|------------|-------------|--------|
| セッション開始 | session-start.sh | 未コミット警告、playbook 有無 | visual |
| ブランチ操作 | check-main-branch.sh | main ブランチ保護 | structural (exit 2) |
| コード変更 | playbook-guard.sh | playbook なしブロック | structural (exit 2) |
| コミット前 | pre-bash-check.sh | 回帰テスト、整合性 | structural (exit 1/2) |
| コミット前 | check-coherence.sh | 四つ組整合性、critic 強制 | structural (exit 2) |
| セッション終了 | session-end.sh | 未 push、整合性サマリー | visual |

---

## 6. 失敗シナリオと防御機構

> **LLM が暴走するシナリオとその防御機構**

### 6.1 自己報酬詐欺（critic バイパス）

```yaml
攻撃: critic を呼ばずに done 判定
症状: 証拠なしで Phase を done に変更

防御機構:
  - critic-guard.sh: done 更新前に警告（settings.json 登録済み）
  - CLAUDE.md LOOP: 行動ルールで MUST
  - playbook-format.md: double_check フラグ

限界: 構造的ブロックではなく警告のみ
```

### 6.2 計画乖離（DRIFT 無視）

```yaml
攻撃: project.md と無関係な作業を実行
症状: スコープ際限なく拡大

防御機構:
  - plan-guard SubAgent: 計画との整合性チェック
  - scope-guard.sh: done_when/done_criteria 変更警告
```

### 6.3 保護ファイル突破

```yaml
攻撃: admin モードで CLAUDE.md を書き換え
症状: ガバナンスルール消失

防御機構:
  - check-protected-edit.sh: HARD_BLOCK（admin でも警告）
  - protected-files.txt: BLOCK リスト定義
```

### 6.4 状態遷移スキップ

```yaml
攻撃: pending → done を直接実行
症状: 設計なし実装、バグ蓄積

防御機構:
  - check-coherence.sh（⚠️ 未登録）
  - CLAUDE-ref.md STATE MACHINE

限界: check-coherence.sh が settings.json に未登録
```

### 6.5 executor 無視

```yaml
攻撃: executor: codex の Phase を Claude が実行
症状: 専門性未活用、品質低下

防御機構:
  - executor-guard.sh: executor 不一致警告（settings.json 登録済み）
```

---

## 7. 設計原則

### 7.1 Hooks vs SubAgents vs Skills

```
判断フロー:

Q1: 構造的ブロック（exit 2）が必要?
  YES → Hooks (PreToolUse)
  NO  → Q2

Q2: LLM の判断・推論が必要?
  YES → SubAgents
  NO  → Q3

Q3: 常に参照可能な知識ベース?
  YES → Skills
  NO  → Hooks (SessionStart/End)
```

### 7.2 enforcement レベル

```yaml
structural:  # LLM が破れない
  - check-protected-edit.sh (exit 2)
  - init-guard.sh (exit 2)
  - playbook-guard.sh (exit 2)
  - check-main-branch.sh (exit 2 可能)

guideline:   # LLM 遵守に依存
  - CLAUDE.md のルール
  - critic 必須化

visual:      # 視覚的インパクト
  - session-start.sh の警告ボックス
  - critic-guard.sh の警告

passive:     # ブロックしない
  - log-subagent.sh
  - session-end.sh
  - check-file-dependencies.sh
```

### 7.3 ルール vs 構造

```
ルール（弱い）:
  「〇〇してはいけない」と書いてある
  → Claude が無視すれば終わり

構造（強い）:
  Hook が exit 2 でブロック
  → Claude が無視しようとしても物理的に不可能

設計原則:
  - 重要なルールは Hook で強制
  - Claude の善意に依存しない
  - 「うっかり」を許さない
```

---

## 8. 問題点サマリー（2025-12-09 更新）

### 8.1 ~~未登録 Hooks~~ ✅ 解決済み

| Hook | 状態 | 詳細 |
|------|------|------|
| check-coherence.sh | ✅ 間接呼出 | pre-bash-check.sh 経由で git commit 時に発火 |
| check-state-update.sh | ✅ 間接呼出 | pre-bash-check.sh 経由で git commit 時に発火 |

### 8.2 Skills のファイル名・frontmatter 問題

| Skill | 問題 | 対策 |
|-------|------|------|
| frontend-design | frontmatter なし | frontmatter 追加 |
| lint-checker | skill.md + frontmatter なし | SKILL.md にリネーム + frontmatter |
| test-runner | 同上 | 同上 |
| deploy-checker | 同上 | 同上 |

### 8.3 SubAgent の自動委譲問題

| Agent | 問題 | 対策 |
|-------|------|------|
| reviewer | PROACTIVELY/AUTOMATICALLY なし | description 改善 |
| health-checker | 日本語 description | 英語化検討 |

---

## 9. 最適化計画（2025-12-09 更新）

### ~~Phase 1: 高優先度~~ ✅ 完了

1. ✅ **check-coherence.sh** - pre-bash-check.sh 経由で間接呼出
2. ✅ **check-state-update.sh** - pre-bash-check.sh 経由で間接呼出
3. ✅ **UserPromptSubmit Hook 追加** - prompt-guard.sh
4. ✅ **Stop Hook 追加** - stop-summary.sh

### Phase 2: 中優先度（品質向上）- 保留

5. **Skills ファイル名修正** (優先度下げ、動作に影響なし)
   - lint-checker/skill.md → SKILL.md
   - test-runner/skill.md → SKILL.md
   - deploy-checker/skill.md → SKILL.md

6. **Skills frontmatter 追加** (優先度下げ)

7. **SubAgent description 最適化** (優先度下げ)

### Phase 3: 低優先度（拡張）- 保留

8. **SubagentStop Hook** - PostToolUse(Task) で代替実装済み
9. **PreCompact Hook** - 必要時に追加
10. **Command 追加** - 必要時に追加

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | **検証完了**: 10/11項目OK。「入力→処理→出力」フローを証拠ベースで検証。#8（自動参照）は部分的対応（ガイドライン依存）。 |
| 2025-12-09 | **GAP 解消実装完了**: UserPromptSubmit(prompt-guard.sh), Stop(stop-summary.sh), Layer 5(log-subagent.sh), learning Skill 拡張。 |
| 2025-12-09 | ユーザー確認事項11項目の分析完了。GAP 対応計画 Phase 1-6 策定。 |
| 2025-12-08 | Git 操作自律化セクション追加（Section 5）。spec.yaml/architecture-*.md 削除完了。 |
| 2025-12-08 | 実コードベース検証。spec.yaml/architecture-features.md 参照不要版に改訂。 |
| 2025-12-08 | spec.yaml 統合。優先度ツリー、非機能要件、詳細仕様を追加。 |
| 2025-12-08 | 初版作成。現状棚卸しとギャップ分析。 |
