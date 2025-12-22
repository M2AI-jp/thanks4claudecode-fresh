# CLAUDE.md

> **【即時実行】このファイルを読んだ直後、INIT セクションを実行せよ。[自認]出力までユーザーに応答するな。違反 → init-guard.sh がブロック（exit 2）。**

> **【三位一体】Hooks（構造的強制）+ SubAgents（検証）+ CLAUDE.md（思考制御）。単独では機能しない。組み合わせて初めて強制力を持つ。**

> **【報酬詐欺防止】「完了」の自己判断禁止。critic SubAgent が PASS を返すまで done 不可。1回で終わらせようとする衝動に抗え。LOOP を回し続けよ。**

> **【自律 ≠ 勝手】project → playbook → phase の3層連鎖から次を導出。待つな。しかしユーザーの意図を推測で補完するな。不明 → 質問。「確認」はするな。**

> **【タスク標準化】全タスク開始は pm SubAgent 経由必須。直接 playbook を作成するな。pm → project.milestone 参照 → derives_from 設定 → playbook 作成。**

> **【3層自動運用】project（永続）→ playbook（一時）→ phase（作業単位）。Claude が主導管理。人間は意思決定とプロンプト提供のみ。**

---

## 3層構造

```yaml
project:
  定義: リポジトリ全体のビジョンと目標（永続）
  ファイル: plan/project.md
  子要素: milestone（中間目標）

milestone:
  定義: project の中間目標
  ID形式: M001, M002, ...
  紐付け: playbook.meta.derives_from で参照

playbook:
  定義: milestone を達成するための実行計画（一時的）
  ファイル: plan/active/playbook-{name}.md
  完了後: アーカイブ + project.milestone 自動更新
  子要素: phase

phase:
  定義: playbook 内の作業単位
  ID形式: p0, p1, p2, ...
  完了条件: done_criteria[]
```

---

## INIT（セッション開始時）【絶対ルール】

> **ユーザーのメッセージに応答する前に、以下を必ず完了せよ。スキップは許可されていない。**

```
【フェーズ 1: 必須読み込み】※ユーザー応答前に必須

  1. Read: state.md（現在地・goal・milestone）
  2. Read: plan/project.md（プロジェクト計画）
  3. Read: playbook（playbook.active から特定、なければ null）
  4. Read: docs/repository-map.yaml（全ファイルマッピング）

  ⚠️ Hook 出力を「見た」だけでは不十分。Read ツールで実際に読め。
  ⚠️ Read 未完了でユーザーに応答するな。

【フェーズ 2: git/branch 状態取得】

  5. Bash: `git rev-parse --abbrev-ref HEAD`
  6. Bash: `git status -sb`
  7. main ブランチ → ブランチを切る

【フェーズ 3: playbook 準備】★pm 経由必須

  8. playbook=null → pm SubAgent を呼び出す
     - pm が project.milestone を参照して playbook を作成
     - derives_from を必ず設定（milestone ID）
     - ブランチ作成も pm が実行
     ⚠️ pm を経由せずに直接 playbook を作成することは禁止

【フェーズ 4: 宣言】

  9. [自認] を出力

【フェーズ 4.5: 5W1H 自動構造化】★重要

  条件: playbook=null の場合のみ実行（計画がない = 新規タスク）

  10. ユーザープロンプトを自動的に 5W1H 形式で構造化
  11. [5W1H 構造化] を出力
  12. ★ユーザー応答を待たずに★ フェーズ 5 へ進む

  スキップ条件:
    - playbook が既に存在する（計画済み）
    - compact/resume トリガー（セッション継続）

【フェーズ 5: project チェック & 計画の導出】

  13. plan/project.md の存在を確認
  14. playbook=null かつ project が存在する場合:
      - project.milestones から not_started/in_progress を確認
      - depends_on を分析し、着手可能な milestone を特定
      - pm を呼び出して playbook を作成
      - 「project: {goal} / 次: {milestone.name} を進めます。」
  15. playbook がある場合:
      - 現在の phase を確認し LOOP に入る
  16. project が存在しない場合（setup）:
      - 「project は setup 完了後に生成されます。」
      - playbook の phase 0 から開始
  17. LOOP に入る（ユーザーが止めない限り進む）

  ⚠️ 禁止: 「よろしいですか？」と聞く
  ⚠️ 禁止: 「何か続けますか？」と聞く
```

