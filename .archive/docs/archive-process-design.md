# Archive Process Design

> **目的**: archive-playbook.sh を改善し、playbook 完了時の確実なアーカイブを実現
>
> **作成日**: 2025-12-09
> **playbook**: playbook-artifact-health.md p3

---

## 1. 現状分析

### 1.1 archive-playbook.sh の現在の設計

```yaml
発火条件: PostToolUse:Edit
対象: playbook*.md ファイルが編集されたとき
動作: 全 Phase が done なら「提案」を出力（stdout）
問題:
  - 提案のみで自動実行しない
  - 提案が stdout に出力されるだけで永続化されない
  - Claude が提案を見ても実行するルールがない
```

### 1.2 POST_LOOP の現在の設計

```yaml
行動:
  0. 自動コミット
  1. 自動マージ
  2. project.done_when の更新
  3. 次タスクの導出
  4. 残タスクあり → ブランチ作成、playbook 作成
  5. 残タスクなし → 完了メッセージ

問題: アーカイブステップがない
```

---

## 2. 改善オプションの比較

| オプション | 内容 | メリット | デメリット |
|-----------|------|---------|-----------|
| A | archive-playbook.sh を自動実行に変更 | 確実にアーカイブされる | 事故リスク（意図しないアーカイブ） |
| B | POST_LOOP にアーカイブステップを追加 | CLAUDE.md で明示的にルール化 | Claude が「読んでも無視」する可能性 |
| C | Hook 検出 + POST_LOOP 実行の組み合わせ | 二重チェック、堅牢 | 実装が複雑 |

---

## 3. 推奨設計: オプション C（Hook 検出 + POST_LOOP 実行）

### 3.1 改善後のフロー

```
1. playbook の最終 Phase が done になる
2. Claude が playbook を Edit で更新（status: done）
3. archive-playbook.sh が発火（PostToolUse:Edit）
4. 全 Phase done を検出 → 「アーカイブ推奨」を出力
5. Claude が POST_LOOP に入る
6. POST_LOOP 行動 0.5（新規）: アーカイブ実行
   - 現在の playbook を .archive/plan/ に移動
   - state.md の active_playbooks を null に更新
7. POST_LOOP 行動 1: 自動コミット
8. 以降は従来通り
```

### 3.2 CLAUDE.md POST_LOOP への追加案

```yaml
行動:
  0. 自動コミット（最終 Phase 分）★直接実行

  0.5. 【新規】完了 playbook のアーカイブ★直接実行:
     - archive-playbook.sh の提案が出力されている場合
     - 以下を実行:
       ```bash
       mkdir -p .archive/plan
       mv plan/active/playbook-{name}.md .archive/plan/
       ```
     - state.md の active_playbooks.{layer} を null に更新
     - 注意: アーカイブ前に git add/commit を完了すること

  1. 自動マージ★直接実行
  ...
```

### 3.3 archive-playbook.sh の改善案

```bash
# 現在: 提案を出力するだけ
# 改善: 提案を出力 + state.md にフラグを立てる（オプション）

# フラグ方式（検討）
# echo "archive_pending: plan/active/playbook-{name}.md" >> .claude/.session-init/archive-pending

# ただし、POST_LOOP で Claude が実行することを明記すれば、
# 現在の「提案のみ」設計でも問題ない。
# 重要なのは CLAUDE.md に「提案を見たら実行」ルールを追加すること。
```

---

## 4. 実装リスク分析

### 4.1 削除ミスのリスク

| リスク | 対策 |
|--------|------|
| 意図しないアーカイブ | 全 Phase done チェックは既に実装済み |
| 誤って現在進行中の playbook をアーカイブ | state.md active_playbooks との照合を追加 |
| git 履歴からの復元困難 | アーカイブなので mv（削除ではない）、git log で追跡可能 |

### 4.2 ロールバック手順

```bash
# アーカイブを取り消す場合
mv .archive/plan/playbook-{name}.md plan/active/
# state.md を更新
# active_playbooks.{layer}: plan/active/playbook-{name}.md
```

---

## 5. アーカイブ判定基準

### 5.1 アーカイブ条件

```yaml
必須条件（AND）:
  - playbook 内の全 Phase の status が done
  - state.md の active_playbooks に該当しない（現在進行中でない）

オプション条件:
  - critic PASS 記録がある（Phase 完了が検証済み）
  - 最終更新から 24 時間以上経過（安全マージン）
```

### 5.2 アーカイブ禁止条件

```yaml
以下の場合はアーカイブしない:
  - 現在進行中の playbook（state.md active_playbooks に登録）
  - Phase の一部が pending または in_progress
  - setup/playbook-setup.md（テンプレートとして常に保持）
```

---

## 6. 実装計画

### Phase 1: CLAUDE.md POST_LOOP の更新（BLOCK ファイル）

```yaml
変更内容:
  - 行動 0.5 として「完了 playbook のアーカイブ」を追加
  - アーカイブ実行コマンドを明記
  - アーカイブ後の state.md 更新ルールを明記

必要な許可: ユーザー許可（BLOCK ファイル）
```

### Phase 2: archive-playbook.sh の微修正（オプション）

```yaml
変更内容:
  - 現在進行中 playbook のチェックを追加
  - state.md active_playbooks との照合

必要な許可: なし（通常ファイル）
```

### Phase 3: 運用ルールの文書化

```yaml
作成ファイル: docs/archive-operation-rules.md
内容:
  - アーカイブ判定基準
  - 手動アーカイブ手順
  - ロールバック手順
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | 初版作成。p3 アーカイブプロセス設計完了。 |
