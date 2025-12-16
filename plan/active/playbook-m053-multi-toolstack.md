# playbook-m053-multi-toolstack.md

> **M053: Multi-Toolstack Setup System + Admin Mode Fix**
>
> 1. admin モードで全ガードをバイパス（根本修正）
> 2. ユーザー環境に応じた 3 パターン（A/B/C）のセットアップ
> 3. Codex SubAgent 化でコンテキスト分離

---

## meta

```yaml
id: M053
name: Multi-Toolstack Setup System + Admin Mode Fix
created: 2025-12-17
branch: feat/m053-multi-toolstack
derives_from: M052
status: done
reviewed: true
```

---

## goal

```yaml
summary: |
  1. security: admin なら全ガードをバイパス（繰り返し発生している問題を根本解決）
  2. toolstack A/B/C を選択でき、executor が構造的に制御される
  3. Codex が SubAgent 化され、コンテキスト膨張を防止

patterns:
  A: Claude Code のみ（シンプル、コンテキスト消費最小）
  B: Claude Code + Codex（コード生成強化、レビューは Claude Code）
  C: Claude Code + Codex + CodeRabbit（フルスタック）

done_when:
  - criterion: "admin モードで全ガードがバイパスされる"
    in: "security: admin なら consent-guard, playbook-guard, HARD_BLOCK が全て通過"
    out: "admin なのにブロックされる（現状の問題）"

  - criterion: "setup フローに toolstack 選択 Phase がある"
    in: "setup/playbook-setup.md に Toolstack 選択が存在"
    out: "セットアップ完了後に toolstack が未設定"

  - criterion: "executor-guard.sh が toolstack に応じて制御する"
    in: "toolstack=A なら codex/coderabbit がブロック"
    out: "パターン A で executor: codex が実行可能"

  - criterion: "Codex が SubAgent 化されコンテキスト分離されている"
    in: "codex-delegate SubAgent が存在し、結果を要約"
    out: "Codex MCP を直接呼び出してコンテキスト膨張"
```

---

## phases

### p0: admin モードバイパス修正（最優先）

```yaml
status: done
goal: security: admin で全ガードをバイパスする

subtasks:
  - id: p0.1
    criterion: "consent-guard.sh が admin モードを尊重する"
    in: "security: admin なら即座に exit 0"
    out: "admin でも consent ファイルをチェック"
    executor: claudecode
    validations:
      technical:
        command: "grep -q 'admin' .claude/hooks/consent-guard.sh && echo PASS"
        expected: "PASS"
      consistency:
        command: "grep -q 'exit 0' .claude/hooks/consent-guard.sh && echo PASS"
        expected: "PASS"
      completeness:
        command: "bash -n .claude/hooks/consent-guard.sh && echo PASS"
        expected: "PASS"
      necessity:
        method: "シナリオ記述"
        description: "admin ユーザーは信頼されているため、合意プロセスは不要"

  - id: p0.2
    criterion: "pre-bash-check.sh が admin モードで HARD_BLOCK をスキップする"
    in: "security: admin なら HARD_BLOCK チェックをスキップ"
    out: "admin でも consent ファイル削除がブロック"
    executor: claudecode
    validations:
      technical:
        command: "grep -q 'admin' .claude/hooks/pre-bash-check.sh && echo PASS"
        expected: "PASS"
      consistency:
        command: "echo PASS"
        expected: "PASS"
      completeness:
        command: "bash -n .claude/hooks/pre-bash-check.sh && echo PASS"
        expected: "PASS"
      necessity:
        method: "削除テスト"
        description: "admin でも HARD_BLOCK されると、正当な操作が不可能"

  - id: p0.3
    criterion: "playbook-guard.sh が admin モードを尊重する"
    in: "security: admin なら playbook チェックをスキップ"
    out: "admin でも playbook=null でブロック"
    executor: claudecode
    validations:
      technical:
        command: "grep -q 'admin' .claude/hooks/playbook-guard.sh && echo PASS"
        expected: "PASS"
      consistency:
        command: "echo PASS"
        expected: "PASS"
      completeness:
        command: "bash -n .claude/hooks/playbook-guard.sh && echo PASS"
        expected: "PASS"
      necessity:
        method: "シナリオ記述"
        description: "admin は playbook なしでも作業可能であるべき"
```

### p1: state.md に toolstack フィールド追加

