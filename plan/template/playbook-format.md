# playbook-{project}.md

> **このテンプレートを埋めて playbook を作成する。**
>
> 詳細な記述方法は planning-rules.md を参照。
> 具体例は playbook-examples.md を参照。

---

## meta

```yaml
project: {プロジェクト名}
branch: {type}/{description}  # feat/xxx, fix/xxx, refactor/xxx, docs/xxx
created: {作成日}
issue: {Issue 番号 or null}
derives_from: {project.done_when の id}  # 例: DW-001
reviewed: false  # reviewer SubAgent による検証済みフラグ
```

> **branch フィールド**: playbook とブランチは 1:1 で紐づく。
> **derives_from フィールド**: この playbook が対応する project.done_when の ID。
> 計画の連鎖（project → playbook）を追跡可能にする。

---

## playbook 導出ガイド

> **project.done_when から playbook を作成する手順**

```yaml
手順:
  1. project.md の not_achieved を確認
  2. depends_on を分析し、着手可能な done_when を特定
  3. priority で優先順位を決定
  4. 選択した done_when の decomposition を読み込み
  5. 以下を変換:
     - derives_from: done_when.id
     - goal.summary: decomposition.playbook_summary
     - goal.done_when: decomposition.success_indicators
     - phases: decomposition.phase_hints を展開

phase_hints → phases 変換ルール:
  phase_hints[i] を以下の Phase に変換:
    id: p{i}
    name: phase_hints[i].name
    goal: phase_hints[i].what
    done_criteria: # success_indicators から導出、または Claude が具体化
    test_method: # Claude が具体化
    status: pending

例:
  # project.md の decomposition
  decomposition:
    playbook_summary: setup フローの検証と改善
    phase_hints:
      - name: 現状分析
        what: setup/playbook-setup.md を読み、構造を理解
    success_indicators:
      - setup が Phase 8 まで完了する

  # 導出された playbook
  meta:
    derives_from: DW-001
  goal:
    summary: setup フローの検証と改善
    done_when:
      - setup が Phase 8 まで完了する
  phases:
    - id: p0
      name: 現状分析
      goal: setup/playbook-setup.md を読み、構造を理解
```

---

## goal

```yaml
summary: {1行の目標}
done_when:
  - {最終完了条件1}
  - {最終完了条件2}
```

---

## phases

> **V12: チェックボックス形式を導入。報酬詐欺防止のため `- [ ]` / `- [x]` で進捗を明示。**

### p1: {フェーズ名}

**goal**: {このフェーズの目標}

#### subtasks

- [ ] **p1.1**: {対象} が {状態} である
  - executor: claudecode | codex | coderabbit | user
  - test_command: `{検証コマンド}`
  - validations:
    - technical: "{技術的に正しく動作するか}"
    - consistency: "{他コンポーネントと整合性があるか}"
    - completeness: "{必要な変更が全て完了しているか}"

- [ ] **p1.2**: {コマンド} が {期待結果} を返す
  - executor: claudecode
  - test_command: `{コマンド} && echo PASS || echo FAIL`
  - validations:
    - technical: "{...}"
    - consistency: "{...}"
    - completeness: "{...}"

- [ ] **p1.3**: ユーザーが {操作} を完了している
  - executor: user
  - test_command: `手動確認: {具体的な確認手順}`
  - validations:
    - technical: "{...}"
    - consistency: "{...}"
    - completeness: "{...}"

**status**: pending | in_progress | done
**max_iterations**: 5

---

### p2: {フェーズ名}

**goal**: {このフェーズの目標}
**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: {前提条件} が満たされている
  - executor: claudecode
  - test_command: `test -f {path} && echo PASS`
  - validations:
    - technical: "{...}"
    - consistency: "{...}"
    - completeness: "{...}"

**status**: pending

---

### チェックボックス完了時の記法