---

## [自認]（必ず最初に出力）

```
[自認]
what: {focus.current}
milestone: {goal.milestone}
phase: {goal.phase}
branch: {現在のブランチ名}
project_summary: {plan/project.md の vision.goal}
remaining: {残りの milestone 数 | 残りの phase 数}
playbook: {playbook.active}
done_criteria: {現在の phase.done_criteria を列挙}
git_status: {clean | modified | untracked}
last_critic: {null | PASS | FAIL}
```

---

## [理解確認]（Edit/Write 前に必須）

> **詳細: @.claude/skills/consent-process/skill.md**

```
[理解確認]
what: 「〇〇をすること」と理解しました
why: 目的は「△△」と推測します
how: 以下の手順で進めます
scope: 変更対象ファイル
exclusions: 変更しないファイル
risks: |
  リスク1_{カテゴリ}:
    問題: {失敗の可能性}
    影響: {影響度}
    対策: {防止策}
  リスク2_{カテゴリ}:
    ...
```

```yaml
risks 必須項目:
  問題: 何が失敗する可能性があるか
  影響: 失敗した場合の影響
  対策: どう防ぐか

リスクカテゴリ例:
  - 不完全な網羅性
  - 整合性の欠如
  - 技術的障害
  - 仕様の誤解
  - 回帰（既存機能の破壊）

ルール:
  - 主要リスク 3-5 個に絞る
  - コピペ禁止、タスク固有のリスクを分析
  - 対策は実行可能なアクションであること
```

---

## CORE（原則）

```yaml
three_layer_system:
  rule: project → playbook → phase の3層で自動運用
  project: 永続（milestone で進捗管理）
  playbook: 一時（完了→アーカイブ→milestone更新）
  phase: 作業単位（critic PASS で完了）

pdca_autonomy:
  rule: playbook 完了 → milestone 更新 → 次 playbook 自動作成
  禁止: ユーザープロンプトを待つ

clear_timing:
  rule: playbook 完了時に /clear 推奨をアナウンス
  理由: コンテキスト汚染を防ぎ、動作を安定させる

tdd_first:
  rule: done_criteria = テスト仕様
  条件: 根拠 = ユーザー発言引用 | 検証可能指標
  禁止: 根拠なき done_criteria

validation:
  rule: critic は .claude/rules/frameworks/ を参照
  禁止: 都度生成の評価基準

plan_based:
  条件: playbook=null で Edit/Write → ブロック

git_branch_sync:
  rule: 1 playbook = 1 branch
```

---

## LOOP（V11: subtasks 構造対応）

```
iteration = 0
max = playbook.phase.max_iterations || 10

while true:
  iteration++
  if iteration > max: break  # デッドロック検出

  0. 根拠なし → ユーザーに質問
  1. subtasks を読む（criterion + executor + test_command）
  2. 各 subtask について:
     - executor: claudecode/codex → 自動実行
     - executor: coderabbit → レビュー実行
     - executor: user → ユーザー確認待ち（DEFERRED）
  3. test_command を実行して PASS/FAIL を判定
  4. 全 subtask PASS → CRITIQUE()
     - PASS → playbook 更新 → 自動コミット → 次 phase
     - FAIL → 修正 → continue
  5. 不明 → break

executor 選択ガイドライン:
  claudecode: ファイル作成、設計、軽量スクリプト
  codex: 本格的なコード実装
  coderabbit: コードレビュー
  user: 手動確認、外部操作

phase 完了時の自動コミット:
  条件: critic PASS 後
  実行:
  ```bash
  git add -A && git commit -m "$(cat <<'EOF'
  feat({phase}): {summary}

  done_criteria:
  - {criteria_1}
  - {criteria_2}

  critic: PASS
  playbook: {playbook_path}

  🤖 Generated with [Claude Code](https://claude.com/claude-code)

  Co-Authored-By: Claude <noreply@anthropic.com>
  EOF
  )"
  ```
```

---

## POST_LOOP（playbook 完了後）

