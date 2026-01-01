# playbook-orchestration-practice.md

> **複数言語オーケストレーション練習 - SubAgent + Codex + CodeRabbit の全機能検証**

---

## meta

```yaml
project: orchestration-practice
branch: feat/multi-language-orchestration-demo
created: 2026-01-01
issue: null
reviewed: true
roles:
  worker: codex
  reviewer: coderabbit
```

---

## goal

```yaml
summary: tmp フォルダで Python/TypeScript/Bash を組み合わせたプログラムを作成し、オーケストレーション機能を全て検証する
done_when:
  - tmp/run.sh を実行すると Python -> TypeScript の順で処理が行われ最終結果が出力される
  - codex executor で TypeScript 実装が行われた証跡がある
  - CodeRabbit によるコードレビューが完了している
```

---

## context

```yaml
5w1h:
  who: Claude Code + Codex + CodeRabbit（オーケストレーション検証）
  what: Python/TypeScript/Bash を組み合わせたパイプライン処理プログラムの作成
  when: 本セッション中
  where: tmp/ フォルダ内
  why: SubAgent + Codex + CodeRabbit の連携を実際に検証するため
  how: Bash が Python -> TypeScript の順で呼び出すパイプ連携方式

analysis_result:
  source: user-provided
  timestamp: 2026-01-01T23:30:00Z
  data:
    confirmed_scope:
      - 連携方式: パイプ連携（Bash が Python/TypeScript を呼び出す）
      - 検証範囲: SubAgent + Codex + CodeRabbit（全機能）
      - ブランチ: feat/multi-language-orchestration-demo（既に作成済み）
    risks:
      technical:
        - risk: "Node.js / Python ランタイムが未インストールの可能性"
          severity: low
          mitigation: "実行前に which python3 / which node で確認"
      scope:
        - risk: "練習目的のため本番用途は考慮しない"
          severity: low
          mitigation: "tmp/ 内に閉じて実装"

user_approved_understanding:
  source: user-provided
  approved_at: 2026-01-01T23:30:00Z
  summary: |
    - tmp フォルダ内で Python/TypeScript/Bash の組み合わせプログラムを作成
    - run.sh を実行すると Python -> TypeScript の順で処理
    - Codex で TypeScript を実装、CodeRabbit でレビュー
```

---

## phases

### p1: 基盤構築（Python + Bash）

**goal**: Python スクリプトと Bash オーケストレーターの基盤を作成する

#### subtasks

- [x] **p1.1**: tmp/process.py が存在し、stdin から JSON を読み込み加工して stdout に出力する
  - executor: claudecode
  - validations:
    - technical: "echo '{\"input\": \"hello\"}' | python3 tmp/process.py で JSON 出力を確認" ✓
    - consistency: "JSON フォーマットが後続の TypeScript で読み込み可能な形式" ✓
    - completeness: "エラーハンドリングが含まれている" ✓

- [x] **p1.2**: tmp/run.sh が存在し、実行権限があり、Python スクリプトを呼び出せる
  - executor: claudecode
  - validations:
    - technical: "bash tmp/run.sh で Python 部分が動作する" ✓
    - consistency: "シェバン #!/bin/bash が正しく設定されている" ✓
    - completeness: "set -euo pipefail でエラー時に停止する" ✓

**status**: done
**max_iterations**: 5

---

### p2: TypeScript 実装（Codex 委譲）

**goal**: Codex を使用して TypeScript 処理スクリプトを実装する

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: tmp/transform.ts が存在し、stdin から JSON を読み込み変換して stdout に出力する
  - executor: codex (via codex-delegate SubAgent)
  - evidence: Task(subagent_type='codex-delegate') で実装委譲、agentId: a06e567
  - validations:
    - technical: "echo '{\"processed\": true}' | npx ts-node tmp/transform.ts で JSON 出力を確認" ✓
    - consistency: "入力フォーマットが Python の出力と一致" ✓
    - completeness: "型定義が含まれている（PythonInput, TypeScriptOutput interface）" ✓

