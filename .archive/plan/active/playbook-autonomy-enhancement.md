# playbook-autonomy-enhancement.md

> **自律性強化: PDCA自動回転・妥当性評価フレームワーク**

---

## meta

```yaml
project: thanks4claudecode
created: 2025-12-08
issue: "#8"
branch: feat/autonomy-enhancement
type: meta-improvement
```

---

## goal

```yaml
summary: LLM が完全自律で PDCA を回せるようにする
root_cause: MECE分析で発見した15個の欠落機能のうち、自律性に関わる4つを解消

done_when:
  - コア思想が構造的に保存され、セッション開始時に必ず読み込まれる
  - LOOP が 10 回超えたら自動警告が出る（デッドロック検出）
  - done_criteria の妥当性を固定フレームワークで評価できる
  - playbook 完了後、次のタスクが自動的に開始される
```

---

## core_philosophy（実装の指針）

> **これを忘れたら全ての実装が無意味になる。**

```yaml
pdca_autonomy: ユーザープロンプトなしで PDCA が回る
tdd_first: 「正しい動き」を先に定義、根拠ベースの done_criteria
validation_framework: 妥当性評価は都度生成ではなく固定フレームワーク
plan_based: 計画なしで作業開始禁止
issue_context: Issue で外部コンテキスト化、セッション間継続
git_branch_sync: 1 playbook = 1 branch
```

---

## phases

### p1: コア思想の永続化

```yaml
id: p1
name: コア思想の永続化
goal: コア思想を構造的に保存し、セッション開始時に必ず読み込まれるようにする
executor: claude
max_iterations: 10

正しい動きの定義:
  - セッション開始時、INIT で コア思想が表示される
  - コア思想に違反する行動をしようとすると警告が出る
  - コア思想は CLAUDE.md または専用ファイルに記載される

done_criteria:
  - CLAUDE.md に core_philosophy セクションが追加されている
  - session-start.sh がコア思想を表示する
  - 証拠: cat CLAUDE.md | grep -A10 "core_philosophy"

evidence:
  - CLAUDE.md: CORE_PHILOSOPHY セクション追加（79-112行）
  - session-start.sh: コア思想表示セクション追加（137-149行）
  - critic: PASS（客観的証拠に基づく検証完了）
status: done
```

---

### p2: デッドロック検出

```yaml
id: p2
name: デッドロック検出（max_iterations）
goal: LOOP が無限ループしないよう、回数制限と警告を実装
executor: claude
max_iterations: 10

正しい動きの定義:
  - playbook に max_iterations フィールドがある
  - LOOP が max_iterations を超えたら自動で警告を出力
  - 警告後、続行するかどうかの判断ロジックがある

done_criteria:
  - playbook フォーマットに max_iterations フィールドが定義されている
  - CLAUDE.md の LOOP セクションに回数カウントのロジックがある
  - この playbook の全 Phase に max_iterations フィールドが存在する

evidence:
  - playbook-format.md: max_iterations フィールド追加（86行）
  - CLAUDE.md: LOOP に iteration_count / max_iterations ロジック追加（121-146行）
  - playbook: 全 Phase に max_iterations: 10 を設定
  - critic: PASS
status: done
```

---

### p3: 妥当性評価フレームワーク

```yaml
id: p3
name: 妥当性評価フレームワーク
goal: done_criteria の妥当性を都度生成ではなく固定フレームワークで評価
executor: claude
max_iterations: 10

正しい動きの定義:
  - done_criteria を定義する際、固定のチェックリストを使う
  - チェックリストは .claude/frameworks/ に保存される
  - critic エージェントがこのフレームワークを参照する

done_criteria:
  - .claude/frameworks/done-criteria-validation.md が存在
  - critic.md が frameworks/ を参照

evidence:
  - ls: .claude/frameworks/done-criteria-validation.md 存在確認済
  - grep: critic.md に "frameworks/done-criteria-validation.md" 参照あり
  - critic: PASS
status: done
```

---

### p4: PDCA 自律回転機構

```yaml
id: p4
name: PDCA 自律回転機構
goal: playbook 完了後、次のタスクが自動的に開始される
executor: claude
max_iterations: 10

正しい動きの定義:
  - POST_LOOP が次のタスクを検出したら、自動で新 playbook を作成
  - 新 playbook 作成後、自動で LOOP に入る
  - 「報告して待つ」パターンが発生しない

done_criteria:
  - POST_LOOP が「残タスクあり → 新 playbook 作成 → LOOP 再開」を命令
  - CLAUDE.md に「POST_LOOP 後は自動で次へ進む」ルールがある
  - 証拠: playbook 完了 → 次 playbook 自動作成のフローが定義されている

evidence:
  - CLAUDE.md: POST_LOOP セクション追加（128-148行）
  - 内容: 残タスク検出 → 新ブランチ/playbook作成 → LOOP再開
  - 禁止事項: 「報告して待つ」パターン明記
  - critic: PASS
status: done
```

---

### p5: 統合テスト

```yaml
id: p5
name: 統合テスト
goal: 全ての実装が連携して動作することを確認
executor: claude
max_iterations: 10

正しい動きの定義:
  - セッション開始からコア思想が表示される
  - LOOP 実行中にデッドロック検出が機能する
  - done_criteria 評価時に固定フレームワークが使用される
  - playbook 完了後、自動で次に進む

done_criteria:
  - 異常系テスト: デッドロック検出の動作確認
  - 正常系テスト: PDCA 1サイクルが自律で完了
  - critic PASS

evidence:
  - 異常系: CLAUDE.md 110-115行 iteration counting ロジック確認
  - 異常系: playbook 全 Phase に max_iterations: 10 あり（58,86,115,142,171行）
  - 正常系: session-start.sh 137-146行 CORE 表示確認
  - 正常系: CLAUDE.md 128-148行 POST_LOOP 定義確認
  - 正常系: この playbook 自体が p1-p5 の PDCA サイクルで完了
  - critic: PASS
status: done
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | 全 Phase 完了（p1-p5 critic PASS）。Issue #8 完了。 |
| 2025-12-08 | p4 完了。POST_LOOP セクション追加。PDCA 自律回転機構実装。 |
| 2025-12-08 | p3 完了。.claude/frameworks/ 作成。critic.md 更新。CLAUDE.md 簡潔化。 |
| 2025-12-08 | p2 完了。LOOP にデッドロック検出追加。 |
| 2025-12-08 | p1 完了。CLAUDE.md + session-start.sh に CORE 追加。 |
| 2025-12-08 | 初版作成。Issue #8。 |