> **詳細: @.claude/skills/post-loop/skill.md**

playbook の全 phase が done → 以下を自動実行:

```yaml
フロー:
  1. 自動コミット（最終 phase 分）
  2. playbook をアーカイブ
  3. project.milestone を自動更新
     - status = achieved
     - achieved_at = now()
     - playbooks[] に追記
  4. ★ /clear 推奨アナウンス ★
  5. 次の milestone を特定（depends_on 分析）
  6. pm で新 playbook を自動作成
  7. PR 作成・マージ（オプション）

/clear 推奨アナウンス:
  ┌────────────────────────────────────────────────┐
  │ 🎉 playbook 完了: {playbook_name}              │
  │                                                │
  │ 📊 project 進捗: {X}/{Y} milestones            │
  │                                                │
  │ ⚠️ /clear を実行してください                   │
  │    コンテキストがリフレッシュされ、            │
  │    動作が安定します。                          │
  └────────────────────────────────────────────────┘

禁止: 「報告して待つ」パターン
```

---

## ACTION_GUARDS（アクションベース制御）

```yaml
設計思想:
  - Edit/Write 時のみ playbook チェック
  - Read/Grep/WebSearch 等は常に許可
  - プロンプトの「意図」ではなく「アクション」を制御

⚠️ playbook なしで Edit/Write → ブロック
⚠️ 調査・報告は playbook なしでも可能
```

---

## CRITIQUE

```yaml
条件: phase 完了前に critic 必須
実行: Task(subagent_type="critic")
参照: .claude/rules/frameworks/done-criteria-validation.md
PASS → phase.status = done
FAIL → 修正 → 再実行
```

---

## CONTEXT（コンテキスト管理）

```yaml
真実源:
  - state.md / project.md / playbook が唯一の真実
  - チャット履歴に依存しない

いつ /clear するか:
  - playbook が完了したとき（★推奨★）
  - コンテキスト使用率が 80% を超えたとき

/clear 後の必須行動:
  1. INIT を最初からやり直す
  2. [自認] を再宣言する
```

---

## THINK（思考深化モード）

> **M023: ユーザーが「think」「ultrathink」を指示した場合の対応**

```yaml
think:
  トリガー: ユーザーが「think」を含むメッセージを送信
  効果: 通常より深く考え、複数の選択肢を検討
  用途:
    - 設計判断が必要な場合
    - トレードオフの分析
    - 複数のアプローチ比較

ultrathink:
  トリガー: ユーザーが「ultrathink」を含むメッセージを送信
  効果: 最大限の思考深度で分析
  用途:
    - 複雑なアーキテクチャ決定
    - 根本原因の徹底分析
    - 長期的影響の考慮
    - 報酬詐欺の可能性を自己検証

対応ルール:
  1. think/ultrathink 指示を受けたら、即座に実行開始
  2. 思考過程を明示的に出力する
  3. 複数の選択肢を列挙し、各メリット・デメリットを分析
  4. 最終的な推奨案を根拠と共に提示
  5. ultrathink の場合は「報酬詐欺をしていないか」を自問

禁止:
  - think/ultrathink 指示を無視して通常処理
  - 形式的な思考で終わらせる
  - 結論ありきの分析
```

---

## 禁止事項

```
❌ 確認を求める、許可を求める、選ばせる（安全上の例外を除く）
❌ done_criteria 確認なしで「完了しました」
❌ 保護対象ファイルを無断で編集
❌ playbook=null で Edit/Write を実行
❌ main ブランチで直接作業
❌ critic なしで phase を done にする（絶対禁止）
❌ ユーザーに聞かずに done_criteria を推測で定義する【報酬詐欺】
❌ pm SubAgent を経由せずに直接 playbook を作成する
❌ playbook 完了時に /clear を案内せずに次に進む
```

---

## 参照ドキュメント

```yaml
フォルダ管理:
  docs/folder-management.md: フォルダ配置ルール、テンポラリ/永続区分

テンポラリファイル:
  tmp/: 一時ファイル置き場（playbook 完了時に自動クリーンアップ）

システム構造（M027）:
  docs/repository-map.yaml:
    - hook_trigger_sequence: 公式ドキュメント準拠の Hook 発火順序
    - workflows: INIT/LOOP/POST_LOOP/CONSENT/CRITIQUE の組み合わせモジュール
```

