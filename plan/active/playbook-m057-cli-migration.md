# playbook-m057-cli-migration.md

> **Codex/CodeRabbit CLI 化 - MCP 誤設計の根本修正**
>
> Codex と CodeRabbit が MCP サーバーとして誤設計されていた問題を修正。
> 実際には両方とも CLI ツールとして存在しており、その仕様に合わせて
> 全ドキュメント・SubAgent・Hook を一括更新する。

---

## meta

```yaml
project: Codex/CodeRabbit CLI Migration
branch: feat/m057-cli-migration
created: 2025-12-17
issue: null
derives_from: M057
reviewed: false
```

---

## goal

```yaml
summary: |
  Codex と CodeRabbit を MCP から CLI 実装に根本修正し、
  全システムを一貫性のある CLI 構成に統一する。

done_when:
  - .mcp.json から codex エントリが削除されている
  - docs/toolstack-patterns.md が MCP → CLI に全面書き換えされている
  - .claude/agents/codex-delegate.md が CLI ベースに修正されている
  - .claude/hooks/executor-guard.sh の MCP 参照が CLI に修正されている
  - plan/template/playbook-format.md の executor 説明が更新されている
  - .claude/CLAUDE-ref.md の MCP 参照が削除されている
  - setup/playbook-setup.md の MCP 設定が CLI に修正されている
  - repository-map.yaml が更新されている
```

---

## phases

### p1: 現状分析 & CLI パス確認

**goal**: MCP 設定の確認と CLI 実装の検証

**depends_on**: []

#### subtasks

- [ ] **p1.1**: .mcp.json を読み、codex MCP 設定を確認している
  - executor: claudecode
  - test_command: `test -f .mcp.json && grep -q 'codex' .mcp.json && echo PASS || echo FAIL`
  - validations:
    - technical: "MCP 設定ファイルが存在し codex エントリが確認できる"
    - consistency: "設定形式が正しい JSON である"
    - completeness: "全 codex/coderabbit エントリが可視化される"

- [ ] **p1.2**: CLI バイナリのパスが確認されている
  - executor: claudecode
  - test_command: `test -x /Users/amano/.asdf/installs/nodejs/24.4.1/bin/codex && echo PASS || echo FAIL`
  - validations:
    - technical: "Codex CLI バイナリが実行可能である"
    - consistency: "バイナリパスが環境に存在する"
    - completeness: "codex --version で動作確認可能"

- [ ] **p1.3**: docs/toolstack-patterns.md が現在の MCP 仕様を記載している
  - executor: claudecode
  - test_command: `test -f docs/toolstack-patterns.md && grep -q 'MCP' docs/toolstack-patterns.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ドキュメントが存在し MCP 記載がある"
    - consistency: "フォーマットが Markdown である"
    - completeness: "全 toolstack パターンが記載されている"

**status**: pending
**max_iterations**: 3

---

### p2: .mcp.json 修正 & MCP 設定削除

**goal**: .mcp.json から codex MCP エントリを削除

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: .mcp.json の codex エントリが削除されている
  - executor: claudecode
  - test_command: `test -f .mcp.json && ! grep -q '"codex"' .mcp.json && echo PASS || echo FAIL`
  - validations:
    - technical: "JSON ファイルが有効である（json コマンドで検証）"
    - consistency: "残りの MCP エントリは保持されている"
    - completeness: ".mcp.json が正しい JSON 形式である"

- [ ] **p2.2**: .mcp.json が有効な JSON である
  - executor: claudecode
  - test_command: `test -f .mcp.json && python3 -m json.tool .mcp.json > /dev/null && echo PASS || echo FAIL`
  - validations:
    - technical: "JSON パーサーが正常に読み込める"
    - consistency: "構文エラーがない"
    - completeness: "バックアップを確認してから修正"

**status**: pending
**max_iterations**: 3

---

### p3: toolstack-patterns.md 全面書き換え

**goal**: MCP ベースの説明を CLI ベースに統一

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: docs/toolstack-patterns.md が CLI ベースに全面書き換えされている
  - executor: claudecode
  - test_command: `test -f docs/toolstack-patterns.md && grep -q 'codex exec' docs/toolstack-patterns.md && ! grep -q 'MCP' docs/toolstack-patterns.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ドキュメントに CLI 使用例が明記されている"
    - consistency: "他の toolstack ドキュメントと一貫性がある"
    - completeness: "Codex/CodeRabbit の全 CLI オプションが記載されている"

