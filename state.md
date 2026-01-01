# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-facade-audit-v2.md
branch: feat/facade-audit-v2
last_archived: plan/playbook-facade-audit.md
review_pending: false
```

---

## goal

```yaml
milestone: null
phase: complete
done_criteria:
  - playbook テンプレートが「executor 強制」「証拠強制」を構造的に保証している
  - executor-guard が Task/Bash を含む全ツールを監視している
  - Codex MCP が 5 回連続で正常応答する（タイムアウトなし）
  - フォールバック時にユーザー確認プロンプトが発生する
  - p3-p7 の実装が全て Codex によって行われた証拠がある
  - CodeRabbit 最終レビューで critical: 0, major: 0 である
note: executor 強制を構造的に保証し、Codex/CodeRabbit による監査を完遂する
progress:
  - p_init: done (2026-01-01) - テンプレート V17 改善完了、playbook-guard.sh バグ修正
  - p0: done (2026-01-01) - Codex MCP 安定性確認（8/8成功）、フォールバックポリシー作成
  - p1: done (2026-01-01) - executor-guard 拡張完了（Task/Bash 追加、20/20 テスト PASS）
  - p2: done (2026-01-01) - フォールバックポリシー実装（V17 メッセージ更新、15/15 テスト PASS）
  - p3: done (2026-01-01) - ガード検証完了（67テスト、exit0削減70→22、critic-guard強化）
  - p4: done (2026-01-01) - テスト基盤強化（guards 132テスト、critic 23ケース、E2E 51アサーション）
  - p5: done (2026-01-01) - CodeRabbit中間レビュー完了（critical:0+1修正済み、100%カバレッジ）
  - p6: done (2026-01-01) - 統合テスト完了（TDDフロー検証、81テスト100%PASS）
  - p7: done (2026-01-01) - 最終レビュー完了（critical:1+major:2修正、最終critical:0,major:0）
  - p_final: done (2026-01-01) - 完了検証（executor-guard全ツール監視、Codex安定、全証拠確認、critical:0,major:0）
```

---

## session

```yaml
last_start: 2026-01-01 17:20:50
last_end: 2025-12-24 03:27:11
last_clear: 2025-12-24 03:20:00
```

---

## config

```yaml
security: admin
toolstack: C  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
roles:
  orchestrator: claudecode  # 監督・調整・設計（常に claudecode）
  worker: codex             # 実装担当（A: claudecode, B/C: codex）
  reviewer: coderabbit      # レビュー担当（A/B: claudecode, C: coderabbit）
  human: user               # 人間の介入（常に user）
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/folder-management.md | フォルダ管理ルール |
