# Self-Healing System 設計書

> **目的**: ユーザーの手作業に依存しない自律改善システムの構築
>
> **核心課題**: Claude Code の機能がカタログスペック通りに動作するか検証し、
> コンテキスト消失・ドキュメント陳腐化・機能故障を自動検知・修復する仕組み

---

## 1. 課題分析

### 1.1 現状の問題

| 問題 | 影響 | 現状の対策 |
|------|------|-----------|
| Auto-compact でユーザー意図が消失 | 作業の方向性を見失う | pre-compact.sh（部分対応） |
| ドキュメント（current-implementation.md）の陳腐化 | 古い情報を参照してしまう | なし |
| Hook/SubAgent の故障検知がない | 気づかずに機能が停止 | なし |
| 機能のカタログスペックと実動作の乖離 | 期待通りに動かない | ユーザーの手作業テスト |

### 1.2 ユーザーの手作業依存箇所

```yaml
現在ユーザーが手作業で行っていること:
  - 冗長なプロンプトでコンテキストを補完
  - ドキュメントの最新性を目視確認
  - Hook が動作しているかの確認
  - compact 後の状態復元の確認
  - current-implementation.md の手動更新
```

---

## 2. 解決アーキテクチャ

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Self-Healing System                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  【Layer 1: Context Continuity】コンテキスト継続性                    │
│  ├─ PreCompact → 完全な状態スナップショット保存                       │
│  ├─ SessionStart(compact) → スナップショットから復元                  │
│  └─ UserPromptSubmit → 意図の構造化保存                              │
│                                                                      │
│  【Layer 2: Document Freshness】ドキュメント鮮度管理                  │
│  ├─ PostToolUse(Read) → 読み込み時に鮮度チェック                     │
│  ├─ PostToolUse(Edit/Write) → 関連ドキュメント更新を促す              │
│  └─ SessionStart → 重要ドキュメントの鮮度警告                        │
│                                                                      │
│  【Layer 3: Feature Verification】機能検証                           │
│  ├─ SessionStart → Hook/SubAgent 存在・整合性確認                    │
│  ├─ health-checker → 定期的な自己診断                                │
│  └─ settings.json ↔ 実ファイル整合性チェック                         │
│                                                                      │
│  【Layer 4: Self-Improvement】自律改善ループ                         │
│  ├─ learning Skill → 失敗パターンの記録・学習                        │
│  ├─ PostToolUse → 変更検知と関連更新の自動提案                       │
│  └─ coherence → 不整合の自動修復提案                                 │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. 実装計画

### Phase 1: Context Continuity 強化

**目標**: Auto-compact でユーザー意図が消失しない仕組み

#### 3.1.1 PreCompact 強化（pre-compact.sh 改修）

```yaml
現状:
  - user-intent.md の最新5件を additionalContext に含める
  - focus, playbook, done_criteria を保存

強化:
  - 完全なセッション状態スナップショットを .claude/.session-init/snapshot.json に保存
  - playbook の現在 Phase の詳細情報を保存
  - 最新の [自認] 状態を保存
  - 変更中のファイルリスト（git status）を保存
```

#### 3.1.2 SessionStart の compact 分岐

```yaml
SessionStart の matcher を活用:
  startup: 通常の初期化
  resume: セッション再開
  clear: /clear 後の再初期化
  compact: auto-compact 後の復元 ★これを追加

compact 時の処理:
  1. snapshot.json から状態を復元
  2. 「📦 Compact からの復元」セクションを表示
  3. user-intent.md の内容を強調表示
  4. 前回の作業状態を詳細に表示
  5. 「この意図に沿って作業を継続してください」を明示
```

### Phase 2: Document Freshness Check

**目標**: ドキュメントの陳腐化を自動検知

#### 3.2.1 doc-freshness-check.sh（PostToolUse:Read）

```yaml
トリガー: Read ツール使用後

処理:
  1. 読み込んだファイルのパスを取得
  2. 重要ドキュメント（docs/, CLAUDE.md, current-implementation.md）かチェック
  3. git log でファイルの最終更新日を取得
  4. 関連ファイルの更新日と比較
     - current-implementation.md → .claude/hooks/, .claude/agents/ の更新日
     - CLAUDE.md → playbook-format.md, state.md の更新日
  5. 乖離が 3 日以上なら警告

出力例:
  ⚠️ current-implementation.md は 2025-12-09 に更新されましたが、
     .claude/hooks/playbook-guard.sh は 2025-12-10 に変更されています。
     ドキュメントが古い可能性があります。
```

#### 3.2.2 update-tracker.sh（PostToolUse:Edit/Write）

```yaml
トリガー: Edit/Write ツール使用後

処理:
  1. 変更したファイルのパスを取得
  2. 依存マップから影響を受けるドキュメントを特定
  3. 更新が必要なドキュメントを systemMessage で提案

依存マップ（.claude/config/doc-dependencies.yaml）:
  .claude/hooks/*:
    - docs/current-implementation.md
    - .claude/hooks/CLAUDE.md
  .claude/agents/*:
    - docs/current-implementation.md
    - .claude/agents/CLAUDE.md
  plan/template/*:
    - docs/current-implementation.md
```

