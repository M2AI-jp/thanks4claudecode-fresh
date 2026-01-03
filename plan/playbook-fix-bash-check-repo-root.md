# playbook-fix-bash-check-repo-root.md

## meta

```yaml
project: fix-bash-check-repo-root
branch: fix/bash-check-repo-root
created: 2026-01-03
issue: null
reviewed: true
roles:
  worker: claudecode  # 1行修正のため claudecode で十分
```

---

## goal

```yaml
summary: bash-check.sh の REPO_ROOT パス計算を 2 階層から 4 階層に修正
done_when:
  - bash-check.sh の REPO_ROOT が 4 階層上（リポジトリルート）を指している
  - bash -n bash-check.sh が成功する（構文エラーなし）
  - contract.sh が正しく source できるパスになっている
```

---

## context

```yaml
5w1h:
  who: Claude Code（claudecode executor）
  what: bash-check.sh の REPO_ROOT パス計算を修正
  when: 即時対応（P0 緊急修復）
  where: .claude/skills/access-control/guards/bash-check.sh 行 15
  why: 現在の 2 階層では contract.sh を参照できない
  how: "../.." を "../../../.." に変更

analysis_result:
  source: prompt-analyzer
  timestamp: 2026-01-03T15:15:00Z
  data:
    5w1h:
      what: REPO_ROOT パス計算の修正
      why: contract.sh の source に失敗している
      where: bash-check.sh 行 15
      how: パス階層を 2 → 4 に修正
    risks:
      technical:
        - risk: パス計算ミス
          severity: low
          mitigation: bash -n で構文確認
      scope: []
      dependency: []
    ambiguity: []
    summary:
      confidence: high
      ready_for_playbook: true
      blocking_issues: []

translated_requirements:
  source: term-translator
  timestamp: 2026-01-03T15:15:00Z
  data:
    original_terms: []
    technical_requirements:
      - requirement: REPO_ROOT="${SCRIPT_DIR}/../../../.."
        derived_from: 4 階層上
        implementation_hint: 行 15 を直接編集
    codebase_context:
      relevant_files:
        - .claude/skills/access-control/guards/bash-check.sh
        - scripts/contract.sh
      existing_patterns:
        - SCRIPT_DIR + 相対パスでリポジトリルートを取得
      conventions:
        - 親ディレクトリへの参照は .. を使用

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-03T15:15:00Z
  summary: ユーザーが「はい、進めてください」と承認
  approved_items:
    - question_id: approval
      question: この理解で playbook を作成してよろしいですか？
      answer: はい、進めてください
```

---

## phases

### p1: パス修正

**goal**: REPO_ROOT のパス計算を 4 階層に修正する

#### subtasks

- [x] **p1.1**: bash-check.sh の REPO_ROOT が `"${SCRIPT_DIR}/../../../.."` である
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 確認: REPO_ROOT=\"${SCRIPT_DIR}/../../../..\""
    - consistency: "PASS - contract.sh への相対パスが正しい"
    - completeness: "PASS - 1 箇所のみ変更"
  - validated: 2026-01-03T16:00:00

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: 修正が正しく適用され、スクリプトが動作することを確認

**depends_on**: [p1]

#### subtasks

- [x] **p_final.1**: bash -n bash-check.sh が成功する（構文エラーなし）
  - executor: claudecode
  - validations:
    - technical: "PASS - bash -n → exit code 0, Syntax OK"
    - consistency: "PASS - 標準的なシェル構文"
    - completeness: "PASS - 構文エラー 0 件"
  - validated: 2026-01-03T16:00:00

- [x] **p_final.2**: REPO_ROOT から contract.sh へのパスが正しい
  - executor: claudecode
  - validations:
    - technical: "PASS - realpath → /Users/amano/Desktop/thanks4claudecode-v2"
    - consistency: "PASS - CONTRACT_SCRIPT が正しく定義"
    - completeness: "PASS - test -f contract.sh → YES"
  - validated: 2026-01-03T16:00:00

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: skipped (no structural changes)

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: skipped (no temp files)

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git commit`
  - status: done

- [x] **ft4**: PR 作成
  - command: `gh pr create`
  - status: done (PR #74)