- [ ] **p3.2**: toolstack パターン A/B/C の説明が更新されている
  - executor: claudecode
  - test_command: `grep -q 'Pattern A' docs/toolstack-patterns.md && grep -q 'Pattern B' docs/toolstack-patterns.md && grep -q 'Pattern C' docs/toolstack-patterns.md && echo PASS || echo FAIL`
  - validations:
    - technical: "3 パターン全てが記載されている"
    - consistency: "各パターンの説明が一貫性がある"
    - completeness: "CLI 使用例が各パターンに含まれている"

- [ ] **p3.3**: Codex/CodeRabbit の CLI 使用法が明確に記載されている
  - executor: claudecode
  - test_command: `grep -q 'codex exec' docs/toolstack-patterns.md && grep -q 'coderabbit review' docs/toolstack-patterns.md && echo PASS || echo FAIL`
  - validations:
    - technical: "CLI コマンドの構文が正確である"
    - consistency: "他の CLI ツール説明と形式が統一されている"
    - completeness: "実行例、出力形式が明示されている"

**status**: pending
**max_iterations**: 3

---

### p4: SubAgent & Hook 修正

**goal**: codex-delegate.md と executor-guard.sh を CLI ベースに修正

**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: .claude/agents/codex-delegate.md が CLI ベースに修正されている
  - executor: claudecode
  - test_command: `test -f .claude/agents/codex-delegate.md && grep -q 'Bash.*CLI' .claude/agents/codex-delegate.md && ! grep -q 'MCP' .claude/agents/codex-delegate.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ドキュメントに Bash CLI 実行方法が記載されている"
    - consistency: "SubAgent インターフェースが保持されている"
    - completeness: "実装例が実行可能である"

- [ ] **p4.2**: .claude/hooks/executor-guard.sh の MCP 参照が CLI に修正されている
  - executor: claudecode
  - test_command: `test -f .claude/hooks/executor-guard.sh && grep -q 'codex' .claude/hooks/executor-guard.sh && ! grep -q 'MCP' .claude/hooks/executor-guard.sh && bash -n .claude/hooks/executor-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "Shell スクリプト構文が正しい"
    - consistency: "他の Hook と同じ判定ロジックを使用"
    - completeness: "全 executor タイプ (claudecode/codex/coderabbit/user) をカバー"

- [ ] **p4.3**: executor-guard.sh が toolstack 設定に応じて制御できる
  - executor: claudecode
  - test_command: `grep -q 'state.config.toolstack' .claude/hooks/executor-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "state.config.toolstack を参照している"
    - consistency: "state.md の toolstack フィールドと一致"
    - completeness: "A/B/C パターンのルーティングが完全"

**status**: pending
**max_iterations**: 3

---

### p5: Template & Documentation 更新

**goal**: playbook-format.md と setup/playbook-setup.md を修正

**depends_on**: [p4]

#### subtasks

- [ ] **p5.1**: plan/template/playbook-format.md の executor 説明が更新されている
  - executor: claudecode
  - test_command: `test -f plan/template/playbook-format.md && grep -q 'executor: claudecode' plan/template/playbook-format.md && grep -q 'executor: codex' plan/template/playbook-format.md && echo PASS || echo FAIL`
  - validations:
    - technical: "executor 選択ガイドが最新である"
    - consistency: "実装の説明と一致している"
    - completeness: "全 executor タイプの説明がある"

- [ ] **p5.2**: setup/playbook-setup.md の MCP 設定が CLI に修正されている
  - executor: claudecode
  - test_command: `test -f setup/playbook-setup.md && ! grep -q 'MCP' setup/playbook-setup.md && grep -q 'CLI' setup/playbook-setup.md && echo PASS || echo FAIL`
  - validations:
    - technical: "セットアップ手順が実行可能である"
    - consistency: "docs/toolstack-patterns.md と一致"
    - completeness: "全セットアップステップが明記されている"

- [ ] **p5.3**: .claude/CLAUDE-ref.md から MCP 参照が削除されている
  - executor: claudecode
  - test_command: `test -f .claude/CLAUDE-ref.md && ! grep -q 'MCP' .claude/CLAUDE-ref.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し有効な内容である"
    - consistency: "CLAUDE.md との参照が保持されている"
    - completeness: "削除対象の MCP 参照が全て削除されている"