```markdown
# 完了した subtask（- [x] に変更 + validated タイムスタンプ追加）
- [x] **p1.1**: README.md が存在する ✓
  - executor: claudecode
  - test_command: `test -f README.md && echo PASS`
  - validations:
    - technical: "PASS - ファイルが存在する"
    - consistency: "PASS - 他ドキュメントと整合"
    - completeness: "PASS - 内容が完全"
  - validated: 2025-12-17T02:30:00
```

> **重要**: `- [ ]` → `- [x]` の変更は subtask-guard.sh がチェック。
> validations の 3 点全てが PASS でなければ `[x]` への変更はブロックされる。

### subtask 構造（V12: チェックボックス形式）

```markdown
- [ ] **p{N}.{M}**: {criterion}
  - executor: claudecode | codex | coderabbit | user
  - test_command: `{PASS/FAIL を返すコマンド}`
  - validations:
    - technical: "{技術的検証}"
    - consistency: "{整合性検証}"
    - completeness: "{完全性検証}"
  - depends_on: [p1.2]  # オプション
```

### 必須フィールド

| フィールド | 説明 |
|-----------|------|
| `- [ ]` / `- [x]` | チェックボックス（未完了/完了） |
| `**p{N}.{M}**` | subtask ID（太字） |
| criterion | 検証可能な完了条件（`:` の後に記述） |
| executor | 実行者（claudecode / codex / coderabbit / user） |
| test_command | PASS/FAIL を返す検証コマンド |
| validations | 3 点検証（technical / consistency / completeness） |

### 完了時の追加フィールド

| フィールド | 説明 |
|-----------|------|
| validated | 検証完了日時（ISO 8601 形式） |

### 旧形式との比較

```markdown
# V11 形式（廃止）
- id: p1.1
  criterion: "README.md が存在する"
  executor: claudecode
  test_command: "test -f README.md && echo PASS"
  status: PASS  # ← 報酬詐欺が容易

# V12 形式（現行）
- [x] **p1.1**: README.md が存在する ✓
  - executor: claudecode
  - test_command: `test -f README.md && echo PASS`
  - validations:
    - technical: "PASS - ファイルが存在する"
    - consistency: "PASS - .gitignore と整合"
    - completeness: "PASS - 内容が完全"
  - validated: 2025-12-17T02:30:00
```

> **報酬詐欺防止**: `- [ ]` → `- [x]` の変更は subtask-guard.sh がチェック。
> チェックボックスの変更は Edit ツールで追跡可能。

---

## Phase 記述ルール（V12）

### Phase 必須項目

| 項目 | 形式 | 説明 |
|------|------|------|
| `### p{N}: {name}` | Markdown 見出し | Phase 識別子 + フェーズ名 |
| `**goal**` | 太字 | このフェーズの目標（1行） |
| `#### subtasks` | 小見出し | subtask リストの開始 |
| `- [ ]` / `- [x]` | チェックボックス | subtask（後述） |
| `**status**` | 太字 | 状態（pending / in_progress / done） |

### subtask 必須フィールド（チェックボックス形式）

| 項目 | 説明 |
|------|------|
| `- [ ]` / `- [x]` | チェックボックス（未完了/完了） |
| `**p{N}.{M}**` | subtask ID（太字、行頭に配置） |
| criterion | `:` の後に検証可能な完了条件（1文） |
| executor | claudecode / codex / coderabbit / user |
| test_command | PASS/FAIL を返す検証コマンド（バッククォートで囲む） |
| validations | 3 点検証（technical / consistency / completeness） |

### オプション項目

| 項目 | 説明 |
|------|------|
| depends_on | 依存する Phase または subtask の id リスト |
| prerequisites | 前提条件（環境、ツールなど） |
| max_iterations | **推奨**: LOOP 回数上限（デフォルト: 10）。デッドロック防止 |
| time_limit | **推奨**: 想定作業時間（例: 30min, 1h）。超過時は警告 |
| priority | **推奨**: 優先度（high / medium / low）。LLM が実行順序を判断 |
| notes | 補足情報 |

