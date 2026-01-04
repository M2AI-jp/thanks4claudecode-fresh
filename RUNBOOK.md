# RUNBOOK.md

> **Procedures and operational checkpoints.**
> CLAUDE.md が最優先。詳細は各ドキュメントに集約する。

---

## Session Start

1. `state.md` を読む
2. `playbook.active` があれば該当ファイルを開く
3. `git status -sb` で作業状態を確認

---

## Task Start

- playbook は必ず `playbook-init` 経由で作成
- ブランチ命名は `{type}/{description}`
- `state.md` の playbook.active / branch を更新

---

## During Work

- playbook なしの Edit/Write/Bash（変更系）は禁止
- subtask 完了時は validations（technical/consistency/completeness）必須
- critic/reviewer の判定が PASS するまで完了にしない

参照:
- `docs/criterion-validation-rules.md`
- `docs/ARCHITECTURE.md`

---

## Completion

- playbook 完了後のアーカイブは Hook で自動処理される
- repository-map の更新が必要な場合は手動で実行

```bash
bash .claude/hooks/generate-repository-map.sh
```

---

## Admin Mode (Maintenance Only)

- `state.md` の `config.security: admin`
- 運用・保守のみに限定（契約回避のために使わない）