**status**: pending
**max_iterations**: 3

---

### p6: 自動マッピング & 整合性確認

**goal**: repository-map.yaml を更新し全システムの整合性を確認

**depends_on**: [p5]

#### subtasks

- [ ] **p6.1**: repository-map.yaml が自動生成され更新されている
  - executor: claudecode
  - test_command: `bash .claude/hooks/generate-repository-map.sh && test -f docs/repository-map.yaml && echo PASS || echo FAIL`
  - validations:
    - technical: "スクリプト実行が成功する"
    - consistency: "YAML ファイルが有効である"
    - completeness: "全ファイルが正しくマッピングされている"

- [ ] **p6.2**: .claude/agents/codex-delegate.md が repository-map.yaml に反映されている
  - executor: claudecode
  - test_command: `grep -q 'codex-delegate' docs/repository-map.yaml && grep -q 'CLI' docs/repository-map.yaml && echo PASS || echo FAIL`
  - validations:
    - technical: "エントリが正しく登録されている"
    - consistency: "説明が最新の実装と一致"
    - completeness: "全 SubAgent/Hook が含まれている"

**status**: pending
**max_iterations**: 3

---

### p7: 検証 & クリーンアップ

**goal**: 全ファイルが CLI ベースに統一されたことを検証

**depends_on**: [p6]

#### subtasks

- [ ] **p7.1**: grep で "MCP" が含まれるファイルが確認されている（除外対象除く）
  - executor: claudecode
  - test_command: `grep -r 'MCP' --include='*.md' --include='*.sh' --include='*.json' . --exclude-dir=.git --exclude-dir=.archive --exclude-dir=plan/archive --exclude='*.backup' | grep -v 'docs/CLAUDE.md' | wc -l | grep -q '^0$' && echo PASS || echo FAIL`
  - validations:
    - technical: "grep が正しく実行されている"
    - consistency: "除外対象が適切に指定されている"
    - completeness: "全リポジトリが対象となっている"

- [ ] **p7.2**: .claude/hooks/executor-guard.sh が bash 構文チェック合格している
  - executor: claudecode
  - test_command: `bash -n .claude/hooks/executor-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "Shell スクリプト構文が正しい"
    - consistency: "他の Hook スクリプトと同じコードスタイル"
    - completeness: "Hook スクリプトが検証対象となっている"

- [ ] **p7.3**: state.md の toolstack 設定が正常に機能している
  - executor: user
  - test_command: `手動確認: state.md の toolstack が A/B/C のいずれかに設定されており、executor-guard.sh がそれに応じて制御できることを確認`
  - validations:
    - technical: "toolstack 値が有効である"
    - consistency: "executor-guard.sh の制御ロジックと一致"
    - completeness: "全 toolstack パターンで動作確認済み"

**status**: pending
**max_iterations**: 3

---

## 参照

- project.md: M057 milestone 定義
- docs/toolstack-patterns.md: Toolstack パターン（修正対象）
- .claude/agents/codex-delegate.md: Codex SubAgent（修正対象）
- .claude/hooks/executor-guard.sh: Executor ガード（修正対象）
- plan/template/playbook-format.md: Playbook テンプレート（修正対象）
- setup/playbook-setup.md: Setup ガイド（修正対象）
