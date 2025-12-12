# project.md

> **Hook システム健全性検証プロジェクト**
> **playbook はこのファイルを参照して作成する。**

## meta

```yaml
project: hook-system-health-check
created: 2025-12-12
type: automation
location: .claude/hooks/
```

## vision

### ユーザーの意図

> 本リポジトリの最も重要な本質的機能10個を特定し、設計通りに機能しているか
> 点検・改善・修正を行う。全ての機能がどんな状況でも確実に動作することを保証する。

### 成功の定義

- 10個の重要機能全てが「設計通りの機能」として明文化されている
- 各機能のテストが実行され、設計通りに動作することが確認されている
- 発見された問題が全て修正されている
- 回帰テストが整備され、将来の変更でも動作を保証できる

## stack

```yaml
framework: bash/shell
language: bash
deploy: local
database: none
external_apis: none
```

## constraints

- 既存の Hook 構造を維持する（破壊的変更は避ける）
- テストは自動化可能な形式で整備する
- 全ての修正は test-hooks.sh で検証可能であること

## done_when

```yaml
- id: DW-001
  name: 重要機能10個の設計定義
  status: achieved
  criteria:
    - 10機能の「設計通りの機能」が明文化されている

- id: DW-002
  name: session-start.sh 検証完了
  status: achieved
  priority: high
  criteria:
    - 設計通りの発火条件でテスト PASS
    - pending/consent ファイル作成が確認できる

- id: DW-003
  name: init-guard.sh 検証完了
  status: achieved
  priority: high
  criteria:
    - 必須ファイル未読時に Edit/Write がブロックされる
    - admin モードでバイパスされる

- id: DW-004
  name: playbook-guard.sh 検証完了
  status: achieved
  priority: high
  criteria:
    - playbook=null で Edit/Write がブロックされる
    - state.md への編集は許可される

- id: DW-005
  name: project-guard.sh 検証完了
  status: achieved
  priority: high
  criteria:
    - project.md 未存在で Edit/Write がブロックされる
    - 除外パス（plan/, .claude/hooks/）は許可される

- id: DW-006
  name: consent-guard.sh 検証完了
  status: achieved
  priority: high
  criteria:
    - consent ファイル存在時に Edit/Write がブロックされる
    - consent ファイル削除後は許可される

- id: DW-007
  name: check-protected-edit.sh 検証完了
  status: achieved
  priority: high
  criteria:
    - HARD_BLOCK ファイルが常にブロックされる
    - admin モードで HARD_BLOCK も解除される

- id: DW-008
  name: critic-guard.sh 検証完了
  status: achieved
  priority: high
  criteria:
    - state: done への変更が self_complete なしでブロックされる
    - self_complete: true 存在時は許可される

- id: DW-009
  name: prompt-guard.sh 検証完了
  status: achieved
  priority: high
  criteria:
    - user-intent.md にプロンプトが保存される
    - 新しい指示検出時に consent が再作成される

- id: DW-010
  name: check-main-branch.sh 検証完了
  status: achieved
  priority: high
  criteria:
    - focus=workspace かつ main で Edit がブロックされる
    - focus=setup/product では main でも許可される

- id: DW-011
  name: scope-guard.sh 検証完了
  status: achieved
  priority: high
  criteria:
    - done_criteria 変更検出時に警告が出る
    - STRICT_MODE=true でブロックされる
```

## decomposition

```yaml
DW-002:
  summary: session-start.sh 検証完了
  playbook_summary: セッション開始時の初期化機能を検証
  phase_hints:
    - name: 設計確認
      what: session-start.sh の設計意図を確認
    - name: テスト実行
      what: 発火条件を満たしてテスト
    - name: 問題修正
      what: 発見された問題を修正
  success_indicators:
    - pending ファイルが作成される
    - consent ファイルが適切に作成される
    - [自認] テンプレートが出力される

# 他の DW も同様のパターン
```

## milestones

- [x] 重要機能10個の特定と設計定義
- [x] 全10機能の検証完了
- [x] 発見された問題の修正完了
- [x] 回帰テスト整備

## notes

- 検証対象の10機能は全て PreToolUse または SessionStart で発火する Hook
- admin モードでの動作確認も必須
- 修正時は既存のテストフレームワーク（test-hooks.sh）を活用