### 計画管理フィールドの使い方

```yaml
# タイムボックス機能（task-01）
time_limit: 30min  # 超過時は LLM が [自認] で警告を表示

# 優先順位管理（task-02）
priority: high  # high > medium > low の順で実行を優先

# 依存関係管理（task-03）
depends_on: [p1, p2]  # 依存 Phase が未完了なら実行不可
```

**LLM の行動ルール**:
- `time_limit` 超過 → 「Phase {id} の想定時間を超過しています」と警告
- `priority: high` → 他の Phase より優先して実行
- `depends_on` 未完了 → 「依存 Phase {ids} が未完了です」と警告し実行しない

---

## test_command パターン集

> **V11: criterion ごとに test_command を紐付け。以下のパターンを参照。**

```yaml
# ファイル存在チェック
test_command: "test -f {path} && echo PASS || echo FAIL"
test_command: "test -d {dir} && echo PASS || echo FAIL"

# ファイル内容チェック
test_command: "grep -q '{pattern}' {file} && echo PASS || echo FAIL"
test_command: "grep -c '{pattern}' {file} | awk '{if($1>={N}) print \"PASS\"; else print \"FAIL\"}'"

# コマンド実行結果
test_command: "{command} && echo PASS || echo FAIL"
test_command: "{command}; [ $? -eq 0 ] && echo PASS || echo FAIL"

# 数値比較
test_command: "wc -l {file} | awk '{if($1>={N}) print \"PASS\"; else print \"FAIL\"}'"
test_command: "[ $(expr) -ge {N} ] && echo PASS || echo FAIL"

# HTTP ステータス
test_command: "curl -s -o /dev/null -w '%{http_code}' {url} | grep -q '200' && echo PASS || echo FAIL"

# 複数条件
test_command: |
  test -f {file1} && \
  grep -q '{pattern}' {file2} && \
  echo PASS || echo FAIL

# 手動確認（executor: user の場合）
test_command: "手動確認: {具体的な確認手順を記述}"
```

### executor 別 test_command 例

```yaml
claudecode:
  - "test -f docs/readme.md && echo PASS"
  - "grep -q 'subtasks:' plan/playbook-*.md && echo PASS"
  - "wc -l {file} | awk '{if($1>=50) print \"PASS\"}'"

codex:
  - "npm test && echo PASS"
  - "pytest {path} && echo PASS"
  - "go test ./... && echo PASS"

coderabbit:
  - "cr review --check && echo PASS"
  - "手動確認: CodeRabbit の PR コメントに重大な指摘がないこと"

user:
  - "手動確認: Vercel ダッシュボードでデプロイ成功を確認"
  - "手動確認: API キーが環境変数に設定されていること"
```

---

## criterion 記述ガイド

> **V11: criterion は subtask の一部。test_command と 1:1 で対応。**

```yaml
良い criterion（検証可能）:
  - "README.md が存在する"
    → test_command: "test -f README.md && echo PASS"
  - "npm test が exit code 0 で終了する"
    → test_command: "npm test && echo PASS"
  - "http://localhost:3000 が 200 を返す"
    → test_command: "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000 | grep '200'"
  - "禁止パターンが15個以上列挙されている"
    → test_command: "grep -c '^- ' {file} | awk '{if($1>=15) print \"PASS\"}'"

悪い criterion（曖昧・検証不可）:
  - "ドキュメントを書く" ← 何を、どこに？
  - "テストする" ← 何を、どうテスト？
  - "完成させる" ← 完成の定義は？
  - "適切に設定する" ← 「適切」とは？
  - "正しく動作する" ← 「正しく」とは？
  - "確認する" ← アクションであり状態でない

⚠️ 禁止パターン（docs/criterion-validation-rules.md 参照）:
  - 動詞で終わる（「〜する」「〜した」）
  - 曖昧な形容詞（「適切」「正しく」「良い」）
  - 検証方法が不明（test_command が書けない）
```

