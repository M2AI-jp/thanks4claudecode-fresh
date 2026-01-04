# thanks4claudecode

> Claude Code の Hook/Skill/SubAgent を前提にした運用ハーネス。
> playbook 駆動とガード強制で一貫性を保つ。

---

## Core Entry Points

- `CLAUDE.md` - コア契約（行動ルール）
- `AGENTS.md` - コーディングルール
- `state.md` - 現在地（SSOT）
- `docs/ARCHITECTURE.md` - 構造と動線
- `docs/core-feature-reclassification.md` - Hook Unit 目録
- `docs/repository-health.md` - 健全性の判定基準

---

## Quick Start

1. Claude Code で開く
2. `state.md` を読み、playbook がある場合は参照
3. playbook の flow に従って作業する（pm → reviewer → critic）

---

## Repository Map

- `docs/repository-map.yaml`（自動生成）
- 更新: `bash .claude/hooks/generate-repository-map.sh`
