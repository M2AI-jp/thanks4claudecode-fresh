# playbook-system-foundation-redesign.md

> **システム基盤再設計 - 技術的負債解消とエコシステム確立**

---

## meta

```yaml
project: system-foundation-redesign
branch: feat/system-foundation-redesign
created: 2025-12-10
issue: null
derives_from: ユーザー要求（コンテキスト管理・plan粒度・state機能整理）
```

---

## goal

```yaml
summary: 変遷で生じた技術的負債を解消し、機能間エコシステムを確立する
done_when:
  - project.md がチェックボックス式・細粒度・担当割り当て形式になっている
  - state.md が機能単位で整理され、形骸化セクションがない
  - current-implementation.md にドキュメント依存が追記されている
  - 全ファイルが適切なサイズに収まっている
  - critic PASS
```

---

## phases

```yaml
- id: p1
  name: project.md 書き直し
  goal: チェックボックス式・細粒度・担当割り当て形式に変換
  executor: claudecode
  tasks:
    - [ ] 現在の project.md を分析（claudecode）
    - [ ] 新フォーマット設計（claudecode）
    - [ ] project.md 全体書き換え（claudecode）
    - [ ] 200行以下に収める（claudecode）
  done_criteria:
    - チェックボックス式タスク管理
    - 細粒度（p1〜p5 ではなく個別タスク単位）
    - 各タスクに担当者（claudecode/user/codex）
    - 200行以下
  test_method: |
    1. wc -l plan/project.md で 200行以下を確認
    2. チェックボックス形式を目視確認
  status: done

- id: p2
  name: state.md 再設計
  goal: 機能単位で整理し、形骸化セクションを削除
  executor: claudecode
  depends_on: [p1]
  tasks:
    - [ ] 現在の state.md を機能分析（claudecode）
    - [ ] 必要な機能を特定（claudecode）
    - [ ] 不要セクション削除リスト作成（claudecode）
    - [ ] state.md 全体書き換え（claudecode）
    - [ ] 100行以下に収める（claudecode）
  done_criteria:
    - focus/playbook/goal のみ残す
    - learning_mode は簡潔に（5行以下）
    - layer 個別定義を統合
    - 100行以下
  test_method: |
    1. wc -l state.md で 100行以下を確認
    2. 形骸化セクションがないことを目視確認
  status: done

- id: p3
  name: current-implementation.md 更新
  goal: ドキュメント（参照コンテキスト）との依存を追記
  executor: claudecode
  depends_on: [p2]
  tasks:
    - [ ] 現在の依存関係図を確認（claudecode）
    - [ ] ドキュメント依存を分析（claudecode）
    - [ ] セクション7に追記（claudecode）
  done_criteria:
    - Hooks/SubAgents/Skills/ドキュメント間の依存が明記
    - 参照コンテキストの流れが可視化
  test_method: |
    1. セクション7にドキュメント依存が記載されていることを確認
  status: done

- id: p4
  name: 最終検証
  goal: 全変更が正常に機能することを確認
  executor: claudecode
  depends_on: [p1, p2, p3]
  tasks:
    - [ ] 各ファイルサイズ確認（claudecode）
    - [ ] エコシステム動作確認（claudecode）
    - [ ] critic 実行（claudecode）
  done_criteria:
    - project.md 200行以下
    - state.md 100行以下
    - エコシステム正常動作
    - critic PASS
  test_method: |
    1. wc -l で各ファイルサイズ確認
    2. Task(subagent_type="critic") で検証
  status: done
```

---

## evidence

```yaml
p1: |
  - project.md: 880行 → 144行（84%削減）
  - チェックボックス式タスク管理実装
  - 細粒度（個別タスク単位）
  - 担当者割り当て（cc/user/codex）

p2: |
  - state.md: 271行 → 78行（71%削減）
  - 形骸化セクション削除（layer個別定義、states、rules、plan_hierarchy等）
  - 機能単位整理（focus、playbook、goal、verification、session、config、参照）

p3: |
  - current-implementation.md セクション7更新
  - 7.2: ドキュメント依存（参照コンテキスト）追加
  - 7.3: 依存マトリクス追加
  - Hooks/SubAgents/Skills/ドキュメント間依存可視化

p4: |
  - project.md: 144行 ✓（目標200行以下）
  - state.md: 79行 ✓（目標100行以下）
  - エコシステム動作確認:
    - session-start.sh: pending/consent ファイル作成確認
    - Hooks: 19個
    - SubAgents: 7個
    - Skills: 13個
    - 親ディレクトリ CLAUDE.md: 6個
  - critic: PASS
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-10 | 初版作成。システム基盤再設計 playbook。 |