---

## executor 判定ガイド

```yaml
executor の種類:
  claudecode:
    説明: Claude Code が直接実行（デフォルト）
    用途:
      - 自然言語タスク（ドキュメント、設計、計画）
      - 軽量なコード修正
      - ファイル操作
      - コマンド実行
    config: なし

  codex:
    説明: Codex CLI（Bash 経由）でコード生成
    用途:
      - 本格的なコード実装
      - 複雑なロジック
      - 大規模なリファクタリング
    config:
      model: gpt-5.1-codex  # オプション
      reasoning: medium     # minimal | low | medium | high

  coderabbit:
    説明: CodeRabbit CLI でコードレビュー
    用途:
      - PR 前のコードレビュー
      - セキュリティ・品質チェック
    config:
      type: uncommitted    # all | committed | uncommitted
      base: main           # 比較ベースブランチ

  user:
    説明: CLI 外の手動作業
    用途:
      - 外部サービス登録（Vercel, GCP, Stripe）
      - API キー取得
      - 意思決定
      - 支払い情報入力
    config:
      instruction: "具体的な操作手順"

キーワード判定:
  - "レビュー" "品質チェック" → coderabbit
  - "登録" "サインアップ" "契約" → user
  - "API キー" "シークレット" → user
  - "選んでください" → user
  - 本格的なコード実装 → codex
  - それ以外 → claudecode

Phase 記述例:
  - id: p1
    name: 認証機能実装
    executor: codex
    executor_config:
      model: gpt-5.1-codex
      reasoning: high
    done_criteria:
      - auth.ts が存在する
      - npm test が通る

  - id: p2
    name: コードレビュー
    executor: coderabbit
    executor_config:
      type: uncommitted
    done_criteria:
      - CodeRabbit が PASS

  - id: p3
    name: Vercel デプロイ設定
    executor: user
    executor_config:
      instruction: |
        1. Vercel ダッシュボードにログイン
        2. 環境変数を設定
        3. Deploy ボタンをクリック
    done_criteria:
      - デプロイ URL が 200 を返す
```

---

## executor: user の完了確認ガイド

> **user が実行する Phase は「自己申告」に依存するため、完了確認を強化する**

### 完了確認のフロー

```yaml
LLM の行動:
  1. 「次は〇〇を行ってください」と案内
  2. 具体的な手順をリスト形式で提示
  3. 「完了したらお知らせください」と依頼
  4. ユーザーが「完了」と報告
  5. 【重要】done_criteria をチェックリスト形式で確認
  6. 全て確認 → Phase 完了

確認例（デプロイの場合）:
  LLM: 「以下を確認させてください：
    - [ ] Vercel にサインアップ済みですか？
    - [ ] 環境変数（OPENAI_API_KEY）を設定しましたか？
    - [ ] デプロイ URL にアクセスして動作確認しましたか？」
```

### 自動検証可能な場合

```yaml
検証可能な done_criteria:
  - URL にアクセスして 200 が返る
    → LLM が curl で確認可能
  - 環境変数が設定されている
    → LLM が確認不可（ユーザーに確認を依頼）

検証方法の記載例:
  done_criteria:
    - デプロイ URL が 200 を返す
  test_method: |
    curl -I {url} でステータスコードを確認
    または LLM が WebFetch で確認
```

### 自動検証不可の場合

```yaml
ユーザーに明示的な確認を求める:
  - 「〇〇を完了しましたか？」と YES/NO で聞く
  - 複数項目がある場合はチェックリスト形式

禁止事項:
  - ユーザーが「完了」と言っただけで Phase を done にする
  - 確認なしで次の Phase に進む
```

---

## ダブルチェック機能（Phase 完了前必須）

> **Phase を done にする前に、必ず以下のチェックを実行すること。**
> **これは自己報酬詐欺を防止するための構造的強制である。**

