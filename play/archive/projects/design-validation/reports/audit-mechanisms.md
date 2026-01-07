# チェック・レビュー機能 完全リスト

> Generated: 2026-01-07
> Playbook: audit-verification (p1.1)
> Purpose: 報酬詐欺防止のための監査機能の理解と網羅

---

## 1. Playbook 生成時チェック

playbook を作成する際に動作する検証機能。

### 1.1 フローチェーン

```
Hook(prompt.sh) → prompt-analyzer → playbook-init → pm → reviewer
```

| 順序 | コンポーネント | 発火条件 | 検証内容 | ブロック動作 |
|------|---------------|----------|----------|--------------|
| 1 | prompt.sh | UserPromptSubmit | instruction 検出 | 指示（ブロックなし） |
| 2 | prompt-analyzer | playbook-init から呼出 | 5W1H分析、リスク、曖昧さ | なし（分析のみ） |
| 3 | understanding-check | playbook-init Step 2 | ユーザー理解確認 | ユーザー承認まで待機 |
| 4 | executor-resolver | pm から呼出 | executor アサイン | なし（解決のみ） |
| 5 | reviewer | pm Step 10 | 4QV+ 検証 | FAIL → 再レビュー（最大3回） |

### 1.2 Guard スクリプト

| Guard | ファイル | 発火条件 | 検証内容 | ブロック動作 |
|-------|----------|----------|----------|--------------|
| playbook-guard | `.claude/skills/playbook-gate/guards/playbook-guard.sh` | PreToolUse (Edit/Write) | playbook.active が null でないか | BLOCK: playbook なしで編集禁止 |
| init-guard | `.claude/skills/session-manager/handlers/init-guard.sh` | PreToolUse (Edit) | セッション初期化済みか | BLOCK: 未初期化時 |

### 1.3 SubAgent 検証

| SubAgent | ファイル | 検証内容 | 出力 |
|----------|----------|----------|------|
| reviewer | `.claude/skills/quality-assurance/agents/reviewer.md` | playbook の形式・内容・整合・完全・報酬詐欺チェック | PASS/FAIL + 修正案 |
| pm | `.claude/skills/golden-path/agents/pm.md` | playbook 作成、reviewer 呼出、state.md 更新 | plan.json + progress.json |

---

## 2. Phase/Subtask 完了時チェック

phase または subtask を done にする際に動作する検証機能。

### 2.1 Guard スクリプト

| Guard | ファイル | 発火条件 | 検証内容 | ブロック動作 |
|-------|----------|----------|----------|--------------|
| subtask-guard | `.claude/skills/reward-guard/guards/subtask-guard.sh` | progress.json 編集時 | subtask を done にする際に validations 全 PASS が必要、validated_by: critic が必須 | BLOCK: 検証なしで done 禁止 |
| critic-guard | `.claude/skills/reward-guard/guards/critic-guard.sh` | progress.json 編集時 | critic PASS なしで playbook 完了禁止 | BLOCK: critic なしで完了禁止 |
| phase-status-guard | `.claude/skills/reward-guard/guards/phase-status-guard.sh` | progress.json 編集時 | 依存 phase が完了しているか | BLOCK: 依存未完了で次 phase 禁止 |
| scope-guard | `.claude/skills/reward-guard/guards/scope-guard.sh` | Edit/Write 時 | scope.excludes に該当する変更でないか | WARN: スコープ外作業の警告 |
| depends-check | `.claude/skills/playbook-gate/guards/depends-check.sh` | phase 開始時 | depends_on の全 phase が done か | BLOCK: 依存未完了 |
| completion-check | `.claude/skills/reward-guard/guards/completion-check.sh` | Stop Hook | playbook 完了時の最終検証 | INFO: 未完了 subtask の警告 |
| pending-guard | `.claude/skills/post-loop/guards/pending-guard.sh` | Edit/Write 時 | post-loop 待ちでないか | BLOCK: 完了後の追加作業禁止 |

### 2.2 SubAgent 検証

