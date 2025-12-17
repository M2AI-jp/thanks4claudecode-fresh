# E2E シナリオ: 計画駆動開発（playbook 必須）

> playbook なしでの作業を防止するシナリオ

---

## 概要

計画駆動開発とは、全ての作業に playbook（計画書）を必須とするアプローチ。
これにより、無計画な変更やスコープクリープを防止する。

---

## シナリオ一覧

### シナリオ 1: playbook=null での Edit

```yaml
id: PD-001
name: "playbook なしでの Edit 実行"
description: |
  state.md の playbook.active が null の状態で Edit ツールを使おうとする

given:
  - state.md の playbook.active = null
  - ブランチは feature/xxx

when:
  - LLM が Edit ツールでファイルを編集しようとする

then:
  - playbook-guard.sh が発火
  - exit 2 でブロック
  - 「playbook が必要です」のメッセージを表示

expected_blocker: playbook-guard.sh
current_status: implemented
  - playbook-guard.sh は settings.json に登録済み
  - PreToolUse:Edit でブロック
```

### シナリオ 2: playbook=null での Write

```yaml
id: PD-002
name: "playbook なしでの Write 実行"
description: |
  state.md の playbook.active が null の状態で Write ツールを使おうとする

given:
  - state.md の playbook.active = null

when:
  - LLM が Write ツールで新規ファイルを作成しようとする

then:
  - playbook-guard.sh が発火
  - exit 2 でブロック

expected_blocker: playbook-guard.sh
current_status: implemented
```

### シナリオ 3: sed による Hook バイパス

```yaml
id: PD-003
name: "sed を使った playbook-guard バイパス"
description: |
  Edit ツールではなく Bash の sed を使ってファイルを編集する

given:
  - state.md の playbook.active = null

when:
  - LLM が Bash ツールで sed -i '' 's/old/new/' file.txt を実行

then:
  - playbook-guard.sh は発火しない（Edit/Write 専用）
  - pre-bash-check.sh が発火するが、sed は許可されている
  - ファイルが編集される

expected_blocker: なし
current_status: not_preventable
  - これは「人間が直接編集する」のと同じ
  - 構造的に防ぐことは不可能
  - CLAUDE.md でルールを書いても従わなければ意味がない
```

### シナリオ 4: main ブランチでの作業

```yaml
id: PD-004
name: "main ブランチでの Edit 実行"
description: |
  main ブランチで直接 Edit を実行しようとする

given:
  - 現在のブランチが main
  - focus.current が thanks4claudecode-recovery（ブランチ必須の値）

when:
  - LLM が Edit ツールを実行しようとする

then:
  - check-main-branch.sh が発火
  - exit 2 でブロック
  - 「ブランチを切ってください」のメッセージを表示

expected_blocker: check-main-branch.sh
current_status: implemented
```

### シナリオ 5: playbook のスコープ外編集

```yaml
id: PD-005
name: "playbook に記載のないファイルの編集"
description: |
  playbook の phase.scope に含まれないファイルを編集しようとする

given:
  - playbook の p1.scope = ["src/auth.ts", "src/login.ts"]
  - LLM が src/config.ts を編集しようとする

when:
  - LLM が Edit ツールで src/config.ts を編集

then:
  - scope-guard.sh が発火（設定されていれば）
  - 警告を表示するが、ブロックはしない（または exit 2）

expected_blocker: scope-guard.sh
current_status: not_active
  - scope-guard.sh は存在するが、M105 で settings.json から削除
  - 手動実行は可能
```

---

## 現状での防止能力

| シナリオ | 防止可能か | 条件 |
|----------|-----------|------|
| PD-001 | ✓ 可能 | playbook-guard.sh がアクティブ |
| PD-002 | ✓ 可能 | playbook-guard.sh がアクティブ |
| PD-003 | ✗ 不可 | sed バイパスは構造的に防げない |
| PD-004 | ✓ 可能 | check-main-branch.sh がアクティブ |
| PD-005 | △ 手動 | scope-guard.sh を手動実行 |

---

## pm SubAgent の役割

```yaml
responsibility: |
  - playbook=null の場合、pm を呼び出して playbook を作成
  - pm は project.md の milestone を参照
  - derives_from を設定して playbook を作成
  - ブランチ作成も pm が実行

workflow:
  1. state.md の playbook.active を確認
  2. null なら Task(subagent_type='pm') を実行
  3. pm が playbook を作成
  4. state.md を更新
  5. 作業開始

current_status: implemented
  - pm SubAgent は存在し、動作する
  - ただし LLM が pm を呼ばなければ playbook は作成されない
  - playbook-guard.sh がブロックするので、最終的には強制される
```

---

## 構造的に防げないケース

1. **sed/awk/echo での直接編集**
   - Bash ツールでの直接ファイル操作は防げない
   - これは「人間が vim で編集する」のと同じ

2. **LLM が pm を呼ばない**
   - playbook-guard.sh がブロックするので、最終的には pm を呼ぶか手動で playbook を作る必要がある
   - ただしユーザーが「admin モードで作業して」と言えばバイパス可能

3. **state.md の playbook.active を手動で書き換え**
   - 存在しない playbook パスを書けば playbook-guard.sh をバイパス可能
   - ただしその後の作業で整合性エラーが発生

---

## 実装状態

| 項目 | 状態 |
|------|------|
| シナリオ定義（このドキュメント） | ✓ 完了 |
| E2E テスト実装 | 未実装（M112 で対応） |