### Phase 3: Feature Verification

**目標**: Hook/SubAgent が正常動作しているか自動検証

#### 3.3.1 system-health-check.sh（SessionStart 統合）

```yaml
SessionStart で実行:
  1. settings.json の Hook 登録を読み込み
  2. 登録された各 .sh ファイルが存在するか確認
  3. 実行権限があるか確認
  4. SubAgent 定義ファイルが存在するか確認
  5. 問題があれば警告を出力

チェック項目:
  - [ ] settings.json が有効な JSON か
  - [ ] 登録された Hook ファイルが全て存在するか
  - [ ] Hook ファイルが実行可能か（chmod +x）
  - [ ] SubAgent ファイルが存在するか
  - [ ] state.md が有効な形式か
```

#### 3.3.2 health-checker SubAgent の強化

```yaml
現状: 手動呼び出し

強化:
  - SessionStart で自動呼び出し（軽量チェックのみ）
  - 問題検出時に詳細診断を実行
  - 自動修復可能な問題は修復提案を出力
```

### Phase 4: Self-Improvement Loop

**目標**: 失敗から学習し、同じ問題を繰り返さない

#### 3.4.1 failure-logger.sh

```yaml
トリガー: exit 2 で終了した Hook

処理:
  1. 失敗した Hook 名、日時、コンテキストを記録
  2. .claude/logs/failures.log に JSONL 形式で保存
  3. 同じ失敗パターンが 3 回以上続いたら警告

記録フォーマット:
  {"timestamp": "2025-12-10T...", "hook": "playbook-guard.sh",
   "context": "playbook=null", "user_action": "Edit src/foo.ts"}
```

#### 3.4.2 learning Skill の活用

```yaml
learning Skill を SessionStart で参照:
  1. 過去の失敗パターンを読み込み
  2. 現在の状態と照合
  3. 類似パターンを検出したら事前警告

例:
  ⚠️ 過去に playbook=null で Edit 試行 → ブロック が 5 回発生しています。
     pm SubAgent で playbook を作成してから作業を開始してください。
```

---

## 4. 実装優先順位

| 優先度 | 機能 | 理由 |
|--------|------|------|
| P0 | Context Continuity 強化 | ユーザー最大の痛点 |
| P1 | SessionStart compact 分岐 | P0 と連動 |
| P2 | Document Freshness Check | 陳腐化問題の解決 |
| P3 | Feature Verification | 信頼性向上 |
| P4 | Self-Improvement Loop | 長期的な品質向上 |

---

## 5. 技術的制約と対策

### 5.1 SessionStart の trigger 検出

```yaml
問題: session-start.sh は入力 JSON を読んでいない
      → trigger（startup/resume/clear/compact）を検出できない

対策:
  session-start.sh の先頭で stdin から JSON を読み込む:
    INPUT=$(cat)
    TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "startup"')

  trigger による分岐:
    case "$TRIGGER" in
      compact)
        # snapshot.json から復元
        # 「📦 Compact からの復元」を表示
        ;;
      clear)
        # .session-init/ をリセット
        ;;
      *)
        # 通常の初期化
        ;;
    esac
```

### 5.2 PostToolUse(Read) の登録

```yaml
問題: 現在 PostToolUse(Read) は登録されていない

対策:
  settings.json に追加:
  {
    "matcher": "Read",
    "hooks": [{
      "type": "command",
      "command": "bash .claude/hooks/doc-freshness-check.sh"
    }]
  }

注意: Read は頻繁に呼ばれるため、軽量な処理に留める
```

### 5.3 自動修復の範囲

```yaml
自動修復可能:
  - chmod +x の付与
  - .session-init/ ディレクトリの作成
  - snapshot.json の初期化

自動修復不可（提案のみ）:
  - Hook ファイルの内容修正
  - settings.json の構造変更
  - SubAgent の修正
```

---

## 6. 成功基準

```yaml
Phase 1 完了基準:
  - [ ] auto-compact 後にユーザー意図が完全に復元される
  - [ ] compact 後のセッションで前回の作業状態が明確に表示される

Phase 2 完了基準:
  - [ ] 古いドキュメントを読んだ時に警告が表示される
  - [ ] ファイル変更後に関連ドキュメント更新が提案される

Phase 3 完了基準:
  - [ ] Hook 故障時に SessionStart で警告が表示される
  - [ ] settings.json と実ファイルの不整合が検出される

Phase 4 完了基準:
  - [ ] 失敗パターンが自動記録される
  - [ ] 類似パターンで事前警告が表示される
```

---

## 7. 依存関係

```
Phase 1 (Context Continuity)
    │
    ├── Phase 2 (Document Freshness) ← 独立して実装可能
    │
    └── Phase 3 (Feature Verification) ← Phase 1 の基盤が必要
            │
            └── Phase 4 (Self-Improvement) ← Phase 3 の基盤が必要
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-10 | 初版作成 |
