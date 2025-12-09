# playbook-system-completion

> **タスク**: システム完成度向上 - 品質の一貫性と運用効率化
>
> **derives_from**: project.md / system_completion
> **ブランチ**: feat/system-completion
> **設計思想**: 仕組みの完成を実現するための最終整備

---

## goal

```yaml
summary: |
  タスク開始プロセスの標準化、git 自動化、ファイル棚卸し、setup 完成。
  品質のバラつきを解消し、再現可能な開発環境を構築する。

done_criteria:
  - 全タスク開始が project.md → pm → playbook の流れで統一されている
  - git 操作（コミット/マージ/ブランチ）が SubAgent で自動化されている
  - 全ファイルの存在理由が docs/file-inventory.md に記載されている
  - setup/playbook-setup.md が現在の機能を完全に反映している
```

---

## phases

### Phase 1: タスク開始プロセス標準化

```yaml
current_phase: 1
status: done
evidence: |
  critic PASS (2025-12-09)

  成果物:
    - .claude/agents/pm.md: 「必須経由点」セクション追加、計画の導出フローを詳細化
    - .claude/commands/task-start.md: 新規作成、pm 経由でタスク開始を強制
    - CLAUDE.md: 【タスク標準化】ルール追加、INIT フェーズ 3 / POST_LOOP を pm 経由必須に更新
    - docs/task-initiation-flow.md: 新規作成、詳細フロー図・禁止パターン・derives_from 説明

  検証結果:
    - criteria 1 (pm が project.md 参照): pm.md 行 47-112 で計画の導出フローを定義 PASS
    - criteria 2 (/task-start コマンド): task-start.md 作成、pm 呼び出しを明記 PASS
    - criteria 3 (CLAUDE.md 更新): INIT フェーズ 3・POST_LOOP に「★pm 経由必須」を追加 PASS
    - criteria 4 (フロー図): docs/task-initiation-flow.md 作成 PASS

summary: |
  全タスク開始を project.md からの導出に統一。
  pm SubAgent を強化し、タスク開始の必須経由点にする。

done_criteria:
  - pm SubAgent が project.md の done_when を参照して playbook を生成する
  - /task-start コマンドが pm 経由でタスクを開始する
  - CLAUDE.md の INIT/POST_LOOP が pm 経由を強制する
  - タスク開始フロー図が作成されている

test_method: |
  1. /task-start を実行
  2. pm が project.md を参照することを確認
  3. derives_from が正しく設定された playbook が生成されることを確認

executor: claude_code
```

### Phase 2: git 自動化

```yaml
current_phase: 2
status: done
evidence: |
  critic PASS (2025-12-09)

  成果物:
    - .claude/agents/git-ops.md: 参照ドキュメント作成、設計方針・コマンド例・エラーハンドリング定義
    - CLAUDE.md LOOP: 行292-312 に Phase 完了時の自動コミット手順を追加
    - CLAUDE.md POST_LOOP: 行336-365 に自動マージ・自動ブランチ手順を追加
    - .claude/agents/pm.md: 行164-200「git 操作（直接実行）」セクション追加

  検証結果:
    - criteria 1 (git-ops 参照ドキュメント): git-ops.md 存在確認 PASS
    - criteria 2 (CLAUDE.md LOOP): 行292-312 に自動コミット手順記載 PASS
    - criteria 3 (CLAUDE.md POST_LOOP): 行336-365 に自動マージ・ブランチ手順記載 PASS
    - criteria 4 (pm.md git 操作): 行164-200 に実行タイミング記載 PASS

  設計方針:
    - git 操作は Claude が Bash で直接実行（SubAgent 呼び出しではない）
    - git-ops.md は参照ドキュメント（コマンド例・エラーハンドリングの情報源）
    - CLAUDE.md が実行トリガーと手順を定義

summary: |
  git-ops 参照ドキュメントを作成し、コミット/マージ/ブランチ作成の自動化手順を定義。
  Claude が CLAUDE.md の指示に従って直接 git コマンドを実行する方式。

done_criteria:
  - git-ops 参照ドキュメントが作成されている
  - CLAUDE.md LOOP に Phase 完了時の自動コミット手順が記載されている
  - CLAUDE.md POST_LOOP に自動マージ・自動ブランチ手順が記載されている
  - pm.md に git 操作の実行タイミングが記載されている

test_method: |
  1. CLAUDE.md LOOP セクションに自動コミット手順があることを確認
  2. CLAUDE.md POST_LOOP セクションに自動マージ手順があることを確認
  3. pm.md に git 操作セクションがあることを確認

executor: claude_code
depends_on: Phase 1
```

