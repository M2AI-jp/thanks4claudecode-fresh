# 設計思想: Hook/Skill/SubAgent の関係性

> **Claude Code ワークスペースにおける拡張システムの設計思想を定義**
>
> このドキュメントは Hook、Skill、SubAgent の役割分担と相互連携を明確化します。

---

## 1. 導火線モデル（Fuse Model）

```
┌─────────────────────────────────────────────────────────────────────┐
│                        イベント発生                                   │
│                            ↓                                        │
│  ┌─────────────┐   発火   ┌─────────────┐   呼出   ┌─────────────┐  │
│  │    Hook     │ ──────→ │   Skill     │ ──────→ │  SubAgent   │  │
│  │  （導火線）  │          │ （知識体系） │          │ （委譲先）   │  │
│  └─────────────┘          └─────────────┘          └─────────────┘  │
│                                                                      │
│  自動・強制・ブロック可     自動・文脈判断        自動/手動・独立実行   │
└─────────────────────────────────────────────────────────────────────┘
```

### Hook（導火線）

**役割**: イベントを検知し、処理を起動する発火点

```yaml
特性:
  発火: 自動（イベント駆動）
  制御: ブロック可能（exit 2）
  設定: settings.json に登録

発火タイミング:
  - SessionStart: セッション開始時
  - PreToolUse: ツール実行前
  - PostToolUse: ツール実行後
  - UserPromptSubmit: プロンプト送信時
  - Stop: セッション中断時

例:
  playbook-guard.sh:
    トリガー: PreToolUse(Edit|Write)
    動作: playbook.active が null なら BLOCK
```

### Skill（知識体系）

**役割**: 特定ドメインの専門知識とガイドラインを提供

```yaml
特性:
  発火: 自動（文脈から判断）
  制御: ブロック不可（ガイダンスのみ）
  設定: .claude/skills/{name}/SKILL.md

発火条件:
  - プロンプトに関連キーワードが含まれる
  - ユーザーが明示的に要求
  - 他の Skill/Hook から参照

例:
  test-runner:
    キーワード: "テスト実行して", "テストして"
    動作: Unit/E2E テストを自動実行し結果を報告
```

### SubAgent（委譲先）

**役割**: 複雑なタスクを独立して実行する専門エージェント

```yaml
特性:
  発火: 自動/手動（Task ツールで委譲）
  制御: 独立実行（別コンテキスト）
  設定: .claude/agents/{name}.md

呼び出し方法:
  - Task(subagent_type='{name}', prompt='...')
  - Skill 内から参照・推奨

例:
  critic:
    呼び出し: Task(subagent_type='critic')
    動作: done_criteria の達成を証拠ベースで検証
```

---

## 2. 4QV+ 構成（Four-Quadrant Validation Plus）

```
┌─────────────────────────────────────────────────────────────────────┐
│                           4QV+ 検証構成                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │     Q1: Technical       │  │    Q2: Consistency      │           │
│  │   技術的正確性検証        │  │   他コンポーネント整合性   │           │
│  │                         │  │                         │           │
│  │  - コマンド実行結果確認   │  │  - state.md との整合     │           │
│  │  - ファイル存在確認       │  │  - playbook との整合     │           │
│  │  - 構文エラーチェック     │  │  - 設定ファイルとの整合   │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│                                                                      │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │    Q3: Completeness     │  │    Q4+: Evidence        │           │
│  │    完全性検証            │  │    証拠ベース検証         │           │
│  │                         │  │                         │           │
│  │  - 全 done_criteria 確認 │  │  - critic SubAgent 検証  │           │
│  │  - 関連ファイル更新確認   │  │  - 実行結果の記録        │           │
│  │  - 抜け漏れチェック       │  │  - タイムスタンプ付与     │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### validations フィールド（V16 形式）

```yaml
validations:
  technical: "{Q1: 技術的に正しく動作するか}"
  consistency: "{Q2: 他コンポーネントと整合性があるか}"
  completeness: "{Q3: 必要な変更が全て完了しているか}"
