# 計画の連鎖的導出システム - 設計ドキュメント

> **project.done_when → playbook → phase の自動導出を実現する**

---

## 1. 問題の定義

### 現状

```
Vision
  ↓ (手動)
Project.done_when
  ↓ (???) ← 仕組みがない
Playbook
  ↓ (手動)
Phase
  ↓ (Claude が実行)
Action
```

LLM は project.md を読んでも「具体的に何をすればいいか」がわからない。
done_when の定義があっても、そこから playbook を導出する仕組みがない。

### 目標

```
Project.done_when
  │
  ├─ decomposition（分解指針）
  │
  ↓ pm が導出を支援
  │
Playbook
  │
  ├─ derives_from（project との紐付け）
  │
  ↓ Claude が phases を展開
  │
Phase
```

---

## 2. decomposition 構造

### 定義

`decomposition` は project.done_when の各項目に付与される「分解指針」。
LLM が playbook を作成する際の具体的なヒントを提供する。

### フィールド

```yaml
decomposition:
  # 必須フィールド
  playbook_summary: string
    # この done_when を達成するための playbook の一言説明
    # 例: "setup フローの検証と改善"

  phase_hints: list
    # playbook の phases を構成するためのヒント
    # 各項目は { name, what, why? } の構造
    - name: string      # Phase 名
      what: string      # 何をするか
      why: string?      # なぜ必要か（オプション）

  success_indicators: list
    # playbook.done_when に変換される成功条件
    # 具体的で検証可能な条件を列挙
    - string

  # オプションフィールド
  depends_on: list
    # 先に達成すべき他の done_when の ID
    # 依存関係がない場合は空リスト
    - string

  estimated_effort: string?
    # 想定工数（参考情報）
    # 例: "1-2 sessions", "3-5 phases"

  risks: list?
    # 想定されるリスク
    - string
```

### 例

```yaml
# project.md の done_when 例
not_achieved:
  フォーク即使用:
    id: DW-001
    definition: 新規ユーザーがフォーク後、30分以内に最初の playbook を作成できる
    priority: high

    decomposition:
      playbook_summary: setup フローの検証と改善

      phase_hints:
        - name: 現状分析
          what: setup/playbook-setup.md を読み、構造を理解する
        - name: 環境準備
          what: 新規ユーザーと同じ初期状態を作る
          why: 実際のユーザー体験を再現するため
        - name: 実走テスト
          what: setup を Phase 0 から実行し、問題を記録
        - name: 問題修正
          what: 発見した問題を修正
        - name: 再検証
          what: 修正後に再度実走し、完了を確認

      success_indicators:
        - setup が Phase 8 まで完了する
        - 30分以内に完了する
        - 致命的なエラーがない
        - 最初の playbook が作成できる

      depends_on: []
      estimated_effort: "2-3 sessions"
```

---

## 3. 導出フロー

### 全体フロー図

```
┌─────────────────────────────────────────────────────────────────┐
│                      セッション開始                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  INIT: project.md を Read                                       │
│  → not_achieved の一覧を取得                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  依存解決: depends_on を分析                                     │
│  → 着手可能な done_when を特定                                   │
│  → 優先度（priority）で並び替え                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  pm 呼び出し（または自己判断）                                   │
│  → 「次に着手すべき done_when」を決定                            │
│  → decomposition を読み込み                                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  playbook 生成                                                   │
│  1. derives_from: project.done_when[i].id を設定                │
│  2. goal.summary: decomposition.playbook_summary を使用         │
│  3. goal.done_when: decomposition.success_indicators を変換     │
│  4. phases: decomposition.phase_hints を展開                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  phases の詳細化                                                 │
│  → 各 phase_hint を Phase に変換                                │
│  → done_criteria を具体化                                       │
│  → test_method を追加                                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  作業開始 → LOOP                                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  playbook 完了                                                   │
│  → project.done_when[i].status を achieved に更新               │
│  → 次の done_when へ（依存解決から繰り返し）                     │
└─────────────────────────────────────────────────────────────────┘
```

### 詳細ステップ

#### Step 1: project.md の読み込み

```yaml
読み込む情報:
  - not_achieved セクション
  - 各 done_when の id, priority, depends_on
  - 各 done_when の decomposition

出力:
  - 着手可能な done_when のリスト（depends_on が全て achieved）
  - 優先度順にソート
```

#### Step 2: 着手対象の決定

```yaml
判断基準:
  1. depends_on が全て achieved である
  2. priority が高い
  3. estimated_effort が現在のコンテキストに適切

出力:
  - 次に着手する done_when
  - その decomposition
```

#### Step 3: playbook 生成