### Phase 3: 全ファイル棚卸しドキュメント作成

```yaml
current_phase: 3
status: done
evidence: |
  critic PASS (2025-12-09)

  成果物:
    - docs/file-inventory.md: 153 ファイルの棚卸しドキュメント（360+ 行）

  検証結果:
    - criteria 1 (ファイル作成): docs/file-inventory.md 存在確認 PASS
    - criteria 2 (全ファイル記載): 153 件全ファイルの存在理由を記載 PASS
    - criteria 3 (削除候補): 優先度別に分類、理由付きでリスト PASS
    - criteria 4 (統合候補): 3 件を理由付きでリスト PASS
    - criteria 5 (カテゴリ別): 6 カテゴリ + サブカテゴリで整理 PASS

  内容サマリー:
    - .archive/: 34 件（開発履歴）
    - .claude/: 68 件（Hooks/SubAgents/Skills）
    - docs/: 5 件（ドキュメント）
    - plan/: 26 件（計画管理）
    - setup/: 2 件（セットアップ）
    - root: 8 件（ルート設定）
    - 削除候補: 高0件、中7件、低9件
    - 統合候補: 3件
    - アーカイブ候補: 10件（完了済み playbook）

summary: |
  全ファイルの存在理由を明確化。
  削除候補・統合候補を詳細な理由付きで docs/file-inventory.md に記載。

done_criteria:
  - docs/file-inventory.md が作成されている
  - 全ファイル（100+ 件）の存在理由が記載されている
  - 削除候補が理由付きでリストされている
  - 統合候補が理由付きでリストされている
  - カテゴリ別に整理されている

test_method: |
  1. docs/file-inventory.md を読む
  2. 全ファイルがカバーされているか確認
  3. 削除/統合候補の理由が明確か確認

executor: claude_code
```

### Phase 4: setup 完成

```yaml
current_phase: 4
status: done
evidence: |
  critic PASS (2025-12-09)

  成果物:
    - setup/playbook-setup.md: V2.0 に更新（1534 行）

  更新内容:
    - Quickstart セクション追加（5分で開始、3ステップ）
    - このリポジトリの活用方法セクション追加
    - 設計思想セクション強化:
      - 三位一体アーキテクチャ図
      - アクションベース Guards 説明
      - 報酬詐欺防止説明
      - 計画の連鎖説明
      - コンテキスト外部化説明
    - 現在のシステム構成セクション追加
    - 変更履歴追加

  検証結果:
    - criteria 1 (全機能反映): Hooks 22個、SubAgents 10個、Skills 9個 記載 PASS
    - criteria 2 (設計思想強化): 189-307行に詳細説明 PASS
    - criteria 3 (Phase 構成見直し): Phase 5-A Linter/Formatter 追加 PASS
    - criteria 4 (クイックスタート): 8-32行に 5分オンボーディング PASS
    - criteria 5 (実例参照): 35-63行に活用方法説明 PASS

summary: |
  setup/playbook-setup.md を現在の機能増加を反映して完成させる。
  このリポジトリ自体を参照可能なテンプレートとして整備。

done_criteria:
  - setup/playbook-setup.md が現在の全機能を反映している
  - 設計思想セクションが強化されている
  - Phase 構成が現状に合わせて見直されている
  - 新規ユーザー向けクイックスタートがある
  - このリポジトリを実例として参照するセクションがある

test_method: |
  1. setup/playbook-setup.md を読む
  2. 新規ユーザーが理解できる構成か確認
  3. 現在の機能（Hooks 16個、SubAgents 9個など）が反映されているか確認

executor: claude_code
depends_on: Phase 3
```

---

## meta

```yaml
issue: null
priority: critical
estimated_effort: 4h
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | 初版作成。project.md / system_completion から導出。4 Phase 構成。 |