---

## あるべき姿（SOLID原則に基づく設計）

> **各マイルストーンの本来の目的と、SOLID原則との対応を明示する。**

### SOLID原則の適用

```yaml
S - 単一責任原則 (SRP):
  適用対象: 各Hook、各SubAgent
  ルール: 1つのモジュールは1つの責任のみを持つ
  例:
    - init-guard.sh: 「必須ファイルRead強制」のみ
    - playbook-guard.sh: 「playbook存在チェック」のみ
    - consent-guard.sh: 「合意プロセス強制」のみ

O - 開放閉鎖原則 (OCP):
  適用対象: Hook システム全体
  ルール: 拡張に開いて、修正に閉じる
  例:
    - 新機能は新Hookとして追加、既存Hookを修正しない
    - settings.jsonへの登録で機能拡張

L - リスコフの置換原則 (LSP):
  適用対象: SubAgent
  ルール: 派生型は基底型と置換可能
  例:
    - 全SubAgentは同じ呼び出しインターフェースを持つ

I - インターフェース分離原則 (ISP):
  適用対象: Hook のトリガー
  ルール: クライアントに不要なインターフェースを強制しない
  例:
    - PreToolUse:Edit と PreToolUse:Bash は分離
    - matcher: "*" は避ける

D - 依存性逆転原則 (DIP):
  適用対象: Hook間の依存関係
  ルール: 高レベルモジュールは低レベルモジュールに依存しない
  例:
    - 共通スキーマ（state-schema.sh）を定義
    - 各Hookはスキーマを参照（ハードコード禁止）
```

### M015: フォルダ管理ルール検証テスト

```yaml
目的: tmp/と永続フォルダの分離を検証し、自動クリーンアップが確実に動作することを確認

あるべき姿:
  - tmp/ ディレクトリが存在し、.gitignore に登録されている
  - cleanup-hook.sh が playbook 完了時に tmp/ をクリーンする
  - 永続ファイル（docs/, .claude/）は削除されない
  - テストファイルを作成→削除のサイクルが動作確認済み

SOLID対応:
  - SRP: cleanup-hook.sh は「tmp/ クリーンアップ」のみの責任
  - OCP: 新しいテンポラリフォルダは .gitignore に追加するだけ

検証コマンド:
  - test -d tmp && grep -q 'tmp/' .gitignore
  - test -x .claude/hooks/cleanup-hook.sh
  - bash -n .claude/hooks/cleanup-hook.sh
```

### M016: リリース準備：自己認識システム完成

```yaml
目的: repository-map.yaml が全ファイルを正確にマッピングし、各コンポーネントの役割が明確になっている

あるべき姿:
  - repository-map.yaml の全 Hook に trigger が明示されている
  - SubAgents/Skills の description が完全（80文字で切れていない）
  - [理解確認] に失敗リスク分析が恒常的に組み込まれている
  - Hook 間の連鎖関係が docs/extension-system.md にドキュメント化

SOLID対応:
  - SRP: generate-repository-map.sh は「マッピング生成」のみの責任
  - ISP: 各Hook/SubAgent/Skill が独立した説明を持つ

検証コマンド:
  - grep -c 'trigger: unknown' docs/repository-map.yaml == 0
  - grep -q '[理解確認]' CLAUDE.md
  - grep -q 'risks' .claude/skills/consent-process/skill.md
```

### M017: 仕様遵守の構造的強制

```yaml
目的: 定義と実装の整合性を自動検証し、乖離を即座に検出・ブロックする

あるべき姿:
  - state.md のスキーマが .claude/schema/state-schema.sh で単一定義
  - 全 Hook がスキーマを source してハードコードなし
  - consistency-check.sh がセッション開始時に整合性を検証
  - 乖離検出時に exit 2 でブロック

SOLID対応:
  - DIP: 全 Hook が state-schema.sh に依存（低レベル詳細への依存を逆転）
  - SRP: consistency-check.sh は「整合性検証」のみの責任

検証コマンド:
  - test -f .claude/schema/state-schema.sh
  - source .claude/schema/state-schema.sh 2>/dev/null
  - grep -l 'source.*state-schema' .claude/hooks/*.sh | wc -l >= 10
```

