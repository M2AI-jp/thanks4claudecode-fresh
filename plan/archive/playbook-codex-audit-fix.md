# playbook-codex-audit-fix.md

> **前回 playbook 実行中に発見した問題の修正**

---

## meta

```yaml
project: codex-audit-fix
branch: fix/codex-audit-fix
created: 2026-01-02
issue: null
reviewed: true
```

---

## goal

```yaml
summary: 前回の Codex audit で発見した 2 つの問題カテゴリを修正する
done_when:
  - .claude/agents/ に 4 つの SubAgent シンボリックリンク（coderabbit-delegate, prompt-analyzer, term-translator, executor-resolver）が存在する
  - ARCHITECTURE.md に command/utility/config/test 層が記載されている
```

---

## context

```yaml
5w1h:
  who: Claude Code（executor: codex）
  what: SubAgent シンボリックリンク作成 + ARCHITECTURE.md 追記
  when: 今回のセッション
  where: .claude/agents/（リンク）、docs/ARCHITECTURE.md（追記）
  why: 前回 playbook 実行中に「サラッと流した問題」の修正
  how: 新ブランチ fix/codex-audit-fix を使用

analysis_result:
  source: user-provided
  timestamp: 2026-01-02T18:00:00Z
  data:
    findings:
      - category: Critical
        issue: SubAgent シンボリックリンク未登録
        affected: [coderabbit-delegate, prompt-analyzer, term-translator, executor-resolver]
      - category: Medium
        issue: ARCHITECTURE.md に command/utility/config/test 層が未記載
    o3_to_opus_change:
      status: verified
      verdict: legitimate
      reason: ユーザーが指示した変更。現在の Codex MCP model パラメータは opus が正しい
      action: revert 不要、ドキュメント化も不要

user_approved_understanding:
  source: understanding-check
  approved_at: 2026-01-02T18:00:00Z
  summary: ユーザー承認済み。o3→opus 変更は正当な変更として確認
```

---

## phases

### p1: SubAgent シンボリックリンク作成

**goal**: 4 つの SubAgent を .claude/agents/ にシンボリックリンクとして登録

#### subtasks

- [x] **p1.1**: .claude/agents/coderabbit-delegate.md が存在し、実ファイルを指している
  - executor: codex
  - validations:
    - technical: "PASS - シンボリックリンク確認済み"
    - consistency: "PASS - 正しいパスを指している"
    - completeness: "PASS - リンク先ファイル存在"
  - validated: 2026-01-02T19:10:00

- [x] **p1.2**: .claude/agents/prompt-analyzer.md が存在し、実ファイルを指している
  - executor: codex
  - validations:
    - technical: "PASS - シンボリックリンク確認済み"
    - consistency: "PASS - 正しいパスを指している"
    - completeness: "PASS - リンク先ファイル存在"
  - validated: 2026-01-02T19:10:00

- [x] **p1.3**: .claude/agents/term-translator.md が存在し、実ファイルを指している
  - executor: codex
  - validations:
    - technical: "PASS - シンボリックリンク確認済み"
    - consistency: "PASS - 正しいパスを指している"
    - completeness: "PASS - リンク先ファイル存在"
  - validated: 2026-01-02T19:10:00

- [x] **p1.4**: .claude/agents/executor-resolver.md が存在し、実ファイルを指している
  - executor: codex
  - validations:
    - technical: "PASS - シンボリックリンク確認済み"
    - consistency: "PASS - 正しいパスを指している"
    - completeness: "PASS - リンク先ファイル存在"
  - validated: 2026-01-02T19:10:00

**status**: done
**max_iterations**: 5

---

### p2: ARCHITECTURE.md MECE gaps 修正

**goal**: ARCHITECTURE.md に不足している command/utility/config/test 層を追記
**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: ARCHITECTURE.md に .claude/commands/ セクションが記載されている
  - executor: codex
  - validations:
    - technical: "PASS - grep で commands/ 確認"
    - consistency: "PASS - 実際のディレクトリ構造と一致"
    - completeness: "PASS - 主要コマンド列挙済み"
  - validated: 2026-01-02T19:10:00

- [x] **p2.2**: ARCHITECTURE.md に utility 層（common.sh, state-schema.sh 等）が記載されている
  - executor: codex
  - validations:
    - technical: "PASS - grep で common.sh, state-schema.sh 確認"
    - consistency: "PASS - 実際のファイル構造と一致"
    - completeness: "PASS - 主要 utility 列挙済み"
  - validated: 2026-01-02T19:10:00

- [x] **p2.3**: ARCHITECTURE.md に config 層（.mcp.json, mcp.json 等）が記載されている
  - executor: codex
  - validations:
    - technical: "PASS - grep で .mcp.json, mcp.json 確認"
    - consistency: "PASS - 実際のファイル構造と一致"
    - completeness: "PASS - 主要 config 列挙済み"
  - validated: 2026-01-02T19:10:00

- [x] **p2.4**: ARCHITECTURE.md に test 層（regression-test.sh 等）が記載されている
  - executor: codex
  - validations:
    - technical: "PASS - grep で regression-test.sh 確認"
    - consistency: "PASS - 実際のファイル構造と一致"
    - completeness: "PASS - 主要テストスクリプト列挙済み"
  - validated: 2026-01-02T19:10:00

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when の全項目が実際に満たされているか最終検証
**depends_on**: [p1, p2]

#### subtasks

- [x] **p_final.1**: .claude/agents/ に 4 つの SubAgent シンボリックリンクが存在する
  - executor: claudecode
  - validations:
    - technical: "PASS - ls -la で 4 リンク確認"
    - consistency: "PASS - 各リンクが正しいパスを指している"
    - completeness: "PASS - 4 つ全て存在"
  - validated: 2026-01-02T19:10:00

- [x] **p_final.2**: ARCHITECTURE.md に command/utility/config/test 層が記載されている
  - executor: claudecode
  - validations:
    - technical: "PASS - grep で 4 層全て確認"
    - consistency: "PASS - 実ファイル構造と一致"
    - completeness: "PASS - 4 層全て記載"
  - validated: 2026-01-02T19:10:00

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: skipped (スクリプト不在)

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: done

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done