### pre_done_checklist

```yaml
# Phase を done にする前の必須チェックリスト
pre_done_checklist:
  evidence_check:
    - [ ] done_criteria の全項目に「証拠」を示せるか?
    - [ ] 証拠は「コマンド実行結果」または「ファイル引用」か?
    - [ ] 「満たしている気がする」で判定していないか?
    - [ ] 「設定した」ではなく「動作確認した」か?

  critic_check:
    - [ ] critic エージェントを呼び出したか?
    - [ ] critic が PASS を返したか?
    - [ ] critic が指摘した問題を全て解決したか?

  test_execution:
    - [ ] playbook の test_method を実際に実行したか?
    - [ ] test_method の期待結果と一致したか?
    - [ ] エッジケースを考慮したか?
```

### 自己報酬詐欺の検出パターン

```yaml
# 以下の症状がある場合、報酬詐欺の可能性が高い
fraud_symptoms:
  language_patterns:
    - 「〇〇した」だけで証拠なし
    - 「〇〇のはず」「〇〇だと思う」
    - 「シミュレーションでは...」（実行なし）
    - 「設計上は...」（動作確認なし）

  behavior_patterns:
    - done_criteria の一部のみ確認
    - critic を呼び出さずに done 判定
    - test_method を実行せずに PASS
    - 机上の検討のみで実装完了と主張

  action_on_detection:
    1. 即座に critic エージェントを呼び出す
    2. 不足している証拠を収集
    3. 問題を修正してから再判定
```

### ダブルチェック実行フロー

```yaml
# Phase 完了判定時の必須フロー
double_check_flow:
  step_1:
    name: 自己評価
    action: done_criteria を1つずつ確認し、証拠を列挙

  step_2:
    name: critic 呼び出し（必須）
    action: |
      Task(subagent_type="critic"):
        評価対象: 全 done_criteria
        判定: PASS/FAIL（証拠ベース）

  step_3:
    name: critic 結果の処理
    if_pass: Phase を done に更新
    if_fail: 問題を修正 → step_1 に戻る

  step_4:
    name: 最終確認
    action: |
      LLM の自問:
        - 「本当に終わったか?」
        - 「ユーザーが見たら満足するか?」
        - 「証拠なしで完了と言っていないか?」
```

### playbook への統合

```yaml
# playbook 作成時、各 Phase に以下を含める（推奨）
- id: p1
  name: {フェーズ名}
  done_criteria:
    - {完了条件}
    - 実際に動作確認済み（test_method 実行）
  test_method: |
    1. {検証手順}
  double_check: true  # ← ダブルチェック必須フラグ（デフォルト true）
  status: pending
```

### 強制メカニズム

```yaml
# ダブルチェックを強制するための仕組み
enforcement:
  claude_md_rule:
    location: CLAUDE.md LOOP セクション
    content: |
      全て PASS?
        - YES → CRITIQUE() を実行
          - CRITIQUE pass → state.md更新 → 次のPhaseへ
          - CRITIQUE fail → 問題を修正 → continue

  critic_agent:
    trigger: done 判定前に自動委譲
    model: haiku（軽量・高速）
    output: PASS/FAIL + 証拠

  check_coherence:
    trigger: git commit 前
    action: state.md と playbook の整合性チェック
```

---

## 中間成果物の処理

> **Phase の evidence として一時的に作成するファイルの管理ルール**

### 中間成果物とは

```yaml
定義: 最終的に他のファイルに統合され、単独では参照されなくなるファイル

例:
  - phase-*.md（Phase ごとの分析結果）
  - draft-*.md（下書き）
  - analysis-*.md（分析結果）
  - temp-*.md（一時ファイル）

対照的に「最終成果物」:
  - docs/*.md（統合されたドキュメント）
  - .claude/hooks/*.sh（実装されたスクリプト）
  - plan/playbook-*.md（進行中の playbook）
```