```yaml
入力:
  - done_when.id
  - done_when.definition
  - decomposition

変換ルール:
  meta.derives_from: done_when.id
  goal.summary: decomposition.playbook_summary
  goal.done_when: decomposition.success_indicators
  phases: decomposition.phase_hints を展開

phases 展開ルール:
  phase_hints[i] → Phase として:
    id: p{i}
    name: phase_hints[i].name
    goal: phase_hints[i].what
    done_criteria: # Claude が具体化
    test_method: # Claude が具体化
    status: pending
```

#### Step 4: playbook 完了後の更新

```yaml
更新対象:
  - project.md: done_when[i].status → achieved
  - state.md: active_playbooks.{layer} → 次の playbook または null
  - playbook: .archive/plan/ に退避

次のアクション:
  - 依存解決から繰り返し
  - 全て achieved なら完了報告
```

---

## 4. pm SubAgent の拡張役割

### 現在の役割（維持）

```yaml
スコープ管理:
  - done_criteria/done_when の無断変更を検出
  - スコープクリープの警告
  - 計画外の作業を防止
```

### 新規追加役割

```yaml
計画の導出:
  trigger:
    - playbook=null でセッション開始
    - 現在の playbook が完了
    - ユーザーが「次は何をする？」と聞いた

  action:
    1. project.md の not_achieved を読み込み
    2. depends_on を分析し、着手可能なものを特定
    3. priority で並び替え
    4. 推奨する done_when を提案
    5. decomposition を参考に playbook skeleton を生成

優先度判断:
  trigger:
    - 複数の done_when が着手可能
    - ユーザーが優先度を聞いた

  action:
    1. priority フィールドを確認
    2. depends_on のグラフを分析
    3. クリティカルパスを特定
    4. 推奨順序を提案

依存解決:
  trigger:
    - playbook 作成時
    - 計画の見直し時

  action:
    1. depends_on を再帰的に解決
    2. 循環依存を検出
    3. 着手可能なものをリストアップ
```

### pm の呼び出しタイミング

```yaml
自動呼び出し（推奨）:
  - セッション開始時、playbook=null の場合
  - playbook 完了後、次のタスク決定時

手動呼び出し:
  - Task(subagent_type='pm', prompt='次に何をすべきか提案して')
  - Task(subagent_type='pm', prompt='この done_when の playbook を作成して')
```

---

## 5. playbook テンプレートの拡張

### 新規フィールド

```yaml
## meta

meta:
  project: {プロジェクト名}
  branch: {ブランチ名}
  created: {日付}
  issue: {Issue 番号 or null}

  # 新規追加
  derives_from: {project.done_when[i].id}
    # この playbook が対応する project.done_when の ID
    # 例: DW-001
```

### 導出ガイド（テンプレートに追加）

```markdown
## playbook 作成時の手順

1. project.md の not_achieved を確認
2. 着手する done_when を決定
3. decomposition を読み込み
4. 以下を変換:
   - derives_from: done_when.id
   - goal.summary: decomposition.playbook_summary
   - goal.done_when: decomposition.success_indicators
   - phases: decomposition.phase_hints を展開
5. phases の done_criteria と test_method を具体化
```

---

## 6. CLAUDE.md への追加ルール

### INIT フローへの追加

```yaml
【フェーズ 5: Macro チェック & 計画の導出】

  9. plan/project.md の存在を確認
  10. playbook=null の場合:
      a. project.md の not_achieved を読み込み
      b. depends_on を分析、着手可能な done_when を特定
      c. priority で並び替え
      d. 「次に着手すべき: {done_when.name}」を宣言
      e. decomposition を参照して playbook を作成
      f. または pm を呼び出して提案を受ける
  11. playbook がある場合:
      - 現在の Phase を確認
      - LOOP に入る
```

### 新規セクション: PLAN_DERIVATION

```yaml
## PLAN_DERIVATION（計画の導出）

計画の連鎖:
  project.done_when[i]
    ↓ decomposition を参照
  playbook
    ↓ phase_hints を展開
  phases

導出ルール:
  1. project.done_when から着手可能なものを選ぶ
  2. decomposition.playbook_summary → playbook.goal.summary
  3. decomposition.success_indicators → playbook.goal.done_when
  4. decomposition.phase_hints → playbook.phases

pm の活用:
  - 複雑な依存関係がある場合は pm を呼び出す
  - 単純な場合は自己判断で導出可能
```

---

## 7. 検証方法

### p0 の done_criteria 検証

| 条件 | 検証方法 |
|------|----------|
| decomposition の構造が定義されている | このドキュメントの Section 2 |
| playbook への導出フローが図示されている | このドキュメントの Section 3 |
| pm の拡張役割が定義されている | このドキュメントの Section 4 |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | 初版作成 |