- [x] **p2.2**: tmp/run.sh が Python -> TypeScript のパイプライン処理を実行できる
  - executor: claudecode
  - validations:
    - technical: "bash tmp/run.sh でパイプライン全体が動作する" ✓
    - consistency: "Python 出力が TypeScript 入力として正しく渡される" ✓
    - completeness: "最終結果が stdout に出力される" ✓

**status**: done
**max_iterations**: 5

---

### p3: コードレビュー（CodeRabbit）

**goal**: CodeRabbit を使用してコードレビューを実施する

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: CodeRabbit によるコードレビューが実行されている
  - executor: coderabbit (via CodeRabbit CLI)
  - evidence: |
      - コマンド: coderabbit review --plain --base main
      - 結果: "Review completed ✔"（指摘なし）
      - commit: 4fb161b (tmp/ ファイルを -f で強制追加)
  - validations:
    - technical: "coderabbit review の実行ログが存在する" ✓
    - consistency: "レビュー対象ファイルが tmp/ 内のファイルを含む" ✓
    - completeness: "重大な問題がない、または対応済み" ✓

- [x] **p3.2**: レビュー指摘事項が対応済み、または軽微な指摘のみである
  - executor: claudecode
  - evidence: |
      - 事前レビュー（general-purpose agent）で Major 指摘 2 件を検出・修正済み
      - run.sh: echo -> printf '%s'（コマンドインジェクション対策）
      - transform.ts: オプショナルチェーン + Unicode 対応
      - CodeRabbit CLI 実行時は指摘なし
  - validations:
    - technical: "レビュー結果の確認（指摘事項リスト）" ✓
    - consistency: "指摘事項と修正内容の対応" ✓
    - completeness: "未対応の重大な指摘がない" ✓

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p3]

#### subtasks

- [x] **p_final.1**: tmp/run.sh を実行すると Python -> TypeScript の順で処理が行われ最終結果が出力される
  - executor: claudecode
  - evidence: |
      bash tmp/run.sh '{"input": "hello world"}' 実行結果:
      - Step 1: Python processor (processed_by: "python", step: 1)
      - Step 2: TypeScript transformer (processed_by: "typescript", step: 2)
      - 最終出力: JSON with reversed_input, input_length
  - validations:
    - technical: "bash tmp/run.sh を実行し、JSON 出力を確認" ✓
    - consistency: "Python 処理結果が TypeScript に渡され、最終変換されている" ✓
    - completeness: "エラーなく最終結果が得られる" ✓

- [x] **p_final.2**: codex executor で TypeScript 実装が行われた証跡がある
  - executor: claudecode
  - evidence: |
      - p2.1 で Task(subagent_type='codex-delegate') を使用
      - agentId: a06e567
      - tmp/transform.ts: PythonInput/TypeScriptOutput interface 定義あり
  - validations:
    - technical: "p2.1 の executor が codex で完了している" ✓
    - consistency: "tmp/transform.ts のコードが存在する" ✓
    - completeness: "Codex による実装履歴が playbook に記録されている" ✓

- [x] **p_final.3**: CodeRabbit によるコードレビューが完了している
  - executor: claudecode
  - evidence: |
      - p3.1 で coderabbit review --plain --base main を実行
      - 結果: "Review completed ✔"
      - Major 指摘は事前修正済み
  - validations:
    - technical: "p3.1 の executor が coderabbit で完了している" ✓
    - consistency: "レビュー結果が playbook に記録されている" ✓
    - completeness: "重大な指摘がない、または対応済み" ✓

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done (tmp/ は .gitignore のため map 対象外)

- [x] **ft2**: tmp/ 内の一時ファイルを保持（練習成果物として）
  - command: `echo "練習成果物として tmp/ 内ファイルを保持"`
  - status: done
  - note: git add -f で強制追加済み、commit 4fb161b

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done
  - commits:
    - 4fb161b: feat: add multi-language pipeline demo files