# Q4+ は critic SubAgent が証拠ベースで実行
```

---

## 3. コンポーネント間の連携パターン

### パターン 1: Hook → Skill

```yaml
シナリオ: セッション開始時に状態確認
フロー:
  1. SessionStart Hook 発火
  2. session-start.sh が state.md を読み込み
  3. state Skill の知識を参照して [自認] を出力
```

### パターン 2: Skill → SubAgent

```yaml
シナリオ: playbook 作成の委譲
フロー:
  1. plan-management Skill が呼び出される
  2. playbook 作成が必要と判断
  3. pm SubAgent に委譲: Task(subagent_type='pm')
```

### パターン 3: Hook → SubAgent

```yaml
シナリオ: Phase 完了時の検証
フロー:
  1. PostToolUse(Edit) Hook 発火
  2. critic-guard.sh が Phase 完了を検出
  3. critic SubAgent を呼び出し推奨
```

### パターン 4: 循環連携（LOOP）

```yaml
シナリオ: タスク実行ループ
フロー:
  1. Hook: playbook-guard.sh（存在確認）
  2. Skill: test-runner（テスト実行）
  3. SubAgent: critic（完了検証）
  4. Hook: subtask-guard.sh（状態更新監視）
  5. → 次の subtask へ（繰り返し）
```

---

## 4. 設計原則

### 4.1 単一責任の原則

```yaml
Hook:
  - イベント検知と発火のみ
  - 複雑なロジックは持たない
  - ブロック/許可の判断のみ

Skill:
  - ドメイン知識の提供のみ
  - 実行は Claude 本体に委ねる
  - 手順とガイドラインを提示

SubAgent:
  - 独立したタスク実行
  - 結果の報告
  - 親コンテキストへの影響なし
```

### 4.2 疎結合の原則

```yaml
連携方法:
  - 直接呼び出しではなくイベント駆動
  - 名前ベースの参照（ハードコードしない）
  - 設定ファイルで接続を定義

変更影響:
  - Hook 変更 → Skill/SubAgent への影響なし
  - Skill 変更 → 呼び出し側への影響なし
  - SubAgent 変更 → 呼び出し側への影響なし
```

### 4.3 フェイルセーフの原則

```yaml
Hook:
  - 失敗時は BLOCK（exit 2）でシステム保護
  - 不明な状態では安全側に倒す
  - エラーログを必ず出力

Skill:
  - ガイダンスが不明な場合は明示
  - 推測で動作しない
  - ユーザー確認を促す

SubAgent:
  - 完了できない場合は FAIL を報告
  - 部分完了の状態を明示
  - 次のアクションを提案
```

---

## 5. 命名規則

```yaml
Hook:
  形式: {action}-{target}.sh
  例: playbook-guard.sh, check-main-branch.sh

Skill:
  形式: {domain}/SKILL.md
  例: test-runner/SKILL.md, state/SKILL.md

SubAgent:
  形式: {role}.md
  例: critic.md, pm.md, reviewer.md
```

---

## 6. 追加・変更のガイドライン

### 新しい Hook を追加する場合

```yaml
1. .claude/hooks/{name}.sh を作成
2. settings.json に登録
3. RUNBOOK.md の Hooks テーブルに追加
4. generate-repository-map.sh を実行
```

### 新しい Skill を追加する場合

```yaml
1. .claude/skills/{name}/SKILL.md を作成
2. フロントマッター（name, description）を記述
3. RUNBOOK.md の Skills テーブルに追加
4. generate-repository-map.sh を実行
```

### 新しい SubAgent を追加する場合

```yaml
1. .claude/agents/{name}.md を作成
2. AGENTS.md に追加
3. RUNBOOK.md の SubAgents テーブルに追加
4. generate-repository-map.sh を実行
```

---

## 参照ドキュメント

| ファイル | 内容 |
|---------|------|
| docs/extension-system.md | 発火タイミング・トリガーの詳細 |
| docs/repository-map.yaml | 全コンポーネント一覧（自動生成） |
| RUNBOOK.md | 操作手順と一覧テーブル |
| .claude/settings.json | Hook 登録設定 |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-23 | 初版作成。M090 構造的整合性修正の一環として導火線モデルと 4QV+ 構成を定義。 |
