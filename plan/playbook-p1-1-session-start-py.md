# playbook-p1-1-session-start-py.md

> **P1.1: session_start.py の実装**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/p1.1-session-start
created: 2025-12-23
issue: null
derives_from: P1.1
reviewed: true
roles:
  worker: codex
```

---

## goal

```yaml
summary: UserPromptSubmit Hook から呼ばれる session_start.py を実装する
done_when:
  - .claude/hooks/session_start.py が存在する
  - state.md の YAML frontmatter を解析できる
  - playbook.active の有無を判定できる
  - python3 -m py_compile でエラー 0
```

---

## phases

### p1: 要件分析と設計

**goal**: session_start.py の仕様を明確化する

#### subtasks

- [x] **p1.1**: 既存の session-start.sh の動作仕様が理解されている
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "session-start.sh の入出力形式を文書化" → PASS
    - consistency: "state.md の構造と一致していることを確認" → PASS
    - completeness: "全ての機能を網羅していることを確認" → PASS
  - result: 入力=stdin JSON, 処理=state.md更新+情報抽出, 出力=テキストメッセージ

- [x] **p1.2**: state.md の YAML frontmatter 構造が文書化されている
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "YAML frontmatter の形式を確認" → PASS
    - consistency: "state-schema.sh との整合性を確認" → PASS
    - completeness: "必要なフィールドが全て特定されている" → PASS
  - result: focus, playbook, goal, session, config の5セクション

- [x] **p1.3**: session_start.py の入出力仕様が定義されている
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "stdin/stdout/stderr の形式を定義" → PASS
    - consistency: "Claude Code Hook 仕様との整合性を確認" → PASS
    - completeness: "全てのエッジケースを考慮" → PASS
  - result: stdin=JSON, stdout=systemMessage/continue, 正規表現で解析

**status**: done
**max_iterations**: 5

---

### p2: 実装

**goal**: session_start.py を実装する

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: .claude/hooks/session_start.py が存在する
  - executor: worker
  - coding: true
  - validations:
    - technical: "test -f .claude/hooks/session_start.py でファイル存在確認" → PASS
    - consistency: "他の Python スクリプトと同じ構造であることを確認" → PASS
    - completeness: "必要な import 文が含まれていることを確認" → PASS (json, re, sys, pathlib)

- [x] **p2.2**: state.md の YAML frontmatter を解析する関数が実装されている
  - executor: worker
  - coding: true
  - validations:
    - technical: "parse_state_md() 関数が存在し、YAML を解析できる" → PASS
    - consistency: "state.md の実際の構造に対応していることを確認" → PASS
    - completeness: "全セクション（focus, playbook, goal）を解析できる" → PASS

- [x] **p2.3**: playbook.active の有無を判定する関数が実装されている
  - executor: worker
  - coding: true
  - validations:
    - technical: "build_message() 内で playbook.active を判定" → PASS
    - consistency: "null, 空文字, 有効なパスを正しく判定できる" → PASS
    - completeness: "playbook の有無に応じたメッセージを返す" → PASS

- [x] **p2.4**: メイン処理が実装されている
  - executor: worker
  - coding: true
  - validations:
    - technical: "main() 関数が存在し、Hook として呼び出し可能" → PASS
    - consistency: "stdin から JSON を読み取り、stdout に結果を出力" → PASS
    - completeness: "エラーハンドリングが含まれている" → PASS (try/except)

**status**: done
**max_iterations**: 10

---

### p3: 検証

**goal**: 実装が done_criteria を満たすことを検証する

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: python3 -m py_compile .claude/hooks/session_start.py が exit 0 で終了する
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "py_compile でシンタックスエラーがないことを確認" → PASS
    - consistency: "Python 3 の構文に準拠していることを確認" → PASS
    - completeness: "全てのコードパスがシンタックス的に正しい" → PASS

- [x] **p3.2**: state.md を解析して playbook.active を取得できる
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "python3 -c 'from session_start import ...' でインポート可能" → PASS
    - consistency: "実際の state.md を解析して正しい値を返す" → PASS
    - completeness: "playbook が null の場合も正しく判定できる" → PASS

- [x] **p3.3**: playbook の有無に応じたメッセージが出力される
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "playbook=null の場合、警告メッセージが出力される" → PASS
    - consistency: "playbook が存在する場合、playbook 情報が出力される" → PASS
    - completeness: "Hook の systemMessage 形式に準拠している" → PASS

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p3]

#### subtasks

- [x] **p_final.1**: .claude/hooks/session_start.py が存在する
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "test -f .claude/hooks/session_start.py && echo PASS" → PASS
    - consistency: "ファイルが Hook ディレクトリに配置されている" → PASS
    - completeness: "ファイルが空でなく、有効な Python コードを含む" → PASS (152行)

- [x] **p_final.2**: state.md の YAML frontmatter を解析できる
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "python3 -c で state.md を解析してエラーが発生しない" → PASS
    - consistency: "解析結果が state.md の内容と一致する" → PASS
    - completeness: "全セクションが正しく解析される" → PASS

- [x] **p_final.3**: playbook.active の有無を判定できる
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "playbook.active の値を正しく取得できる" → PASS
    - consistency: "null, 空文字, 有効なパスの判定が正しい" → PASS
    - completeness: "判定結果に基づくメッセージが適切" → PASS

- [x] **p_final.4**: python3 -m py_compile でエラー 0
  - executor: orchestrator
  - coding: false
  - validations:
    - technical: "python3 -m py_compile .claude/hooks/session_start.py が exit 0" → PASS
    - consistency: "全ての Python 構文が正しい" → PASS
    - completeness: "シンタックスエラーが 0 件" → PASS

- [x] **p_final.5**: playbook_reviewer による検証が PASS である
  - executor: reviewer
  - coding: false
  - validations:
    - technical: "reviewer SubAgent を呼び出し、PASS を取得" → PASS
    - consistency: "全ての done_when が満たされていることを確認" → PASS (4/4)
    - completeness: "レビュー指摘事項が 0 件または全て対応済み" → PASS

**status**: done
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-23 | 初版作成 |