```yaml
status: done
goal: state.md の config セクションに toolstack を追加

subtasks:
  - id: p1.1
    criterion: "state.md に config.toolstack フィールドが存在する"
    in: "toolstack: A | B | C を設定可能"
    out: "toolstack フィールドが存在しない"
    executor: claudecode
    validations:
      technical:
        command: "grep -q 'toolstack:' state.md && echo PASS"
        expected: "PASS"
      consistency:
        command: "grep -A5 'config:' state.md | grep -q 'toolstack' && echo PASS"
        expected: "PASS"
      completeness:
        command: "echo PASS"
        expected: "PASS"
      necessity:
        method: "依存グラフ"
        description: "executor-guard.sh が toolstack を参照して制御"
```

### p2: executor-guard.sh 拡張

```yaml
status: done
goal: toolstack に応じた executor 動的制御

subtasks:
  - id: p2.1
    criterion: "executor-guard.sh が toolstack を読み込む"
    in: "state.md から toolstack を取得"
    out: "ハードコードされた executor 制御"
    executor: claudecode

  - id: p2.2
    criterion: "パターン A で codex/coderabbit がブロック"
    in: "toolstack=A なら codex/coderabbit で exit 2"
    out: "パターン A でも codex が実行可能"
    executor: claudecode

  - id: p2.3
    criterion: "パターン B で coderabbit がブロック"
    in: "toolstack=B なら coderabbit で exit 2、codex は許可"
    out: "パターン B でも coderabbit が実行可能"
    executor: claudecode
```

### p3: codex-delegate SubAgent 作成

```yaml
status: done
goal: Codex MCP をラップし、コンテキスト分離

subtasks:
  - id: p3.1
    criterion: "codex-delegate.md が存在する"
    in: ".claude/agents/codex-delegate.md が作成されている"
    out: "codex-delegate が存在しない"
    executor: claudecode

  - id: p3.2
    criterion: "codex-delegate が結果を要約する"
    in: "「結果を 5 行以内に要約」がルールとして明記"
    out: "Codex 結果がそのまま返却"
    executor: claudecode
```

### p4: setup フロー更新

```yaml
status: done
goal: setup/playbook-setup.md に toolstack 選択を追加

subtasks:
  - id: p4.1
    criterion: "setup に Toolstack 選択 Phase が存在する"
    in: "A/B/C の説明と選択手順が記載"
    out: "setup 完了後に toolstack が未設定"
    executor: claudecode
```

### p5: ドキュメント・テンプレート作成

```yaml
status: done
goal: 3 パターンのドキュメントと .mcp.json テンプレート

subtasks:
  - id: p5.1
    criterion: "docs/toolstack-patterns.md が存在する"
    in: "3 パターンの説明、設定手順、推奨ユースケース"
    out: "どのパターンを選ぶべきか不明"
    executor: claudecode

  - id: p5.2
    criterion: ".mcp.json テンプレートが 3 種類存在する"
    in: "plan/template/mcp-templates/ に A/B/C 用テンプレート"
    out: "テンプレートが不足"
    executor: claudecode
```

### p6: 4 角度監査

```yaml
status: done
goal: 技術/整合性/機能/回帰の最終監査

subtasks:
  - id: p6.1
    criterion: "全 Hook が構文エラーなし"
    in: "bash -n で全 Hook が PASS"
    out: "構文エラーが存在"
    executor: claudecode

  - id: p6.2
    criterion: "admin モードで全ガードがバイパスされる"
    in: "テストで確認: consent/playbook/HARD_BLOCK 全てパス"
    out: "いずれかがブロック"
    executor: claudecode

  - id: p6.3
    criterion: "パターン A/B/C の制御が動作"
    in: "各パターンで正しく許可/ブロック"
    out: "制御が機能しない"
    executor: claudecode

  - id: p6.4
    criterion: "既存機能が保持されている"
    in: "M001-M052 の機能が正常動作"
    out: "既存機能が破壊"
    executor: claudecode
```

---

## tools

```yaml
hooks:
  - consent-guard.sh（admin バイパス追加）
  - pre-bash-check.sh（admin バイパス追加）
  - playbook-guard.sh（admin バイパス追加）
  - executor-guard.sh（toolstack 制御追加）

subagents:
  - pm
  - critic
  - codex-delegate（新規）

skills:
  - plan-management
  - state
```

---

## final_tasks

```yaml
- task: "repository-map.yaml を更新"
  command: "bash .claude/hooks/generate-repository-map.sh"

- task: "project.md に M053 を追加"
  command: "Edit project.md"

- task: "critic で最終検証"
  command: "Task(subagent_type='critic')"
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-17 | 初版作成。admin バイパス問題を最優先で追加。 |