### 判定フローチャート

```
ファイル作成時の判定:
                    ┌─────────────────┐
                    │ ファイル作成    │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ 他のファイルに   │
                    │ 統合されるか？   │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │ YES          │ NO           │
              ▼              ▼              │
    ┌─────────────────┐  ┌─────────────────┐
    │ 中間成果物      │  │ 最終成果物      │
    │ → 統合後削除    │  │ → 保持         │
    └─────────────────┘  └─────────────────┘
```

### playbook 作成時のルール

```yaml
中間成果物を作成する Phase がある場合:
  1. 最終 Phase に「クリーンアップ」を含める
  2. クリーンアップの done_criteria:
     - 「中間成果物が最終成果物に統合されている」
     - 「中間成果物が削除されている」

推奨パターン:
  - 可能な限り中間成果物を作成せず、既存ファイルに追記する
  - 中間成果物が必要な場合、ファイル名に「draft-」または「temp-」プレフィックスを付ける

悪い例:
  - Phase 1-7 で phase-*.md を作成 → Phase 8 で統合 → phase-*.md が残存

良い例:
  - Phase 1-7 で既存の docs/*.md に直接追記
  - または Phase 8 の done_criteria に「phase-*.md が削除されている」を含める
```

### 参照ドキュメント

- docs/file-creation-process-design.md - 詳細な設計ドキュメント

---

## テンポラリファイルとクリーンアップ

> **playbook 実行中に生成する一時ファイルの管理ルール**

### tmp/ フォルダの使用

```yaml
用途:
  - テスト結果・シナリオ
  - 一時的な分析ファイル
  - デバッグ出力
  - 中間成果物（後で削除予定のもの）

配置例:
  - tmp/test-results.md
  - tmp/analysis-draft.md
  - tmp/debug-output.log

注意:
  - tmp/ は .gitignore に登録されており、git に追跡されない
  - 重要なファイルは tmp/ に置かない
  - 永続化が必要な場合は docs/ または .archive/ に移動
```

### 自動クリーンアップ

```yaml
トリガー:
  - playbook の全 Phase が done になったとき

実行内容:
  - tmp/ 内のファイルを自動削除
  - tmp/CLAUDE.md と tmp/README.md は保持

実装:
  - .claude/hooks/cleanup-hook.sh が PostToolUse:Edit で発火
  - archive-playbook.sh と同様のロジックで playbook 完了を検出
```

### playbook 設計時の考慮

```yaml
推奨:
  - 一時ファイルは必ず tmp/ に配置
  - 中間成果物も tmp/ を使用（最終的に削除されるため）
  - 永続化が必要なファイルは最初から docs/ に配置

禁止:
  - ルート直下に一時ファイルを作成
  - docs/ に中間成果物を作成（後で削除が必要になる）
```

### 参照ドキュメント

- tmp/CLAUDE.md - tmp/ フォルダの役割説明
- docs/folder-management.md - フォルダ管理ルール全般

---

## validations

> **M018: subtask 完了時の 3 検証（technical/consistency/completeness）**

```yaml
validations:
  technical:
    description: 技術的に正しく動作するか
    method: test_command の実行結果が PASS を返す
    examples:
      - bash -n {script} でシンタックスエラーがない
      - npm test が exit 0 で終了する
      - curl が期待する HTTP ステータスを返す

  consistency:
    description: 他のコンポーネントと整合性があるか
    method: 関連ファイルとの整合性チェック
    examples:
      - state.md と playbook の状態が一致
      - settings.json に Hook が登録されている
      - schema 定義と実装が一致

  completeness:
    description: 必要な変更が全て完了しているか
    method: done_criteria の全項目が満たされている
    examples:
      - 関連ドキュメントが更新されている
      - 必要なファイルが全て作成されている
      - 依存コンポーネントも修正されている
```

### 検証タイミング