### M018: id単位の3検証システム

```yaml
目的: 全 subtask に3つの検証（technical/consistency/completeness）を強制し、報酬詐欺を防止

あるべき姿:
  - subtask-guard.sh が存在し、subtask.status = done 変更をチェック
  - 3検証（technical/consistency/completeness）が全て PASS でなければブロック
  - playbook-format.md に validations セクションが追加されている
  - 新形式 playbook が自動生成可能

SOLID対応:
  - SRP: subtask-guard.sh は「subtask 検証」のみの責任
  - OCP: 新しい検証タイプは validations リストに追加するだけ

検証コマンド:
  - test -x .claude/hooks/subtask-guard.sh
  - grep -q 'technical.*consistency.*completeness' .claude/hooks/subtask-guard.sh
  - grep -q 'validations:' plan/template/playbook-format.md

【注意】M018 は status: pending のまま完了扱いにされていた（報酬詐欺）
```

### M019: playbook自己完結システム

```yaml
目的: playbook に tools/final_tasks を定義し、自動実行されるようにする

あるべき姿:
  - playbook に tools セクション（使用する Hook/SubAgent/Skill を明示）
  - playbook に final_tasks セクション（完了時の自動タスク）
  - archive-playbook.sh が final_tasks 完了をチェック
  - CLAUDE.md LOOP に tools/final_tasks 処理ロジックが追加

SOLID対応:
  - SRP: 各 tool は独自の責任を持つ
  - OCP: 新しい final_task はリストに追加するだけ

検証コマンド:
  - grep -q '## tools' plan/template/playbook-format.md
  - grep -q 'final_tasks' plan/template/playbook-format.md
  - grep -q 'final_tasks' .claude/hooks/archive-playbook.sh

【注意】M019 も検証が不十分だった
```

### M020: archive-playbook.sh バグ修正

```yaml
目的: アーカイブ先を正しく設定し、完了済み playbook を自動移動

あるべき姿:
  - archive-playbook.sh の ARCHIVE_DIR が plan/archive/ を指す
  - plan/active/ に完了済み playbook が残存しない
  - playbook 完了時に自動でアーカイブ提案

SOLID対応:
  - SRP: archive-playbook.sh は「アーカイブ提案」のみの責任

検証コマンド:
  - grep -q 'ARCHIVE_DIR.*plan/archive' .claude/hooks/archive-playbook.sh
  - ls plan/active/playbook-m01[4-9]*.md 2>/dev/null | wc -l == 0
```

### M021: init-guard.sh デッドロック修正

```yaml
目的: playbook=null 時でも基本 Bash コマンドをブロックしない

あるべき姿:
  - 基本コマンド（sed/grep/cat/echo/ls/wc/head/tail）が許可リストに含まれる
  - git コマンド（status/branch/log/diff/show）が許可される
  - session-start.sh に CORE ルールが含まれる
  - state.md 整合性チェックが system-health-check.sh で実行される

SOLID対応:
  - SRP: init-guard.sh は「必須ファイル Read 強制」のみの責任
    → playbook 強制は playbook-guard.sh に移譲すべき
  - ISP: 必要なコマンドのみ許可（不要なブロックをしない）

検証コマンド:
  - grep -q 'sed.*grep.*cat.*echo' .claude/hooks/init-guard.sh
  - grep -q 'git.*show' .claude/hooks/init-guard.sh
  - grep -q 'CORE' .claude/hooks/session-start.sh

【問題】現在の init-guard.sh は責任過多（SRP 違反）
  - 必須ファイル Read 強制
  - playbook 存在チェック
  - Bash コマンドフィルタリング
→ 分離が必要
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | V11: subtasks 構造対応。LOOP に executor 選択ガイドライン追加。旧形式（done_criteria リスト）との互換性維持。 |
| 2025-12-13 | V7.0: 3層構造（project→playbook→phase）の自動運用。用語統一（Macro廃止, layer廃止）。/clear タイミング明示。 |
| 2025-12-10 | V6.0: コンテキスト・アーキテクチャ再設計。 |
