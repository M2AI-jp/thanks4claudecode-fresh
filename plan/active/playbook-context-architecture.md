# playbook-context-architecture.md

> **コンテキスト・アーキテクチャ再設計 - リポジトリ完成形**
>
> コンテキストを「機能」として管理し、散逸を防ぎ、適切な配置に再構成する

---

## meta

```yaml
project: context-architecture
branch: feat/context-architecture
created: 2025-12-10
issue: null
derives_from: null  # リポジトリ完成タスク
```

---

## goal

```yaml
summary: コンテキストを機能として管理し、このリポジトリの完成形を実現する
done_when:
  - コンテキストが機能別に適切に配置されている
  - 全機能が維持されている（削減ではない）
  - 必要な時に必要なコンテキストが参照される設計になっている
  - project.md が完成形として整備されている
  - critic PASS
```

---

## background

```yaml
問題認識:
  1. CLAUDE.md (23.5KB) が毎回全部読まれる
     - 一部は「必要時参照」で十分な機能
  2. state.md に履歴が混在（想定外）
     - 「現在地」と「履歴」は別機能として分離すべき
  3. docs/ の役割が曖昧
     - 機能別に構造化すべき
  4. project.md の achieved セクションも毎回読まれる
     - 構造の最適化が必要

設計原則:
  - 「削減」ではなく「適切な配置」
  - 全機能は担保される
  - 機能不全があれば修正する

公式仕様の活用:
  - ファイル参照時に親ディレクトリの CLAUDE.md が自動的にコンテキストに追加される
  - .claude/ 配下にフォルダ階層を作り、各フォルダに CLAUDE.md を置く
  - 必要な時に必要なコンテキストだけが読まれる設計が可能
```

---

## phases

```yaml
- id: p1
  name: state.md 機能分離
  goal: 「現在地」と「履歴」を別機能として分離
  executor: claudecode
  done_criteria:
    - state.md が「現在地」機能に特化している
    - .claude/context/history.md に履歴が移動している
    - 両機能とも正常に動作している
    - state.md の役割が明確に定義されている
  test_method: |
    1. state.md を読み、履歴セクションがないことを確認
    2. .claude/context/history.md を読み、履歴が保存されていることを確認
    3. state.md のサイズが適切になっていることを確認
  status: done

- id: p2
  name: CLAUDE.md 機能分離
  goal: 毎回必要な指示と特定状況向け指示を分離
  executor: claudecode
  depends_on: [p1]
  done_criteria:
    - CLAUDE.md が「毎回必要な指示」に特化している
    - 特定状況向け指示が Skill 化されている
    - 全機能が維持されている（参照方法が変わるだけ）
    - @参照または Skill 呼び出しで元の機能にアクセス可能
  test_method: |
    1. CLAUDE.md を読み、INIT/CORE/LOOP/POST_LOOP が残っていることを確認
    2. Skill 化された機能が .claude/skills/ に存在することを確認
    3. 各 Skill の frontmatter に適切な triggers があることを確認
  status: pending

- id: p3
  name: .claude/ フォルダ構造化
  goal: 各フォルダに CLAUDE.md を配置し、参照時に自動コンテキスト提供
  executor: claudecode
  depends_on: [p2]
  done_criteria:
    - .claude/agents/CLAUDE.md が存在する
    - .claude/skills/CLAUDE.md が存在する
    - .claude/hooks/CLAUDE.md が存在する
    - .claude/context/CLAUDE.md が存在する
    - .claude/frameworks/CLAUDE.md が存在する
    - 各 CLAUDE.md がそのフォルダの役割を説明している
  test_method: |
    1. ls .claude/*/CLAUDE.md で各フォルダに CLAUDE.md があることを確認
    2. 各 CLAUDE.md の内容がフォルダの役割を説明していることを確認
  status: pending

- id: p4
  name: docs/ 構造化
  goal: 機能別に整理し、役割を明確化
  executor: claudecode
  depends_on: [p3]
  done_criteria:
    - docs/CLAUDE.md が存在する
    - docs/ の各ファイルの役割が明確になっている
    - 開発履歴系ドキュメントが適切に整理されている
    - 削減ではなく構造化されている
  test_method: |
    1. docs/CLAUDE.md を読み、フォルダの役割が説明されていることを確認
    2. ls docs/ で構造を確認
  status: pending

- id: p5
  name: project.md 再編集
  goal: 完成形としての整備、アーキテクチャを正確に反映
  executor: claudecode
  depends_on: [p4]
  done_criteria:
    - project.md が現在のアーキテクチャを正確に反映している
    - achieved セクションの構造が最適化されている
    - 「完成形」としての体裁が整っている
    - 冗長な記述が整理されている（削除ではなく整理）
  test_method: |
    1. project.md を読み、現在のアーキテクチャと一致することを確認
    2. 各セクションの役割が明確であることを確認
  status: pending

- id: p6
  name: 機能検証
  goal: 全機能が正常に動作することを確認
  executor: claudecode
  depends_on: [p1, p2, p3, p4, p5]
  done_criteria:
    - 全機能が正常に動作している
    - Skill 化した機能が正しく参照される
    - Hook が正常に発火する
    - SubAgent が正常に呼び出される
    - critic PASS
  test_method: |
    1. git commit テストで Hook 発火を確認
    2. Task(subagent_type="critic") で critic を呼び出し
    3. 各 Skill が呼び出し可能であることを確認
    4. critic PASS を取得
  status: pending
```

---

## evidence

```yaml
p1: |
  - state.md: 321行 → 274行（履歴60行を分離）
  - .claude/context/history.md: 70行（履歴保存先として作成）
  - state.md ヘッダーに役割を明記（「現在地」機能）
  - 参照: `.claude/context/history.md` への参照を追加
p2: null
p3: null
p4: null
p5: null
p6: null
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-10 | 初版作成。コンテキスト・アーキテクチャ再設計 playbook。 |