```yaml
when_to_validate:
  - subtask.status を done に変更する前
  - phase.status を done に変更する前
  - playbook アーカイブ前

enforcement:
  hook: subtask-guard.sh
  trigger: PreToolUse:Edit (playbook ファイル)
  action: status: done への変更時に警告を表示
```

### 検証のバイパス条件

```yaml
bypass_conditions:
  - admin モード（security: admin）
  - 緊急修正（emergency_fix フラグ）

bypass_audit:
  - バイパス理由を commit message に記載
  - 後から検証を実行することを明示
```

---

## p_final: 完了検証フェーズ（必須）

> **M056: playbook 完了時に done_when が実際に満たされているか自動検証する**
>
> **このフェーズは全 playbook に必須。スキップは報酬詐欺とみなされる。**

### p_final の目的

```yaml
目的: |
  playbook の done_when が「本当に満たされているか」を自動検証。
  「ロジックがある」ではなく「実際に動作する」を確認する。
  報酬詐欺（done_when 未達成で achieved）を構造的に防止。

問題背景:
  - M014 等が achieved だが done_when が実際には満たされていなかった
  - test_command で「存在チェック」だけでは不十分
  - 「実際の動作確認」（end-to-end テスト）が必須

解決策:
  - playbook 最終フェーズとして p_final を必須化
  - done_when の各項目に test_command を定義
  - 全 PASS でなければアーカイブ不可
```

### p_final の構造

```yaml
### p_final: 完了検証（必須）

> **playbook の done_when が全て満たされているか最終検証**

#### subtasks

- id: p_final.1
  criterion: "done_when 項目1 が実際に満たされている"
  executor: claudecode
  test_command: "{done_when 項目1 の検証コマンド}"
  validations:
    technical: "検証コマンドが正常に実行できる"
    consistency: "test_command の結果が実際の状態と一致"
    completeness: "関連する全てのファイル/機能が含まれている"

- id: p_final.2
  criterion: "done_when 項目2 が実際に満たされている"
  executor: claudecode
  test_command: "{done_when 項目2 の検証コマンド}"
  validations:
    technical: "検証コマンドが正常に実行できる"
    consistency: "test_command の結果が実際の状態と一致"
    completeness: "関連する全てのファイル/機能が含まれている"

# done_when の項目数だけ繰り返す

status: pending
max_iterations: 3
```

### p_final テンプレート例

```yaml
# 例: M055 の p_final（機能重要度マップと保護システム）
### p_final: 完了検証

#### subtasks

- id: p_final.1
  criterion: "docs/feature-priority-map.md が存在し、critical 機能が 5 個以上定義されている"
  executor: claudecode
  test_command: |
    test -f docs/feature-priority-map.md && \
    grep -c 'priority: critical' docs/feature-priority-map.md | awk '{if($1>=5) print "PASS"; else print "FAIL"}'
  validations:
    technical: "ファイルが存在し、grep コマンドが正常に動作する"
    consistency: "critical 機能の数が feature-priority-map.md の定義と一致"
    completeness: "全ての重要機能が critical に分類されている"

- id: p_final.2
  criterion: "セッション開始時に critical 機能一覧が実際に表示される"
  executor: claudecode
  test_command: |
    echo '{"trigger":"startup"}' | bash .claude/hooks/session-start.sh 2>&1 | \
    grep -q '保護すべき' && echo PASS || echo FAIL
  validations:
    technical: "session-start.sh が正常に実行できる"
    consistency: "表示される機能一覧が feature-priority-map.md と一致"
    completeness: "全 critical 機能が表示される"

status: pending
```

### p_final 実装ガイド