| SubAgent | ファイル | 発火条件 | 検証内容 | 出力 |
|----------|----------|----------|----------|------|
| critic | `.claude/skills/reward-guard/agents/critic.md` | subtask/phase 完了前 | done_criteria の証拠ベース検証、報酬詐欺チェック | PASS/FAIL + evidence |
| reviewer | `.claude/skills/quality-assurance/agents/reviewer.md` | p_final phase | done_when 項目の独立検証 | PASS/FAIL + 修正案 |

### 2.3 検証フレームワーク

| フレームワーク | ファイル | 用途 |
|---------------|----------|------|
| done-criteria-validation | `.claude/frameworks/done-criteria-validation.md` | done_criteria 検証の手順と基準 |
| playbook-review-criteria | `.claude/frameworks/playbook-review-criteria.md` | 4QV+ レビュー基準（形式/内容/整合/完全/詐欺） |
| playbook-reviewer-spec | `.claude/frameworks/playbook-reviewer-spec.md` | reviewer の動作仕様 |

---

## 3. Project 生成時チェック（現状）

project を作成する際に動作する検証機能。

### 3.1 現状のフロー

```
pm SubAgent → project.json 作成 → (reviewer チェックなし) → state.md 更新
```

| 順序 | コンポーネント | 発火条件 | 検証内容 | ブロック動作 |
|------|---------------|----------|----------|--------------|
| 1 | pm | Task(pm) | project.json 作成 | なし |
| 2 | - | - | **reviewer チェックなし** | **なし（Gap）** |
| 3 | state.md 更新 | pm 内部 | project.active 設定 | なし |

### 3.2 検出された Gap

| 項目 | Playbook 生成時 | Project 生成時 | 状態 |
|------|----------------|----------------|------|
| reviewer チェック | ✅ pm Step 10 | ❌ なし | **Gap** |
| meta.reviewed フィールド | ✅ plan.json | ❌ project.json にない | **Gap** |
| meta.reviewed_by フィールド | ✅ plan.json | ❌ project.json にない | **Gap** |
| critic 検証 | ✅ subtask 完了時 | ❓ milestone 完了時は未定義 | **要調査** |

---

## 4. Hook レイヤー（Event Unit）

10 個の Hook Unit が存在し、それぞれ chain.sh を通じて Guard/Handler を呼び出す。

| Hook Unit | ファイル | 発火タイミング | 主な役割 |
|-----------|----------|---------------|----------|
| session-start | `.claude/events/session-start/chain.sh` | セッション開始時 | health/integrity チェック |
| user-prompt-submit | `.claude/events/user-prompt-submit/chain.sh` | ユーザー入力時 | instruction 検出、State Injection |
| pre-tool-edit | `.claude/events/pre-tool-edit/chain.sh` | Edit/Write 前 | playbook-guard, subtask-guard 等 |
| pre-tool-bash | `.claude/events/pre-tool-bash/chain.sh` | Bash 前 | bash-check, coherence |
| post-tool-edit | `.claude/events/post-tool-edit/chain.sh` | Edit/Write 後 | progress-reminder, archive |
| subagent-stop | `.claude/events/subagent-stop/chain.sh` | SubAgent 終了時 | archive-playbook |
| pre-compact | `.claude/events/pre-compact/chain.sh` | コンパクト前 | 状態保存 |
| stop | `.claude/events/stop/chain.sh` | セッション終了前 | completion-check |
| session-end | `.claude/events/session-end/chain.sh` | セッション終了時 | end handler |
| notification | `.claude/events/notification/chain.sh` | 通知時 | no-op |

---

## 5. Access Control

編集制限とセキュリティ関連のチェック機能。

| Guard | ファイル | 発火条件 | 検証内容 | ブロック動作 |
|-------|----------|----------|----------|--------------|
| main-branch | `.claude/skills/access-control/guards/main-branch.sh` | Edit/Write 時 | main ブランチでないか | BLOCK: main ブランチでの編集禁止 |
| protected-edit | `.claude/skills/access-control/guards/protected-edit.sh` | Edit/Write 時 | protected-files.txt に該当しないか | BLOCK: 保護ファイルの編集禁止 |
| bash-check | `.claude/skills/access-control/guards/bash-check.sh` | Bash 時 | 危険なコマンドでないか | WARN/BLOCK: 危険操作の警告/禁止 |

