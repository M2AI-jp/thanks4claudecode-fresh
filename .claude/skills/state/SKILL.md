---
name: state
description: このワークスペースの state.md 管理、playbook 運用、レイヤー構造の専門知識。state.md の更新、focus の切り替え、done_criteria の判定、CRITIQUE の実行時に使用する。
---

# Workspace Management Skill

このワークスペース固有の管理知識を提供します。

## state.md の構造

```yaml
# 必須セクション
focus:
  current: <layer>           # 現在のフォーカスレイヤー
  session: task | discussion # セッションタイプ

goal:
  phase: <phase-id>          # 現在のフェーズ
  done_criteria:             # 達成条件（テストとして扱う）
    - criteria1
    - criteria2

# レイヤー定義（4つ）
layer: plan-template         # playbook テンプレートの改善
layer: workspace             # ワークスペース自体の改善
layer: setup                 # Mac 開発環境標準化
layer: product               # ユーザーのプロダクト開発
```

## レイヤーの編集権限

| focus.current | 編集可能な範囲 |
|---------------|---------------|
| plan-template | plan/template/**, plan/playbook-* |
| workspace | .claude/**, CLAUDE.md, AGENTS.md, plan/** |
| setup | setup/** |
| product | projects/**, 実装コード |

**常に編集可能**: state.md, README.md

## session の違い

| session | 特徴 |
|---------|------|
| task | state.md 更新必須、commit 前チェック有効 |
| discussion | 自由な議論、チェック無効 |

## CRITIQUE の実行方法

done と判定する前に必ず実行:

```
[CRITIQUE]
done_criteria 達成の証拠:
  - {criteria}: {PASS|FAIL} - {具体的な証拠}
playbook 自体の妥当性: {問題なし|修正が必要}
成果物の動作確認: {確認済み|未確認}
判定: {PASS|FAIL}
```

## state.md 更新のルール

1. task セッションでは commit 前に state.md を更新する
2. done_criteria を満たしたら sub を更新する
3. Phase 完了時は state を次の状態に遷移させる

## 状態遷移

```
pending → designing → implementing → reviewing → state_update → done
```

禁止遷移:
- pending → implementing（designing をスキップ）
- implementing → done（state_update をスキップ）

---

## playbook 必須ルール

```yaml
条件:
  session: task
  playbook: null

対応:
  1. 作業開始禁止
  2. まず playbook を作成

手順:
  1. plan/template/playbook-format.md を読む
  2. ユーザーにヒアリング:
     - 何を作るか（ゴール）
     - 完了条件は何か（done_criteria）
     - フェーズ分割
  3. plan/playbook-{name}.md を作成
  4. state.md の playbook: を更新
  5. 作業開始

なぜ必須か:
  - playbook なし = done_criteria なし = 完了判定不可能
  - 「計画なしで作業 → 自己報酬詐欺」の防止
```

## playbook 作成テンプレート

```yaml
# plan/playbook-{name}.md

## meta
project: {プロジェクト名}
created: {今日の日付}

## goal
summary: {1行の目標}
done_when:
  - {最終完了条件1}
  - {最終完了条件2}

## phases
- id: p1
  name: {フェーズ名}
  goal: {このフェーズの目標}
  executor: codex
  done_criteria:
    - {完了条件1}
    - {完了条件2}
  status: pending
```