```yaml
手順:
  1. playbook の goal.done_when を確認
  2. 各 done_when 項目に対応する p_final.{N} subtask を作成
  3. test_command は「存在チェック」ではなく「実際の動作確認」を使用
  4. validations に technical/consistency/completeness を必ず含める
  5. p_final が全 PASS → final_tasks 実行 → アーカイブ可能

done_when の再検証ポイント:
  - 「〇〇が存在する」→「〇〇が存在し、期待する内容を含む」
  - 「〇〇が動作する」→「〇〇を実行して期待する出力を得る」
  - 「〇〇が設定されている」→「〇〇を参照して値を確認する」

禁止パターン:
  - test -f {file} だけで PASS（存在するが壊れている可能性）
  - grep -q {pattern} だけで PASS（パターンはあるが動作しない可能性）
  - 手動確認だけに依存（自動検証可能なら自動化必須）

推奨パターン:
  - 実際にコマンドを実行して出力を確認
  - 複数条件を && で連結して全て満たすことを確認
  - エラー出力も含めて検証（2>&1 | grep ...）
```

### p_final の強制メカニズム

```yaml
enforcement:
  archive_playbook_sh:
    - p_final Phase が存在しない playbook → 警告を表示
    - p_final.status != done → アーカイブをブロック
    - done_when の項目数と p_final subtask 数の不一致 → 警告

  pm_subagent:
    - 新規 playbook 作成時に p_final を自動追加
    - done_when から p_final subtasks を自動生成

  critic_subagent:
    - p_final の検証結果を確認
    - 「存在チェックのみ」のパターンを検出して警告
```

---

## final_tasks

> **M019: playbook 自己完結システム - アーカイブ前の必須チェック**
>
> **V12 形式**: チェックボックス `- [ ]` / `- [x]` で進捗管理

### final_tasks 記法（V12）

```markdown
## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'CLAUDE.md' ! -name 'README.md' -delete`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending
```

### 完了時の記法

```markdown
- [x] **ft1**: repository-map.yaml を更新する ✓
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done
  - executed: 2025-12-17T05:00:00
```

### final_tasks の役割

```yaml
目的: |
  playbook アーカイブ前に必須のクリーンアップを強制。
  archive-playbook.sh が final_tasks の完了をチェック。

チェックタイミング:
  - archive-playbook.sh が PostToolUse:Edit で発火
  - 全 phase が done の場合に final_tasks をチェック
  - 未完了の final_tasks がある場合はアーカイブをブロック

V12 検出パターン:
  - セクション: `## final_tasks`
  - 未完了: `- [ ] **ft`
  - 完了: `- [x] **ft`

status 更新:
  - 各タスク実行後に `- [ ]` → `- [x]` に変更
  - status: pending → status: done に変更
  - executed タイムスタンプを追加
```

### 標準 final_tasks

```markdown
## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'CLAUDE.md' ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-17 | V14: final_tasks を V12 チェックボックス形式に統一。archive-playbook.sh と整合。 |
| 2025-12-14 | V13: final_tasks セクション追加。M019 playbook自己完結システム対応。 |
| 2025-12-14 | V12: validations セクション追加。M018 3検証システム対応。 |
| 2025-12-13 | V11: subtasks 構造を導入。criterion + executor + test_command を1セット化。test_command パターン集追加。 |
| 2025-12-09 | V10: 中間成果物の処理セクションを追加。stray files 防止。 |
| 2025-12-08 | V9: derives_from と playbook 導出ガイドを追加。計画の連鎖対応。 |
| 2025-12-08 | V8: executor を拡張（claudecode/codex/coderabbit/user）。executor_config 追加。 |
| 2025-12-08 | V7: max_iterations フィールド追加。デッドロック防止。 |
| 2025-12-02 | V6: ダブルチェック機能追加。自己報酬詐欺防止の構造的強制。 |
| 2025-12-01 | V5: executor:user 完了確認ガイドを追加。 |
| 2025-12-01 | V4: branch フィールド追加。playbook とブランチの 1:1 紐づけ。 |
| 2025-12-01 | V3: タイプ別分類を削除。純粋なフォーマット定義に。 |
| 2025-12-01 | V2: タイプ別最小構造に再設計。 |
| 2025-12-01 | V1: 初版。 |