---

## 6. Executor Orchestration

executor（claudecode/codex/coderabbit/user）の割り当てと委譲。

| コンポーネント | ファイル | 役割 |
|---------------|----------|------|
| executor-resolver | `.claude/skills/executor-resolver/SKILL.md` | subtask の executor を toolstack に応じて解決 |
| executor-guard | `.claude/skills/playbook-gate/guards/executor-guard.sh` | executor が自分でない subtask への作業をブロック |
| codex-delegate | `.claude/agents/codex-delegate.md` | codex への委譲 |
| coderabbit-delegate | `.claude/agents/coderabbit-delegate.md` | coderabbit への委譲 |

---

## 7. 検証機能の発火タイミングサマリー

```
セッション開始
    │
    ├─ [session-start] health.sh, integrity.sh
    │
ユーザー入力
    │
    ├─ [user-prompt-submit] prompt.sh → State Injection
    │
    ├─ instruction 検出時
    │   ├─ prompt-analyzer (5W1H, リスク, 曖昧さ)
    │   ├─ understanding-check (ユーザー確認)
    │   ├─ pm (playbook 作成)
    │   │   ├─ executor-resolver
    │   │   └─ reviewer (4QV+ 検証) ← PASS 必須
    │   └─ state.md 更新
    │
ツール使用（Edit/Write）
    │
    ├─ [pre-tool-edit]
    │   ├─ init-guard (セッション初期化)
    │   ├─ main-branch (main 禁止)
    │   ├─ playbook-guard (playbook 必須)
    │   ├─ protected-edit (保護ファイル)
    │   ├─ depends-check (依存確認)
    │   ├─ executor-guard (executor 確認)
    │   ├─ subtask-guard (done 検証)
    │   ├─ phase-status-guard (phase 検証)
    │   ├─ scope-guard (スコープ確認)
    │   └─ critic-guard (critic PASS 必須)
    │
    ├─ [post-tool-edit]
    │   └─ progress-reminder, archive-playbook
    │
Subtask 完了
    │
    ├─ critic (証拠ベース検証) ← PASS 必須
    │
Phase 完了
    │
    ├─ 依存 phase 確認
    │
Playbook 完了
    │
    ├─ [p_final] reviewer (独立検証)
    ├─ critic (最終検証)
    │
    ├─ [stop] completion-check
    │
セッション終了
    │
    └─ [session-end] end.sh
```

---

## 8. 報酬詐欺防止メカニズム

### 8.1 直接防止

| メカニズム | 説明 | 実装 |
|-----------|------|------|
| subtask-guard | validations 全 PASS + validated_by: critic なしで done 禁止 | `.claude/skills/reward-guard/guards/subtask-guard.sh` |
| critic-guard | critic PASS なしで playbook 完了禁止 | `.claude/skills/reward-guard/guards/critic-guard.sh` |
| reviewer 4QV+ | 報酬詐欺チェック項目含む | `.claude/frameworks/playbook-review-criteria.md` |

### 8.2 間接防止

| メカニズム | 説明 | 実装 |
|-----------|------|------|
| scope-guard | scope.excludes への作業を警告 | `.claude/skills/reward-guard/guards/scope-guard.sh` |
| depends-check | 依存未完了での次 phase 開始を禁止 | `.claude/skills/playbook-gate/guards/depends-check.sh` |
| executor-guard | 担当外 subtask への作業を禁止 | `.claude/skills/playbook-gate/guards/executor-guard.sh` |

---

## 9. 結論

### 実装済み（Playbook レベル）
- ✅ prompt-analyzer による分析
- ✅ understanding-check によるユーザー確認
- ✅ reviewer による 4QV+ 検証
- ✅ critic による done_criteria 検証
- ✅ subtask-guard による done 検証
- ✅ playbook-guard による playbook 必須チェック

### 未実装（Project レベル）
- ❌ project.json の reviewer チェック
- ❌ meta.reviewed / meta.reviewed_by フィールド
- ❌ milestone 完了時の critic 検証

### 次のアクション
p2 で Gap を詳細分析し、p3 で不足機能を実装する。
