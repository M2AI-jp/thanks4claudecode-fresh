# playbook-m078-codex-mcp.md

> **Codex CLI から Codex MCP への切り替え - TTY 制約回避**

---

## meta

```yaml
project: thanks4claudecode
branch: research/codex-mcp
created: 2025-12-18
issue: null
derives_from: M078
reviewed: true  # 2025-12-18 plan-reviewer PASS
roles:
  worker: claudecode  # MCP 設定は軽量作業なので claudecode で実行
```

---

## goal

```yaml
summary: Codex CLI の TTY 制約を回避し、MCP サーバー経由で Codex を呼び出せるようにする
done_when:
  - .claude/mcp.json が存在し、codex mcp-server が登録されている
  - codex-delegate.md が MCP ツール mcp__codex__codex を使用する形式に更新されている
  - docs/ai-orchestration.md に Codex MCP の説明が追加されている
  - toolstack C で簡単なコーディングタスクを Codex MCP 経由で実行し、正常に動作することが確認されている
  - テスト完了後、toolstack: A に復元されている
```

---

## phases

### p1: MCP 設定追加

**goal**: .claude/mcp.json を作成し、codex mcp-server を登録する

#### subtasks

- [x] **p1.1**: .claude/mcp.json が存在し、codex mcp-server が登録されている
  - executor: orchestrator
  - test_command: `test -f .claude/mcp.json && grep -q 'codex' .claude/mcp.json && echo PASS || echo FAIL`
  - validations:
    - technical: "JSON 構文が正しく、codex エントリが含まれる"
    - consistency: "MCP 設定が Claude Code の仕様に準拠"
    - completeness: "必要なフィールド（command, args, env, timeout）が全て含まれる"

- [x] **p1.2**: mcp.json に timeout: 600000ms が設定されている
  - executor: orchestrator
  - test_command: `grep -q '600000' .claude/mcp.json && echo PASS || echo FAIL`
  - validations:
    - technical: "timeout 値が正しく設定されている"
    - consistency: "長時間実行タスク用の適切な値"
    - completeness: "timeout フィールドが存在する"

**status**: pending
**max_iterations**: 5

---

### p2: codex-delegate SubAgent 更新

**goal**: codex-delegate.md を MCP 経由の呼び出しに変更する

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: codex-delegate.md が MCP ツール呼び出し形式に更新されている
  - executor: orchestrator
  - test_command: `grep -q 'mcp__codex__codex' .claude/agents/codex-delegate.md && echo PASS || echo FAIL`
  - validations:
    - technical: "MCP ツール名が正しく記載されている"
    - consistency: "既存の呼び出し方法との互換性が説明されている"
    - completeness: "使用例が含まれている"

- [x] **p2.2**: CLI 呼び出し（Bash: codex exec）から MCP 呼び出しへの変更が明記されている
  - executor: orchestrator
  - test_command: `grep -q 'MCP' .claude/agents/codex-delegate.md && echo PASS || echo FAIL`
  - validations:
    - technical: "変更内容が明確に記載されている"
    - consistency: "変更理由（TTY 制約）が説明されている"
    - completeness: "Before/After が明確"

**status**: pending
**max_iterations**: 5

---

### p3: ドキュメント更新

**goal**: docs/ai-orchestration.md に Codex MCP の説明を追加する

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: docs/ai-orchestration.md に Codex MCP セクションが追加されている
  - executor: orchestrator
  - test_command: `grep -q 'Codex MCP' docs/ai-orchestration.md && echo PASS || echo FAIL`
  - validations:
    - technical: "セクションが正しく追加されている"
    - consistency: "既存のドキュメント構造と整合"
    - completeness: "MCP 設定方法と使用方法が含まれている"

- [x] **p3.2**: MCP 設定方法（mcp.json の設定手順）が記載されている
  - executor: orchestrator
  - test_command: `grep -q 'mcp.json' docs/ai-orchestration.md && echo PASS || echo FAIL`
  - validations:
    - technical: "設定手順が正確"
    - consistency: "実際の mcp.json と一致"
    - completeness: "必要なフィールドが全て説明されている"

**status**: pending
**max_iterations**: 5

---

### p4: 動作確認（E2E テスト）

**goal**: toolstack C で Codex MCP の動作を確認し、元の状態に復元する

**depends_on**: [p3]

#### subtasks

- [x] **p4.1**: ユーザーが Claude Code を再起動している（MCP サーバー読み込みのため）
  - executor: human
  - test_command: `手動確認: Claude Code を再起動し、MCP サーバーが読み込まれたことを確認`
  - validations:
    - technical: "再起動後に MCP サーバーが利用可能"
    - consistency: "mcp.json の設定が反映されている"
    - completeness: "codex MCP が接続済み"

- [x] **p4.2**: state.md の toolstack が C に変更されている
  - executor: orchestrator
  - test_command: `grep -q 'toolstack: C' state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "toolstack 値が正しく変更されている"
    - consistency: "config セクション内に存在"
    - completeness: "roles も適切に更新されている"

- [x] **p4.3**: 簡単なコーディングタスクを Codex MCP 経由で実行し、正常に動作することが確認されている
  - executor: worker
  - test_command: `手動確認: Codex MCP 経由でコード生成が成功した`
  - validations:
    - technical: "MCP ツール呼び出しが成功した"
    - consistency: "生成されたコードが正しい"
    - completeness: "エラーなく完了した"

- [x] **p4.4**: テスト完了後、state.md が toolstack: A に復元されている
  - executor: orchestrator
  - test_command: `grep -q 'toolstack: A' state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "toolstack 値が A に戻っている"
    - consistency: "roles もデフォルトに戻っている"
    - completeness: "全ての設定が元通り"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p4]

#### subtasks

- [x] **p_final.1**: .claude/mcp.json が存在し、codex mcp-server が登録されている
  - executor: orchestrator
  - test_command: `test -f .claude/mcp.json && grep -q 'codex' .claude/mcp.json && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し codex が含まれる"
    - consistency: "JSON 構文が正しい"
    - completeness: "必要なフィールドが全て存在"

- [x] **p_final.2**: codex-delegate.md が MCP ツール mcp__codex__codex を使用する形式に更新されている
  - executor: orchestrator
  - test_command: `grep -q 'mcp__codex__codex' .claude/agents/codex-delegate.md && echo PASS || echo FAIL`
  - validations:
    - technical: "MCP ツール名が記載されている"
    - consistency: "使用例が含まれている"
    - completeness: "変更理由が説明されている"

- [x] **p_final.3**: docs/ai-orchestration.md に Codex MCP の説明が追加されている
  - executor: orchestrator
  - test_command: `grep -q 'Codex MCP' docs/ai-orchestration.md && echo PASS || echo FAIL`
  - validations:
    - technical: "セクションが存在する"
    - consistency: "既存構造と整合"
    - completeness: "設定方法と使用方法が含まれている"

- [x] **p_final.4**: テスト完了後、toolstack: A に復元されている
  - executor: orchestrator
  - test_command: `grep -q 'toolstack: A' state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "toolstack 値が A"
    - consistency: "roles がデフォルト"
    - completeness: "元の状態に完全復元"

**status**: pending
**max_iterations**: 3

---

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

---

## 注意事項

```yaml
重要:
  - Claude Code の再起動が必要（MCP サーバー読み込みのため）
  - Phase 4 開始前にユーザーに再起動を依頼すること
  - テスト完了後は必ず toolstack: A に復元すること

参考:
  - Codex MCP: https://github.com/openai/codex
  - MCP 設定: https://docs.anthropic.com/claude-code/mcp
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-18 | 初版作成 |
